// lib/presentation/features/match/verify/verify_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/shared_widgets.dart';
import '../../../../data/models/ocr_result_model.dart';
import '../../../../core/router/app_router.dart';

import 'verify_notifier.dart';

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

  // Provider key for notifiers: "tournamentId__matchId"
  String get notifierKey => '${tournamentId}__$matchId';

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
            ? _LobbyVerifyBody(
                notifierKey:  notifierKey,
                providerKey:  '${matchId}__lobby',
                tournamentId: tournamentId,
                matchId:      matchId,
              )
            : _ResultVerifyBody(
                notifierKey:  notifierKey,
                providerKey:  '${matchId}__result',
                tournamentId: tournamentId,
                matchId:      matchId,
              ),
      );
}

// ── Lobby Verification ─────────────────────────────────────
class _LobbyVerifyBody extends ConsumerStatefulWidget {
  final String notifierKey;
  final String providerKey;
  final String tournamentId;
  final String matchId;

  const _LobbyVerifyBody({
    required this.notifierKey,
    required this.providerKey,
    required this.tournamentId,
    required this.matchId,
  });

  @override
  ConsumerState<_LobbyVerifyBody> createState() => _LobbyVerifyBodyState();
}

class _LobbyVerifyBodyState extends ConsumerState<_LobbyVerifyBody> {
  // Track text editing controllers so edits are captured before save
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  String _controllerKey(int slot, int player) => '${slot}_$player';

  Future<void> _confirm(BuildContext context) async {
    // Flush any pending text field edits into the notifier state
    final notifier = ref.read(lobbyVerifyNotifierProvider(widget.notifierKey).notifier);
    final entries  = ref.read(lobbyVerifyNotifierProvider(widget.notifierKey)).entries;

    for (int i = 0; i < entries.length; i++) {
      for (int j = 0; j < entries[i].playerNames.length; j++) {
        final key  = _controllerKey(i, j);
        final ctrl = _controllers[key];
        if (ctrl != null) {
          notifier.updatePlayerName(i, j, ctrl.text.trim());
        }
      }
    }

    await notifier.confirm();

    if (!context.mounted) return;

    final state = ref.read(lobbyVerifyNotifierProvider(widget.notifierKey));

    if (state.errorMessage != null) {
      SnackBarHelper.showError(context, state.errorMessage!);
      return;
    }

    if (state.isSaved) {
      SnackBarHelper.showSuccess(context, 'Lobby saved! Match status → lobby_uploaded');
      context.go('${AppRoutes.matchDetail}/${widget.tournamentId}/${widget.matchId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lobbyVerifyNotifierProvider(widget.notifierKey));

    return Stack(
      children: [
        Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: InfoBanner(
                'Review AI results below. Tap any player name to edit if wrong.',
              ),
            ),
            Expanded(
              child: state.entries.isEmpty
                  ? const EmptyState(
                      title:    'No lobby data',
                      subtitle: 'Go back and process images first.',
                    )
                  : ListView.separated(
                      padding:          const EdgeInsets.all(20),
                      itemCount:        state.entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder:      (_, i) => _LobbySlotCard(
                        entry:           state.entries[i],
                        slotIndex:       i,
                        controllers:     _controllers,
                        controllerKeyFn: _controllerKey,
                      ),
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: AppButton(
                  label:     'Confirm & Save Lobby',
                  onTap:     state.isSaving ? null : () => _confirm(context),
                  isLoading: state.isSaving,
                ),
              ),
            ),
          ],
        ),
        if (state.isSaving)
          const LoadingOverlay(message: 'Saving lobby data...'),
      ],
    );
  }
}

class _LobbySlotCard extends StatelessWidget {
  final OcrLobbyEntry entry;
  final int           slotIndex;
  final Map<String, TextEditingController> controllers;
  final String Function(int, int) controllerKeyFn;

