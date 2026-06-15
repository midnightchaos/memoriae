import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'auth/welcome_screen.dart';
import 'main_navigation_screen.dart';
import 'caregiver/caregiver_dashboard_screen.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../services/profile_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Gentle breathing pulse for the logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.forward();
    _pulseController.repeat(reverse: true);

    // Navigate after splash
    Future.delayed(const Duration(milliseconds: 3200), () async {
      if (mounted) {
        try {
          final auth = AuthService.instance;
          final user = await auth.getCurrentUser();

          Widget destination;
          if (user != null) {
            if (mounted) {
              final profileService = Provider.of<ProfileService>(
                context,
                listen: false,
              );
              await profileService.syncWithUser(user);
            }

            destination = auth.isCaregiver
                ? const CaregiverDashboardScreen()
                : const MainNavigationScreen();
          } else {
            destination = const WelcomeScreen();
          }

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    destination,
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: AppDurations.pageTransition,
              ),
              (route) => false,
            );
          }
        } catch (e) {
          debugPrint('Startup error: $e');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with breathing pulse
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.lavender400.withOpacity(0.35),
                                blurRadius: 32,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: AppColors.teal400.withOpacity(0.15),
                                blurRadius: 48,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('💜', style: TextStyle(fontSize: 56)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // App name with slide-up
                    Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Text(
                        'Memoriae',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 38,
                          fontWeight: FontWeight.w400,
                          color: theme.textTheme.displayMedium?.color,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Tagline
                    Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.6),
                      child: Text(
                        'Caring for Memory',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: theme.textTheme.bodyLarge?.color?.withOpacity(
                            0.7,
                          ),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Loading dots
                    _LoadingDots(color: AppColors.lavender400),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Three pulsing dots loading indicator
class _LoadingDots extends StatefulWidget {
  final Color color;

  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((c) {
      return Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();

    // Stagger the dot animations
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(_animations[i].value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
