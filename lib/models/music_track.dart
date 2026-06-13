class MusicTrack {
  final String id;
  final String name;
  final String filePath;
  final String type; // 'asset', 'local', 'recorded'
  final DateTime dateAdded;
  final Duration? duration;
  final String? subtitle;
  final String? icon;
  final int? colorValue;

  MusicTrack({
    required this.id,
    required this.name,
    required this.filePath,
    required this.type,
    required this.dateAdded,
    this.duration,
    this.subtitle,
    this.icon,
    this.colorValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'type': type,
      'dateAdded': dateAdded.toIso8601String(),
      'duration': duration?.inSeconds,
      'subtitle': subtitle,
      'icon': icon,
      'colorValue': colorValue,
    };
  }

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      type: json['type'] as String,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      duration: json['duration'] != null 
          ? Duration(seconds: json['duration'] as int)
          : null,
      subtitle: json['subtitle'] as String?,
      icon: json['icon'] as String?,
      colorValue: json['colorValue'] as int?,
    );
  }

  MusicTrack copyWith({
    String? id,
    String? name,
    String? filePath,
    String? type,
    DateTime? dateAdded,
    Duration? duration,
    String? subtitle,
    String? icon,
    int? colorValue,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      dateAdded: dateAdded ?? this.dateAdded,
      duration: duration ?? this.duration,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
