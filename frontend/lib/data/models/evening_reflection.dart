class EveningReflection {
  final String id;
  final DateTime date;
  final String wentWell;
  final String didntGoWell;
  final String biggestAchievement;
  final String gratitude;
  final int energyLevel; // 1-10
  final int stressLevel; // 1-10
  final String mood; // emoji
  final String sleepQuality;
  final bool finishedGoals;
  final String lessonLearned;
  final String improveTomorrow;
  final String tomorrowPriorities;
  final DateTime createdAt;

  EveningReflection({
    required this.id,
    required this.date,
    this.wentWell = '',
    this.didntGoWell = '',
    this.biggestAchievement = '',
    this.gratitude = '',
    this.energyLevel = 5,
    this.stressLevel = 5,
    this.mood = '',
    this.sleepQuality = 'Good',
    this.finishedGoals = false,
    this.lessonLearned = '',
    this.improveTomorrow = '',
    this.tomorrowPriorities = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'wentWell': wentWell,
      'didntGoWell': didntGoWell,
      'biggestAchievement': biggestAchievement,
      'gratitude': gratitude,
      'energyLevel': energyLevel,
      'stressLevel': stressLevel,
      'mood': mood,
      'sleepQuality': sleepQuality,
      'finishedGoals': finishedGoals ? 1 : 0,
      'lessonLearned': lessonLearned,
      'improveTomorrow': improveTomorrow,
      'tomorrowPriorities': tomorrowPriorities,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EveningReflection.fromMap(Map<String, dynamic> map) {
    return EveningReflection(
      id: map['id'],
      date: DateTime.parse(map['date']),
      wentWell: map['wentWell'],
      didntGoWell: map['didntGoWell'],
      biggestAchievement: map['biggestAchievement'],
      gratitude: map['gratitude'],
      energyLevel: map['energyLevel'],
      stressLevel: map['stressLevel'],
      mood: map['mood'],
      sleepQuality: map['sleepQuality'],
      finishedGoals: map['finishedGoals'] == 1,
      lessonLearned: map['lessonLearned'],
      improveTomorrow: map['improveTomorrow'],
      tomorrowPriorities: map['tomorrowPriorities'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
