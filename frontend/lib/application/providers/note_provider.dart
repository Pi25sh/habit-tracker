import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../data/models/note_record.dart';

final noteProvider = StateNotifierProvider<NoteNotifier, List<NoteRecord>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NoteNotifier(prefs);
});

class NoteNotifier extends StateNotifier<List<NoteRecord>> {
  final SharedPreferences _prefs;
  static const _notesKey = 'my_notes_data';

  NoteNotifier(this._prefs) : super([]) {
    _loadNotes();
  }

  void _loadNotes() {
    final notesString = _prefs.getString(_notesKey);
    if (notesString != null) {
      final List<dynamic> decoded = jsonDecode(notesString);
      state = decoded.map((json) => NoteRecord.fromJson(json)).toList();
    } else {
      state = [];
    }
  }

  Future<void> _saveNotes(List<NoteRecord> notes) async {
    final encoded = jsonEncode(notes.map((n) => n.toJson()).toList());
    await _prefs.setString(_notesKey, encoded);
    state = notes;
  }

  Future<void> addOrUpdateNote(NoteRecord note) async {
    final currentNotes = List<NoteRecord>.from(state);
    
    // Check if a note already exists for this date (just compare Year/Month/Day)
    final existingIndex = currentNotes.indexWhere((n) => 
      n.date.year == note.date.year && 
      n.date.month == note.date.month && 
      n.date.day == note.date.day
    );

    if (existingIndex != -1) {
      currentNotes[existingIndex] = note;
    } else {
      currentNotes.add(note);
    }
    
    await _saveNotes(currentNotes);
  }

  NoteRecord? getNoteForDate(DateTime date) {
    try {
      return state.firstWhere((n) => 
        n.date.year == date.year && 
        n.date.month == date.month && 
        n.date.day == date.day
      );
    } catch (_) {
      return null;
    }
  }
}
