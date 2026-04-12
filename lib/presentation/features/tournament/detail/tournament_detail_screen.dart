// tournament/detail/tournament_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/providers/providers.dart';
import '../../../common/widgets/shared_widgets.dart';
import '../../../../domain/entities/tournament_entity.dart';
import '../../../../domain/entities/match_entity.dart';

final _tournamentDetailProvider =
    FutureProvider.family<TournamentEntity?, String>((ref, id) async {
  final r = await ref.read(getTournamentUseCaseProvider).call(id);
  return r.fold((_) => null, (t) => t);
});

final _matchesProvider =
    FutureProvider.family<List<MatchEntity>, String>((ref, tournamentId) async {
  final r = await ref.read(getMatchesUseCaseProvider).call(tournamentId);
  return r.fold((_) => [], (m) => m);
});

class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

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
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => context.push(
                '${AppRoutes.leaderboard}/$tournamentId'),
          ),
        ],
      ),
      body: matches.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.yellow)),
        error: (_, __) => const EmptyState(
            title: 'Error loading matches',
            subtitle: 'Please try again'),
        data: (matchList) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: matchList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _MatchCard(
            match: matchList[i],
            tournamentId: tournamentId,
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchEntity match;
  final String tournamentId;
  const _MatchCard({required this.match, required this.tournamentId});

  Color get _statusColor {
    switch (match.status) {
      case 'completed':      return AppColors.success;
      case 'lobby_uploaded': return AppColors.warning;
      case 'result_uploaded':return AppColors.info;
      default:               return AppColors.muted;
    }
  }

  String get _statusLabel {
    switch (match.status) {
      case 'completed':      return 'DONE';
      case 'lobby_uploaded': return 'LOBBY SET';
      case 'result_uploaded':return 'RESULT READY';
      default:               return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('${AppRoutes.matchDetail}/$tournamentId/${match.id}'),
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
                    style: AppTextStyles.subheading(color: AppColors.white)),
                if (match.scheduledAt != null)
                  Text(_fmt(match.scheduledAt!),
                      style: AppTextStyles.body(
                          color: AppColors.muted, size: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_statusLabel,
                style: AppTextStyles.label(color: _statusColor, size: 10)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
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
