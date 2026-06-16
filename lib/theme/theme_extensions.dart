import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'design_tokens.dart';

// ─── Card Style Extension ───────────────────────────────────────────────────

class AppCardStyle extends ThemeExtension<AppCardStyle> {
  final Color background;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  const AppCardStyle({
    required this.background,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.shadows,
  });

  // Light theme card
  static AppCardStyle get light => AppCardStyle(
    background: Colors.white,
    borderColor: Colors.transparent,
    borderWidth: 0,
    borderRadius: AppRadius.xl,
    shadows: AppShadows.medium,
  );

  // Dark theme card
  static AppCardStyle get dark => AppCardStyle(
    background: AppColors.slate800,
    borderColor: Colors.transparent,
    borderWidth: 0,
    borderRadius: AppRadius.xl,
    shadows: AppShadows.subtle,
  );

  // Black minimalism card
  static AppCardStyle get black => AppCardStyle(
    background: const Color(0xFF0A0A0A),
    borderColor: Colors.white10,
    borderWidth: 1,
    borderRadius: AppRadius.lg,
    shadows: const [],
  );

  BoxDecoration get decoration => BoxDecoration(
    color: background,
    borderRadius: borderRadius,
    border: borderWidth > 0
        ? Border.all(color: borderColor, width: borderWidth)
        : null,
    boxShadow: shadows.isNotEmpty ? shadows : null,
  );

