import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/team_entity.dart';
import '../../domain/entities/player_entity.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/entities/leaderboard_entity.dart';

// ── Tournament Model ───────────────────────────────────────
class TournamentModel extends TournamentEntity {
  const TournamentModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.organizerTag,
    required super.gameType,
    required super.totalMatches,
    required super.status,
    required super.rankPoints,
    required super.killPoints,
    required super.createdAt,
  });

  factory TournamentModel.fromMap(Map<String, dynamic> m) {
    final rp = Map<String, dynamic>.from(m['rank_points'] as Map? ?? {});
    return TournamentModel(
      id:           m['id'],
      userId:       m['user_id'],
      name:         m['name'],
      organizerTag: m['organizer_tag'] ?? '',
      gameType:     m['game_type'] ?? 'bgmi',
      totalMatches: m['total_matches'] ?? 6,
      status:       m['status'] ?? 'setup',
      rankPoints:   rp.map((k, v) => MapEntry(int.parse(k), (v as num).toInt())),
      killPoints:   m['kill_points'] ?? 1,
      createdAt:    DateTime.parse(m['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id':       userId,
    'name':          name,
    'organizer_tag': organizerTag,
    'game_type':     gameType,
    'total_matches': totalMatches,
    'status':        status,
    'rank_points':   rankPoints.map((k, v) => MapEntry(k.toString(), v)),
    'kill_points':   killPoints,
  };

  factory TournamentModel.fromEntity(TournamentEntity e) => TournamentModel(
    id:           e.id,
    userId:       e.userId,
    name:         e.name,
    organizerTag: e.organizerTag,
    gameType:     e.gameType,
    totalMatches: e.totalMatches,
    status:       e.status,
    rankPoints:   e.rankPoints,
    killPoints:   e.killPoints,
    createdAt:    e.createdAt,
  );
}

// ── Team Model ─────────────────────────────────────────────
class TeamModel extends TeamEntity {
  const TeamModel({
    required super.id,
    required super.tournamentId,
    required super.slotNumber,
    required super.teamName,
    super.isActive,
    super.players,
  });

  factory TeamModel.fromMap(Map<String, dynamic> m) => TeamModel(
    id:           m['id'],
    tournamentId: m['tournament_id'],
    slotNumber:   m['slot_number'],
    teamName:     m['team_name'],
    isActive:     m['is_active'] ?? true,
    players: m['players'] != null
        ? (m['players'] as List)
            .map((p) => PlayerModel.fromMap(p))
            .toList()
        : [],
  );

  Map<String, dynamic> toMap() => {
    'tournament_id': tournamentId,
    'slot_number':   slotNumber,
    'team_name':     teamName,
    'is_active':     isActive,
  };

  factory TeamModel.fromEntity(TeamEntity e) => TeamModel(
    id:           e.id,
    tournamentId: e.tournamentId,
    slotNumber:   e.slotNumber,
    teamName:     e.teamName,
    isActive:     e.isActive,
    players:      e.players,
  );
}

// ── Player Model ───────────────────────────────────────────
class PlayerModel extends PlayerEntity {
  const PlayerModel({
    required super.id,
    required super.teamId,
    required super.tournamentId,
    required super.name,
    super.isSubstitute,
    super.joinedMatch,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> m) => PlayerModel(
    id:           m['id'],
    teamId:       m['team_id'],
    tournamentId: m['tournament_id'],
    name:         m['name'],
    isSubstitute: m['is_substitute'] ?? false,
    joinedMatch:  m['joined_match'],
  );

  Map<String, dynamic> toMap() => {
    'team_id':       teamId,
    'tournament_id': tournamentId,
    'name':          name,
    'is_substitute': isSubstitute,
    'joined_match':  joinedMatch,
  };
}

// ── Match Model ────────────────────────────────────────────
class MatchModel extends MatchEntity {
  const MatchModel({
    required super.id,
    required super.tournamentId,
    required super.matchNumber,
    super.scheduledAt,
    required super.status,
  });

  factory MatchModel.fromMap(Map<String, dynamic> m) => MatchModel(
    id:           m['id'],
    tournamentId: m['tournament_id'],
    matchNumber:  m['match_number'],
    scheduledAt:  m['scheduled_at'] != null
                    ? DateTime.parse(m['scheduled_at'])
                    : null,
    status:       m['status'] ?? 'pending',
  );

  Map<String, dynamic> toMap() => {
    'tournament_id': tournamentId,
    'match_number':  matchNumber,
    'scheduled_at':  scheduledAt?.toIso8601String(),
    'status':        status,
  };
}

// ── Leaderboard Model ──────────────────────────────────────
class LeaderboardModel extends LeaderboardEntry {
  const LeaderboardModel({
    required super.teamId,
    required super.teamName,
    required super.slotNumber,
    required super.matchesPlayed,
    required super.totalRankPoints,
    required super.totalKillPoints,
    required super.grandTotal,
    required super.position,
    super.matchBreakdown,
  });

  factory LeaderboardModel.fromMap(Map<String, dynamic> m) => LeaderboardModel(
    teamId:           m['team_id'],
    teamName:         m['team_name'],
    slotNumber:       m['slot_number'],
    matchesPlayed:    (m['matches_played'] as num).toInt(),
    totalRankPoints:  (m['total_rank_points'] as num).toInt(),
    totalKillPoints:  (m['total_kill_points'] as num).toInt(),
    grandTotal:       (m['grand_total'] as num).toInt(),
    position:         (m['position'] as num).toInt(),
  );
}

// ── MVP Model ──────────────────────────────────────────────
class MvpModel extends MvpEntity {
  const MvpModel({
    required super.playerId,
    required super.playerName,
    required super.teamId,
    required super.teamName,
    required super.slotNumber,
    required super.totalKills,
    required super.mvpRank,
  });

  factory MvpModel.fromMap(Map<String, dynamic> m) => MvpModel(
    playerId:   m['player_id'],
    playerName: m['player_name'],
    teamId:     m['team_id'],
    teamName:   m['team_name'],
    slotNumber: m['slot_number'],
    totalKills: (m['total_kills'] as num).toInt(),
    mvpRank:    (m['mvp_rank'] as num).toInt(),
  );
}
