import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Palette (Coastal Services)
  static const Color _primary = Color(0xFFD4AF37); // Coastal Gold (Accent)
  static const Color _primaryContainer = Color(0xFF0B1E3B); // Coastal Navy (Brand Primary)
  static const Color _background = Color(0xFF050E1C); // Very Dark Navy (Background)
  static const Color _surface = Color(0xFF102847); // Lighter Navy (Cards)
  static const Color _surfaceHighlight = Color(0xFF1C3A63); // Highlight
  static const Color _warmLight = Color(0xFFD4AF37); // Gold for lights
  static const Color _error = Color(0xFFCF6679);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      primaryColor: _primary,
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        onPrimary: Colors.black, // Gold text black
        primaryContainer: _primaryContainer, // Navy
        onPrimaryContainer: Colors.white, // Navy text white
        surface: _surface,
        onSurface: Colors.white,
        error: _error,
        secondary: _warmLight,
      ),
      
      // Typography: Clean, Sans-Serif, Readable
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, color: Colors.white70),
        bodyMedium: const TextStyle(fontSize: 14, color: Colors.white60),
      ),

      // Card Theme (Zones, Presets)
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Slider Theme (Crucial for Universal Dimming)
      sliderTheme: SliderThemeData(
        activeTrackColor: _warmLight,
        inactiveTrackColor: _surfaceHighlight,
        thumbColor: Colors.white,
        overlayColor: _warmLight.withOpacity(0.2),
        trackHeight: 6.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
