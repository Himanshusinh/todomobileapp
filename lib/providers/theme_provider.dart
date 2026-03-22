import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({bool initialIsDark = false}) : _isDarkMode = initialIsDark;

  /// SharedPreferences key (read in [main] before [runApp]).
  static const preferenceKeyDarkMode = 'app_dark_mode';

  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  /// Persists choice so light/dark applies app-wide after restart.
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(preferenceKeyDarkMode, _isDarkMode);
  }

  Future<void> toggleTheme() => setDarkMode(!_isDarkMode);
}
