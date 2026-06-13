import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:menta/services/gemini_service.dart';
import 'package:menta/models/journal_entry.dart';
import 'mocks.mocks.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockDatabaseHelper mockDb;
  late GeminiService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDb = MockDatabaseHelper();
    service = GeminiService(dbHelper: mockDb);
  });

  test('getMemoryContext includes moodSummary when journals exist', () async {
    final List<JournalEntry> journals = [
      JournalEntry(
        id: '1', 
        title: 'Happy Day', 
        content: 'I had a great time today.', 
        date: DateTime.now(), 
        mood: 'Happy'
      ),
      JournalEntry(
        id: '2', 
        title: 'Tired Day', 
        content: 'I feel a bit tired.', 
        date: DateTime.now().subtract(const Duration(days: 1)), 
        mood: 'Tired'
      ),
    ];

    when(mockDb.readAllEntries()).thenAnswer((_) async => journals);
    when(mockDb.getAllMedications()).thenAnswer((_) async => []);
    when(mockDb.getAllFamiliarFaces()).thenAnswer((_) async => []);
    when(mockDb.getAllDailyRoutines()).thenAnswer((_) async => []);
    when(mockDb.getAllReminders()).thenAnswer((_) async => []);

    final context = await service.getMemoryContext();

    // This should fail (RED) as moodSummary is not yet implemented
    expect(context.containsKey('moodSummary'), isTrue, reason: 'Context should contain a mood summary');
    expect(context['moodSummary'], contains('Happy'));
    expect(context['moodSummary'], contains('Tired'));
  });
}
