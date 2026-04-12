// lib/presentation/features/match/detail/match_detail_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/match_entity.dart';
import '../../../../domain/entities/team_entity.dart';

class MatchDetailState {
  final bool isLoading;
  final MatchEntity? match;
  final List<TeamEntity> teams;
  final String? errorMessage;

  const MatchDetailState({
    this.isLoading    = false,
    this.match,
    this.teams        = const [],
    this.errorMessage,
  });

  MatchDetailState copyWith({
    bool?             isLoading,
    MatchEntity?      match,
    List<TeamEntity>? teams,
    String?           errorMessage,
  }) =>
      MatchDetailState(
        isLoading:    isLoading    ?? this.isLoading,
        match:        match        ?? this.match,
        teams:        teams        ?? this.teams,
        errorMessage: errorMessage,
      );
}

class MatchDetailNotifier extends StateNotifier<MatchDetailState> {
  final Ref    _ref;
  final String matchId;

  MatchDetailNotifier(this._ref, this.matchId)
      : super(const MatchDetailState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);

    // Get all matches for the tournament to find this one
    // In a real app you'd have a getMatch(id) endpoint
    // For now we mark it loaded
    state = state.copyWith(isLoading: false);
  }
}

final matchDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<MatchDetailNotifier, MatchDetailState, String>(
  (ref, matchId) => MatchDetailNotifier(ref, matchId),
);
