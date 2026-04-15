

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../common/providers/providers.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/shared_widgets.dart';
import '../../../../data/models/ocr_result_model.dart';
import '../../../../domain/entities/team_entity.dart';
import '../../../../domain/entities/tournament_entity.dart';

// ── State Providers ────────────────────────────────────────
final _stepProvider         = StateProvider<int>((_) => 1);
final _loadingProvider      = StateProvider<bool>((_) => false);
final _matchCountProvider   = StateProvider<int>((_) => 6);
final _rankPointsProvider   = StateProvider<Map<int, int>>(
      (_) => Map.from(AppConstants.defaultRankPoints),
);
final _scheduledTimesProvider = StateProvider<List<DateTime?>>(
      (_) => List.filled(8, null),
);
final _teamImagesProvider   = StateProvider<List<File>>((_) => []);
final _ocrTeamsProvider     = StateProvider<List<OcrTeamEntry>>((_) => []);
final _ocrRunningProvider   = StateProvider<bool>((_) => false);

// ── Main Screen ────────────────────────────────────────────
class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() =>
      _CreateTournamentScreenState();
}

class _CreateTournamentScreenState
    extends ConsumerState<CreateTournamentScreen> {
  final _nameCtrl = TextEditingController();
  final _orgCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_stepProvider.notifier).state       = 1;
      ref.read(_matchCountProvider.notifier).state = 6;
      ref.read(_teamImagesProvider.notifier).state = [];
      ref.read(_ocrTeamsProvider.notifier).state   = [];
      ref.read(_ocrRunningProvider.notifier).state = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final step = ref.read(_stepProvider);
    if (step < 5) ref.read(_stepProvider.notifier).state = step + 1;
  }

  void _back() {
    final step = ref.read(_stepProvider);
    if (step > 1) {
      ref.read(_stepProvider.notifier).state = step - 1;
    } else {
      context.pop();
    }
  }

  Future<void> _launch() async {
    ref.read(_loadingProvider.notifier).state = true;

    final matchCount = ref.read(_matchCountProvider);
    final rankPts    = ref.read(_rankPointsProvider);
    final times      = ref.read(_scheduledTimesProvider);
    final teams      = ref.read(_ocrTeamsProvider);

    final tResult = await ref.read(createTournamentUseCaseProvider).call(
      TournamentEntity(
        id:           const Uuid().v4(),
        userId:       '',
        name:         _nameCtrl.text.trim(),
        organizerTag: _orgCtrl.text.trim(),
        gameType:     'bgmi',
        totalMatches: matchCount,
        status:       'setup',
        rankPoints:   rankPts,
        killPoints:   AppConstants.defaultKillPoints,
        createdAt:    DateTime.now(),
      ),
    );

    await tResult.fold(
          (f) async {
        ref.read(_loadingProvider.notifier).state = false;
        if (mounted) SnackBarHelper.showError(context, f.message);
      },
          (tournament) async {
        // Save teams
        if (teams.isNotEmpty) {
          final teamEntities = teams
              .map((t) => TeamEntity(
            id:           const Uuid().v4(),
            tournamentId: tournament.id,
            slotNumber:   t.slotNumber,
            teamName:     t.teamName,
          ))
              .toList();
          await ref.read(saveTeamsUseCaseProvider).call(teamEntities);
        }

        // Create match schedule
        await ref.read(createMatchesUseCaseProvider).call(
          tournamentId:   tournament.id,
          total:          matchCount,
          scheduledTimes: times.sublist(0, matchCount),
        );

        ref.read(_loadingProvider.notifier).state = false;
        if (mounted) {
          context.go('${AppRoutes.tournamentDetail}/${tournament.id}');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final step      = ref.watch(_stepProvider);
    final isLoading = ref.watch(_loadingProvider);
    final ocrRunning = ref.watch(_ocrRunningProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: BackButton(onPressed: _back),
        title: Text(
          ['Basic Info', 'Point System', 'Schedule',
            'Team List', 'Confirm'][step - 1],
          style: AppTextStyles.heading(size: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            value:            step / 5,
            backgroundColor:  AppColors.border,
            valueColor:       const AlwaysStoppedAnimation(AppColors.yellow),
            minHeight:        2,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: StepIndicator(current: step, total: 5),
              ),
              Expanded(
                child: IndexedStack(
                  index: step - 1,
                  children: [
                    _Step1(nameCtrl: _nameCtrl, orgCtrl: _orgCtrl),
                    const _Step2(),
                    const _Step3(),
                    const _Step4(),
                    _Step5(
                      nameCtrl: _nameCtrl,
                      orgCtrl:  _orgCtrl,
                      onLaunch: _launch,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            const LoadingOverlay(message: 'Creating tournament...'),
          if (ocrRunning)
            const LoadingOverlay(message: 'Reading team list...'),
        ],
      ),
      bottomNavigationBar: step < 5
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: AppButton(
            label: step == 4 ? 'Confirm Teams & Continue' : 'Continue',
            onTap: _next,
          ),
        ),
      )
          : null,
    );
  }
}

// ── Step 1: Basic Info ─────────────────────────────────────
class _Step1 extends ConsumerWidget {
  final TextEditingController nameCtrl;
  final TextEditingController orgCtrl;
  const _Step1({required this.nameCtrl, required this.orgCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            AppTextField(
              label:      'Tournament Name',
              hint:       'e.g. Summer Cup Knockout G-1',
              controller: nameCtrl,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label:      'Organizer / Tag',
              hint:       'e.g. B2B Esports',
              controller: orgCtrl,
            ),
            const SizedBox(height: 24),
            const SectionLabel('Select Game'),
            const _GameCard(name: 'BGMI', sub: 'Battlegrounds Mobile India',
                isSelected: true, isLocked: false),
            const SizedBox(height: 8),
            const _GameCard(name: 'PUBG Mobile', sub: 'Coming soon', isLocked: true),
            const SizedBox(height: 8),
            const _GameCard(name: 'Free Fire', sub: 'Coming soon', isLocked: true),
            const SizedBox(height: 24),
            const SectionLabel('Number of Matches'),
            const _MatchCounter(),
          ],
        ),
      );
}

class _GameCard extends StatelessWidget {
  final String name;
  final String sub;
  final bool   isSelected;
  final bool   isLocked;
  const _GameCard({
    required this.name,
    required this.sub,
    this.isSelected = false,
    this.isLocked   = false,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: isLocked ? 0.4 : 1,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.yellow.withOpacity(0.07)
            : AppColors.bg3,
        border: Border.all(
          color: isSelected ? AppColors.yellow : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_esports_outlined,
              color: AppColors.yellow, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.subheading(
                        color: AppColors.white)),
                Text(sub,
                    style: AppTextStyles.body(
                        color: AppColors.muted, size: 12)),
              ],
            ),
          ),
          if (isLocked)
            const Icon(Icons.lock_outline,
                color: AppColors.muted, size: 16)
          else if (isSelected)
            Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow,
              ),
              child: const Icon(Icons.check,
                  size: 12, color: Colors.black),
            ),
        ],
      ),
    ),
  );
}

