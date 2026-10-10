import 'package:flutter/material.dart';

import '../../../data/repositories/article_repository.dart';
import '../../story/ui/story_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.repo});

  final ArticleRepository repo;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    return Scaffold(
      appBar: AppBar(title: const Text('Vreteno')),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          if (repo.loading && repo.stories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: repo.refresh,
            child: ListView.separated(
              itemCount: repo.stories.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final story = repo.stories[i];
                return ListTile(
                  title: Text(
                    story.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    story.sourceIds
                        .map((id) => repo.sourceOf(id).name)
                        .join(', '),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StoryScreen(story: story, repo: repo),
                    ),
                  ),
                  trailing: Text('${story.sourceIds.length}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
