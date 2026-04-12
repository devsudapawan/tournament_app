// lib/core/utils/snackbar_helper.dart
//
// Shows consistent snackbars across the app.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SnackBarHelper {
  SnackBarHelper._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.danger, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.yellow, Icons.info_outline);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body(color: AppColors.white, size: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.bg3,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
