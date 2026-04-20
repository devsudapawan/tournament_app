// lib/presentation/features/leaderboard/screens/leaderboard_screen.dart
//
// Point Table structure (Step 5):
//   Pos | Slot | Team Name | M1 | M2 | M3 | Total
//
// Per-match breakdown is fetched via getMatchBreakdownUseCaseProvider.
// Only completed matches appear (DB-side filtering).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/widgets/shared_widgets.dart';
import '../../../../domain/entities/leaderboard_entity.dart';
import '../screens/leaderboard_notifier.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const LeaderboardScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final ScreenshotController _screenshotCtrl = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
        leaderboardNotifierProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Leaderboard', style: AppTextStyles.heading(size: 17)),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh, color: AppColors.muted),
            tooltip:   'Refresh',
            onPressed: () => ref
                .read(leaderboardNotifierProvider(widget.tournamentId)
                    .notifier)
                .refresh(),
          ),
          IconButton(
            icon:      const Icon(Icons.share_outlined),
            onPressed: () {}, // export reserved for later
          ),
        ],
        bottom: TabBar(
          controller:           _tab,
          indicatorColor:       AppColors.yellow,
          labelColor:           AppColors.yellow,
          unselectedLabelColor: AppColors.muted,
          tabs: const [
            Tab(text: 'Point Table'),
            Tab(text: 'Top 5 MVP'),
          ],
        ),
      ),
      body: Screenshot(
        controller: _screenshotCtrl,
        child: Container(
          color: AppColors.bg,
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.yellow))
              : state.errorMessage != null
                  ? EmptyState(
                      title:    'Error',
                      subtitle: state.errorMessage!)
                  : TabBarView(
                      controller: _tab,
                      children: [
                        // ── Point Table Tab ──────────────────────
                        _PointTable(
                          entries:         state.entries,
                          matchBreakdowns: state.matchBreakdowns,
                        ),
                        // ── MVP Tab ──────────────────────────────
                        _MvpList(mvpList: state.mvpList),
                      ],
                    ),
        ),
      ),
    );
  }
}

// ── Point Table ────────────────────────────────────────────
class _PointTable extends StatelessWidget {
  final List<LeaderboardEntry>          entries;
  final Map<String, Map<int, int>>      matchBreakdowns; // teamId → matchNum → pts

  const _PointTable({
    required this.entries,
    required this.matchBreakdowns,
  });

