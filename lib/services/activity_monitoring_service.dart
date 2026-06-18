import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';
import 'database_helper.dart';
import 'auth_service.dart';
import 'alert_service.dart';
import 'analytics_service.dart';
import 'dart:async';

class ActivityMonitoringService extends ChangeNotifier {
  static final ActivityMonitoringService instance =
      ActivityMonitoringService._init();
  ActivityMonitoringService._init();

  // Activity Types
  static const String typeChat = 'C';
  static const String typeJournal = 'J';
  static const String typeGame = 'G';
  static const String typeTherapy = 'T';
  static const String typeFeedback = 'F';
  static const String typeIntervention = 'I';

  DateTime? _lastInteractionTime;
  DateTime? get lastInteractionTime => _lastInteractionTime;

  /// Log a patient activity
  Future<void> logActivity({
    required String type,
    required String description,
    int durationSeconds = 0,
  }) async {
    try {
      final currentUser = await AuthService.instance.getCurrentUser();
      if (currentUser == null) return;

      final log = ActivityLog(
        activityType: type,
        description: description,
        durationSeconds: durationSeconds,
        patientId: currentUser.id,
      );

      await DatabaseHelper.instance.insertActivityLog(log);
      _lastInteractionTime = DateTime.now();
      AnalyticsService.instance.invalidateCache();
      notifyListeners();

      // Update engagement score for today
      await updateDailyEngagementScore(currentUser.id);
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }

  /// Update last interaction time (for passive monitoring)
  void recordInteraction() {
    _lastInteractionTime = DateTime.now();
    notifyListeners();
  }

  /// Calculate and store today's engagement score: E = 2C + 10J + 5G
  Future<void> updateDailyEngagementScore(String patientId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get logs for today
      final logs = await DatabaseHelper.instance.getActivityLogs(patientId);
      final todayLogs = logs
          .where(
            (l) =>
                l.timestamp.year == today.year &&
                l.timestamp.month == today.month &&
                l.timestamp.day == today.day,
          )
          .toList();

      int chatCount = todayLogs.where((l) => l.activityType == typeChat).length;
      int journalCount = todayLogs
          .where((l) => l.activityType == typeJournal)
          .length;
      int gameCount = todayLogs.where((l) => l.activityType == typeGame).length;
      int therapyCount = todayLogs
          .where((l) => l.activityType == typeTherapy)
          .length;
      int feedbackCount = todayLogs
          .where((l) => l.activityType == typeFeedback)
          .length;

      // E = 2C + 10J + 5G
      double score =
          (2.0 * chatCount) + (10.0 * journalCount) + (5.0 * gameCount);

      await DatabaseHelper.instance.insertEngagementScore({
        'id': '${patientId}_${today.year}_${today.month}_${today.day}',
        'patientId': patientId,
        'date': today.toIso8601String(),
        'score': score,
        'chatCount': chatCount,
        'journalCount': journalCount,
        'gameCount': gameCount,
        'therapyCount': therapyCount,
        'feedbackCount': feedbackCount,
      });

      debugPrint('Updated engagement score for $today: $score');

      // Check for low engagement and trigger encouragement if needed
      await _checkForLowEngagement(patientId, score);
    } catch (e) {
      debugPrint('Error updating engagement score: $e');
    }
  }

  /// Get today's engagement score
  Future<Map<String, dynamic>?> getTodayEngagementScore(
    String patientId,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final history = await DatabaseHelper.instance.getEngagementHistory(
      patientId,
    );

    try {
      return history.firstWhere((s) {
        final date = DateTime.parse(s['date']);
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      });
    } catch (_) {
      return null;
    }
  }

  /// Trigger encouragement if engagement is low
  Future<void> _checkForLowEngagement(String patientId, double score) async {
    final now = DateTime.now();

    // Only check after 2 PM to give user time to be active
    if (now.hour < 14) return;

    // Threshold for day's end engagement
    const double lowEngagementThreshold = 15.0;

    if (score < lowEngagementThreshold) {
      await AlertService.instance.createAlert(
        patientId: patientId,
        type: 'Low Engagement',
        message:
            'Patient engagement score is low today ($score). Consider a gentle check-in or suggestive activity.',
        severity: 'Medium',
      );

      debugPrint('Low engagement detected for $patientId: $score');
    }
  }
}
