import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../providers/auth_notifier.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Forgot Password Screen — sends a password reset link via email
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .sendPasswordResetEmail(_emailCtrl.text.trim());

      if (!mounted) return;
      setState(() => _emailSent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.parseErrorMessage(e)),
          backgroundColor: AppColors.logoutRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  /// View shown before email is sent
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 2),
          Image.asset(
            AppConstants.logoFont,
            width: 300,
            fit: BoxFit.contain,
            semanticLabel: 'ModSwap',
          ),
          const SizedBox(height: 2),

          // Lock icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_outlined,
                size: 80,
                color: AppColors.orange,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          const Text(
            "Forgot Password?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          const Text(
            "Don't worry! Enter your email and we'll send you a link to reset your password.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Email field
          _FieldLabel("KMUTT Email"),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              hint: "student@mail.kmutt.ac.th",
              icon: Icons.email_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return "Please enter your email";
              }
              if (!v.endsWith(AppConstants.kmuttDomain)) {
                return "Must be a ${AppConstants.kmuttDomain} email";
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Send button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: _loading ? null : _handleSendReset,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Send Reset Link",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Back to login
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text(
              "Back to Login",
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// View shown after email is sent successfully
  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 2),
        Image.asset(
          AppConstants.logoFont,
          width: 300,
          fit: BoxFit.contain,
          semanticLabel: 'ModSwap',
        ),
        const SizedBox(height: 2),

        // Success icon
        Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 80,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Title
        const Text(
          "Check Your Email",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle
        const Text(
          "We've sent a password reset link to:",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textGray),
        ),
        const SizedBox(height: 8),

        // Email
        Text(
          _emailCtrl.text.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.orange,
          ),
        ),
        const SizedBox(height: 24),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.navy, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Next steps:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "1. Open your email inbox",
                style: TextStyle(fontSize: 13, color: AppColors.navy),
              ),
              SizedBox(height: 4),
              Text(
                "2. Click the reset link in the email",
                style: TextStyle(fontSize: 13, color: AppColors.navy),
              ),
              SizedBox(height: 4),
              Text(
                "3. Set a new password",
                style: TextStyle(fontSize: 13, color: AppColors.navy),
              ),
              SizedBox(height: 4),
              Text(
                "4. Return here and login",
                style: TextStyle(fontSize: 13, color: AppColors.navy),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Back to login button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Back to Login",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Resend link
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  setState(() => _emailSent = false);
                },
          child: const Text(
            "Didn't receive? Try again",
            style: TextStyle(color: AppColors.textGray, fontSize: 13),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.textGray, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
