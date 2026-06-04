import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _ds;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl(this._ds, this._firestore);

  @override
  Stream<String?> get authStateUid => _ds.authStateUid;

  @override
  String? get currentUserEmail => _ds.currentUserEmail;

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return watchProfileData(
      uid,
    ).map((data) => null); // use watchProfileData for merging
  }

  @override
  Stream<Map<String, dynamic>?> watchProfileData(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  @override
  Future<void> register(String email, String password) =>
      _ds.register(email, password);

  @override
  Future<void> login(String email, String password) =>
      _ds.login(email, password);

  @override
  Future<void> logout() => _ds.logout();

  @override
  Future<void> sendEmailVerification() => _ds.sendEmailVerification();

  @override
  Future<bool> checkEmailVerified() => _ds.checkEmailVerified();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _ds.sendPasswordResetEmail(email);

  @override
  Future<UserProfile> getProfile() => _ds.getProfile();

  @override
  Future<UserProfile> completeProfile({
    required String displayName,
    required String studentId,
    required String faculty,
    required String lineId,
  }) => _ds.completeProfile(
    displayName: displayName,
    studentId: studentId,
    faculty: faculty,
    lineId: lineId,
  );

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    String? studentId,
    String? faculty,
    String? lineId,
  }) => _ds.updateProfile(
    displayName: displayName,
    studentId: studentId,
    faculty: faculty,
    lineId: lineId,
  );

  @override
  Future<void> changePassword(String newPassword) =>
      _ds.changePassword(newPassword);

  @override
  Future<void> verifyDevice(String deviceId) => _ds.verifyDevice(deviceId);

  @override
  String? parseErrorMessage(Object error) => _ds.parseErrorMessage(error);
}
