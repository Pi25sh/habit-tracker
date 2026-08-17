import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/journal_entry.dart';
import '../../data/database/database_service.dart';

final journalProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>((ref) {
  return JournalNotifier();
});

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  final _db = DatabaseService();

  JournalNotifier() : super([]) {
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final data = await _db.queryAll('journal_entries');
    if (!mounted) return;
    state = data.map((map) => JournalEntry.fromMap(map)).toList();
  }

  Future<void> addEntry(JournalEntry entry) async {
    await _db.insert('journal_entries', entry.toMap());
    state = [...state, entry];
  }

  Future<void> updateEntry(JournalEntry entry) async {
    await _db.update('journal_entries', entry.toMap(), entry.id);
    state = [
      for (final e in state)
        if (e.id == entry.id) entry else e
    ];
  }

  Future<void> deleteEntry(String id) async {
    await _db.delete('journal_entries', id);
    state = state.where((e) => e.id != id).toList();
  }
}
