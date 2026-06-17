import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import '../models/chat_message.dart';
import '../models/game_progress.dart';
import 'auth_service.dart';
import 'analytics_service.dart';

enum MentaGameType { faceRecall, journalQuiz, routineCheck, wordAssociation }

class MentaGamesService extends ChangeNotifier {
  static final MentaGamesService instance = MentaGamesService._init();
  MentaGamesService._init();

  final _db = DatabaseHelper.instance;
  final _random = Random();

  // Current active game state
  MentaGameType? _activeGameType;
  String? _correctAnswer;
  DateTime? _gameStartTime;

  MentaGameType? get activeGameType => _activeGameType;

  /// Selects and initiates a random game based on available data
  Future<ChatMessage?> generateGameInvite() async {
    final user = await AuthService.instance.getCurrentUser();
    final userId = user?.id;
    if (userId == null) return null;

    // Check available data to see which games are possible
    final faces = await _db.getFamiliarFaces(userId);
    final journals = await _db.readAllEntries();
    final routines = await _db.getDailyRoutines(userId);

    List<MentaGameType> possibleGames = [
      MentaGameType.wordAssociation,
    ]; // Always possible
    if (faces.isNotEmpty) possibleGames.add(MentaGameType.faceRecall);
    if (journals.isNotEmpty) possibleGames.add(MentaGameType.journalQuiz);
    if (routines.isNotEmpty) possibleGames.add(MentaGameType.routineCheck);

    _activeGameType = possibleGames[_random.nextInt(possibleGames.length)];
    _gameStartTime = DateTime.now();

    String content = "";
    Map<String, dynamic> metadata = {'gameType': _activeGameType.toString()};

    switch (_activeGameType!) {
      case MentaGameType.faceRecall:
        final face = faces[_random.nextInt(faces.length)];
        _correctAnswer = face.name;
        content =
            "I found a photo of someone special. Do you remember who this is?";
        metadata['faceId'] = face.id;
        metadata['imagePath'] = face.photoPath;
        metadata['options'] = _generateOptions(
          face.name,
          faces.map((f) => f.name).toList(),
        );
        break;

      case MentaGameType.journalQuiz:
        final journal = journals[_random.nextInt(journals.length)];
        _correctAnswer = journal.title;
        content =
            "You wrote something wonderful recently. Do you remember what you titled this entry: '${journal.content.substring(0, min(50, journal.content.length))}...'?";
        metadata['journalId'] = journal.id;
        metadata['options'] = _generateOptions(
          journal.title,
          journals.map((j) => j.title).toList(),
        );
        break;

      case MentaGameType.routineCheck:
        final routine = routines[_random.nextInt(routines.length)];
        _correctAnswer = routine.title;
        content =
            "It's almost ${routine.time}. Do you remember what we usually do at this time?";
        metadata['routineId'] = routine.id;
        metadata['options'] = _generateOptions(
          routine.title,
          routines.map((r) => r.title).toList(),
        );
        break;

      case MentaGameType.wordAssociation:
        final words = [
          "Garden",
          "Library",
          "Ocean",
          "Mountain",
          "Kitchen",
          "Piano",
        ];
        final word = words[_random.nextInt(words.length)];
        _correctAnswer = null; // Open ended
        content =
            "Let's play Word Association! I'll say a word, and you tell me the first thing that comes to mind. The word is: **$word**";
        metadata['word'] = word;
        break;
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: 'game_question',
      metadata: jsonEncode(metadata),
      imagePath: metadata['imagePath'],
    );
  }

  List<String> _generateOptions(String correct, List<String> all) {
    List<String> options = [correct];
    List<String> others = all.where((item) => item != correct).toList();
    others.shuffle();
    options.addAll(others.take(2));
    options.shuffle();
    return options;
  }

  Future<ChatMessage> handleResponse(String response) async {
    final user = await AuthService.instance.getCurrentUser();
    final userId = user?.id;
    bool isCorrect = false;
    String feedback = "";

    if (_activeGameType == MentaGameType.wordAssociation) {
      isCorrect = true;
      feedback =
          "That's a wonderful association! Memory is like a beautiful tapestry, isn't it?";
    } else if (_correctAnswer != null) {
      isCorrect = response.toLowerCase() == _correctAnswer!.toLowerCase();
      feedback = isCorrect
          ? "That's it! Wonderful memory. You're doing great today."
          : "Not quite, but that's okay! It was actually '$_correctAnswer'. Memory takes practice!";
    }

    // Save progress
    if (userId != null && _activeGameType != null) {
      final duration = _gameStartTime != null
          ? DateTime.now().difference(_gameStartTime!).inSeconds
          : 0;

      await _db.saveGameProgress(
        GameProgress(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          gameType: _activeGameType.toString().split('.').last,
          score: isCorrect ? 100 : 0,
          completedAt: DateTime.now(),
          duration: duration,
        ),
      );

      // Invalidate analytics cache so profile updates immediately
      AnalyticsService.instance.invalidateCache();
    }

    _activeGameType = null;
    _correctAnswer = null;
    _gameStartTime = null;

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: feedback,
      isUser: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: 'game_result',
      metadata: jsonEncode({'isCorrect': isCorrect}),
    );
  }
}
