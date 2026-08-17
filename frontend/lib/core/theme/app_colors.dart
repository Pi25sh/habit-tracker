import 'package:flutter/material.dart';

enum AppThemeType { warm, sage, lavender, dark }

class ThemeColors {
  final Color primary; // Primary Accent (e.g. Sage Green)
  final Color secondary; // e.g. Sunshine Yellow
  final Color background; // Primary Background (Warm Cream)
  final Color surface; // Secondary Background (Paper)
  final Color textPrimary; // Deep Brown
  final Color textSecondary; // Muted Brown
  final Color border; // #D8CCB8
  final Color lightPrimary; // Light Sage
  final Color lightSecondary; // Light Yellow
  final Color softPeach; // Soft Peach

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.lightPrimary,
    required this.lightSecondary,
    required this.softPeach,
  });
}

class AppColors {
  static const Map<AppThemeType, ThemeColors> themes = {
    AppThemeType.warm: ThemeColors(
      primary: Color(0xFF8DA989), // Sage Green
      secondary: Color(0xFFF4C85D), // Sunshine Yellow
      background: Color(0xFFF9F7F2), // Warm Off-White/Cream
      surface: Color(0xFFFFFFFF), // White for cards
      textPrimary: Color(0xFF1E2420), // Deep Dark Green/Black
      textSecondary: Color(0xFF4A6B53), // Muted Sage
      border: Color(0xFFE4EBDC),
      lightPrimary: Color(0xFFDDE8D9), // Light Sage
      lightSecondary: Color(0xFFFFF0B8), // Light Yellow
      softPeach: Color(0xFFE9B8A7),
    ),
    AppThemeType.sage: ThemeColors(
      primary: Color(0xFFAFC8B3), 
      secondary: Color(0xFFF4C85D),
      background: Color(0xFFE8F0EA), // Slightly more green bg
      surface: Color(0xFFF4F8F5),
      textPrimary: Color(0xFF2C3E30), 
      textSecondary: Color(0xFF5D7A63),
      border: Color(0xFFC3D4C7),
      lightPrimary: Color(0xFFDDE8D9),
      lightSecondary: Color(0xFFFFF0B8),
      softPeach: Color(0xFFE9B8A7),
    ),
    AppThemeType.lavender: ThemeColors(
      primary: Color(0xFF65508A),
      secondary: Color(0xFF5E4C7E),
      background: Color(0xFFF0EDF3),
      surface: Color(0xFFF7F4F9),
      textPrimary: Color(0xFF2F2D35),
      textSecondary: Color(0xFF433E47),
      border: Color(0xFF433E47),
      lightPrimary: Color(0xFFE5E3E7),
      lightSecondary: Color(0xFFDED7E9),
      softPeach: Color(0xFFE9B8A7),
    ),
    AppThemeType.dark: ThemeColors(
      primary: Color(0xFFAFC8B3),
      secondary: Color(0xFFF4C85D),
      background: Color(0xFF1E1C1A),
      surface: Color(0xFF2A2724),
      textPrimary: Color(0xFFF7F0DE),
      textSecondary: Color(0xFFB0A59A),
      border: Color(0xFF4A453F),
      lightPrimary: Color(0xFF3C4D3F),
      lightSecondary: Color(0xFF6B5829),
      softPeach: Color(0xFF6B4536),
    ),
  };
}
