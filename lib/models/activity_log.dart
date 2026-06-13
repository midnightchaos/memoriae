class ActivityLog {
  final String? id;
  final String activityType; // 'C' for Chat, 'J' for Journal, 'G' for Games
  final String description;
  final DateTime timestamp;
  final int durationSeconds; // For tracking engagement time
  final String patientId;

  ActivityLog({
    this.id,
    required this.activityType,
    required this.description,
    DateTime? timestamp,
    this.durationSeconds = 0,
    required this.patientId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'activityType': activityType,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'patientId': patientId,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id']?.toString(),
      activityType: map['activityType'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
      durationSeconds: map['durationSeconds'] ?? 0,
      patientId: map['patientId'],
    );
  }
}
