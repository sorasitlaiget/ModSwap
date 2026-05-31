import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/notification_model.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/dio_client.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

part 'auth_notifier.g.dart';

class AuthStateData {
  final AuthStatus status;
  final User? firebaseUser;
  final UserProfile? profile;
  final String? errorMessage;

  const AuthStateData({
    required this.status,
    this.firebaseUser,
    this.profile,
    this.errorMessage,
  });

  AuthStateData copyWith({
    AuthStatus? status,
    User? firebaseUser,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return AuthStateData(
      status: status ?? this.status,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late final AuthService _authService;
  late final ApiService _apiService;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;

  bool _processingAuthChange = false;

  @override
  AuthStateData build() {
    _authService = AuthService();
    final dioClient = DioClient(_authService);
    _apiService = ApiService(dioClient);

    _authSubscription = _authService.authStateChanges.listen(_onAuthChange);

    ref.onDispose(() {
      _authSubscription?.cancel();
      _profileSubscription?.cancel();
    });

    return const AuthStateData(status: AuthStatus.initializing);
  }

  Future<void> _onAuthChange(User? user) async {
    if (_processingAuthChange) {
      AppLogger.d('[AuthNotifier] Already processing, skipping...');
      return;
    }
    _processingAuthChange = true;

    try {
      AppLogger.d('[AuthNotifier] Auth state changed: user=${user?.uid}');

      if (user == null) {
        await _profileSubscription?.cancel();
        _profileSubscription = null;
        state = const AuthStateData(status: AuthStatus.unauthenticated);
        return;
      }

      state = state.copyWith(status: state.status, firebaseUser: user);

      try {
        await user.reload();
        await user.getIdToken(true);
      } catch (e) {
        AppLogger.e('[AuthNotifier] reload failed', error: e);
      }

      final refreshed = _authService.currentUser;
      if (refreshed == null) {
        state = const AuthStateData(status: AuthStatus.unauthenticated);
        return;
      }

      AppLogger.d(
        '[AuthNotifier] After reload: emailVerified=${refreshed.emailVerified}',
      );

      if (!refreshed.emailVerified) {
        AppLogger.d('[AuthNotifier] Setting status to emailUnverified');
        state = AuthStateData(
          status: AuthStatus.emailUnverified,
          firebaseUser: refreshed,
        );
        return;
      }

      AppLogger.d('[AuthNotifier] Email verified, fetching profile...');
      await _fetchProfile(refreshed);
    } finally {
      _processingAuthChange = false;
    }
  }

  Future<void> _fetchProfile(User user) async {
    try {
      final profile = await _apiService.getMyProfile();
      AppLogger.d(
        '[AuthNotifier] Profile loaded, isComplete=${profile.isProfileComplete}',
      );

      final newStatus = profile.isProfileComplete
          ? AuthStatus.authenticated
          : AuthStatus.profileIncomplete;

      state = AuthStateData(
        status: newStatus,
        firebaseUser: user,
        profile: profile,
      );

      _subscribeToProfileChanges(user.uid);
    } catch (e) {
      AppLogger.e('[AuthNotifier] Failed to fetch profile', error: e);
      state = AuthStateData(
        status: AuthStatus.profileIncomplete,
        firebaseUser: user,
        errorMessage: AuthService.parseErrorMessage(e),
      );
    }
  }

  void _subscribeToProfileChanges(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (doc) {
            if (!doc.exists || state.profile == null) return;
            final data = doc.data();
            if (data == null) return;

            final updated = state.profile!.mergeFromFirestore(data);
            if (updated == state.profile) return;

            AppLogger.d(
              '[AuthNotifier] Profile stats updated: rating=${updated.rating}, reviews=${updated.totalReviews}',
            );
            state = state.copyWith(profile: updated);
          },
          onError: (err) {
            AppLogger.e('[AuthNotifier] Profile listener error', error: err);
          },
        );
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(errorMessage: null);

    try {
      AppLogger.d('[AuthNotifier] login() called');
      await _authService.login(email: email, password: password);
      _verifyDeviceInBackground();
    } catch (e) {
      state = state.copyWith(errorMessage: AuthService.parseErrorMessage(e));
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(errorMessage: null);

    try {
      final user = await _authService.register(
        email: email,
        password: password,
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      await user.sendEmailVerification();
    } catch (e) {
      state = state.copyWith(errorMessage: AuthService.parseErrorMessage(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    AppLogger.d('[AuthNotifier] logout() called');
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    await _authService.logout();
    state = const AuthStateData(status: AuthStatus.unauthenticated);
  }

  Future<void> resendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email: email);
  }

  Future<bool> checkEmailVerified() async {
    await _authService.reloadUser();
    final user = _authService.currentUser;
    if (user == null) return false;

    if (user.emailVerified) {
      state = state.copyWith(firebaseUser: user);
      await _fetchProfile(user);
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
    final profile = await _apiService.completeProfile(
      displayName: displayName,
      studentId: studentId,
      faculty: faculty,
      lineId: lineId,
    );
    state = AuthStateData(
      status: AuthStatus.authenticated,
      firebaseUser: state.firebaseUser,
      profile: profile,
    );
  }

  Future<void> refreshProfile() async {
    final user = state.firebaseUser;
    if (user == null) return;
    await _fetchProfile(user);
  }

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
    state = state.copyWith(profile: updated);
    return updated;
  }

  Future<void> changePassword(String newPassword) async {
    await _apiService.changePassword(newPassword);
    final uid = state.firebaseUser?.uid;
    if (uid != null) {
      NotificationService()
          .send(
            recipientUid: uid,
            type: NotificationType.passwordChanged,
            title: 'Password Changed',
            body: 'Your password was changed successfully.',
          )
          .catchError((_) {});
    }
  }

  void _verifyDeviceInBackground() {
    _getOrCreateDeviceId()
        .then((id) => _apiService.verifyDevice(id))
        .catchError((_) {});
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
}
