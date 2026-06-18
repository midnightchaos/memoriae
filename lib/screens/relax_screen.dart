import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

import '../theme/app_theme.dart';
import 'breathing_exercise_screen.dart';
import 'music_therapy_screen.dart';
import 'meditation_screen.dart';
import 'drawing_therapy_screen.dart';
import 'face_matching_game_screen.dart';

class RelaxScreen extends StatelessWidget {
  const RelaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;
    final isDark = themeService.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBlackMinimalism
                ? [Colors.black, const Color(0xFF0A0A0A), Colors.black]
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
                    if (Navigator.of(context).canPop())
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    const Spacer(),
                    Text(
                      'Relax & Unwind',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content - Changed to SingleChildScrollView
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Featured Relaxation Card
                      _buildFeaturedCard(context, isDark, isBlackMinimalism),

                      const SizedBox(height: 32),

                      // Therapy Options Grid
                      _buildTherapyCard(
                        context: context,
                        icon: '🎵',
                        title: 'Music Therapy',
                        subtitle: 'Calming melodies & nature sounds',
                        gradient: [AppColors.lavender400, AppColors.purple400],
                        isDark: isDark,
                        isBlackMinimalism: isBlackMinimalism,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MusicTherapyScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTherapyCard(
                        context: context,
                        icon: '🧘',
                        title: 'Meditation',
                        subtitle: 'Guided mindfulness sessions',
                        gradient: [AppColors.emerald400, AppColors.teal400],
                        isDark: isDark,
                        isBlackMinimalism: isBlackMinimalism,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MeditationScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTherapyCard(
                        context: context,
                        icon: '💆',
                        title: 'Breathing Exercises',
                        subtitle: 'Deep relaxation techniques',
                        gradient: [AppColors.blue400, AppColors.teal400],
                        isDark: isDark,
                        isBlackMinimalism: isBlackMinimalism,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BreathingExerciseScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTherapyCard(
                        context: context,
                        icon: '🎨',
                        title: 'Art Therapy',
                        subtitle: 'Express yourself through drawing',
                        gradient: [AppColors.rose400, AppColors.peach400],
                        isDark: isDark,
                        isBlackMinimalism: isBlackMinimalism,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DrawingTherapyScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTherapyCard(
                        context: context,
                        icon: '🎮',
                        title: 'Memory Game',
                        subtitle: 'Match faces to names - fun & relaxing',
                        gradient: [AppColors.purple400, AppColors.lavender400],
                        isDark: isDark,
                        isBlackMinimalism: isBlackMinimalism,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FaceMatchingGameScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    bool isDark,
    bool isBlackMinimalism,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isBlackMinimalism ? const Color(0xFF0A0A0A) : null,
        gradient: isBlackMinimalism
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.blue100, AppColors.lavender100],
              ),
        borderRadius: BorderRadius.circular(24),
        border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
        boxShadow: isBlackMinimalism
            ? null
            : [
                BoxShadow(
                  color: AppColors.blue400.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌸', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Quick Breathing',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isBlackMinimalism ? Colors.white : AppColors.slate900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '5 minutes • Calm your mind',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isBlackMinimalism ? Colors.white70 : AppColors.slate700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BreathingExerciseScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlackMinimalism
                  ? Colors.white
                  : AppColors.blue400,
              foregroundColor: isBlackMinimalism ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Start Session',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapyCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required bool isDark,
    required bool isBlackMinimalism,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isBlackMinimalism ? const Color(0xFF0A0A0A) : null,
          gradient: isBlackMinimalism
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient
                      .map((c) => c.withValues(alpha: 0.15))
                      .toList(),
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBlackMinimalism
                ? Colors.white10
                : gradient[0].withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isBlackMinimalism
              ? null
              : [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(painter: _WavePainter(gradient[0])),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: gradient[0].withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Text
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isBlackMinimalism
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white
                                          : AppColors.slate900),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 14,
                                color:
                                    (isBlackMinimalism
                                            ? Colors.white70
                                            : (isDark
                                                  ? Colors.white
                                                  : AppColors.slate900))
                                        .withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: gradient[0].withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: gradient[0],
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;

  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i < size.width; i += 20) {
      path.lineTo(i, size.height * 0.5 + 10 * (i % 40 > 20 ? 1 : -1));
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
