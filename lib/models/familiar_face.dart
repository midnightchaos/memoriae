class FamiliarFace {
  final String id;
  final String userId;
  final String name;
  final String relation;
  final String? phoneNumber;
  final String? email;
  final String? photoPath;
  final String? notes;
  final DateTime createdAt;

  static const String defaultRelation = 'Family Member';

  FamiliarFace({
    required this.id,
    required this.userId,
    required this.name,
    required this.relation,
    this.phoneNumber,
    this.email,
    this.photoPath,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'relation': relation,
      'phoneNumber': phoneNumber,
      'email': email,
      'photoPath': photoPath,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory FamiliarFace.fromMap(Map<String, dynamic> map) {
    return FamiliarFace(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      relation: map['relation'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      photoPath: map['photoPath'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  FamiliarFace copyWith({
    String? id,
    String? userId,
    String? name,
    String? relation,
    String? phoneNumber,
    String? email,
    String? photoPath,
    String? notes,
    DateTime? createdAt,
  }) {
    return FamiliarFace(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool matchesSearch(String query) {
    final searchLower = query.toLowerCase();
    return name.toLowerCase().contains(searchLower) ||
        relation.toLowerCase().contains(searchLower) ||
        (email?.toLowerCase().contains(searchLower) ?? false) ||
        (phoneNumber?.contains(RegExp(r'\d')) ??
            false &&
                phoneNumber!
                    .replaceAll(RegExp(r'[^\d]', multiLine: true), '')
                    .contains(searchLower));
  }
}
