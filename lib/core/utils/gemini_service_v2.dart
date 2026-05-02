// // lib/core/utils/gemini_service.dart
// // v2 — Handles ALL slot list image formats, not just PointCalc style
//
// import 'dart:convert';
// import 'dart:io';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:string_similarity/string_similarity.dart';
// import '../constants/app_constants.dart';
// import '../../data/models/ocr_result_model.dart';
// import '../../domain/entities/team_entity.dart';
//
// class GeminiService {
//   static const _systemInstruction = '''
// You are an Esports Data Extraction specialist for BGMI and PUBG Mobile.
// Your ONLY job is to extract data from game screenshots and return valid JSON.
//
// Rules:
// 1. Return ONLY a valid JSON array. No markdown, no explanation, no backticks, no code fences.
// 2. Extract team/player names EXACTLY as shown — preserve special characters, clan tags, numbers.
// 3. Slot numbers can appear as "03", "#3", "3", "| 3" — always return the integer value.
// 4. In result screens, the team with the Gold Crown icon OR shown largest on left = Rank 1.
// 5. If a slot is locked (lock emoji) or has no team name, skip it entirely.
// 6. Kill counts labeled "finishes", "finish", "eliminations", "/N" all mean kills.
// 7. Team logos/icons next to team names should be ignored — extract text only.
// 8. Never guess. If you cannot read something, use "UNKNOWN".
// ''';
//
//   GenerativeModel _model(String name) => GenerativeModel(
//         model: name,a
//         apiKey: AppConstants.geminiApiKey,
//         systemInstruction: Content.system(_systemInstruction),
//         generationConfig: GenerationConfig(
//           temperature: 0.0,
//           responseMimeType: 'application/json',
//         ),
//       );
//
//   // ── 1. Team List — handles ALL visual formats ──────────────
//   // Works with: PointCalc black/yellow cards, Joy Bangla green cards,
//   // any other promotional slot list image
//   Future<List<OcrTeamEntry>> extractTeamList(
//     List<File> images, {
//     void Function(int current, int total, String status)? onProgress,
//   }) async {
//     final all = <OcrTeamEntry>[];
//     final seenSlots = <int>{};
//
//     for (int i = 0; i < images.length; i++) {
//       onProgress?.call(i + 1, images.length,
//           'Reading team list ${i + 1} of ${images.length}...');
//
//       // Prompt designed to handle ANY slot list format
//       const prompt = '''
// This image shows a BGMI/PUBG tournament slot list.
// It may be a promotional card, a screenshot, or any other format.
// Each row or entry shows a slot number and a team name.
//
// Extract every slot number and team name you can see.
// Ignore team logos, images, or icons — only extract the text.
// Slot numbers may look like: 03, 3, #3, #03, | 3
//
// Return a JSON array ONLY:
// [
//   {"slot": 3, "team_name": "5 BROTHERS ESPORTS"},
//   {"slot": 4, "team_name": "INX ESPORTS"},
//   {"slot": 13, "team_name": "KARUNADU ESPORTS"}
// ]
//
// Skip any slot that is locked, empty, or has no team name.
// ''';
//
//       final raw = await _callWithFallback(images[i], prompt);
//       if (raw == null) continue;
//
//       try {
//         final list = jsonDecode(raw) as List;
//         for (final item in list) {
//           final slot = _toInt(item['slot']);
//           final name = (item['team_name'] as String?)?.trim();
//           if (slot == null || slot < 1 || slot > 30) continue;
//           if (name == null || name.isEmpty || name == 'UNKNOWN') continue;
//           if (seenSlots.contains(slot)) continue;
//           seenSlots.add(slot);
//           all.add(OcrTeamEntry(
//             slotNumber: slot,
//             teamName: name.toUpperCase(),
//             confidence: 0.95,
//           ));
//         }
//       } catch (_) {}
//     }
//
//     onProgress?.call(images.length, images.length, 'Complete');
//     all.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
//     return all;
//   }
//
//   // ── 2. Lobby Images ────────────────────────────────────────
//   Future<List<OcrLobbyEntry>> extractLobby(
//     List<File> images, {
//     void Function(int current, int total, String status)? onProgress,
//   }) async {
//     final all = <OcrLobbyEntry>[];
//     final seenSlots = <int>{};
//
//     for (int i = 0; i < images.length; i++) {
//       onProgress?.call(i + 1, images.length,
//           'Reading lobby image ${i + 1} of ${images.length}...');
//
//       const prompt = '''
// This is a BGMI/PUBG in-game lobby screenshot.
// Each numbered colored box = one team slot.
// Inside each box: a slot number (like 03, 12) and player names.
// Some players show kill count as "/0 Eliminations" or "/1 Eliminations".
//
// Extract every slot and all its players:
// [
//   {
//     "slot": 3,
//     "players": [
//       {"name": "GODxJonathan", "kills": 0},
//       {"name": "GODxZgod", "kills": 2}
//     ]
//   }
// ]
//
// List ALL players visible in each slot box.
// kills = number shown after "/" (use 0 if not visible).
// ''';
//
//       final raw = await _callWithFallback(images[i], prompt);
//       if (raw == null) continue;
//
//       try {
//         final list = jsonDecode(raw) as List;
//         for (final item in list) {
//           final slot = _toInt(item['slot']);
//           if (slot == null || slot < 1 || slot > 30) continue;
//           if (seenSlots.contains(slot)) continue;
//
//           final ps = (item['players'] as List? ?? [])
//               .map((p) => (p['name'] as String? ?? '').trim())
//               .where((n) => n.isNotEmpty && n != 'UNKNOWN')
//               .toList();
//
//           if (ps.isEmpty) continue;
//           seenSlots.add(slot);
//           all.add(OcrLobbyEntry(
//             slotNumber: slot,
//             playerNames: ps,
//             confidence: 0.95,
//           ));
//         }
//       } catch (_) {}
//     }
//
//     onProgress?.call(images.length, images.length, 'Complete');
//     all.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
//     return all;
//   }
//
//   // ── 3. Result Images ───────────────────────────────────────
//   Future<List<OcrResultEntry>> extractResults(
//     List<File> images, {
//     void Function(int current, int total, String status)? onProgress,
//   }) async {
//     final all = <OcrResultEntry>[];
//     final seenRanks = <int>{};
//
//     for (int i = 0; i < images.length; i++) {
//       onProgress?.call(i + 1, images.length,
//           'Reading result image ${i + 1} of ${images.length}...');
//
//       const prompt = '''
// This is a BGMI/PUBG end-of-match results screenshot.
// Players are grouped by their finishing rank/position.
//
// IMPORTANT:
// - Team with Gold Crown icon OR shown large on left = Rank 1
// - "X finishes" or "X finish" = kills for that player
// - Each group of players = same rank/team
//
// Return every player with rank and kills:
// [
//   {"rank": 1, "player_name": "Cute Darinda", "kills": 4},
//   {"rank": 1, "player_name": "ZHsasukee", "kills": 8},
//   {"rank": 2, "player_name": "LHSxKYZA", "kills": 1}
// ]
//
// If kills not visible for a player, use 0.
// List EVERY player you can see.
// ''';
//
//       final raw = await _callWithFallback(images[i], prompt);
//       if (raw == null) continue;
//
//       try {
//         final list = jsonDecode(raw) as List;
//         final groups = <int, List<OcrPlayerKill>>{};
//
//         for (final item in list) {
//           final rank = _toInt(item['rank']);
//           final name = (item['player_name'] as String?)?.trim();
//           final kills = _toInt(item['kills']) ?? 0;
//           if (rank == null || rank < 1 || rank > 30) continue;
//           if (name == null || name.isEmpty || name == 'UNKNOWN') continue;
//           if (seenRanks.contains(rank)) continue;
//           groups
//               .putIfAbsent(rank, () => [])
//               .add(OcrPlayerKill(playerName: name, kills: kills));
//         }
//
//         for (final e in groups.entries) {
//           if (seenRanks.contains(e.key)) continue;
//           seenRanks.add(e.key);
//           all.add(OcrResultEntry(rankPosition: e.key, players: e.value));
//         }
//       } catch (_) {}
//     }
//
//     onProgress?.call(images.length, images.length, 'Complete');
//     all.sort((a, b) => a.rankPosition.compareTo(b.rankPosition));
//     return all;
//   }
//
//   // ── 4. Match results → Teams via fuzzy slot matching ───────
//   List<OcrResultEntry> matchResultsToTeams({
//     required List<OcrResultEntry> resultEntries,
//     required List<OcrLobbyEntry> lobbyEntries,
//     required List<TeamEntity> teams,
//   }) {
//     final playerToSlot = <String, int>{};
//     for (final lobby in lobbyEntries) {
//       for (final name in lobby.playerNames) {
//         playerToSlot[name.toLowerCase()] = lobby.slotNumber;
//       }
//     }
//     final slotToTeam = {for (final t in teams) t.slotNumber: t};
//
//     for (final entry in resultEntries) {
//       for (final player in entry.players) {
//         final slot = _fuzzySlot(player.playerName, playerToSlot);
//         if (slot != null && slotToTeam.containsKey(slot)) {
//           entry.matchedTeamId = slotToTeam[slot]!.id;
//           entry.matchedTeamName = slotToTeam[slot]!.teamName;
//           entry.matchConfidence = 0.95;
//           break;
//         }
//       }
//     }
//     return resultEntries;
//   }
//
//   // ── Internal helpers ───────────────────────────────────────
//   Future<String?> _callWithFallback(File image, String prompt) async {
//     final r = await _callModel(image, prompt, AppConstants.geminiFlashLite);
//     if (r != null && r.trim().isNotEmpty) return r;
//     return _callModel(image, prompt, AppConstants.geminiFlash);
//   }
//
//   Future<String?> _callModel(File image, String prompt, String model) async {
//     try {
//       final bytes = await image.readAsBytes();
//       final mime = image.path.toLowerCase().endsWith('.png')
//           ? 'image/png'
//           : 'image/jpeg';
//       final resp = await _model(model).generateContent([
//         Content.multi([DataPart(mime, bytes), TextPart(prompt)]),
//       ]);
//       final text = resp.text?.trim();
//       if (text == null || text.isEmpty) return null;
//       return _stripFences(text);
//     } on GenerativeAIException catch (e) {
//       if (e.message.contains('quota') || e.message.contains('rate')) {
//         throw GeminiQuotaException(e.message);
//       }
//       return null;
//     } catch (_) {
//       return null;
//     }
//   }
//
//   String _stripFences(String raw) {
//     var s = raw.replaceAll('```json', '').replaceAll('```', '').trim();
//     final start = s.indexOf(RegExp(r'[\[\{]'));
//     if (start > 0) s = s.substring(start);
//     return s;
//   }
//
//   int? _toInt(dynamic v) {
//     if (v == null) return null;
//     if (v is int) return v;
//     if (v is double) return v.toInt();
//     return int.tryParse(v.toString());
//   }
//
//   int? _fuzzySlot(String name, Map<String, int> map) {
//     final lower = name.toLowerCase();
//     if (map.containsKey(lower)) return map[lower];
//     double best = 0;
//     int? slot;
//     for (final e in map.entries) {
//       final s = StringSimilarity.compareTwoStrings(lower, e.key);
//       if (s > best && s >= AppConstants.fuzzyMatchThreshold) {
//         best = s;
//         slot = e.value;
//       }
//     }
//     return slot;
//   }
// }
//
// class GeminiQuotaException implements Exception {
//   final String message;
//   const GeminiQuotaException(this.message);
// }


