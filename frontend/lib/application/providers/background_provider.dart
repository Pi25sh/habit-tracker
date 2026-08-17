import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // For sharedPreferencesProvider

final backgroundProvider = StateNotifierProvider<BackgroundNotifier, Map<int, String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BackgroundNotifier(prefs);
});

class BackgroundNotifier extends StateNotifier<Map<int, String>> {
  final SharedPreferences _prefs;
  static const _bgKey = 'global_background_map';

  BackgroundNotifier(this._prefs) : super(_loadInitialMap(_prefs));

  static Map<int, String> _loadInitialMap(SharedPreferences prefs) {
    final str = prefs.getString(_bgKey);
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(int.parse(key), value as String));
      } catch (e) {
        // Fallback for old single string if needed, or just return empty
      }
    }
    return {};
  }

  void _saveMap() {
    final mapToSave = state.map((key, value) => MapEntry(key.toString(), value));
    _prefs.setString(_bgKey, jsonEncode(mapToSave));
  }

  void setBackground(int index, String url) {
    state = {...state, index: url};
    _saveMap();
  }

  void clearBackground(int index) {
    final newState = Map<int, String>.from(state);
    newState.remove(index);
    state = newState;
    _saveMap();
  }
}
