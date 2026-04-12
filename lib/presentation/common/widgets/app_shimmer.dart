// lib/presentation/common/widgets/app_shimmer.dart
//
// Skeleton loading placeholders for lists and cards.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';

class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor:      AppColors.bg3,
    highlightColor: AppColors.bg4,
    child: child,
  );
}

// ── Pre-built shimmer variants ─────────────────────────────
class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const ShimmerList({super.key, this.count = 5, this.itemHeight = 72});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(20),
    itemCount: count,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, __) => ShimmerCard(height: itemHeight),
  );
}

class ShimmerRow extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerRow({super.key, this.width = 200, this.height = 16});

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
