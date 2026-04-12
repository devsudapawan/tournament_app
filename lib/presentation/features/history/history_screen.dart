import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/tournament_entity.dart';
import '../../common/providers/providers.dart';
import '../../common/widgets/shared_widgets.dart';

final _historyProvider = FutureProvider<List<TournamentEntity>>((ref) async {
  final r = await ref.read(getMyTournamentsUseCaseProvider).call();
  return r.fold((_) => [], (list) => list);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('History', style: AppTextStyles.heading(size: 17)),
      ),
      body: history.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.yellow)),
        error: (_, __) => const EmptyState(
            title: 'Error', subtitle: 'Could not load history'),
        data: (list) => list.isEmpty
            ? const EmptyState(
                title: 'No tournaments yet',
                subtitle: 'Your completed tournaments will appear here')
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final t = list[i];
                  return GestureDetector(
                    onTap: () => context.push(
                        '${AppRoutes.tournamentDetail}/${t.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name,
                                    style: AppTextStyles.subheading(
                                        color: AppColors.white)),
                                const SizedBox(height: 4),
                                Text(
                                  '${t.gameType.toUpperCase()} · ${t.totalMatches} matches',
                                  style: AppTextStyles.body(
                                      color: AppColors.muted, size: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.muted, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
