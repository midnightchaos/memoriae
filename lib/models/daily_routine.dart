class DailyRoutine {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String time;
  final List<int> days;
  final bool isActive;
  final DateTime createdAt;

  DailyRoutine({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.time,
    required this.days,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'time': time,
      'days': days.join(','),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory DailyRoutine.fromMap(Map<String, dynamic> map) {
    return DailyRoutine(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      time: map['time'] as String,
      days: (map['days'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  DailyRoutine copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? time,
    List<int>? days,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return DailyRoutine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
