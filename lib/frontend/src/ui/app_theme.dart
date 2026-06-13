import 'package:flutter/material.dart';

class AppTheme {
  // Primary Brand Colors
  static const Color turquoise = Color(0xFF2CAFBC);
  static const Color darkSlate = Color(0xFF404745);
  static const Color mediumGray = Color(0xFF9A9E9D);
  static const Color lightGray = Color(0xFFDCEEF0);
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
  static const Color recommendationBorder = Color(0xFF2CAFBC);

  // Filter / Category Gradients (bright scheme)
  static const LinearGradient natureGradient = LinearGradient(
    colors: [Color(0xFF2CAFBC), Color(0xFF9A9E9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient historyGradient = LinearGradient(
    colors: [Color(0xFF2CAFBC), Color(0xFFDCEEF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient foodGradient = LinearGradient(
    colors: [Color(0xFF404745), Color(0xFF2CAFBC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adventureGradient = LinearGradient(
    colors: [Color(0xFF2CAFBC), Color(0xFF404745)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Recommendation Card Backgrounds
  static const Color natureCardBg = Color(0x4D2CAFBC);
  static const Color historyCardBg = Color(0x4DDCEEF0);
  static const Color foodCardBg = Color(0x4D404745);
  static const Color adventureCardBg = Color(0x4D9A9E9D);

  // Recommendation Borders
  static const Color natureBorder = Color(0xFF2CAFBC);
  static const Color historyBorder = Color(0xFFDCEEF0);
  static const Color foodBorder = Color(0xFF404745);
  static const Color adventureBorder = Color(0xFF2CAFBC);
  static const Color gold = Color(0xFF2CAFBC);
  static const Color coral = Color(0xFF2CAFBC);
  static const Color cyan = Color(0xFF2CAFBC);
  static const Color emerald = Color(0xFF9A9E9D);
  static const Color violet = Color(0xFF404745);
  static const Color glassStrong = Color(0xCCFFFFFF);
  static const Color rose = Color(0xFF2CAFBC);
  static const Color teal = Color(0xFF2CAFBC);
  static const Color pink = Color(0xFFDCEEF0);
  static const Color sky = Color(0xFF2CAFBC);
  static const Color purple = Color(0xFF404745);
  static const Color Rose = Color(0xFF2CAFBC);

  // ✅ Weather Card Colors (bright scheme)
  static const Color weatherCardStart = Color(0xFFEAEBEC);
  static const Color weatherCardEnd = Color(0xFFFFFFFF);

  static const Color weatherBorder = Color(0xFF2CAFBC);

  static const Color weatherTextPrimary = Color(0xFF404745);
  static const Color weatherTextSecondary = Color(0xFF9A9E9D);

  // ✅ 🔥 Weather Gradient (bright)
  static const LinearGradient weatherCardGradient = LinearGradient(
    colors: [weatherCardStart, weatherCardEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient homeGradient = LinearGradient(
    colors: [turquoise, offWhite],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ 🔥 Weather Decoration (IMPORTANT)
  static BoxDecoration weatherCardDecoration = BoxDecoration(
    gradient: weatherCardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: weatherBorder.withValues(alpha:0.35), width: 1),
    boxShadow: [
      BoxShadow(
        color: weatherBorder.withValues(alpha:0.15),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: turquoise,
      brightness: Brightness.light,
    ).copyWith(primary: turquoise, secondary: mediumGray, surface: pureWhite);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pureWhite,
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
        prefixIconColor: turquoise,
        suffixIconColor: turquoise,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: veryLightGray, width: 1),
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
      iconTheme: const IconThemeData(color: turquoise),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: turquoise,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: turquoise, width: 1),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: veryLightGray),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: turquoise,
      brightness: Brightness.dark,
    ).copyWith(primary: turquoise, secondary: mediumGray, surface: offWhite);

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
          side: BorderSide(color: veryLightGray.withValues(alpha:0.5), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGray,
        hintStyle: const TextStyle(color: mediumGray),
        labelStyle: const TextStyle(color: darkSlate),
        prefixIconColor: turquoise,
        suffixIconColor: turquoise,
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
      iconTheme: const IconThemeData(color: turquoise),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: turquoise,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: turquoise, width: 1),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: veryLightGray),
    );
  }
}
