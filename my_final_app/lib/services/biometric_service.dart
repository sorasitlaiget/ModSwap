import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyEmail = 'saved_email';
  static const _keyPassword = 'saved_password';
  static const _keyEnabled = 'biometric_enabled';

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final val = await _storage.read(key: _keyEnabled);
    return val == 'true';
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to sign in to ModSwap',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    await Future.wait([
      _storage.write(key: _keyEmail, value: email),
      _storage.write(key: _keyPassword, value: password),
      _storage.write(key: _keyEnabled, value: 'true'),
    ]);
  }

  Future<({String email, String password})?> loadCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  Future<void> clearCredentials() async {
    await Future.wait([
      _storage.delete(key: _keyEmail),
      _storage.delete(key: _keyPassword),
      _storage.write(key: _keyEnabled, value: 'false'),
    ]);
  }
}
