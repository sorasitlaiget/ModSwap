import '../entities/user_profile.dart';

abstract interface class AuthRepository {
  Stream<String?> get authStateUid;
  String? get currentUserEmail;
  Stream<UserProfile?> watchProfile(String uid);
  Stream<Map<String, dynamic>?> watchProfileData(String uid);

  Future<void> register(String email, String password);
  Future<void> login(String email, String password);
  Future<void> logout();

  Future<void> sendEmailVerification();
  Future<bool> checkEmailVerified();
  Future<void> sendPasswordResetEmail(String email);

  Future<UserProfile> getProfile();
  Future<UserProfile> completeProfile({
    required String displayName,
    required String studentId,
    required String faculty,
    required String lineId,
  });
  Future<UserProfile> updateProfile({
    String? displayName,
    String? studentId,
    String? faculty,
    String? lineId,
  });
  Future<void> changePassword(String newPassword);
  Future<void> verifyDevice(String deviceId);

  String? parseErrorMessage(Object error);
}
