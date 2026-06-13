import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:menta/services/daily_routine_notification_service.dart';
import 'package:menta/models/daily_routine.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockFlutterLocalNotificationsPlugin mockNotifications;
  late DailyRoutineNotificationService service;

  setUp(() {
    tz.initializeTimeZones();
    mockNotifications = MockFlutterLocalNotificationsPlugin();
    service = DailyRoutineNotificationService.test(mockNotifications);
    DailyRoutineNotificationService.instance = service;
  });

  test('scheduleRoutineReminder calls zonedSchedule with correct parameters', () async {
    final routine = DailyRoutine(
      id: 'test_id',
      userId: 'user_1',
      title: 'Test Routine',
      description: 'Test Description',
      time: '09:00',
      days: [1], // Monday
      createdAt: DateTime.now(),
    );

    // Mock initialize
    when(mockNotifications.initialize(any, onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse')))
        .thenAnswer((_) async => true);
    
    // Mock resolvePlatformSpecificImplementation for permissions
    when(mockNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>())
        .thenReturn(null);
    when(mockNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>())
        .thenReturn(null);

    await service.scheduleRoutineReminder(routine);

    verify(mockNotifications.zonedSchedule(
      any,
      argThat(contains('Test Routine')),
      any,
      any,
      any,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'routine_test_id',
    )).called(1);
  });

  test('initialize sets timezone to device local', () async {
    // Mock the MethodChannel for flutter_timezone
    const channel = MethodChannel('flutter_timezone');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getLocalTimezone') {
        return 'America/New_York';
      }
      return null;
    });

    // Mock initialize plugin calls
    when(mockNotifications.initialize(any, onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse')))
        .thenAnswer((_) async => true);
    when(mockNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>())
        .thenReturn(null);
    when(mockNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>())
        .thenReturn(null);

    final uninitializedService = DailyRoutineNotificationService.test(mockNotifications, initialized: false);
    await uninitializedService.initialize();

    expect(tz.local.name, 'America/New_York');
  });
}
