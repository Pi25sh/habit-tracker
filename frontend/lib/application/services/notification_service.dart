import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    try {
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(settings: initSettings);
    } catch (e) {
      debugPrint('Notification initialization failed (safe to ignore on web): $e');
    }
  }

  Future<void> scheduleDailyReminder(String id, String title, String body, TimeOfDay time) async {
    // Note: True scheduled notifications require the timezone package. 
    // For this prototype, we'll assume the setup for local notifications is in place.
    // In production, you would use zonedSchedule.
  }

  Future<void> showNotification(String id, String title, String body) async {
    int notificationId = id.hashCode;
    
    const androidDetails = AndroidNotificationDetails(
      'habit_stacking',
      'Habit Stacking',
      channelDescription: 'Reminders for stacked habits',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Show notification failed: $e');
    }
  }
}
