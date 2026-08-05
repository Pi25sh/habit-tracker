class NoteRecord {
  String id;
  DateTime date;
  String? mood;
  String? journalEntry;
  String? gratitude;

  NoteRecord({
    required this.id,
    required this.date,
    this.mood,
    this.journalEntry,
    this.gratitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'journalEntry': journalEntry,
      'gratitude': gratitude,
    };
  }

  factory NoteRecord.fromJson(Map<String, dynamic> json) {
    return NoteRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mood: json['mood'] as String?,
      journalEntry: json['journalEntry'] as String?,
      gratitude: json['gratitude'] as String?,
    );
  }
}
