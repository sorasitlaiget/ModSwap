import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _agree = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _loading = false;
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ค้นหาตำแหน่งใต้ตัวแปร bool ต่างๆ แล้วเพิ่มฟังก์ชันนี้ครับ
  void _onPasswordChanged(String value) {
    setState(() {
      _hasMinLength = value.length >= AppConstants.passwordMinLength;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must agree to the Terms & Conditions.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthState>();
      await auth.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;
      await _showCheckEmailDialog(_emailCtrl.text.trim());

      if (!mounted) return;
      // Pop register screen so AuthGate can take over
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(AuthService.parseErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCheckEmailDialog(String email) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: AppColors.orange,
          ),
        ),
        title: const Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "We've sent a verification link to:",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepRow(number: '1', text: 'Open your email inbox'),
                  SizedBox(height: 6),
                  _StepRow(number: '2', text: 'Click the verification link'),
                  SizedBox(height: 6),
                  _StepRow(
                    number: '3',
                    text: 'Return here — auto-detect verification',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.logoutRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ⭐ No AppBar - removed back button
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Image.asset(
                      AppConstants.logoMascot,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 2),
                    Image.asset(
                      AppConstants.logoFont,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Create Account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Join ModSwap with your KMUTT email",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textGray),
                    ),
                    const SizedBox(height: 24),

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
                          return "Only KMUTT email is allowed";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel("Password"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _isPasswordObscured,
                      onChanged: _onPasswordChanged,
                      decoration:
                          _inputDecoration(
                            hint: "enter your password",
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textGray,
                                size: 20,
                              ),
                              onPressed: () => setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              }),
                            ),
                          ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Please enter a password";
                        }
                        if (!_hasMinLength ||
                            !_hasUppercase ||
                            !_hasLowercase) {
                          return "Please fulfill all password requirements";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          _buildReqItem("At least 8 characters", _hasMinLength),
                          _buildReqItem(
                            "Contains uppercase (A-Z)",
                            _hasUppercase,
                          ),
                          _buildReqItem(
                            "Contains lowercase (a-z)",
                            _hasLowercase,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel("Confirm Password"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _isConfirmPasswordObscured,
                      decoration:
                          _inputDecoration(
                            hint: "Re-enter your password",
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textGray,
                                size: 20,
                              ),
                              onPressed: () => setState(() {
                                _isConfirmPasswordObscured =
                                    !_isConfirmPasswordObscured;
                              }),
                            ),
                          ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Please confirm your password";
                        }
                        if (v != _passCtrl.text) {
                          return "Passwords don't match";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agree,
                            activeColor: AppColors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) =>
                                setState(() => _agree = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "I agree to the Terms & Conditions",
                              style: TextStyle(
                                fontSize: 12,
                                color: _agree
                                    ? AppColors.textGray
                                    : Colors.red.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                        onPressed: _loading ? null : _handleRegister,
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
                                "Register",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ⭐ Already have an account? Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: _loading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.textGray, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: AppColors.softGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildReqItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet ? Colors.green : AppColors.textGray,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : AppColors.textGray,
              fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.navy),
          ),
        ),
      ],
    );
  }
}
