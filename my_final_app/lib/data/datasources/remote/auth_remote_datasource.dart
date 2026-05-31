import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/constants.dart';
import '../../../domain/entities/user_profile.dart';
import '../../network/dio_client.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final DioClient _client;

  AuthRemoteDataSource(this._auth, this._client);

  Stream<String?> get authStateUid =>
      _auth.authStateChanges().map((u) => u?.uid);

  String? get currentUserEmail => _auth.currentUser?.email;

  User? get currentUser => _auth.currentUser;

  Future<void> register(String email, String password) async {
    if (!email.endsWith(AppConstants.kmuttDomain)) {
      throw Exception('Please use a KMUTT email (${AppConstants.kmuttDomain})');
    }
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user == null) throw Exception('Registration failed');
  }

  Future<void> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user == null) throw Exception('Login failed');
  }

  Future<void> logout() => _auth.signOut();

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!email.endsWith(AppConstants.kmuttDomain)) {
      throw Exception('Please use a KMUTT email (${AppConstants.kmuttDomain})');
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserProfile> getProfile() async {
    final data = await _client.get<Map<String, dynamic>>('/auth/me');
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> completeProfile({
    required String displayName,
    required String studentId,
    required String faculty,
    required String lineId,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/auth/complete-profile',
      body: {
        'displayName': displayName,
        'studentId': studentId,
        'faculty': faculty,
        'lineId': lineId,
      },
    );
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile({
    String? displayName,
    String? studentId,
    String? faculty,
    String? lineId,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (studentId != null) body['studentId'] = studentId;
    if (faculty != null) body['faculty'] = faculty;
    if (lineId != null) body['lineId'] = lineId;
    final data = await _client.patch<Map<String, dynamic>>('/auth/profile', body: body);
    return UserProfile.fromJson(data);
  }

  Future<void> changePassword(String newPassword) async {
    await _client.patch<Map<String, dynamic>>(
      '/auth/password',
      body: {'newPassword': newPassword},
    );
  }

  Future<void> verifyDevice(String deviceId) async {
    await _client.post<Map<String, dynamic>>(
      '/auth/verify-device',
      body: {'deviceId': deviceId},
    );
  }

  String parseErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Invalid email format';
        case 'user-not-found':
          return 'No account found with this email';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password';
        case 'email-already-in-use':
          return 'This email is already registered';
        case 'weak-password':
          return 'Password is too weak';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later';
        case 'network-request-failed':
          return 'Network connection failed';
        case 'user-disabled':
          return 'This account has been disabled';
        default:
          return error.message ?? 'An error occurred';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
