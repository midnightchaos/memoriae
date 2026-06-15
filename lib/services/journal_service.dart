import '../models/journal_entry.dart';
import 'database_helper.dart';

class JournalService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Load all journal entries
  Future<List<JournalEntry>> loadEntries() async {
    return await _db.readAllEntries();
  }

  // Add a new entry
  Future<void> addEntry(JournalEntry entry) async {
    await _db.createEntry(entry);
  }

  // Update an existing entry
  Future<void> updateEntry(JournalEntry entry) async {
    await _db.updateEntry(entry);
  }

  // Delete an entry
  Future<void> deleteEntry(String entryId) async {
    await _db.deleteEntry(entryId);
  }

  // Search entries
  Future<List<JournalEntry>> searchEntries(String query) async {
    if (query.isEmpty) {
      return await loadEntries();
    }
    return await _db.searchEntries(query);
  }

  // Filter by date range
  Future<List<JournalEntry>> filterByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _db.filterByDateRange(start, end);
  }

  // Get entries by mood
  Future<List<JournalEntry>> filterByMood(String mood) async {
    return await _db.filterByMood(mood);
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    return await _db.getStatistics();
  }
}
