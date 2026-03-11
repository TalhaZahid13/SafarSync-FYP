// utils/theme_manager.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';

class ThemeManager {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    primarySwatch: _createMaterialColor(AppColors.primary),
    scaffoldBackgroundColor: AppColors.lightBackground,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 1,
      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.lightCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightBackground,
      hintStyle: GoogleFonts.poppins(color: AppColors.lightTextHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightBackground,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      displayMedium: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      displaySmall: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      headlineLarge: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      headlineMedium: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      headlineSmall: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      titleLarge: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      titleMedium: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      titleSmall: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      bodyLarge: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      bodyMedium: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      bodySmall: GoogleFonts.poppins(color: AppColors.lightTextSecondary),
      labelLarge: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      labelMedium: GoogleFonts.poppins(color: AppColors.lightTextPrimary),
      labelSmall: GoogleFonts.poppins(color: AppColors.lightTextSecondary),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    primarySwatch: _createMaterialColor(AppColors.primary),
    scaffoldBackgroundColor: AppColors.darkBackground,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 1,
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkCardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      hintStyle: GoogleFonts.poppins(color: AppColors.darkTextHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      displayMedium: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      displaySmall: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      headlineLarge: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      headlineMedium: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      headlineSmall: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      titleLarge: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      titleMedium: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      titleSmall: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      bodyLarge: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      bodyMedium: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      bodySmall: GoogleFonts.poppins(color: AppColors.darkTextSecondary),
      labelLarge: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      labelMedium: GoogleFonts.poppins(color: AppColors.darkTextPrimary),
      labelSmall: GoogleFonts.poppins(color: AppColors.darkTextSecondary),
    ),
  );

  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
