import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/familiar_faces_screen.dart';
import 'screens/add_edit_face_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'providers/export_provider.dart';
import 'services/menta_service.dart';
import 'services/profile_service.dart';
import 'services/familiar_face_service.dart';
import 'services/theme_service.dart';
import 'services/activity_monitoring_service.dart';
import 'services/alert_service.dart';
import 'services/inactivity_detection_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize shared preferences
  final sharedPrefs = await SharedPreferences.getInstance();

  // Don't initialize database here - let it initialize lazily when first accessed
  // This prevents authentication issues during app startup

  // Initialize services
  final profileService = ProfileService();
  await profileService.load();

  final themeService = ThemeService();
  await themeService.load();

  // Start background monitoring
  InactivityDetectionService.instance.startMonitoring();

  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: sharedPrefs),
        ChangeNotifierProvider(
          create: (context) => ExportProvider(sharedPrefs),
        ),
        ChangeNotifierProvider(create: (context) => MentaService()),
        ChangeNotifierProvider(create: (context) => profileService),
        ChangeNotifierProvider(create: (context) => themeService),
        ChangeNotifierProvider(create: (context) => FamiliarFaceService()),
        ChangeNotifierProvider(
          create: (context) => ActivityMonitoringService.instance,
        ),
        ChangeNotifierProvider(create: (context) => AlertService.instance),
        ChangeNotifierProvider(
          create: (context) => InactivityDetectionService.instance,
        ),
      ],
      child: const MemoriaeApp(),
    ),
  );
}

class MemoriaeApp extends StatelessWidget {
  const MemoriaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    ThemeData getTheme() {
      switch (themeService.themeMode) {
        case AppThemeMode.light:
          return AppTheme.lightTheme;
        case AppThemeMode.blackMinimalism:
          return AppTheme.blackMinimalismTheme;
        case AppThemeMode.dark:
          return AppTheme.darkTheme;
      }
    }

    return MaterialApp(
      title: 'Memoriae',
      debugShowCheckedModeBanner: false,
      theme: getTheme(),
      home: const SplashScreen(),
      routes: {
        '/familiar-faces': (ctx) => const FamiliarFacesScreen(),
        '/add-edit-face': (ctx) => const AddEditFaceScreen(),
        '/connect': (ctx) => const ConnectScreen(),
        '/settings': (ctx) => const SettingsScreen(),
      },
    );
  }
}
