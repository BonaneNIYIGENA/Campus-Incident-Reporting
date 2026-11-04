import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _asDate(Object? value) =>
    value is Timestamp ? value.toDate() : DateTime.now();

class StatusEvent {
  const StatusEvent({
    required this.status,
    required this.note,
    required this.changedBy,
    required this.at,
  });
  final String status, note, changedBy;
  final DateTime at;

  factory StatusEvent.fromMap(Map<String, dynamic> map) => StatusEvent(
    status: map['status'] as String? ?? '',
    note: map['note'] as String? ?? '',
    changedBy: map['changedBy'] as String? ?? '',
    at: _asDate(map['at']),
  );

  Map<String, dynamic> toMap() => {
    'status': status,
    'note': note,
    'changedBy': changedBy,
    'at': Timestamp.fromDate(at),
  };
}

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.building,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.isAnonymous,
    required this.createdAt,
    this.imagePath,
    this.upvoteCount = 0,
    this.upvoters = const [],
    this.history = const [],
  });

  final String id,
      title,
      description,
      category,
      building,
      status,
      reporterId,
      reporterName;
  final bool isAnonymous;
  final DateTime createdAt;
  final String? imagePath;
  final int upvoteCount;
  final List<String> upvoters;
  final List<StatusEvent> history;

  factory Incident.fromMap(String id, Map<String, dynamic> map) => Incident(
    id: id,
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    category: map['category'] as String? ?? 'Other',
    building: map['building'] as String? ?? 'Other',
    status: map['status'] as String? ?? 'Submitted',
    reporterId: map['reporterId'] as String? ?? '',
    reporterName: map['reporterName'] as String? ?? '',
    isAnonymous: map['isAnonymous'] as bool? ?? false,
    createdAt: _asDate(map['createdAt']),
    imagePath: map['imageUrl'] as String?,
    upvoteCount: (map['upvoteCount'] as num?)?.toInt() ?? 0,
    upvoters: List<String>.from(map['upvoters'] as List? ?? const []),
    history: [
      for (final event in map['history'] as List? ?? const [])
        StatusEvent.fromMap(Map<String, dynamic>.from(event as Map)),
    ],
  );
}
