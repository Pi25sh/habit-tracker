import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // for sharedPreferencesProvider
import 'app_colors.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeType>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<AppThemeType> {
  final SharedPreferences _prefs;
  static const _themeKey = 'app_theme_preference';

  ThemeNotifier(this._prefs) : super(AppThemeType.lavender) {
    _loadTheme();
  }

  void _loadTheme() {
    final savedThemeStr = _prefs.getString(_themeKey);
    if (savedThemeStr != null) {
      state = AppThemeType.values.firstWhere(
        (t) => t.toString() == savedThemeStr,
        orElse: () => AppThemeType.lavender,
      );
    }
  }

  Future<void> setTheme(AppThemeType theme) async {
    state = theme;
    await _prefs.setString(_themeKey, theme.toString());
  }
}
