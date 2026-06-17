import 'package:flutter/material.dart';
import '../services/theme_service.dart';

import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/menta_service.dart';
import '../services/activity_monitoring_service.dart';
import '../models/chat_message.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/menta_games_service.dart';
import '../widgets/animated_page_wrapper.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late MentaService _mentaService;

  // Image Input
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;

  // Voice Input
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _mentaService = Provider.of<MentaService>(context, listen: false);
    _addWelcomeMessage();
    _initializeAndCheckApi();

    // Record interaction on screen open
    ActivityMonitoringService.instance.recordInteraction();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) => debugPrint('STT status: $status'),
        onError: (errorNotification) =>
            debugPrint('STT error: $errorNotification'),
      );
    } catch (e) {
      debugPrint('STT initialization failed: $e');
    }
  }

  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speech.initialize();
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) => setState(() {
              _messageController.text = val.recognizedWords;
            }),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  Future<void> _initializeAndCheckApi() async {
    await _mentaService.initialize(); // Ensure API key is loaded

    if (!_mentaService.hasApiKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⚠️ Gemini API key not configured. Please set it in Settings.',
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        );
      }
    } else {
      print('API key loaded');
      setState(() {}); // Refresh UI to show connected status
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content:
              "Hello! I'm Menta, your memory care companion. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final imagePath = _selectedImagePath;

    if (text.isEmpty && imagePath == null) return;

    // Log activity
    ActivityMonitoringService.instance.logActivity(
      type: ActivityMonitoringService.typeChat,
      description: imagePath != null
          ? 'Patient sent an image to Menta'
          : 'Patient sent a message to Menta',
    );

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: text,
          isUser: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          imagePath: imagePath,
        ),
      );
      _isLoading = true;
      _selectedImagePath = null;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get response from Menta
      final response = await _mentaService.chat(text, imagePath: imagePath);

      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: response,
            isUser: false,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      final errorMessage = e.toString();
      String userFriendlyMessage = "I'm sorry, I encountered an error. ";

      if (errorMessage.contains('API key')) {
        userFriendlyMessage =
            '⚠️ API key issue detected. Please check your settings or try again later.';
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('connection')) {
        userFriendlyMessage =
            '🚫 Connection error. Please check your internet and try again.';
      } else {
        userFriendlyMessage +=
            'Please try again or contact support if the issue persists.';
      }

      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: userFriendlyMessage,
            isUser: false,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        _isLoading = false;
      });

      // Show retry option
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${errorMessage.length > 50 ? '${errorMessage.substring(0, 50)}...' : errorMessage}',
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _messageController.text = text;
                _sendMessage();
              },
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _scrollToBottom();
    }
  }

  void _handleFeedback(String messageId, bool isPositive) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPositive
              ? 'Glad I could help! 😊'
              : 'Thanks for the feedback. I\'ll try to do better. 😔',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Log feedback for adaptive learning
    ActivityMonitoringService.instance.logActivity(
      type: ActivityMonitoringService.typeFeedback,
      description:
          'User provided ${isPositive ? 'positive' : 'negative'} feedback on Menta response',
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildApiStatusIndicator(bool isDark) {
    return FutureBuilder<bool>(
      future: _checkApiKeyValid(),
      builder: (context, snapshot) {
        final themeService = context.watch<ThemeService>();
        final isBlackMinimalism =
            themeService.themeMode == AppThemeMode.blackMinimalism;
        final hasValidKey = snapshot.data ?? false;
        final isConnected = snapshot.connectionState == ConnectionState.done;

        if (!isConnected) {
          return Text(
            'Checking...',
            style: TextStyle(
              fontSize: 12,
              color: isBlackMinimalism
                  ? Colors.white38
                  : (isDark ? AppColors.slate400 : AppColors.slate600),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasValidKey ? Icons.check_circle : Icons.error_outline,
              size: 12,
              color: hasValidKey ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              hasValidKey ? 'AI Connected' : 'Limited Mode',
              style: TextStyle(
                fontSize: 12,
                color: hasValidKey
                    ? Colors.green
                    : (isBlackMinimalism
                          ? Colors.orange.withValues(alpha: 0.8)
                          : Colors.orange),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkApiKeyValid() async {
    return _mentaService.hasApiKey;
  }

  Future<void> _shareConversation() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No conversation to share'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Format the conversation
    final buffer = StringBuffer();
    buffer.writeln('Menta Conversation');
    buffer.writeln(
      'Generated: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
    );
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (var message in _messages) {
      final sender = message.isUser ? 'You' : 'Menta';
      final time = DateFormat('hh:mm a').format(message.dateTime);
      buffer.writeln('[$time] $sender:');
      buffer.writeln(message.content);
      buffer.writeln();
    }

    buffer.writeln('=' * 50);
    buffer.writeln('Total messages: ${_messages.length}');

    try {
      // Share as plain text (works with any app)
      await SharePlus.instance.share(
        ShareParams(
          text: buffer.toString(),
          subject:
              'Menta Conversation - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation?'),
        content: const Text(
          'This will delete all messages in this chat. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
      });

      // Also clear from database
      await _mentaService.geminiService.clearConversation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation cleared'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = context.watch<ThemeService>();
    final isDark = theme.brightness == Brightness.dark;
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isBlackMinimalism
                    ? null
                    : LinearGradient(
                        colors: [AppColors.lavender400, AppColors.teal400],
                      ),
                color: isBlackMinimalism ? Colors.white : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('💬', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Menta', style: TextStyle(fontSize: 18)),
                _buildApiStatusIndicator(isDark),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _messages.length > 1 ? _shareConversation : null,
            tooltip: 'Share conversation',
          ),
          IconButton(
            icon: const Icon(Icons.videogame_asset_outlined),
            onPressed: _startMentaGame,
            tooltip: 'Play a memory game',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearConversation();
              } else if (value == 'settings') {
                Navigator.pushNamed(context, '/settings');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Clear conversation',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedPageWrapper(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation with Menta',
                        style: TextStyle(
                          color: isBlackMinimalism
                              ? Colors.white38
                              : (isDark
                                    ? AppColors.slate400
                                    : AppColors.slate600),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _MessageBubble(
                          message: message,
                          isDark: isDark,
                          isBlackMinimalism: isBlackMinimalism,
                          onFeedback: (isPositive) {
                            _handleFeedback(message.id, isPositive);
                          },
                          onOptionSelected: (option) {
                            _handleGameResponse(option);
                          },
                        );
                      },
                    ),
            ),

            // Loading indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBlackMinimalism
                            ? const Color(0xFF0A0A0A)
                            : (isDark ? AppColors.slate800 : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: isBlackMinimalism
                            ? Border.all(color: Colors.white10)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.lavender400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Menta is thinking...',
                            style: TextStyle(
                              color: isBlackMinimalism
                                  ? Colors.white38
                                  : (isDark
                                        ? AppColors.slate400
                                        : AppColors.slate600),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Input field
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isBlackMinimalism
                    ? Colors.black
                    : (isDark ? AppColors.slate800 : Colors.white),
                border: isBlackMinimalism
                    ? const Border(top: BorderSide(color: Colors.white10))
                    : null,
                boxShadow: isBlackMinimalism
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedImagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_selectedImagePath!),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: GestureDetector(
                                onTap: _clearSelectedImage,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.image_outlined,
                            color: AppColors.lavender400,
                          ),
                          onPressed: _pickImage,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isBlackMinimalism
                                  ? const Color(0xFF0A0A0A)
                                  : (isDark
                                        ? AppColors.slate700
                                        : AppColors.slate100),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.red
                                : (isBlackMinimalism
                                      ? const Color(0xFF0A0A0A)
                                      : (isDark
                                            ? AppColors.slate700
                                            : AppColors.slate100)),
                            shape: BoxShape.circle,
                            border: isBlackMinimalism && !_isListening
                                ? Border.all(color: Colors.white10)
                                : null,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening
                                  ? Colors.white
                                  : AppColors.lavender400,
                            ),
                            onPressed: _listen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: isBlackMinimalism
                                ? null
                                : LinearGradient(
                                    colors: [
                                      AppColors.lavender400,
                                      AppColors.teal400,
                                    ],
                                  ),
                            color: isBlackMinimalism ? Colors.white : null,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.send,
                              color: isBlackMinimalism
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            onPressed: _isLoading ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMentaGame() async {
    setState(() => _isLoading = true);
    final gameInvite = await MentaGamesService.instance.generateGameInvite();
    setState(() => _isLoading = false);

    if (gameInvite != null) {
      setState(() {
        _messages.add(gameInvite);
      });
      _scrollToBottom();
    }
  }

  Future<void> _handleGameResponse(String option) async {
    final userResponse = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: option,
      isUser: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _messages.add(userResponse);
      _isLoading = true;
    });
    _scrollToBottom();

    final feedback = await MentaGamesService.instance.handleResponse(option);

    setState(() {
      _isLoading = false;
      _messages.add(feedback);
    });
    _scrollToBottom();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final bool isBlackMinimalism;
  final Function(bool)? onFeedback;
  final Function(String)? onOptionSelected;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.isBlackMinimalism,
    this.onFeedback,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: isBlackMinimalism
                    ? null
                    : LinearGradient(
                        colors: [AppColors.lavender400, AppColors.teal400],
                      ),
                color: isBlackMinimalism ? Colors.white24 : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('💬', style: TextStyle(fontSize: 16)),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: (message.isUser && !isBlackMinimalism)
                    ? LinearGradient(
                        colors: [AppColors.lavender400, AppColors.teal400],
                      )
                    : null,
                color: message.isUser
                    ? (isBlackMinimalism ? Colors.white12 : null)
                    : (isBlackMinimalism
                          ? const Color(0xFF1A1A1A)
                          : (isDark ? AppColors.slate800 : Colors.white)),
                borderRadius: BorderRadius.circular(20),
                border: isBlackMinimalism
                    ? Border.all(color: Colors.white10)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: message.imagePath!.startsWith('assets/')
                            ? Image.asset(
                                message.imagePath!,
                                fit: BoxFit.cover,
                                width: 200,
                              )
                            : Image.file(
                                File(message.imagePath!),
                                fit: BoxFit.cover,
                                width: 200,
                              ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : (isDark ? AppColors.slate100 : AppColors.slate900),
                      fontSize: 15,
                    ),
                  ),
                  if (message.type == 'game_question' &&
                      message.metadata != null)
                    _buildGameOptions(context),
                  if (!message.isUser &&
                      message.content.length > 20 &&
                      message.type == 'text')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FeedbackButton(
                            icon: Icons.thumb_up_outlined,
                            onPressed: () => onFeedback?.call(true),
                            isDark: isDark,
                            isBlackMinimalism: isBlackMinimalism,
                          ),
                          const SizedBox(width: 8),
                          _FeedbackButton(
                            icon: Icons.thumb_down_outlined,
                            onPressed: () => onFeedback?.call(false),
                            isDark: isDark,
                            isBlackMinimalism: isBlackMinimalism,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: isBlackMinimalism ? Colors.white12 : AppColors.blue400,
                borderRadius: BorderRadius.circular(16),
                border: isBlackMinimalism
                    ? Border.all(color: Colors.white10)
                    : null,
              ),
              child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameOptions(BuildContext context) {
    try {
      final metadata = jsonDecode(message.metadata!);
      final options = metadata['options'] as List<dynamic>?;
      if (options == null || options.isEmpty) return const SizedBox();

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => onOptionSelected?.call(option.toString()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isBlackMinimalism
                        ? Colors.white24
                        : AppColors.lavender400.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  option.toString(),
                  style: TextStyle(
                    color: isBlackMinimalism
                        ? Colors.white
                        : AppColors.lavender400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    } catch (e) {
      return const SizedBox();
    }
  }
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;
  final bool isBlackMinimalism;

  const _FeedbackButton({
    required this.icon,
    required this.onPressed,
    required this.isDark,
    required this.isBlackMinimalism,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          icon,
          size: 14,
          color: isBlackMinimalism
              ? Colors.white38
              : (isDark ? AppColors.slate400 : AppColors.slate600),
        ),
      ),
    );
  }
}
