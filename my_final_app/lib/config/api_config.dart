import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Configuration
/// Toggle [useEmulator] to switch between local emulator and production
class ApiConfig {
  /// ⚠️ Replace with your Firebase Project ID
  static const String projectId = 'modswap-7b425';
  static const String region = 'asia-southeast1';

  /// Set to false when deploying to production
  static const bool useEmulator = true;

  /// Set to true เมื่อทดสอบกับมือถือจริง (ไม่ใช่ Simulator)
  /// emulator ต้องรันด้วย: firebase emulators:start --host 0.0.0.0
  static const bool useRealDevice = false;
  static const String _lanIp = '192.168.1.146';

  static String _resolveHost() {
    if (kIsWeb) return '127.0.0.1';
    if (useRealDevice) return _lanIp;
    return Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  }

  /// Base URL of the Backend API
  static String get apiBaseUrl {
    if (useEmulator) {
      return 'http://${_resolveHost()}:5001/$projectId/$region/api';
    }
    return 'https://$region-$projectId.cloudfunctions.net/api';
  }

  /// Host for Firebase Auth & Firestore Emulators
  static String get emulatorHost => _resolveHost();

  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;

  /// HTTP timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
