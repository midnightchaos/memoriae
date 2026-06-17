import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/familiar_face.dart';
import '../services/familiar_face_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../services/activity_monitoring_service.dart';
import '../services/theme_service.dart';
import '../services/database_helper.dart';
import '../services/analytics_service.dart';
import '../models/game_progress.dart';
import 'package:uuid/uuid.dart';

class FaceMatchingGameScreen extends StatefulWidget {
  static const routeName = '/face-matching-game';

  const FaceMatchingGameScreen({super.key});

  @override
  State<FaceMatchingGameScreen> createState() => _FaceMatchingGameScreenState();
}

class _FaceMatchingGameScreenState extends State<FaceMatchingGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  List<FamiliarFace> _gameFaces = [];
  List<String> _shuffledNames = [];
  List<Color> _faceColors = [];

  int? _selectedFaceIndex;
  int? _selectedNameIndex;

  List<int> _matchedFaces = [];
  int _score = 0;
  int _attempts = 0;
  bool _isLoading = true;

  // Game colors for color matching mode
  final List<Color> _gameColors = [
    AppColors.lavender400,
    AppColors.rose400,
    AppColors.blue400,
    AppColors.emerald400,
    AppColors.peach400,
    AppColors.teal400,
    AppColors.purple400,
    AppColors.mint400,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadGame();

    // Record interaction on screen open
    ActivityMonitoringService.instance.recordInteraction();
  }

  Future<void> _loadGame() async {
    final profileService = context.read<ProfileService>();
    if (profileService.profile != null) {
      // Log game start
      ActivityMonitoringService.instance.logActivity(
        type: ActivityMonitoringService.typeGame,
        description: 'Patient started Face Matching Game',
      );

      await context.read<FamiliarFaceService>().loadFaces(
        profileService.profile!.id,
      );

      if (!mounted) return;

      final faceService = context.read<FamiliarFaceService>();

      if (faceService.faces.length < 3) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Select random faces for the game (3-6 faces)
      final allFaces = List<FamiliarFace>.from(faceService.faces);
      allFaces.shuffle();
      final gameSize = min(6, max(3, allFaces.length));

      setState(() {
        _gameFaces = allFaces.take(gameSize).toList();
        _shuffledNames = _gameFaces.map((f) => f.name).toList()..shuffle();
        _faceColors = List.generate(
          _gameFaces.length,
          (index) => _gameColors[index % _gameColors.length],
        );
        _isLoading = false;
      });
    }
  }

  void _onFaceTap(int index) {
    if (_matchedFaces.contains(index)) return;

    setState(() {
      _selectedFaceIndex = index;
      _checkMatch();
    });
  }

  void _onNameTap(int index) {
    if (_selectedNameIndex == index) {
      setState(() {
        _selectedNameIndex = null;
      });
      return;
    }

    setState(() {
      _selectedNameIndex = index;
      _checkMatch();
    });
  }

  void _checkMatch() {
    if (_selectedFaceIndex == null || _selectedNameIndex == null) return;

    final faceName = _gameFaces[_selectedFaceIndex!].name;
    final selectedName = _shuffledNames[_selectedNameIndex!];

    setState(() {
      _attempts++;
    });

    if (faceName == selectedName) {
      // Correct match!
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      setState(() {
        _matchedFaces.add(_selectedFaceIndex!);
        _score += 10;
        _selectedFaceIndex = null;
        _selectedNameIndex = null;
      });

      // Check if game is complete
      if (_matchedFaces.length == _gameFaces.length) {
        // Save progress to database
        final profileService = context.read<ProfileService>();
        if (profileService.profile != null) {
          final progress = GameProgress(
            id: const Uuid().v4(),
            userId: profileService.profile!.id,
            gameType: 'Face Matching',
            score: _score,
            completedAt: DateTime.now(),
            duration: 0, // Could calculate this if needed
          );

          DatabaseHelper.instance.saveGameProgress(progress).then((_) {
            // Invalidate analytics cache so profile updates
            AnalyticsService.instance.invalidateCache();
          });
        }

        // Log game completion
        ActivityMonitoringService.instance.logActivity(
          type: ActivityMonitoringService.typeGame,
          description:
              'Patient completed Face Matching Game with score $_score',
        );

        _showCompletionDialog();
      }
    } else {
      // Wrong match
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _selectedFaceIndex = null;
            _selectedNameIndex = null;
          });
        }
      });
    }
  }

  void _showCompletionDialog() {
    final accuracy = (_score / (_attempts * 10) * 100).toStringAsFixed(0);
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
        title: Row(
          children: [
            Text(
              '🎉 Congratulations! 🎉',
              style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You matched all the faces!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isBlackMinimalism ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Score', '$_score points', isBlackMinimalism),
            _buildStatRow('Attempts', '$_attempts', isBlackMinimalism),
            _buildStatRow('Accuracy', '$accuracy%', isBlackMinimalism),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Exit',
              style: TextStyle(
                color: isBlackMinimalism ? Colors.white70 : null,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlackMinimalism
                  ? Colors.white
                  : AppColors.emerald400,
              foregroundColor: isBlackMinimalism ? Colors.black : Colors.white,
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isBlackMinimalism) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isBlackMinimalism ? Colors.white70 : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isBlackMinimalism ? Colors.white : AppColors.lavender500,
            ),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _selectedFaceIndex = null;
      _selectedNameIndex = null;
      _matchedFaces = [];
      _score = 0;
      _attempts = 0;
      _shuffledNames = _gameFaces.map((f) => f.name).toList()..shuffle();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBlackMinimalism
                ? [Colors.black, const Color(0xFF121212)]
                : (isDark
                      ? [
                          AppColors.slate900,
                          AppColors.slate800,
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.lavender50,
                          AppColors.blue50,
                          AppColors.mint50,
                        ]),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        size: 28,
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      'Face Matching',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        size: 28,
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                      onPressed: _resetGame,
                    ),
                  ],
                ),
              ),

              // Score Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBlackMinimalism
                        ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
                        : [AppColors.lavender400, AppColors.blue400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: isBlackMinimalism
                      ? Border.all(color: Colors.white10)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isBlackMinimalism
                                  ? Colors.black
                                  : AppColors.lavender400)
                              .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreItem('Score', '$_score'),
                    Container(
                      width: 2,
                      height: 24,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _buildScoreItem(
                      'Matched',
                      '${_matchedFaces.length}/${_gameFaces.length}',
                    ),
                    Container(
                      width: 2,
                      height: 24,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _buildScoreItem('Attempts', '$_attempts'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Game Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _gameFaces.length < 3
                    ? _buildInsufficientFaces(isBlackMinimalism)
                    : _buildGameContent(isDark, isBlackMinimalism),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
        ),
      ],
    );
  }

  Widget _buildInsufficientFaces(bool isBlackMinimalism) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😔', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(
            'Not enough faces',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isBlackMinimalism ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add at least 3 familiar faces to play',
            style: TextStyle(color: isBlackMinimalism ? Colors.white38 : null),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlackMinimalism
                  ? Colors.white
                  : AppColors.lavender400,
              foregroundColor: isBlackMinimalism ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent(bool isDark, bool isBlackMinimalism) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isBlackMinimalism
                  ? const Color(0xFF0A0A0A)
                  : (isDark
                        ? AppColors.slate800.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBlackMinimalism
                    ? Colors.white10
                    : AppColors.lavender400.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isBlackMinimalism
                      ? Colors.white70
                      : AppColors.lavender500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap a face, then tap the matching name!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isBlackMinimalism ? Colors.white70 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Faces Grid
          Text(
            'Faces',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isBlackMinimalism ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _gameFaces.length,
            itemBuilder: (context, index) =>
                _buildFaceCard(index, isDark, isBlackMinimalism),
          ),

          const SizedBox(height: 32),

          // Names List
          Text(
            'Names',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isBlackMinimalism ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(
              _shuffledNames.length,
              (index) => _buildNameChip(index, isDark, isBlackMinimalism),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFaceCard(int index, bool isDark, bool isBlackMinimalism) {
    final face = _gameFaces[index];
    final isMatched = _matchedFaces.contains(index);
    final isSelected = _selectedFaceIndex == index;
    final color = _faceColors[index];

    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: isMatched ? null : () => _onFaceTap(index),
        child: Opacity(
          opacity: isMatched ? 0.4 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: isBlackMinimalism
                  ? const Color(0xFF0A0A0A)
                  : (isDark ? AppColors.slate800 : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color
                    : isMatched
                    ? AppColors.emerald400
                    : (isBlackMinimalism
                          ? Colors.white10
                          : color.withValues(alpha: 0.3)),
                width: isSelected || isMatched ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? color : Colors.black).withValues(alpha: 0.2),
                  blurRadius: isSelected ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        face.photoPath != null
                            ? Image.file(
                                File(face.photoPath!),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [color.withValues(alpha: 0.6), color],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                        if (isMatched)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: AppColors.emerald400,
                                size: 48,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameChip(int index, bool isDark, bool isBlackMinimalism) {
    final name = _shuffledNames[index];
    final isSelected = _selectedNameIndex == index;

    // Find if this name is already matched
    final matchedFaceIndex = _matchedFaces.firstWhere(
      (faceIndex) => _gameFaces[faceIndex].name == name,
      orElse: () => -1,
    );
    final isMatched = matchedFaceIndex != -1;
    final color = isMatched
        ? _faceColors[matchedFaceIndex]
        : AppColors.lavender400;

    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: isMatched ? null : () => _onNameTap(index),
        child: Opacity(
          opacity: isMatched ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                  : null,
              color: isSelected
                  ? null
                  : isBlackMinimalism
                  ? const Color(0xFF0A0A0A)
                  : (isDark ? AppColors.slate800 : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? color
                    : isMatched
                    ? AppColors.emerald400
                    : (isBlackMinimalism
                          ? Colors.white10
                          : color.withValues(alpha: 0.3)),
                width: isSelected || isMatched ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? color : Colors.black).withValues(alpha: 0.2),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : isBlackMinimalism
                        ? Colors.white70
                        : (isDark ? Colors.white : AppColors.slate900),
                  ),
                ),
                if (isMatched) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.emerald400,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