  /// Sorted list of all match numbers that appear in the breakdowns.
  List<int> get _matchNumbers {
    final nums = <int>{};
    for (final byMatch in matchBreakdowns.values) {
      nums.addAll(byMatch.keys);
    }
    final sorted = nums.toList()..sort();
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
        title:    'No results yet',
        subtitle: 'Complete matches to see standings',
      );
    }

    final matchNums = _matchNumbers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────
          _TableHeader(matchNums: matchNums),
          const SizedBox(height: 8),
          // ── Data rows ───────────────────────────────
          ...entries.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PointTableRow(
                  entry:      e.value,
                  position:   e.key + 1,
                  matchNums:  matchNums,
                  breakdown:  matchBreakdowns[e.value.teamId] ?? {},
                ),
              )),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<int> matchNums;
  const _TableHeader({required this.matchNums});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        AppColors.bg3,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Pos
            SizedBox(
              width: 30,
              child: Text(
                'Pos',
                style: AppTextStyles.label(color: AppColors.muted, size: 10),
              ),
            ),
            // Slot
            SizedBox(
              width: 36,
              child: Text(
                'Slot',
                style: AppTextStyles.label(color: AppColors.muted, size: 10),
              ),
            ),
            // Team name
            Expanded(
              child: Text(
                'Team',
                style: AppTextStyles.label(color: AppColors.muted, size: 10),
              ),
            ),
            // Match columns
            ...matchNums.map((m) => SizedBox(
                  width: 32,
                  child: Text(
                    'M$m',
                    style: AppTextStyles.label(
                        color: AppColors.yellow, size: 10),
                    textAlign: TextAlign.center,
                  ),
                )),
            // Total
            SizedBox(
              width: 42,
              child: Text(
                'Total',
                style: AppTextStyles.label(
                    color: AppColors.white, size: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}

class _PointTableRow extends StatelessWidget {
  final LeaderboardEntry  entry;
  final int               position;
  final List<int>         matchNums;
  final Map<int, int>     breakdown; // matchNum → points

  const _PointTableRow({
    required this.entry,
    required this.position,
    required this.matchNums,
    required this.breakdown,
  });

  Color get _posColor {
    switch (position) {
      case 1:  return AppColors.rank1;
      case 2:  return AppColors.rank2;
      case 3:  return AppColors.rank3;
      default: return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: position <= 3
              ? _posColor.withOpacity(0.06)
              : AppColors.bg3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: position <= 3
                ? _posColor.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Position
            SizedBox(
              width: 30,
              child: Text(
                '#$position',
                style: AppTextStyles.heading(size: 13, color: _posColor),
              ),
            ),
            // Slot badge
            SizedBox(
              width: 36,
              child: SlotBadge(slot: entry.slotNumber, size: 22),
            ),
            // Team name
            Expanded(
              child: Text(
                entry.teamName,
                style: AppTextStyles.subheading(
                    color: AppColors.white, size: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Per-match points (M1, M2, M3...)
            ...matchNums.map((m) {
              final pts = breakdown[m];
              return SizedBox(
                width: 32,
                child: Text(
                  pts != null ? '$pts' : '—',
                  style: AppTextStyles.label(
                    color: pts != null ? AppColors.white : AppColors.muted,
                    size: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
            // Grand total
            SizedBox(
              width: 42,
              child: Text(
                '${entry.grandTotal}',
                style: AppTextStyles.number(size: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}

// ── MVP List ───────────────────────────────────────────────
class _MvpList extends StatelessWidget {
  final List<MvpEntity> mvpList;
  const _MvpList({required this.mvpList});

  @override
  Widget build(BuildContext context) {
    if (mvpList.isEmpty) {
      return const EmptyState(
        title:    'No MVP data yet',
        subtitle: 'Complete matches to see top killers',
      );
    }
    return ListView.separated(
      padding:          const EdgeInsets.all(16),
      itemCount:        mvpList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder:      (_, i)  => _MvpCard(mvp: mvpList[i]),
    );
  }
}

class _MvpCard extends StatelessWidget {
  final MvpEntity mvp;
  const _MvpCard({required this.mvp});

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:  return AppColors.rank1;
      case 2:  return AppColors.rank2;
      case 3:  return AppColors.rank3;
      default: return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: mvp.mvpRank == 1
          ? AppColors.rank1.withOpacity(0.07)
          : AppColors.bg3,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: mvp.mvpRank == 1
            ? AppColors.rank1.withOpacity(0.3)
            : AppColors.border,
      ),
    ),
    child: Row(
      children: [
        // Rank circle
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color:  _rankColor(mvp.mvpRank).withOpacity(0.15),
            shape:  BoxShape.circle,
            border: Border.all(
                color: _rankColor(mvp.mvpRank).withOpacity(0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            mvp.mvpRank == 1 ? '🏆' : '#${mvp.mvpRank}',
            style: AppTextStyles.body(
                size: mvp.mvpRank == 1 ? 18 : 13),
          ),
        ),
        const SizedBox(width: 12),
        // Player info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mvp.playerName,
                style: AppTextStyles.subheading(color: AppColors.white),
              ),
              Row(
                children: [
                  SlotBadge(slot: mvp.slotNumber, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      mvp.teamName,
                      style: AppTextStyles.body(
                          color: AppColors.muted, size: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Kill count
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${mvp.totalKills}',
              style: AppTextStyles.number(size: 24),
            ),
            Text(
              'TOTAL KILLS',
              style: AppTextStyles.label(color: AppColors.muted, size: 9),
            ),
          ],
        ),
      ],
    ),
  );
}