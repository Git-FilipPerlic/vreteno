import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/article.dart';
import '../../../data/models/source.dart';
import '../../../data/models/story.dart';
import '../../../data/repositories/article_repository.dart';
import '../../../services/tone_analysis.dart';

/// Jedna priča: članci grupisani po izvoru, da se vidi kako ko piše o istom.
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
    final covered = repo.sources.where((s) => bySource.containsKey(s.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Priča')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(story.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${story.articles.length} članaka, ${story.sourceIds.length} izvora',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(source.name, style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Tooltip(
                message: source.rationale.isEmpty
                    ? 'Nema javno dostupne ocene'
                    : source.rationale,
                child: Chip(
                  label: Text(source.leaning.label),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          for (final a in articles) _ArticleTile(article: a),
        ],
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final tone = analyzeTone(article);
    final theme = Theme.of(context);
    final notes = [
      tone.level.label,
      if (tone.capsWords > 0) 'VELIKA SLOVA ×${tone.capsWords}',
      if (tone.exclamations > 0) 'uzvičnici ×${tone.exclamations}',
      if (tone.quotes > 0) 'citati ×${tone.quotes}',
      if (tone.loadedWords.isNotEmpty)
        'nabijene reči: ${tone.loadedWords.join(', ')}',
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(article.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.summary.isNotEmpty)
            Text(article.summary, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            notes.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: switch (tone.level) {
                ToneLevel.neutral => theme.colorScheme.outline,
                ToneLevel.emphasized => theme.colorScheme.tertiary,
                ToneLevel.sensational => theme.colorScheme.error,
              },
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => launchUrl(
        Uri.parse(article.url),
        mode: LaunchMode.externalApplication,
      ),
    );
  }
}
