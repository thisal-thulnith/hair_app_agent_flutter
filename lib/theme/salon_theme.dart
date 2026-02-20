import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional Buff Salon Theme
/// Premium beauty salon color palette and design system
class SalonTheme {
  // Brand Colors - Luxury Beauty Salon Palette
  static const Color primaryGold = Color(0xFFD4AF37); // Luxurious gold
  static const Color primaryRose = Color(0xFFFF6B9D); // Rose pink
  static const Color deepPurple = Color(0xFF6B4E71); // Deep purple
  static const Color softCream = Color(0xFFFFF8F0); // Soft cream
  static const Color darkNavy = Color(0xFF1A1A2E); // Dark navy
  static const Color charcoal = Color(0xFF2D2D3A); // Charcoal
  static const Color lightGray = Color(0xFFF5F5F7); // Light gray
  static const Color accentCoral = Color(0xFFFF8E9E); // Coral accent

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF8E9E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6B4E71), Color(0xFF8B6F8F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D3A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Text Styles using Professional Fonts
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      color: darkNavy,
      letterSpacing: -1,
      height: 1.1,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: darkNavy,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: darkNavy,
      height: 1.3,
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: darkNavy,
      letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: darkNavy,
      letterSpacing: -0.2,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: darkNavy,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      color: charcoal,
      height: 1.6,
      letterSpacing: 0.1,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      color: charcoal,
      height: 1.5,
      letterSpacing: 0.1,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      color: Color(0xFF6B6B7B),
      height: 1.4,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  );

  // Dark Theme (for dark mode)
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: -1,
      height: 1.1,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.3,
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: -0.2,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      color: Color(0xFFE5E5EA),
      height: 1.6,
      letterSpacing: 0.1,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      color: Color(0xFFD1D1D6),
      height: 1.5,
      letterSpacing: 0.1,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      color: Color(0xFFAEAEB2),
      height: 1.4,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryGold,
      secondary: primaryRose,
      tertiary: deepPurple,
      surface: Colors.white,
      background: softCream,
      error: Color(0xFFDC2626),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkNavy,
      onBackground: charcoal,
    ),
    scaffoldBackgroundColor: softCream,
    cardColor: Colors.white,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: darkNavy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkNavy,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFE5E5EA), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFE5E5EA), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryGold, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: Color(0xFF8E8E93),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryGold,
      secondary: primaryRose,
      tertiary: deepPurple,
      surface: charcoal,
      background: darkNavy,
      error: Color(0xFFEF4444),
      onPrimary: darkNavy,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Color(0xFFE5E5EA),
    ),
    scaffoldBackgroundColor: darkNavy,
    cardColor: charcoal,
    textTheme: darkTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: darkNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: darkNavy,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2D2D3A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF3D3D4A), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF3D3D4A), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryGold, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: Color(0xFF8E8E93),
      ),
    ),
    cardTheme: CardTheme(
      color: charcoal,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  // Common shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  // Gold glow effect
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: primaryGold.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // Rose glow effect
  static List<BoxShadow> roseGlow = [
    BoxShadow(
      color: primaryRose.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}
