import 'package:flutter/material.dart';

class CalendarEvent {
  String id;
  String title;
  DateTime date;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? location;
  String? notes;
  int? color;
  DateTime? createdAt;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.notes,
    this.color,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'startTime': startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
    'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
    'location': location,
    'notes': notes,
    'color': color,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    TimeOfDay? pStart, pEnd;
    if (json['startTime'] != null) {
      final parts = (json['startTime'] as String).split(':');
      pStart = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (json['endTime'] != null) {
      final parts = (json['endTime'] as String).split(':');
      pEnd = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: pStart,
      endTime: pEnd,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      color: json['color'] as int?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
}

class CalendarReminder {
  String id;
  String title;
  DateTime date;
  TimeOfDay? time;
  String? repeat; // e.g. "Daily", "Weekly", "Never"
  bool notification;
  String? notes;
  DateTime? createdAt;

  CalendarReminder({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    this.repeat,
    this.notification = true,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'time': time != null ? '${time!.hour}:${time!.minute}' : null,
    'repeat': repeat,
    'notification': notification,
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory CalendarReminder.fromJson(Map<String, dynamic> json) {
    TimeOfDay? pTime;
    if (json['time'] != null) {
      final parts = (json['time'] as String).split(':');
      pTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return CalendarReminder(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      time: pTime,
      repeat: json['repeat'] as String?,
      notification: json['notification'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
}

class SpecialDay {
  String id;
  String title;
  DateTime date;
  String? emoji; // Changed from type
  String? person;
  String? notes;
  DateTime? createdAt;

  SpecialDay({
    required this.id,
    required this.title,
    required this.date,
    this.emoji,
    this.person,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'emoji': emoji,
    'person': person,
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory SpecialDay.fromJson(Map<String, dynamic> json) {
    return SpecialDay(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      emoji: json['emoji'] as String?,
      person: json['person'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
}