// lib/core/utils/gemini_service.dart
//
// Image processing pipeline:
//   File → ML Kit OCR (free, on-device) → raw text
//        → Gemini text prompt (high quota, cheap)
//        → fallback: Gemini vision (uses image quota)
//
// Public interface is IDENTICAL to the previous version.
// Nothing outside this file needs to change.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:string_similarity/string_similarity.dart';
import '../constants/app_constants.dart';
import '../../data/models/ocr_result_model.dart';
import '../../data/datasources/local/mlkit_ocr_service.dart';
import '../../domain/entities/team_entity.dart';

class GeminiService {

  // ML Kit instance — reused across all calls, disposed with service
  final _ocr = MlKitOcrService();


  static const _systemInstruction = '''
You are an Esports Data Extraction specialist for BGMI and PUBG Mobile.
Your ONLY job is to extract data from game screenshots and return valid JSON.

Rules:
1. Return ONLY a valid JSON array. No markdown, no explanation, no backticks, no code fences.
2. Extract team/player names EXACTLY as shown — preserve special characters, clan tags, numbers.
3. Slot numbers can appear as "03", "#3", "3", "| 3" — always return the integer value.
4. In result screens, the team with the Gold Crown icon OR shown largest on left = Rank 1.
5. If a slot is locked (lock emoji) or has no team name, skip it entirely.
6. Kill counts labeled "finishes", "finish", "eliminations", "/N" all mean kills.
7. Team logos/icons next to team names should be ignored — extract text only.
8. Never guess. If you cannot read something, use "UNKNOWN".
''';

