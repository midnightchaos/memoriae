class Caregiver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isVerified;
  final DateTime createdAt;
  final String? passwordHash;
  final String? salt;

  Caregiver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.isVerified = false,
    DateTime? createdAt,
    this.passwordHash,
    this.salt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'isVerified': isVerified ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'passwordHash': passwordHash,
      'salt': salt,
    };
  }

  factory Caregiver.fromMap(Map<String, dynamic> map) {
    return Caregiver(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      isVerified: map['isVerified'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      passwordHash: map['passwordHash'],
      salt: map['salt'],
    );
  }
}
