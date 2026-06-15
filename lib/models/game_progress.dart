class GameProgress {
  final String id;
  final String userId;
  final String gameType;
  final int score;
  final DateTime completedAt;
  final int duration;

  GameProgress({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.score,
    required this.completedAt,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'gameType': gameType,
      'score': score,
      'completedAt': completedAt.millisecondsSinceEpoch,
      'duration': duration,
    };
  }

  factory GameProgress.fromMap(Map<String, dynamic> map) {
    return GameProgress(
      id: map['id'] as String,
      userId: map['userId'] as String,
      gameType: map['gameType'] as String,
      score: map['score'] as int,
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map['completedAt'] as int,
      ),
      duration: map['duration'] as int,
    );
  }
}
