import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/gemini_service_v2.dart';
import '../../../../data/models/ocr_result_model.dart';
import '../../../common/providers/providers.dart';

enum UploadType { lobby, result }

class UploadState {
  final List<File> images;
  final bool isProcessing;
  final String? errorMessage;
  final bool isOcrDone;
  final int currentImage; // progress tracking
  final int totalImages; // progress tracking
  final String statusText; // progress label
  final List<OcrLobbyEntry> lobbyEntries;
  final List<OcrResultEntry> resultEntries;

  const UploadState({
    this.images = const [],
    this.isProcessing = false,
    this.errorMessage,
    this.isOcrDone = false,
    this.currentImage = 0,
    this.totalImages = 0,
    this.statusText = '',
    this.lobbyEntries = const [],
    this.resultEntries = const [],
  });

  UploadState copyWith({
    List<File>? images,
    bool? isProcessing,
    String? errorMessage,
    bool? isOcrDone,
    int? currentImage,
    int? totalImages,
    String? statusText,
    List<OcrLobbyEntry>? lobbyEntries,
    List<OcrResultEntry>? resultEntries,
  }) =>
      UploadState(
        images: images ?? this.images,
        isProcessing: isProcessing ?? this.isProcessing,
        errorMessage: errorMessage,
        isOcrDone: isOcrDone ?? this.isOcrDone,
        currentImage: currentImage ?? this.currentImage,
        totalImages: totalImages ?? this.totalImages,
        statusText: statusText ?? this.statusText,
        lobbyEntries: lobbyEntries ?? this.lobbyEntries,
        resultEntries: resultEntries ?? this.resultEntries,
      );

  bool get hasImages => images.isNotEmpty;
  double get progress => totalImages > 0 ? currentImage / totalImages : 0;
}

class UploadNotifier extends StateNotifier<UploadState> {
  final Ref _ref;
  final String matchId;
  final String tournamentId;
  final UploadType uploadType;

  UploadNotifier(this._ref, this.matchId, this.tournamentId, this.uploadType)
      : super(const UploadState());

  int get maxImages => uploadType == UploadType.lobby ? 3 : 8;
  int get minImages => uploadType == UploadType.lobby ? 1 : 6;

  bool get canProcess => state.images.length >= minImages;
  bool get canAddMore => state.images.length < maxImages;

  void addImages(List<File> files) {
    if (!canAddMore) return;
    final remaining = maxImages - state.images.length;
    final toAdd = files.take(remaining).toList();
    state = state.copyWith(
      images: [...state.images, ...toAdd],
      isOcrDone: false,
    );
  }

  void removeImage(int index) {
    final updated = [...state.images]..removeAt(index);
    state = state.copyWith(images: updated, isOcrDone: false);
  }

  // Processes images ONE BY ONE via Gemini
  // Updates progress after each image
  Future<void> processWithGemini() async {
    if (!canProcess) return;

    state = state.copyWith(
      isProcessing: true,
      errorMessage: null,
      currentImage: 0,
      totalImages: state.images.length,
      statusText: 'Starting Gemini AI...',
    );

    try {
      final gemini = _ref.read(geminiServiceProvider);

      void onProgress(int current, int total, String status) {
        state = state.copyWith(
          currentImage: current,
          totalImages: total,
          statusText: status,
        );
      }

      if (uploadType == UploadType.lobby) {
        final entries = await gemini.extractLobby(
          state.images,
          onProgress: onProgress,
        );
        state = state.copyWith(
          isProcessing: false,
          isOcrDone: true,
          lobbyEntries: entries,
          statusText: 'Complete',
        );
      } else {
        final entries = await gemini.extractResults(
          state.images,
          onProgress: onProgress,
        );
        state = state.copyWith(
          isProcessing: false,
          isOcrDone: true,
          resultEntries: entries,
          statusText: 'Complete',
        );
      }
    } on GeminiQuotaException {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Daily AI quota reached. Try again tomorrow.',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Processing failed: ${e.toString()}',
      );
    }
  }

  void reset() => state = const UploadState();
}

// Key format: "tournamentId__matchId__lobby" or "tournamentId__matchId__result"
final uploadNotifierProvider = StateNotifierProvider.autoDispose
    .family<UploadNotifier, UploadState, String>(
  (ref, key) {
    final parts = key.split('__');
    final tournamentId = parts[0];
    final matchId = parts[1];
    final type = parts[2] == 'lobby' ? UploadType.lobby : UploadType.result;
    return UploadNotifier(ref, matchId, tournamentId, type);
  },
);
