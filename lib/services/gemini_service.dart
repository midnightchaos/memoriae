import 'dart:convert';
import 'package:meta/meta.dart';
import 'dart:math';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mem3/models/chat_message.dart';
import 'package:mem3/config/env_config.dart';
import 'package:mem3/config/menta_system_prompt.dart';
import 'package:mem3/services/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class GeminiService {
  // Use stable models for better quota
  static const String _primaryModel = 'gemini-flash-latest';
  static const String _fallbackModel = 'gemini-flash-lite-latest';
  
  static String get baseUrl => 'https://generativelanguage.googleapis.com/v1beta/models/$_primaryModel:generateContent';
  static const String _apiKeyPrefsKey = 'gemini_api_key';
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  
  String? _apiKey;
  final DatabaseHelper _dbHelper;
  String? _currentUserId;
  String? _currentUserName;
  String _currentModel = _primaryModel;
  
  GeminiService({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance {
    _loadApiKey();
  }
  
  // Initialize and ensure API key is loaded
  Future<void> initialize() async {
    await _loadApiKey();
    await _loadUserContext();
    developer.log('[GeminiService] Initialized with model: $_currentModel');
    developer.log('[GeminiService] API key: ${hasApiKey ? "YES" : "NO"}');
  }
  
  // Load user context for personalization
  Future<void> _loadUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('current_user_id');
    _currentUserName = prefs.getString('current_user_name');
  }
  
  // Load API key from SharedPreferences or use default from env
  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_apiKeyPrefsKey);
    
    if (savedKey != null && savedKey.isNotEmpty) {
      _apiKey = savedKey;
      developer.log('[GeminiService] Loaded API key from SharedPreferences');
    } else if (EnvConfig.hasDefaultApiKey) {
      _apiKey = EnvConfig.geminiApiKey;
      developer.log('[GeminiService] Using default API key from env');
    } else {
      developer.log('[GeminiService] NO API KEY FOUND!');
    }
  }
  
  // Get memory context from database - THIS IS THE KEY FIX!
  @visibleForTesting
  Future<Map<String, dynamic>> getMemoryContext() async {
    try {
      developer.log('[GeminiService] 🔍 Loading memory context from database...');
      
      // Get recent journal entries
      final journals = await _dbHelper.readAllEntries();
      final recentJournals = journals.take(3).map((j) => {
        'title': j.title,
        'date': DateFormat('MMM dd, yyyy').format(j.date),
        'mood': j.mood,
        'content': j.content.length > 100 ? '${j.content.substring(0, 100)}...' : j.content,
      }).toList();
      
      // Get medications for user
      final medications = await _dbHelper.getMedications(_currentUserId ?? '');
      final activeMeds = medications.where((m) => m.isActive).map((m) => {
        'name': m.name,
        'dosage': m.dosage,
        'frequency': m.frequency,
        'timeOfDay': m.timeOfDay,
      }).toList();
      
      // Get familiar faces for user
      final allFaces = await _dbHelper.getFamiliarFaces(_currentUserId ?? '');
      final facesData = allFaces.map((f) => {
        'name': f.name,
        'relation': f.relation,
        'notes': f.notes ?? '',
      }).toList();
      
      // Get daily routines for user
      final allRoutines = await _dbHelper.getDailyRoutines(_currentUserId ?? '');
      final activeRoutines = allRoutines.where((r) => r.isActive).map((r) => {
        'title': r.title,
        'time': r.time,
        'description': r.description ?? '',
      }).toList();
      
      // Get reminders for user
      final allReminders = await _dbHelper.getAllReminders(); // Note: reminders table might not be userId-aware yet in stub
      final activeReminders = allReminders.map((r) => {
        'title': r['title'],
        'dateTime': DateFormat('MMM dd, yyyy h:mm a').format(r['dateTime']),
        'description': r['description'] ?? '',
      }).toList();
      
      // NEW: Get ALL safety locations
      final safetyLocations = await _dbHelper.getSafetyLocations(_currentUserId ?? '');
      final zones = safetyLocations.map((s) => {
        'name': s.name,
        'radius': s.radius,
        'type': s.isHome ? 'Home' : 'Safe Zone',
      }).toList();

      // NEW: Calculate Mood Trend
      String moodSummary = 'No recent mood data.';
      if (journals.isNotEmpty) {
        final recentMoods = journals.take(5).map((j) => j.mood).toList();
        moodSummary = 'Recently, the user has felt: ${recentMoods.join(", ")}.';
      }

      // NEW: Filter for Today's Agenda
      final now = DateTime.now();
      final todayWeekday = now.weekday;
      final todayRoutines = allRoutines.where((r) => r.isActive && r.days.contains(todayWeekday)).toList();
      
      final todayReminders = allReminders.where((r) {
        final dt = r['dateTime'] as DateTime;
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      }).toList();

      developer.log('[GeminiService] ✅ Loaded context: ${journals.length} journals, ${activeMeds.length} meds, ${todayRoutines.length} routines today');
      
      return {
        'journals': recentJournals.isNotEmpty ? recentJournals : null,
        'medications': activeMeds.isNotEmpty ? activeMeds : null,
        'routines': activeRoutines.isNotEmpty ? activeRoutines : null,
        'familiarFaces': facesData.isNotEmpty ? facesData : null,
        'reminders': activeReminders.isNotEmpty ? activeReminders : null,
        'safetyZones': zones.isNotEmpty ? zones : null,
        'moodSummary': moodSummary,
        'todayAgenda': {
          'routines': todayRoutines.map((r) => '${r.time}: ${r.title}').toList(),
          'reminders': todayReminders.map((r) => '${DateFormat('h:mm a').format(r['dateTime'])}: ${r['title']}').toList(),
        },
      };
    } catch (e) {
      developer.log('[GeminiService] ❌ Error loading memory context: $e');
      return {};
    }
  }
  
  
  // Set and save API key
  Future<void> setApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      throw Exception('API key cannot be empty');
    }
    
    _apiKey = apiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefsKey, apiKey);
    developer.log('[GeminiService] API key saved');
  }
  
  // Clear the saved API key
  Future<void> clearApiKey() async {
    _apiKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefsKey);
    developer.log('[GeminiService] API key cleared');
  }
  
  String? get apiKey => _apiKey;
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  String get currentModel => _currentModel;
  
  // Check if the API key is valid
  Future<bool> validateApiKey() async {
    if (!hasApiKey) {
      developer.log('[GeminiService] Cannot validate - no API key');
      return false;
    }
    
    try {
      developer.log('[GeminiService] Validating API key...');
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey'),
      );
      developer.log('[GeminiService] Validation response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      developer.log('[GeminiService] Validation error: $e');
      return false;
    }
  }

  // Save a message to the database
  Future<void> saveMessage(ChatMessage message) async {
    await _dbHelper.insertChatMessage(message);
  }
  
  // Get conversation history - FIXED: Limit to recent conversation only
  Future<List<ChatMessage>> getConversationHistory({int limit = 6}) async {
    return await _dbHelper.getChatMessages(limit: limit);
  }
  
  // Clear conversation history
  Future<void> clearConversation() async {
    await _dbHelper.clearChatHistory();
  }
  
  // Calculate exponential backoff delay
  Duration _getRetryDelay(int attempt) {
    final exponentialDelay = _baseRetryDelay * pow(2, attempt);
    // Add jitter to prevent thundering herd
    final jitter = Duration(milliseconds: Random().nextInt(1000));
    return exponentialDelay + jitter;
  }
  
  // Make API request with retry logic
  Future<http.Response> _makeApiRequestWithRetry({
    required String url,
    required Map<String, dynamic> requestBody,
    required int maxRetries,
  }) async {
    int attempt = 0;
    Exception? lastException;
    
    while (attempt < maxRetries) {
      try {
        developer.log('[GeminiService] API request attempt ${attempt + 1}/$maxRetries');
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timed out after 30 seconds');
          },
        );
        
        // Success cases
        if (response.statusCode == 200) {
          developer.log('[GeminiService] ✅ Request successful');
          return response;
        }
        
        // Retryable error codes
        if (response.statusCode == 503 || // Service Unavailable
            response.statusCode == 429 || // Too Many Requests
            response.statusCode == 500) { // Internal Server Error
          
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
          developer.log('[GeminiService] ⚠️ Retryable error ${response.statusCode}: $errorMsg');
          
          if (attempt < maxRetries - 1) {
            final delay = _getRetryDelay(attempt);
            developer.log('[GeminiService] ⏳ Retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
            attempt++;
            continue;
          }
        }
        
        // Non-retryable errors - return immediately
        if (response.statusCode == 401 || response.statusCode == 403) {
          developer.log('[GeminiService] ❌ Authentication error - not retrying');
          return response;
        }
        
        // Unknown error - return to handle elsewhere
        return response;
        
      } on SocketException catch (e) {
        lastException = Exception('Network error: ${e.message}. Please check your internet connection.');
        developer.log('[GeminiService] 🌐 Network error on attempt ${attempt + 1}: $e');
        
        // For DNS/network errors, retry with longer delays
        if (attempt < maxRetries - 1) {
          final delay = Duration(seconds: 3 + (attempt * 2)); // 3s, 5s, 7s
          developer.log('[GeminiService] ⏳ Network issue - retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          attempt++;
        } else {
          break;
        }
      } on Exception catch (e) {
        lastException = e;
        developer.log('[GeminiService] ❌ Exception on attempt ${attempt + 1}: $e');
        
        if (attempt < maxRetries - 1) {
          final delay = _getRetryDelay(attempt);
          developer.log('[GeminiService] ⏳ Retrying after exception in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          attempt++;
        } else {
          break;
        }
      }
    }
    
    // All retries exhausted
    throw lastException ?? Exception('All retry attempts failed');
  }
  
  // Switch to fallback model
  Future<void> _switchToFallbackModel() async {
    if (_currentModel != _fallbackModel) {
      developer.log('[GeminiService] 🔄 Switching to fallback model: $_fallbackModel');
      _currentModel = _fallbackModel;
    }
  }
  
  // Send message to Gemini API with retry logic and fallback
  Future<ChatMessage> sendMessage(String message, {String? imagePath, bool storeInHistory = true}) async {
    developer.log('[GeminiService] ========== SEND MESSAGE START ==========');
    if (imagePath != null) {
      developer.log('[GeminiService] Image Path: "$imagePath"');
    }
    developer.log('[GeminiService] Message: "$message"');
    developer.log('[GeminiService] Model: $_currentModel');
    developer.log('[GeminiService] Has API key: $hasApiKey');
    
    if (!hasApiKey) {
      developer.log('[GeminiService] ERROR: No API key configured!');
      throw Exception('API key not set. Please configure your Gemini API key in Settings.');
    }

    try {
      // Save user message first
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: message,
        isUser: true,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        imagePath: imagePath,
      );
      
      if (storeInHistory) {
        await saveMessage(userMessage);
        developer.log('[GeminiService] User message saved to DB');
      }

      // Get ONLY recent conversation history (last 3 exchanges = 6 messages)
      // This prevents old conversations from repeating
      final history = await getConversationHistory(limit: 6);
      developer.log('[GeminiService] Loaded ${history.length} recent messages from history');
      
      // ALWAYS load fresh database context for EVERY message
      final memoryContext = await getMemoryContext();
      
      // Build the conversation context
      final contents = <Map<String, dynamic>>[];
      
      // ALWAYS include system prompt + database context at the start
      final systemPrompt = MentaSystemPrompt.getPromptWithContext(
        userName: _currentUserName,
        currentDate: DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
        currentTime: DateFormat('h:mm a').format(DateTime.now()),
        recentData: memoryContext,
      );

      contents.add({
        'role': 'user',
        'parts': [{'text': systemPrompt}]
      });
      
      contents.add({
        'role': 'model',
        'parts': [{'text': 'I understand perfectly. I am Menta, your dedicated memory companion. I have reviewed your journals, medications, daily routines, and familiar faces. I will use this information to provide you with compassionate, personalized support while monitoring your safety and well-being. How can I help you today?'}]
      });
      
      // Add recent conversation history (but skip older messages to avoid repetition)
      for (var msg in history.reversed) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [{'text': msg.content}]
        });
      }
      
      // Add current message and image if present
      final userParts = <Map<String, dynamic>>[
        {'text': message}
      ];

      if (imagePath != null) {
        final base64Image = await _fileToBase64(imagePath);
        if (base64Image != null) {
          userParts.insert(0, {
            'inline_data': {
              'mime_type': 'image/jpeg',
              'data': base64Image,
            }
          });
          
          // Add face recognition specific instructions if there's an image
          final imageInstructions = StringBuffer();
          imageInstructions.writeln('\n📷 IMAGE ANALYSIS INSTRUCTIONS:');
          imageInstructions.writeln('The user has uploaded an image.');
          imageInstructions.writeln('1. Examine the image carefully.');
          imageInstructions.writeln('2. Compare any people in the image against the FAMILIAR FACES list provided above.');
          imageInstructions.writeln('3. If you find a match, greet them warmly and remind the user of their relationship.');
          imageInstructions.writeln('4. If no match is found but there is a person, describe them politely.');
          imageInstructions.writeln('5. If the image is not of a person, describe what you see in the context of memory care.');
          
          userParts.add({'text': imageInstructions.toString()});
        }
      }
      
      contents.add({
        'role': 'user',
        'parts': userParts
      });

      final requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      // Try with primary model first
      String currentUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_currentModel:generateContent?key=$_apiKey';
      
      developer.log('[GeminiService] Making API request with retries...');
      http.Response response;
      
      try {
        response = await _makeApiRequestWithRetry(
          url: currentUrl,
          requestBody: requestBody,
          maxRetries: _maxRetries,
        );
      } catch (e) {
        // If primary model fails completely, try fallback
        if (_currentModel != _fallbackModel) {
          developer.log('[GeminiService] 🔄 Primary model failed, trying fallback model...');
          await _switchToFallbackModel();
          currentUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_currentModel:generateContent?key=$_apiKey';
          
          response = await _makeApiRequestWithRetry(
            url: currentUrl,
            requestBody: requestBody,
            maxRetries: 2, // Fewer retries for fallback
          );
        } else {
          rethrow;
        }
      }

      developer.log('[GeminiService] Final response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('[GeminiService] Response parsed successfully');
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'] ?? 'No response generated';
          developer.log('[GeminiService] Response text length: ${text.length}');
          
          // Save AI response to history
          final aiMessage = ChatMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            content: text,
            isUser: false,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          
          if (storeInHistory) {
            await saveMessage(aiMessage);
            developer.log('[GeminiService] AI response saved to DB');
          }
          
          developer.log('[GeminiService] ========== SEND MESSAGE SUCCESS ==========');
          return aiMessage;
        } else {
          developer.log('[GeminiService] ERROR: No candidates in response');
          throw Exception('No response generated from the model');
        }
      } else {
        developer.log('[GeminiService] ERROR: Bad status code ${response.statusCode}');
        developer.log('[GeminiService] Error response: ${response.body}');
        
        final error = jsonDecode(response.body);
        final errorMessage = error['error']?['message'] ?? 'Unknown error';
        
        if (response.statusCode == 401 || response.statusCode == 403) {
          await clearApiKey();
          throw Exception('Invalid API key. Please update your API key in settings.');
        }
        
        if (response.statusCode == 503) {
          throw Exception('The AI service is temporarily busy. This usually resolves quickly. Please try again in a moment.');
        }
        
        throw Exception('API Error: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      developer.log('[GeminiService] ========== SEND MESSAGE FAILED (NETWORK) ==========');
      developer.log('[GeminiService] Network exception: $e');
      throw Exception('Cannot connect to Google AI services. Please check your internet connection and try again.');
    } catch (e) {
      developer.log('[GeminiService] ========== SEND MESSAGE FAILED ==========');
      developer.log('[GeminiService] Exception: $e');
      
      // Check for specific network-related errors
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Network error')) {
        throw Exception('Cannot connect to Google AI services. Please check your internet connection and try again.');
      }
      
      if (e.toString().contains('API key')) {
        rethrow;
      }
      if (e is! Exception) {
        throw Exception('Failed to send message: ${e.toString()}');
      }
      rethrow;
    }
  }
  
  // Simple method to get response text (for compatibility with MentaService)
  Future<String> getResponse(String message, {String? imagePath}) async {
    developer.log('[GeminiService] getResponse called with: "$message"');
    final chatMessage = await sendMessage(message, imagePath: imagePath);
    return chatMessage.content;
  }

  // Helper to convert file to base64
  Future<String?> _fileToBase64(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      developer.log('[GeminiService] Error converting file to base64: $e');
    }
    return null;
  }
}
