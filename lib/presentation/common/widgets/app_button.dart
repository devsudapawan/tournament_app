import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum ButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final ButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary   = variant == ButtonVariant.primary;
    final isSecondary = variant == ButtonVariant.secondary;

    return SizedBox(
      width:  width ?? double.infinity,
      height: height,
      child: Material(
        color: isPrimary
            ? (onTap == null ? AppColors.bg4 : AppColors.yellow)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: isSecondary
                ? BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isPrimary ? Colors.black : AppColors.yellow,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[icon!, const SizedBox(width: 8)],
                        Text(
                          label.toUpperCase(),
                          style: AppTextStyles.heading(
                            size: 14,
                            color: isPrimary
                                ? (onTap == null ? AppColors.muted : Colors.black)
                                : AppColors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
