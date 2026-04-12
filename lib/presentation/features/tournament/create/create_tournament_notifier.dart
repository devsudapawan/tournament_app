// // lib/presentation/features/tournament/create/create_tournament_notifier.dart
// //
// // Controls the full 5-step tournament creation flow state.
//
// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:uuid/uuid.dart';
// import '../../../../core/constants/app_constants.dart';
// import '../../../../data/models/ocr_result_model.dart';
// import '../../../../domain/entities/team_entity.dart';
// import '../../../../domain/entities/tournament_entity.dart';
// import '../../../common/providers/providers.dart';
//
// class CreateTournamentState {
//   final int currentStep;
//   final bool isLoading;
//   final String? errorMessage;
//   final String? createdTournamentId;
//
//   // Step 1
//   final String name;
//   final String organizerTag;
//   final String gameType;
//   final int matchCount;
//
//   // Step 2
//   final Map<int, int> rankPoints;
//   final int killPoints;
//
//   // Step 3
//   final List<DateTime?> scheduledTimes;
//
//   // Step 4
//   final List<File> teamImages;
//   final List<OcrTeamEntry> ocrTeams;
//   final bool isOcrRunning;
//
//   const CreateTournamentState({
//     this.currentStep        = 1,
//     this.isLoading          = false,
//     this.errorMessage,
//     this.createdTournamentId,
//     this.name               = '',
//     this.organizerTag       = '',
//     this.gameType           = 'bgmi',
//     this.matchCount         = 6,
//     this.rankPoints         = const {
//       1: 10, 2: 8, 3: 6, 4: 4, 5: 3, 6: 2, 7: 1, 8: 1,
//     },
//     this.killPoints         = 1,
//     this.scheduledTimes     = const [],
//     this.teamImages         = const [],
//     this.ocrTeams           = const [],
//     this.isOcrRunning       = false,
//   });
//
//   CreateTournamentState copyWith({
//     int?                 currentStep,
//     bool?                isLoading,
//     String?              errorMessage,
//     String?              createdTournamentId,
//     String?              name,
//     String?              organizerTag,
//     String?              gameType,
//     int?                 matchCount,
//     Map<int, int>?       rankPoints,
//     int?                 killPoints,
//     List<DateTime?>?     scheduledTimes,
//     List<File>?          teamImages,
//     List<OcrTeamEntry>?  ocrTeams,
//     bool?                isOcrRunning,
//   }) =>
//       CreateTournamentState(
//         currentStep:          currentStep          ?? this.currentStep,
//         isLoading:            isLoading            ?? this.isLoading,
//         errorMessage:         errorMessage,
//         createdTournamentId:  createdTournamentId  ?? this.createdTournamentId,
//         name:                 name                 ?? this.name,
//         organizerTag:         organizerTag         ?? this.organizerTag,
//         gameType:             gameType             ?? this.gameType,
//         matchCount:           matchCount           ?? this.matchCount,
//         rankPoints:           rankPoints           ?? this.rankPoints,
//         killPoints:           killPoints           ?? this.killPoints,
//         scheduledTimes:       scheduledTimes       ?? this.scheduledTimes,
//         teamImages:           teamImages           ?? this.teamImages,
//         ocrTeams:             ocrTeams             ?? this.ocrTeams,
//         isOcrRunning:         isOcrRunning         ?? this.isOcrRunning,
//       );
// }
//
// class CreateTournamentNotifier
//     extends StateNotifier<CreateTournamentState> {
//   final Ref _ref;
//
//   CreateTournamentNotifier(this._ref)
//       : super(CreateTournamentState(
//           scheduledTimes: List.filled(8, null),
//         ));
//
//   // ── Navigation ──────────────────────────────────────────
//   void nextStep() {
//     if (state.currentStep < 5) {
//       state = state.copyWith(currentStep: state.currentStep + 1);
//     }
//   }
//
//   void prevStep() {
//     if (state.currentStep > 1) {
//       state = state.copyWith(currentStep: state.currentStep - 1);
//     }
//   }
//
//   void goToStep(int step) => state = state.copyWith(currentStep: step);
//
//   // ── Step 1 fields ───────────────────────────────────────
//   void setName(String v)         => state = state.copyWith(name: v);
//   void setOrganizerTag(String v) => state = state.copyWith(organizerTag: v);
//   void setGameType(String v)     => state = state.copyWith(gameType: v);
//
//   void setMatchCount(int delta) {
//     final next = (state.matchCount + delta)
//         .clamp(AppConstants.minMatches, AppConstants.maxMatches);
//     state = state.copyWith(matchCount: next);
//   }
//
//   // ── Step 2 fields ───────────────────────────────────────
//   void setRankPoint(int position, int points) {
//     final updated = Map<int, int>.from(state.rankPoints);
//     updated[position] = points;
//     state = state.copyWith(rankPoints: updated);
//   }
//
//   // ── Step 3 fields ───────────────────────────────────────
//   void setScheduledTime(int index, DateTime dt) {
//     final updated = List<DateTime?>.from(state.scheduledTimes);
//     updated[index] = dt;
//     state = state.copyWith(scheduledTimes: updated);
//   }
//
//   // ── Step 4 — OCR ────────────────────────────────────────
//   Future<void> addTeamImage(File file) async {
//     if (state.teamImages.length >= 2) return;
//     final updated = [...state.teamImages, file];
//     state = state.copyWith(teamImages: updated, isOcrRunning: true);
//
//     final ocr     = _ref.read(ocrServiceProvider);
//     final entries = await ocr.readTeamListImages(updated);
//     state = state.copyWith(ocrTeams: entries, isOcrRunning: false);
//   }
//
//   void removeTeamImage(int index) {
//     final updated = [...state.teamImages]..removeAt(index);
//     state = state.copyWith(teamImages: updated);
//   }
//
//   void updateOcrTeamName(int index, String name) {
//     final updated = [...state.ocrTeams];
//     updated[index] = OcrTeamEntry(
//       slotNumber:  updated[index].slotNumber,
//       teamName:    name.toUpperCase(),
//       confidence:  updated[index].confidence,
//       isEdited:    true,
//     );
//     state = state.copyWith(ocrTeams: updated);
//   }
//
//   // ── Step 5 — Launch ─────────────────────────────────────
//   Future<void> launch() async {
//     state = state.copyWith(isLoading: true, errorMessage: null);
//
//     // 1. Create tournament
//     final tournamentResult = await _ref
//         .read(createTournamentUseCaseProvider)
//         .call(TournamentEntity(
//           id:           const Uuid().v4(),
//           userId:       '',
//           name:         state.name.trim(),
//           organizerTag: state.organizerTag.trim(),
//           gameType:     state.gameType,
//           totalMatches: state.matchCount,
//           status:       'setup',
//           rankPoints:   state.rankPoints,
//           killPoints:   state.killPoints,
//           createdAt:    DateTime.now(),
//         ));
//
//     await tournamentResult.fold(
//       (f) async => state = state.copyWith(
//         isLoading: false, errorMessage: f.message),
//       (tournament) async {
//         // 2. Save teams
//         final teams = state.ocrTeams
//             .map((t) => TeamEntity(
//                   id:           const Uuid().v4(),
//                   tournamentId: tournament.id,
//                   slotNumber:   t.slotNumber,
//                   teamName:     t.teamName,
//                 ))
//             .toList();
//         await _ref.read(saveTeamsUseCaseProvider).call(teams);
//
//         // 3. Create match schedule
//         await _ref.read(createMatchesUseCaseProvider).call(
//           tournamentId:   tournament.id,
//           total:          state.matchCount,
//           scheduledTimes: state.scheduledTimes.sublist(0, state.matchCount),
//         );
//
//         state = state.copyWith(
//           isLoading:           false,
//           createdTournamentId: tournament.id,
//         );
//       },
//     );
//   }
//
//   void reset() => state = CreateTournamentState(
//         scheduledTimes: List.filled(8, null),
//       );
// }
//
// final createTournamentNotifierProvider = StateNotifierProvider.autoDispose<
//     CreateTournamentNotifier, CreateTournamentState>(
//   (ref) => CreateTournamentNotifier(ref),
// );


