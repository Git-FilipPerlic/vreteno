import 'package:flutter/material.dart';

import '../../../data/repositories/article_repository.dart';
import '../../story/ui/story_screen.dart';
import '../../../services/blind_spots.dart';

class BlindSpotsScreen extends StatelessWidget {
  const BlindSpotsScreen({super.key, required this.repo});

  final ArticleRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slepe tačke')),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          if (repo.loading && repo.stories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final spots = repo.blindSpots;
          if (spots.isEmpty) {
            return const Center(child: Text('Nema slepih tačaka'));
          }
          final missed = missedCounts(spots).entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final e in missed)
                      Chip(
                        label: Text('${repo.sourceOf(e.key).name}: ${e.value}'),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Broj priča koje je izvor propustio, a druge su pokrile.',
                ),
              ),
              const Divider(),
              for (final s in spots) _SpotTile(spot: s, repo: repo),
            ],
          );
        },
      ),
    );
  }
}

class _SpotTile extends StatelessWidget {
  const _SpotTile({required this.spot, required this.repo});

  final BlindSpot spot;
  final ArticleRepository repo;

  @override
  Widget build(BuildContext context) {
    final side = spot.oneSided;
    return ListTile(
      title: Text(
        spot.story.title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Pokrili: ${spot.covered.map((s) => s.name).join(', ')}\n'
        'Nisu: ${spot.missing.map((s) => s.name).join(', ')}',
      ),
      isThreeLine: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoryScreen(story: spot.story, repo: repo),
        ),
      ),
      trailing: side == null
          ? null
          : Tooltip(
              message: 'Pokrivaju je samo izvori: ${side.label}',
              child: const Icon(Icons.warning_amber),
            ),
    );
  }
}
