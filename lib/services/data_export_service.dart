import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:menta/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DataExportService {
  static const String _caregiverEmailKey = 'caregiver_email';
  static const String _exportFrequencyKey = 'export_frequency';
  static const String _lastExportDateKey = 'last_export_date';

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SharedPreferences _prefs;

  DataExportService(this._prefs);

  // Save caregiver email and export preferences
  Future<void> saveExportSettings({
    required String email,
    required String frequency,
  }) async {
    await _prefs.setString(_caregiverEmailKey, email);
    await _prefs.setString(_exportFrequencyKey, frequency);
  }

  // Get current export settings
  Map<String, String> getExportSettings() {
    return {
      'email': _prefs.getString(_caregiverEmailKey) ?? '',
      'frequency': _prefs.getString(_exportFrequencyKey) ?? 'manual',
    };
  }

  // Generate a comprehensive JSON report of all user data
  Future<Map<String, dynamic>> generateReport(String userId) async {
    try {
      // Get all data from database
      final user = await _dbHelper.getUserById(userId);
      final journalEntries = await _dbHelper.readAllEntries();
      final familiarFaces = await _dbHelper.getFamiliarFaces(userId);
      final medications = await _dbHelper.getMedications(userId);
      final routines = await _dbHelper.getDailyRoutines(userId);
      final safetyLocations = await _dbHelper.getSafetyLocations(userId);
      final gameProgress = await _dbHelper.getGameProgress(userId);

      // Compile the report
      final report = {
        'metadata': {
          'generatedAt': DateTime.now().toIso8601String(),
          'appVersion': '1.0.0',
        },
        'user': user?.toMap(),
        'journalEntries': journalEntries.map((e) => _entryToMap(e)).toList(),
        'familiarFaces': familiarFaces.map((f) => f.toMap()).toList(),
        'medications': medications.map((m) => m.toMap()).toList(),
        'dailyRoutines': routines.map((r) => r.toMap()).toList(),
        'safetyLocations': safetyLocations.map((l) => l.toMap()).toList(),
        'gameProgress': gameProgress.map((g) => g.toMap()).toList(),
      };

      return report;
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  // Convert journal entry to map (helper method)
  Map<String, dynamic> _entryToMap(dynamic entry) {
    if (entry is Map) return Map<String, dynamic>.from(entry);
    return {};
  }

  // Export data to a JSON file and share it
  Future<void> exportDataToFile(String userId) async {
    try {
      final report = await generateReport(userId);
      final jsonString = JsonEncoder.withIndent('  ').convert(report);

      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'memoriae_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(path.join(directory.path, fileName));

      // Write the file
      await file.writeAsString(jsonString);

      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Memoriae Data Export',
          text: 'Here is your Memoriae data export from ${DateTime.now()}',
        ),
      );

      // Update last export date
      await _prefs.setString(
        _lastExportDateKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  // Send data via email (requires email configuration)
  Future<void> sendDataViaEmail(String userId, {String? recipientEmail}) async {
    try {
      final email = recipientEmail ?? _prefs.getString(_caregiverEmailKey);
      if (email == null || email.isEmpty) {
        throw Exception('No recipient email provided');
      }

      final report = await generateReport(userId);
      final jsonString = JsonEncoder.withIndent('  ').convert(report);

      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'memoriae_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(path.join(directory.path, fileName));
      await file.writeAsString(jsonString);

      // In a real app, you would configure your email server here
      // This is a placeholder that would need to be configured with actual SMTP settings
      final smtpServer = SmtpServer(
        'smtp.example.com',
        username: 'your_email@example.com',
        password: 'your_password',
        port: 587,
        ssl: false,
        allowInsecure: true, // Only for testing with self-signed certificates
      );

      // Create the email message
      final message = Message()
        ..from = const Address('noreply@memoriae.app', 'Memoriae App')
        ..recipients.add(email)
        ..subject = 'Memoriae Data Export - ${DateTime.now()}'
        ..text = 'Please find attached your Memoriae data export.'
        ..attachments = [FileAttachment(file)..location = Location.inline];

      // Send the email
      await send(message, smtpServer);

      // Update last export date
      await _prefs.setString(
        _lastExportDateKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  // Check if it's time for a scheduled export
  bool isScheduledExportDue() {
    final lastExport = _prefs.getString(_lastExportDateKey);
    if (lastExport == null) return false;

    final lastExportDate = DateTime.parse(lastExport);
    final frequency = _prefs.getString(_exportFrequencyKey) ?? 'manual';
    final now = DateTime.now();

    switch (frequency) {
      case 'daily':
        return now.difference(lastExportDate).inHours >= 24;
      case 'weekly':
        return now.difference(lastExportDate).inDays >= 7;
      case 'monthly':
        return now.year > lastExportDate.year ||
            now.month > lastExportDate.month;
      default:
        return false;
    }
  }
}
