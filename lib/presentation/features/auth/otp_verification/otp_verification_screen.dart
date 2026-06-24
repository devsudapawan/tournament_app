// lib/presentation/features/auth/register/otp_verification_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';

import '../../../common/widgets/app_button.dart';
import '../register/register_notifier.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String fullName;
  final int age;
  final String gender;
  final String phone;
  final String email;
  final String password;
  final File? profileImage;

  const OtpVerificationScreen({
    super.key,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.phone,
    required this.email,
    required this.password,
    this.profileImage,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();

  bool _isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // ───────────────── Verify OTP ─────────────────
  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    if (_otpController.text.trim().length != 6) {
      SnackBarHelper.showError(
        context,
        'Please enter valid OTP',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // ───────────────── API CALL ─────────────────
      // Verify OTP API here

      await Future.delayed(
        const Duration(seconds: 2),
      );

      // Example:
      // final isVerified = await ref
      //     .read(authProvider.notifier)
      //     .verifyOtp(
      //       phone: widget.phone,
      //       otp: _otpController.text.trim(),
      //     );

      final isVerified = true;

      if (!isVerified) {
        SnackBarHelper.showError(
          context,
          'Invalid OTP',
        );

        setState(() {
          _isVerifying = false;
        });

        return;
      }

      // ───────────────── SIGNUP ─────────────────
      await ref.read(registerNotifierProvider.notifier).signUp(
        fullName: widget.fullName,
        age: widget.age,
        gender: widget.gender,
        phone: widget.phone,
        email: widget.email,
        password: widget.password,
        profileImage: widget.profileImage,
      );

      if (!mounted) return;

      context.go(AppRoutes.profile);
    } catch (e) {
      SnackBarHelper.showError(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // ───────────────── Resend OTP ─────────────────
  Future<void> _resendOtp() async {
    try {
      // resend otp api

      SnackBarHelper.showSuccess(
        context,
        'OTP sent successfully',
      );
    } catch (e) {
      SnackBarHelper.showError(
        context,
        e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,

      textStyle: AppTextStyles.heading(
        size: 20,
      ),

      decoration: BoxDecoration(
        color: AppColors.bg3,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color: AppColors.border,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,

      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────────────── Heading ─────────────────
              Text(
                'OTP Verification',
                style: AppTextStyles.display(size: 28),
              ),

              const SizedBox(height: 10),

              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Enter the 6-digit code sent to\n',
                      style: AppTextStyles.body(
                        color: AppColors.muted,
                      ),
                    ),
                    TextSpan(
                      text: widget.phone,
                      style: AppTextStyles.body(
                        color: AppColors.yellow,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ───────────────── OTP FIELD ─────────────────
              Pinput(
                controller: _otpController,

                length: 6,

                keyboardType: TextInputType.number,

                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],

                defaultPinTheme: defaultPinTheme,

                focusedPinTheme: defaultPinTheme.copyDecorationWith(
                  border: Border.all(
                    color: AppColors.yellow,
                    width: 1.5,
                  ),
                ),

                submittedPinTheme: defaultPinTheme,

                separatorBuilder: (index) =>
                const SizedBox(width: 10),
              ),

              const SizedBox(height: 24),

              // ───────────────── Resend ─────────────────
              Center(
                child: GestureDetector(
                  onTap: _resendOtp,

                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Didn't receive code? ",
                          style: AppTextStyles.body(
                            color: AppColors.muted,
                            size: 13,
                          ),
                        ),
                        TextSpan(
                          text: 'Resend',
                          style: AppTextStyles.body(
                            color: AppColors.yellow,
                            size: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ───────────────── Verify Button ─────────────────
              AppButton(
                label: 'Verify OTP',
                onTap: _verifyOtp,
                isLoading: _isVerifying,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}