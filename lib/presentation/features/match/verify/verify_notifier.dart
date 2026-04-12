// lib/presentation/features/match/verify/verify_notifier.dart
//
// Manages OCR verification and saving of lobby / result data.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/models/ocr_result_model.dart';
import '../../../../domain/entities/team_entity.dart';
import '../../../../domain/entities/player_entity.dart';
import '../../../common/providers/providers.dart';

// ── Lobby Verify State ─────────────────────────────────────
class LobbyVerifyState {
  final List<OcrLobbyEntry> entries;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  const LobbyVerifyState({
    this.entries      = const [],
    this.isSaving     = false,
    this.isSaved      = false,
    this.errorMessage,
  });

  LobbyVerifyState copyWith({
    List<OcrLobbyEntry>? entries,
    bool?   isSaving,
    bool?   isSaved,
    String? errorMessage,
  }) =>
      LobbyVerifyState(
        entries:      entries      ?? this.entries,
        isSaving:     isSaving     ?? this.isSaving,
        isSaved:      isSaved      ?? this.isSaved,
        errorMessage: errorMessage,
      );
}

class LobbyVerifyNotifier extends StateNotifier<LobbyVerifyState> {
  final Ref    _ref;
  final String tournamentId;
  final String matchId;
  final List<TeamEntity> teams;

  LobbyVerifyNotifier(
    this._ref,
    this.tournamentId,
    this.matchId,
    this.teams,
    List<OcrLobbyEntry> entries,
  ) : super(LobbyVerifyState(entries: entries));

  void updatePlayerName(int slotIndex, int playerIndex, String name) {
    final updated = [...state.entries];
    final entry   = updated[slotIndex];
    final players = [...entry.playerNames];
    players[playerIndex] = name;
    updated[slotIndex] = OcrLobbyEntry(
      slotNumber:  entry.slotNumber,
      playerNames: players,
      confidence:  entry.confidence,
    );
    state = state.copyWith(entries: updated);
  }

  Future<void> confirm() async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    // Build player entities from OCR entries
    // Match each slot entry → find team by slot number → create players
    final slotToTeam = {for (final t in teams) t.slotNumber: t};
    final updatedTeams = <TeamEntity>[];

    for (final entry in state.entries) {
      final team = slotToTeam[entry.slotNumber];
      if (team == null) continue;

      final players = entry.playerNames
          .map((name) => PlayerEntity(
                id:           const Uuid().v4(),
                teamId:       team.id,
                tournamentId: tournamentId,
                name:         name.trim(),
              ))
          .toList();

      updatedTeams.add(team.copyWith(players: players));
    }

    final result = await _ref
        .read(tournamentRepositoryProvider)
        .savePlayers(updatedTeams);

    // Update match status → lobby_uploaded
    await _ref
        .read(matchRepositoryProvider)
        .updateMatchStatus(matchId, 'lobby_uploaded');

    result.fold(
      (f) => state = state.copyWith(isSaving: false, errorMessage: f.message),
      (_) => state = state.copyWith(isSaving: false, isSaved: true),
    );
  }
}

// ── Result Verify State ────────────────────────────────────
class ResultVerifyState {
  final List<OcrResultEntry> entries;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  const ResultVerifyState({
    this.entries      = const [],
    this.isSaving     = false,
    this.isSaved      = false,
    this.errorMessage,
  });

  ResultVerifyState copyWith({
    List<OcrResultEntry>? entries,
    bool?   isSaving,
    bool?   isSaved,
    String? errorMessage,
  }) =>
      ResultVerifyState(
        entries:      entries      ?? this.entries,
        isSaving:     isSaving     ?? this.isSaving,
        isSaved:      isSaved      ?? this.isSaved,
        errorMessage: errorMessage,
      );
}

class ResultVerifyNotifier extends StateNotifier<ResultVerifyState> {
  final Ref    _ref;
  final String tournamentId;
  final String matchId;
  final List<TeamEntity> teams;

  ResultVerifyNotifier(
    this._ref,
    this.tournamentId,
    this.matchId,
    this.teams,
    List<OcrResultEntry> entries,
  ) : super(ResultVerifyState(entries: entries));

  void assignTeam(int entryIndex, String teamId, String teamName) {
    final updated = [...state.entries];
    updated[entryIndex] = OcrResultEntry(
      rankPosition:       updated[entryIndex].rankPosition,
      players:            updated[entryIndex].players,
      matchedTeamId:      teamId,
      matchedTeamName:    teamName,
      matchConfidence:    1.0,
      isManuallyAssigned: true,
    );
    state = state.copyWith(entries: updated);
  }

  void updatePlayerKills(int entryIndex, int playerIndex, int kills) {
    final updated = [...state.entries];
    final players = [...updated[entryIndex].players];
    players[playerIndex] = OcrPlayerKill(
      playerName: players[playerIndex].playerName,
      kills:      kills,
    );
    updated[entryIndex] = OcrResultEntry(
      rankPosition:    updated[entryIndex].rankPosition,
      players:         players,
      matchedTeamId:   updated[entryIndex].matchedTeamId,
      matchedTeamName: updated[entryIndex].matchedTeamName,
      matchConfidence: updated[entryIndex].matchConfidence,
    );
    state = state.copyWith(entries: updated);
  }

  Future<void> confirm() async {
    // Check all entries have matched teams
    final unmatched = state.entries.where((e) => !e.isMatched).toList();
    if (unmatched.isNotEmpty) {
      state = state.copyWith(
        errorMessage:
            '${unmatched.length} team(s) not matched. Please assign manually.',
      );
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    final slotToTeam  = {for (final t in teams) t.id: t};
    final saveResults = _ref.read(saveMatchResultUseCaseProvider);
    final saveKills   = _ref.read(savePlayerKillsUseCaseProvider);

    for (final entry in state.entries) {
      if (!entry.isMatched) continue;

      final team = slotToTeam[entry.matchedTeamId];
      if (team == null) continue;

      // Save rank result
      await saveResults.call(
        matchId:      matchId,
        tournamentId: tournamentId,
        teamId:       entry.matchedTeamId!,
        slotNumber:   team.slotNumber,
        rankPosition: entry.rankPosition,
        kills:        entry.totalKills,
      );

      // Save individual player kills for MVP
      for (final player in entry.players) {
        final playerEntity = team.players.firstWhere(
          (p) => p.name.toLowerCase() == player.playerName.toLowerCase(),
          orElse: () => PlayerEntity(
            id:           const Uuid().v4(),
            teamId:       team.id,
            tournamentId: tournamentId,
            name:         player.playerName,
          ),
        );

        await saveKills.call(
          matchId:      matchId,
          tournamentId: tournamentId,
          teamId:       team.id,
          playerId:     playerEntity.id,
          playerName:   player.playerName,
          kills:        player.kills,
        );
      }
    }

    // Update match status
    await _ref
        .read(matchRepositoryProvider)
        .updateMatchStatus(matchId, 'completed');

    state = state.copyWith(isSaving: false, isSaved: true);
  }
}
