// lib/presentation/common/widgets/app_bottom_sheet.dart
//
// Reusable bottom sheet used for team assignment, confirmations, etc.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AppBottomSheet {
  AppBottomSheet._();

  /// Generic bottom sheet with a title and custom content.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget body,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context:       context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize:     0.3,
        maxChildSize:     0.9,
        builder: (_, controller) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(title,
                  style: AppTextStyles.heading(size: 17)),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Body
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmation dialog.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel   = 'Confirm',
    String cancelLabel    = 'Cancel',
    bool   isDangerous    = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTextStyles.heading(size: 17)),
        content: Text(message,
            style: AppTextStyles.body(color: AppColors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel,
                style: AppTextStyles.body(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDangerous ? AppColors.danger : AppColors.yellow,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel,
                style: AppTextStyles.label(
                  color: isDangerous ? Colors.white : Colors.black,
                  size: 12,
                )),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Team picker — shown when OCR fails to match a team.
  static Future<String?> pickTeam({
    required BuildContext context,
    required List<({String id, String name, int slot})> teams,
  }) {
    return showModalBottomSheet<String>(
      context:       context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text('Assign Team',
                style: AppTextStyles.heading(size: 17)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: teams.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final team = teams[i];
                return ListTile(
                  onTap: () => Navigator.pop(ctx, team.id),
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('#${team.slot}',
                        style: AppTextStyles.label(
                            color: Colors.black, size: 11)),
                  ),
                  title: Text(team.name,
                      style: AppTextStyles.body(color: AppColors.white)),
                  tileColor: AppColors.bg3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
