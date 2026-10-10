import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/bias_bar.dart';
import '../../../data/models/story.dart';
import '../../../data/repositories/article_repository.dart';
import '../../story/ui/story_screen.dart';

enum _Filter { all, many, oneSided }

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.repo});

  final ArticleRepository repo;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  _Filter _filter = _Filter.all;

  List<Story> _visible(ArticleRepository repo) {
    switch (_filter) {
      case _Filter.all:
        return repo.stories;
      case _Filter.many:
        return repo.stories.where((s) => s.sourceIds.length >= 3).toList();
      case _Filter.oneSided:
        final oneSided = {
          for (final b in repo.blindSpots)
            if (b.oneSided != null) b.story,
        };
        return repo.stories.where(oneSided.contains).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.layers_outlined, color: AppColors.crimson),
            SizedBox(width: 8),
            Text('Vreteno'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          if (repo.loading && repo.stories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final stories = _visible(repo);
          return RefreshIndicator(
            color: AppColors.crimson,
            onRefresh: repo.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                _filters(),
                const SizedBox(height: 8),
                if (stories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: Text('Nema priča za ovaj filter')),
                  ),
                for (final s in stories) ...[
                  _StoryCard(story: s, repo: repo),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filters() {
    Widget chip(_Filter f, IconData icon, String label) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: AppColors.crimson),
        label: Text(label),
        selected: _filter == f,
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: AppColors.crimsonPale,
        side: const BorderSide(color: AppColors.crimsonLine),
        onSelected: (_) => setState(() => _filter = f),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_Filter.all, Icons.dynamic_feed, 'Sve'),
          chip(_Filter.many, Icons.groups_outlined, '3+ izvora'),
          chip(_Filter.oneSided, Icons.contrast, 'Jednostrane'),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.repo});

  final Story story;
  final ArticleRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sources = [for (final id in story.sourceIds) repo.sourceOf(id)];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StoryScreen(story: story, repo: repo),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
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
                        const Icon(
                          Icons.newspaper,
                          size: 14,
                          color: AppColors.crimson,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${sources.length} ${sources.length == 1 ? 'izvor' : 'izvora'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppColors.inkSoft,
                  ),
                  const SizedBox(width: 4),
                  Text(timeAgo(story.latest), style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                story.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              if (sources.length > 1) ...[
                const SizedBox(height: 12),
                BiasBar(sources: sources),
              ],
              const SizedBox(height: 10),
              Text(
                sources.map((s) => s.name).join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
