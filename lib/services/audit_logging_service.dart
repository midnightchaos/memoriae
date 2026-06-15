import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'auth_service.dart';

class AuditLog {
  final String? id;
  final String caregiverId;
  final String action;
  final String details;
  final DateTime timestamp;

  AuditLog({
    this.id,
    required this.caregiverId,
    required this.action,
    required this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'caregiverId': caregiverId,
      'action': action,
      'details': details,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id']?.toString(),
      caregiverId: map['caregiverId'],
      action: map['action'],
      details: map['details'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

class AuditLoggingService extends ChangeNotifier {
  static final AuditLoggingService instance = AuditLoggingService._internal();
  AuditLoggingService._internal();

  Future<void> logAction({
    required String action,
    required String details,
  }) async {
    try {
      final user = await AuthService.instance.getCurrentUser();
      if (user == null) return;

      final log = AuditLog(
        caregiverId: user.id,
        action: action,
        details: details,
      );

      await DatabaseHelper.instance.insertAuditLog(log);
      debugPrint('Audit Log: $action - $details');
    } catch (e) {
      debugPrint('Error logging audit action: $e');
    }
  }

  Future<List<AuditLog>> getLogs({String? caregiverId}) async {
    final result = await DatabaseHelper.instance.getAuditLogs(
      caregiverId: caregiverId,
    );
    return result
        .map((m) => AuditLog.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}
