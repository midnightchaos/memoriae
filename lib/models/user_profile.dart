class UserProfile {
  final String id;
  final String name;
  final String email;
  final int? age;
  final bool caregiverAccess;
  final String? linkedCaregiverId;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.caregiverAccess = false,
    this.linkedCaregiverId,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    int? age,
    bool? caregiverAccess,
    String? linkedCaregiverId,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      caregiverAccess: caregiverAccess ?? this.caregiverAccess,
      linkedCaregiverId: linkedCaregiverId ?? this.linkedCaregiverId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'age': age,
    'caregiverAccess': caregiverAccess ? 1 : 0,
    'linkedCaregiverId': linkedCaregiverId,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id: m['id'],
    name: m['name'],
    email: m['email'],
    age: m['age'] as int?,
    caregiverAccess: (m['caregiverAccess'] ?? 0) == 1,
    linkedCaregiverId: m['linkedCaregiverId'],
  );
}
