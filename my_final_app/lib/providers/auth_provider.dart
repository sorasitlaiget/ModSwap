import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/dio_client.dart';
import '../services/notification_service.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  emailUnverified,
  profileIncomplete,
  authenticated,
}

class AuthState extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;

  StreamSubscription<User?>? _authSubscription;

  AuthStatus _status = AuthStatus.initializing;
  User? _firebaseUser;
  UserProfile? _profile;
  String? _errorMessage;

  bool _processingAuthChange = false;

  AuthState(this._authService, this._apiService) {
    _init();
  }

  factory AuthState.create() {
    final authService = AuthService();
    final dioClient = DioClient(authService);
    final apiService = ApiService(dioClient);
    return AuthState(authService, apiService);
  }

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _init() {
    _authSubscription = _authService.authStateChanges.listen(_onAuthChange);
  }

  Future<void> _onAuthChange(User? user) async {
    if (_processingAuthChange) {
      debugPrint('[AuthState] Already processing, skipping...');
      return;
    }
    _processingAuthChange = true;

    try {
      debugPrint('[AuthState] Auth state changed: user=${user?.email}');

      if (user == null) {
        _firebaseUser = null;
        _profile = null;
        _setStatus(AuthStatus.unauthenticated);
        return;
      }

      _firebaseUser = user;

      try {
        await user.reload();
        await user.getIdToken(true);
      } catch (e) {
        debugPrint('[AuthState] reload failed: $e');
      }

      final refreshed = _authService.currentUser;
      if (refreshed == null) {
        _firebaseUser = null;
        _profile = null;
        _setStatus(AuthStatus.unauthenticated);
        return;
      }

      _firebaseUser = refreshed;
      debugPrint(
          '[AuthState] After reload: emailVerified=${refreshed.emailVerified}');

      if (!refreshed.emailVerified) {
        debugPrint('[AuthState] Setting status to emailUnverified');
        _profile = null;
        _setStatus(AuthStatus.emailUnverified);
        return;
      }

      debugPrint('[AuthState] Email verified, fetching profile...');
      await _fetchProfile();
    } finally {
      _processingAuthChange = false;
    }
  }

  Future<void> _fetchProfile() async {
    try {
      _profile = await _apiService.getMyProfile();
      debugPrint(
          '[AuthState] Profile loaded, isComplete=${_profile!.isProfileComplete}');

      if (_profile!.isProfileComplete) {
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.profileIncomplete);
      }
    } catch (e) {
      debugPrint('[AuthState] Failed to fetch profile: $e');
      _errorMessage = AuthService.parseErrorMessage(e);
      _setStatus(AuthStatus.profileIncomplete);
    }
  }

  void _setStatus(AuthStatus newStatus) {
    final oldStatus = _status;
    _status = newStatus;
    debugPrint(
        '[AuthState] Status: $oldStatus → $newStatus, notifying listeners...');
    notifyListeners();
  }

  // === Public actions ===

  Future<void> register({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        email: email,
        password: password,
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      await user.sendEmailVerification();
    } catch (e) {
      _errorMessage = AuthService.parseErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;

    try {
      debugPrint('[AuthState] login() called for $email');
      await _authService.login(email: email, password: password);
      debugPrint(
          '[AuthState] login() succeeded — waiting for authStateChanges to fire');
      // Fire-and-forget: check if this is a new device
      _verifyDeviceInBackground();
    } catch (e) {
      _errorMessage = AuthService.parseErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    debugPrint('[AuthState] logout() called');
    await _authService.logout();
    _firebaseUser = null;
    _profile = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  Future<void> resendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  /// ⭐ Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email: email);
  }

  Future<bool> checkEmailVerified() async {
    await _authService.reloadUser();
    final user = _authService.currentUser;
    if (user == null) return false;

    if (user.emailVerified) {
      _firebaseUser = user;
      await _fetchProfile();
      return true;
    }
    return false;
  }

  Future<void> completeProfile({
    required String displayName,
    required String studentId,
    required String faculty,
    required String lineId,
  }) async {
    _profile = await _apiService.completeProfile(
      displayName: displayName,
      studentId: studentId,
      faculty: faculty,
      lineId: lineId,
    );
    _setStatus(AuthStatus.authenticated);
  }

  Future<void> refreshProfile() async {
    await _fetchProfile();
  }

  /// PATCH any subset of profile fields. Pass null to skip a field.
  /// Returns updated profile; also stored in state and notifies listeners.
  Future<UserProfile> updateProfile({
    String? displayName,
    String? studentId,
    String? faculty,
    String? lineId,
  }) async {
    final updated = await _apiService.updateProfile(
      displayName: displayName,
      studentId: studentId,
      faculty: faculty,
      lineId: lineId,
    );
    _profile = updated;
    notifyListeners();
    return updated;
  }

  Future<void> changePassword(String newPassword) async {
    await _apiService.changePassword(newPassword);
    final uid = _firebaseUser?.uid;
    if (uid != null) {
      NotificationService().send(
        recipientUid: uid,
        type: NotificationType.passwordChanged,
        title: 'Password Changed',
        body: 'Your password was changed successfully.',
      ).catchError((_) {});
    }
  }

  void _verifyDeviceInBackground() {
    _getOrCreateDeviceId().then((id) => _apiService.verifyDevice(id)).catchError((_) {});
  }

  Future<String> _getOrCreateDeviceId() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/modswap_device_id.txt');
      if (await file.exists()) return (await file.readAsString()).trim();
      final id = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await file.writeAsString(id);
      return id;
    } catch (_) {
      return 'device_unknown';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
