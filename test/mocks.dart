import 'package:mockito/annotations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:menta/services/database_helper.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  DatabaseHelper,
])
void main() {}
