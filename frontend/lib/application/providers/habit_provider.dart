import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // For sharedPreferencesProvider
import '../../data/models/habit.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HabitNotifier(prefs);
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  final SharedPreferences _prefs;
  static const _habitsKey = 'my_habits_data';
  static const _syncEnabledKey = 'habits_sync_enabled';

  HabitNotifier(this._prefs) : super([]) {
    _loadHabits();
    _syncWithBackend(); // Sync on startup
  }

  void _loadHabits() {
    final habitsString = _prefs.getString(_habitsKey);
    if (habitsString != null) {
      final List<dynamic> decoded = jsonDecode(habitsString);
      state = decoded.map((json) => Habit.fromJson(json)).toList();
    } else {
      state = [];
    }
  }

  Future<void> _saveHabits(List<Habit> habits) async {
    final encoded = jsonEncode(habits.map((h) => h.toJson()).toList());
    await _prefs.setString(_habitsKey, encoded);

    // Update local updated_at timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt('${_habitsKey}_updated_at', timestamp);

    state = habits;

    // Fire and forget sync if enabled
    final syncEnabled = _prefs.getBool(_syncEnabledKey) ?? true;
    if (syncEnabled) {
      _syncWithBackend(encoded, timestamp);
    }
  }

  Future<void> _syncWithBackend([String? encodedLocal, int? localTimestamp]) async {
    try {
      final currentEncoded = encodedLocal ?? _prefs.getString(_habitsKey) ?? '[]';
      final currentTimestamp = localTimestamp ?? _prefs.getInt('${_habitsKey}_updated_at') ?? 0;

      final result = await ApiService.syncData('habits', currentEncoded, currentTimestamp);

      // If the server had newer data, it will return it
      if (result != null) {
        final remoteEncoded = result['value'] as String;
        final remoteTimestamp = result['updated_at'] as int;

        // Update local storage directly without triggering another sync
        await _prefs.setString(_habitsKey, remoteEncoded);
        await _prefs.setInt('${_habitsKey}_updated_at', remoteTimestamp);

        final List<dynamic> decoded = jsonDecode(remoteEncoded);
        state = decoded.map((json) => Habit.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Sync failed (backend might be offline): $e');
    }
  }

  // Backend API integration
  Future<void> fetchHabitsFromBackend() async {
    try {
      final habits = await ApiService.getHabits();
      if (habits.isNotEmpty) {
        final parsed = habits.map((json) => Habit.fromJson(json as Map<String, dynamic>)).toList();
        await _saveHabits(parsed);
      }
    } catch (e) {
      debugPrint('Failed to fetch habits from backend: $e');
    }
  }

  Future<void> addHabit(Habit habit) async {
    final currentHabits = List<Habit>.from(state);
    currentHabits.add(habit);
    await _saveHabits(currentHabits);

    // Also try to create on backend
    try {
      final backendHabit = {
        'name': habit.name,
        'description': habit.description,
        'icon': habit.icon ?? 'check_circle',
        'color': '#${habit.color.toRadixString(16).padLeft(6, '0')}',
        'frequency': habit.frequency ?? 'daily',
        'time_of_day': 'anytime',
        'goal_target': 1,
        'goal_unit': 'times',
        'start_date': habit.createdAt?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
      };
      await ApiService.createHabit(backendHabit);
    } catch (e) {
      debugPrint('Backend create habit failed: $e');
    }

    if (habit.reminderTime != null) {
      NotificationService().scheduleDailyReminder(
        habit.id,
        'Time for ${habit.name}!',
        'It is time to complete your habit.',
        habit.reminderTime!,
      );
    }
  }

  Future<void> updateHabit(Habit habit) async {
    final currentHabits = List<Habit>.from(state);
    final index = currentHabits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      currentHabits[index] = habit;
      await _saveHabits(currentHabits);

      // Also try to update on backend
      try {
        final backendHabit = {
          'name': habit.name,
          'description': habit.description,
          'icon': habit.icon ?? 'check_circle',
          'color': '#${habit.color.toRadixString(16).padLeft(6, '0')}',
          'frequency': habit.frequency ?? 'daily',
          'time_of_day': 'anytime',
          'goal_target': 1,
          'goal_unit': 'times',
        };
        await ApiService.updateHabit(habit.id, backendHabit);
      } catch (e) {
        debugPrint('Backend update habit failed: $e');
      }

      if (habit.reminderTime != null) {
        NotificationService().scheduleDailyReminder(
          habit.id,
          'Time for ${habit.name}!',
          'It is time to complete your habit.',
          habit.reminderTime!,
        );
      }
    }
  }

  Future<void> deleteHabit(String id) async {
    final currentHabits = List<Habit>.from(state);
    currentHabits.removeWhere((h) => h.id == id);
    await _saveHabits(currentHabits);

    // Also try to delete from backend
    try {
      await ApiService.deleteHabit(id);
    } catch (e) {
      debugPrint('Backend delete habit failed: $e');
    }
  }

  Future<void> toggleHabitCompletion(Habit habit, DateTime date) async {
    // Ensure the list is growable to prevent crashes from const [] during hot reload
    habit.completedDates = List<DateTime>.from(habit.completedDates);

    final dateOnly = DateTime(date.year, date.month, date.day);

    // Check if already completed on this date
    final isCompleted = habit.completedDates.any((d) =>
      d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day
    );

    if (isCompleted) {
      habit.completedDates.removeWhere((d) =>
        d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day
      );
    } else {
      habit.completedDates.add(dateOnly);
      habit.currentStreak++;
      if (habit.currentStreak > habit.longestStreak) {
        habit.longestStreak = habit.currentStreak;
      }

      // Habit Stacking Check
      final stackedHabits = state.where((h) => h.linkedHabitId == habit.id && !h.isPaused).toList();
      for (var stacked in stackedHabits) {
        NotificationService().showNotification(
          stacked.id,
          'Habit Stacking: ${stacked.name}',
          'You just finished ${habit.name}. Now it\'s time for ${stacked.name}!',
        );
      }

      // Also log to backend
      try {
        await ApiService.logHabit(habit.id, dateOnly);
      } catch (e) {
        debugPrint('Backend log habit failed: $e');
      }
    }

    await updateHabit(habit);
  }

  Future<void> setSyncEnabled(bool enabled) async {
    await _prefs.setBool(_syncEnabledKey, enabled);
    if (enabled) {
      _syncWithBackend();
    }
  }
}
