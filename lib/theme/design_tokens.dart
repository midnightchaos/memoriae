import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Spacing rhythm — 4px base grid
class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

/// Border radius tokens
class AppRadius {
  AppRadius._();
  static final sm = BorderRadius.circular(8);
  static final md = BorderRadius.circular(12);
  static final lg = BorderRadius.circular(16);
  static final xl = BorderRadius.circular(20);
  static final xxl = BorderRadius.circular(24);
  static final pill = BorderRadius.circular(100);
}

/// Shadow presets
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glowWith(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Gradient presets
class AppGradients {
  AppGradients._();

  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.lavender400, AppColors.teal400],
  );

  static const warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.lavender100, AppColors.peach100],
  );

  static const warmDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D1B69), Color(0xFF1A1A2E)],
  );

  static const glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33FFFFFF), Color(0x0DFFFFFF)],
  );

  static const glassDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1AFFFFFF), Color(0x05FFFFFF)],
  );

  /// Page backgrounds
  static const pageLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cream50, AppColors.lavender50, AppColors.mint50],
  );

  static const pageDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  static const pageBlack = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.black, Color(0xFF0A0A0A), Colors.black],
  );
}

/// Animation durations — gentle for elderly users
class AppDurations {
  AppDurations._();
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 500);
  static const entrance = Duration(milliseconds: 600);
  static const pageTransition = Duration(milliseconds: 400);
}

/// Animation curves
class AppCurves {
  AppCurves._();
  static const entrance = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const bounce = Curves.easeOutBack;
  static const smooth = Curves.easeInOutCubic;
}
