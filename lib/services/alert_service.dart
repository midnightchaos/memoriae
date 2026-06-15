import 'package:flutter/foundation.dart';
import '../models/caregiver_alert.dart';
import 'database_helper.dart';

class AlertService extends ChangeNotifier {
  static final AlertService instance = AlertService._internal();
  AlertService._internal();

  Future<void> createAlert({
    required String patientId,
    required String type,
    required String message,
    required String severity,
  }) async {
    try {
      // Check if a similar active alert already exists to avoid spamming
      final existingAlerts = await DatabaseHelper.instance.getCaregiverAlerts(
        patientId,
      );
      final hasActiveSimilarAlert = existingAlerts.any(
        (a) =>
            a.type == type &&
            !a.isResolved &&
            DateTime.now().difference(a.timestamp).inHours < 12,
      );

      if (hasActiveSimilarAlert) {
        debugPrint(
          'Similar alert "$type" already exists and is unresolved. Skipping duplicate.',
        );
        return;
      }

      final alert = CaregiverAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: patientId,
        type: type,
        message: message,
        severity: severity,
        timestamp: DateTime.now(),
      );

      await DatabaseHelper.instance.insertCaregiverAlert(alert);
      debugPrint('Alert created: $type - $message');
      notifyListeners();

      // Note: In a production app, this is where you'd trigger
      // Firebase Cloud Messaging (FCM) to send a push notification to the caregiver.
    } catch (e) {
      debugPrint('Error creating alert: $e');
    }
  }

  Future<List<CaregiverAlert>> getAlerts(String patientId) async {
    return await DatabaseHelper.instance.getCaregiverAlerts(patientId);
  }

  Future<void> resolveAlert(String alertId) async {
    await DatabaseHelper.instance.resolveAlert(alertId);
    notifyListeners();
  }
}
