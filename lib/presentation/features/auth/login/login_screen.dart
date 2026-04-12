// lib/presentation/features/auth/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_app/core/utils/app_images.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../common/providers/providers.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import 'login_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool  _showPw   = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(loginNotifierProvider.notifier).signIn(
      email:    _email.text.trim(),
      password: _password.text.trim(),
    );
  }

  void _forgotPassword() {
    if (_email.text.trim().isEmpty) {
      SnackBarHelper.showInfo(
          context, 'Enter your email above first');
      return;
    }
    _showForgotPasswordDialog(_email.text.trim());
  }

  void _showForgotPasswordDialog(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Password',
            style: AppTextStyles.heading(size: 17)),
        content: Text(
          'We will send a password reset link to:\n$email',
          style: AppTextStyles.body(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.body(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final result = await ref
                  .read(sendPasswordResetUseCaseProvider)
                  .call(email);
              result.fold(
                    (f) => SnackBarHelper.showError(context, f.message),
                    (_) => SnackBarHelper.showSuccess(
                  context,
                  'Reset link sent! Check your inbox.',
                ),
              );
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes
    ref.listen(loginNotifierProvider, (_, next) {
      if (next.success) {
        context.go(AppRoutes.shell);
      } else if (next.emailNotConfirmed) {
        _showEmailNotConfirmedDialog(next.unconfirmedEmail ?? '');
      } else if (next.errorMessage != null) {
        SnackBarHelper.showError(context, next.errorMessage!);
        ref.read(loginNotifierProvider.notifier).clearError();
      }
    });

    final state = ref.watch(loginNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo ──────────────────────────────
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text('PC',
                      style: AppTextStyles.heading(
                          size: 22, color: Colors.black)),
                ),
                const SizedBox(height: 28),
                Text('Welcome back',
                    style: AppTextStyles.display(size: 28)),
                const SizedBox(height: 8),
                Text('Sign in to manage your tournaments',
                    style: AppTextStyles.body(color: AppColors.muted)),
                const SizedBox(height: 36),

                // ── Email / Password ──────────────────
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text('Forgot password?',
                        style: AppTextStyles.label(
                            color: AppColors.muted, size: 12)),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Sign In Button ────────────────────
                AppButton(
                  label:     'Sign In',
                  onTap:     _submit,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 24),

                // ── Divider ───────────────────────────
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      child: Text('or continue with',
                          style: AppTextStyles.label(
                              color: AppColors.muted, size: 11)),
                    ),
                    const Expanded(
                        child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 20),

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
                              .read(loginNotifierProvider.notifier)
                              .signInWithGoogle(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _SocialButton(
                          iconPath:
                          AppImages.facebookLogo,
                          onTap: () => ref
                              .read(loginNotifierProvider.notifier)
                              .signInWithFacebook(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _SocialButton(
                          iconPath: AppImages.appleIcon,
                          color:    AppColors.white,
                          onTap: () => ref
                              .read(loginNotifierProvider.notifier)
                              .signInWithApple(),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 28),

                // ── Register Link ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?  ",
                        style: AppTextStyles.body(
                            color: AppColors.muted, size: 13)),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: Text('Sign Up',
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

  void _showEmailNotConfirmedDialog(String email) {
    ref.read(loginNotifierProvider.notifier).clearEmailNotConfirmed();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.mark_email_unread_outlined,
                color: AppColors.yellow, size: 22),
            const SizedBox(width: 10),
            Text('Confirm your email',
                style: AppTextStyles.heading(size: 16)),
          ],
        ),
        content: Text(
          'We sent a confirmation link to:\n\n$email\n\nPlease check your inbox (and spam folder) and click the link to activate your account.',
          style: AppTextStyles.body(color: AppColors.grey, size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: AppTextStyles.body(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(loginNotifierProvider.notifier)
                  .resendConfirmation(email);
              if (mounted) {
                SnackBarHelper.showSuccess(
                  context,
                  'Confirmation email resent! Check your inbox.',
                );
              }
            },
            child: const Text('Resend Email'),
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