  // ── Gemini model — text only (no vision) ──────────────────
  // Used when ML Kit successfully extracts text.
  // Much higher rate limit than vision models.
  GenerativeModel _textModel(String name) => GenerativeModel(
    model:  name,
    apiKey: AppConstants.geminiApiKey,
    systemInstruction: Content.system(_systemInstruction),
    generationConfig: GenerationConfig(
      temperature:      0.0,
      responseMimeType: 'application/json',
    ),
  );

  // ── Gemini model — vision (image bytes) ───────────────────
  // Fallback only — used when ML Kit returns too little text.
  // Costs vision quota (limited on free tier).
  GenerativeModel _visionModel(String name) => GenerativeModel(
    model:  name,
    apiKey: AppConstants.geminiApiKey,
    systemInstruction: Content.system(_systemInstruction),
    generationConfig: GenerationConfig(
      temperature:      0.0,
      responseMimeType: 'application/json',
    ),
  );

  // ── 1. Team List ───────────────────────────────────────────
  // Called once during tournament creation.
  // Max 2 images. Extracts slot number + team name.
  Future<List<OcrTeamEntry>> extractTeamList(
      List<File> images, {
        void Function(int current, int total, String status)? onProgress,
      }) async {
    final all       = <OcrTeamEntry>[];
    final seenSlots = <int>{};

    for (int i = 0; i < images.length; i++) {
      onProgress?.call(
        i + 1,
        images.length,
        'Reading team list ${i + 1} of ${images.length}...',
      );

      const prompt = '''
This image shows a BGMI/PUBG tournament slot list.
It may be a promotional card, a screenshot, or any other format.
Each row or entry shows a slot number and a team name.

Extract every slot number and team name you can see.
Ignore team logos, images, or icons — only extract the text.
Slot numbers may look like: 03, 3, #3, #03, | 3

Return a JSON array ONLY:
[
  {"slot": 3, "team_name": "5 BROTHERS ESPORTS"},
  {"slot": 4, "team_name": "INX ESPORTS"},
  {"slot": 13, "team_name": "KARUNADU ESPORTS"}
]

Skip any slot that is locked, empty, or has no team name.
''';

      final raw = await _callVisionWithFallback(images[i], prompt);
      debugPrint('[DEBUG] raw response: $raw');
      if (raw == null) continue;

      try {
        final list = jsonDecode(raw) as List;
        for (final item in list) {
          final slot = _toInt(item['slot']);
          final name = (item['team_name'] as String?)?.trim();
          if (slot == null || slot < 1 || slot > 30) continue;
          if (name == null || name.isEmpty || name == 'UNKNOWN') continue;
          if (seenSlots.contains(slot)) continue;
          seenSlots.add(slot);
          all.add(OcrTeamEntry(
            slotNumber: slot,
            teamName:   name.toUpperCase(),
            confidence: 0.95,
          ));
        }
      } catch (e, stack) {
        debugPrint('[GeminiService] Error parsing team list JSON: $e\nRaw: $raw\nStack: $stack');
        // Don't rethrow — continue to next image if one fails to parse
        continue;
      }
    }

    onProgress?.call(images.length, images.length, 'Complete');
    all.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
    return all;
  }

