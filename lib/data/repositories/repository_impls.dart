// lib/data/repositories/repository_impls.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/team_entity.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/entities/leaderboard_entity.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../models/models.dart';

// ── Auth Repository ────────────────────────────────────────
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseDataSource remote;
  AuthRepositoryImpl(this.remote);

  @override
  bool get isLoggedIn => remote.currentUser != null;

  @override
  String? get userId => remote.currentUser?.id;

  @override
  Future<Either<Failure, void>> signInWithEmail(
      String email, String password) async {
    try {
      await remote.signInWithEmail(email, password);
      return const Right(null);
    } on AuthException catch (e) {
      // Pass the special marker so the UI can handle it differently
      return Left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signInWithPhone(String phone) async {
    return const Left(AuthFailure('Phone auth not implemented yet'));
  }

  @override
  Future<Either<Failure, bool>> signUp(String email, String password) async {
    try {
      final requiresConfirmation = await remote.signUp(email, password);
      return Right(requiresConfirmation);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    try {
      await remote.signInWithGoogle();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signInWithApple() async {
    try {
      await remote.signInWithApple();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signInWithFacebook() async {
    try {
      await remote.signInWithFacebook();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remote.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resendConfirmationEmail(String email) async {
    try {
      await remote.resendConfirmationEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remote.signOut();
      return const Right(null);
    } catch (_) {
      return const Left(AuthFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getProfile() async {
    try {
      return Right(await remote.getProfile());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveProfile(
      Map<String, dynamic> data) async {
    try {
      await remote.upsertProfile(data);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
  // Inside TournamentRepositoryImpl — add this method:
  @override
  Future<Either<Failure, void>> deleteTournament(String id) async {
    try {
      await remote.deleteTournament(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

// Inside MatchRepositoryImpl — add these two methods:
  @override
  Future<Either<Failure, void>> addMatch({
    required String tournamentId,
    required int matchNumber,
  }) async {
    try {
      await remote.insertMatches([{
        'tournament_id': tournamentId,
        'match_number':  matchNumber,
        'status':        'pending',
        'scheduled_at':  null,
      }]);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMatch(String matchId) async {
    try {
      await remote.deleteMatch(matchId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

}

// ── Tournament Repository ──────────────────────────────────
class TournamentRepositoryImpl implements TournamentRepository {
  final SupabaseDataSource remote;
  TournamentRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, TournamentEntity>> createTournament(
      TournamentEntity t) async {
    try {
      final model  = TournamentModel.fromEntity(t);
      final result = await remote.createTournament(model.toMap());
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<TournamentEntity>>> getMyTournaments() async {
    try {
      return Right(await remote.getMyTournaments());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> getTournament(String id) async {
    try {
      final t = await remote.getTournament(id);
      if (t == null) return const Left(ServerFailure('Tournament not found'));
      return Right(t);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatus(
      String id, String status) async {
    try {
      await remote.updateTournamentStatus(id, status);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<TeamEntity>>> saveTeams(
      List<TeamEntity> teams) async {
    try {
      final maps =
      teams.map((t) => TeamModel.fromEntity(t).toMap()).toList();
      return Right(await remote.insertTeams(maps));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<TeamEntity>>> getTeams(
      String tournamentId) async {
    try {
      return Right(await remote.getTeams(tournamentId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> savePlayers(List<TeamEntity> teams) async {
    try {
      final players = <Map<String, dynamic>>[];
      for (final team in teams) {
        for (final p in team.players) {
          players.add(PlayerModel(
            id:           p.id,
            teamId:       p.teamId,
            tournamentId: p.tournamentId,
            name:         p.name,
            isSubstitute: p.isSubstitute,
            joinedMatch:  p.joinedMatch,
          ).toMap());
        }
      }
      if (players.isNotEmpty) await remote.upsertPlayers(players);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTournament(String id) async {
    try {
      await remote.deleteTournament(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}

// ── Match Repository ───────────────────────────────────────
class MatchRepositoryImpl implements MatchRepository {
  final SupabaseDataSource remote;
  MatchRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, void>> createMatches({
    required String tournamentId,
    required int total,
    required List<DateTime?> scheduledTimes,
  }) async {
    try {
      final maps = List.generate(
        total,
            (i) => {
          'tournament_id': tournamentId,
          'match_number':  i + 1,
          'scheduled_at':  scheduledTimes[i]?.toIso8601String(),
          'status':        'pending',
        },
      );
      await remote.insertMatches(maps);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addMatch({
    required String tournamentId,
    required int matchNumber,
  }) async {
    try {
      final map = {
        'tournament_id': tournamentId,
        'match_number':  matchNumber,
        'status':        'pending',
      };
      await remote.insertMatches([map]);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMatch(String matchId) async {
    try {
      await remote.deleteMatch(matchId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<MatchEntity>>> getMatches(
      String tournamentId) async {
    try {
      return Right(await remote.getMatches(tournamentId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateMatchStatus(
      String matchId, String status) async {
    try {
      await remote.updateMatchStatus(matchId, status);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveMatchResult({
    required String matchId,
    required String tournamentId,
    required String teamId,
    required int slotNumber,
    required int rankPosition,
    required int kills,
  }) async {
    try {
      await remote.saveMatchResult({
        'p_match_id':      matchId,
        'p_tournament_id': tournamentId,
        'p_team_id':       teamId,
        'p_slot_number':   slotNumber,
        'p_rank_position': rankPosition,
        'p_kills':         kills,
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> savePlayerKills({
    required String matchId,
    required String tournamentId,
    required String teamId,
    required String playerId,
    required String playerName,
    required int kills,
  }) async {
    try {
      await remote.savePlayerKills({
        'match_id':      matchId,
        'tournament_id': tournamentId,
        'team_id':       teamId,
        'player_id':     playerId,
        'player_name':   playerName,
        'kills':         kills,
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}

// ── Leaderboard Repository ─────────────────────────────────
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final SupabaseDataSource remote;
  LeaderboardRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard(
      String tournamentId) async {
    try {
      return Right(await remote.getLeaderboard(tournamentId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<MvpEntity>>> getMvp(
      String tournamentId) async {
    try {
      return Right(await remote.getMvp(tournamentId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getMatchBreakdown(
      String tournamentId) async {
    try {
      return Right(await remote.getMatchBreakdown(tournamentId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<LeaderboardEntry>> leaderboardStream(String tournamentId) =>
      remote.leaderboardStream(tournamentId);
}