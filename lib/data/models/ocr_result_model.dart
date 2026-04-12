// OCR intermediate models — hold raw OCR output before user confirms

// From team list image (Image 1)
class OcrTeamEntry {
  int slotNumber;
  String teamName;
  double confidence;
  bool isEdited;

  OcrTeamEntry({
    required this.slotNumber,
    required this.teamName,
    required this.confidence,
    this.isEdited = false,
  });

  bool get needsReview => confidence < 0.85 || isEdited;
}

// From lobby image (Image 2) — slot + player names
class OcrLobbyEntry {
  int slotNumber;
  List<String> playerNames;
  double confidence;

  OcrLobbyEntry({
    required this.slotNumber,
    required this.playerNames,
    required this.confidence,
  });
}

// From result image (Image 3) — rank + players + kills
class OcrResultEntry {
  int rankPosition;
  List<OcrPlayerKill> players;
  String? matchedTeamId;
  String? matchedTeamName;
  double matchConfidence;
  bool isManuallyAssigned;

  OcrResultEntry({
    required this.rankPosition,
    required this.players,
    this.matchedTeamId,
    this.matchedTeamName,
    this.matchConfidence = 0.0,
    this.isManuallyAssigned = false,
  });

  int get totalKills => players.fold(0, (sum, p) => sum + p.kills);
  bool get isMatched => matchedTeamId != null;
  bool get needsReview => !isMatched || matchConfidence < 0.85;
}

class OcrPlayerKill {
  String playerName;
  int kills;
  String? matchedPlayerId;

  OcrPlayerKill({
    required this.playerName,
    required this.kills,
    this.matchedPlayerId,
  });
}