  // ── 2. Lobby Images ────────────────────────────────────────
  // Called before each match. Max 3 images.
  // Extracts slot number + player names.
  Future<List<OcrLobbyEntry>> extractLobby(
      List<File> images, {
        void Function(int current, int total, String status)? onProgress,
      }) async {
    final all       = <OcrLobbyEntry>[];
    final seenSlots = <int>{};

    for (int i = 0; i < images.length; i++) {
      onProgress?.call(
        i + 1,
        images.length,
        'Reading lobby image ${i + 1} of ${images.length}...',
      );

      final prompt = '''
This text is extracted from a BGMI/PUBG in-game lobby screenshot.
Each numbered section = one team slot.
Each slot has a slot number and player names.
Some players show kill count as "/0 Eliminations" or "/1 Eliminations".

IMPORTANT: Read the ACTUAL slot numbers. Do NOT start at 1 if the text shows 6, 7, 8 etc.
This is image ${i + 1} of ${images.length}.

Extract every slot and all its players:
[
  {
    "slot": 6,
    "players": [
      {"name": "GODxJonathan", "kills": 0},
      {"name": "GODxZgod", "kills": 2}
    ]
  }
]

kills = number shown after "/" (use 0 if not visible).
List ALL players visible in each slot.
''';

      // final raw = await _processImage(images[i], prompt);
      final raw = await _callVisionWithFallback(images[i], prompt);
      if (raw == null) continue;

      try {
        final list = jsonDecode(raw) as List;
        for (final item in list) {
          final slot = _toInt(item['slot']);
          if (slot == null || slot < 1 || slot > 30) continue;
          if (seenSlots.contains(slot)) continue;

          final ps = (item['players'] as List? ?? [])
              .map((p) => (p['name'] as String? ?? '').trim())
              .where((n) => n.isNotEmpty && n != 'UNKNOWN')
              .toList();

          if (ps.isEmpty) continue;
          seenSlots.add(slot);
          all.add(OcrLobbyEntry(
            slotNumber:  slot,
            playerNames: ps,
            confidence:  0.95,
          ));
        }
      } catch (e, stack) {
        debugPrint('[GeminiService] Error parsing lobby JSON: $e\nRaw: $raw\nStack: $stack');
        throw Exception('AI JSON Parse Error: $e\nRaw Text: $raw');
      }
    }

    onProgress?.call(images.length, images.length, 'Complete');
    all.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
    return all;
  }

