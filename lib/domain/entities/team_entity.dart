import 'player_entity.dart';

class TeamEntity {
  final String id;
  final String tournamentId;
  final int slotNumber;
  final String teamName;
  final bool isActive;
  final List<PlayerEntity> players;

  const TeamEntity({
    required this.id,
    required this.tournamentId,
    required this.slotNumber,
    required this.teamName,
    this.isActive = true,
    this.players  = const [],
  });

  TeamEntity copyWith({List<PlayerEntity>? players, bool? isActive}) =>
      TeamEntity(
        id:           id,
        tournamentId: tournamentId,
        slotNumber:   slotNumber,
        teamName:     teamName,
        isActive:     isActive ?? this.isActive,
        players:      players  ?? this.players,
      );
}
