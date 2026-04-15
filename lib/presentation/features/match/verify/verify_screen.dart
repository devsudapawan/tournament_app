import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/shared_widgets.dart';
import '../../../../data/models/ocr_result_model.dart';
import '../../../../core/router/app_router.dart';
import '../upload/upload_screen.dart';

final _verifyLoadingProvider = StateProvider<bool>((_) => false);

class VerifyScreen extends ConsumerWidget {
  final String matchId;
  final String uploadType;
  final String tournamentId;

  const VerifyScreen({
    super.key,
    required this.matchId,
    required this.uploadType,
    required this.tournamentId,
  });

  bool get isLobby => uploadType == 'lobby';

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(
            isLobby ? 'Verify Lobby Data' : 'Verify Match Results',
            style: AppTextStyles.heading(size: 17),
          ),
        ),
        body: isLobby
            ? _LobbyVerifyBody(providerKey: '${matchId}__$uploadType', tournamentId: tournamentId, matchId: matchId)
            : _ResultVerifyBody(providerKey: '${matchId}__$uploadType', tournamentId: tournamentId, matchId: matchId),
      );
}

// ── Lobby Verification ─────────────────────────────────────
class _LobbyVerifyBody extends ConsumerStatefulWidget {
  final String providerKey;
  final String tournamentId;
  final String matchId;
  const _LobbyVerifyBody({required this.providerKey, required this.tournamentId, required this.matchId});
  @override
  ConsumerState<_LobbyVerifyBody> createState() => _LobbyVerifyBodyState();
}

class _LobbyVerifyBodyState extends ConsumerState<_LobbyVerifyBody> {
  Future<void> _confirm(BuildContext context) async {
    ref.read(_verifyLoadingProvider.notifier).state = true;
    // TODO: save to Supabase via saveTeamsUseCase
    await Future.delayed(const Duration(seconds: 1));
    ref.read(_verifyLoadingProvider.notifier).state = false;
    if (context.mounted) {
      context.go('${AppRoutes.matchDetail}/${widget.tournamentId}/${widget.matchId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_verifyLoadingProvider);
    final _entries = ref.watch(lobbyAiResultProvider(widget.providerKey));
    return Stack(
      children: [
        Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: InfoBanner(
                'Review AI results below. Tap any field to edit if incorrect.',
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _LobbySlotCard(entry: _entries[i]),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: AppButton(
                  label: 'Confirm & Save Lobby',
                  onTap: () => _confirm(context),
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
        if (isLoading) const LoadingOverlay(message: 'Saving lobby data...'),
      ],
    );
  }
}

class _LobbySlotCard extends StatelessWidget {
  final OcrLobbyEntry entry;
  const _LobbySlotCard({required this.entry});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entry.confidence < 0.85
                ? AppColors.danger.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SlotBadge(slot: entry.slotNumber),
                  const SizedBox(width: 10),
                  Text('Slot #${entry.slotNumber}',
                      style: AppTextStyles.subheading(color: AppColors.white)),
                  const Spacer(),
                  ConfidenceDot(entry.confidence),
                  const SizedBox(width: 6),
                  Text(
                    '${(entry.confidence * 100).round()}% conf.',
                    style: AppTextStyles.label(
                      color: entry.confidence >= 0.85
                          ? AppColors.success
                          : AppColors.danger,
                      size: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Players
            ...entry.playerNames.asMap().entries.map((e) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    border: e.key < entry.playerNames.length - 1
                        ? const Border(
                            bottom: BorderSide(color: AppColors.border))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text('P${e.key + 1} ',
                          style: AppTextStyles.label(
                              color: AppColors.yellow, size: 11)),
                      Expanded(
                        child: TextFormField(
                          initialValue: e.value,
                          style: AppTextStyles.body(
                              color: AppColors.white, size: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
}

// ── Result Verification ─────────────────────────────────────
class _ResultVerifyBody extends ConsumerStatefulWidget {
  final String providerKey;
  final String tournamentId;
  final String matchId;
  const _ResultVerifyBody({required this.providerKey, required this.tournamentId, required this.matchId});
  @override
  ConsumerState<_ResultVerifyBody> createState() => _ResultVerifyBodyState();
}

class _ResultVerifyBodyState extends ConsumerState<_ResultVerifyBody> {
  Future<void> _confirm(BuildContext context) async {
    ref.read(_verifyLoadingProvider.notifier).state = true;
    // TODO: save results via saveMatchResultUseCase for each entry
    await Future.delayed(const Duration(seconds: 1));
    ref.read(_verifyLoadingProvider.notifier).state = false;
    if (context.mounted) {
      context.go('${AppRoutes.matchDetail}/${widget.tournamentId}/${widget.matchId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_verifyLoadingProvider);
    final _entries = ref.watch(resultAiResultProvider(widget.providerKey));
    return Stack(
      children: [
        Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: InfoBanner(
                'Each block shows rank, team match, and individual kills. Red border = needs manual team assignment.',
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ResultRankCard(
                  entry: _entries[i],
                  rank: i + 1,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: AppButton(
                  label: 'Confirm & Save Results',
                  onTap: () => _confirm(context),
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
        if (isLoading) const LoadingOverlay(message: 'Saving match results...'),
      ],
    );
  }
}

class _ResultRankCard extends StatelessWidget {
  final OcrResultEntry entry;
  final int rank;
  const _ResultRankCard({required this.entry, required this.rank});

  Color get _rankColor {
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

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !entry.isMatched
                ? AppColors.danger.withOpacity(0.5)
                : AppColors.border,
            width: !entry.isMatched ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Rank header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _rankColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _rankColor.withOpacity(0.5)),
                    ),
                    alignment: Alignment.center,
                    child: Text('#${entry.rankPosition}',
                        style:
                            AppTextStyles.label(color: _rankColor, size: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.matchedTeamName ?? 'Team not matched',
                          style: AppTextStyles.subheading(
                            color: entry.isMatched
                                ? AppColors.white
                                : AppColors.danger,
                          ),
                        ),
                        if (!entry.isMatched)
                          Text('Tap to assign team manually',
                              style: AppTextStyles.body(
                                  color: AppColors.danger, size: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${entry.totalKills} kills',
                      style: AppTextStyles.label(
                          color: AppColors.yellow, size: 10),
                    ),
                  ),
                ],
              ),
            ),
            // Players
            ...entry.players.map((p) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(p.playerName,
                            style: AppTextStyles.body(
                                color: AppColors.grey, size: 13)),
                      ),
                      Text('${p.kills} kills',
                          style: AppTextStyles.label(
                            color: p.kills > 0
                                ? AppColors.yellow
                                : AppColors.muted,
                            size: 11,
                          )),
                    ],
                  ),
                )),
          ],
        ),
      );
}
