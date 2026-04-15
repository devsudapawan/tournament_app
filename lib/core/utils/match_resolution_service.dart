import 'package:string_similarity/string_similarity.dart';
import '../../data/models/ocr_result_model.dart';
import '../../domain/entities/team_entity.dart';

class ResolvedTeamResult {
  final String teamId;
  final String teamName;
  final int slotNumber;
  final int rankPosition;
  final int totalKills;
  final int rankPoints;
  final int killPoints;
  final int totalPoints;
  final List<OcrPlayerKill> playerKills;

  ResolvedTeamResult({
    required this.teamId,
    required this.teamName,
    required this.slotNumber,
    required this.rankPosition,
    required this.totalKills,
    required this.rankPoints,
    required this.killPoints,
    required this.totalPoints,
    required this.playerKills,
  });
}

class MatchResolutionService {
  static const _fuzzyThreshold = 0.75;

  static int _getRankPoints(int rank) {
    switch (rank) {
      case 1:
        return 15;
      case 2:
        return 12;
      case 3:
        return 10;
      case 4:
        return 8;
      case 5:
        return 6;
      case 6:
        return 4;
      case 7:
        return 3;
      case 8:
        return 2;
      case 9:
      case 10:
        return 1;
      default:
        return 0;
    }
  }

  static List<ResolvedTeamResult> resolveMatchResults({
    required List<OcrResultEntry> resultEntries,
    required List<TeamEntity> teams,
  }) {
    // We already have teams with players loaded from Lobby data 
    // into the database (saving Lobby updates TeamEntity's players).
    // Now we map player names directly to their team/slot.
    
    final playerToTeam = <String, TeamEntity>{};
    for (final team in teams) {
      for (final player in team.players) {
        playerToTeam[player.name.toLowerCase()] = team;
      }
    }

    final resolved = <ResolvedTeamResult>[];

    for (final entry in resultEntries) {
      TeamEntity? matchedTeam;
      
      // Try to find the first player that matches a team
      for (final player in entry.players) {
        matchedTeam = _fuzzyMatchTeam(player.playerName, playerToTeam);
        if (matchedTeam != null) break;
      }

      int kills = entry.totalKills;
      int rankPts = _getRankPoints(entry.rankPosition);
      int killPts = kills; // 1 point per kill

      if (matchedTeam != null) {
        entry.matchedTeamId = matchedTeam.id;
        entry.matchedTeamName = matchedTeam.teamName;
        entry.matchConfidence = 0.95;
        
        resolved.add(ResolvedTeamResult(
          teamId: matchedTeam.id,
          teamName: matchedTeam.teamName,
          slotNumber: matchedTeam.slotNumber,
          rankPosition: entry.rankPosition,
          totalKills: kills,
          rankPoints: rankPts,
          killPoints: killPts,
          totalPoints: rankPts + killPts,
          playerKills: entry.players,
        ));
      } else {
        // Unmatched team - handle gracefully in UI
        resolved.add(ResolvedTeamResult(
          teamId: '',
          teamName: 'UNKNOWN TEAM',
          slotNumber: 0,
          rankPosition: entry.rankPosition,
          totalKills: kills,
          rankPoints: rankPts,
          killPoints: killPts,
          totalPoints: rankPts + killPts,
          playerKills: entry.players,
        ));
      }
    }

    return resolved;
  }

  static TeamEntity? _fuzzyMatchTeam(String playerName, Map<String, TeamEntity> playerToTeam) {
    final lowerName = playerName.toLowerCase();
    
    // Direct match
    if (playerToTeam.containsKey(lowerName)) {
      return playerToTeam[lowerName];
    }

    // Fuzzy match
    double bestMatch = 0.0;
    TeamEntity? bestTeam;

    for (final entry in playerToTeam.entries) {
      final similarity = StringSimilarity.compareTwoStrings(lowerName, entry.key);
      if (similarity > bestMatch && similarity >= _fuzzyThreshold) {
        bestMatch = similarity;
        bestTeam = entry.value;
      }
    }

    return bestTeam;
  }
}
