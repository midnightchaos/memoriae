import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/medication.dart';

class MedicationNotificationService {
  static MedicationNotificationService _instance = MedicationNotificationService._internal();
  static MedicationNotificationService get instance => _instance;

  @visibleForTesting
  static set instance(MedicationNotificationService service) => _instance = service;

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  MedicationNotificationService._internal() : _notifications = FlutterLocalNotificationsPlugin();

  @visibleForTesting
  MedicationNotificationService.test(this._notifications, {bool initialized = true}) : _initialized = initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    
    // Use device timezone or fallback to Asia/Kolkata
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
    // Handle notification tap - navigate to medications screen
    // This would typically use a navigator key or callback
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleMedicationReminder(Medication medication) async {
    if (!medication.isActive) {
      await cancelMedicationReminder(medication.id);
      return;
    }

    await initialize();

    final timeParts = medication.timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medications on time',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFFA78BFA),
      ticker: 'Medication Reminder',
      styleInformation: BigTextStyleInformation(
        'Time to take ${medication.name} (${medication.dosage})',
        contentTitle: '💊 Medication Reminder',
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

    // Schedule daily notification
    await _notifications.zonedSchedule(
      medication.id.hashCode,
      '💊 Medication Reminder',
      'Time to take ${medication.name} (${medication.dosage})',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'medication_${medication.id}',
    );

    print('✅ Medication reminder scheduled for ${medication.name} at ${medication.timeOfDay}');
  }

  Future<void> cancelMedicationReminder(String medicationId) async {
    await _notifications.cancel(medicationId.hashCode);
    print('❌ Cancelled reminder for medication: $medicationId');
  }

  Future<void> cancelAllMedicationReminders() async {
    await _notifications.cancelAll();
    print('❌ Cancelled all medication reminders');
  }

  Future<void> rescheduleAllMedications(List<Medication> medications) async {
    await cancelAllMedicationReminders();
    for (final medication in medications) {
      if (medication.isActive) {
        await scheduleMedicationReminder(medication);
      }
    }
    print('🔄 Rescheduled ${medications.where((m) => m.isActive).length} medications');
  }

  Future<bool> requestPermissions() async {
    if (_notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>() !=
        null) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!;
      
      final granted = await androidImplementation.requestNotificationsPermission();
      
      // Also request exact alarm permission for Android 12+
      final exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
      
      print('Notification permission: $granted');
      print('Exact alarm permission: $exactAlarmGranted');
      
      return (granted ?? false) && (exactAlarmGranted ?? true);
    }

    if (_notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>() !=
        null) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()!
          .requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  Future<void> showImmediateNotification(String title, String body) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medications on time',
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
      '💊 Test Notification',
      'Medication reminders are working perfectly!',
    );
    print('📱 Test notification sent');
  }

  // Get list of pending notifications for debugging
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (_notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>() !=
        null) {
      final bool? enabled = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .areNotificationsEnabled();
      return enabled ?? false;
    }
    return true;
  }
}
