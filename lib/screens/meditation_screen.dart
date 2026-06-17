import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

import 'dart:async';
import '../theme/app_theme.dart';
import '../services/activity_monitoring_service.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSessionActive = false;
  String _currentPhase = 'Ready to begin';
  int _selectedDuration = 5; // minutes

  final List<Map<String, dynamic>> _sessions = [
    {
      'title': 'Quick Calm',
      'duration': 5,
      'icon': '⚡',
      'color': AppColors.mint400,
      'description': 'Perfect for a quick mental reset',
    },
    {
      'title': 'Deep Focus',
      'duration': 10,
      'icon': '🎯',
      'color': AppColors.blue400,
      'description': 'Enhance concentration and clarity',
    },
    {
      'title': 'Stress Relief',
      'duration': 15,
      'icon': '🌊',
      'color': AppColors.teal400,
      'description': 'Release tension and find peace',
    },
    {
      'title': 'Extended Peace',
      'duration': 20,
      'icon': '🌙',
      'color': AppColors.purple400,
      'description': 'Deep relaxation and mindfulness',
    },
  ];

  final List<String> _guidanceSteps = [
    'Find a comfortable position',
    'Close your eyes gently',
    'Take a deep breath in',
    'Hold for a moment',
    'Breathe out slowly',
    'Notice your body relaxing',
    'Let go of any tension',
    'Focus on your breath',
    'Be present in this moment',
    'Feel the peace within',
  ];

  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Record interaction on screen open
    ActivityMonitoringService.instance.recordInteraction();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startSession(int durationMinutes) {
    setState(() {
      _selectedDuration = durationMinutes;
      _remainingSeconds = durationMinutes * 60;
      _isSessionActive = true;
      _currentPhase = _guidanceSteps[0];
      _currentStepIndex = 0;
    });

    // Log activity
    ActivityMonitoringService.instance.logActivity(
      type: ActivityMonitoringService.typeTherapy,
      description:
          'Patient started meditation session: $durationMinutes minutes',
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;

          // Change guidance every 30 seconds
          if (_remainingSeconds % 30 == 0 &&
              _currentStepIndex < _guidanceSteps.length - 1) {
            _currentStepIndex++;
            _currentPhase = _guidanceSteps[_currentStepIndex];
          }
        });
      } else {
        _endSession();
      }
    });
  }

  void _endSession() {
    _timer?.cancel();
    setState(() {
      _isSessionActive = false;
      _currentPhase = 'Session complete! 🎉';
    });

    // Log activity
    ActivityMonitoringService.instance.logActivity(
      type: ActivityMonitoringService.typeTherapy,
      description:
          'Patient completed meditation session: $_selectedDuration minutes',
    );

    // Show completion dialog
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showCompletionDialog();
      }
    });
  }

  void _stopSession() {
    _timer?.cancel();
    setState(() {
      _isSessionActive = false;
      _remainingSeconds = 0;
      _currentPhase = 'Ready to begin';
      _currentStepIndex = 0;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [Text('🎉 '), Text('Session Complete')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Well done! You\'ve completed your meditation session.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '$_selectedDuration minutes of mindfulness',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.lavender400,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startSession(_selectedDuration);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lavender400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Practice Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeService = context.watch<ThemeService>();
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isBlackMinimalism ? Colors.black : null,
          gradient: isBlackMinimalism
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.slate900,
                          AppColors.slate800,
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.lavender50,
                          AppColors.blue50,
                          AppColors.lavender100,
                        ],
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
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () {
                        if (_isSessionActive) {
                          _showExitConfirmation();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const Spacer(),
                    Text(
                      'Meditation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isSessionActive
                    ? _buildActiveSession(isDark, isBlackMinimalism)
                    : _buildSessionSelection(isDark, isBlackMinimalism),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSession(bool isDark, bool isBlackMinimalism) {
    final progress = _remainingSeconds / (_selectedDuration * 60);
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),

        // Animated Circle
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isBlackMinimalism
                    ? null
                    : RadialGradient(
                        colors: [
                          AppColors.lavender400.withValues(alpha: 0.3),
                          AppColors.purple400.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        stops: [
                          0.0,
                          0.7 * _animationController.value + 0.3,
                          1.0,
                        ],
                      ),
                color: isBlackMinimalism
                    ? Colors.white.withValues(alpha: 
                        0.05 * _animationController.value,
                      )
                    : null,
                boxShadow: isBlackMinimalism
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.lavender400.withValues(alpha: 
                            0.3 * _animationController.value,
                          ),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                border: isBlackMinimalism
                    ? Border.all(
                        color: Colors.white10.withValues(alpha: 
                          0.5 * _animationController.value,
                        ),
                        width: 2,
                      )
                    : null,
              ),
              child: Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isBlackMinimalism
                        ? const Color(0xFF0A0A0A)
                        : (isDark ? AppColors.slate800 : Colors.white),
                    border: isBlackMinimalism
                        ? Border.all(color: Colors.white10)
                        : null,
                    boxShadow: isBlackMinimalism
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: isBlackMinimalism ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'remaining',
                        style: TextStyle(
                          fontSize: 14,
                          color: isBlackMinimalism
                              ? Colors.white38
                              : (isDark
                                    ? AppColors.slate400
                                    : AppColors.slate600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 48),

        // Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isBlackMinimalism
                      ? Colors.white10
                      : (isDark ? AppColors.slate700 : AppColors.slate200),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isBlackMinimalism ? Colors.white : AppColors.lavender400,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _currentPhase,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isBlackMinimalism ? Colors.white : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const Spacer(),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _stopSession,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isBlackMinimalism
                    ? Colors.white24
                    : AppColors.coral400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: isBlackMinimalism
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildSessionSelection(bool isDark, bool isBlackMinimalism) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isBlackMinimalism
                ? null
                : LinearGradient(
                    colors: [AppColors.lavender100, AppColors.lavender100],
                  ),
            color: isBlackMinimalism ? const Color(0xFF0A0A0A) : null,
            borderRadius: BorderRadius.circular(24),
            border: isBlackMinimalism
                ? Border.all(color: Colors.white10)
                : null,
            boxShadow: isBlackMinimalism
                ? null
                : [
                    BoxShadow(
                      color: AppColors.lavender400.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            children: [
              const Text('🧘', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Choose Your Practice',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isBlackMinimalism ? Colors.white : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select a meditation session duration',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isBlackMinimalism ? Colors.white70 : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Session Options
        ...List.generate(_sessions.length, (index) {
          final session = _sessions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSessionCard(
              session: session,
              isDark: isDark,
              isBlackMinimalism: isBlackMinimalism,
              onTap: () => _startSession(session['duration'] as int),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSessionCard({
    required Map<String, dynamic> session,
    required bool isDark,
    required bool isBlackMinimalism,
    required VoidCallback onTap,
  }) {
    final color = session['color'] as Color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isBlackMinimalism
              ? const Color(0xFF0A0A0A)
              : (isDark ? AppColors.slate800 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBlackMinimalism ? Colors.white10 : color.withValues(alpha: 0.3),
            width: isBlackMinimalism ? 1 : 2,
          ),
          boxShadow: isBlackMinimalism
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isBlackMinimalism
                    ? Colors.white12
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  session['icon'] as String,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['title'] as String,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isBlackMinimalism ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session['description'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: isBlackMinimalism
                          ? Colors.white70
                          : (isDark ? AppColors.slate400 : AppColors.slate600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isBlackMinimalism
                          ? Colors.white12
                          : color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${session['duration']} minutes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isBlackMinimalism ? Colors.white : color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              color: isBlackMinimalism ? Colors.white24 : color,
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('End Session?'),
        content: const Text(
          'Are you sure you want to end your meditation session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopSession();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral400,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}
