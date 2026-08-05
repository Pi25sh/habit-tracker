import 'dart:convert';
import 'package:flutter/material.dart';

class Habit {
  String id;
  String name;
  String? description;
  int color;
  String? icon;
  String routine; // 'Morning', 'Afternoon', 'Evening'
  List<DateTime> completedDates;
  int currentStreak;
  int longestStreak;
  String? frequency;
  DateTime? createdAt;
  bool isPaused;
  TimeOfDay? reminderTime;
  String? linkedHabitId; // For habit stacking

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    this.icon,
    required this.routine,
    this.completedDates = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.frequency,
    this.createdAt,
    this.isPaused = false,
    this.reminderTime,
    this.linkedHabitId,
  });

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
    );
  }
}
