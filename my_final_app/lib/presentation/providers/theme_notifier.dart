import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_notifier.g.dart';

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;

  void setDark(bool dark) => state = dark ? ThemeMode.dark : ThemeMode.light;

  bool get isDark => state == ThemeMode.dark;
}
