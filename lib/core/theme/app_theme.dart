import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Context-resolved helpers (used throughout the app) ────────────────────
  static Color sunAccent(BuildContext context) => const Color(0xFFE8392A);
  static Color windAccent(BuildContext context) => const Color(0xFF1A5CDB);

  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color border(BuildContext context) => Theme.of(context).dividerColor;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withAlpha(115);
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  // ── Editorial palette — Light ──────────────────────────────────────────────
  static const Color warmPaper     = Color(0xFFF0EDE8); // warm newsprint bg
  static const Color surfaceLight  = Color(0xFFFAF8F4);
  static const Color borderLight   = Color(0xFFDDDAD4);
  static const Color inkBlack      = Color(0xFF1A1A18); // primary text

  // ── Editorial palette — Dark ───────────────────────────────────────────────
  static const Color warmCharcoal  = Color(0xFF0E0D0B); // deep warm charcoal
  static const Color surfaceDark   = Color(0xFF191816);
  static const Color borderDark    = Color(0xFF2A2826);
  static const Color textPrimaryDark = Color(0xFFEDEBE6);

  // ── Per-tab hero accent — one per screen only ─────────────────────────────
  static const Color sunRed    = Color(0xFFE8392A);
  static const Color windBlue  = Color(0xFF1A5CDB);

  // ── Structural ────────────────────────────────────────────────────────────
  static const Color hairline    = Color(0x14000000); // 8% black, row dividers
  static const Color capsuleDark = Color(0xFF1A1A18); // dark primary capsule

  // ── Legacy constants — keep so seasonal_rose etc. don't break ─────────────
  static const Color summerCoral = Color(0xFFE8392A);
  static const Color monsoonTeal = Color(0xFF1A5CDB);
  static const Color calm        = Color(0xFF636366);
  static const Color moderate    = Color(0xFF1A5CDB);
  static const Color strong      = Color(0xFFE8392A);
}

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    backgroundColor: AppColors.warmPaper,
    surfaceColor: AppColors.surfaceLight,
    textColor: AppColors.inkBlack,
    borderColor: AppColors.borderLight,
    primaryColor: AppColors.sunRed,
    secondaryColor: AppColors.windBlue,
    errorColor: AppColors.sunRed,
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    backgroundColor: AppColors.warmCharcoal,
    surfaceColor: AppColors.surfaceDark,
    textColor: AppColors.textPrimaryDark,
    borderColor: AppColors.borderDark,
    primaryColor: AppColors.sunRed,
    secondaryColor: AppColors.windBlue,
    errorColor: AppColors.sunRed,
  );

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
      fontFamily: GoogleFonts.inter().fontFamily,
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
      cardTheme: const CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(0)),
          side: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: textColor,
        unselectedItemColor: textColor.withAlpha(89),
        elevation: 0,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textPrimary) {
    return TextTheme(
      // Hero display — Inter Light 72sp (Replaces Fraunces)
      // "Sun", "Wind", cardinal direction
      displayLarge: GoogleFonts.inter(
        fontSize: 72,
        fontWeight: FontWeight.w300,
        color: textPrimary,
        height: 0.95,
        letterSpacing: -2.0,
      ),
      // Sub-hero numerals — Inter Regular 36sp (Replaces Space Mono)
      displayMedium: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: -1.0,
      ),
      // Data row label — Inter SemiBold 12sp, tracked 1.8em
      titleLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 1.8,
      ),
      // Capsule label variant — slightly dimmed
      titleMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimary.withAlpha(178),
        letterSpacing: 1.8,
      ),
      // Body / explanation text — Inter Regular 14sp, generous leading
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textPrimary.withAlpha(150),
      ),
      // Micro labels — Inter SemiBold 11sp
      labelLarge: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textPrimary.withAlpha(150),
        letterSpacing: 1.2,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: textPrimary.withAlpha(120),
        letterSpacing: 1.0,
      ),
    );
  }
}
