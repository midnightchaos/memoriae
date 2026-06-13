import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/activity_monitoring_service.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  String _currentPhase = 'Breathe In';
  int _cycleCount = 0;
  bool _isActive = false;
  Timer? _phaseTimer;
  
  // Breathing patterns
  String _selectedPattern = '4-7-8';
  final Map<String, Map<String, int>> _breathingPatterns = {
    '4-7-8': {
      'inhale': 4,
      'hold': 7,
      'exhale': 8,
    },
    'Box': {
      'inhale': 4,
      'hold': 4,
      'exhale': 4,
      'hold2': 4,
    },
    'Simple': {
      'inhale': 4,
      'exhale': 4,
    },
    'Deep Calm': {
      'inhale': 5,
      'hold': 5,
      'exhale': 5,
    },
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Record interaction on screen open
    ActivityMonitoringService.instance.recordInteraction();
  }

  @override
  void dispose() {
    _controller.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isActive = true;
      _cycleCount = 0;
    });

    // Log activity
    ActivityMonitoringService.instance.logActivity(
      type: ActivityMonitoringService.TYPE_THERAPY,
      description: 'Patient started breathing exercise: $_selectedPattern',
    );

    _runBreathingCycle();
  }

  void _stopBreathing() {
    // Log activity
    ActivityMonitoringService.instance.logActivity(
      type: ActivityMonitoringService.TYPE_THERAPY,
      description: 'Patient stopped breathing exercise after $_cycleCount cycles',
    );

    setState(() {
      _isActive = false;
      _currentPhase = 'Breathe In';
    });
    _phaseTimer?.cancel();
    _controller.reset();
  }

  void _runBreathingCycle() {
    if (!_isActive) return;

    final pattern = _breathingPatterns[_selectedPattern]!;
    
    // Inhale
    _breathe('Breathe In', pattern['inhale']!, true, () {
      if (!_isActive) return;
      
      // Hold (if exists)
      if (pattern.containsKey('hold')) {
        _breathe('Hold', pattern['hold']!, false, () {
          if (!_isActive) return;
          _exhale(pattern);
        });
      } else {
        _exhale(pattern);
      }
    });
  }

  void _exhale(Map<String, int> pattern) {
    // Exhale
    _breathe('Breathe Out', pattern['exhale']!, true, () {
      if (!_isActive) return;
      
      // Hold after exhale (Box breathing only)
      if (pattern.containsKey('hold2')) {
        _breathe('Hold', pattern['hold2']!, false, () {
          if (!_isActive) return;
          setState(() => _cycleCount++);
          _runBreathingCycle();
        });
      } else {
        setState(() => _cycleCount++);
        _runBreathingCycle();
      }
    });
  }

  void _breathe(String phase, int duration, bool animate, VoidCallback onComplete) {
    setState(() => _currentPhase = phase);
    
    if (animate) {
      if (phase == 'Breathe In') {
        _controller.duration = Duration(seconds: duration);
        _controller.forward(from: 0);
      } else {
        _controller.duration = Duration(seconds: duration);
        _controller.reverse(from: 1);
      }
    }
    
    _phaseTimer?.cancel();
    _phaseTimer = Timer(Duration(seconds: duration), onComplete);
  }

  Color _getPhaseColor() {
    switch (_currentPhase) {
      case 'Breathe In':
        return AppColors.blue400;
      case 'Hold':
        return AppColors.purple400;
      case 'Breathe Out':
        return AppColors.emerald400;
      default:
        return AppColors.blue400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isBlackMinimalism = themeService.themeMode == AppThemeMode.blackMinimalism;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBlackMinimalism
                ? [Colors.black, const Color(0xFF0A0A0A), Colors.black]
                : (isDark
                    ? [AppColors.slate900, AppColors.slate800, AppColors.slate900]
                    : [AppColors.blue50, AppColors.lavender50, AppColors.mint50]),
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      'Breathing Exercise',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Pattern Selector
              if (!_isActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a Pattern',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isBlackMinimalism ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _breathingPatterns.keys.map((pattern) {
                          final isSelected = pattern == _selectedPattern;
                          return ChoiceChip(
                            label: Text(pattern),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedPattern = pattern);
                              }
                            },
                            selectedColor: isBlackMinimalism ? Colors.white : AppColors.blue400,
                            backgroundColor: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
                            labelStyle: TextStyle(
                              color: isSelected 
                                  ? (isBlackMinimalism ? Colors.black : Colors.white) 
                                  : (isBlackMinimalism ? Colors.white70 : null),
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                            side: isBlackMinimalism ? BorderSide(color: isSelected ? Colors.white : Colors.white10) : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Breathing Circle
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 100 + (_scaleAnimation.value * 150),
                    height: 100 + (_scaleAnimation.value * 150),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _getPhaseColor().withOpacity(0.8),
                          _getPhaseColor().withOpacity(0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getPhaseColor().withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 80 + (_scaleAnimation.value * 100),
                        height: 80 + (_scaleAnimation.value * 100),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getPhaseColor(),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Phase Text
              Text(
                _currentPhase,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _getPhaseColor(),
                ),
              ),

              const SizedBox(height: 20),

              // Cycle Counter
              if (_isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isBlackMinimalism 
                        ? const Color(0xFF0A0A0A) 
                        : (isDark ? AppColors.slate800 : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: isBlackMinimalism ? Border.all(color: Colors.white10) : null,
                    boxShadow: isBlackMinimalism ? null : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Cycles: $_cycleCount',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isBlackMinimalism ? Colors.white : null,
                    ),
                  ),
                ),

              const Spacer(),

              // Instructions
              if (!_isActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, size: 32, color: AppColors.blue400),
                      const SizedBox(height: 12),
                      Text(
                        _getPatternInstructions(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Control Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_isActive) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _stopBreathing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startBreathing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBlackMinimalism ? Colors.white : AppColors.blue400,
                            foregroundColor: isBlackMinimalism ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getPatternInstructions() {
    switch (_selectedPattern) {
      case '4-7-8':
        return 'Breathe in for 4 seconds, hold for 7, exhale for 8. Perfect for relaxation and sleep.';
      case 'Box':
        return 'Breathe in for 4 seconds, hold for 4, exhale for 4, hold for 4. Great for focus and calm.';
      case 'Simple':
        return 'Breathe in for 4 seconds, exhale for 4. Easy and effective for stress relief.';
      case 'Deep Calm':
        return 'Breathe in for 5 seconds, hold for 5, exhale for 5. Deep relaxation technique.';
      default:
        return 'Follow the circle and breathe with the prompts.';
    }
  }
}
