import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/incident.dart';

class IncidentProvider extends ChangeNotifier {
  final Map<String, Set<String>> _votes = {};
  final List<Incident> _items = [
    Incident(
      id: 'sample-water',
      title: 'Water pressure is low in Residence B',
      description: 'The taps on the second floor have had very low pressure since this morning.',
      category: 'Water',
      building: 'Residence',
      status: 'In Progress',
      reporterId: 'student@alustudent.com',
      reporterName: 'Aline Student',
      isAnonymous: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      history: [
        StatusEvent(
          status: 'Submitted',
          note: 'Report submitted',
          changedBy: 'Aline Student',
          at: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        StatusEvent(
          status: 'In Progress',
          note: 'Maintenance team notified',
          changedBy: 'Jordan Staff',
          at: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    ),
    Incident(
      id: 'sample-light',
      title: 'Light out near the library entrance',
      description: 'The walkway light beside the main entrance is not working after dark.',
      category: 'Electricity',
      building: 'Library',
      status: 'Submitted',
      reporterId: 'demo-other-student',
      reporterName: '',
      isAnonymous: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      history: [
        StatusEvent(
          status: 'Submitted',
          note: 'Report submitted',
          changedBy: 'Student account',
          at: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    ),
  ];
  bool _busy = false;
  String? _error;
  String query = '';
  String category = 'All';
  String status = 'All';

  List<Incident> get items => List.unmodifiable(_items);
  bool get loading => false;
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

  void retry() {
    _error = null;
    notifyListeners();
  }

  bool hasUpvoted(String incidentId, String userId) =>
      _votes[incidentId]?.contains(userId) ?? false;

  void toggleUpvote(Incident incident, String userId) {
    if (incident.reporterId == userId) return;
    final voters = _votes.putIfAbsent(incident.id, () => <String>{});
    if (!voters.add(userId)) voters.remove(userId);
    final index = _items.indexWhere((entry) => entry.id == incident.id);
    if (index >= 0) {
      final old = _items[index];
      _items[index] = Incident(
        id: old.id,
        title: old.title,
        description: old.description,
        category: old.category,
        building: old.building,
        status: old.status,
        reporterId: old.reporterId,
        reporterName: old.reporterName,
        isAnonymous: old.isAnonymous,
        createdAt: old.createdAt,
        imagePath: old.imagePath,
        upvoteCount: voters.length,
        history: old.history,
      );
    }
    notifyListeners();
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
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    _items.insert(
      0,
      Incident(
        id: now.microsecondsSinceEpoch.toString(),
        title: title.trim(),
        description: description.trim(),
        category: category,
        building: building,
        status: 'Submitted',
        reporterId: reporterId,
        reporterName: anonymous ? '' : reporterName,
        isAnonymous: anonymous,
        createdAt: now,
        imagePath: photo?.path,
        history: [
          StatusEvent(
            status: 'Submitted',
            note: 'Report submitted',
            changedBy: reporterName,
            at: now,
          ),
        ],
      ),
    );
    _busy = false;
    notifyListeners();
  }

  Future<void> updateStatus(Incident item, String value, String note) async {
    _busy = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      final old = _items[index];
      _items[index] = Incident(
        id: old.id,
        title: old.title,
        description: old.description,
        category: old.category,
        building: old.building,
        status: value,
        reporterId: old.reporterId,
        reporterName: old.reporterName,
        isAnonymous: old.isAnonymous,
        createdAt: old.createdAt,
        imagePath: old.imagePath,
        upvoteCount: old.upvoteCount,
        history: [
          ...old.history,
          StatusEvent(
            status: value,
            note: note.trim(),
            changedBy: 'Staff member',
            at: DateTime.now(),
          ),
        ],
      );
    }
    _busy = false;
    notifyListeners();
  }

  Future<void> delete(Incident item) async {
    _items.removeWhere((entry) => entry.id == item.id);
    notifyListeners();
  }
}
