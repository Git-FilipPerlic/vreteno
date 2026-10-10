import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bias_bar.dart';
import '../../../data/models/source.dart';
import '../../../data/repositories/article_repository.dart';

/// Spisak izvora sa ocenom, obrazloženjem i linkom na javni izvor ocene.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key, required this.repo});

  final ArticleRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.library_books_outlined, color: AppColors.crimson),
            SizedBox(width: 8),
            Text('Izvori'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.crimsonPale,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.crimson),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ocene ne potiču od nas. Preuzete su iz javnih izvora '
                    '(Reuters Institute, Media Ownership Monitor) i označene su linkom. '
                    'Gde izvor nije ocenjen, piše "nepoznato".',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final s in repo.sources) ...[
            _SourceCard(source: s),
            const SizedBox(height: 10),
          ],
          Text(
            'Boje: ${Leaning.values.map((l) => l.label).join(', ')}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final Source source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
                Icon(leaningIcon(source.leaning), size: 16),
                const SizedBox(width: 4),
                Text(source.leaning.label, style: theme.textTheme.labelMedium),
              ],
            ),
            if (source.rationale.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(source.rationale, style: theme.textTheme.bodySmall),
            ],
            if (source.evidence.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse(source.evidence),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 16, color: AppColors.crimson),
                    SizedBox(width: 4),
                    Text(
                      'Javni izvor ocene',
                      style: TextStyle(
                        color: AppColors.crimson,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
