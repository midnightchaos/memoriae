class CaregiverAlert {
  final String? id;
  final String type; // e.g., 'INACTIVITY', 'LOW_ENGAGEMENT', 'MISSED_ROUTINE'
  final String message;
  final String severity; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final DateTime timestamp;
  final bool isResolved;
  final String patientId;

  CaregiverAlert({
    this.id,
    required this.type,
    required this.message,
    required this.severity,
    DateTime? timestamp,
    this.isResolved = false,
    required this.patientId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'message': message,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'isResolved': isResolved ? 1 : 0,
      'patientId': patientId,
    };
  }

  factory CaregiverAlert.fromMap(Map<String, dynamic> map) {
    return CaregiverAlert(
      id: map['id']?.toString(),
      type: map['type'],
      message: map['message'],
      severity: map['severity'],
      timestamp: DateTime.parse(map['timestamp']),
      isResolved: map['isResolved'] == 1,
      patientId: map['patientId'],
    );
  }
}
