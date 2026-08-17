class HabitCompletion {
  final String id;
  final String habitId;
  final DateTime timestamp;
  final int? durationMinutes; // For habits that are timed
  final String? note;
  final String? moodAfter;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.timestamp,
    this.durationMinutes,
    this.note,
    this.moodAfter,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'timestamp': timestamp.toIso8601String(),
      'durationMinutes': durationMinutes,
      'note': note,
      'moodAfter': moodAfter,
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'],
      habitId: map['habitId'],
      timestamp: DateTime.parse(map['timestamp']),
      durationMinutes: map['durationMinutes'],
      note: map['note'],
      moodAfter: map['moodAfter'],
    );
  }
}
