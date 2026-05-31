import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/notification_model.dart';
import '../providers/auth_notifier.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _facultyCtrl = TextEditingController();
  final _lineIdCtrl = TextEditingController();

  bool _loading = false;
  String? _studentIdError;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _studentIdCtrl.dispose();
    _facultyCtrl.dispose();
    _lineIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      try {
        await notifier.completeProfile(
          displayName: _displayNameCtrl.text.trim(),
          studentId: _studentIdCtrl.text.trim(),
          faculty: _facultyCtrl.text.trim(),
          lineId: _lineIdCtrl.text.trim(),
        );
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('already completed') ||
            msg.contains('Profile already')) {
          await notifier.refreshProfile();
          return;
        }
        rethrow;
      }
      // Fire-and-forget: send welcome notification
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        NotificationService()
            .send(
              recipientUid: uid,
              type: NotificationType.welcome,
              title: 'Welcome to ModSwap!',
              body: 'Start buying, selling, and swapping with KMUTT',
            )
            .catchError((_) {});
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('STUDENT_ID_CONFLICT') ||
          msg.contains('Student ID is already in use')) {
        setState(() => _studentIdError = 'Student ID is already in use');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.logoutRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
                    const SizedBox(height: 16),
                    Image.asset(
                      AppConstants.logoMascot,
                      height: 180,
                      fit: BoxFit.contain,
                      semanticLabel: 'ModSwap mascot logo',
                    ),
                    const SizedBox(height: 4),
                    Image.asset(
                      AppConstants.logoFont,
                      height: 120,
                      fit: BoxFit.contain,
                      semanticLabel: 'ModSwap',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Complete Your Profile",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Almost there! Fill in your details so other students can contact you.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textGray),
                    ),
                    const SizedBox(height: 24),

                    _FieldLabel("Display Name"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _displayNameCtrl,
                      decoration: _inputDecoration(
                        hint: "e.g., John",
                        icon: Icons.person_outline,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Please enter your display name";
                        }
                        if (v.trim().isEmpty) {
                          return "At least 1 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel("Student ID"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _studentIdCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: AppConstants.studentIdLength,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        if (_studentIdError != null) {
                          setState(() => _studentIdError = null);
                        }
                      },
                      decoration: _inputDecoration(
                        hint:
                            "${AppConstants.studentIdLength}-digit student ID",
                        icon: Icons.badge_outlined,
                        hasError: _studentIdError != null,
                      ).copyWith(counterText: ''),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Please enter your student ID";
                        }
                        if (v.trim().length != AppConstants.studentIdLength) {
                          return "Student ID must be exactly "
                              "${AppConstants.studentIdLength} digits";
                        }
                        if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                          return "Student ID must contain only digits";
                        }
                        return null;
                      },
                    ),
                    if (_studentIdError != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          _studentIdError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    _FieldLabel("Faculty"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _facultyCtrl,
                      decoration: _inputDecoration(
                        hint: "e.g., Engineering",
                        icon: Icons.school_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Please enter your faculty";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel("Line ID"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lineIdCtrl,
                      decoration: _inputDecoration(
                        hint: "Used for closing deals with buyers",
                        icon: Icons.chat_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Please enter your Line ID";
                        }
                        if (v.trim().isEmpty) {
                          return "At least 1 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

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
                        onPressed: _loading ? null : _handleSubmit,
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
                                "Save & Continue",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: AppColors.softGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: hasError
            ? const BorderSide(color: Colors.red, width: 1)
            : BorderSide.none,
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
