import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpectaTheme {
  // Brand Colors from specta-web app.css
  static const Color slateBg = Color(0xFF020617);
  static const Color slateGlass = Color(0xFF0F172A);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonCyan = Color(0xFF22D3EE);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: slateBg,
      primaryColor: neonPurple,
      colorScheme: const ColorScheme.dark(
        primary: neonPurple,
        secondary: neonCyan,
        surface: slateGlass,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slateGlass.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonPurple, width: 2),
        ),
        labelStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // Helper method for the neon glow effect used in text and boxes
  static List<BoxShadow> get neonGlowCyan {
    return [
      BoxShadow(color: neonCyan.withOpacity(0.5), blurRadius: 6),
      BoxShadow(color: neonCyan.withOpacity(0.3), blurRadius: 20),
    ];
  }

  static List<BoxShadow> get neonGlowPurple {
    return [
      BoxShadow(color: neonPurple.withOpacity(0.5), blurRadius: 6),
      BoxShadow(color: neonPurple.withOpacity(0.3), blurRadius: 20),
    ];
  }
}
