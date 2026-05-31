import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/complete_profile_usecase.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/update_profile_usecase.dart';
import '../../presentation/di/providers.dart';
import '../../utils/logger.dart';
import 'auth_provider.dart';

part 'auth_notifier.g.dart';

class AuthStateData {
  final AuthStatus status;
  final String? uid;
  final String? email;
  final UserProfile? profile;
  final String? errorMessage;

  const AuthStateData({
    required this.status,
    this.uid,
    this.email,
    this.profile,
    this.errorMessage,
  });

  AuthStateData copyWith({
    AuthStatus? status,
    String? uid,
    String? email,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return AuthStateData(
      status: status ?? this.status,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late AuthRepository _repo;
  late LoginUseCase _login;
  late RegisterUseCase _register;
  late LogoutUseCase _logout;
  late CompleteProfileUseCase _completeProfile;
  late UpdateProfileUseCase _updateProfile;

  StreamSubscription<String?>? _authSub;
  StreamSubscription<Map<String, dynamic>?>? _profileSub;
  bool _processing = false;

  @override
  AuthStateData build() {
    _repo = ref.read(authRepositoryProvider);
    _login = ref.read(loginUseCaseProvider);
    _register = ref.read(registerUseCaseProvider);
    _logout = ref.read(logoutUseCaseProvider);
    _completeProfile = ref.read(completeProfileUseCaseProvider);
    _updateProfile = ref.read(updateProfileUseCaseProvider);

    _authSub = _repo.authStateUid.listen(_onUidChange);

    ref.onDispose(() {
      _authSub?.cancel();
      _profileSub?.cancel();
    });

    return const AuthStateData(status: AuthStatus.initializing);
  }

  Future<void> _onUidChange(String? uid) async {
    if (_processing) return;
    _processing = true;
    try {
      AppLogger.d('[AuthNotifier] uid changed: $uid');
      if (uid == null) {
        _profileSub?.cancel();
        _profileSub = null;
        state = const AuthStateData(status: AuthStatus.unauthenticated);
        return;
      }

      final email = _repo.currentUserEmail;
      final verified = await _repo.checkEmailVerified();
      if (!verified) {
        state = AuthStateData(status: AuthStatus.emailUnverified, uid: uid, email: email);
        return;
      }

      await _fetchProfile(uid);
    } finally {
      _processing = false;
    }
  }

  Future<void> _fetchProfile(String uid) async {
    try {
      final profile = await _repo.getProfile();
      final newStatus = profile.isProfileComplete
          ? AuthStatus.authenticated
          : AuthStatus.profileIncomplete;
      state = AuthStateData(status: newStatus, uid: uid, profile: profile);
      _subscribeToProfileChanges(uid);
    } catch (e) {
      AppLogger.e('[AuthNotifier] Failed to fetch profile', error: e);
      state = AuthStateData(
        status: AuthStatus.profileIncomplete,
        uid: uid,
        errorMessage: _repo.parseErrorMessage(e),
      );
    }
  }

  void _subscribeToProfileChanges(String uid) {
    _profileSub?.cancel();
    _profileSub = _repo.watchProfileData(uid).listen(
      (data) {
        if (data == null || state.profile == null) return;
        final updated = state.profile!.mergeFromFirestore(data);
        if (updated == state.profile) return;
        AppLogger.d('[AuthNotifier] Profile stats updated from Firestore');
        state = state.copyWith(profile: updated);
      },
      onError: (Object err) {
        AppLogger.e('[AuthNotifier] Profile listener error', error: err);
      },
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(errorMessage: null);
    try {
      await _login(email, password);
      _verifyDeviceInBackground();
    } catch (e) {
      state = state.copyWith(errorMessage: _repo.parseErrorMessage(e));
      rethrow;
    }
  }

  Future<void> register({required String email, required String password}) async {
    state = state.copyWith(errorMessage: null);
    try {
      await _register(email, password);
      await Future.delayed(const Duration(milliseconds: 1500));
      await _repo.sendEmailVerification();
    } catch (e) {
      state = state.copyWith(errorMessage: _repo.parseErrorMessage(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    AppLogger.d('[AuthNotifier] logout()');
    _profileSub?.cancel();
    _profileSub = null;
    await _logout();
    state = const AuthStateData(status: AuthStatus.unauthenticated);
  }

  Future<void> resendVerificationEmail() => _repo.sendEmailVerification();

  Future<void> sendPasswordResetEmail(String email) =>
      _repo.sendPasswordResetEmail(email);

  Future<bool> checkEmailVerified() async {
    final verified = await _repo.checkEmailVerified();
    if (verified && state.uid != null) await _fetchProfile(state.uid!);
    return verified;
  }

  Future<void> completeProfile({
    required String displayName,
    required String studentId,
    required String faculty,
    required String lineId,
  }) async {
    final profile = await _completeProfile(
      displayName: displayName,
      studentId: studentId,
      faculty: faculty,
      lineId: lineId,
    );
    state = AuthStateData(
      status: AuthStatus.authenticated,
      uid: state.uid,
      profile: profile,
    );
  }

  Future<void> refreshProfile() async {
    if (state.uid == null) return;
    await _fetchProfile(state.uid!);
  }

  Future<UserProfile> updateProfile({
    String? displayName,
    String? studentId,
    String? faculty,
    String? lineId,
  }) async {
    final updated = await _updateProfile(
      displayName: displayName,
      studentId: studentId,
      faculty: faculty,
      lineId: lineId,
    );
    state = state.copyWith(profile: updated);
    return updated;
  }

  Future<void> changePassword(String newPassword) =>
      _repo.changePassword(newPassword);

  void _verifyDeviceInBackground() {
    _getOrCreateDeviceId()
        .then((id) => _repo.verifyDevice(id))
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
