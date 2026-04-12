import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/tournament_entity.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../common/providers/providers.dart';
import '../../common/widgets/app_shimmer.dart';

// ── News provider — free GNews API ────────────────────────
// Free tier: 100 requests/day, no key needed for basic use
final _newsProvider = FutureProvider<List<_NewsItem>>((ref) async {
  try {
    // Using GNews free API for gaming news
    final url = Uri.parse(
      'https://gnews.io/api/v4/search'
      '?q=BGMI+PUBG+esports'
      '&lang=en'
      '&max=5'
      '&apikey=YOUR_GNEWS_API_KEY',
      // Get free key at: https://gnews.io — 100 req/day free
    );
    final resp = await http.get(url).timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) return _fallbackNews;
    final data = jsonDecode(resp.body) as Map;
    final articles = data['articles'] as List? ?? [];
    return articles
        .map((a) => _NewsItem(
              title: a['title'] ?? '',
              source: a['source']?['name'] ?? '',
              url: a['url'] ?? '',
              imageUrl: a['image'],
              publishedAt: a['publishedAt'] ?? '',
            ))
        .toList();
  } catch (_) {
    return _fallbackNews;
  }
});

// Fallback static news when API is unavailable / key not set
const _fallbackNews = [
  _NewsItem(
    title: 'BGMI Season 4 Battle Royale — New map confirmed',
    source: 'Krafton India',
    url: '',
    publishedAt: '2026-03-22',
  ),
  _NewsItem(
    title: 'BGMI Pro Series 2026 registrations now open',
    source: 'Esports India',
    url: '',
    publishedAt: '2026-03-21',
  ),
  _NewsItem(
    title: 'Top 10 BGMI teams of 2026 ranked by win rate',
    source: 'Gaming Hub',
    url: '',
    publishedAt: '2026-03-20',
  ),
];

final _activeTournamentsProvider =
    FutureProvider<List<TournamentEntity>>((ref) async {
  final r = await ref.read(getMyTournamentsUseCaseProvider).call();
  return r.fold(
      (_) => [], (list) => list.where((t) => t.status != 'completed').toList());
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(_activeTournamentsProvider);
    final news = ref.watch(_newsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('PC',
                          style: AppTextStyles.label(
                              color: Colors.black, size: 12)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PointCalc',
                            style: AppTextStyles.heading(size: 16)),
                        Text('Tournament Manager',
                            style: AppTextStyles.body(
                                color: AppColors.muted, size: 11)),
                      ],
                    ),
                    const Spacer(),
                    // Quick create button
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.createTournament),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add,
                                color: Colors.black, size: 16),
                            const SizedBox(width: 4),
                            Text('Create',
                                style: AppTextStyles.label(
                                    color: Colors.black, size: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Active Tournaments ────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text('Active Tournaments',
                    style: AppTextStyles.heading(size: 15)),
              ),
            ),

            tournaments.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ShimmerList(count: 2, itemHeight: 72),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
              data: (list) => list.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bg3,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sports_esports_outlined,
                                  color: AppColors.muted, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No active tournaments. Tap Create to start.',
                                  style: AppTextStyles.body(
                                      color: AppColors.muted, size: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ActiveTournamentCard(tournament: list[i]),
                          ),
                          childCount: list.length,
                        ),
                      ),
                    ),
            ),

            // ── News Feed ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Text('Esports News',
                        style: AppTextStyles.heading(size: 15)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('BGMI',
                          style: AppTextStyles.label(
                              color: AppColors.yellow, size: 9)),
                    ),
                  ],
                ),
              ),
            ),

            news.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ShimmerList(count: 3, itemHeight: 80),
                ),
              ),
              error: (_, __) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _NewsCard(item: _fallbackNews[i]),
                  ),
                  childCount: _fallbackNews.length,
                ),
              ),
              data: (items) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _NewsCard(item: items[i]),
                  ),
                  childCount: items.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

// ── Active Tournament Card ─────────────────────────────────
class _ActiveTournamentCard extends StatelessWidget {
  final TournamentEntity tournament;
  const _ActiveTournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () =>
            context.push('${AppRoutes.tournamentDetail}/${tournament.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tournament.isActive
                ? AppColors.yellow.withValues(alpha: 0.05)
                : AppColors.bg3,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tournament.isActive
                  ? AppColors.yellow.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.bg4,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.emoji_events_outlined,
                    color: AppColors.yellow, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.name,
                        style: AppTextStyles.subheading(
                            color: AppColors.white, size: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '${tournament.gameType.toUpperCase()} · '
                      '${tournament.totalMatches} matches',
                      style:
                          AppTextStyles.body(color: AppColors.muted, size: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('LIVE',
                    style: AppTextStyles.label(
                        color: AppColors.success, size: 10)),
              ),
            ],
          ),
        ),
      );
}

// ── News Card ──────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  final _NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // News icon / image placeholder
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bg4,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.newspaper_outlined,
                  color: AppColors.muted, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.body(color: AppColors.white, size: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(item.source,
                          style: AppTextStyles.label(
                              color: AppColors.yellow, size: 10)),
                      if (item.publishedAt.isNotEmpty) ...[
                        Text('  ·  ',
                            style: AppTextStyles.label(
                                color: AppColors.muted, size: 10)),
                        Text(
                          _fmtDate(item.publishedAt),
                          style: AppTextStyles.label(
                              color: AppColors.muted, size: 10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _fmtDate(String s) {
    try {
      final dt = DateTime.parse(s);
      return DateFormatter.relative(dt);
    } catch (_) {
      return s;
    }
  }
}

class _NewsItem {
  final String title;
  final String source;
  final String url;
  final String? imageUrl;
  final String publishedAt;

  const _NewsItem({
    required this.title,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
  });
}