class _MatchCounter extends ConsumerWidget {
  const _MatchCounter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_matchCountProvider);
    return Column(
      children: [
        Row(
          children: [
            _CountBtn(
              icon: Icons.remove,
              onTap: () {
                if (count > AppConstants.minMatches) {
                  ref.read(_matchCountProvider.notifier).state = count - 1;
                }
              },
            ),
            Expanded(
              child: Center(
                child: Text('$count',
                    style: AppTextStyles.number(size: 40)),
              ),
            ),
            _CountBtn(
              icon: Icons.add,
              onTap: () {
                if (count < AppConstants.maxMatches) {
                  ref.read(_matchCountProvider.notifier).state = count + 1;
                }
              },
            ),
          ],
        ),
        Text('MATCHES IN THIS TOURNAMENT',
            style: AppTextStyles.label(color: AppColors.muted)),
      ],
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _CountBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color:        AppColors.bg3,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.white, size: 22),
    ),
  );
}

// ── Step 2: Point System ───────────────────────────────────
class _Step2 extends ConsumerWidget {
  const _Step2();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankPts = ref.watch(_rankPointsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Rank Points (Position 1–8)'),
          ...List.generate(8, (i) {
            final pos  = i + 1;
            final ctrl = TextEditingController(
                text: '${rankPts[pos] ?? 0}');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:        AppColors.bg3,
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          Text('#$pos ',
                              style: AppTextStyles.body(
                                  color: AppColors.yellow)),
                          Text(_posLabel(pos),
                              style: AppTextStyles.body(
                                  color: AppColors.muted, size: 13)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 64,
                      child: TextFormField(
                        controller:  ctrl,
                        keyboardType: TextInputType.number,
                        textAlign:   TextAlign.center,
                        style: AppTextStyles.heading(
                            size: 15, color: AppColors.white),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 8),
                          isDense:    true,
                          filled:     true,
                          fillColor:  AppColors.bg,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.yellow),
                          ),
                        ),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null) {
                            ref
                                .read(_rankPointsProvider.notifier)
                                .state = {...rankPts, pos: n};
                          }
                        },
                      ),
                    ),
                    Text(' pts',
                        style: AppTextStyles.label(
                            color: AppColors.muted, size: 11)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const SectionLabel('Kill Points'),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:        AppColors.yellowGlow,
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(
                  color: AppColors.yellow.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_esports_outlined,
                    color: AppColors.yellow, size: 18),
                const SizedBox(width: 10),
                Text('Per kill (each player)',
                    style: AppTextStyles.body(color: AppColors.white)),
                const Spacer(),
                Text('1 pt',
                    style: AppTextStyles.heading(
                        size: 15, color: AppColors.yellow)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const InfoBanner(
              'Teams ranked 9th and below receive 0 rank points but still earn kill points.'),
        ],
      ),
    );
  }

  String _posLabel(int pos) {
    switch (pos) {
      case 1:  return 'Winner';
      case 2:  return '2nd place';
      case 3:  return '3rd place';
      default: return '${pos}th place';
    }
  }
}

