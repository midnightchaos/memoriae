import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/daily_routine.dart';

class DailyRoutineNotificationService {
  static DailyRoutineNotificationService _instance =
      DailyRoutineNotificationService._internal();
  static DailyRoutineNotificationService get instance => _instance;

  @visibleForTesting
  static set instance(DailyRoutineNotificationService service) =>
      _instance = service;

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  DailyRoutineNotificationService._internal()
    : _notifications = FlutterLocalNotificationsPlugin();

  @visibleForTesting
  DailyRoutineNotificationService.test(
    this._notifications, {
    bool initialized = true,
  }) : _initialized = initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // Use device timezone or fallback to Asia/Kolkata
    try {
      final String timeZoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions for Android 13+
    await requestPermissions();

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    print('Daily routine notification tapped: ${response.payload}');
  }

  Future<void> scheduleRoutineReminder(DailyRoutine routine) async {
    if (!routine.isActive) {
      await cancelRoutineReminder(routine.id);
      return;
    }

    await initialize();

    final timeParts = routine.time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Schedule for each selected day
    for (final day in routine.days) {
      final now = tz.TZDateTime.now(tz.local);

      // Calculate the next occurrence of this day
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Find the next occurrence of the specified weekday
      int daysUntilTarget = (day - scheduledDate.weekday) % 7;
      if (daysUntilTarget == 0 && scheduledDate.isBefore(now)) {
        daysUntilTarget = 7; // Schedule for next week if time has passed today
      }

      scheduledDate = scheduledDate.add(Duration(days: daysUntilTarget));

      final androidDetails = AndroidNotificationDetails(
        'daily_routines',
        'Daily Routines',
        channelDescription: 'Reminders for your daily routines and tasks',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: Color(0xFF8B5CF6),
        ticker: 'Daily Routine Reminder',
        styleInformation: BigTextStyleInformation(
          '',
          contentTitle: '📅 ${routine.title}',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use unique ID for each day of the week
      final notificationId = '${routine.id}_$day'.hashCode;

      await _notifications.zonedSchedule(
        notificationId,
        '📅 ${routine.title}',
        routine.description.isNotEmpty
            ? routine.description
            : 'Time for your routine',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'routine_${routine.id}',
      );

      print(
        '✅ Routine reminder scheduled for ${routine.title} on day $day at ${routine.time}',
      );
    }
  }

  Future<void> cancelRoutineReminder(String routineId) async {
    // Cancel all day variations of this routine
    for (int day = 1; day <= 7; day++) {
      final notificationId = '${routineId}_$day'.hashCode;
      await _notifications.cancel(notificationId);
    }
    print('❌ Cancelled reminder for routine: $routineId');
  }

  Future<void> cancelAllRoutineReminders() async {
    await _notifications.cancelAll();
    print('❌ Cancelled all routine reminders');
  }

  Future<void> rescheduleAllRoutines(List<DailyRoutine> routines) async {
    // Don't cancel all - only cancel and reschedule routines
    for (final routine in routines) {
      await cancelRoutineReminder(routine.id);
      if (routine.isActive) {
        await scheduleRoutineReminder(routine);
      }
    }
    print(
      '🔄 Rescheduled ${routines.where((r) => r.isActive).length} routines',
    );
  }

  Future<bool> requestPermissions() async {
    if (_notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >() !=
        null) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!;

      final granted = await androidImplementation
          .requestNotificationsPermission();
      final exactAlarmGranted = await androidImplementation
          .requestExactAlarmsPermission();

      print('Notification permission: $granted');
      print('Exact alarm permission: $exactAlarmGranted');

      return (granted ?? false) && (exactAlarmGranted ?? true);
    }

    if (_notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >() !=
        null) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()!
          .requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  Future<void> showImmediateNotification(String title, String body) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'daily_routines',
      'Daily Routines',
      channelDescription: 'Reminders for your daily routines and tasks',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }

  Future<void> showTestNotification() async {
    await showImmediateNotification(
      '📅 Test Notification',
      'Daily routine reminders are working perfectly!',
    );
    print('📱 Test notification sent');
  }

  // Get list of pending notifications for debugging
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (_notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >() !=
        null) {
      final bool? enabled = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!
          .areNotificationsEnabled();
      return enabled ?? false;
    }
    return true;
  }

  // Helper to get day name
  String getDayName(int day) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[day];
  }
}
