import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    // Set local timezone - adjust as needed for your locale
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

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

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _initialized = true;
    } catch (e) {
      debugPrint('Notification initialization failed (safe to ignore on web): $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Habit reminders channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_reminders',
          'Habit Reminders',
          description: 'Daily reminders for your habits',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Habit stacking channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_stacking',
          'Habit Stacking',
          description: 'Reminders for stacked habits',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Task reminders channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'task_reminders',
          'Task Reminders',
          description: 'Reminders for your tasks and bucket list items',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload if needed
  }

  /// Schedule a daily reminder at a specific time
  Future<void> scheduleDailyReminder(
    String id,
    String title,
    String body,
    TimeOfDay time, {
    String channelId = 'habit_reminders',
    String payload = '',
  }) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Use zonedSchedule for recurring daily notifications
      await _notificationsPlugin.zonedSchedule(
        id: id.hashCode,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at this time
      );
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      debugPrint('Scheduled daily reminder for $id at $hh:$mm');
    } catch (e) {
      debugPrint('Schedule daily reminder failed: $e');
    }
  }

  /// Schedule a one-time reminder at a specific date and time
  Future<void> scheduleOneTimeReminder(
    String id,
    String title,
    String body,
    DateTime dateTime, {
    String channelId = 'habit_reminders',
    String payload = '',
  }) async {
    if (!_initialized) await init();

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    // Don't schedule if in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('Skipping past reminder for $id');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id.hashCode,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Scheduled one-time reminder for $id at $dateTime');
    } catch (e) {
      debugPrint('Schedule one-time reminder failed: $e');
    }
  }

  /// Show an immediate notification
  Future<void> showNotification(
    String id,
    String title,
    String body, {
    String channelId = 'habit_stacking',
    String payload = '',
  }) async {
    if (!_initialized) await init();

    int notificationId = id.hashCode;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'habit_stacking' ? 'Habit Stacking' : 'Notifications',
      channelDescription: channelId == 'habit_stacking'
          ? 'Reminders for stacked habits'
          : 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Show notification failed: $e');
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(String id) async {
    if (!_initialized) await init();
    try {
      await _notificationsPlugin.cancel(id: id.hashCode);
    } catch (e) {
      debugPrint('Cancel notification failed: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) await init();
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Cancel all notifications failed: $e');
    }
  }

  /// Cancel all notifications for a specific channel
  Future<void> cancelChannelNotifications(String channelId) async {
    // flutter_local_notifications doesn't support cancel by channel directly
    // Would need to track notification IDs per channel
    await cancelAllNotifications();
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await init();
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Get pending notifications failed: $e');
      return [];
    }
  }
}