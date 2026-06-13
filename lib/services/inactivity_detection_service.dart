import 'dart:async';
import 'package:flutter/foundation.dart';
import 'activity_monitoring_service.dart';
import 'alert_service.dart';
import 'auth_service.dart';

class InactivityDetectionService extends ChangeNotifier {
  static final InactivityDetectionService instance = InactivityDetectionService._internal();
  InactivityDetectionService._internal();

  Timer? _inactivityTimer;
  static const Duration _checkInterval = Duration(minutes: 5);
  static const Duration _inactivityThreshold = Duration(minutes: 30);

  void startMonitoring() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(_checkInterval, (_) => _checkInactivity());
    debugPrint('Inactivity monitoring started (Check every hour)');
  }

  void stopMonitoring() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  Future<void> _checkInactivity() async {
    try {
      final lastInteraction = ActivityMonitoringService.instance.lastInteractionTime;
      if (lastInteraction == null) return;

      final now = DateTime.now();
      final difference = now.difference(lastInteraction);

      if (difference > _inactivityThreshold) {
        final currentUser = await AuthService.instance.getCurrentUser();
        if (currentUser == null) return;

        debugPrint('Inactivity detected: $difference since last interaction');
        
        // Trigger alert
        await AlertService.instance.createAlert(
          patientId: currentUser.id,
          type: 'Inactivity',
          message: 'Patient hasn\'t interacted with the app for over 30 minutes. Last activity: ${lastInteraction.toLocal()}',
          severity: 'High',
        );
      }
    } catch (e) {
      debugPrint('Error checking inactivity: $e');
    }
  }

  /// Manually trigger a check (e.g., when app comes to foreground)
  Future<void> performManualCheck() async {
    await _checkInactivity();
  }
}
