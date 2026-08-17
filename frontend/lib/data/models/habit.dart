import 'package:flutter/material.dart';

class Habit {
  String id;
  String name;
  String? description;
  int color;
  String? icon;
  String routine; // 'Morning', 'Afternoon', 'Evening', 'Night'
  List<DateTime> completedDates;
  int currentStreak;
  int longestStreak;
  String? frequency;
  DateTime? createdAt;
  bool isPaused;
  TimeOfDay? reminderTime;
  String? linkedHabitId; // For habit stacking

  // The main paper note (Todo Detail "Notes" section)
  String? note;

  // Scrapbook / Chat style entries
  List<String> textNotes; // List of text memories ("time|message")
  List<String> imagePaths; // Paths to attached images
  List<String> doodlePaths; // Paths to attached doodles

  // To support repeat days logic S M T W T F S
  List<int> repeatDays; // 1=Mon, 7=Sun

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    this.icon,
    required this.routine,
    List<DateTime>? completedDates,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.frequency,
    this.createdAt,
    this.isPaused = false,
    this.reminderTime,
    this.linkedHabitId,
    this.note,
    List<String>? textNotes,
    List<String>? imagePaths,
    List<String>? doodlePaths,
    List<int>? repeatDays,
  }) : completedDates = completedDates ?? [],
       textNotes = textNotes ?? [],
       imagePaths = imagePaths ?? [],
       doodlePaths = doodlePaths ?? [],
       repeatDays = repeatDays ?? [1, 2, 3, 4, 5, 6, 7];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'routine': routine,
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'frequency': frequency,
      'createdAt': createdAt?.toIso8601String(),
      'isPaused': isPaused,
      'reminderTime': reminderTime != null ? '${reminderTime!.hour}:${reminderTime!.minute}' : null,
      'linkedHabitId': linkedHabitId,
      'note': note,
      'textNotes': textNotes,
      'imagePaths': imagePaths,
      'doodlePaths': doodlePaths,
      'repeatDays': repeatDays,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parsedTime;
    if (json['reminderTime'] != null) {
      final parts = (json['reminderTime'] as String).split(':');
      if (parts.length == 2) {
        parsedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as int,
      icon: json['icon'] as String?,
      routine: json['routine'] as String,
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      frequency: json['frequency'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      isPaused: json['isPaused'] as bool? ?? false,
      reminderTime: parsedTime,
      linkedHabitId: json['linkedHabitId'] as String?,
      note: json['note'] as String?,
      textNotes: (json['textNotes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      imagePaths: (json['imagePaths'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      doodlePaths: (json['doodlePaths'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      repeatDays: (json['repeatDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [1, 2, 3, 4, 5, 6, 7],
    );
  }
}
