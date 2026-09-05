import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // For sharedPreferencesProvider
import '../../data/models/task.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TaskNotifier(prefs);
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final SharedPreferences _prefs;
  static const _tasksKey = 'my_tasks_data';
  static const _syncEnabledKey = 'tasks_sync_enabled';

  TaskNotifier(this._prefs) : super([]) {
    _loadTasks();
    _syncWithBackend(); // Sync on startup
  }

  void _loadTasks() {
    final tasksString = _prefs.getString(_tasksKey);
    if (tasksString != null) {
      final List<dynamic> decoded = jsonDecode(tasksString);
      state = decoded.map((json) => Task.fromJson(json)).toList();
    } else {
      state = [];
    }
  }

  Future<void> _saveTasks(List<Task> tasks) async {
    final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _prefs.setString(_tasksKey, encoded);

    // Update local updated_at timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt('${_tasksKey}_updated_at', timestamp);

    state = tasks;

    // Fire and forget sync if enabled
    final syncEnabled = _prefs.getBool(_syncEnabledKey) ?? true;
    if (syncEnabled) {
      _syncWithBackend(encoded, timestamp);
    }
  }

  Future<void> _syncWithBackend([String? encodedLocal, int? localTimestamp]) async {
    try {
      final currentEncoded = encodedLocal ?? _prefs.getString(_tasksKey) ?? '[]';
      final currentTimestamp = localTimestamp ?? _prefs.getInt('${_tasksKey}_updated_at') ?? 0;

      final result = await ApiService.syncData('tasks', currentEncoded, currentTimestamp);

      // If the server had newer data, it will return it
      if (result != null) {
        final remoteEncoded = result['value'] as String;
        final remoteTimestamp = result['updated_at'] as int;

        // Update local storage directly without triggering another sync
        await _prefs.setString(_tasksKey, remoteEncoded);
        await _prefs.setInt('${_tasksKey}_updated_at', remoteTimestamp);

        final List<dynamic> decoded = jsonDecode(remoteEncoded);
        state = decoded.map((json) => Task.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Sync failed (backend might be offline): $e');
    }
  }

  // Backend API integration (if backend has task endpoints)
  Future<void> fetchTasksFromBackend() async {
    // Note: Backend doesn't have task endpoints yet, so this is a placeholder
    debugPrint('Task backend sync not yet implemented');
  }

  Future<void> addTask(Task task) async {
    final currentTasks = List<Task>.from(state);
    currentTasks.add(task);
    await _saveTasks(currentTasks);

    if (task.reminderTime != null && task.dueDate != null) {
      final reminderDateTime = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.reminderTime!.hour,
        task.reminderTime!.minute,
      );
      if (reminderDateTime.isAfter(DateTime.now())) {
        NotificationService().scheduleDailyReminder(
          task.id,
          'Task Reminder: ${task.name}',
          'You have a task due today.',
          task.reminderTime!,
        );
      }
    }
  }

  Future<void> updateTask(Task task) async {
    final currentTasks = List<Task>.from(state);
    final index = currentTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      currentTasks[index] = task;
      await _saveTasks(currentTasks);

      if (task.reminderTime != null && task.dueDate != null && !task.isCompleted) {
        final reminderDateTime = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
          task.reminderTime!.hour,
          task.reminderTime!.minute,
        );
        if (reminderDateTime.isAfter(DateTime.now())) {
          NotificationService().scheduleDailyReminder(
            task.id,
            'Task Reminder: ${task.name}',
            'You have a task due today.',
            task.reminderTime!,
          );
        }
      }
    }
  }

  Future<void> deleteTask(String id) async {
    final currentTasks = List<Task>.from(state);
    currentTasks.removeWhere((t) => t.id == id);
    await _saveTasks(currentTasks);
  }

  Future<void> toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    await updateTask(task);
  }

  Future<void> setSyncEnabled(bool enabled) async {
    await _prefs.setBool(_syncEnabledKey, enabled);
    if (enabled) {
      _syncWithBackend();
    }
  }
}