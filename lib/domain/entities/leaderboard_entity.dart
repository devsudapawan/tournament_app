class LeaderboardEntry {
  final String teamId;
  final String teamName;
  final int slotNumber;
  final int matchesPlayed;
  final int totalRankPoints;
  final int totalKillPoints;
  final int grandTotal;
  final int position;
  final Map<int, int> matchBreakdown; // matchNumber → totalPoints

  const LeaderboardEntry({
    required this.teamId,
    required this.teamName,
    required this.slotNumber,
    required this.matchesPlayed,
    required this.totalRankPoints,
    required this.totalKillPoints,
    required this.grandTotal,
    required this.position,
    this.matchBreakdown = const {},
  });
}

class MvpEntity {
  final String playerId;
  final String playerName;
  final String teamId;
  final String teamName;
  final int slotNumber;
  final int totalKills;
  final int mvpRank;

  const MvpEntity({
    required this.playerId,
    required this.playerName,
    required this.teamId,
    required this.teamName,
    required this.slotNumber,
    required this.totalKills,
    required this.mvpRank,
  });
}
