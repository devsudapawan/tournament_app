// lib/presentation/features/match/detail/match_detail_screen.dart
//
// Shows the two steps for processing a match.
// LOCK RULE:
//   pending        → Lobby enabled,  Result DISABLED
//   lobby_uploaded → Lobby DISABLED, Result enabled
//   completed      → Both DISABLED (match is done)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/match_entity.dart';
import '../../../common/providers/providers.dart';
import '../../../common/widgets/shared_widgets.dart';

// ── Provider: loads all matches for the tournament, then finds this one ──
final _matchStatusProvider = FutureProvider.autoDispose
    .family<MatchEntity?, String>((ref, key) async {
  // key = "tournamentId__matchId"
  final parts        = key.split('__');
  final tournamentId = parts[0];
  final matchId      = parts[1];

  final result = await ref.read(getMatchesUseCaseProvider).call(tournamentId);
  return result.fold(
    (_) => null,
    (matches) {
      try {
        return matches.firstWhere((m) => m.id == matchId);
      } catch (_) {
        return null;
      }
    },
  );
});

class MatchDetailScreen extends ConsumerWidget {
  final String matchId;
  final String tournamentId;

  const MatchDetailScreen({
    super.key,
    required this.matchId,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key         = '${tournamentId}__$matchId';
    final matchAsync  = ref.watch(_matchStatusProvider(key));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Match Detail', style: AppTextStyles.heading(size: 17)),
        actions: [
          // Refresh button — re-fetches match status from DB
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.muted),
            onPressed: () => ref.invalidate(_matchStatusProvider(key)),
            tooltip: 'Refresh status',
          ),
        ],
      ),
      body: matchAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.yellow),
        ),
        error: (_, __) => const EmptyState(
          title:    'Error loading match',
          subtitle: 'Pull to refresh or go back.',
        ),
        data: (match) => _MatchDetailBody(
          match:        match,
          matchId:      matchId,
          tournamentId: tournamentId,
          onRefresh:    () => ref.invalidate(_matchStatusProvider(key)),
        ),
      ),
    );
  }
}

class _MatchDetailBody extends StatelessWidget {
  final MatchEntity? match;
  final String       matchId;
  final String       tournamentId;
  final VoidCallback onRefresh;

  const _MatchDetailBody({
    required this.match,
    required this.matchId,
    required this.tournamentId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final status = match?.status ?? 'pending';

    // Derive enabled states from match status
    final lobbyEnabled  = status == 'pending';
    final resultEnabled = status == 'lobby_uploaded';
    final isCompleted   = status == 'completed';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Banner ─────────────────────────────
          _StatusBanner(status: status),
          const SizedBox(height: 24),

          const SectionLabel('Match Steps'),

          // ── Step 1: Upload Lobby ──────────────────────
          _StepTile(
            number:     1,
            title:      'Upload Lobby Screenshots',
            sub:        lobbyEnabled
                ? 'Slot + player names (max 3 images)'
                : status == 'lobby_uploaded' || isCompleted
                    ? '✓ Lobby confirmed & saved'
                    : 'Completed',
            icon:       Icons.group_outlined,
            enabled:    lobbyEnabled,
            onTap:      lobbyEnabled
                ? () => context.push(
                    '${AppRoutes.upload}/$tournamentId/$matchId/lobby')
                : null,
          ),

          const SizedBox(height: 10),

          // ── Step 2: Upload Results ────────────────────
          _StepTile(
            number:  2,
            title:   'Upload Result Screenshots',
            sub:     resultEnabled
                ? 'Rank + kills (6–8 images)'
                : status == 'pending'
                    ? 'Upload lobby first'
                    : isCompleted
                        ? '✓ Results saved & points calculated'
                        : 'Rank + kills (6–8 images)',
            icon:    Icons.emoji_events_outlined,
            enabled: resultEnabled,
            onTap:   resultEnabled
                ? () => context.push(
                    '${AppRoutes.upload}/$tournamentId/$matchId/result')
                : null,
          ),

          const SizedBox(height: 24),

          // ── Completed message ─────────────────────────
          if (isCompleted) ...[
            Container(
              width:  double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(
                    color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Match Completed',
                    style: AppTextStyles.subheading(
                        color: AppColors.success),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Points have been saved to the leaderboard.',
                    style: AppTextStyles.body(
                        color: AppColors.muted, size: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status banner shows current match stage ─────────────────
class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      'lobby_uploaded' => (
          'Lobby uploaded — ready for results',
          Icons.check_circle_outline,
          AppColors.yellow,
        ),
      'completed' => (
          'Match completed',
          Icons.emoji_events_outlined,
          AppColors.success,
        ),
      _ => (
          'Pending — upload lobby to begin',
          Icons.pending_outlined,
          AppColors.muted,
        ),
    };

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.body(color: color, size: 13),
          ),
        ],
      ),
    );
  }
}

// ── Step tile with enabled/disabled state ───────────────────
class _StepTile extends StatelessWidget {
  final int        number;
  final String     title;
  final String     sub;
  final IconData   icon;
  final bool       enabled;
  final VoidCallback? onTap;

  const _StepTile({
    required this.number,
    required this.title,
    required this.sub,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        enabled ? AppColors.bg3 : AppColors.bg3.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? AppColors.border : AppColors.border.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width:  40,
                height: 40,
                decoration: BoxDecoration(
                  color:        enabled
                      ? AppColors.yellow.withValues(alpha: 0.1)
                      : AppColors.muted.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.yellow : AppColors.muted,
                  size:  20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.subheading(
                        color: enabled ? AppColors.white : AppColors.muted,
                      ),
                    ),
                    Text(
                      sub,
                      style: AppTextStyles.body(
                        color: AppColors.muted,
                        size:  12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                enabled
                    ? Icons.chevron_right
                    : Icons.lock_outline,
                color: enabled ? AppColors.muted : AppColors.muted.withOpacity(0.4),
                size:  18,
              ),
            ],
          ),
        ),
      );
}