  // ── 3. Result Images ───────────────────────────────────────
  // Called after each match. 6 to 8 images.
  // Each image shows multiple teams with rank + player kills.
  // Extracts: rank position + player name + kills per player.
  Future<List<OcrResultEntry>> extractResults(
      List<File> images, {
        void Function(int current, int total, String status)? onProgress,
      }) async {
    final all            = <OcrResultEntry>[];
    final seenRanks      = <int>{};
    int runningRankOffset = 1;

    for (int i = 0; i < images.length; i++) {
      onProgress?.call(
        i + 1,
        images.length,
        'Reading result image ${i + 1} of ${images.length}...',
      );

      final prompt = '''
This text is extracted from a BGMI/PUBG end-of-match results screenshot.
Players are grouped by their finishing rank/position.
Each group belongs to one team.

IMPORTANT:
- Read the literal rank numbers shown (e.g. #4, #5, 9, 10).
- "X finishes" or "X finish" = kills for that player.
- Rank 1 team appears large on the left — always has a crown icon.
- If rank is missing, continue from rank $runningRankOffset.
- This is image ${i + 1} of ${images.length}.

Return every player with their rank and kills:
[
  {"rank": 1, "player_name": "Cute Darinda",  "kills": 4},
  {"rank": 1, "player_name": "ZHsasukee",     "kills": 8},
  {"rank": 1, "player_name": "XyzXTanjiro",   "kills": 0},
  {"rank": 1, "player_name": "Nory Jiii",     "kills": 0},
  {"rank": 2, "player_name": "LHSxKYZA",      "kills": 1},
  {"rank": 9, "player_name": "PBxSYCHO",      "kills": 0}
]

If kills not visible for a player, use 0.
List EVERY player you can see. Do not skip any.
''';

      // final raw = await _processImage(images[i], prompt);
      final raw = await _callVisionWithFallback(images[i], prompt);
      if (raw == null) continue;

      try {
        final list   = jsonDecode(raw) as List;
        final groups = <int, List<OcrPlayerKill>>{};
        int maxRankInImage = runningRankOffset;

        for (final item in list) {
          final rank  = _toInt(item['rank']);
          final name  = (item['player_name'] as String?)?.trim();
          final kills = _toInt(item['kills']) ?? 0;
          if (rank == null || rank < 1 || rank > 30) continue;
          if (name == null || name.isEmpty || name == 'UNKNOWN') continue;
          if (rank > maxRankInImage) maxRankInImage = rank;
          groups
              .putIfAbsent(rank, () => [])
              .add(OcrPlayerKill(playerName: name, kills: kills));
        }

        for (final e in groups.entries) {
          if (seenRanks.contains(e.key)) continue;
          seenRanks.add(e.key);
          all.add(OcrResultEntry(rankPosition: e.key, players: e.value));
        }

        runningRankOffset = maxRankInImage + 1;
      } catch (e, stack) {
        debugPrint('[GeminiService] Error parsing result JSON: $e\nRaw: $raw\nStack: $stack');
        throw Exception('AI JSON Parse Error: $e\nRaw Text: $raw');
      }
    }

    onProgress?.call(images.length, images.length, 'Complete');
    all.sort((a, b) => a.rankPosition.compareTo(b.rankPosition));
    return all;
  }

