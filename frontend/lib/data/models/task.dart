import 'package:flutter/material.dart';

class Task {
  String id;
  String name;
  String? description;
  int color;
  String? icon;
  bool isCompleted;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  TimeOfDay? reminderTime;
  String? priority;
  String? category;
  DateTime? createdAt;
  DateTime? updatedAt;

  // The main paper note
  String? note;

  // Scrapbook / Chat style entries
  List<String> imagePaths; // Paths to attached images
  List<String> doodlePaths; // Paths to attached doodles

  Task({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    this.icon,
    this.isCompleted = false,
    this.dueDate,
    this.dueTime,
    this.reminderTime,
    this.priority,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.note,
    List<String>? imagePaths,
    List<String>? doodlePaths,
  })  : imagePaths = imagePaths ?? [],
        doodlePaths = doodlePaths ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime != null
          ? '${dueTime!.hour}:${dueTime!.minute}'
          : null,
      'reminderTime': reminderTime != null
          ? '${reminderTime!.hour}:${reminderTime!.minute}'
          : null,
      'priority': priority,
      'category': category,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'note': note,
      'imagePaths': imagePaths,
      'doodlePaths': doodlePaths,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parsedReminderTime;
    if (json['reminderTime'] != null) {
      final parts = (json['reminderTime'] as String).split(':');
      if (parts.length == 2) {
        parsedReminderTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    TimeOfDay? parsedDueTime;
    if (json['dueTime'] != null) {
      final parts = (json['dueTime'] as String).split(':');
      if (parts.length == 2) {
        parsedDueTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as int,
      icon: json['icon'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dueTime: parsedDueTime,
      reminderTime: parsedReminderTime,
      priority: json['priority'] as String?,
      category: json['category'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      note: json['note'] as String?,
      imagePaths: (json['imagePaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      doodlePaths: (json['doodlePaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
