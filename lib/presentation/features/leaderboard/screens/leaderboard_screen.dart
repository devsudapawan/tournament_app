// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:screenshot/screenshot.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../../common/providers/providers.dart';
// import '../../../common/widgets/shared_widgets.dart';
// import '../../../../core/utils/export_service.dart';
// import '../../../../domain/entities/leaderboard_entity.dart';
//
// final _leaderboardProvider =
//     StreamProvider.family<List<LeaderboardEntry>, String>(
//         (ref, tournamentId) =>
//             ref.watch(leaderboardStreamUseCaseProvider).call(tournamentId));
//
// final _mvpProvider =
//     FutureProvider.family<List<MvpEntity>, String>((ref, id) async {
//   final r = await ref.read(getMvpUseCaseProvider).call(id);
//   return r.fold((_) => [], (m) => m);
// });
//
// class LeaderboardScreen extends ConsumerStatefulWidget {
//   final String tournamentId;
//   const LeaderboardScreen({super.key, required this.tournamentId});
//   @override
//   ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
// }
//
// class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
//     with SingleTickerProviderStateMixin {
//   late final TabController _tab;
//   final _screenshotCtrl = ScreenshotController();
//
//   @override
//   void initState() {
//     super.initState();
//     _tab = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tab.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final leaderboard = ref.watch(_leaderboardProvider(widget.tournamentId));
//     final mvp         = ref.watch(_mvpProvider(widget.tournamentId));
//
//     return Scaffold(
//       backgroundColor: AppColors.bg,
//       appBar: AppBar(
//         title: Text('Leaderboard', style: AppTextStyles.heading(size: 17)),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.share_outlined),
//             onPressed: () => ExportService.exportAndShare(
//               controller: _screenshotCtrl,
//               fileName:   'leaderboard_${widget.tournamentId}',
//             ),
//           ),
//         ],
//         bottom: TabBar(
//           controller: _tab,
//           indicatorColor: AppColors.yellow,
//           labelColor: AppColors.yellow,
//           unselectedLabelColor: AppColors.muted,
//           tabs: const [
//             Tab(text: 'Point Table'),
//             Tab(text: 'Top 5 MVP'),
//           ],
//         ),
//       ),
//       body: Screenshot(
//         controller: _screenshotCtrl,
//         child: Container(
//           color: AppColors.bg,
//           child: TabBarView(
//             controller: _tab,
//             children: [
//               // ── Point Table Tab ──────────────────
//               leaderboard.when(
//                 loading: () => const Center(
//                     child: CircularProgressIndicator(
//                         color: AppColors.yellow)),
//                 error: (_, __) => const EmptyState(
//                     title: 'Error',
//                     subtitle: 'Could not load leaderboard'),
//                 data: (entries) => _PointTable(entries: entries),
//               ),
//
//               // ── MVP Tab ──────────────────────────
//               mvp.when(
//                 loading: () => const Center(
//                     child: CircularProgressIndicator(
//                         color: AppColors.yellow)),
//                 error: (_, __) => const EmptyState(
//                     title: 'Error',
//                     subtitle: 'Could not load MVP data'),
//                 data: (mvpList) => _MvpList(mvpList: mvpList),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ── Point Table ────────────────────────────────────────────
// class _PointTable extends StatelessWidget {
//   final List<LeaderboardEntry> entries;
//   const _PointTable({required this.entries});
//
//   @override
//   Widget build(BuildContext context) {
//     if (entries.isEmpty) {
//       return const EmptyState(
//         title: 'No results yet',
//         subtitle: 'Complete matches to see standings',
//       );
//     }
//     return ListView.separated(
//       padding: const EdgeInsets.all(16),
//       itemCount: entries.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 8),
//       itemBuilder: (_, i) => _LeaderboardRow(
//         entry: entries[i],
//         position: i + 1,
//       ),
//     );
//   }
// }
//
// class _LeaderboardRow extends StatelessWidget {
//   final LeaderboardEntry entry;
//   final int position;
//   const _LeaderboardRow({required this.entry, required this.position});
//
//   Color get _posColor {
//     switch (position) {
//       case 1:  return AppColors.rank1;
//       case 2:  return AppColors.rank2;
//       case 3:  return AppColors.rank3;
//       default: return AppColors.muted;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//     decoration: BoxDecoration(
//       color: position <= 3
//           ? _posColor.withOpacity(0.06)
//           : AppColors.bg3,
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(
//         color: position <= 3
//             ? _posColor.withOpacity(0.3)
//             : AppColors.border,
//       ),
//     ),
//     child: Row(
//       children: [
//         // Position
//         SizedBox(
//           width: 32,
//           child: Text(
//             '#$position',
//             style: AppTextStyles.heading(
//                 size: 15, color: _posColor),
//           ),
//         ),
//         // Slot + Team
//         SlotBadge(slot: entry.slotNumber, size: 26),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             entry.teamName,
//             style: AppTextStyles.subheading(
//                 color: AppColors.white, size: 14),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//         // Points breakdown
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text(
//               '${entry.grandTotal}',
//               style: AppTextStyles.number(size: 20),
//             ),
//             Text(
//               'R:${entry.totalRankPoints}  K:${entry.totalKillPoints}',
//               style: AppTextStyles.label(
//                   color: AppColors.muted, size: 10),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }
//
// // ── MVP List ───────────────────────────────────────────────
// class _MvpList extends StatelessWidget {
//   final List<MvpEntity> mvpList;
//   const _MvpList({required this.mvpList});
//
//   @override
//   Widget build(BuildContext context) {
//     if (mvpList.isEmpty) {
//       return const EmptyState(
//         title: 'No MVP data yet',
//         subtitle: 'Complete matches to see top killers',
//       );
//     }
//     return ListView.separated(
//       padding: const EdgeInsets.all(16),
//       itemCount: mvpList.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 8),
//       itemBuilder: (_, i) => _MvpCard(mvp: mvpList[i]),
//     );
//   }
// }
//
// class _MvpCard extends StatelessWidget {
//   final MvpEntity mvp;
//   const _MvpCard({required this.mvp});
//
//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: mvp.mvpRank == 1
//           ? AppColors.rank1.withOpacity(0.07)
//           : AppColors.bg3,
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(
//         color: mvp.mvpRank == 1
//             ? AppColors.rank1.withOpacity(0.3)
//             : AppColors.border,
//       ),
//     ),
//     child: Row(
//       children: [
//         // Rank badge
//         Container(
//           width: 40, height: 40,
//           decoration: BoxDecoration(
//             color: _rankColor(mvp.mvpRank).withOpacity(0.15),
//             shape: BoxShape.circle,
//             border: Border.all(
//                 color: _rankColor(mvp.mvpRank).withOpacity(0.5)),
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             mvp.mvpRank == 1 ? '🏆' : '#${mvp.mvpRank}',
//             style: AppTextStyles.body(size: mvp.mvpRank == 1 ? 18 : 13),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(mvp.playerName,
//                   style: AppTextStyles.subheading(color: AppColors.white)),
//               Row(
//                 children: [
//                   SlotBadge(slot: mvp.slotNumber, size: 18),
//                   const SizedBox(width: 6),
//                   Text(mvp.teamName,
//                       style: AppTextStyles.body(
//                           color: AppColors.muted, size: 12)),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text('${mvp.totalKills}',
//                 style: AppTextStyles.number(size: 24)),
//             Text('TOTAL KILLS',
//                 style: AppTextStyles.label(
//                     color: AppColors.muted, size: 9)),
//           ],
//         ),
//       ],
//     ),
//   );
//
//   Color _rankColor(int rank) {
//     switch (rank) {
//       case 1:  return AppColors.rank1;
//       case 2:  return AppColors.rank2;
//       case 3:  return AppColors.rank3;
//       default: return AppColors.muted;
//     }
//   }
// }
// lib/presentation/features/leaderboard/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/providers/providers.dart';
import '../../../common/widgets/shared_widgets.dart';
import '../../../../domain/entities/leaderboard_entity.dart';

final _leaderboardProvider =
StreamProvider.family<List<LeaderboardEntry>, String>(
      (ref, tournamentId) =>
      ref.watch(leaderboardStreamUseCaseProvider).call(tournamentId),
);

final _mvpProvider =
FutureProvider.family<List<MvpEntity>, String>((ref, id) async {
  final r = await ref.read(getMvpUseCaseProvider).call(id);
  return r.fold((_) => [], (m) => m);
});

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
  final bool _isExporting = false;

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

  // Future<void> _share() async {
  //   if (_isExporting) return;
  //   setState(() => _isExporting = true);
  //   try {
  //     await ExportService.exportAndShare(
  //       controller: _screenshotCtrl,
  //       fileName:   'leaderboard_${widget.tournamentId}',
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isExporting = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final leaderboard = ref.watch(_leaderboardProvider(widget.tournamentId));
    final mvp         = ref.watch(_mvpProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Leaderboard', style: AppTextStyles.heading(size: 17)),
        actions: [
          _isExporting
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                color: AppColors.yellow, strokeWidth: 2,
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: (){
              // _share
            },
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
          child: TabBarView(
            controller: _tab,
            children: [
              // ── Point Table Tab ──────────────────────
              leaderboard.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.yellow)),
                error: (_, __) => const EmptyState(
                    title: 'Error', subtitle: 'Could not load leaderboard'),
                data: (entries) => _PointTable(entries: entries),
              ),

              // ── MVP Tab ──────────────────────────────
              mvp.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.yellow)),
                error: (_, __) => const EmptyState(
                    title: 'Error', subtitle: 'Could not load MVP data'),
                data: (mvpList) => _MvpList(mvpList: mvpList),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Point Table ────────────────────────────────────────────
class _PointTable extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _PointTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
        title:    'No results yet',
        subtitle: 'Complete matches to see standings',
      );
    }
    return ListView.separated(
      padding:          const EdgeInsets.all(16),
      itemCount:        entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder:      (_, i)  => _LeaderboardRow(
        entry:    entries[i],
        position: i + 1,
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int position;
  const _LeaderboardRow({required this.entry, required this.position});

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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: position <= 3
          ? _posColor.withOpacity(0.06)
          : AppColors.bg3,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: position <= 3
            ? _posColor.withOpacity(0.3)
            : AppColors.border,
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            '#$position',
            style: AppTextStyles.heading(size: 15, color: _posColor),
          ),
        ),
        SlotBadge(slot: entry.slotNumber, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            entry.teamName,
            style:    AppTextStyles.subheading(color: AppColors.white, size: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.grandTotal}',
              style: AppTextStyles.number(size: 20),
            ),
            Text(
              'R:${entry.totalRankPoints}  K:${entry.totalKillPoints}',
              style: AppTextStyles.label(color: AppColors.muted, size: 10),
            ),
          ],
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
                      style:    AppTextStyles.body(color: AppColors.muted, size: 12),
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