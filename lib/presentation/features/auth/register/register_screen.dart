// // lib/presentation/features/auth/register/register_screen.dart
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/router/app_router.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../../../core/utils/app_images.dart';
// import '../../../../core/utils/validators.dart';
// import '../../../../core/utils/snackbar_helper.dart';
// import '../../../common/widgets/app_button.dart';
// import '../../../common/widgets/app_text_field.dart';
// import 'register_notifier.dart';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';
//
// class RegisterScreen extends ConsumerStatefulWidget {
//   const RegisterScreen({super.key});
//   @override
//   ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
// }
//
// class _RegisterScreenState extends ConsumerState<RegisterScreen> {
//   final _formKey  = GlobalKey<FormState>();
//   final _fullName = TextEditingController();
//   final _age      = TextEditingController();
//   final _phone    = TextEditingController();
//   final _email    = TextEditingController();
//   final _password = TextEditingController();
//   final _confirm  = TextEditingController();
//
//   String? _selectedGender;
//
//   bool _showPw = false;
//
//   File? _profileImage;
//   @override
//   void dispose() {
//     _fullName.dispose();
//     _age.dispose();
//     _phone.dispose();
//     _email.dispose();
//     _password.dispose();
//     _confirm.dispose();
//     super.dispose();
//   }
//
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     await ref.read(registerNotifierProvider.notifier).signUp(
//       email:    _email.text.trim(),
//       password: _password.text.trim(),
//     );
//   }
//
//
//   Future<void> _pickImage() async {
//     final picked = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 70,
//     );
//
//     if (picked != null) {
//       setState(() {
//         _profileImage = File(picked.path);
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     ref.listen(registerNotifierProvider, (_, next) {
//       if (next.success) {
//         if (next.requiresEmailConfirmation) {
//           // Show confirmation message then go to login
//           _showConfirmationSentDialog(_email.text.trim());
//         } else {
//           // Email confirmation disabled — go straight to profile
//           context.go(AppRoutes.profile);
//         }
//       } else if (next.errorMessage != null) {
//         SnackBarHelper.showError(context, next.errorMessage!);
//       }
//     });
//
//     final state = ref.watch(registerNotifierProvider);
//
//     return Scaffold(
//       backgroundColor: AppColors.bg,
//       appBar: AppBar(
//         leading: BackButton(onPressed: () => context.pop()),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(
//               horizontal: 24, vertical: 16),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Create account',
//                     style: AppTextStyles.display(size: 28)),
//                 const SizedBox(height: 8),
//                 Text('Start managing your tournaments',
//                     style: AppTextStyles.body(color: AppColors.muted)),
//                 const SizedBox(height: 36),
//
//                 AppTextField(
//                   label:        'Email',
//                   hint:         'you@example.com',
//                   controller:   _email,
//                   keyboardType: TextInputType.emailAddress,
//                   validator:    Validators.email,
//                 ),
//                 const SizedBox(height: 16),
//                 AppTextField(
//                   label:       'Password',
//                   hint:        '••••••••',
//                   controller:  _password,
//                   obscureText: !_showPw,
//                   validator:   Validators.password,
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _showPw
//                           ? Icons.visibility_off_outlined
//                           : Icons.visibility_outlined,
//                       color: AppColors.muted, size: 20,
//                     ),
//                     onPressed: () =>
//                         setState(() => _showPw = !_showPw),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 AppTextField(
//                   label:       'Confirm password',
//                   hint:        '••••••••',
//                   controller:  _confirm,
//                   obscureText: true,
//                   validator:   (v) =>
//                       Validators.confirmPassword(v, _password.text),
//                 ),
//                 const SizedBox(height: 28),
//
//                 AppButton(
//                   label:     'Create Account',
//                   onTap:     _submit,
//                   isLoading: state.isLoading,
//                 ),
//                 const SizedBox(height: 24),
//
//                 // ── Divider ──────────────────────────
//                 Row(
//                   children: [
//                     const Expanded(
//                         child: Divider(color: AppColors.border)),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12),
//                       child: Text('or sign up with',
//                           style: AppTextStyles.label(
//                               color: AppColors.muted, size: 11)),
//                     ),
//                     const Expanded(
//                         child: Divider(color: AppColors.border)),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//
//                 // ── Social Buttons ────────────────────
//                 // ── Social Buttons ────────────────────
//                 if (state.isSocialLoading)
//                   const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(12),
//                       child: CircularProgressIndicator(
//                           color: AppColors.yellow),
//                     ),
//                   )
//                 else
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _SocialButton(
//                           iconPath: AppImages.googleLogo,
//
//                           onTap: () => ref
//                               .read(registerNotifierProvider.notifier)
//                               .signInWithGoogle(),
//                         ),
//                       ),
//                       const SizedBox(width: 20),
//                       Expanded(
//                         child: _SocialButton(
//                           iconPath:
//                           AppImages.facebookLogo,
//                           onTap: () => ref
//                               .read(registerNotifierProvider.notifier)
//                               .signInWithFacebook(),
//                         ),
//                       ),
//                       const SizedBox(width: 20),
//                       Expanded(
//                         child: _SocialButton(
//                           iconPath: AppImages.appleIcon,
//                           color:    AppColors.white,
//                           onTap: () => ref
//                               .read(registerNotifierProvider.notifier)
//                               .signInWithApple(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 const SizedBox(height: 24),
//
//                 // ── Login Link ───────────────────────
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text('Already have an account?  ',
//                         style: AppTextStyles.body(
//                             color: AppColors.muted, size: 13)),
//                     GestureDetector(
//                       onTap: () => context.pop(),
//                       child: Text('Sign In',
//                           style: AppTextStyles.body(
//                               color: AppColors.yellow, size: 13)),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showConfirmationSentDialog(String email) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         backgroundColor: AppColors.bg3,
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             const Icon(Icons.mark_email_read_outlined,
//                 color: AppColors.yellow, size: 22),
//             const SizedBox(width: 10),
//             Text('Check your inbox',
//                 style: AppTextStyles.heading(size: 16)),
//           ],
//         ),
//         content: Text(
//           'We sent a confirmation link to:\n\n$email\n\nClick the link to activate your account, then sign in.',
//           style: AppTextStyles.body(color: AppColors.grey, size: 14),
//         ),
//         actions: [
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               minimumSize: Size.zero,
//               padding: const EdgeInsets.symmetric(
//                   horizontal: 20, vertical: 10),
//             ),
//             onPressed: () {
//               Navigator.pop(context);
//               context.go(AppRoutes.login);
//             },
//             child: const Text('Go to Sign In'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ── Social Button Widget ───────────────────────────────────
// class _SocialButton extends StatelessWidget {
//   final String   iconPath;
//   final Color?    color;
//   final VoidCallback onTap;
//
//   const _SocialButton({
//     required this.iconPath,
//     this.color,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       height:  48,
//       decoration: BoxDecoration(
//         color:        AppColors.bg3,
//         borderRadius: BorderRadius.circular(12),
//         border:       Border.all(color: AppColors.border),
//       ),
//       child: Image.asset(iconPath, color: color ),
//     ),
//   );
// }


// lib/presentation/features/auth/register/register_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_images.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/validators.dart';

import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';

import 'register_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // ───────────────── Controllers ─────────────────
  final _fullName = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // ───────────────── Variables ─────────────────
  String? _selectedGender;

  bool _showPw = false;
  bool _showConfirmPw = false;

  File? _profileImage;

  // ───────────────── Dispose ─────────────────
  @override
  void dispose() {
    _fullName.dispose();
    _age.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();

    super.dispose();
  }

  // ───────────────── Image Picker ─────────────────
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  // ───────────────── Submit ─────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(registerNotifierProvider.notifier).signUp(
      fullName: _fullName.text.trim(),
      age: int.parse(_age.text.trim()),
      gender: _selectedGender!,
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      password: _password.text.trim(),
      profileImage: _profileImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerNotifierProvider, (_, next) {
      if (next.success) {
        if (next.requiresEmailConfirmation) {
          _showConfirmationSentDialog(_email.text.trim());
        } else {
          context.go(AppRoutes.profile);
        }
      } else if (next.errorMessage != null) {
        SnackBarHelper.showError(context, next.errorMessage!);
      }
    });

    final state = ref.watch(registerNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,

      // ───────────────── AppBar ─────────────────
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
      ),

      // ───────────────── Body ─────────────────
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───────────────── Heading ─────────────────
                Text(
                  'Create account',
                  style: AppTextStyles.display(size: 28),
                ),

                const SizedBox(height: 8),

                Text(
                  'Start managing your tournaments',
                  style: AppTextStyles.body(
                    color: AppColors.muted,
                  ),
                ),

                const SizedBox(height: 32),

                // ───────────────── Profile Image ─────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,

                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.bg3,

                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,

                          child: _profileImage == null
                              ? const Icon(
                            Icons.person,
                            size: 45,
                            color: AppColors.muted,
                          )
                              : null,
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,

                          child: Container(
                            padding: const EdgeInsets.all(6),

                            decoration: const BoxDecoration(
                              color: AppColors.yellow,
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ───────────────── Full Name ─────────────────
                AppTextField(
                  label: 'Full Name',
                  hint: 'John Doe',
                  controller: _fullName,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Full name is required';
                    }

                    if (v.trim().length < 3) {
                      return 'Enter valid full name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ───────────────── Age ─────────────────
                AppTextField(
                  label: 'Age',
                  hint: '21',
                  controller: _age,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,

                  textInputFormatter: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2)
                  ],

                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Age is required';
                    }

                    final age = int.tryParse(v);

                    if (age == null || age < 10 || age > 100) {
                      return 'Enter valid age';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ───────────────── Gender ─────────────────

                Text(
                  'Gender',
                  style: AppTextStyles.body(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGender,

                  dropdownColor: AppColors.bg3,

                  decoration: InputDecoration(
                    // labelText: 'Gender',

                    // labelStyle: AppTextStyles.body(
                    //   color: AppColors.muted,
                    // ),

                    filled: true,
                    fillColor: AppColors.bg3,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.yellow,
                      ),
                    ),
                  ),

                  items: ['Male', 'Female', 'Other']
                      .map(
                        (gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender, style: AppTextStyles.body(color: AppColors.white, size: 15),),
                    ),
                  )
                      .toList(),

                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },

                  validator: (v) {
                    if (v == null) {
                      return 'Please select gender';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ───────────────── Phone Number ─────────────────
                AppTextField(
                  label: 'Phone Number',
                  hint: '+91 9876543210',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,

                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone number is required';
                    }

                    if (v.trim().length < 10) {
                      return 'Enter valid phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ───────────────── Email ─────────────────
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),

                const SizedBox(height: 16),

                // ───────────────── Password ─────────────────
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _password,
                  obscureText: !_showPw,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,

                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPw
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),

                    onPressed: () {
                      setState(() {
                        _showPw = !_showPw;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ───────────────── Confirm Password ─────────────────
                AppTextField(
                  label: 'Confirm password',
                  hint: '••••••••',
                  controller: _confirm,
                  obscureText: !_showConfirmPw,
                  textInputAction: TextInputAction.done,

                  validator: (v) =>
                      Validators.confirmPassword(v, _password.text),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPw
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),

                    onPressed: () {
                      setState(() {
                        _showConfirmPw = !_showConfirmPw;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // ───────────────── Create Account Button ─────────────────
                AppButton(
                  label: 'Create Account',
                  onTap: _submit,
                  isLoading: state.isLoading,
                ),

                const SizedBox(height: 24),

                // ───────────────── Divider ─────────────────
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: AppColors.border,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),

                      child: Text(
                        'or sign up with',

                        style: AppTextStyles.label(
                          color: AppColors.muted,
                          size: 11,
                        ),
                      ),
                    ),

                    const Expanded(
                      child: Divider(
                        color: AppColors.border,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ───────────────── Social Buttons ─────────────────
                if (state.isSocialLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: AppColors.yellow,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          iconPath: AppImages.googleLogo,

                          onTap: () {
                            ref
                                .read(
                              registerNotifierProvider.notifier,
                            )
                                .signInWithGoogle();
                          },
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: _SocialButton(
                          iconPath: AppImages.facebookLogo,

                          onTap: () {
                            ref
                                .read(
                              registerNotifierProvider.notifier,
                            )
                                .signInWithFacebook();
                          },
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: _SocialButton(
                          iconPath: AppImages.appleIcon,
                          color: AppColors.white,

                          onTap: () {
                            ref
                                .read(
                              registerNotifierProvider.notifier,
                            )
                                .signInWithApple();
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // ───────────────── Login Link ─────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?  ',

                      style: AppTextStyles.body(
                        color: AppColors.muted,
                        size: 13,
                      ),
                    ),

                    GestureDetector(
                      onTap: () => context.pop(),

                      child: Text(
                        'Sign In',

                        style: AppTextStyles.body(
                          color: AppColors.yellow,
                          size: 13,
                        ),
                      ),
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

  // ───────────────── Confirmation Dialog ─────────────────
  void _showConfirmationSentDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg3,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        title: Row(
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.yellow,
              size: 22,
            ),

            const SizedBox(width: 10),

            Text(
              'Check your inbox',
              style: AppTextStyles.heading(size: 16),
            ),
          ],
        ),

        content: Text(
          'We sent a confirmation link to:\n\n$email\n\nClick the link to activate your account, then sign in.',

          style: AppTextStyles.body(
            color: AppColors.grey,
            size: 14,
          ),
        ),

        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,

              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
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

// ───────────────── Social Button ─────────────────
class _SocialButton extends StatelessWidget {
  final String iconPath;
  final Color? color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.iconPath,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        height: 48,

        decoration: BoxDecoration(
          color: AppColors.bg3,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: AppColors.border,
          ),
        ),

        child: Image.asset(
          iconPath,
          color: color,
        ),
      ),
    );
  }
}