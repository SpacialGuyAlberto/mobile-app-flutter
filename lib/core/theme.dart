import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Web-Dashboard Styles
  static const Color backgroundDark = Color(0xFF0A0A0C); // from modal-overlay
  static const Color cardDark = Color(0xFF131415); // from details-box
  static const Color cardElevated = Color(0xFF161719); // from modal-header
  static const Color primaryColor = Color(0xFF6938EF); // from btn-save
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0x1AFFFFFF); // white/10
  static const Color borderLight = Color(0x0DFFFFFF); // white/5
  static const Color textMuted = Color(0x66FFFFFF); // white/40
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: cardDark,
        background: backgroundDark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: Colors.white),
        bodyMedium: GoogleFonts.inter(color: Colors.white70),
        displayLarge: GoogleFonts.instrumentSerif(color: Colors.white),
        labelLarge: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.jetBrainsMono(color: textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // rounded-md
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
          textStyle: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w400,
            fontSize: 10,
            letterSpacing: 1.5, // tracking-widest
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white60,
          side: const BorderSide(color: borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
          textStyle: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w400,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // rounded-xl
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        hintStyle: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