// ── Step 3: Match Schedule ─────────────────────────────────
class _Step3 extends ConsumerWidget {
  const _Step3();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_matchCountProvider);
    final times = ref.watch(_scheduledTimesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Start Times'),
          ...List.generate(count, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () async {
                final dt = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate:   DateTime.now(),
                  lastDate:    DateTime.now()
                      .add(const Duration(days: 365)),
                  builder: (ctx, child) =>
                      Theme(data: ThemeData.dark(), child: child!),
                );
                if (dt != null && context.mounted) {
                  final tm = await showTimePicker(
                    context:     context,
                    initialTime: TimeOfDay.now(),
                    builder:     (ctx, child) =>
                        Theme(data: ThemeData.dark(), child: child!),
                  );
                  if (tm != null) {
                    final full = DateTime(dt.year, dt.month, dt.day,
                        tm.hour, tm.minute);
                    final updated = [...times];
                    updated[i] = full;
                    ref
                        .read(_scheduledTimesProvider.notifier)
                        .state = updated;
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: times[i] != null
                        ? AppColors.yellow.withOpacity(0.4)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    SlotBadge(slot: i + 1, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Match ${i + 1}',
                            style: AppTextStyles.subheading(
                                size: 14, color: AppColors.white)),
                        Text(
                          times[i] != null
                              ? _fmt(times[i]!)
                              : 'Tap to set time',
                          style: AppTextStyles.body(
                            color: times[i] != null
                                ? AppColors.yellow
                                : AppColors.muted,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      times[i] != null
                          ? Icons.check_circle_outline
                          : Icons.access_time,
                      color: times[i] != null
                          ? AppColors.success
                          : AppColors.muted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} · $h:$m';
  }
}

// ── Step 4: Upload Team List ───────────────────────────────
// FIX: Changed to ConsumerStatefulWidget so OCR results survive rebuilds
// FIX: Improved OCR logic handles separate blocks (slot # in yellow box,
//      team name in black box) — actual ML Kit output for this image type
class _Step4 extends ConsumerStatefulWidget {
  const _Step4();

  @override
  ConsumerState<_Step4> createState() => _Step4State();
}

class _Step4State extends ConsumerState<_Step4> {

  Future<void> _pickImages() async {
    final images = ref.read(_teamImagesProvider);
    if (images.length >= 2) return;

    final picker  = ImagePicker();
    final remaining = 2 - images.length;

    // Allow picking multiple images
    final picked = await picker.pickMultiImage(imageQuality: 95);
    if (picked.isEmpty) return;

    final toAdd = picked
        .take(remaining)
        .map((x) => File(x.path))
        .toList();

    final updated = [...images, ...toAdd];
    ref.read(_teamImagesProvider.notifier).state = updated;

    // Auto-run OCR after picking
    await _runOcr(updated);
  }

  Future<void> _runOcr(List<File> images) async {
    if (images.isEmpty) return;
    ref.read(_ocrRunningProvider.notifier).state = true;

    try {
      final ocr     = ref.read(geminiServiceProvider);
      final entries = await ocr.extractTeamList(
        images,
        onProgress: (current, total, name) {
          // Progress is shown via the loading overlay
        },
      );

      if (entries.isEmpty && mounted) {
        SnackBarHelper.showError(
          context,
          'Could not read any teams. Make sure the image is clear and shows slot numbers.',
        );
      } else if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          '${entries.length} teams detected. Review and edit below.',
        );
      }

      ref.read(_ocrTeamsProvider.notifier).state = entries;
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'OCR error: ${e.toString()}');
        print("OCR error : ${e.toString()}");
      }
    } finally {
      ref.read(_ocrRunningProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final images   = ref.watch(_teamImagesProvider);
    final ocrTeams = ref.watch(_ocrTeamsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoBanner(
            'Upload the slot + team name image. Up to 2 images. '
                'OCR will extract all team names and slot numbers automatically.',
          ),

          // ── Upload area ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionLabel('Images (${images.length}/2)'),
              if (ocrTeams.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${ocrTeams.length} teams found',
                    style: AppTextStyles.label(
                        color: AppColors.success, size: 10),
                  ),
                ),
            ],
          ),

          if (images.length < 2)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_outlined,
                        color: AppColors.yellow, size: 26),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize:        MainAxisSize.min,
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        Text('Tap to upload team list',
                            style: AppTextStyles.body(
                                color: AppColors.white)),
                        Text('Can select both images at once',
                            style: AppTextStyles.body(
                                color: AppColors.muted, size: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── Uploaded files ────────────────────────
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...images.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        AppColors.bg3,
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color:        AppColors.yellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('IMG',
                          style: AppTextStyles.label(
                              color: Colors.black, size: 10)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Team list image ${e.key + 1}',
                              style: AppTextStyles.body(
                                  color: AppColors.white, size: 13)),
                          Text('Uploaded',
                              style: AppTextStyles.body(
                                  color: AppColors.success, size: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: AppColors.muted),
                      onPressed: () {
                        final updated = [...images]
                          ..removeAt(e.key);
                        ref
                            .read(_teamImagesProvider.notifier)
                            .state = updated;
                        // Re-run OCR on remaining images
                        if (updated.isNotEmpty) {
                          _runOcr(updated);
                        } else {
                          ref
                              .read(_ocrTeamsProvider.notifier)
                              .state = [];
                        }
                      },
                      padding:     EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            )),

            // Retry OCR button
            if (ocrTeams.isEmpty && images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppButton(
                  label:   'Retry OCR',
                  variant: ButtonVariant.secondary,
                  onTap:   () => _runOcr(images),
                ),
              ),
          ],

          // ── OCR Results table ─────────────────────
          if (ocrTeams.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionLabel('Review — tap any name to edit'),
            Row(
              children: [
                Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success)),
                const SizedBox(width: 4),
                Text('High confidence  ',
                    style: AppTextStyles.label(
                        color: AppColors.muted, size: 10)),
                Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.danger)),
                const SizedBox(width: 4),
                Text('Needs review',
                    style: AppTextStyles.label(
                        color: AppColors.muted, size: 10)),
              ],
            ),
            const SizedBox(height: 10),
            ...ocrTeams.asMap().entries.map(
                  (e) => _OcrTeamRow(index: e.key, entry: e.value),
            ),
          ],

          // ── Skip message ──────────────────────────
          if (images.isEmpty)
            const InfoBanner(
              'You can skip uploading and add teams manually later from the tournament detail screen.',
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OcrTeamRow extends ConsumerWidget {
  final int          index;
  final OcrTeamEntry entry;
  const _OcrTeamRow({required this.index, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: entry.teamName);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.needsReview
              ? AppColors.danger.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SlotBadge(slot: entry.slotNumber, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: ctrl,
              style: AppTextStyles.body(
                  color: AppColors.white, size: 15),
              decoration: const InputDecoration(
                isDense:        true,
                border:         InputBorder.none,
                contentPadding: EdgeInsets.all(8),
              ),
              onChanged: (v) {
                final teams = [
                  ...ref.read(_ocrTeamsProvider)
                ];
                teams[index] = OcrTeamEntry(
                  slotNumber: entry.slotNumber,
                  teamName:   v.toUpperCase(),
                  confidence: entry.confidence,
                  isEdited:   true,
                );
                ref
                    .read(_ocrTeamsProvider.notifier)
                    .state = teams;
              },
            ),
          ),
          const SizedBox(width: 5,),
          ConfidenceDot(entry.confidence),
        ],
      ),
    );
  }
}

