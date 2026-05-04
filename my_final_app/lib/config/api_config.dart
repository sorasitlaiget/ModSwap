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

  /// Base URL of the Backend API
  static String get apiBaseUrl {
    if (useEmulator) {
      // Android emulator uses 10.0.2.2 to access host machine
      // iOS simulator and Web use 127.0.0.1
      final host = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      return 'http://$host:5001/$projectId/$region/api';
    }
    return 'https://$region-$projectId.cloudfunctions.net/api';
  }

  /// Host for Firebase Auth & Firestore Emulators
  static String get emulatorHost {
    return !kIsWeb && Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  }

  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;

  /// HTTP timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
