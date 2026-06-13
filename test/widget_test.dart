import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mem3/main.dart';
import 'package:mem3/services/theme_service.dart';
import 'package:mem3/services/profile_service.dart';
import 'package:mem3/services/menta_service.dart';
import 'package:mem3/services/familiar_face_service.dart';
import 'package:mem3/services/activity_monitoring_service.dart';
import 'package:mem3/services/alert_service.dart';
import 'package:mem3/services/inactivity_detection_service.dart';
import 'package:mem3/providers/export_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SharedPreferences>.value(value: sharedPrefs),
          ChangeNotifierProvider(create: (_) => ExportProvider(sharedPrefs)),
          ChangeNotifierProvider(create: (_) => MentaService()),
          ChangeNotifierProvider(create: (_) => ProfileService()),
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => FamiliarFaceService()),
          ChangeNotifierProvider(create: (_) => ActivityMonitoringService.instance),
          ChangeNotifierProvider(create: (_) => AlertService.instance),
          ChangeNotifierProvider(create: (_) => InactivityDetectionService.instance),
        ],
        child: const MemoriaeApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify that splash screen or main app title is shown
    // Note: SplashScreen might navigate quickly or show a logo
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // We expect "Memoriae" to be the title of the MaterialApp or some text in Splash
    expect(find.text('Memoriae'), findsOneWidget);
  });
}
