import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// ── Slot Badge ─────────────────────────────────────────────
class SlotBadge extends StatelessWidget {
  final int slot;
  final double size;
  const SlotBadge({super.key, required this.slot, this.size = 32});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.yellow,
      borderRadius: BorderRadius.circular(6),
    ),
    alignment: Alignment.center,
    child: Text(
      '#$slot',
      style: AppTextStyles.label(
        color: Colors.black,
        size: size * 0.38,
        spacing: 0.5,
      ),
    ),
  );
}

// ── Step Indicator ─────────────────────────────────────────
class StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const StepIndicator({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          return Expanded(
            child: Container(
              height: 1,
              color: stepIndex < current - 1
                  ? AppColors.yellow
                  : AppColors.border,
            ),
          );
        }
        final step = i ~/ 2 + 1;
        final isDone   = step < current;
        final isActive = step == current;
        return Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDone || isActive) ? AppColors.yellow : AppColors.bg3,
            border: Border.all(
              color: (isDone || isActive) ? AppColors.yellow : AppColors.border,
            ),
            boxShadow: isActive
                ? [const BoxShadow(color: AppColors.yellowGlow, blurRadius: 8, spreadRadius: 2)]
                : null,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.black)
              : Text(
                  '$step',
                  style: AppTextStyles.label(
                    color: isActive ? Colors.black : AppColors.muted,
                    size: 11,
                    spacing: 0,
                  ),
                ),
        );
      }),
    );
  }
}

// ── Section Label ──────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: AppTextStyles.label(color: AppColors.yellow, size: 11),
    ),
  );
}

// ── Info Banner ────────────────────────────────────────────
class InfoBanner extends StatelessWidget {
  final String text;
  const InfoBanner(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.yellowGlow,
      border: Border.all(color: AppColors.yellow.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.yellow, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppTextStyles.body(color: Colors.white70, size: 12)),
        ),
      ],
    ),
  );
}

// ── Confidence Dot ─────────────────────────────────────────
class ConfidenceDot extends StatelessWidget {
  final double confidence;
  const ConfidenceDot(this.confidence, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: confidence >= 0.85 ? AppColors.success : AppColors.danger,
    ),
  );
}

// ── Loading Overlay ────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black54,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.yellow),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTextStyles.body(color: AppColors.white)),
          ],
        ],
      ),
    ),
  );
}

// ── Empty State ────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_esports_outlined,
              size: 56, color: AppColors.border),
          const SizedBox(height: 16),
          Text(title,
              style: AppTextStyles.heading(color: AppColors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: AppTextStyles.body(color: AppColors.muted),
              textAlign: TextAlign.center),
          if (onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel ?? 'Get started'),
            ),
          ],
        ],
      ),
    ),
  );
}
