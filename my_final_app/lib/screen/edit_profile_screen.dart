import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_ext.dart';

/// Edit Profile screen.
/// Allows the signed-in user to update:
/// - Display Name
/// - Student ID
/// - Faculty
/// - Line ID
///
/// Email is shown read-only because Firebase email change requires a
/// separate verification flow.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _studentIdCtrl;
  late final TextEditingController _facultyCtrl;
  late final TextEditingController _lineIdCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthState>().profile;
    _displayNameCtrl = TextEditingController(text: profile?.displayName ?? '');
    _studentIdCtrl = TextEditingController(text: profile?.studentId ?? '');
    _facultyCtrl = TextEditingController(text: profile?.faculty ?? '');
    _lineIdCtrl = TextEditingController(text: profile?.lineId ?? '');
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _studentIdCtrl.dispose();
    _facultyCtrl.dispose();
    _lineIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final auth = context.read<AuthState>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1) Save text fields (only if changed)
      final profile = auth.profile!;
      String? newDisplayName = _displayNameCtrl.text.trim();
      String? newStudentId = _studentIdCtrl.text.trim();
      String? newFaculty = _facultyCtrl.text.trim();
      String? newLineId = _lineIdCtrl.text.trim();

      if (newDisplayName == profile.displayName) newDisplayName = null;
      if (newStudentId == (profile.studentId ?? '')) newStudentId = null;
      if (newFaculty == (profile.faculty ?? '')) newFaculty = null;
      if (newLineId == (profile.lineId ?? '')) newLineId = null;

      final hasFieldChanges =
          newDisplayName != null ||
          newStudentId != null ||
          newFaculty != null ||
          newLineId != null;

      if (hasFieldChanges) {
        await auth.updateProfile(
          displayName: newDisplayName,
          studentId: newStudentId,
          faculty: newFaculty,
          lineId: newLineId,
        );
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.logoutRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthState>().profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: context.appBg,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Navy header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.navy,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 12,
                16,
                28,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BackCircleButton(onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.orange,
                    child: Icon(Icons.person, color: Colors.white, size: 52),
                  ),
                ],
              ),
            ),

            // ── Form section ───────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.appBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                transform: Matrix4.translationValues(0, -18, 0),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LabeledField(
                        label: 'Display Name',
                        controller: _displayNameCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Display name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: 'Email',
                        initialValueOverride: profile.email,
                        readOnly: true,
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: 'Student ID',
                        controller: _studentIdCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(label: 'Faculty', controller: _facultyCtrl),
                      const SizedBox(height: 14),
                      _LabeledField(label: 'Line ID', controller: _lineIdCtrl),

                      const SizedBox(height: 28),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Orange-bordered circular back button used on the dark header.
class _BackCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.orange, width: 2),
        ),
        child: const Icon(Icons.arrow_back, color: AppColors.orange, size: 20),
      ),
    );
  }
}

/// Labeled rounded input. Used for every field in the edit form.
class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValueOverride;
  final bool readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _LabeledField({
    required this.label,
    this.controller,
    this.initialValueOverride,
    this.readOnly = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: context.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValueOverride : null,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: context.primaryText,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.cardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            suffixIcon: readOnly
                ? null
                : Icon(Icons.edit, size: 18, color: context.secondaryText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: context.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: context.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
