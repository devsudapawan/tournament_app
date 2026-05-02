// lib/presentation/features/home/news_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NewsDetailPage extends ConsumerStatefulWidget {
  final dynamic news;
  const NewsDetailPage({super.key, required this.news});

  @override
  ConsumerState<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends ConsumerState<NewsDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing header with image ───────────
          SliverAppBar(
            expandedHeight: widget.news.imageUrl != null ? 220 : 0,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
            actions: [
              // Share / copy URL button
              GestureDetector(
                onTap: () {
                  if (widget.news.url != null && (widget.news.url as String).isNotEmpty) {
                    Clipboard.setData(
                        ClipboardData(text: widget.news.url as String));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.link,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
            flexibleSpace: widget.news.imageUrl != null
                ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.news.imageUrl as String,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.bg3,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.muted,
                        size: 40,
                      ),
                    ),
                  ),
                  // Gradient overlay so text is readable
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
                : null,
          ),

          // ── Content ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Source + date row ──────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.yellow.withOpacity(0.3)),
                        ),
                        child: Text(
                          (widget.news.source as String?)?.toUpperCase() ?? 'NEWS',
                          style: AppTextStyles.label(
                              color: AppColors.yellow, size: 9),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (widget.news.publishedAt != null &&
                          (widget.news.publishedAt as String).isNotEmpty)
                        Text(
                          _formatDate(widget.news.publishedAt as String),
                          style: AppTextStyles.body(
                              color: AppColors.muted, size: 11),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Title ──────────────────────────
                  Text(
                    (widget.news.title as String?) ?? '',
                    style: AppTextStyles.heading(size: 20),
                  ),

                  const SizedBox(height: 16),

                  // ── Divider ────────────────────────
                  Container(
                    height: 1,
                    color: AppColors.border,
                  ),

                  const SizedBox(height: 16),

                  // ── Description ────────────────────
                  if (widget.news.description != null &&
                      (widget.news.description as String).isNotEmpty) ...[
                    Text(
                      widget.news.description as String,
                      style: AppTextStyles.body(
                          color: AppColors.white, size: 15),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Content ────────────────────────
                  if (widget.news.content != null &&
                      (widget.news.content as String).isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        _cleanContent(widget.news.content as String),
                        style: AppTextStyles.body(
                            color: AppColors.grey, size: 14),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Read full article hint ─────────
                  if (widget.news.url != null &&
                      (widget.news.url as String).isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.news.url as String));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Link copied — open in your browser'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.yellow.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.open_in_new,
                                color: AppColors.yellow, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tap to copy link and read the full article',
                                style: AppTextStyles.body(
                                    color: AppColors.yellow, size: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// GNews appends "[N chars]" to content — strip it
  String _cleanContent(String raw) {
    final idx = raw.lastIndexOf('[');
    if (idx > 0) return raw.substring(0, idx).trim();
    return raw;
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}