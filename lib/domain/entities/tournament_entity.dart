// ── tournament_entity.dart ────────────────────────────────
class TournamentEntity {
  final String id;
  final String userId;
  final String name;
  final String organizerTag;
  final String gameType;
  final int totalMatches;
  final String status;
  final Map<int, int> rankPoints;
  final int killPoints;
  final DateTime createdAt;

  const TournamentEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.organizerTag,
    required this.gameType,
    required this.totalMatches,
    required this.status,
    required this.rankPoints,
    required this.killPoints,
    required this.createdAt,
  });

  bool get isSetup     => status == 'setup';
  bool get isActive    => status == 'active';
  bool get isCompleted => status == 'completed';
}
