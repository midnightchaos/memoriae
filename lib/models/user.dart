class User {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? profileImagePath;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isGuest;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.profileImagePath,
    required this.createdAt,
    required this.lastLoginAt,
    this.isGuest = false,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'profileImagePath': profileImagePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
      'isGuest': isGuest ? 1 : 0,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      age: map['age'] as int?,
      profileImagePath: map['profileImagePath'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(
        map['lastLoginAt'] as int,
      ),
      isGuest: map['isGuest'] == 1,
      isActive: map['isActive'] == 1,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? profileImagePath,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isGuest,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isGuest: isGuest ?? this.isGuest,
      isActive: isActive ?? this.isActive,
    );
  }
}
