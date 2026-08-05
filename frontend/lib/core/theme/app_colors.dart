import 'package:flutter/material.dart';

enum AppThemeType { pastel, matcha, dark, lavender, pink }

class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });
}

class AppColors {
  static const Map<AppThemeType, ThemeColors> themes = {
    AppThemeType.matcha: ThemeColors(
      primary: Color(0xFFA3B18A), // Matcha Green
      secondary: Color(0xFFD5BDAF), // Dusty Rose
      accent: Color(0xFF588157),
      background: Color(0xFFF9F7F3),
      surface: Colors.white,
      textPrimary: Color(0xFF344E41),
      textSecondary: Color(0xFF8A9A5B),
    ),
    AppThemeType.pastel: ThemeColors(
      primary: Color(0xFFFFB6C1), // Blush Pink
      secondary: Color(0xFFB0E0E6), // Baby Blue
      accent: Color(0xFFFFFDD0), // Cream
      background: Color(0xFFFAFAFA),
      surface: Colors.white,
      textPrimary: Color(0xFF4A4A4A),
      textSecondary: Color(0xFF8E8E93),
    ),
    AppThemeType.dark: ThemeColors(
      primary: Color(0xFFBB86FC), // Neon Purple
      secondary: Color(0xFF03DAC6), // Teal
      accent: Color(0xFFCF6679), // Pink Red
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFAAAAAA),
    ),
    AppThemeType.lavender: ThemeColors(
      primary: Color(0xFFC3B1E1), // Soft Purple
      secondary: Color(0xFFE6E6FA), // Lavender
      accent: Color(0xFFFFD1DC), // Pastel Pink
      background: Color(0xFFFDFBFE),
      surface: Colors.white,
      textPrimary: Color(0xFF4B3F72),
      textSecondary: Color(0xFF8E7CBE),
    ),
    AppThemeType.pink: ThemeColors(
      primary: Color(0xFFFF9EBB), // Barbie Pink
      secondary: Color(0xFFFFC2D1), // Light Pink
      accent: Color(0xFFFF007F), // Hot Pink
      background: Color(0xFFFFF0F5), // Lavender Blush
      surface: Colors.white,
      textPrimary: Color(0xFF6B2D5C),
      textSecondary: Color(0xFFA05C8A),
    ),
  };
}
