import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // for sharedPreferencesProvider

final healthProvider = StateNotifierProvider<HealthNotifier, Map<String, dynamic>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HealthNotifier(prefs);
});

class HealthNotifier extends StateNotifier<Map<String, dynamic>> {
  final SharedPreferences _prefs;
  static const _key = 'health_data';

  HealthNotifier(this._prefs) : super({}) {
    _loadData();
  }

  void _loadData() {
    final dataStr = _prefs.getString(_key);
    if (dataStr != null) {
      state = Map<String, dynamic>.from(jsonDecode(dataStr));
    }
  }

  void _saveData() {
    _prefs.setString(_key, jsonEncode(state));
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  int getWaterCups() {
    final key = _todayKey();
    if (state.containsKey(key)) {
      return state[key]['water'] ?? 0;
    }
    return 0;
  }

  void addWaterCup() {
    final key = _todayKey();
    final current = Map<String, dynamic>.from(state);
    
    if (!current.containsKey(key)) {
      current[key] = {};
    }
    
    current[key]['water'] = (current[key]['water'] ?? 0) + 1;
    state = current;
    _saveData();
  }

  void removeWaterCup() {
    final key = _todayKey();
    final current = Map<String, dynamic>.from(state);
    
    if (current.containsKey(key) && current[key]['water'] != null && current[key]['water'] > 0) {
      current[key]['water'] = current[key]['water'] - 1;
      state = current;
      _saveData();
    }
  }

  double getSleepHours() {
    final key = _todayKey();
    if (state.containsKey(key)) {
      return (state[key]['sleep'] ?? 0.0).toDouble();
    }
    return 0.0;
  }

  void setSleepHours(double hours) {
    final key = _todayKey();
    final current = Map<String, dynamic>.from(state);
    
    if (!current.containsKey(key)) {
      current[key] = {};
    }
    
    current[key]['sleep'] = hours;
    state = current;
    _saveData();
  }

  bool isSyncEnabled() {
    return _prefs.getBool('health_sync_enabled') ?? false;
  }

  void setSyncEnabled(bool enabled) {
    _prefs.setBool('health_sync_enabled', enabled);
    // Trigger a rebuild by re-assigning state
    state = Map.from(state); 
  }
}
