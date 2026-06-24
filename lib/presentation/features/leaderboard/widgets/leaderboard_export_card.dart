// lib/presentation/features/leaderboard/widgets/leaderboard_export_card.dart
//
// The exportable black & yellow styled leaderboard card.
// Wrap this in a Screenshot widget to capture it as PNG.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/leaderboard_entity.dart';
import '../../../common/widgets/shared_widgets.dart';

class LeaderboardExportCard extends StatelessWidget {
  final String tournamentName;
  final String organizerTag;
  final List<LeaderboardEntry> entries;
  final int totalMatches;

  const LeaderboardExportCard({
    super.key,
    required this.tournamentName,
    required this.organizerTag,
    required this.entries,
    required this.totalMatches,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        color: AppColors.bg,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No leaderboard data to export',
            style: AppTextStyles.body(color: AppColors.muted),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.all(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: const BoxDecoration(
                  color: AppColors.yellow,
                ),
                child: Column(
                  children: [
                    Text(
                      tournamentName.toUpperCase(),
                      style:
                          AppTextStyles.display(size: 20, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      color: Colors.black,
                      child: Text(
                        organizerTag.toUpperCase(),
                        style: AppTextStyles.label(
                            color: AppColors.yellow, size: 11),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Column Headers ────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppColors.bg2,
                child: Row(
                  children: [
                    const _HeaderCell('POS', width: 36),
                    const _HeaderCell('SLOT', width: 44),
                    const Expanded(child: _HeaderCell('TEAM')),
                    ...List.generate(
                      totalMatches,
                      (i) => _HeaderCell('M${i + 1}', width: 32),
                    ),
                    const _HeaderCell('TOTAL', width: 48),
                  ],
                ),
              ),

              // ── Rows ──────────────────────────────────────────
              ...entries.asMap().entries.map(
                    (e) => _LeaderboardExportRow(
                      entry: e.value,
                      position: e.key + 1,
                      totalMatches: totalMatches,
                    ),
                  ),

              // ── Footer ────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'by POINTCALC',
                      style: AppTextStyles.label(
                          color: AppColors.yellow, size: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double? width;
  const _HeaderCell(this.text, {this.width});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Text(
          text,
          style: AppTextStyles.label(color: AppColors.muted, size: 10),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      );
}

class _LeaderboardExportRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int position;
  final int totalMatches;

  const _LeaderboardExportRow({
    required this.entry,
    required this.position,
    required this.totalMatches,
  });

  Color get _rowColor {
    switch (position) {
      case 1:
        return AppColors.rank1.withOpacity(0.08);
      case 2:
        return AppColors.rank2.withOpacity(0.05);
      case 3:
        return AppColors.rank3.withOpacity(0.05);
      default:
        return position.isEven ? AppColors.bg2 : AppColors.bg3;
    }
  }

  Color get _posColor {
    switch (position) {
      case 1:
        return AppColors.rank1;
      case 2:
        return AppColors.rank2;
      case 3:
        return AppColors.rank3;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        color: _rowColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            // Position
            SizedBox(
              width: 36,
              child: Text(
                '#$position',
                style: AppTextStyles.label(color: _posColor, size: 12),
                textAlign: TextAlign.center,
              ),
            ),
            // Slot badge
            SizedBox(
              width: 44,
              child: Center(child: SlotBadge(slot: entry.slotNumber, size: 22)),
            ),
            // Team name
            Expanded(
              child: Text(
                entry.teamName,
                style: AppTextStyles.body(color: AppColors.white, size: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Per-match points
            ...List.generate(totalMatches, (i) {
              final pts = entry.matchBreakdown[i + 1];
              return SizedBox(
                width: 32,
                child: Text(
                  pts != null ? '$pts' : '-',
                  style: AppTextStyles.label(
                    color: pts != null ? AppColors.grey : AppColors.hint,
                    size: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
            // Grand total
            SizedBox(
              width: 48,
              child: Text(
                '${entry.grandTotal}',
                style: AppTextStyles.label(color: AppColors.yellow, size: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}

// ── MVP Export Card ────────────────────────────────────────
class MvpExportCard extends StatelessWidget {
  final String tournamentName;
  final List<MvpEntity> mvpList;

  const MvpExportCard({
    super.key,
    required this.tournamentName,
    required this.mvpList,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.yellow,
            child: Column(
              children: [
                Text('TOP 5 MVP',
                    style:
                        AppTextStyles.display(size: 22, color: Colors.black)),
                Text(tournamentName.toUpperCase(),
                    style: AppTextStyles.label(color: Colors.black, size: 11)),
              ],
            ),
          ),
          // MVP rows
          ...mvpList.map((mvp) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 32,
                      child: Text(
                        '#${mvp.mvpRank}',
                        style: AppTextStyles.heading(
                          size: 16,
                          color: _rankColor(mvp.mvpRank),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Slot + name
                    SlotBadge(slot: mvp.slotNumber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mvp.playerName,
                              style: AppTextStyles.subheading(
                                  color: AppColors.white, size: 13)),
                          Text(mvp.teamName,
                              style: AppTextStyles.body(
                                  color: AppColors.muted, size: 11)),
                        ],
                      ),
                    ),
                    // Kills
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${mvp.totalKills}',
                            style: AppTextStyles.number(size: 22)),
                        Text('KILLS',
                            style: AppTextStyles.label(
                                color: AppColors.muted, size: 9)),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('by POINTCALC',
                  style:
                      AppTextStyles.label(color: AppColors.yellow, size: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.rank1;
      case 2:
        return AppColors.rank2;
      case 3:
        return AppColors.rank3;
      default:
        return AppColors.muted;
    }
  }
}
