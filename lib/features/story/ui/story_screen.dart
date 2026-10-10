import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/bias_bar.dart';
import '../../../data/models/article.dart';
import '../../../data/models/source.dart';
import '../../../data/models/story.dart';
import '../../../data/repositories/article_repository.dart';
import '../../../services/tone_analysis.dart';

/// Jedna priča: raspodela izvora i članci grupisani po izvoru.
class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key, required this.story, required this.repo});

  final Story story;
  final ArticleRepository repo;

  @override
  Widget build(BuildContext context) {
    final bySource = <String, List<Article>>{};
    for (final a in story.articles) {
      bySource.putIfAbsent(a.sourceId, () => []).add(a);
    }
    final covered = repo.sources
        .where((s) => bySource.containsKey(s.id))
        .toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Priča'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            story.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.newspaper, size: 16, color: AppColors.crimson),
              const SizedBox(width: 4),
              Text(
                '${covered.length} izvora, ${story.articles.length} članaka',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 16, color: AppColors.inkSoft),
              const SizedBox(width: 4),
              Text(timeAgo(story.latest), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.crimsonPale,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.balance,
                      size: 18,
                      color: AppColors.crimson,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ko je pokrio priču',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                BiasBar(sources: covered, height: 10, showLegend: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final s in covered)
            _SourceSection(source: s, articles: bySource[s.id]!),
        ],
      ),
    );
  }
}

class _SourceSection extends StatelessWidget {
  const _SourceSection({required this.source, required this.articles});

  final Source source;
  final List<Article> articles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: leaningColor(source.leaning),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    source.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: source.rationale.isEmpty
                        ? 'Nema javno dostupne ocene'
                        : source.rationale,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.crimsonPale,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(leaningIcon(source.leaning), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            source.leaning.label,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              for (final a in articles) ...[
                const Divider(height: 24),
                _ArticleTile(article: a),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

IconData _toneIcon(ToneLevel l) => switch (l) {
  ToneLevel.neutral => Icons.sentiment_neutral,
  ToneLevel.emphasized => Icons.priority_high,
  ToneLevel.sensational => Icons.local_fire_department,
};

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final tone = analyzeTone(article);
    final theme = Theme.of(context);
    final toneColor = switch (tone.level) {
      ToneLevel.neutral => AppColors.inkSoft,
      ToneLevel.emphasized => const Color(0xFFB26A00),
      ToneLevel.sensational => AppColors.crimson,
    };
    final notes = [
      if (tone.capsWords > 0) 'VELIKA SLOVA ×${tone.capsWords}',
      if (tone.exclamations > 0) 'uzvičnici ×${tone.exclamations}',
      if (tone.quotes > 0) 'citati ×${tone.quotes}',
      if (tone.loadedWords.isNotEmpty)
        'nabijene reči: ${tone.loadedWords.join(', ')}',
    ];
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(article.url),
        mode: LaunchMode.externalApplication,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  article.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new, size: 18, color: AppColors.inkSoft),
            ],
          ),
          if (article.summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              article.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_toneIcon(tone.level), size: 16, color: toneColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  [tone.level.label, ...notes].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: toneColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
