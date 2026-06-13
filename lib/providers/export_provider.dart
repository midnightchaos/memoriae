import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_export_service.dart';

class ExportProvider with ChangeNotifier {
  final DataExportService _exportService;
  bool _isExporting = false;
  String? _lastExportDate;
  String? _exportError;

  ExportProvider(SharedPreferences prefs) : _exportService = DataExportService(prefs) {
    _loadLastExportDate();
    _checkScheduledExport();
  }

  bool get isExporting => _isExporting;
  String? get lastExportDate => _lastExportDate;
  String? get exportError => _exportError;

  Future<void> _loadLastExportDate() async {
    final lastExport = _exportService.getExportSettings()['lastExportDate'];
    if (lastExport != null) {
      _lastExportDate = lastExport;
      notifyListeners();
    }
  }

  Future<void> _checkScheduledExport() async {
    if (_exportService.isScheduledExportDue()) {
      // In a real app, you would trigger an automatic export here
      // For now, we'll just update the last export date
      await _updateLastExportDate();
    }
  }

  Future<void> exportData(String userId, {bool sendEmail = false}) async {
    if (_isExporting) return;

    _isExporting = true;
    _exportError = null;
    notifyListeners();

    try {
      if (sendEmail) {
        await _exportService.sendDataViaEmail(userId);
      } else {
        await _exportService.exportDataToFile(userId);
      }
      await _updateLastExportDate();
    } catch (e) {
      _exportError = e.toString();
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> _updateLastExportDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_export_date', DateTime.now().toIso8601String());
    _lastExportDate = DateTime.now().toIso8601String();
    notifyListeners();
  }

  Future<Map<String, dynamic>> getExportStats() async {
    final settings = _exportService.getExportSettings();
    return {
      'lastExport': _lastExportDate,
      'frequency': settings['frequency'] ?? 'manual',
      'email': settings['email'] ?? 'Not set',
    };
  }
}
