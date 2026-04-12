// lib/presentation/features/tournament/list/tournament_list_screen.dart
// Tab 2 — All tournaments grouped by status

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/tournament_entity.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../common/providers/providers.dart';
import '../../common/widgets/app_shimmer.dart';
import '../../common/widgets/match_status_chip.dart';
import '../../common/widgets/shared_widgets.dart';

final _allTournamentsProvider =
    FutureProvider<List<TournamentEntity>>((ref) async {
  final r = await ref.read(getMyTournamentsUseCaseProvider).call();
  return r.fold((_) => [], (list) => list);
});

class TournamentListScreen extends ConsumerStatefulWidget {
  const TournamentListScreen({super.key});

  @override
  ConsumerState<TournamentListScreen> createState() =>
      _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(_allTournamentsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Tournaments', style: AppTextStyles.heading(size: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.createTournament),
            tooltip: 'Create tournament',
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          dividerHeight: 0,
          dividerColor: Colors.transparent,
          indicatorColor: AppColors.yellow,
          labelColor: AppColors.yellow,
          unselectedLabelColor: AppColors.muted,
          labelStyle: AppTextStyles.label(color: AppColors.yellow, size: 12),
          tabs: const [
            Tab(text: 'Ongoing'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: all.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: ShimmerList(count: 4),
        ),
        error: (_, __) => const EmptyState(
            title: 'Error', subtitle: 'Could not load tournaments'),
        data: (list) => TabBarView(
          controller: _tab,
          children: [
            _TournamentTabList(
              tournaments: list.where((t) => t.status == 'active').toList(),
              emptyTitle: 'No ongoing tournaments',
              emptySubtitle: 'Start a tournament to see it here',
            ),
            _TournamentTabList(
              tournaments: list.where((t) => t.status == 'setup').toList(),
              emptyTitle: 'No upcoming tournaments',
              emptySubtitle: 'Create one to get started',
              onAction: () => context.push(AppRoutes.createTournament),
              actionLabel: 'Create Tournament',
            ),
            _TournamentTabList(
              tournaments: list.where((t) => t.status == 'completed').toList(),
              emptyTitle: 'No completed tournaments',
              emptySubtitle: 'Completed tournaments will appear here',
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentTabList extends StatelessWidget {
  final List<TournamentEntity> tournaments;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _TournamentTabList({
    required this.tournaments,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        onAction: onAction,
        actionLabel: actionLabel,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: tournaments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _TournamentListCard(tournament: tournaments[i]),
    );
  }
}

class _TournamentListCard extends StatelessWidget {
  final TournamentEntity tournament;
  const _TournamentListCard({required this.tournament});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () =>
            context.push('${AppRoutes.tournamentDetail}/${tournament.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg3,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: AppTextStyles.subheading(
                          color: AppColors.white, size: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  MatchStatusChip(status: tournament.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetaTag(
                    icon: Icons.sports_esports_outlined,
                    label: tournament.gameType.toUpperCase(),
                  ),
                  const SizedBox(width: 10),
                  _MetaTag(
                    icon: Icons.format_list_numbered,
                    label: '${tournament.totalMatches} matches',
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.relative(tournament.createdAt),
                    style:
                        AppTextStyles.label(color: AppColors.muted, size: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.label(color: AppColors.muted, size: 11)),
        ],
      );
}
