// lib/presentation/features/auth/register/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_images.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import 'register_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _confirm  = TextEditingController();
  bool  _showPw   = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(registerNotifierProvider.notifier).signUp(
      email:    _email.text.trim(),
      password: _password.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerNotifierProvider, (_, next) {
      if (next.success) {
        if (next.requiresEmailConfirmation) {
          // Show confirmation message then go to login
          _showConfirmationSentDialog(_email.text.trim());
        } else {
          // Email confirmation disabled — go straight to profile
          context.go(AppRoutes.profile);
        }
      } else if (next.errorMessage != null) {
        SnackBarHelper.showError(context, next.errorMessage!);
      }
    });

    final state = ref.watch(registerNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create account',
                    style: AppTextStyles.display(size: 28)),
                const SizedBox(height: 8),
                Text('Start managing your tournaments',
                    style: AppTextStyles.body(color: AppColors.muted)),
                const SizedBox(height: 36),

                AppTextField(
                  label:        'Email',
                  hint:         'you@example.com',
                  controller:   _email,
                  keyboardType: TextInputType.emailAddress,
                  validator:    Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label:       'Password',
                  hint:        '••••••••',
                  controller:  _password,
                  obscureText: !_showPw,
                  validator:   Validators.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPw
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.muted, size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _showPw = !_showPw),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label:       'Confirm password',
                  hint:        '••••••••',
                  controller:  _confirm,
                  obscureText: true,
                  validator:   (v) =>
                      Validators.confirmPassword(v, _password.text),
                ),
                const SizedBox(height: 28),

                AppButton(
                  label:     'Create Account',
                  onTap:     _submit,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 24),

                // ── Divider ──────────────────────────
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      child: Text('or sign up with',
                          style: AppTextStyles.label(
                              color: AppColors.muted, size: 11)),
                    ),
                    const Expanded(
                        child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Social Buttons ────────────────────
                // ── Social Buttons ────────────────────
                if (state.isSocialLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: AppColors.yellow),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          iconPath: AppImages.googleLogo,

                          onTap: () => ref
                              .read(registerNotifierProvider.notifier)
                              .signInWithGoogle(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _SocialButton(
                          iconPath:
                          AppImages.facebookLogo,
                          onTap: () => ref
                              .read(registerNotifierProvider.notifier)
                              .signInWithFacebook(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _SocialButton(
                          iconPath: AppImages.appleIcon,
                          color:    AppColors.white,
                          onTap: () => ref
                              .read(registerNotifierProvider.notifier)
                              .signInWithApple(),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // ── Login Link ───────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?  ',
                        style: AppTextStyles.body(
                            color: AppColors.muted, size: 13)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('Sign In',
                          style: AppTextStyles.body(
                              color: AppColors.yellow, size: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationSentDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.mark_email_read_outlined,
                color: AppColors.yellow, size: 22),
            const SizedBox(width: 10),
            Text('Check your inbox',
                style: AppTextStyles.heading(size: 16)),
          ],
        ),
        content: Text(
          'We sent a confirmation link to:\n\n$email\n\nClick the link to activate your account, then sign in.',
          style: AppTextStyles.body(color: AppColors.grey, size: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.login);
            },
            child: const Text('Go to Sign In'),
          ),
        ],
      ),
    );
  }
}

// ── Social Button Widget ───────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String   iconPath;
  final Color?    color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.iconPath,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height:  48,
      decoration: BoxDecoration(
        color:        AppColors.bg3,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.border),
      ),
      child: Image.asset(iconPath, color: color ),
    ),
  );
}