// lib/presentation/features/match/verify/verify_notifier.dart
//
// Manages OCR verification and saving of lobby / result data.
// Lobby: saves players to DB, updates match status → lobby_uploaded
// Result: runs MatchResolutionService, saves points, status → completed

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/match_resolution_service.dart';
import '../../../../data/models/ocr_result_model.dart';
import '../../../../domain/entities/team_entity.dart';
import '../../../../domain/entities/player_entity.dart';
import '../../../common/providers/providers.dart';
import '../upload/upload_screen.dart';

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

  LobbyVerifyNotifier(
    this._ref,
    this.tournamentId,
    this.matchId,
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

    try {
      // Load teams from DB for this tournament
      final teamsResult = await _ref
          .read(getTeamsUseCaseProvider)
          .call(tournamentId);
      final teams = teamsResult.fold(
        (f) => <TeamEntity>[],
        (t) => t,
      );

      if (teams.isEmpty) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'No teams found for this tournament.',
        );
        return;
      }

      // Build player entities from OCR entries
      // Match each slot entry → find team by slot number → create players
      final slotToTeam = {for (final t in teams) t.slotNumber: t};
      final updatedTeams = <TeamEntity>[];

      for (final entry in state.entries) {
        final team = slotToTeam[entry.slotNumber];
        if (team == null) continue;

        final players = entry.playerNames
            .where((name) => name.trim().isNotEmpty)
            .map((name) => PlayerEntity(
                  id:           const Uuid().v4(),
                  teamId:       team.id,
                  tournamentId: tournamentId,
                  name:         name.trim(),
                ))
            .toList();

        updatedTeams.add(team.copyWith(players: players));
      }

      // Save players to DB
      final result = await _ref
          .read(tournamentRepositoryProvider)
          .savePlayers(updatedTeams);

      // Check for save error
      final hasError = result.fold((_) => true, (_) => false);
      if (hasError) {
        result.fold(
          (f) => state = state.copyWith(
            isSaving: false,
            errorMessage: f.message,
          ),
          (_) {},
        );
        return;
      }

      // Update match status → lobby_uploaded
      await _ref
          .read(matchRepositoryProvider)
          .updateMatchStatus(matchId, 'lobby_uploaded');

      state = state.copyWith(isSaving: false, isSaved: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save lobby: ${e.toString()}',
      );
    }
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

  ResultVerifyNotifier(
    this._ref,
    this.tournamentId,
    this.matchId,
    List<OcrResultEntry> entries,
  ) : super(ResultVerifyState(entries: entries));

  void updatePlayerKills(int entryIndex, int playerIndex, int kills) {
    final updated = [...state.entries];
    final players = [...updated[entryIndex].players];
    players[playerIndex] = OcrPlayerKill(
      playerName: players[playerIndex].playerName,
      kills:      kills,
    );
    updated[entryIndex] = OcrResultEntry(
      rankPosition: updated[entryIndex].rankPosition,
      players:      players,
    );
    state = state.copyWith(entries: updated);
  }

  /// Runs the full matching pipeline (Steps 4.1–4.5) then saves.
  Future<void> confirm() async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      // ── Stage 1+2: Load teams (with players from lobby) ──────
      final teamsResult = await _ref
          .read(getTeamsUseCaseProvider)
          .call(tournamentId);
      final teams = teamsResult.fold(
        (f) => <TeamEntity>[],
        (t) => t,
      );

      if (teams.isEmpty) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'No teams found. Was the lobby uploaded for this match?',
        );
        return;
      }

      // Verify teams have players loaded (from lobby save)
      final hasPlayers = teams.any((t) => t.players.isNotEmpty);
      if (!hasPlayers) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'No player data found. Please upload lobby first.',
        );
        return;
      }

      // ── Stage 3: Match result players → lobby players → teams ──
      // Uses MatchResolutionService for fuzzy matching (threshold: 0.75)
      final resolved = MatchResolutionService.resolveMatchResults(
        resultEntries: state.entries,
        teams:         teams,
      );

      // Check for unmatched teams
      final unmatched = resolved.where((r) => r.teamId.isEmpty).toList();
      if (unmatched.isNotEmpty) {
        state = state.copyWith(
          isSaving: false,
          errorMessage:
              '${unmatched.length} team(s) could not be matched to lobby data. '
              'Please check lobby player names.',
        );
        return;
      }

      // ── Stage 4+5: Save results to DB ──────────────────────
      final saveResults = _ref.read(saveMatchResultUseCaseProvider);
      final saveKills   = _ref.read(savePlayerKillsUseCaseProvider);

      for (final result in resolved) {
        // Save match result per team
        // The Supabase RPC 'calculate_and_insert_match_result' handles
        // rank_points, kill_points, total_points calculation server-side
        await saveResults.call(
          matchId:      matchId,
          tournamentId: tournamentId,
          teamId:       result.teamId,
          slotNumber:   result.slotNumber,
          rankPosition: result.rankPosition,
          kills:        result.totalKills,
        );

        // Save individual player kills for MVP tracking
        final team = teams.firstWhere(
          (t) => t.id == result.teamId,
        );

        for (final player in result.playerKills) {
          // Try to find existing player entity from lobby data
          PlayerEntity playerEntity;
          try {
            playerEntity = team.players.firstWhere(
              (p) => p.name.toLowerCase() == player.playerName.toLowerCase(),
            );
          } catch (_) {
            // Player not found in lobby — create a temporary ID
            playerEntity = PlayerEntity(
              id:           const Uuid().v4(),
              teamId:       team.id,
              tournamentId: tournamentId,
              name:         player.playerName,
            );
          }

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

      // Update match status → completed
      await _ref
          .read(matchRepositoryProvider)
          .updateMatchStatus(matchId, 'completed');

      state = state.copyWith(isSaving: false, isSaved: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save results: ${e.toString()}',
      );
    }
  }
}

// ── Providers ──────────────────────────────────────────────
// Key format: "tournamentId__matchId"

final lobbyVerifyNotifierProvider = StateNotifierProvider.autoDispose
    .family<LobbyVerifyNotifier, LobbyVerifyState, String>(
  (ref, key) {
    final parts        = key.split('__');
    final tournamentId = parts[0];
    final matchId      = parts[1];
    // Read AI-extracted lobby entries from upload screen provider
    final providerKey  = '${matchId}__lobby';
    final entries      = ref.read(lobbyAiResultProvider(providerKey));
    return LobbyVerifyNotifier(ref, tournamentId, matchId, entries);
  },
);

final resultVerifyNotifierProvider = StateNotifierProvider.autoDispose
    .family<ResultVerifyNotifier, ResultVerifyState, String>(
  (ref, key) {
    final parts        = key.split('__');
    final tournamentId = parts[0];
    final matchId      = parts[1];
    // Read AI-extracted result entries from upload screen provider
    final providerKey  = '${matchId}__result';
    final entries      = ref.read(resultAiResultProvider(providerKey));
    return ResultVerifyNotifier(ref, tournamentId, matchId, entries);
  },
);
