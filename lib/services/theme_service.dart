import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, blackMinimalism }

class ThemeService extends ChangeNotifier {
  static const _key = 'theme_mode';
  AppThemeMode _themeMode = AppThemeMode.light;
  AppThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == AppThemeMode.dark || _themeMode == AppThemeMode.blackMinimalism;
  bool get isDarkMode => isDark;

  ThemeService() {
    load();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_key) ?? 0;
      _themeMode = AppThemeMode.values[themeIndex];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    try {
      _themeMode = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, mode.index);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme: $e');
      rethrow;
    }
  }

  Future<void> toggle() async {
    // Legacy support for toggle button - cycles through themes
    final nextIndex = (_themeMode.index + 1) % AppThemeMode.values.length;
    await setTheme(AppThemeMode.values[nextIndex]);
  }
}
