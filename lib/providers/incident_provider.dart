import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';

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
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
