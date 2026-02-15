import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Light Theme Colors ─── Pearl & Rose Gold ───
  static const Color pearl = Color(0xFFF8F5F0);       // Warm ivory
  static const Color pearlSurface = Color(0xFFFFFFFF); // Pure white cards
  static const Color pearlMuted = Color(0xFFEDE8E1);   // Muted pearl accents
  static const Color textDark = Color(0xFF2D2A26);     // Warm dark text

  // ─── Dark Theme Colors ─── Deep Plum & Gold ───
  static const Color charcoal = Color(0xFF0E0B14);      // Deep purple-black
  static const Color charcoalSurface = Color(0xFF1A1625); // Dark purple surface
  static const Color charcoalMuted = Color(0xFF2A2535);   // Muted dark accent
  static const Color textLight = Color(0xFFF0ECE5);       // Warm cream text

  // ─── Accent Colors (shared) ───
  static const Color gold = Color(0xFFD4A856);            // Warm salon gold
  static const Color goldDim = Color(0xFFB8923E);         // Subdued gold
  static const Color goldGlow = Color(0xFFE8C878);        // Glow highlight
  static const Color roseGold = Color(0xFFE8A0B0);        // Rose gold accent
  static const Color blush = Color(0xFFF5D5DC);           // Soft blush
  static const Color lavender = Color(0xFFD4B8E8);        // Soft lavender
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF81C784);

  // ─── Light Theme ───
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: pearl,
      colorScheme: const ColorScheme.light(
        primary: gold,
        onPrimary: pearlSurface,
        secondary: roseGold,
        surface: pearlSurface,
        onSurface: textDark,
        surfaceContainer: pearlMuted,
        tertiary: lavender,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.w700, color: textDark,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24, fontWeight: FontWeight.w600, color: textDark,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w600, color: gold,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w400, color: textDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14, color: textDark.withOpacity(0.75),
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12, color: textDark.withOpacity(0.55),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: pearl,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: gold),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w700, color: gold,
        ),
      ),
    );
  }

  // ─── Dark Theme ───
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: charcoal,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: charcoal,
        secondary: roseGold,
        surface: charcoalSurface,
        onSurface: textLight,
        surfaceContainer: charcoalMuted,
        tertiary: lavender,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.w700, color: gold,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24, fontWeight: FontWeight.w600, color: textLight,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w600, color: goldGlow,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w400, color: textLight,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14, color: textLight.withOpacity(0.8),
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12, color: textLight.withOpacity(0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: gold),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w700, color: gold,
        ),
      ),
    );
  }
}
