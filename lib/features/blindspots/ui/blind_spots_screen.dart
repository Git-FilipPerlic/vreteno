import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bias_bar.dart';
import '../../../data/models/source.dart';
import '../../../data/repositories/article_repository.dart';
import '../../../services/blind_spots.dart';
import '../../story/ui/story_screen.dart';

class BlindSpotsScreen extends StatelessWidget {
  const BlindSpotsScreen({super.key, required this.repo});

  final ArticleRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.visibility_off_outlined, color: AppColors.crimson),
            SizedBox(width: 8),
            Text('Slepe tačke'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          if (repo.loading && repo.stories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final spots = repo.blindSpots;
          final missed = missedCounts(spots).entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return RefreshIndicator(
            color: AppColors.crimson,
            onRefresh: repo.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                const _Explainer(),
                const SizedBox(height: 12),
                if (missed.isNotEmpty) ...[
                  Text(
                    'Najviše propuštenih priča',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final e in missed)
                        Chip(
                          avatar: Icon(
                            leaningIcon(repo.sourceOf(e.key).leaning),
                            size: 16,
                          ),
                          label: Text(
                            '${repo.sourceOf(e.key).name}  ${e.value}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (spots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('Nema slepih tačaka')),
                  ),
                for (final s in spots) ...[
                  _SpotCard(spot: s, repo: repo),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              'Priče koje je pokrilo više izvora, a neki izvor koji je mogao da ih '
              'objavi to nije učinio. Meri se samo po RSS feedu, pa "nisu" '
              'znači "nije u feedu".',
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot, required this.repo});

  final BlindSpot spot;
  final ArticleRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final side = spot.oneSided;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StoryScreen(story: spot.story, repo: repo),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (side != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Samo izvori: ${side.label}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                spot.story.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              _SourceRow(
                icon: Icons.check_circle_outline,
                label: 'Pokrili',
                sources: spot.covered,
              ),
              const SizedBox(height: 6),
              _SourceRow(
                icon: Icons.remove_circle_outline,
                label: 'Nisu',
                sources: spot.missing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.label,
    required this.sources,
  });

  final IconData icon;
  final String label;
  final List<Source> sources;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.crimson),
        const SizedBox(width: 6),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final s in sources)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: leaningColor(s.leaning),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(s.name),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
