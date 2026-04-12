// lib/presentation/features/auth/profile/profile_screen.dart
// v2 — Added Sign Out button, works as Tab 4 in bottom nav

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../common/providers/providers.dart';
import '../../common/widgets/app_bottom_sheet.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/shared_widgets.dart';

final _profileLoadingProvider = StateProvider<bool>((_) => false);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _age     = TextEditingController();
  String? _gender;
  bool _loaded = false;

  static const _genders = [
    'Male', 'Female', 'Other', 'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ref.read(getProfileUseCaseProvider).call();
    result.fold((_) {}, (data) {
      if (data != null) {
        _name.text = data['name'] ?? '';
        _age.text  = data['age']?.toString() ?? '';
        setState(() {
          _gender = data['gender'];
          _loaded = true;
        });
      } else {
        setState(() => _loaded = true);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(_profileLoadingProvider.notifier).state = true;

    final result = await ref.read(saveProfileUseCaseProvider).call({
      'name':   _name.text.trim(),
      'age':    int.tryParse(_age.text.trim()),
      'gender': _gender?.toLowerCase().replaceAll(' ', '_'),
    });

    ref.read(_profileLoadingProvider.notifier).state = false;
    result.fold(
          (f) => SnackBarHelper.showError(context, f.message),
          (_) => SnackBarHelper.showSuccess(context, 'Profile saved!'),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await AppBottomSheet.confirm(
      context:      context,
      title:        'Sign Out',
      message:      'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      isDangerous:  true,
    );
    if (!confirmed) return;

    await ref.read(signOutUseCaseProvider).call();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_profileLoadingProvider);
    final user      = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Profile', style: AppTextStyles.heading(size: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ──────────────────────────
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bg3,
                          border: Border.all(
                              color: AppColors.yellow.withOpacity(0.4),
                              width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _name.text.isNotEmpty
                              ? _name.text[0].toUpperCase()
                              : 'U',
                          style: AppTextStyles.display(
                              size: 28, color: AppColors.yellow),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 26, height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.yellow,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (user?.email != null)
                  Center(
                    child: Text(
                      user!.email!,
                      style: AppTextStyles.body(
                          color: AppColors.muted, size: 13),
                    ),
                  ),
                const SizedBox(height: 28),

                // ── Fields ─────────────────────────
                AppTextField(
                  label:     'Full Name',
                  hint:      'Your name',
                  controller: _name,
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label:        'Age',
                  hint:         '18',
                  controller:   _age,
                  keyboardType: TextInputType.number,
                  validator:    Validators.age,
                ),
                const SizedBox(height: 16),

                const SectionLabel('Gender'),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _genders.map((g) {
                    final isSelected =
                        _gender == g.toLowerCase().replaceAll(' ', '_') ||
                            _gender == g;
                    return GestureDetector(
                      onTap: () => setState(() =>
                      _gender = g.toLowerCase().replaceAll(' ', '_')),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.yellow.withOpacity(0.1)
                              : AppColors.bg3,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.yellow
                                : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(g,
                            style: AppTextStyles.body(
                              color: isSelected
                                  ? AppColors.yellow
                                  : AppColors.grey,
                              size: 13,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                AppButton(
                  label:     'Save Profile',
                  onTap:     _save,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),

                // ── Divider ────────────────────────
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                // ── Settings section ───────────────
                const SectionLabel('App Info'),
                const _SettingsTile(
                  icon:  Icons.info_outline,
                  label: 'Version 1.0.0',
                  sub:   'PointCalc — Esports Tournament Manager',
                ),
                const SizedBox(height: 8),
                const _SettingsTile(
                  icon:  Icons.help_outline,
                  label: 'How to use OCR',
                  sub:   'Guide to uploading screenshots',
                ),
                const SizedBox(height: 24),

                // ── Sign Out ───────────────────────
                AppButton(
                  label:   'Sign Out',
                  variant: ButtonVariant.secondary,
                  onTap:   _signOut,
                  icon:    const Icon(Icons.logout_outlined,
                      color: AppColors.danger, size: 18),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Signed in as ${user?.email ?? ""}',
                    style: AppTextStyles.label(
                        color: AppColors.muted, size: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String?  sub;
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.sub,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color:        AppColors.bg3,
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.muted, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.body(
                      color: AppColors.white, size: 13)),
              if (sub != null)
                Text(sub!,
                    style: AppTextStyles.body(
                        color: AppColors.muted, size: 11)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right,
            color: AppColors.muted, size: 16),
      ],
    ),
  );
}