// ── Step 5: Confirm ────────────────────────────────────────
class _Step5 extends ConsumerWidget {
  final TextEditingController nameCtrl;
  final TextEditingController orgCtrl;
  final VoidCallback          onLaunch;
  const _Step5({
    required this.nameCtrl,
    required this.orgCtrl,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchCount = ref.watch(_matchCountProvider);
    final teams      = ref.watch(_ocrTeamsProvider);
    final rankPts    = ref.watch(_rankPointsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Tournament Summary'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        AppColors.bg3,
              borderRadius: BorderRadius.circular(14),
              border:       Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SummaryRow('Name',
                    nameCtrl.text.isEmpty ? '(not set)' : nameCtrl.text,
                    highlight: true),
                _SummaryRow('Organizer',
                    orgCtrl.text.isEmpty ? '(not set)' : orgCtrl.text),
                const _SummaryRow('Game', 'BGMI'),
                _SummaryRow('Matches', '$matchCount matches'),
                _SummaryRow('Teams',
                    '${teams.length} registered'),
                _SummaryRow('Win points', '${rankPts[1]} pts'),
                const _SummaryRow('Kill points', '1 pt / kill',
                    isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (teams.isNotEmpty) ...[
            const SectionLabel('Team Preview'),
            ...teams.take(5).map(
                  (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:        AppColors.bg3,
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      SlotBadge(slot: t.slotNumber, size: 28),
                      const SizedBox(width: 12),
                      Text(t.teamName,
                          style: AppTextStyles.subheading(
                              color: AppColors.white, size: 14)),
                    ],
                  ),
                ),
              ),
            ),
            if (teams.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  '+ ${teams.length - 5} more teams',
                  style: AppTextStyles.body(
                      color: AppColors.muted, size: 12),
                ),
              ),
          ] else
            const InfoBanner(
              'No teams detected from OCR. You can still launch and add teams later.',
            ),

          const SizedBox(height: 24),
          AppButton(
            label: 'Launch Tournament',
            onTap: onLaunch,
            icon:  const Icon(Icons.rocket_launch_outlined,
                color: Colors.black, size: 18),
          ),
          const SizedBox(height: 12),
          AppButton(
            label:   'Edit',
            variant: ButtonVariant.secondary,
            onTap: () =>
            ref.read(_stepProvider.notifier).state = 1,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   highlight;
  final bool   isLast;
  const _SummaryRow(this.label, this.value,
      {this.highlight = false, this.isLast = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(
          bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.body(
                color: AppColors.muted, size: 13)),
        Text(value,
            style: AppTextStyles.subheading(
              color: highlight
                  ? AppColors.yellow
                  : AppColors.white,
              size: 14,
            )),
      ],
    ),
  );
}