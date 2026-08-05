import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // For sharedPreferencesProvider
import '../../data/models/habit.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HabitNotifier(prefs);
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  final SharedPreferences _prefs;
  static const _habitsKey = 'my_habits_data';

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
    
    // Fire and forget sync
    _syncWithBackend(encoded, timestamp);
  }

  Future<void> _syncWithBackend([String? encodedLocal, int? localTimestamp]) async {
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
  }

  Future<void> addHabit(Habit habit) async {
    final currentHabits = List<Habit>.from(state);
    currentHabits.add(habit);
    await _saveHabits(currentHabits);
    
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
  }

  Future<void> toggleHabitCompletion(Habit habit, DateTime date) async {
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
    }

    await updateHabit(habit);
  }
}
