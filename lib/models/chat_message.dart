class ChatMessage {
  static const String tableName = 'chat_messages';
  
  final String id;
  final String content;
  final bool isUser;
  final int timestamp;
  final String type; // 'text', 'game_invite', 'game_question', 'game_result'
  final bool isLoading;
  final String? metadata;
  final String? imagePath;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required int timestamp,
    this.type = 'text',
    this.isLoading = false,
    this.metadata,
    this.imagePath,
  }) : timestamp = timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp,
      'type': type,
      'metadata': metadata,
      'imagePath': imagePath,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      content: map['content'],
      isUser: map['isUser'] == 1,
      timestamp: map['timestamp'],
      type: map['type'] ?? 'text',
      metadata: map['metadata'],
      imagePath: map['imagePath'],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    int? timestamp,
    String? type,
    bool? isLoading,
    String? metadata,
    String? imagePath,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isLoading: isLoading ?? this.isLoading,
      metadata: metadata ?? this.metadata,
      imagePath: imagePath ?? this.imagePath,
    );
  }
  
  // Get the message as a DateTime
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}
