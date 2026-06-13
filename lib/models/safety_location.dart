class SafetyLocation {
  final String id;
  final String userId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isHome;
  final DateTime createdAt;

  SafetyLocation({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radius = 100.0,
    this.isHome = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isHome': isHome ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SafetyLocation.fromMap(Map<String, dynamic> map) {
    return SafetyLocation(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      radius: map['radius'] as double,
      isHome: (map['isHome'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  SafetyLocation copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isHome,
    DateTime? createdAt,
  }) {
    return SafetyLocation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      isHome: isHome ?? this.isHome,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
