import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pure White / Light Pearl Gloss Color Palette
  static const Color pearlBackground = Color(0xFFF4F7FC);
  static const Color pearlGlossCard = Color(0xCCFFFFFF); // 80% opaque white
  static const Color glassBorder = Color(0x99FFFFFF);     // 60% border highlight
  static const Color glassShadow = Color(0x0C002060);     // Soft subtle blue shadow

  // Accent Colors: Electric Blue & Royal Blue
  static const Color electricBlue = Color(0xFF0066FF);
  static const Color electricBlueHover = Color(0xFF0052CC);
  static const Color royalBlue = Color(0xFF1E3A8A);
  static const Color softBlueBadge = Color(0xFFEBF3FF);

  // Status & Utility Colors
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color roseError = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Linear Gradients
  static const LinearGradient pearlGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFEFF4FB),
      Color(0xFFE2EBF8),
    ],
  );

  static const LinearGradient electricGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFF0066FF),
      Color(0xFF1D4ED8),
    ],
  );

  static const LinearGradient glassGlossGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xB3FFFFFF),
      Color(0x66FFFFFF),
    ],
  );

  // ThemeData Setup
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: pearlBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: electricBlue,
        primary: electricBlue,
        secondary: royalBlue,
        surface: pearlGlossCard,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.w800, // DIPERBAIKI: extraBold (B kapital)
          fontSize: 32,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  // Backdrop Filter Blur Preset for Glassmorphism
  static ImageFilter get glassBlur => ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0);
}