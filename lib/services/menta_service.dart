import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../models/chat_message.dart';
import 'database_helper.dart';
import 'gemini_service.dart';

enum MentaState { listening, processing, speaking, idle, error }

class MentaService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final GeminiService _geminiService = GeminiService();

  bool _isInitialized = false;
  bool _isMuted = false;
  MentaState _state = MentaState.idle;
  String _lastSpokenText = '';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isMuted => _isMuted;
  MentaState get state => _state;
  String get lastSpokenText => _lastSpokenText;
  bool get hasApiKey => _geminiService.hasApiKey;
  GeminiService get geminiService => _geminiService;

  // Initialize Menta
  Future<void> initialize() async {
    try {
      // Initialize TTS
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5); // Slower rate for better understanding

      // Initialize speech recognition
      _isInitialized = await _speech.initialize(
        onStatus: (status) => _onSpeechStatus(status),
        onError: (error) => _onSpeechError(error),
      );

      // Initialize Gemini service
      await _geminiService.initialize();

      // Load preferences
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool('menta_muted') ?? false;

      _state = MentaState.idle;
      notifyListeners();
    } catch (e) {
      developer.log('Menta initialization failed: $e');
      _state = MentaState.error;
      notifyListeners();
      rethrow;
    }
  }

  // Toggle mute state
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('menta_muted', _isMuted);
    notifyListeners();
  }

  // Speak text with TTS
  Future<void> speak(String text) async {
    if (_isMuted) return;

    _lastSpokenText = text;
    _state = MentaState.speaking;
    notifyListeners();

    await _tts.speak(text);

    // Wait for speech to complete
    await _tts.awaitSpeakCompletion(true);
    _state = MentaState.idle;
    notifyListeners();
  }

  // Start listening for voice commands
  Future<bool> startListening() async {
    if (!_isInitialized) return false;

    final isAvailable = _speech.isAvailable;
    if (!isAvailable) return false;

    _state = MentaState.listening;
    notifyListeners();

    return await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_US',
    );
  }

  // Stop listening
  Future<void> stopListening() async {
    await _speech.stop();
    _state = MentaState.idle;
    notifyListeners();
  }

  // Handle speech recognition result
  void _onSpeechResult(result) {
    if (result.finalResult) {
      final text = result.recognizedWords.trim();
      if (text.isNotEmpty) {
        _processCommand(text);
      }
    }
  }

  // Process voice command
  Future<void> _processCommand(String command) async {
    _state = MentaState.processing;
    notifyListeners();

    try {
      // 1. Check for navigation commands
      if (await _handleNavigation(command)) return;

      // 2. Check database queries
      final dbResponse = await _queryDatabase(command);
      if (dbResponse != null) {
        await speak(dbResponse);
        return;
      }

      // 3. Fallback to Gemini API or local processing
      final response = await _getAiResponse(command);
      await speak(response);
    } catch (e) {
      developer.log('Error processing command: $e');
      await speak("I'm sorry, I encountered an error. Please try again.");
    } finally {
      _state = MentaState.idle;
      notifyListeners();
    }
  }

  // Handle navigation commands
  Future<bool> _handleNavigation(String command) async {
    final lowerCommand = command.toLowerCase();

    // Simple command mapping - can be expanded
    final routes = {
      'journal': 'journal',
      'diary': 'journal',
      'medication': 'medications',
      'medicine': 'medications',
      'pills': 'medications',
      'photos': 'gallery',
      'pictures': 'gallery',
      'family': 'contacts',
      'contacts': 'contacts',
      'reminders': 'reminders',
      'calendar': 'calendar',
      'schedule': 'calendar',
    };

    for (final entry in routes.entries) {
      if (lowerCommand.contains(entry.key)) {
        // In a real app, this would use Navigator
        await speak("Taking you to ${entry.key}");
        // Navigation would be handled by the UI layer
        return true;
      }
    }

    return false;
  }

  // Query local database
  Future<String?> _queryDatabase(String query) async {
    // Check for familiar faces
    if (query.toLowerCase().startsWith('who is ')) {
      final name = query.substring(7).trim();
      final faces = await _dbHelper.getFamiliarFaces(name);

      if (faces.isNotEmpty) {
        final face = faces.first;
        return "${face.name} is your ${face.relation}. ${face.notes != null && face.notes!.isNotEmpty ? 'Note: ${face.notes}' : ''}";
      }
    }

    // Add more database queries as needed

    return null;
  }

  // Chat method for text-based conversations
  Future<String> chat(String message, {String? imagePath}) async {
    _state = MentaState.processing;
    notifyListeners();

    try {
      // Save user message to database
      await _dbHelper.insertChatMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: message,
          isUser: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          imagePath: imagePath,
        ),
      );

      // Get AI response
      final response = await _getAiResponse(message, imagePath: imagePath);

      // Save AI response to database
      await _dbHelper.insertChatMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response,
          isUser: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      _state = MentaState.idle;
      notifyListeners();

      return response;
    } catch (e) {
      developer.log('Chat error: $e');
      _state = MentaState.idle;
      notifyListeners();
      rethrow;
    }
  }

  // Get AI response (Gemini or fallback)
  Future<String> _getAiResponse(String query, {String? imagePath}) async {
    try {
      developer.log('[MentaService] Getting AI response for: "$query"');
      // Try Gemini first using the initialized instance
      final response = await _geminiService.getResponse(
        query,
        imagePath: imagePath,
      );
      developer.log(
        '[MentaService] Got Gemini response: "${response.substring(0, response.length > 50 ? 50 : response.length)}..."',
      );
      return response;
    } catch (e) {
      developer.log('[MentaService] Gemini API error: $e');
      // Only fallback for network/API errors, not for bad responses
      if (e.toString().contains('API key') ||
          e.toString().contains('connection') ||
          e.toString().contains('network')) {
        return _getLocalResponse(query);
      }
      // Re-throw other errors so they're visible to the user
      rethrow;
    }
  }

  // Simple local response fallback
  String _getLocalResponse(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('hello') || lowerQuery.contains('hi')) {
      return 'Hello! How can I assist you today?';
    } else if (lowerQuery.contains('thank')) {
      return "You're welcome! Is there anything else I can help with?";
    } else if (lowerQuery.contains('help')) {
      return 'I can help you with: checking your journal, managing medications, finding contacts, and more. What would you like to do?';
    }

    return "I'm sorry, I didn't understand that. Could you please rephrase or ask for help?";
  }

  // Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    developer.log('Speech status: $status');
    if (status == 'done' && _state == MentaState.listening) {
      _state = MentaState.idle;
      notifyListeners();
    }
  }

  // Handle speech recognition errors
  void _onSpeechError(error) {
    developer.log('Speech error: $error');
    _state = MentaState.error;
    notifyListeners();

    // Auto-recover from error after delay
    Future.delayed(const Duration(seconds: 2), () {
      _state = MentaState.idle;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.cancel();
    super.dispose();
  }
}