// lib/presentation/features/tournament/create/create_tournament_notifier.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/ocr_result_model.dart';
import '../../../../domain/entities/team_entity.dart';
import '../../../../domain/entities/tournament_entity.dart';
import '../../../common/providers/providers.dart';

class CreateTournamentState {
  final int     currentStep;
  final bool    isLoading;
  final bool    isOcrRunning;
  final String? errorMessage;
  final String? createdTournamentId;

  // Step 1
  final String name;
  final String organizerTag;
  final String gameType;
  final int    matchCount;

  // Step 2
  final Map<int, int> rankPoints;
  final int           killPoints;

  // Step 3
  final List<DateTime?> scheduledTimes;

  // Step 4
  final List<File>         teamImages;
  final List<OcrTeamEntry> ocrTeams;

  const CreateTournamentState({
    this.currentStep        = 1,
    this.isLoading          = false,
    this.isOcrRunning       = false,
    this.errorMessage,
    this.createdTournamentId,
    this.name               = '',
    this.organizerTag       = '',
    this.gameType           = 'bgmi',
    this.matchCount         = 6,
    this.rankPoints         = const {
      1: 10, 2: 8, 3: 6, 4: 4, 5: 3, 6: 2, 7: 1, 8: 1,
    },
    this.killPoints         = 1,
    this.scheduledTimes     = const [],
    this.teamImages         = const [],
    this.ocrTeams           = const [],
  });

