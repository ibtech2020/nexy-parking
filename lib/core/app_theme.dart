import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Kid-friendly bright colors
  static const Color primary    = Color(0xFFFF6B35);  // vivid orange
  static const Color secondary  = Color(0xFF00D4FF);  // sky blue
  static const Color accent1    = Color(0xFFFFE600);  // sunny yellow
  static const Color accent2    = Color(0xFF7CFF50);  // lime green
  static const Color accent3    = Color(0xFFFF4FCB);  // hot pink
  static const Color accent4    = Color(0xFFB44FFF);  // purple

  // Keep legacy names so existing code compiles
  static const Color neonCyan   = secondary;
  static const Color neonOrange = primary;
  static const Color neonRed    = Color(0xFFFF3C3C);

  static const Color darkBg      = Color(0xFF0D1B2A);
  static const Color darkSurface = Color(0xFF162032);
  static const Color darkCard    = Color(0xFF1E2D40);
  static const Color darkBorder  = Color(0xFF2A4060);
  static const Color textPrimary   = Color(0xFFFFF8E7);
  static const Color textSecondary = Color(0xFFAAC4D8);
  static const Color textMuted     = Color(0xFF4A6A88);

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0D1B2A), Color(0xFF162032), Color(0xFF0A1520)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [secondary, Color(0xFF0099CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [primary, Color(0xFFCC4400)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: darkSurface,
        error: neonRed,
        onPrimary: Colors.white,
        onSecondary: darkBg,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: accent1, letterSpacing: 6),
          displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 4),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 2),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 1.5),
          bodyLarge: TextStyle(fontSize: 16, color: textPrimary, letterSpacing: 0.5),
          bodyMedium: TextStyle(fontSize: 14, color: textSecondary, letterSpacing: 0.5),
          labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 2),
          labelSmall: TextStyle(fontSize: 10, color: textMuted, letterSpacing: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2),
        ),
      ),
    );
  }
}
