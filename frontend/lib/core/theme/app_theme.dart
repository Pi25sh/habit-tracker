import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData getTheme(AppThemeType type) {
    final colors = AppColors.themes[type]!;
    final isDark = type == AppThemeType.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: colors.secondary,
        onSecondary: isDark ? Colors.black : Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: GoogleFonts.dancingScript(
          color: colors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: colors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: colors.textPrimary, fontSize: 14),
        labelLarge: TextStyle(color: colors.textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.secondary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary.withOpacity(0.5),
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: false,
      ),
    );
  }
}
