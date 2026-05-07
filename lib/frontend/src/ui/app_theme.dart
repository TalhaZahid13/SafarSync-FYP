import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF050C1E);
  static const Color navyGlass = Color(0xCC050C1E);

  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF030213);
  // Recommendation Section Colors
  static const Color recommendationCardBg = Color(0xE6050C1E);
  static const Color recommendationBorder = Color(0xFF00A5EF);

  // Filter / Category Gradients
  static const LinearGradient natureGradient = LinearGradient(
    colors: [Color(0xFFFDB913), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient historyGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF5733)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient foodGradient = LinearGradient(
    colors: [Color(0xFFFF5733), Color(0xFFFDB913)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adventureGradient = LinearGradient(
    colors: [Color(0xFF00A5EF), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Recommendation Card Backgrounds
  static const Color natureCardBg = Color(0x4DFDB913);
  static const Color historyCardBg = Color(0x4DFF6B35);
  static const Color foodCardBg = Color(0x4DFF5733);
  static const Color adventureCardBg = Color(0x4D00A5EF);

  // Recommendation Borders
  static const Color natureBorder = Color(0xFFFDB913);
  static const Color historyBorder = Color(0xFFFF6B35);
  static const Color foodBorder = Color(0xFFFF5733);
  static const Color adventureBorder = Color(0xFF00A5EF);
  static const Color gold = Color(0xFFFDB913);
  static const Color coral = Color(0xFFFF6B35);
  static const Color cyan = Color(0xFF00A5EF);
  static const Color emerald = Color(0xFFFDB913);
  static const Color violet = Color(0xFFFF6B35);
  static const Color glassStrong = Color(0xE6050C1E);
  static const Color rose = Color(0xFFFF5733);
  static const Color teal = Color(0xFF00A5EF);
  static const Color pink = Color(0xFFFF5733);
  static const Color sky = Color(0xFF00A5EF);
  static const Color purple = Color(0xFFFF6B35);
  static const Color Rose = Color(0xFFFF5733);

  // ✅ Weather Card Colors
  static const Color weatherCardStart = Color(0xFF050C1E);
  static const Color weatherCardEnd = Color(0xFF030213);

  static const Color weatherBorder = Color(0xFF00A5EF);

  static const Color weatherTextPrimary = Colors.white;
  static const Color weatherTextSecondary = Color(0xFFCCCCCC);

  // ✅ 🔥 Weather Gradient (NEW)
  static const LinearGradient weatherCardGradient = LinearGradient(
    colors: [weatherCardStart, weatherCardEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient homeGradient = LinearGradient(
    colors: [gold, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ 🔥 Weather Decoration (IMPORTANT)
  static BoxDecoration weatherCardDecoration = BoxDecoration(
    gradient: weatherCardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: weatherBorder.withOpacity(0.35), width: 1),
    boxShadow: [
      BoxShadow(
        color: weatherBorder.withOpacity(0.15),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: coral,
      brightness: Brightness.light,
    ).copyWith(primary: coral, secondary: gold, surface: lightCard);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: coral, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
        labelStyle: const TextStyle(color: ink),
        prefixIconColor: coral,
        suffixIconColor: cyan,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: ink,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink),
        bodySmall: TextStyle(color: Color(0xFFCCCCCC)),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: coral),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coral,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: gold, width: 1),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x1A000000)),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: coral,
      brightness: Brightness.dark,
    ).copyWith(primary: coral, secondary: gold, surface: navy);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: navy,
      cardColor: navyGlass,
      cardTheme: CardThemeData(
        color: navyGlass,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cyan.withOpacity(0.35), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navyGlass,
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white),
        prefixIconColor: cyan,
        suffixIconColor: coral,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coral,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: gold, width: 1),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x26FFFFFF)),
    );
  }
}
