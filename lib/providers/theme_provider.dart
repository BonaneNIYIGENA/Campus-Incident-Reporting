import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) {
    final value = _prefs.getString('theme_mode') ?? 'system';
    _mode = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  final SharedPreferences _prefs;
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode value) async {
    _mode = value;
    await _prefs.setString('theme_mode', switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    notifyListeners();
  }
}
