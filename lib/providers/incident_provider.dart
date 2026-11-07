import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/image_upload_service.dart';
import '../services/incident_service.dart';

const _sampleTitles = {
  'Water leak near Library entrance',
  'Projector not working in Room 204',
  'Overflowing bin by the cafeteria',
  'Broken desk in Residence B',
  'Lights out along the east corridor',
  'Low water pressure in residence showers',
  'Library study room door will not close',
  'Recycling point needs collection',
  'Loose handrail near the main stairs',
  'Classroom chair has a sharp edge',
};

class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._service);

  final IncidentService _service;
  StreamSubscription<List<Incident>>? _sub;
  AppUser? _user;
  List<Incident> _items = const [];
  bool _loading = false;
  bool _busy = false;
  String? _error;
  String query = '';
  String category = 'All';
  String status = 'All';

  List<Incident> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;
  int get sampleReportsCount => _items
      .where(
        (item) =>
            item.reporterId == _user?.uid && _sampleTitles.contains(item.title),
      )
      .length;
  List<Incident> get visibleItems => _items.where((item) {
    final text =
        query.isEmpty ||
        item.title.toLowerCase().contains(query.toLowerCase()) ||
        item.building.toLowerCase().contains(query.toLowerCase());
    return text &&
        (category == 'All' || item.category == category) &&
        (status == 'All' || item.status == status);
  }).toList();

  // Called whenever the signed in user changes; only verified users get live data.
  void bind(AppUser? user) {
    final ready = user != null && user.emailVerified;
    if (ready && _user?.uid == user.uid) return;
    _user = ready ? user : null;
    _sub?.cancel();
    _sub = null;
    _items = const [];
    _error = null;
    _loading = ready;
    if (ready) _listen();
    scheduleMicrotask(notifyListeners);
  }

  void _listen() {
    _sub = _service.watchAll().listen(
      (list) {
        _items = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = _describe(e);
        notifyListeners();
      },
    );
  }

  void retry() {
    _sub?.cancel();
    _error = null;
    _loading = true;
    notifyListeners();
    _listen();
  }

  void setQuery(String value) {
    query = value.trim();
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  void setStatus(String value) {
    status = value;
    notifyListeners();
  }

  bool hasUpvoted(String incidentId, String userId) => _items.any(
    (item) => item.id == incidentId && item.upvoters.contains(userId),
  );

  Future<void> toggleUpvote(Incident incident, String userId) async {
    if (incident.reporterId == userId || userId.isEmpty) return;
    try {
      await _service.toggleUpvote(id: incident.id, uid: userId);
    } on FirebaseException catch (_) {
      // The live list keeps showing the real count, so nothing to roll back.
    }
  }

  Future<void> create({
    required String title,
    required String description,
    required String category,
    required String building,
    required bool anonymous,
    required String reporterId,
    required String reporterName,
    File? photo,
  }) => _guard(
    () => _service.create(
      title: title,
      description: description,
      category: category,
      building: building,
      anonymous: anonymous,
      reporterId: reporterId,
      reporterName: reporterName,
      photo: photo,
    ),
  );

  Future<void> updateStatus(Incident item, String value, String note) => _guard(
    () => _service.updateStatus(
      id: item.id,
      status: value,
      note: note,
      changedBy: _user?.displayName ?? 'Staff member',
    ),
  );

  Future<void> delete(Incident item) => _guard(() => _service.delete(item.id));

  Future<void> seedSampleReports({
    required String reporterId,
    required String reporterName,
  }) => _guard(() async {
    const samples = [
      (
        'Water leak near Library entrance',
        'Water',
        'Library',
        'A pipe is leaking beside the main entrance and making the walkway slippery.',
      ),
      (
        'Projector not working in Room 204',
        'Facilities',
        'Main Campus',
        'The classroom projector powers on but does not display from any laptop.',
      ),
      (
        'Overflowing bin by the cafeteria',
        'Sanitation',
        'Cafeteria',
        'The outdoor bin is full and litter is spreading around the seating area.',
      ),
      (
        'Broken desk in Residence B',
        'Furniture',
        'Residence',
        'One desk has a loose leg and is unsafe to use for studying.',
      ),
      (
        'Lights out along the east corridor',
        'Electricity',
        'Main Campus',
        'Several ceiling lights are not working along the second floor corridor.',
      ),
      (
        'Low water pressure in residence showers',
        'Water',
        'Residence',
        'Water pressure has been very low in the residence shower block since this morning.',
      ),
      (
        'Library study room door will not close',
        'Facilities',
        'Library',
        'The latch is damaged, so the group study room door stays open.',
      ),
      (
        'Recycling point needs collection',
        'Sanitation',
        'Cafeteria',
        'The recycling containers are full and need to be emptied.',
      ),
      (
        'Loose handrail near the main stairs',
        'Safety',
        'Main Campus',
        'The handrail moves when held and could cause someone to lose balance.',
      ),
      (
        'Classroom chair has a sharp edge',
        'Furniture',
        'Kigali Campus',
        'A broken plastic chair has a sharp edge and should be removed from the room.',
      ),
    ];
    final existing = await _service.watchAll().first;
    final existingTitles = existing
        .where((item) => item.reporterId == reporterId)
        .map((item) => item.title)
        .toSet();
    for (final sample in samples) {
      if (existingTitles.contains(sample.$1)) continue;
      await _service.create(
        title: sample.$1,
        description: sample.$4,
        category: sample.$2,
        building: sample.$3,
        anonymous: false,
        reporterId: reporterId,
        reporterName: reporterName,
      );
    }
    return null;
  });

  Future<void> _guard(Future<Object?> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _error = _describe(e);
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String _describe(Object e) {
    if (e is FirebaseException) {
      return switch (e.code) {
        'permission-denied' => 'You don’t have permission to do that.',
        'unavailable' ||
        'deadline-exceeded' => 'No connection. Check your internet and retry.',
        _ => 'Something went wrong. Please try again.',
      };
    }
    if (e is ImageUploadFailure) return e.message;
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
