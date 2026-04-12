// lib/presentation/features/leaderboard/screens/leaderboard_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/leaderboard_entity.dart';
import '../../../common/providers/providers.dart';

class LeaderboardState {
  final bool isLoading;
  final List<LeaderboardEntry> entries;
  final List<MvpEntity> mvpList;
  final Map<String, Map<int, int>> matchBreakdowns; // teamId → matchNum → pts
  final String? errorMessage;

  const LeaderboardState({
    this.isLoading       = false,
    this.entries         = const [],
    this.mvpList         = const [],
    this.matchBreakdowns = const {},
    this.errorMessage,
  });

  LeaderboardState copyWith({
    bool?                             isLoading,
    List<LeaderboardEntry>?           entries,
    List<MvpEntity>?                  mvpList,
    Map<String, Map<int, int>>?       matchBreakdowns,
    String?                           errorMessage,
  }) =>
      LeaderboardState(
        isLoading:       isLoading       ?? this.isLoading,
        entries:         entries         ?? this.entries,
        mvpList:         mvpList         ?? this.mvpList,
        matchBreakdowns: matchBreakdowns ?? this.matchBreakdowns,
        errorMessage:    errorMessage,
      );
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref    _ref;
  final String tournamentId;

  LeaderboardNotifier(this._ref, this.tournamentId)
      : super(const LeaderboardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);

    // Leaderboard
    final lbResult = await _ref
        .read(getLeaderboardUseCaseProvider)
        .call(tournamentId);

    // MVP
    final mvpResult = await _ref
        .read(getMvpUseCaseProvider)
        .call(tournamentId);

    // Per-match breakdown
    final breakdownResult = await _ref
        .read(getMatchBreakdownUseCaseProvider)
        .call(tournamentId);

    // Build breakdown map: teamId → { matchNumber → totalPoints }
    final breakdowns = <String, Map<int, int>>{};
    breakdownResult.fold((_) {}, (rows) {
      for (final row in rows) {
        final tid = row['team_id'] as String;
        final mn  = row['match_number'] as int;
        final pts = row['total_points'] as int;
        breakdowns[tid] ??= {};
        breakdowns[tid]![mn] = pts;
      }
    });

    state = state.copyWith(
      isLoading:       false,
      entries:         lbResult.fold((_) => [], (e) => e),
      mvpList:         mvpResult.fold((_) => [], (m) => m),
      matchBreakdowns: breakdowns,
    );
  }

  Future<void> refresh() => load();
}

final leaderboardNotifierProvider = StateNotifierProvider.autoDispose
    .family<LeaderboardNotifier, LeaderboardState, String>(
  (ref, tournamentId) => LeaderboardNotifier(ref, tournamentId),
);
