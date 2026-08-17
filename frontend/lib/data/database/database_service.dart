import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase('premium_habit_tracker.db', version: 1, onCreate: _onCreate);
    }

    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'premium_habit_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Habits Table
    await db.execute('''
      CREATE TABLE habits(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        color INTEGER,
        icon TEXT,
        routine TEXT,
        currentStreak INTEGER,
        longestStreak INTEGER,
        frequency TEXT,
        createdAt TEXT,
        isPaused INTEGER,
        reminderTime TEXT,
        linkedHabitId TEXT,
        completedDates TEXT -- JSON encoded list for fast simple loading, or use habit_completions
      )
    ''');

    // Habit Completions Table
    await db.execute('''
      CREATE TABLE habit_completions(
        id TEXT PRIMARY KEY,
        habitId TEXT,
        timestamp TEXT,
        durationMinutes INTEGER,
        note TEXT,
        moodAfter TEXT,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    // Journal Categories Table
    await db.execute('''
      CREATE TABLE journal_categories(
        id TEXT PRIMARY KEY,
        name TEXT,
        emoji TEXT,
        coverImageUrl TEXT,
        color INTEGER,
        isDefault INTEGER,
        createdAt TEXT
      )
    ''');

    // Journal Entries Table
    await db.execute('''
      CREATE TABLE journal_entries(
        id TEXT PRIMARY KEY,
        title TEXT,
        subtitle TEXT,
        body TEXT,
        date TEXT,
        mood TEXT,
        weather TEXT,
        location TEXT,
        categoryId TEXT,
        tags TEXT,
        isFavorite INTEGER,
        isPinned INTEGER,
        isArchived INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        readingTimeMinutes INTEGER,
        wordCount INTEGER,
        attachmentsJson TEXT
      )
    ''');

    // Morning Journals Table
    await db.execute('''
      CREATE TABLE morning_journals(
        id TEXT PRIMARY KEY,
        date TEXT,
        affirmation TEXT,
        dailyGoal TEXT,
        priorities TEXT,
        mood TEXT,
        sleepHours INTEGER,
        sleepQuality TEXT,
        waterGoal INTEGER,
        exerciseGoal TEXT,
        dailyIntention TEXT,
        gratitude TEXT,
        morningQuote TEXT,
        scheduleJson TEXT,
        focusGoal TEXT,
        visualization TEXT,
        createdAt TEXT
      )
    ''');

    // Evening Reflections Table
    await db.execute('''
      CREATE TABLE evening_reflections(
        id TEXT PRIMARY KEY,
        date TEXT,
        wentWell TEXT,
        didntGoWell TEXT,
        biggestAchievement TEXT,
        gratitude TEXT,
        energyLevel INTEGER,
        stressLevel INTEGER,
        mood TEXT,
        sleepQuality TEXT,
        finishedGoals INTEGER,
        lessonLearned TEXT,
        improveTomorrow TEXT,
        tomorrowPriorities TEXT,
        createdAt TEXT
      )
    ''');

    // Mood Logs Table
    await db.execute('''
      CREATE TABLE mood_logs(
        id TEXT PRIMARY KEY,
        timestamp TEXT,
        mood TEXT,
        note TEXT,
        context TEXT
      )
    ''');

    // Daily Statistics Table
    await db.execute('''
      CREATE TABLE daily_statistics(
        id TEXT PRIMARY KEY,
        date TEXT,
        completedHabits INTEGER,
        totalHabits INTEGER,
        completionPercentage REAL,
        productivityScore INTEGER,
        generatedInsight TEXT,
        updatedAt TEXT
      )
    ''');
  }

  // --- Example Basic CRUD Operations ---
  
  // Create
  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Read
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  // Update
  Future<void> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  // Delete
  Future<void> delete(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
