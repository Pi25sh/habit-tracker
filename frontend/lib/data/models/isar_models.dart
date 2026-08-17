import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class IsarHabit {
  Id id = Isar.autoIncrement;

  late String name;
  late String category;
  late String iconPath;
  late String colorHex;
  late int difficulty; // 1 to 5
  late DateTime scheduledTime;
  late bool hasReminder;

  int currentStreak = 0;
  int bestStreak = 0;
  int totalCompleted = 0;
  int missedDays = 0;

  DateTime? createdAt;

  // Scrapbook / Chat style entries
  List<String> textNotes = []; // List of JSON encoded chat notes {timestamp, text}
  List<String> imagePaths = []; // Paths to images attached to this habit
  List<String> doodlePaths = []; // Paths to doodles attached to this habit
  
  // To support repeat days logic S M T W T F S
  List<int> repeatDays = [1, 2, 3, 4, 5, 6, 7]; // 1=Mon, 7=Sun
}

@collection
class IsarDailyLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date; // Store at midnight for uniqueness per day

  late double waterIntakeLiters;
  late int moodScore; // 1 to 5
  String? moodNote;
}

@collection
class IsarHabitCompletion {
  Id id = Isar.autoIncrement;

  @Index()
  late int habitId;

  @Index()
  late DateTime date; // Completed date (normalized to midnight)
  
  late bool isCompleted;
  bool isSkipped = false;
  String? note;
  String? photoPath;
  String? voiceNotePath;
}

@collection
class IsarJournalEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  late String type; // 'Morning', 'Evening', 'Dream', 'Free'
  late String content; // Rich text / markdown
  String? mood;
  List<String> photoPaths = [];
  String? voiceNotePath;
  List<String> tags = [];
}

@collection
class IsarTimelineEvent {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime timestamp;

  late String eventType; // 'Milestone', 'Photo', 'Achievement'
  late String title;
  String? description;
  String? photoPath;
  String? relatedHabitName;
}

@collection
class IsarAchievement {
  Id id = Isar.autoIncrement;

  late String name;
  late String description;
  late DateTime unlockedAt;
  late String lottiePath;
}
