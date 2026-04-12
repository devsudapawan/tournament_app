// lib/presentation/common/widgets/match_status_chip.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class MatchStatusChip extends StatelessWidget {
  final String status;

  const MatchStatusChip({super.key, required this.status});

  String get _label {
    switch (status) {
      case 'completed':       return 'DONE';
      case 'lobby_uploaded':  return 'LOBBY SET';
      case 'result_uploaded': return 'RESULT READY';
      default:                return 'PENDING';
    }
  }

  Color get _color {
    switch (status) {
      case 'completed':       return AppColors.success;
      case 'lobby_uploaded':  return AppColors.warning;
      case 'result_uploaded': return AppColors.info;
      default:                return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _color.withOpacity(0.3)),
    ),
    child: Text(
      _label,
      style: AppTextStyles.label(color: _color, size: 10),
    ),
  );
}
