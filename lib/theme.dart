import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnweshanTheme {
  // Colors
  static const Color primaryDeep = Color(0xFF004B40); // Deep Forest
  static const Color secondaryGold =
      Color(0xFFFFC107); // Golden Harvest catchlight
  static const Color accentGoldDim = Color(0xFF785900); // Golden Harvest dark
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF3F4946);
  static const Color outline = Color(0xFF707976);

  // Spacing & Radius
  static const double spacingUnit = 8.0;
  static const double cardRadius = 32.0; // lg (2rem)
  static const double pillRadius = 999.0; // full

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDeep,
        primary: primaryDeep,
        secondary: secondaryGold,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
      ),
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 56, // 3.5rem
          fontWeight: FontWeight.bold,
          letterSpacing: -1.12,
          color: primaryDeep,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 28, // 1.75rem
          fontWeight: FontWeight.w600,
          color: primaryDeep,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16, // 1rem
          height: 1.6,
          color: onSurface,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 12, // 0.75rem
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6, // 0.05em
          color: onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEDEEEF), // surface-container
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDeep,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const Color darkBackground = Color(0xFF121212); // Standard Material Dark
    const Color darkSurface = Color(0xFF252525); // Material 3 Surface Container High
    const Color darkOnSurface = Colors.white;
    const Color darkOnSurfaceVariant = Color(0xFFAFBAC0); // Grey[400] approx

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDeep,
        brightness: Brightness.dark,
        primary: primaryDeep, // Brand Green
        secondary: secondaryGold,
        onPrimary: Colors.white,
        surface: darkSurface,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: outline,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.12,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          height: 1.6,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          color: darkOnSurfaceVariant,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: darkOnSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDeep,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryDeep,
        unselectedItemColor: darkOnSurfaceVariant,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDeep,
        foregroundColor: Colors.white,
      ),
    );
  }
}
