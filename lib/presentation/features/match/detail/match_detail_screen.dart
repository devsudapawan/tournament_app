// match/detail/match_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/widgets/shared_widgets.dart';

class MatchDetailScreen extends ConsumerWidget {
  final String matchId;
  final String tournamentId;
  const MatchDetailScreen(
      {super.key, required this.matchId, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text('Match Detail', style: AppTextStyles.heading(size: 17)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InfoBanner(
                'Follow the steps below to process this match. Upload lobby first, then results.',
              ),
              const SizedBox(height: 24),
              const SectionLabel('Match Steps'),
              _StepTile(
                number: 1,
                title: 'Upload Lobby Screenshot',
                sub: 'Slot + player names (max 3 images)',
                icon: Icons.group_outlined,
                onTap: () => context
                    .push('${AppRoutes.upload}/$tournamentId/$matchId/lobby'),
              ),
              const SizedBox(height: 10),
              _StepTile(
                number: 2,
                title: 'Upload Result Screenshots',
                sub: 'Rank + kills (6–8 images)',
                icon: Icons.emoji_events_outlined,
                onTap: () => context
                    .push('${AppRoutes.upload}/$tournamentId/$matchId/result'),
              ),
            ],
          ),
        ),
      );
}

class _StepTile extends StatelessWidget {
  final int number;
  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;
  const _StepTile({
    required this.number,
    required this.title,
    required this.sub,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg3,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.yellow, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            AppTextStyles.subheading(color: AppColors.white)),
                    Text(sub,
                        style: AppTextStyles.body(
                            color: AppColors.muted, size: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
            ],
          ),
        ),
      );
}
