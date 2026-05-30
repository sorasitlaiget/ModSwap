import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AppLogger {
  AppLogger._();

  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log(message, name: tag ?? 'ModSwap', level: 500);
    }
  }

  static void i(String message, {String? tag}) {
    dev.log(message, name: tag ?? 'ModSwap', level: 800);
  }

  static void w(String message, {String? tag}) {
    dev.log(message, name: tag ?? 'ModSwap', level: 900);
  }

  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      message,
      name: tag ?? 'ModSwap',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }
}
