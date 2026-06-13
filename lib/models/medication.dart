class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final String timeOfDay;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timeOfDay,
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'timeOfDay': timeOfDay,
      'notes': notes,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      frequency: map['frequency'] as String,
      timeOfDay: map['timeOfDay'] as String,
      notes: map['notes'] as String?,
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Medication copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    String? frequency,
    String? timeOfDay,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
