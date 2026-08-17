import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mood_log.dart';
import '../../data/database/database_service.dart';

final moodProvider = StateNotifierProvider<MoodNotifier, List<MoodLog>>((ref) {
  return MoodNotifier();
});

class MoodNotifier extends StateNotifier<List<MoodLog>> {
  final _db = DatabaseService();

  MoodNotifier() : super([]) {
    _loadMoods();
  }

  Future<void> _loadMoods() async {
    final data = await _db.queryAll('mood_logs');
    state = data.map((map) => MoodLog.fromMap(map)).toList();
  }

  Future<void> addMood(MoodLog log) async {
    await _db.insert('mood_logs', log.toMap());
    state = [...state, log];
  }

  Future<void> updateMood(MoodLog log) async {
    await _db.update('mood_logs', log.toMap(), log.id);
    state = [
      for (final m in state)
        if (m.id == log.id) log else m
    ];
  }

  Future<void> deleteMood(String id) async {
    await _db.delete('mood_logs', id);
    state = state.where((m) => m.id != id).toList();
  }
}
