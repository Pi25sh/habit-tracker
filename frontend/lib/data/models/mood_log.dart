class MoodLog {
  final String id;
  final DateTime timestamp;
  final String mood; // emoji
  final String? note;
  final String? context; // e.g. "Work", "Family", "Health"

  MoodLog({
    required this.id,
    required this.timestamp,
    required this.mood,
    this.note,
    this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
      'note': note,
      'context': context,
    };
  }

  factory MoodLog.fromMap(Map<String, dynamic> map) {
    return MoodLog(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      mood: map['mood'],
      note: map['note'],
      context: map['context'],
    );
  }
}
