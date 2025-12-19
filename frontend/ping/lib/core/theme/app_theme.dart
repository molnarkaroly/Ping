import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark Mode Color Palette - Soft UI / Neumorphic Dark Theme
class AppColors {
  // Dark mode background colors
  static const Color primaryBackground = Color(0xFF1E2128);
  static const Color surfaceColor = Color(0xFF252931);
  static const Color cardColor = Color(0xFF2A2F38);

  // Accent colors
  static const Color emergency = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFF6C63FF);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);

  // Text colors
  static const Color textPrimary = Color(0xFFE8ECF4);
  static const Color textSecondary = Color(0xFF8B94A6);

  // Neumorphic shadow colors for dark mode
  static const Color shadowLight = Color(0xFF2E3440);
  static const Color shadowDark = Color(0xFF151820);

  // Other
  static const Color white = Colors.white;
  static const Color divider = Color(0xFF3A3F4A);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.surfaceColor,
        error: AppColors.emergency,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}

class NeumorphicStyles {
  /// Soft shadows for dark mode neumorphism
  static List<BoxShadow> get softShadows => [
    const BoxShadow(
      color: AppColors.shadowLight,
      offset: Offset(-4, -4),
      blurRadius: 12,
      spreadRadius: 1,
    ),
    const BoxShadow(
      color: AppColors.shadowDark,
      offset: Offset(4, 4),
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];

  /// Subtle shadows for cards
  static List<BoxShadow> get cardShadows => [
    BoxShadow(
      color: AppColors.shadowDark.withAlpha(180),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// Pressed/inset effect shadows
  static List<BoxShadow> get pressedShadows => [
    BoxShadow(
      color: AppColors.shadowDark.withAlpha(128),
      offset: const Offset(2, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static BoxDecoration get baseDecoration => BoxDecoration(
    color: AppColors.cardColor,
    borderRadius: BorderRadius.circular(24),
    boxShadow: softShadows,
  );
}
