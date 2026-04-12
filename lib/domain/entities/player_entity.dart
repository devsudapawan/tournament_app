class PlayerEntity {
  final String id;
  final String teamId;
  final String tournamentId;
  final String name;
  final bool isSubstitute;
  final int? joinedMatch;

  const PlayerEntity({
    required this.id,
    required this.teamId,
    required this.tournamentId,
    required this.name,
    this.isSubstitute = false,
    this.joinedMatch,
  });
}