  CreateTournamentState copyWith({
    int?                currentStep,
    bool?               isLoading,
    bool?               isOcrRunning,
    String?             errorMessage,
    String?             createdTournamentId,
    String?             name,
    String?             organizerTag,
    String?             gameType,
    int?                matchCount,
    Map<int, int>?      rankPoints,
    int?                killPoints,
    List<DateTime?>?    scheduledTimes,
    List<File>?         teamImages,
    List<OcrTeamEntry>? ocrTeams,
  }) =>
      CreateTournamentState(
        currentStep:         currentStep         ?? this.currentStep,
        isLoading:           isLoading           ?? this.isLoading,
        isOcrRunning:        isOcrRunning        ?? this.isOcrRunning,
        errorMessage:        errorMessage,
        createdTournamentId: createdTournamentId ?? this.createdTournamentId,
        name:                name                ?? this.name,
        organizerTag:        organizerTag        ?? this.organizerTag,
        gameType:            gameType            ?? this.gameType,
        matchCount:          matchCount          ?? this.matchCount,
        rankPoints:          rankPoints          ?? this.rankPoints,
        killPoints:          killPoints          ?? this.killPoints,
        scheduledTimes:      scheduledTimes      ?? this.scheduledTimes,
        teamImages:          teamImages          ?? this.teamImages,
        ocrTeams:            ocrTeams            ?? this.ocrTeams,
      );
}

