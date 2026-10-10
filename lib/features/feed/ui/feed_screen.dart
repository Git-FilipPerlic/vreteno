import 'package:flutter/material.dart';

import '../../../data/repositories/article_repository.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.repo});

  final ArticleRepository repo;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    widget.repo.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    return Scaffold(
      appBar: AppBar(title: const Text('Vreteno')),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          if (repo.loading && repo.articles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: repo.refresh,
            child: ListView.separated(
              itemCount: repo.articles.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = repo.articles[i];
                return ListTile(
                  title: Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis),
                  subtitle: Text(repo.sourceOf(a.sourceId).name),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
