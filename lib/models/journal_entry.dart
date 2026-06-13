class JournalEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String? imagePath;
  final List<String> imagesPaths;
  final String? audioPath;
  final List<String> tags;
  final String mood;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.imagePath,
    this.imagesPaths = const [],
    this.audioPath,
    this.tags = const [],
    this.mood = '😊',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'imagesPaths': imagesPaths,
      'audioPath': audioPath,
      'tags': tags,
      'mood': mood,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      date: DateTime.parse(json['date'] as String),
      imagePath: json['imagePath'] as String?,
      imagesPaths: (json['imagesPaths'] as List<dynamic>?)?.cast<String>() ?? [],
      audioPath: json['audioPath'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      mood: json['mood'] as String? ?? '😊',
    );
  }

  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    String? imagePath,
    List<String>? imagesPaths,
    String? audioPath,
    List<String>? tags,
    String? mood,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      imagesPaths: imagesPaths ?? this.imagesPaths,
      audioPath: audioPath ?? this.audioPath,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
    );
  }
}
