import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

/// Shown when user is logged in but email hasn't been verified yet.
/// Auto-checks every 3 seconds in case user clicks the link in another tab.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _checkTimer;
  bool _resending = false;
  bool _checkingNow = false;
  bool _verifiedNotifSent = false;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  void _startAutoCheck() {
    _checkTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkVerified(silent: true),
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _checkingNow = true);

    try {
      final auth = context.read<AuthState>();
      final verified = await auth.checkEmailVerified();

      if (verified && !_verifiedNotifSent) {
        _verifiedNotifSent = true;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          NotificationService().send(
            recipientUid: uid,
            type: NotificationType.emailVerified,
            title: 'Email Verified',
            body: 'Your @mail.kmutt.ac.th account is now verified',
          ).catchError((_) {});
        }
      }

      if (!silent && !verified && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email not verified yet. Please click the link."),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _checkingNow = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _resending = true);
    try {
      await context.read<AuthState>().resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification email sent again"),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.logoutRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _useDifferentAccount() async {
    await context.read<AuthState>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().firebaseUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const SizedBox(height: 2),
              Image.asset(
                AppConstants.logoFont,
                width: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We've sent a verification link to:",
                style: TextStyle(color: AppColors.textGray),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.navy,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "After clicking the link, this screen will refresh automatically.",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Refresh button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _checkingNow ? null : () => _checkVerified(),
                  icon: _checkingNow
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    "I've Verified My Email",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Resend button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.navy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _resending ? null : _resendEmail,
                  icon: _resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.navy,
                          ),
                        )
                      : const Icon(Icons.send_outlined, color: AppColors.navy),
                  label: const Text(
                    "Resend Email",
                    style: TextStyle(color: AppColors.navy, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Use different account
              TextButton(
                onPressed: _useDifferentAccount,
                child: const Text(
                  "Use a different account",
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
