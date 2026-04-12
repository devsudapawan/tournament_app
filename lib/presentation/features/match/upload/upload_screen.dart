import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../common/providers/providers.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/shared_widgets.dart';
import '../../../../data/models/ocr_result_model.dart';

// ── Providers ──────────────────────────────────────────────
// Stores images per "matchId__lobby" or "matchId__result"
final uploadImagesProvider =
    StateProvider.family<List<File>, String>((_, __) => []);

// Stores AI results after processing
final lobbyAiResultProvider =
    StateProvider.family<List<OcrLobbyEntry>, String>((_, __) => []);
final resultAiResultProvider =
    StateProvider.family<List<OcrResultEntry>, String>((_, __) => []);

// Processing state
class _ProcessingState {
  final bool isProcessing;
  final int currentImage;
  final int totalImages;
  final String currentImageName;

  const _ProcessingState({
    this.isProcessing = false,
    this.currentImage = 0,
    this.totalImages = 0,
    this.currentImageName = '',
  });

  _ProcessingState copyWith({
    bool? isProcessing,
    int? currentImage,
    int? totalImages,
    String? currentImageName,
  }) =>
      _ProcessingState(
        isProcessing: isProcessing ?? this.isProcessing,
        currentImage: currentImage ?? this.currentImage,
        totalImages: totalImages ?? this.totalImages,
        currentImageName: currentImageName ?? this.currentImageName,
      );
}

final _processingStateProvider =
    StateProvider<_ProcessingState>((_) => const _ProcessingState());

// ── Screen ─────────────────────────────────────────────────
class UploadScreen extends ConsumerWidget {
  final String matchId;
  final String tournamentId;
  final String uploadType; // 'lobby' or 'result'

  const UploadScreen({
    super.key,
    required this.matchId,
    required this.uploadType,
    required this.tournamentId,
  });

  bool get isLobby => uploadType == 'lobby';
  int get maxImages =>
      isLobby ? AppConstants.maxLobbyImages : AppConstants.maxResultImages;
  int get minImages => isLobby ? 1 : AppConstants.minResultImages;
  String get providerKey => '${matchId}__$uploadType';

  // ── Pick multiple images from gallery ────────────────────
  Future<void> _pickImages(BuildContext context, WidgetRef ref) async {
    final images = ref.read(uploadImagesProvider(providerKey));
    final remaining = maxImages - images.length;
    if (remaining <= 0) return;

    final picker = ImagePicker();
    // Pick multiple images at once
    final picked = await picker.pickMultiImage(imageQuality: 90);

    if (picked.isEmpty) return;

    // Only take up to the remaining slots
    final toAdd = picked.take(remaining).map((x) => File(x.path)).toList();
    ref.read(uploadImagesProvider(providerKey).notifier).state = [
      ...images,
      ...toAdd,
    ];

    if (picked.length > remaining && context.mounted) {
      SnackBarHelper.showInfo(
        context,
        'Only $remaining more image(s) allowed. Added $remaining.',
      );
    }
  }

