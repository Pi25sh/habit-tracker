import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // For sharedPreferencesProvider
import '../../data/models/calendar_models.dart';

class CalendarState {
  final List<CalendarEvent> events;
  final List<CalendarReminder> reminders;
  final List<SpecialDay> specialDays;

  CalendarState({
    this.events = const [],
    this.reminders = const [],
    this.specialDays = const [],
  });

  CalendarState copyWith({
    List<CalendarEvent>? events,
    List<CalendarReminder>? reminders,
    List<SpecialDay>? specialDays,
  }) {
    return CalendarState(
      events: events ?? this.events,
      reminders: reminders ?? this.reminders,
      specialDays: specialDays ?? this.specialDays,
    );
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CalendarNotifier(prefs);
});

class CalendarNotifier extends StateNotifier<CalendarState> {
  final SharedPreferences _prefs;
  static const _eventsKey = 'my_calendar_events_data';
  static const _remindersKey = 'my_calendar_reminders_data';
  static const _specialDaysKey = 'my_calendar_special_days_data';

  CalendarNotifier(this._prefs) : super(CalendarState()) {
    _loadData();
    _syncWithBackend(); // Sync on startup
  }

  void _loadData() {
    final eventsString = _prefs.getString(_eventsKey);
    final remindersString = _prefs.getString(_remindersKey);
    final specialDaysString = _prefs.getString(_specialDaysKey);

    List<CalendarEvent> events = [];
    if (eventsString != null) {
      final List<dynamic> decoded = jsonDecode(eventsString);
      events = decoded.map((json) => CalendarEvent.fromJson(json)).toList();
    }

    List<CalendarReminder> reminders = [];
    if (remindersString != null) {
      final List<dynamic> decoded = jsonDecode(remindersString);
      reminders = decoded.map((json) => CalendarReminder.fromJson(json)).toList();
    }

    List<SpecialDay> specialDays = [];
    if (specialDaysString != null) {
      final List<dynamic> decoded = jsonDecode(specialDaysString);
      specialDays = decoded.map((json) => SpecialDay.fromJson(json)).toList();
    }

    state = CalendarState(
      events: events,
      reminders: reminders,
      specialDays: specialDays,
    );
  }

  Future<void> _saveEvents(List<CalendarEvent> items) async {
    final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
    await _prefs.setString(_eventsKey, encoded);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt('${_eventsKey}_updated_at', timestamp);
    state = state.copyWith(events: items);
  }

  Future<void> _saveReminders(List<CalendarReminder> items) async {
    final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
    await _prefs.setString(_remindersKey, encoded);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt('${_remindersKey}_updated_at', timestamp);
    state = state.copyWith(reminders: items);
  }

  Future<void> _saveSpecialDays(List<SpecialDay> items) async {
    final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
    await _prefs.setString(_specialDaysKey, encoded);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt('${_specialDaysKey}_updated_at', timestamp);
    state = state.copyWith(specialDays: items);
  }

  Future<void> _syncWithBackend() async {
    // Basic sync stub. 
  }

  // --- EVENTS ---
  Future<void> addEvent(CalendarEvent event) async {
    final current = List<CalendarEvent>.from(state.events);
    current.add(event);
    await _saveEvents(current);
  }
  Future<void> updateEvent(CalendarEvent event) async {
    final current = List<CalendarEvent>.from(state.events);
    final index = current.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      current[index] = event;
      await _saveEvents(current);
    }
  }
  Future<void> deleteEvent(String id) async {
    final current = List<CalendarEvent>.from(state.events);
    current.removeWhere((e) => e.id == id);
    await _saveEvents(current);
  }

  // --- REMINDERS ---
  Future<void> addReminder(CalendarReminder reminder) async {
    final current = List<CalendarReminder>.from(state.reminders);
    current.add(reminder);
    await _saveReminders(current);
  }
  Future<void> updateReminder(CalendarReminder reminder) async {
    final current = List<CalendarReminder>.from(state.reminders);
    final index = current.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      current[index] = reminder;
      await _saveReminders(current);
    }
  }
  Future<void> deleteReminder(String id) async {
    final current = List<CalendarReminder>.from(state.reminders);
    current.removeWhere((r) => r.id == id);
    await _saveReminders(current);
  }

  // --- SPECIAL DAYS ---
  Future<void> addSpecialDay(SpecialDay day) async {
    final current = List<SpecialDay>.from(state.specialDays);
    current.add(day);
    await _saveSpecialDays(current);
  }
  Future<void> updateSpecialDay(SpecialDay day) async {
    final current = List<SpecialDay>.from(state.specialDays);
    final index = current.indexWhere((d) => d.id == day.id);
    if (index != -1) {
      current[index] = day;
      await _saveSpecialDays(current);
    }
  }
  Future<void> deleteSpecialDay(String id) async {
    final current = List<SpecialDay>.from(state.specialDays);
    current.removeWhere((d) => d.id == id);
    await _saveSpecialDays(current);
  }
}
