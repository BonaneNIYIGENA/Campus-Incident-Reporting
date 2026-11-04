class StatusEvent {
  const StatusEvent({
    required this.status,
    required this.note,
    required this.changedBy,
    required this.at,
  });
  final String status, note, changedBy;
  final DateTime at;
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
  final List<StatusEvent> history;
}
