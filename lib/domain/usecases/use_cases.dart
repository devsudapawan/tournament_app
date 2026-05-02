// lib/domain/usecases/use_cases.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/repositories.dart';
import '../entities/tournament_entity.dart';
import '../entities/team_entity.dart';
import '../entities/match_entity.dart';
import '../entities/leaderboard_entity.dart';

// ════════════════════════════════════════════
// AUTH USE CASES
// ════════════════════════════════════════════
class SignInUseCase {
  final AuthRepository repo;
  SignInUseCase(this.repo);
  Future<Either<Failure, void>> call(String email, String password) =>
      repo.signInWithEmail(email, password);
}

class SignUpUseCase {
  final AuthRepository repo;
  SignUpUseCase(this.repo);
  // Returns true if email confirmation required
  Future<Either<Failure, bool>> call(String email, String password) =>
      repo.signUp(email, password);
}

class SignInWithGoogleUseCase {
  final AuthRepository repo;
  SignInWithGoogleUseCase(this.repo);
  Future<Either<Failure, void>> call() => repo.signInWithGoogle();
}

class SignInWithAppleUseCase {
  final AuthRepository repo;
  SignInWithAppleUseCase(this.repo);
  Future<Either<Failure, void>> call() => repo.signInWithApple();
}

class SignInWithFacebookUseCase {
  final AuthRepository repo;
  SignInWithFacebookUseCase(this.repo);
  Future<Either<Failure, void>> call() => repo.signInWithFacebook();
}

class SendPasswordResetUseCase {
  final AuthRepository repo;
  SendPasswordResetUseCase(this.repo);
  Future<Either<Failure, void>> call(String email) =>
      repo.sendPasswordResetEmail(email);
}

class ResendConfirmationUseCase {
  final AuthRepository repo;
  ResendConfirmationUseCase(this.repo);
  Future<Either<Failure, void>> call(String email) =>
      repo.resendConfirmationEmail(email);
}

class SignOutUseCase {
  final AuthRepository repo;
  SignOutUseCase(this.repo);
  Future<Either<Failure, void>> call() => repo.signOut();
}

class GetProfileUseCase {
  final AuthRepository repo;
  GetProfileUseCase(this.repo);
  Future<Either<Failure, Map<String, dynamic>?>> call() => repo.getProfile();
}

class SaveProfileUseCase {
  final AuthRepository repo;
  SaveProfileUseCase(this.repo);
  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      repo.saveProfile(data);
}

// ════════════════════════════════════════════
// TOURNAMENT USE CASES
// ════════════════════════════════════════════
class CreateTournamentUseCase {
  final TournamentRepository repo;
  CreateTournamentUseCase(this.repo);
  Future<Either<Failure, TournamentEntity>> call(TournamentEntity t) =>
      repo.createTournament(t);
}

class GetMyTournamentsUseCase {
  final TournamentRepository repo;
  GetMyTournamentsUseCase(this.repo);
  Future<Either<Failure, List<TournamentEntity>>> call() =>
      repo.getMyTournaments();
}

class GetTournamentUseCase {
  final TournamentRepository repo;
  GetTournamentUseCase(this.repo);
  Future<Either<Failure, TournamentEntity>> call(String id) =>
      repo.getTournament(id);
}

class SaveTeamsUseCase {
  final TournamentRepository repo;
  SaveTeamsUseCase(this.repo);
  Future<Either<Failure, List<TeamEntity>>> call(List<TeamEntity> teams) =>
      repo.saveTeams(teams);
}

class GetTeamsUseCase {
  final TournamentRepository repo;
  GetTeamsUseCase(this.repo);
  Future<Either<Failure, List<TeamEntity>>> call(String tournamentId) =>
      repo.getTeams(tournamentId);
}

// ════════════════════════════════════════════
// MATCH USE CASES
// ════════════════════════════════════════════
class CreateMatchesUseCase {
  final MatchRepository repo;
  CreateMatchesUseCase(this.repo);
  Future<Either<Failure, void>> call({
    required String tournamentId,
    required int total,
    required List<DateTime?> scheduledTimes,
  }) =>
      repo.createMatches(
        tournamentId:   tournamentId,
        total:          total,
        scheduledTimes: scheduledTimes,
      );
}

class GetMatchesUseCase {
  final MatchRepository repo;
  GetMatchesUseCase(this.repo);
  Future<Either<Failure, List<MatchEntity>>> call(String tournamentId) =>
      repo.getMatches(tournamentId);
}

class SaveMatchResultUseCase {
  final MatchRepository repo;
  SaveMatchResultUseCase(this.repo);
  Future<Either<Failure, void>> call({
    required String matchId,
    required String tournamentId,
    required String teamId,
    required int slotNumber,
    required int rankPosition,
    required int kills,
  }) =>
      repo.saveMatchResult(
        matchId:      matchId,
        tournamentId: tournamentId,
        teamId:       teamId,
        slotNumber:   slotNumber,
        rankPosition: rankPosition,
        kills:        kills,
      );
}

class SavePlayerKillsUseCase {
  final MatchRepository repo;
  SavePlayerKillsUseCase(this.repo);
  Future<Either<Failure, void>> call({
    required String matchId,
    required String tournamentId,
    required String teamId,
    required String playerId,
    required String playerName,
    required int kills,
  }) =>
      repo.savePlayerKills(
        matchId:      matchId,
        tournamentId: tournamentId,
        teamId:       teamId,
        playerId:     playerId,
        playerName:   playerName,
        kills:        kills,
      );
}

// ════════════════════════════════════════════
// LEADERBOARD USE CASES
// ════════════════════════════════════════════
class GetLeaderboardUseCase {
  final LeaderboardRepository repo;
  GetLeaderboardUseCase(this.repo);
  Future<Either<Failure, List<LeaderboardEntry>>> call(String id) =>
      repo.getLeaderboard(id);
}

class GetMvpUseCase {
  final LeaderboardRepository repo;
  GetMvpUseCase(this.repo);
  Future<Either<Failure, List<MvpEntity>>> call(String id) =>
      repo.getMvp(id);
}

class GetMatchBreakdownUseCase {
  final LeaderboardRepository repo;
  GetMatchBreakdownUseCase(this.repo);
  Future<Either<Failure, List<Map<String, dynamic>>>> call(String id) =>
      repo.getMatchBreakdown(id);
}

class LeaderboardStreamUseCase {
  final LeaderboardRepository repo;
  LeaderboardStreamUseCase(this.repo);
  Stream<List<LeaderboardEntry>> call(String id) =>
      repo.leaderboardStream(id);
}



// Add inside TOURNAMENT USE CASES section:
class DeleteTournamentUseCase {
  final TournamentRepository repo;
  DeleteTournamentUseCase(this.repo);
  Future<Either<Failure, void>> call(String id) =>
      repo.deleteTournament(id);
}

// Add inside MATCH USE CASES section:
class AddMatchUseCase {
  final MatchRepository repo;
  AddMatchUseCase(this.repo);
  Future<Either<Failure, void>> call({
    required String tournamentId,
    required int matchNumber,
  }) =>
      repo.addMatch(
        tournamentId: tournamentId,
        matchNumber:  matchNumber,
      );
}

class DeleteMatchUseCase {
  final MatchRepository repo;
  DeleteMatchUseCase(this.repo);
  Future<Either<Failure, void>> call(String matchId) =>
      repo.deleteMatch(matchId);
}