import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGold = Color(0xFFFFC83D);
  static const Color primaryTeal = Color(0xFF1E7A8C);
  static const Color accentSky = Color(0xFF5BC0EB);
  static const Color ink = Color(0xFF102A43);
  static const Color softCream = Color(0xFFFFF8E8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0F172A);

  static ThemeData lightTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryTeal,
          brightness: Brightness.light,
        ).copyWith(
          primary: primaryTeal,
          secondary: primaryGold,
          surface: surfaceLight,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7FBFF),
      cardColor: surfaceLight,
      cardTheme: const CardTheme(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        hintStyle: const TextStyle(color: Color(0xFF52606D)),
        labelStyle: const TextStyle(color: ink),
        prefixIconColor: primaryTeal,
        suffixIconColor: primaryTeal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0)),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFF7FBFF),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Color(0xFFF7FBFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7FBFF),
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: primaryTeal),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink),
        bodySmall: TextStyle(color: Color(0xFF52606D)),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryGold,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primaryGold,
          secondary: primaryTeal,
          surface: surfaceDark,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      cardColor: const Color(0xFF162233),
      cardTheme: const CardTheme(
        color: Color(0xFF162233),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF162233),
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white),
        prefixIconColor: primaryGold,
        suffixIconColor: primaryGold,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF334155)),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0B1220),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Color(0xFF0B1220),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B1220),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: primaryGold),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
    );
  }
}
