// lib/presentation/features/dashboard/dashboard_screen.dart
// Tab 3 — Organizer Dashboard with real stats from Supabase

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/tournament_entity.dart';
import '../../common/providers/providers.dart';
import '../../common/widgets/app_shimmer.dart';
import '../../common/widgets/shared_widgets.dart';

// ── Stats model ────────────────────────────────────────────
class OrganizerStats {
  final int totalTournaments;
  final int activeTournaments;
  final int completedTournaments;
  final int totalMatchesManaged;
  final int totalTeamsProcessed;
  final int totalPlayersProcessed;
  final int setupTournaments;

  const OrganizerStats({
    this.totalTournaments      = 0,
    this.activeTournaments     = 0,
    this.completedTournaments  = 0,
    this.totalMatchesManaged   = 0,
    this.totalTeamsProcessed   = 0,
    this.totalPlayersProcessed = 0,
    this.setupTournaments      = 0,
  });
}

final _dashboardStatsProvider = FutureProvider<OrganizerStats>((ref) async {
  try {
    final db = ref.read(supabaseDataSourceProvider);

    // Get all tournaments
    final tournaments = await db.getMyTournaments();
    final total       = tournaments.length;
    final active      = tournaments.where((t) => t.status == 'active').length;
    final completed   = tournaments.where((t) => t.status == 'completed').length;
    final setup       = tournaments.where((t) => t.status == 'setup').length;

    // Get total matches and teams across all tournaments
    int totalMatches = 0;
    int totalTeams   = 0;
    int totalPlayers = 0;

    for (final t in tournaments) {
      final matches = await db.getMatches(t.id);
      totalMatches += matches
          .where((m) => m.status == 'completed')
          .length;

      final teams = await db.getTeams(t.id);
      totalTeams  += teams.length;
      totalPlayers += teams.fold(
          0, (sum, team) => sum + team.players.length);
    }

    return OrganizerStats(
      totalTournaments:      total,
      activeTournaments:     active,
      completedTournaments:  completed,
      totalMatchesManaged:   totalMatches,
      totalTeamsProcessed:   totalTeams,
      totalPlayersProcessed: totalPlayers,
      setupTournaments:      setup,
    );
  } catch (_) {
    return const OrganizerStats();
  }
});

