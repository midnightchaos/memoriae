import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_extensions.dart';
import 'design_tokens.dart';

class AppColors {
  AppColors._();

  // Primary — Warm Lavender (dominant color story)
  static const lavender50 = Color(0xFFF5F3FF);
  static const lavender100 = Color(0xFFEDE9FE);
  static const lavender200 = Color(0xFFDDD6FE);
  static const lavender400 = Color(0xFFA78BFA);
  static const lavender500 = Color(0xFF8B5CF6);
  static const lavender900 = Color(0xFF4C1D95);

  // Accent — Soft Blues
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue400 = Color(0xFF60A5FA);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1E40AF);

  // Success — Emerald
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);

  // Warm accents
  static const peach50 = Color(0xFFFEF2F2);
  static const peach100 = Color(0xFFFEE2E2);
  static const peach400 = Color(0xFFFB923C);
  static const rose50 = Color(0xFFFFF1F8);
  static const rose400 = Color(0xFFFB7185);

  // Error/Alert
  static const coral50 = Color(0xFFFFF1F0);
  static const coral100 = Color(0xFFFFDAD5);
  static const coral400 = Color(0xFFF87171);
  static const coral500 = Color(0xFFFF6B57);
  static const coral600 = Color(0xFFE85A48);

  // Mint — Therapy/Calm
  static const mint50 = Color(0xFFF0FDF4);
  static const mint100 = Color(0xFFDCFCE7);
  static const mint400 = Color(0xFF4ADE80);
  static const mint500 = Color(0xFF22C55E);
  static const mint600 = Color(0xFF16A34A);
  static const mint700 = Color(0xFF15803D);

  // Teal — Secondary accent
  static const teal100 = Color(0xFFCCFBF1);
  static const teal400 = Color(0xFF2DD4BF);
  static const teal500 = Color(0xFF14B8A6);
  static const teal800 = Color(0xFF115E59);

  // Supplementary
  static const cyan100 = Color(0xFFCCF2F5);
  static const cyan400 = Color(0xFF22D3EE);
  static const purple400 = Color(0xFFB084F8);
  static const amber400 = Color(0xFFFBBF24);

  // Neutrals — Warm Slate
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  // Cream
  static const cream50 = Color(0xFFFFFBEB);

  // Named gradients
  static const calmGradient = [
    Color(0xFFF5F3FF),
    Color(0xFFEFF6FF),
    Color(0xFFECFDF5),
  ];

  static const lavenderGradient = [Color(0xFFEDE9FE), Color(0xFFFEE2E2)];

  static const tealGradient = [
    Color(0xFF14B8A6),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
  ];
}

// ─── Typography ─────────────────────────────────────────────────────────────

class AppTypography {
  AppTypography._();

  /// Display font — warm serif, premium feel
  static String get displayFamily => 'Playfair Display';

  /// Body font — clean, highly readable
  static String get bodyFamily => 'DM Sans';

  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primary = isLight ? AppColors.slate900 : AppColors.slate100;
    final secondary = isLight ? AppColors.slate700 : AppColors.slate300;
    final tertiary = isLight ? AppColors.slate600 : AppColors.slate400;

    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: primary,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: primary,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.3,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: secondary,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: secondary,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: tertiary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: tertiary,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tertiary,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Black Minimalism uses ultra-thin weights for a stark, editorial feel
  static TextTheme get blackTextTheme {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        color: Colors.white,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w300,
        color: Colors.white,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w300,
        color: Colors.white,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: 0.5,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: 0.5,
        height: 1.3,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w300,
        color: Colors.white,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        color: Colors.white70,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: Colors.white60,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.white54,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Theme Data ─────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = AppTypography._buildTextTheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream50,
      colorScheme: ColorScheme.light(
        primary: AppColors.lavender500,
        secondary: AppColors.teal500,
        surface: Colors.white,
        error: AppColors.coral400,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.slate700),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xxl),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xxl),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lavender500,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
      ),
      extensions: [AppCardStyle.light, AppPageStyle.light, AppNavStyle.light],
    );
  }

  static ThemeData get darkTheme {
    final textTheme = AppTypography._buildTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.slate900,
      colorScheme: ColorScheme.dark(
        primary: AppColors.lavender400,
        secondary: AppColors.teal400,
        surface: AppColors.slate800,
        error: AppColors.coral400,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.slate200),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xxl),
        color: AppColors.slate800,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xxl),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lavender400,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
      ),
      extensions: [AppCardStyle.dark, AppPageStyle.dark, AppNavStyle.dark],
    );
  }

  static ThemeData get blackMinimalismTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: AppColors.slate400,
        surface: Color(0xFF121212),
        error: AppColors.coral400,
      ),
      textTheme: AppTypography.blackTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTypography.blackTextTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
        ),
        color: const Color(0xFF0A0A0A),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
          textStyle: AppTypography.blackTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white38),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),
      extensions: [AppCardStyle.black, AppPageStyle.black, AppNavStyle.black],
    );
  }
}
