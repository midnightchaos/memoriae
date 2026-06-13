import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';

/// Wraps a screen body with themed gradient background, SafeArea,
/// and optional staggered entrance animation for children.
///
/// Eliminates the repeated gradient Container + SafeArea boilerplate
/// from every screen in the app.
class AnimatedPageWrapper extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final EdgeInsets? padding;

  const AnimatedPageWrapper({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    Widget body = child;

    if (padding != null) {
      body = Padding(padding: padding!, child: body);
    }

    if (useSafeArea) {
      body = SafeArea(child: body);
    }

    return Container(
      decoration: pageStyle.backgroundDecoration,
      child: body,
    );
  }
}

/// Animates a child widget with a staggered fade + slide entrance.
/// Use inside lists or columns to create cascading entrance effects.
class StaggeredEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDuration;
  final Duration staggerDelay;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDuration = const Duration(milliseconds: 500),
    this.staggerDelay = const Duration(milliseconds: 60),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: baseDuration + staggerDelay * index,
      curve: AppCurves.entrance,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
