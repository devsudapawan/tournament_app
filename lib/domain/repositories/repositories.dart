// lib/domain/repositories/repositories.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/tournament_entity.dart';
import '../entities/team_entity.dart';
import '../entities/match_entity.dart';
import '../entities/leaderboard_entity.dart';

// ── Auth Repository ────────────────────────────────────────
abstract class AuthRepository {
  Future<Either<Failure, void>>    signInWithEmail(String email, String password);
  Future<Either<Failure, void>>    signInWithPhone(String phone);
  Future<Either<Failure, bool>>    signUp(String email, String password);
  Future<Either<Failure, void>>    signInWithGoogle();
  Future<Either<Failure, void>>    signInWithApple();
  Future<Either<Failure, void>>    signInWithFacebook();
  Future<Either<Failure, void>>    sendPasswordResetEmail(String email);
  Future<Either<Failure, void>>    resendConfirmationEmail(String email);
  Future<Either<Failure, void>>    signOut();
  Future<Either<Failure, Map<String, dynamic>?>> getProfile();
  Future<Either<Failure, void>>    saveProfile(Map<String, dynamic> data);
  bool   get isLoggedIn;
  String? get userId;
}

// ── Tournament Repository ──────────────────────────────────
abstract class TournamentRepository {
  Future<Either<Failure, TournamentEntity>>       createTournament(TournamentEntity t);
  Future<Either<Failure, List<TournamentEntity>>> getMyTournaments();
  Future<Either<Failure, TournamentEntity>>       getTournament(String id);
  Future<Either<Failure, void>>                   updateStatus(String id, String status);
  Future<Either<Failure, List<TeamEntity>>>       saveTeams(List<TeamEntity> teams);
  Future<Either<Failure, List<TeamEntity>>>       getTeams(String tournamentId);
  Future<Either<Failure, void>>                   savePlayers(List<TeamEntity> teams);
}

// ── Match Repository ───────────────────────────────────────
abstract class MatchRepository {
  Future<Either<Failure, void>> createMatches({
    required String tournamentId,
    required int total,
    required List<DateTime?> scheduledTimes,
  });
  Future<Either<Failure, List<MatchEntity>>> getMatches(String tournamentId);
  Future<Either<Failure, void>> updateMatchStatus(String matchId, String status);
  Future<Either<Failure, void>> saveMatchResult({
    required String matchId,
    required String tournamentId,
    required String teamId,
    required int slotNumber,
    required int rankPosition,
    required int kills,
  });
  Future<Either<Failure, void>> savePlayerKills({
    required String matchId,
    required String tournamentId,
    required String teamId,
    required String playerId,
    required String playerName,
    required int kills,
  });
}

// ── Leaderboard Repository ─────────────────────────────────
abstract class LeaderboardRepository {
  Future<Either<Failure, List<LeaderboardEntry>>>       getLeaderboard(String tournamentId);
  Future<Either<Failure, List<MvpEntity>>>              getMvp(String tournamentId);
  Future<Either<Failure, List<Map<String, dynamic>>>>   getMatchBreakdown(String tournamentId);
  Stream<List<LeaderboardEntry>>                        leaderboardStream(String tournamentId);
}