  // ── Process all images through AI one by one ────────────
  Future<void> _processAi(BuildContext context, WidgetRef ref) async {
    final images = ref.read(uploadImagesProvider(providerKey));
    if (images.isEmpty) return;

    final ai = ref.read(geminiServiceProvider);
    final processing = ref.read(_processingStateProvider.notifier);

    processing.state = _ProcessingState(
      isProcessing: true,
      currentImage: 0,
      totalImages: images.length,
      currentImageName: '',
    );

    try {
      if (isLobby) {
        // Process lobby images one by one
        final entries = await ai.extractLobby(
          images,
          onProgress: (current, total, name) {
            processing.state = processing.state.copyWith(
              currentImage: current,
              totalImages: total,
              currentImageName: name,
            );
          },
        );

        if (!context.mounted) return;

        if (entries.isEmpty) {
          SnackBarHelper.showError(
            context,
            'Could not read any slot data. Try a clearer image.',
          );
          processing.state = const _ProcessingState();
          return;
        }

        // Store AI results for verify screen
        ref.read(lobbyAiResultProvider(providerKey).notifier).state = entries;
      } else {
        // Process result images one by one
        final entries = await ai.extractResults(
          images,
          onProgress: (current, total, name) {
            processing.state = processing.state.copyWith(
              currentImage: current,
              totalImages: total,
              currentImageName: name,
            );
          },
        );

        if (!context.mounted) return;

        if (entries.isEmpty) {
          SnackBarHelper.showError(
            context,
            'Could not read any result data. Try clearer images.',
          );
          processing.state = const _ProcessingState();
          return;
        }

        ref.read(resultAiResultProvider(providerKey).notifier).state = entries;
      }

      processing.state = const _ProcessingState();

      if (context.mounted) {
        // Navigate to verify screen — pass the providerKey so it
        // can read the AI results
        context.push(
          '${AppRoutes.verify}/$tournamentId/$matchId/$uploadType',
        );
      }
    } catch (e) {
      processing.state = const _ProcessingState();
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          'AI processing failed: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(uploadImagesProvider(providerKey));
    final procState = ref.watch(_processingStateProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          isLobby ? 'Upload Lobby' : 'Upload Results',
          style: AppTextStyles.heading(size: 17),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoBanner(
                  isLobby
                      ? 'Upload lobby screenshots showing slot numbers and player names. You can select multiple images at once. Max $maxImages images.'
                      : 'Upload result screenshots showing final ranks and kill counts. Select multiple images at once. Min $minImages, Max $maxImages images.',
                ),

                // ── Upload button ──────────────────────
                SectionLabel('Images (${images.length}/$maxImages)'),
                if (images.length < maxImages) ...[
                  GestureDetector(
                    onTap: () => _pickImages(context, ref),
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.yellow, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Select images',
                                  style: AppTextStyles.body(
                                      color: AppColors.white)),
                              Text(
                                'Can select multiple at once · ${images.length}/$maxImages',
                                style: AppTextStyles.body(
                                    color: AppColors.muted, size: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Image grid ─────────────────────────
                if (images.isNotEmpty) ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: images.length,
                    itemBuilder: (_, i) => _ImageTile(
                      file: images[i],
                      index: i,
                      onRemove: () {
                        final updated = [...images]..removeAt(i);
                        ref
                            .read(uploadImagesProvider(providerKey).notifier)
                            .state = updated;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (!isLobby && images.length < minImages)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Need at least $minImages images for results. Currently ${images.length}.',
                            style: AppTextStyles.body(
                                color: AppColors.warning, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // ── Full-screen AI processing overlay ─────
          if (procState.isProcessing) _ProcessingOverlay(state: procState),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: AppButton(
            label: procState.isProcessing
                ? 'Processing...'
                : 'Read Images with AI',
            onTap: (!procState.isProcessing && images.length >= minImages)
                ? () => _processAi(context, ref)
                : null,
            isLoading: procState.isProcessing,
          ),
        ),
      ),
    );
  }
}

// ── Image tile with remove button ──────────────────────────
class _ImageTile extends StatelessWidget {
  final File file;
  final int index;
  final VoidCallback onRemove;

  const _ImageTile({
    required this.file,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, fit: BoxFit.cover),
          ),
          // Index badge
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${index + 1}',
                  style:
                      AppTextStyles.label(color: AppColors.yellow, size: 10)),
            ),
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      );
}

// ── Full-screen processing overlay ─────────────────────────
class _ProcessingOverlay extends StatelessWidget {
  final _ProcessingState state;
  const _ProcessingOverlay({required this.state});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black.withOpacity(0.88),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress ring
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: state.totalImages > 0
                            ? state.currentImage / state.totalImages
                            : null,
                        strokeWidth: 6,
                        color: AppColors.yellow,
                        backgroundColor: AppColors.bg3,
                      ),
                      Text(
                        '${state.currentImage}/${state.totalImages}',
                        style: AppTextStyles.label(
                            color: AppColors.yellow, size: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Reading images...',
                  style: AppTextStyles.heading(size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  state.currentImageName,
                  style: AppTextStyles.body(color: AppColors.muted, size: 14),
                ),
                const SizedBox(height: 24),
                // Progress bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: state.totalImages > 0
                        ? state.currentImage / state.totalImages
                        : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Processing image ${state.currentImage} of ${state.totalImages}\nPlease wait...',
                  style: AppTextStyles.body(color: AppColors.muted, size: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}
