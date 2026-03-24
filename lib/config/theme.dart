import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors from index.css
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color secondary = Color(0xFF64748B);
  static const Color accent = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF1E293B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      background: accent,
      surface: Colors.white,
      error: danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: text,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: accent,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: text,
      ),
      displayMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: text,
      ),
      displaySmall: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: text,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: text,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: text,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: text,
      ),
      titleLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: text,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withOpacity(0.95),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
