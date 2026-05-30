import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_colors.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isObscured = true;
  bool _loading = false;
  bool _rememberMe = true;
  String? _loginError;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.instance.isAvailable();
    final enabled = await BiometricService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _loginError = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      final auth = context.read<AuthState>();
      if (_rememberMe && _biometricAvailable) {
        await BiometricService.instance.saveCredentials(email, password);
      }
      await auth.login(email: email, password: password);
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = AuthService.parseErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await BiometricService.instance.authenticate();
    if (!authenticated || !mounted) return;

    final creds = await BiometricService.instance.loadCredentials();
    if (creds == null || !mounted) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthState>().login(
        email: creds.email,
        password: creds.password,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = AuthService.parseErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    const SizedBox(height: 24),
                    // Logos
                    Image.asset(
                      AppConstants.logoMascot,
                      height: 180,
                      fit: BoxFit.contain,
                      semanticLabel: 'ModSwap mascot logo',
                    ),
                    const SizedBox(height: 2),
                    Image.asset(
                      AppConstants.logoFont,
                      height: 120,
                      fit: BoxFit.contain,
                      semanticLabel: 'ModSwap',
                    ),
                    const SizedBox(height: 2),

                    // Welcome text
                    const Text(
                      "Welcome Back",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Login to your KMUTT account",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textGray),
                    ),
                    const SizedBox(height: 28),

                    // Email
                    _FieldLabel("KMUTT Email"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hint: "student@mail.kmutt.ac.th",
                        icon: Icons.email_outlined,
                        hasError: _loginError != null,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Please enter your email";
                        }
                        if (!v.endsWith(AppConstants.kmuttDomain)) {
                          return "Must end with ${AppConstants.kmuttDomain}";
                        }
                        return null;
                      },
                    ),

                    // ⭐ Error message ใต้ field
                    if (_loginError != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          _loginError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Password
                    _FieldLabel("Password"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _isObscured,
                      decoration:
                          _inputDecoration(
                            hint: "Enter your password",
                            icon: Icons.lock_outline,
                            hasError: _loginError != null,
                          ).copyWith(
                            suffixIcon: IconButton(
                              tooltip: _isObscured ? 'Show password' : 'Hide password',
                              icon: Icon(
                                _isObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textGray,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _isObscured = !_isObscured),
                            ),
                          ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Please enter your password";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    // Remember Me + Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Remember Me",
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                        Semantics(
                          button: true,
                          label: 'Forgot Password',
                          child: GestureDetector(
                            onTap: _loading
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  ),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Login button
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
                        onPressed: _loading ? null : _handleLogin,
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
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    if (_biometricAvailable && _biometricEnabled) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or',
                              style: TextStyle(color: AppColors.textGray),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.navy),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: _loading ? null : _handleBiometricLogin,
                          icon: const Icon(Icons.fingerprint, color: AppColors.navy),
                          label: const Text(
                            'Sign in with Biometrics',
                            style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "New to ModSwap? ",
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Register a new account',
                          child: GestureDetector(
                            onTap: _loading
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    bool hasError = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.textGray, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      filled: true,
      fillColor: Colors.white,

      // ⭐ ปกติ (ยังไม่ focus, ยังไม่ error) — เทาอ่อน
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
      ),

      // ⭐ ตอน focus (คลิกแล้วกำลังพิมพ์) — ส้ม
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: hasError ? Colors.red : AppColors.orange,
          width: 1.8,
        ),
      ),

      // Error state (จาก validator)
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
