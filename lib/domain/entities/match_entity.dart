class MatchEntity {
  final String id;
  final String tournamentId;
  final int matchNumber;
  final DateTime? scheduledAt;
  final String status;

  const MatchEntity({
    required this.id,
    required this.tournamentId,
    required this.matchNumber,
    this.scheduledAt,
    required this.status,
  });

  bool get isPending       => status == 'pending';
  bool get isLobbyUploaded => status == 'lobby_uploaded';
  bool get isResultUploaded=> status == 'result_uploaded';
  bool get isCompleted     => status == 'completed';
}