  // ── 4. Match results → Teams via fuzzy player matching ─────
  // Unchanged — kept for compatibility.
  List<OcrResultEntry> matchResultsToTeams({
    required List<OcrResultEntry> resultEntries,
    required List<OcrLobbyEntry>  lobbyEntries,
    required List<TeamEntity>     teams,
  }) {
    final playerToSlot = <String, int>{};
    for (final lobby in lobbyEntries) {
      for (final name in lobby.playerNames) {
        playerToSlot[name.toLowerCase()] = lobby.slotNumber;
      }
    }
    final slotToTeam = {for (final t in teams) t.slotNumber: t};

    for (final entry in resultEntries) {
      for (final player in entry.players) {
        final slot = _fuzzySlot(player.playerName, playerToSlot);
        if (slot != null && slotToTeam.containsKey(slot)) {
          entry.matchedTeamId   = slotToTeam[slot]!.id;
          entry.matchedTeamName = slotToTeam[slot]!.teamName;
          entry.matchConfidence = 0.95;
          break;
        }
      }
    }
    return resultEntries;
  }

  // ── Core: OCR → Gemini text, with vision fallback ─────────
  //
  // Step 1: ML Kit extracts text from image (free, on-device)
  // Step 2: If text is long enough → send text to Gemini (high quota)
  // Step 3: If text too short     → send image to Gemini (vision quota)
  Future<String?> _processImage(File image, String prompt) async {
    // Step 1 — ML Kit OCR
    final ocrText = await _ocr.extractText(image);
    final hasUsableText = ocrText.length >= AppConstants.minOcrTextLength;

    debugPrint(
      '[GeminiService] OCR extracted ${ocrText.length} chars '
          '— ${hasUsableText ? "using text mode" : "falling back to vision"}',
    );

    if (hasUsableText) {
      // Step 2 — Text-only Gemini (no image bytes, no vision quota)
      final result = await _callTextModel(
        ocrText,
        prompt,
        AppConstants.geminiFlashLite,
      );
      if (result != null && result.trim().isNotEmpty) return result;

      // Text lite failed → try text flash
      final fallback = await _callTextModel(
        ocrText,
        prompt,
        AppConstants.geminiFlash,
      );
      if (fallback != null && fallback.trim().isNotEmpty) return fallback;
    }

    // Step 3 — Vision fallback (sends image bytes, costs vision quota)
    debugPrint('[GeminiService] Using vision fallback for ${image.path}');
    return _callVisionModel(image, prompt, AppConstants.geminiFlashLite)
        .then((r) async {
      if (r != null && r.trim().isNotEmpty) return r;
      return _callVisionModel(image, prompt, AppConstants.geminiFlash);
    });
  }

