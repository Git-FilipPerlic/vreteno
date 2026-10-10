import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../models/source.dart';
import '../sources/default_sources.dart';
import '../sources/feed_client.dart';

/// Drži trenutne članke i osvežava ih sa svih izvora.
class ArticleRepository extends ChangeNotifier {
  ArticleRepository({FeedClient? client, this.sources = defaultSources})
      : _client = client ?? FeedClient();

  final FeedClient _client;
  final List<Source> sources;

  List<Article> articles = const [];
  bool loading = false;

  Source sourceOf(String id) => sources.firstWhere((s) => s.id == id);

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    final all = await _client.fetchAll(sources);
    all.sort((a, b) => (b.publishedAt ?? DateTime(0))
        .compareTo(a.publishedAt ?? DateTime(0)));
    articles = all;
    loading = false;
    notifyListeners();
  }
}