  @override
  AppCardStyle copyWith({
    Color? background,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return AppCardStyle(
      background: background ?? this.background,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  AppCardStyle lerp(ThemeExtension<AppCardStyle>? other, double t) {
    if (other is! AppCardStyle) return this;
    return AppCardStyle(
      background: Color.lerp(background, other.background, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t)!,
      shadows: shadows, // BoxShadow lerp is complex; snap
    );
  }
}

// ─── Page Gradient Extension ────────────────────────────────────────────────

class AppPageStyle extends ThemeExtension<AppPageStyle> {
  final LinearGradient? pageGradient;
  final Color? pageColor;
  final Color sectionHeaderColor;
  final Color subtitleColor;
  final Color iconAccentColor;
  final Color iconBackgroundColor;

  const AppPageStyle({
    this.pageGradient,
    this.pageColor,
    required this.sectionHeaderColor,
    required this.subtitleColor,
    required this.iconAccentColor,
    required this.iconBackgroundColor,
  });

  static AppPageStyle get light => AppPageStyle(
    pageGradient: AppGradients.pageLight,
    sectionHeaderColor: AppColors.slate900,
    subtitleColor: AppColors.slate500,
    iconAccentColor: AppColors.lavender400,
    iconBackgroundColor: AppColors.lavender400.withValues(alpha: 0.15),
  );

  static AppPageStyle get dark => AppPageStyle(
    pageGradient: AppGradients.pageDark,
    sectionHeaderColor: AppColors.slate100,
    subtitleColor: AppColors.slate400,
    iconAccentColor: AppColors.lavender400,
    iconBackgroundColor: AppColors.lavender400.withValues(alpha: 0.15),
  );

  static AppPageStyle get black => const AppPageStyle(
    pageGradient: AppGradients.pageBlack,
    pageColor: Colors.black,
    sectionHeaderColor: Colors.white70,
    subtitleColor: Colors.white38,
    iconAccentColor: Colors.white,
    iconBackgroundColor: Colors.white12,
  );

  /// Convenience: returns a BoxDecoration for page backgrounds
  BoxDecoration get backgroundDecoration =>
      BoxDecoration(gradient: pageGradient, color: pageColor);

  @override
  AppPageStyle copyWith({
    LinearGradient? pageGradient,
    Color? pageColor,
    Color? sectionHeaderColor,
    Color? subtitleColor,
    Color? iconAccentColor,
    Color? iconBackgroundColor,
  }) {
    return AppPageStyle(
      pageGradient: pageGradient ?? this.pageGradient,
      pageColor: pageColor ?? this.pageColor,
      sectionHeaderColor: sectionHeaderColor ?? this.sectionHeaderColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      iconAccentColor: iconAccentColor ?? this.iconAccentColor,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
    );
  }

  @override
  AppPageStyle lerp(ThemeExtension<AppPageStyle>? other, double t) {
    if (other is! AppPageStyle) return this;
    return AppPageStyle(
      pageGradient: pageGradient,
      pageColor: Color.lerp(pageColor, other.pageColor, t),
      sectionHeaderColor: Color.lerp(
        sectionHeaderColor,
        other.sectionHeaderColor,
        t,
      )!,
      subtitleColor: Color.lerp(subtitleColor, other.subtitleColor, t)!,
      iconAccentColor: Color.lerp(iconAccentColor, other.iconAccentColor, t)!,
      iconBackgroundColor: Color.lerp(
        iconBackgroundColor,
        other.iconBackgroundColor,
        t,
      )!,
    );
  }
}

// ─── Nav Bar Style Extension ────────────────────────────────────────────────

class AppNavStyle extends ThemeExtension<AppNavStyle> {
  final Color barBackground;
  final Color barBorderColor;
  final Color selectedLabelColor;
  final Color unselectedLabelColor;
  final LinearGradient selectedIndicatorGradient;

  const AppNavStyle({
    required this.barBackground,
    required this.barBorderColor,
    required this.selectedLabelColor,
    required this.unselectedLabelColor,
    required this.selectedIndicatorGradient,
  });

  static AppNavStyle get light => AppNavStyle(
    barBackground: Colors.white.withValues(alpha: 0.92),
    barBorderColor: AppColors.slate200.withValues(alpha: 0.3),
    selectedLabelColor: AppColors.lavender500,
    unselectedLabelColor: AppColors.slate400,
    selectedIndicatorGradient: const LinearGradient(
      colors: [AppColors.lavender100, AppColors.blue100],
    ),
  );

  static AppNavStyle get dark => AppNavStyle(
    barBackground: AppColors.slate900.withValues(alpha: 0.92),
    barBorderColor: AppColors.slate700.withValues(alpha: 0.3),
    selectedLabelColor: AppColors.lavender400,
    unselectedLabelColor: AppColors.slate500,
    selectedIndicatorGradient: LinearGradient(
      colors: [
        AppColors.lavender400.withValues(alpha: 0.2),
        AppColors.blue400.withValues(alpha: 0.1),
      ],
    ),
  );

  static AppNavStyle get black => AppNavStyle(
    barBackground: Colors.black.withValues(alpha: 0.95),
    barBorderColor: Colors.white10,
    selectedLabelColor: Colors.white,
    unselectedLabelColor: Colors.white38,
    selectedIndicatorGradient: const LinearGradient(
      colors: [Colors.white12, Colors.white10],
    ),
  );

  @override
  AppNavStyle copyWith({
    Color? barBackground,
    Color? barBorderColor,
    Color? selectedLabelColor,
    Color? unselectedLabelColor,
    LinearGradient? selectedIndicatorGradient,
  }) {
    return AppNavStyle(
      barBackground: barBackground ?? this.barBackground,
      barBorderColor: barBorderColor ?? this.barBorderColor,
      selectedLabelColor: selectedLabelColor ?? this.selectedLabelColor,
      unselectedLabelColor: unselectedLabelColor ?? this.unselectedLabelColor,
      selectedIndicatorGradient:
          selectedIndicatorGradient ?? this.selectedIndicatorGradient,
    );
  }

  @override
  AppNavStyle lerp(ThemeExtension<AppNavStyle>? other, double t) {
    if (other is! AppNavStyle) return this;
    return AppNavStyle(
      barBackground: Color.lerp(barBackground, other.barBackground, t)!,
      barBorderColor: Color.lerp(barBorderColor, other.barBorderColor, t)!,
      selectedLabelColor: Color.lerp(
        selectedLabelColor,
        other.selectedLabelColor,
        t,
      )!,
      unselectedLabelColor: Color.lerp(
        unselectedLabelColor,
        other.unselectedLabelColor,
        t,
      )!,
      selectedIndicatorGradient: selectedIndicatorGradient,
    );
  }
}
