import 'package:flutter/material.dart';

/// App-wide colors and Material themes.
///
/// The brand accent (historically a single turquoise used under many names)
/// is *dynamic*: it follows the user's active destination theme
/// (see `DestinationThemeProvider`). Neutral colors (text, greys, whites)
/// are fixed. Call [applyAccent] — the provider does this — and every
/// accent getter below, plus [lightTheme]/[darkTheme], picks it up.
class AppTheme {
  AppTheme._();

  // ── Dynamic accent (destination theme) ──────────────────────────────────
  static const Color defaultAccent = Color(0xFF2CAFBC);
  static const Color defaultAccentTint = Color(0xFFDCEEF0);

  static Color _accent = defaultAccent;
  static Color _accentTint = defaultAccentTint;
  static Color? _scaffoldTint; // light-mode page background, null = white

  /// Sets the accent used by every accent getter and the Material themes.
  static void applyAccent({
    required Color accent,
    required Color tint,
    Color? lightBackground,
  }) {
    _accent = accent;
    _accentTint = tint;
    _scaffoldTint = lightBackground;
  }

  // Primary Brand Colors
  static Color get turquoise => _accent;
  static const Color darkSlate = Color(0xFF404745);
  static const Color mediumGray = Color(0xFF9A9E9D);
  static Color get lightGray => _accentTint;
  static const Color offWhite = Color(0xFFEAEBEC);
  static const Color veryLightGray = Color(0xFFEFEFEF);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Legacy colors for compatibility (mapped to new scheme)
  static const Color navy = Color(0xFFFFFFFF);
  static const Color navyGlass = Color(0xCCFFFFFF);

  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF404745);
  // Recommendation Section Colors
  static const Color recommendationCardBg = Color(0xE6EAEBEC);
  static Color get recommendationBorder => _accent;

  // Filter / Category Gradients (bright scheme)
  static LinearGradient get natureGradient => LinearGradient(
    colors: [_accent, mediumGray],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get historyGradient => LinearGradient(
    colors: [_accent, _accentTint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get foodGradient => LinearGradient(
    colors: [darkSlate, _accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get adventureGradient => LinearGradient(
    colors: [_accent, darkSlate],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Recommendation Card Backgrounds
  static Color get natureCardBg => _accent.withAlpha(0x4D);
  static Color get historyCardBg => _accentTint.withAlpha(0x4D);
  static const Color foodCardBg = Color(0x4D404745);
  static const Color adventureCardBg = Color(0x4D9A9E9D);

  // Recommendation Borders
  static Color get natureBorder => _accent;
  static Color get historyBorder => _accentTint;
  static const Color foodBorder = Color(0xFF404745);
  static Color get adventureBorder => _accent;
  static Color get gold => _accent;
  static Color get coral => _accent;
  static Color get cyan => _accent;
  static const Color emerald = Color(0xFF9A9E9D);
  static const Color violet = Color(0xFF404745);
  static const Color glassStrong = Color(0xCCFFFFFF);
  static Color get rose => _accent;
  static Color get teal => _accent;
  static Color get pink => _accentTint;
  static Color get sky => _accent;
  static const Color purple = Color(0xFF404745);

  // ✅ Weather Card Colors (bright scheme)
  static const Color weatherCardStart = Color(0xFFEAEBEC);
  static const Color weatherCardEnd = Color(0xFFFFFFFF);

  static Color get weatherBorder => _accent;

  static const Color weatherTextPrimary = Color(0xFF404745);
  static const Color weatherTextSecondary = Color(0xFF9A9E9D);

  // ✅ 🔥 Weather Gradient (bright)
  static const LinearGradient weatherCardGradient = LinearGradient(
    colors: [weatherCardStart, weatherCardEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get homeGradient => LinearGradient(
    colors: [_accent, offWhite],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ 🔥 Weather Decoration (IMPORTANT)
  static BoxDecoration get weatherCardDecoration => BoxDecoration(
    gradient: weatherCardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: weatherBorder.withValues(alpha: 0.35), width: 1),
    boxShadow: [
      BoxShadow(
        color: weatherBorder.withValues(alpha: 0.15),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static ThemeData lightTheme() {
    final accent = _accent;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ).copyWith(primary: accent, secondary: mediumGray, surface: pureWhite);
    final scaffold = _scaffoldTint ?? pureWhite;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      cardColor: pureWhite,
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: veryLightGray, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: offWhite,
        hintStyle: const TextStyle(color: mediumGray),
        labelStyle: const TextStyle(color: darkSlate),
        prefixIconColor: accent,
        suffixIconColor: accent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: veryLightGray, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: darkSlate,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: darkSlate),
        bodySmall: TextStyle(color: mediumGray),
        titleLarge: TextStyle(color: darkSlate, fontWeight: FontWeight.bold),
      ),
      iconTheme: IconThemeData(color: accent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: accent, width: 1),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: veryLightGray),
    );
  }

  static ThemeData darkTheme() {
    final accent = _accent;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(primary: accent, secondary: mediumGray, surface: offWhite);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pureWhite,
      cardColor: offWhite,
      cardTheme: CardThemeData(
        color: offWhite,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: veryLightGray.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGray,
        hintStyle: const TextStyle(color: mediumGray),
        labelStyle: const TextStyle(color: darkSlate),
        prefixIconColor: accent,
        suffixIconColor: accent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pureWhite,
        foregroundColor: darkSlate,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: darkSlate),
        bodySmall: TextStyle(color: mediumGray),
        titleLarge: TextStyle(color: darkSlate, fontWeight: FontWeight.bold),
      ),
      iconTheme: IconThemeData(color: accent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: accent, width: 1),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: veryLightGray),
    );
  }
}