  // Vision only — no OCR attempt
// Used for complex game UI screenshots (lobby, results)
//   Future<String?> _callVisionWithFallback(File image, String prompt) async {
//     debugPrint('[GeminiService] Calling vision model (lite)...');
//     try {
//       final resp = await _callVisionModel(image, prompt, AppConstants.geminiFlashLite);
//       if (resp != null && resp.trim().isNotEmpty) return resp;
//     } catch (e) {
//       debugPrint('[GeminiService] lite generated error: $e');
//     }
//
//     debugPrint('[GeminiService] lite failed, calling vision model (flash)...');
//     final fallback = await _callVisionModel(image, prompt, AppConstants.geminiFlash);
//     if (fallback != null && fallback.trim().isNotEmpty) return fallback;
//
//     debugPrint('[GeminiService] Both vision models failed or returned empty.');
//     return null;
//   }


  Future<String?> _callVisionWithFallback(File image, String prompt) async {
    // Try flash-lite first (higher quota), then flash as fallback
    for (final model in [AppConstants.geminiFlashLite, AppConstants.geminiFlash]) {
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          debugPrint('[GeminiService] Calling vision model $model (attempt ${attempt + 1})...');
          final r = await _callVisionModel(image, prompt, model);
          debugPrint('[DEBUG] vision returned: $r');
          if (r != null && r.trim().isNotEmpty) return r;
          debugPrint('[GeminiService] Vision returned empty for $model.');
          break; // Empty response → try next model, no retry
        } on GeminiQuotaException {
          rethrow; // Quota errors should bubble up
        } catch (e) {
          debugPrint('[GeminiService] Vision failed for $model (attempt ${attempt + 1}): $e');
          if (attempt == 0) {
            // Wait before retry on transient errors
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
    }
    debugPrint('[GeminiService] All vision models failed.');
    return null;
  }
  // ── Text-only Gemini call ──────────────────────────────────
  Future<String?> _callTextModel(
      String ocrText,
      String prompt,
      String model,
      ) async {
    try {
      final content = Content.text(
        'The following text was extracted from a game screenshot using OCR:\n\n'
            '---\n$ocrText\n---\n\n'
            '$prompt',
      );
      final resp = await _textModel(model).generateContent([content]);
      final text = resp.text?.trim();
      if (text == null || text.isEmpty) return null;
      return _stripFences(text);
    } on GenerativeAIException catch (e) {
      if (e.message.contains('quota') || e.message.contains('rate')) {
        throw GeminiQuotaException(e.message);
      }
      debugPrint('[GeminiService] vision model error: ${e.message}');
      return null;  // ← changed
    } catch (e) {
      debugPrint('[GeminiService] vision model unexpected: $e');
      return null;  // ← changed
    }
  }

  // ── Vision Gemini call (fallback) ──────────────────────────
  Future<String?> _callVisionModel(
      File image,
      String prompt,
      String model,
      ) async {
    try {
      final bytes = await image.readAsBytes();
      final mime  = image.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final resp  = await _visionModel(model).generateContent([
        Content.multi([DataPart(mime, bytes), TextPart(prompt)]),
      ]);
      final text = resp.text?.trim();
      if (text == null || text.isEmpty) return null;
      return _stripFences(text);
    } on GenerativeAIException catch (e) {
      if (e.message.contains('quota') || e.message.contains('rate')) {
        throw GeminiQuotaException(e.message);
      }
      debugPrint('[GeminiService] vision model error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[GeminiService] vision model unexpected: $e');
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  String _stripFences(String raw) {
    var s = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final start = s.indexOf(RegExp(r'[\[\{]'));
    if (start > 0) s = s.substring(start);
    return s;
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  int? _fuzzySlot(String name, Map<String, int> map) {
    final lower = name.toLowerCase();
    if (map.containsKey(lower)) return map[lower];
    double best = 0;
    int?   slot;
    for (final e in map.entries) {
      final s = StringSimilarity.compareTwoStrings(lower, e.key);
      if (s > best && s >= AppConstants.fuzzyMatchThreshold) {
        best = s;
        slot = e.value;
      }
    }
    return slot;
  }

  /// Call when the app disposes GeminiService
  void dispose() => _ocr.dispose();
}

class GeminiQuotaException implements Exception {
  final String message;
  const GeminiQuotaException(this.message);
}