final _recentTournamentsProvider =
FutureProvider<List<TournamentEntity>>((ref) async {
  final r = await ref.read(getMyTournamentsUseCaseProvider).call();
  return r.fold((_) => [], (list) => list.take(5).toList());
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats   = ref.watch(_dashboardStatsProvider);
    final recent  = ref.watch(_recentTournamentsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Dashboard',
            style: AppTextStyles.heading(size: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(_dashboardStatsProvider);
              ref.invalidate(_recentTournamentsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color:       AppColors.yellow,
        onRefresh: () async {
          ref.invalidate(_dashboardStatsProvider);
          ref.invalidate(_recentTournamentsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats grid ─────────────────────────
              stats.when(
                loading: () => const ShimmerList(
                    count: 2, itemHeight: 96),
                error: (_, __) => const InfoBanner(
                    'Could not load stats. Pull to refresh.'),
                data: (s) => Column(
                  children: [
                    // Row 1
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Tournaments',
                            value: '${s.totalTournaments}',
                            icon:  Icons.emoji_events_outlined,
                            color: AppColors.yellow,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Active',
                            value: '${s.activeTournaments}',
                            icon:  Icons.play_circle_outline,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Matches Managed',
                            value: '${s.totalMatchesManaged}',
                            icon:  Icons.sports_esports_outlined,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Completed',
                            value: '${s.completedTournaments}',
                            icon:  Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 3
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Teams Processed',
                            value: '${s.totalTeamsProcessed}',
                            icon:  Icons.group_outlined,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Players Processed',
                            value: '${s.totalPlayersProcessed}',
                            icon:  Icons.person_outlined,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Organizer Level ────────────────────
              stats.whenData((s) {
                final level = _calcLevel(s.totalMatchesManaged);
                return _OrganizerLevelCard(
                  level:         level,
                  matchesManaged: s.totalMatchesManaged,
                );
              }).valueOrNull ?? const SizedBox(),

              const SizedBox(height: 28),

              // ── Recent Tournaments ─────────────────
              const SectionLabel('Recent Tournaments'),
              recent.when(
                loading: () =>
                const ShimmerList(count: 3, itemHeight: 64),
                error: (_, __) => const SizedBox(),
                data: (list) => list.isEmpty
                    ? const InfoBanner(
                    'No tournaments yet. Create one to get started.')
                    : Column(
                  children: list
                      .map((t) => Padding(
                    padding:
                    const EdgeInsets.only(bottom: 10),
                    child: _RecentTournamentRow(t: t),
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _OrganizerLevel _calcLevel(int matches) {
    if (matches >= 100) return const _OrganizerLevel('Legend',  AppColors.rank1,    100);
    if (matches >= 50)  return const _OrganizerLevel('Pro',     AppColors.rank2,     50);
    if (matches >= 20)  return const _OrganizerLevel('Advanced',AppColors.info,      20);
    if (matches >= 5)   return const _OrganizerLevel('Rising',  AppColors.success,    5);
    return const _OrganizerLevel('Rookie', AppColors.muted, 0);
  }
}

// ── Stat Card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        AppColors.bg3,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(value,
            style: AppTextStyles.number(size: 26, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.label(
                color: AppColors.muted, size: 11)),
      ],
    ),
  );
}

// ── Organizer Level Card ───────────────────────────────────
class _OrganizerLevel {
  final String title;
  final Color  color;
  final int    minMatches;
  const _OrganizerLevel(this.title, this.color, this.minMatches);
}

class _OrganizerLevelCard extends StatelessWidget {
  final _OrganizerLevel level;
  final int             matchesManaged;

  const _OrganizerLevelCard({
    required this.level,
    required this.matchesManaged,
  });

  @override
  Widget build(BuildContext context) {
    final levels = [0, 5, 20, 50, 100];
    final idx    = levels.indexWhere((l) => matchesManaged < l);
    final next   = idx >= 0 ? levels[idx] : 100;
    final prev   = idx > 0  ? levels[idx - 1] : 0;
    final frac   = (next - prev) > 0
        ? (matchesManaged - prev) / (next - prev)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        level.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: level.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_outlined,
                  color: AppColors.yellow, size: 20),
              const SizedBox(width: 8),
              Text('Organizer Level',
                  style: AppTextStyles.label(
                      color: AppColors.muted, size: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(level.title,
                  style: AppTextStyles.heading(
                      size: 24, color: level.color)),
              const Spacer(),
              Text(
                '$matchesManaged matches managed',
                style: AppTextStyles.body(
                    color: AppColors.muted, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           frac.clamp(0.0, 1.0),
              backgroundColor: AppColors.bg4,
              valueColor:      AlwaysStoppedAnimation(level.color),
              minHeight:       6,
            ),
          ),
          if (next < 100) ...[
            const SizedBox(height: 6),
            Text(
              '${next - matchesManaged} more matches to next level',
              style: AppTextStyles.label(
                  color: AppColors.muted, size: 10),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text('Maximum level reached!',
                style: AppTextStyles.label(
                    color: AppColors.yellow, size: 10)),
          ],
        ],
      ),
    );
  }
}

// ── Recent tournament row ──────────────────────────────────
class _RecentTournamentRow extends StatelessWidget {
  final TournamentEntity t;
  const _RecentTournamentRow({required this.t});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('${AppRoutes.tournamentDetail}/${t.id}'),
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        AppColors.bg3,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.isActive
                  ? AppColors.success
                  : t.isCompleted
                  ? AppColors.muted
                  : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t.name,
                style: AppTextStyles.body(
                    color: AppColors.white, size: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            t.isActive
                ? 'Live'
                : t.isCompleted
                ? 'Done'
                : 'Setup',
            style: AppTextStyles.label(
              color: t.isActive
                  ? AppColors.success
                  : t.isCompleted
                  ? AppColors.muted
                  : AppColors.warning,
              size: 11,
            ),
          ),
        ],
      ),
    ),
  );
}