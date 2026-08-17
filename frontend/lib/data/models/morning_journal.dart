class MorningJournal {
  final String id;
  final DateTime date;
  final String affirmation;
  final String dailyGoal;
  final String priorities; // comma-separated or JSON
  final String mood;
  final int sleepHours;
  final String sleepQuality; // Excellent, Good, Average, Poor
  final int waterGoal;
  final String exerciseGoal;
  final String dailyIntention;
  final String gratitude; // JSON array of 3 things
  final String morningQuote;
  final String scheduleJson;
  final String focusGoal;
  final String visualization;
  final DateTime createdAt;

  MorningJournal({
    required this.id,
    required this.date,
    this.affirmation = '',
    this.dailyGoal = '',
    this.priorities = '',
    this.mood = '',
    this.sleepHours = 0,
    this.sleepQuality = 'Good',
    this.waterGoal = 8,
    this.exerciseGoal = '',
    this.dailyIntention = '',
    this.gratitude = '[]',
    this.morningQuote = '',
    this.scheduleJson = '[]',
    this.focusGoal = '',
    this.visualization = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'affirmation': affirmation,
      'dailyGoal': dailyGoal,
      'priorities': priorities,
      'mood': mood,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'waterGoal': waterGoal,
      'exerciseGoal': exerciseGoal,
      'dailyIntention': dailyIntention,
      'gratitude': gratitude,
      'morningQuote': morningQuote,
      'scheduleJson': scheduleJson,
      'focusGoal': focusGoal,
      'visualization': visualization,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MorningJournal.fromMap(Map<String, dynamic> map) {
    return MorningJournal(
      id: map['id'],
      date: DateTime.parse(map['date']),
      affirmation: map['affirmation'],
      dailyGoal: map['dailyGoal'],
      priorities: map['priorities'],
      mood: map['mood'],
      sleepHours: map['sleepHours'],
      sleepQuality: map['sleepQuality'],
      waterGoal: map['waterGoal'],
      exerciseGoal: map['exerciseGoal'],
      dailyIntention: map['dailyIntention'],
      gratitude: map['gratitude'],
      morningQuote: map['morningQuote'],
      scheduleJson: map['scheduleJson'],
      focusGoal: map['focusGoal'],
      visualization: map['visualization'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
