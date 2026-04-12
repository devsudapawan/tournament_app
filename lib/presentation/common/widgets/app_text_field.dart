import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.label(color: AppColors.muted, size: 11),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller:   controller,
          obscureText:  obscureText,
          keyboardType: keyboardType,
          validator:    validator,
          readOnly:     readOnly,
          onTap:        onTap,
          onChanged:    onChanged,
          maxLines:     maxLines,
          style: AppTextStyles.body(color: AppColors.white, size: 15),
          decoration: InputDecoration(
            hintText:   hint,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}
