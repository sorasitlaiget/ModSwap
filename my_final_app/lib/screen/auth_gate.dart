import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import 'complete_profile_screen.dart';
import 'main_navigation_screen.dart';

/// AuthGate watches AuthState and renders the correct screen.
/// Uses ListenableBuilder for direct Flutter subscription (most reliable).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthState>();
    AppLogger.d('[AuthGate] Build with auth instance: ${auth.hashCode}');

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        AppLogger.d('[AuthGate] ListenableBuilder rebuilt, status: ${auth.status}');

        switch (auth.status) {
          case AuthStatus.initializing:
            return const _SplashScreen(key: ValueKey('splash'));
          case AuthStatus.unauthenticated:
            return const LoginScreen(key: ValueKey('login'));
          case AuthStatus.emailUnverified:
            return const VerifyEmailScreen(key: ValueKey('verify'));
          case AuthStatus.profileIncomplete:
            return const CompleteProfileScreen(key: ValueKey('complete'));
          case AuthStatus.authenticated:
            return const MainNavigationScreen(key: ValueKey('main'));
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
    );
  }
}
