import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Shared / Accent colors
  static Color sunAccent(BuildContext context) => const Color(0xFFE64D2E);
  static Color windAccent(BuildContext context) => const Color(0xFF2E7BFF);

  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color border(BuildContext context) => Theme.of(context).dividerColor;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withAlpha(115); // 45%
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  // Structural (Dark) - Precision Instrument OLED
  static const Color backgroundDark = Color(0xFF0A0A0B);
  static const Color surfaceDark = Color(0xFF141517);
  static const Color borderDark = Color(0xFF1B1C1E);
  static const Color textPrimaryDark = Color(0xFFEDEDED);

  // Structural (Light) - Architectural Warm
  static const Color backgroundLight = Color(0xFFF4F3EF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE0DFD8);
  static const Color textPrimaryLight = Color(0xFF1C1C1A);

  // Seasonal constants - now mapped to monochrome to follow Dieter Rams "Earn your color" rule #2
  // We keep them so that the map in seasonal_rose doesn't break conceptually, but they render minimally.
  static const Color summerCoral = Color(0xFFE64D2E);
  static const Color monsoonTeal = Color(0xFF2E7BFF);

  // Status colors mapped to minimalist aesthetics
  static const Color calm = Color(0xFF636366); // Monochrome
  static const Color moderate = Color(0xFF2E7BFF); // Blueprint
  static const Color strong = Color(0xFFE64D2E); // Vermilion
}

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      backgroundColor: AppColors.backgroundLight,
      surfaceColor: AppColors.surfaceLight,
      textColor: AppColors.textPrimaryLight,
      borderColor: AppColors.borderLight,
      primaryColor: const Color(0xFFE64D2E),
      secondaryColor: const Color(0xFF2E7BFF),
      errorColor: const Color(0xFFE64D2E),
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      backgroundColor: AppColors.backgroundDark,
      surfaceColor: AppColors.surfaceDark,
      textColor: AppColors.textPrimaryDark,
      borderColor: AppColors.borderDark,
      primaryColor: const Color(0xFFE64D2E),
      secondaryColor: const Color(0xFF2E7BFF),
      errorColor: const Color(0xFFE64D2E),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color textColor,
    required Color borderColor,
    required Color primaryColor,
    required Color secondaryColor,
    required Color errorColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: backgroundColor,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      dividerTheme: DividerThemeData(
        thickness: 0.5,
        color: borderColor,
        space: 1,
      ),
      dividerColor: borderColor,
      textTheme: _buildTextTheme(textColor),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(0)),
          side: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: textColor,
        unselectedItemColor: textColor.withAlpha(115),
        elevation: 0,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textPrimary) {
    return TextTheme(
      // Primary Data (Space Mono, large, full opacity)
      displayLarge: GoogleFonts.spaceMono(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.spaceMono(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      // Section Headers (Inter Medium, 13sp, 0.08em letter spacing, 70% op)
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.02,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textPrimary.withAlpha(178), // ~70%
        letterSpacing: 1.04,
      ),
      // Body (Inter Regular, NEVER bold for body)
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textPrimary.withAlpha(115),
      ),
      // Secondary Labels (Inter, 11sp, 0.12em letter spacing, 45% op)
      labelLarge: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textPrimary.withAlpha(115), // ~45%
        letterSpacing: 1.32,
      ),
      // Coordinates / Micro Data (Space Mono, small)
      labelSmall: GoogleFonts.spaceMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: textPrimary.withAlpha(115),
      ),
    );
  }
}
