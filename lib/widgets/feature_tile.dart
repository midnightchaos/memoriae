import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';

/// A full-width feature tile for the home screen.
///
/// Replaces the old FeatureCard with proper Icon support,
/// staggered entrance animation, and full theme awareness.
class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final String? backgroundImage;
  final VoidCallback onTap;
  final int index; // for stagger delay

  const FeatureTile({
    super.key,
    required this.icon,
    required this.label,
    required this.sublabel,
    this.backgroundImage,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;
    final isBlack = pageStyle.pageColor == Colors.black;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 60)),
      curve: AppCurves.entrance,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            borderRadius: AppRadius.xl,
            color: isBlack ? const Color(0xFF0A0A0A) : null,
            border: isBlack ? Border.all(color: Colors.white10) : null,
            boxShadow: isBlack ? null : AppShadows.medium,
          ),
          child: Stack(
            children: [
              // Background image or gradient
              if (backgroundImage != null && !isBlack)
                ClipRRect(
                  borderRadius: AppRadius.xl,
                  child: Image.asset(
                    backgroundImage!,
                    width: double.infinity,
                    height: 88,
                    cacheHeight: 176,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.lavender400.withOpacity(0.3),
                            AppColors.purple400.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: AppRadius.xl,
                      ),
                    ),
                  ),
                ),

              // Gradient overlay for readability
              if (backgroundImage != null && !isBlack)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: AppRadius.xl,
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    // Icon in styled container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isBlack
                            ? Colors.white12
                            : Colors.white.withOpacity(0.25),
                        borderRadius: AppRadius.md,
                      ),
                      child: Icon(icon, size: 26, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: isBlack
                                  ? null
                                  : const [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(1, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sublabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isBlack ? Colors.white38 : Colors.white70,
                              shadows: isBlack
                                  ? null
                                  : const [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(1, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isBlack
                            ? Colors.white10
                            : Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: isBlack ? Colors.white38 : Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
