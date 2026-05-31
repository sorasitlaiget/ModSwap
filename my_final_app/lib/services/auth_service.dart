import 'package:firebase_auth/firebase_auth.dart';
import '../config/constants.dart';

/// Authentication Service - wraps Firebase Auth operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with email and password
  Future<User> register({
    required String email,
    required String password,
  }) async {
    if (!email.endsWith(AppConstants.kmuttDomain)) {
      throw Exception('Please use a KMUTT email (${AppConstants.kmuttDomain})');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      throw Exception('Registration failed');
    }

    return credential.user!;
  }

  /// Sign in with email and password
  Future<User> login({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      throw Exception('Login failed');
    }

    return credential.user!;
  }

  /// Sign out
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    if (user.emailVerified) {
      return;
    }
    await user.sendEmailVerification();
  }

  /// ⭐ Send password reset email
  /// Firebase will send an email with a link to reset password.
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (!email.endsWith(AppConstants.kmuttDomain)) {
      throw Exception('Please use a KMUTT email (${AppConstants.kmuttDomain})');
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Reload user data from Firebase (to check if email is verified)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Get Firebase ID Token (for Backend API authentication)
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Convert FirebaseAuthException into a user-friendly message
  static String parseErrorMessage(Object error) {
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