  const _LobbySlotCard({
    required this.entry,
    required this.slotIndex,
    required this.controllers,
    required this.controllerKeyFn,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        AppColors.bg3,
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
                  Text(
                    'Slot #${entry.slotNumber}',
                    style: AppTextStyles.subheading(color: AppColors.white),
                  ),
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
            // Player rows
            ...entry.playerNames.asMap().entries.map((e) {
              final key  = controllerKeyFn(slotIndex, e.key);
              controllers.putIfAbsent(
                key,
                () => TextEditingController(text: e.value),
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  border: e.key < entry.playerNames.length - 1
                      ? const Border(
                          bottom: BorderSide(color: AppColors.border))
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      'P${e.key + 1} ',
                      style: AppTextStyles.label(
                          color: AppColors.yellow, size: 11),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controllers[key],
                        style: AppTextStyles.body(
                            color: AppColors.white, size: 14),
                        decoration: const InputDecoration(
                          isDense:        true,
                          border:         InputBorder.none,
                          contentPadding: EdgeInsets.all(7),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
}

// ── Result Verification ─────────────────────────────────────
class _ResultVerifyBody extends ConsumerStatefulWidget {
  final String notifierKey;
  final String providerKey;
  final String tournamentId;
  final String matchId;

  const _ResultVerifyBody({
    required this.notifierKey,
    required this.providerKey,
    required this.tournamentId,
    required this.matchId,
  });

  @override
  ConsumerState<_ResultVerifyBody> createState() => _ResultVerifyBodyState();
}

class _ResultVerifyBodyState extends ConsumerState<_ResultVerifyBody> {
  // Controller key: "entryIndex_playerIndex"
  final Map<String, TextEditingController> _killControllers = {};

  @override
  void dispose() {
    for (final c in _killControllers.values) c.dispose();
    super.dispose();
  }

  String _controllerKey(int entry, int player) => '${entry}_$player';

  Future<void> _confirm(BuildContext context) async {
    final notifier = ref.read(resultVerifyNotifierProvider(widget.notifierKey).notifier);
    final entries  = ref.read(resultVerifyNotifierProvider(widget.notifierKey)).entries;

    // Flush kill edits into notifier state before saving
    for (int i = 0; i < entries.length; i++) {
      for (int j = 0; j < entries[i].players.length; j++) {
        final key  = _controllerKey(i, j);
        final ctrl = _killControllers[key];
        if (ctrl != null) {
          final kills =
              int.tryParse(ctrl.text.trim()) ?? entries[i].players[j].kills;
          notifier.updatePlayerKills(i, j, kills);
        }
      }
    }

    await notifier.confirm();

    if (!context.mounted) return;

    final state = ref.read(resultVerifyNotifierProvider(widget.notifierKey));

    if (state.errorMessage != null) {
      SnackBarHelper.showError(context, state.errorMessage!);
      return;
    }

    if (state.isSaved) {
      SnackBarHelper.showSuccess(context, 'Results saved! Match completed ✓');
      context.go('${AppRoutes.matchDetail}/${widget.tournamentId}/${widget.matchId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resultVerifyNotifierProvider(widget.notifierKey));

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: InfoBanner(
                state.entries.isEmpty
                    ? 'No result data found. Go back and process images.'
                    : 'Review ranks and kills. Matching runs automatically on confirm.',
              ),
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _ErrorBanner(message: state.errorMessage!),
              ),
            Expanded(
              child: state.entries.isEmpty
                  ? const EmptyState(
                      title:    'No result data',
                      subtitle: 'Go back and process images first.',
                    )
                  : ListView.separated(
                      padding:          const EdgeInsets.all(20),
                      itemCount:        state.entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder:      (_, i) => _ResultRankCard(
                        entry:           state.entries[i],
                        rank:            i + 1,
                        entryIndex:      i,
                        controllers:     _killControllers,
                        controllerKeyFn: _controllerKey,
                      ),
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: AppButton(
                  label:     state.isSaving
                      ? 'Matching & Saving...'
                      : 'Confirm & Save Results',
                  onTap:     state.isSaving ? null : () => _confirm(context),
                  isLoading: state.isSaving,
                ),
              ),
            ),
          ],
        ),
        if (state.isSaving)
          const LoadingOverlay(message: 'Running matching & saving results...'),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body(color: AppColors.danger, size: 12),
              ),
            ),
          ],
        ),
      );
}

class _ResultRankCard extends StatelessWidget {
  final OcrResultEntry  entry;
  final int             rank;
  final int             entryIndex;
  final Map<String, TextEditingController> controllers;
  final String Function(int, int) controllerKeyFn;

  const _ResultRankCard({
    required this.entry,
    required this.rank,
    required this.entryIndex,
    required this.controllers,
    required this.controllerKeyFn,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:  return AppColors.rank1;
      case 2:  return AppColors.rank2;
      case 3:  return AppColors.rank3;
      default: return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        AppColors.bg3,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColors.border),
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
                    width:  32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:        _rankColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border:       Border.all(color: _rankColor.withOpacity(0.5)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${entry.rankPosition}',
                      style: AppTextStyles.label(color: _rankColor, size: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rank ${entry.rankPosition} team',
                      style: AppTextStyles.subheading(color: AppColors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        AppColors.yellow.withOpacity(0.1),
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
            // Player rows — kills are editable
            ...entry.players.asMap().entries.map((e) {
              final key = controllerKeyFn(entryIndex, e.key);
              controllers.putIfAbsent(
                key,
                () => TextEditingController(text: '${e.value.kills}'),
              );
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.value.playerName,
                        style: AppTextStyles.body(
                            color: AppColors.grey, size: 13),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller:  controllers[key],
                        keyboardType: TextInputType.number,
                        textAlign:    TextAlign.center,
                        style: AppTextStyles.label(
                            color: AppColors.yellow, size: 13),
                        decoration: InputDecoration(
                          isDense:        true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:   const BorderSide(
                                color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                                color: AppColors.yellow),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                                color: AppColors.border),
                          ),
                          suffixText: 'K',
                          suffixStyle: AppTextStyles.label(
                              color: AppColors.muted, size: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
}
