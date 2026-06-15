import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';

/// A premium frosted-glass card with subtle depth and press animation.
///
/// Replaces all ad-hoc `Container(decoration: BoxDecoration(...))` patterns.
class GlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final LinearGradient? gradient;
  final bool enableBlur;
  final bool enablePressAnimation;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.width,
    this.height,
    this.gradient,
    this.enableBlur = false,
    this.enablePressAnimation = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: AppDurations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.enablePressAnimation && widget.onTap != null) {
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.enablePressAnimation) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enablePressAnimation) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardStyle = Theme.of(context).extension<AppCardStyle>()!;

    Widget card = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.gradient != null ? null : cardStyle.background,
        gradient: widget.gradient,
        borderRadius: cardStyle.borderRadius,
        border: cardStyle.borderWidth > 0
            ? Border.all(
                color: cardStyle.borderColor,
                width: cardStyle.borderWidth,
              )
            : null,
        boxShadow: cardStyle.shadows.isNotEmpty ? cardStyle.shadows : null,
      ),
      child: widget.enableBlur
          ? ClipRRect(
              borderRadius: cardStyle.borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            )
          : Padding(padding: widget.padding, child: widget.child),
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      card = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        onLongPress: widget.onLongPress != null
            ? () {
                HapticFeedback.mediumImpact();
                widget.onLongPress?.call();
              }
            : null,
        child: widget.enablePressAnimation
            ? AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: card,
              )
            : card,
      );
    }

    return card;
  }
}
