// tournament/detail/tournament_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/providers/providers.dart';
import '../../../common/widgets/shared_widgets.dart';
import '../../../../domain/entities/tournament_entity.dart';
import '../../../../domain/entities/match_entity.dart';
import '../../home/home_screen.dart';
import '../../tournament_list/tournament_list.dart';
import '../../../common/widgets/home_drawer.dart';

final _tournamentDetailProvider =
FutureProvider.autoDispose.family<TournamentEntity?, String>((ref, id) async {
  final r = await ref.read(getTournamentUseCaseProvider).call(id);
  return r.fold((_) => null, (t) => t);
});

final _matchesProvider =
FutureProvider.autoDispose.family<List<MatchEntity>, String>(
        (ref, tournamentId) async {
      final r = await ref.read(getMatchesUseCaseProvider).call(tournamentId);
      return r.fold((_) => [], (m) => m);
    });



class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  // ── Add Match ──────────────────────────────────────────────
  Future<void> _addMatch(
      BuildContext context,
      WidgetRef ref,
      List<MatchEntity> currentMatches,
      ) async {
    final newNumber = currentMatches.length + 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Add Match $newNumber',
            style: AppTextStyles.heading(size: 16)),
        content: Text(
          'Add Match $newNumber to this tournament?',
          style: AppTextStyles.body(color: AppColors.grey, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTextStyles.label(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Add',
                style: AppTextStyles.label(color: AppColors.yellow)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final result = await ref.read(addMatchUseCaseProvider).call(
      tournamentId: tournamentId,
      matchNumber: newNumber,
    );

    result.fold(
          (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to add match: ${f.message}'),
            backgroundColor: AppColors.danger,
          ));
        }
      },
          (_) {
        // Refresh matches list
        ref.invalidate(_matchesProvider(tournamentId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Match added successfully'),
            backgroundColor: AppColors.success,
          ));
        }
      },
    );
  }

  // ── Delete Match ───────────────────────────────────────────
  Future<void> _deleteMatch(
      BuildContext context,
      WidgetRef ref,
      MatchEntity match,
      List<MatchEntity> currentMatches,
      ) async {
    // Only allow delete if match count > 3
    if (currentMatches.length <= AppConstants.minMatches) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cannot remove match. Minimum 3 matches required.'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    // Only allow delete of pending matches
    if (match.status != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cannot remove a match that has already started.'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Remove Match ${match.matchNumber}',
            style: AppTextStyles.heading(size: 16)),
        content: Text(
          'Remove Match ${match.matchNumber}? This cannot be undone.',
          style: AppTextStyles.body(color: AppColors.grey, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTextStyles.label(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove',
                style: AppTextStyles.label(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final result =
    await ref.read(deleteMatchUseCaseProvider).call(match.id);

    result.fold(
          (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to remove match: ${f.message}'),
            backgroundColor: AppColors.danger,
          ));
        }
      },
          (_) {
        ref.invalidate(_matchesProvider(tournamentId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Match removed'),
            backgroundColor: AppColors.success,
          ));
        }
      },
    );
  }

  // ── Delete Tournament ──────────────────────────────────────
  Future<void> _deleteTournament(
      BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Delete Tournament',
            style: AppTextStyles.heading(
                size: 16, color: AppColors.danger)),
        content: Text(
          'This will permanently delete the tournament and ALL match data. '
              'This cannot be undone.',
          style: AppTextStyles.body(color: AppColors.grey, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTextStyles.label(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: AppTextStyles.label(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final result = await ref
        .read(deleteTournamentUseCaseProvider)
        .call(tournamentId);

    result.fold(
          (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete: ${f.message}'),
            backgroundColor: AppColors.danger,
          ));
        }
      },
          (_) {
        // Invalidate tournaments list on home screen
        ref.invalidate(_tournamentDetailProvider(tournamentId));
        ref.invalidate(activeTournamentsProvider);
        ref.invalidate(allTournamentsProvider);
        ref.invalidate(drawerProfileProvider);
        if (context.mounted) {
          // Go back to home and refresh
          context.go(AppRoutes.home);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Tournament deleted'),
            backgroundColor: AppColors.success,
          ));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(_tournamentDetailProvider(tournamentId));
    final matches    = ref.watch(_matchesProvider(tournamentId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        title: Text(
          tournament.value?.name ?? 'Tournament',
          style: AppTextStyles.heading(size: 17),
        ),
        actions: [
          // Add match — only visible if < 8 matches
          matches.whenOrNull(
            data: (list) => list.length < AppConstants.maxMatches
                ? IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.yellow),
              tooltip: 'Add Match',
              onPressed: () => _addMatch(context, ref, list),
            )
                : null,
          ) ?? const SizedBox(),

          // Leaderboard
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => context.push(
                '${AppRoutes.leaderboard}/$tournamentId'),
          ),

          // Delete tournament
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.danger),
            tooltip: 'Delete Tournament',
            onPressed: () => _deleteTournament(context, ref),
          ),
        ],
      ),
      body: matches.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.yellow)),
        error: (_, __) => const EmptyState(
            title: 'Error loading matches',
            subtitle: 'Please try again'),
        data: (matchList) => matchList.isEmpty
            ? const EmptyState(
          title: 'No matches yet',
          subtitle: 'Tap + to add a match',
        )
            : ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: matchList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _MatchCard(
            match:        matchList[i],
            tournamentId: tournamentId,
            matchCount:   matchList.length,
            onDelete: () => _deleteMatch(
                context, ref, matchList[i], matchList),
          ),
        ),
      ),
    );
  }
}

// ── Match Card ─────────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final MatchEntity match;
  final String tournamentId;
  final int matchCount;
  final VoidCallback onDelete;

  const _MatchCard({
    required this.match,
    required this.tournamentId,
    required this.matchCount,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (match.status) {
      case 'completed':       return AppColors.success;
      case 'lobby_uploaded':  return AppColors.warning;
      case 'result_uploaded': return AppColors.info;
      default:                return AppColors.muted;
    }
  }

  String get _statusLabel {
    switch (match.status) {
      case 'completed':       return 'DONE';
      case 'lobby_uploaded':  return 'LOBBY SET';
      case 'result_uploaded': return 'RESULT READY';
      default:                return 'PENDING';
    }
  }

  // Show delete button only if:
  // 1. Match is pending (not started)
  // 2. Total matches > 3
  bool get _canDelete =>
      match.status == 'pending' && matchCount > AppConstants.minMatches;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(
        '${AppRoutes.matchDetail}/$tournamentId/${match.id}'),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SlotBadge(slot: match.matchNumber, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Match ${match.matchNumber}',
                    style: AppTextStyles.subheading(
                        color: AppColors.white)),
                if (match.scheduledAt != null)
                  Text(_fmt(match.scheduledAt!),
                      style: AppTextStyles.body(
                          color: AppColors.muted, size: 12)),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_statusLabel,
                style: AppTextStyles.label(
                    color: _statusColor, size: 10)),
          ),
          const SizedBox(width: 6),
          // Delete button — only for pending matches when count > 3
          if (_canDelete)
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.remove_circle_outline,
                    color: AppColors.danger, size: 18),
              ),
            )
          else
            const Icon(Icons.chevron_right,
                color: AppColors.muted, size: 18),
        ],
      ),
    ),
  );

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }
}