class CreateTournamentNotifier
    extends StateNotifier<CreateTournamentState> {
  final Ref _ref;

  CreateTournamentNotifier(this._ref)
      : super(CreateTournamentState(
    scheduledTimes: List.filled(8, null),
  ));

  // ── Navigation ──────────────────────────────────────────
  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) => state = state.copyWith(currentStep: step);

  // ── Step 1 ───────────────────────────────────────────────
  void setName(String v)         => state = state.copyWith(name: v);
  void setOrganizerTag(String v) => state = state.copyWith(organizerTag: v);
  void setGameType(String v)     => state = state.copyWith(gameType: v);

  void changeMatchCount(int delta) {
    final next = (state.matchCount + delta)
        .clamp(AppConstants.minMatches, AppConstants.maxMatches);
    state = state.copyWith(matchCount: next);
  }

  // ── Step 2 ───────────────────────────────────────────────
  void setRankPoint(int position, int points) {
    final updated = Map<int, int>.from(state.rankPoints);
    updated[position] = points;
    state = state.copyWith(rankPoints: updated);
  }

  // ── Step 3 ───────────────────────────────────────────────
  void setScheduledTime(int index, DateTime dt) {
    final updated = List<DateTime?>.from(state.scheduledTimes);
    updated[index] = dt;
    state = state.copyWith(scheduledTimes: updated);
  }

  // ── Step 4 — Gemini OCR ──────────────────────────────────
  Future<void> addTeamImages(List<File> files) async {
    final current   = state.teamImages;
    final remaining = 2 - current.length;
    if (remaining <= 0) return;

    final toAdd  = files.take(remaining).toList();
    final updated = [...current, ...toAdd];

    state = state.copyWith(teamImages: updated, isOcrRunning: true);

    try {
      // Use GeminiService — handles ALL image formats
      final gemini  = _ref.read(geminiServiceProvider);
      final entries = await gemini.extractTeamList(updated);
      state = state.copyWith(ocrTeams: entries, isOcrRunning: false);
    } catch (e) {
      state = state.copyWith(isOcrRunning: false);
    }
  }

  void removeTeamImage(int index) {
    final updated = [...state.teamImages]..removeAt(index);
    // Re-run OCR on remaining images
    state = state.copyWith(teamImages: updated, ocrTeams: []);
    if (updated.isNotEmpty) addTeamImages([]);
  }

  void updateOcrTeamName(int index, String name) {
    final updated = [...state.ocrTeams];
    updated[index] = OcrTeamEntry(
      slotNumber: updated[index].slotNumber,
      teamName:   name.toUpperCase(),
      confidence: updated[index].confidence,
      isEdited:   true,
    );
    state = state.copyWith(ocrTeams: updated);
  }

  // ── Step 5 — Launch ─────────────────────────────────────
  Future<void> launch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final tResult = await _ref
        .read(createTournamentUseCaseProvider)
        .call(TournamentEntity(
      id:           const Uuid().v4(),
      userId:       '',
      name:         state.name.trim(),
      organizerTag: state.organizerTag.trim(),
      gameType:     state.gameType,
      totalMatches: state.matchCount,
      status:       'setup',
      rankPoints:   state.rankPoints,
      killPoints:   state.killPoints,
      createdAt:    DateTime.now(),
    ));

    await tResult.fold(
          (f) async => state = state.copyWith(
          isLoading: false, errorMessage: f.message),
          (tournament) async {
        // Save teams if OCR found any
        if (state.ocrTeams.isNotEmpty) {
          final teams = state.ocrTeams
              .map((t) => TeamEntity(
            id:           const Uuid().v4(),
            tournamentId: tournament.id,
            slotNumber:   t.slotNumber,
            teamName:     t.teamName,
          ))
              .toList();
          await _ref.read(saveTeamsUseCaseProvider).call(teams);
        }

        // Create match schedule
        await _ref.read(createMatchesUseCaseProvider).call(
          tournamentId:   tournament.id,
          total:          state.matchCount,
          scheduledTimes: state.scheduledTimes.sublist(0, state.matchCount),
        );

        state = state.copyWith(
          isLoading:           false,
          createdTournamentId: tournament.id,
        );
      },
    );
  }

  void reset() => state = CreateTournamentState(
      scheduledTimes: List.filled(8, null));
}

final createTournamentNotifierProvider = StateNotifierProvider.autoDispose<
    CreateTournamentNotifier, CreateTournamentState>(
      (ref) => CreateTournamentNotifier(ref),
);