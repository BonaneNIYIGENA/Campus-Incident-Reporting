import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) {
    final value = _prefs.getString('theme_mode') ?? 'light';
    _mode = switch (value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  final SharedPreferences _prefs;
  ThemeMode _mode = ThemeMode.light;
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
