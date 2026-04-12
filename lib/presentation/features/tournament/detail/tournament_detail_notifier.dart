// lib/presentation/features/tournament/detail/tournament_detail_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/tournament_entity.dart';
import '../../../../domain/entities/match_entity.dart';
import '../../../../domain/entities/team_entity.dart';
import '../../../common/providers/providers.dart';

class TournamentDetailState {
  final bool isLoading;
  final String? errorMessage;
  final TournamentEntity? tournament;
  final List<MatchEntity> matches;
  final List<TeamEntity> teams;

  const TournamentDetailState({
    this.isLoading    = false,
    this.errorMessage,
    this.tournament,
    this.matches      = const [],
    this.teams        = const [],
  });

  TournamentDetailState copyWith({
    bool?               isLoading,
    String?             errorMessage,
    TournamentEntity?   tournament,
    List<MatchEntity>?  matches,
    List<TeamEntity>?   teams,
  }) =>
      TournamentDetailState(
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage,
        tournament:   tournament   ?? this.tournament,
        matches:      matches      ?? this.matches,
        teams:        teams        ?? this.teams,
      );
}

class TournamentDetailNotifier
    extends StateNotifier<TournamentDetailState> {
  final Ref _ref;
  final String tournamentId;

  TournamentDetailNotifier(this._ref, this.tournamentId)
      : super(const TournamentDetailState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);

    final tResult = await _ref
        .read(getTournamentUseCaseProvider)
        .call(tournamentId);
    final mResult = await _ref
        .read(getMatchesUseCaseProvider)
        .call(tournamentId);
    final teamResult = await _ref
        .read(getTeamsUseCaseProvider)
        .call(tournamentId);

    state = state.copyWith(
      isLoading:  false,
      tournament: tResult.fold((_) => null, (t) => t),
      matches:    mResult.fold((_) => [], (m) => m),
      teams:      teamResult.fold((_) => [], (t) => t),
    );
  }

  Future<void> refresh() => load();
}

final tournamentDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<TournamentDetailNotifier, TournamentDetailState, String>(
  (ref, id) => TournamentDetailNotifier(ref, id),
);
