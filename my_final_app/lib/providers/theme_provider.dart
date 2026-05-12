import 'package:flutter/material.dart';

/// Holds the app's current ThemeMode and exposes a toggle.
/// Listen with `context.watch<ThemeProvider>()` to rebuild on change.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void toggle(bool dark) {
    final newMode = dark ? ThemeMode.dark : ThemeMode.light;
    if (newMode == _mode) return;
    _mode = newMode;
    notifyListeners();
  }
}
