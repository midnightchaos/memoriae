import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:menta/screens/daily_routines_screen.dart';
import 'package:menta/services/theme_service.dart';
import 'package:mockito/mockito.dart';

class MockThemeService extends Mock implements ThemeService {
  @override
  AppThemeMode get themeMode => AppThemeMode.light;
}

void main() {
  testWidgets('DailyRoutinesScreen show dialog test', (
    WidgetTester tester,
  ) async {
    final mockThemeService = MockThemeService();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ThemeService>.value(
          value: mockThemeService,
          child: const DailyRoutinesScreen(userId: 'test_user'),
        ),
      ),
    );

    // This should fail if context.watch is used incorrectly in a method called on tap
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.text('Add Routine'), findsAtLeastNWidgets(1));
  });
}
