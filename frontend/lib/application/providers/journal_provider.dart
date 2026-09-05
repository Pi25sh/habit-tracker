import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../data/models/journal_entry.dart';
import '../services/api_service.dart';

final journalProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return JournalNotifier(prefs);
});

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  final SharedPreferences _prefs;
  static const _journalKey = 'my_journal_entries_data';
  static const _syncEnabledKey = 'journal_sync_enabled';

  JournalNotifier(this._prefs) : super([]) {
    _loadEntries();
    _syncWithBackend();
  }

  void _loadEntries() {
    final data = _prefs.getString(_journalKey);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      state = decoded.map((map) => JournalEntry.fromMap(map)).toList();
    }
  }

  Future<void> _saveEntries(List<JournalEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toMap()).toList());
    await _prefs.setString(_journalKey, encoded);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt('${_journalKey}_updated_at', timestamp);
    state = entries;

    final syncEnabled = _prefs.getBool(_syncEnabledKey) ?? true;
    if (syncEnabled) {
      _syncWithBackend(encoded, timestamp);
    }
  }

  Future<void> _syncWithBackend([String? encodedLocal, int? localTimestamp]) async {
    try {
      final currentEncoded = encodedLocal ?? _prefs.getString(_journalKey) ?? '[]';
      final currentTimestamp = localTimestamp ?? _prefs.getInt('${_journalKey}_updated_at') ?? 0;
      final result = await ApiService.syncData('journal_entries', currentEncoded, currentTimestamp);

      if (result != null) {
        final remoteEncoded = result['value'] as String;
        final remoteTimestamp = result['updated_at'] as int;
        await _prefs.setString(_journalKey, remoteEncoded);
        await _prefs.setInt('${_journalKey}_updated_at', remoteTimestamp);
        final List<dynamic> decoded = jsonDecode(remoteEncoded);
        state = decoded.map((json) => JournalEntry.fromMap(json)).toList();
      }
    } catch (e) {
      debugPrint('Journal sync failed: $e');
    }
  }

  Future<void> addEntry(JournalEntry entry) async {
    final currentEntries = List<JournalEntry>.from(state);
    currentEntries.add(entry);
    await _saveEntries(currentEntries);
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final currentEntries = List<JournalEntry>.from(state);
    final index = currentEntries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      currentEntries[index] = entry;
      await _saveEntries(currentEntries);
    }
  }

  Future<void> deleteEntry(String id) async {
    final currentEntries = List<JournalEntry>.from(state);
    currentEntries.removeWhere((e) => e.id == id);
    await _saveEntries(currentEntries);
  }

  Future<void> setSyncEnabled(bool enabled) async {
    await _prefs.setBool(_syncEnabledKey, enabled);
    if (enabled) {
      _syncWithBackend();
    }
  }
}
