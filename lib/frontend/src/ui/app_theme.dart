import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF0B1220);
  static const Color navyGlass = Color(0xCC0F172A);

  static const Color lightBg = Color(0xFFF7FBFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF102A43);
  // Recommendation Section Colors
  static const Color recommendationCardBg = Color(0xE60F172A);
  static const Color recommendationBorder = Color(0xFF334155);

  // Filter / Category Gradients
  static const LinearGradient natureGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient historyGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF9333EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient foodGradient = LinearGradient(
    colors: [Color(0xFFFF006E), Color(0xFFFF3D7F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adventureGradient = LinearGradient(
    colors: [Color(0xFFFF7A1A), Color(0xFFFF5A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Recommendation Card Backgrounds
  static const Color natureCardBg = Color(0xCC063A4A);
  static const Color historyCardBg = Color(0xCC1F1B5C);
  static const Color foodCardBg = Color(0xCC32123F);
  static const Color adventureCardBg = Color(0xCC3A2A2F);

  // Recommendation Borders
  static const Color natureBorder = Color(0xFF00BFA6);
  static const Color historyBorder = Color(0xFF5B4BDB);
  static const Color foodBorder = Color(0xFFFF2D75);
  static const Color adventureBorder = Color(0xFFFF7A1A);
  static const Color gold = Color(0xFFFFC83D);
  static const Color coral = Color(0xFFFF6B4A);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color emerald = Color(0xFF10B981);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color glassStrong = Color(0xE60F172A);
  static const Color rose = Color(0xFFFF3D7F);
  static const Color teal = Color(0xFF14B8A6);
  static const Color pink = Color(0xFFEC4899);
  static const Color sky = Color(0xFF38BDF8);
  static const Color purple = Color(0xFF9333EA);
  static const Color Rose = Color(0xFFFF3D7F);

  // ✅ Weather Card Colors
  static const Color weatherCardStart = Color(0xFF0F1B3D);
  static const Color weatherCardEnd = Color(0xFF0A1430);

  static const Color weatherBorder = Color(0xFF3B82F6);

  static const Color weatherTextPrimary = Colors.white;
  static const Color weatherTextSecondary = Color(0xFF9CA3AF);

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
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
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
        bodySmall: TextStyle(color: Color(0xFF64748B)),
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
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0)),
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
      dividerTheme: const DividerThemeData(color: Color(0xFF334155)),
    );
  }
}
