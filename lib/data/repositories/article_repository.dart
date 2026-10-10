import 'package:flutter/foundation.dart';

import '../../core/config.dart';
import '../../services/blind_spots.dart';
import '../../services/clustering.dart';
import '../models/article.dart';
import '../models/source.dart';
import '../models/story.dart';
import '../sources/api_client.dart';
import '../sources/default_sources.dart';
import '../sources/feed_client.dart';

/// Odakle su trenutni podaci.
enum DataMode {
  /// Još nije ništa učitano.
  none,

  /// Sa Vreteno servera (kolektor + klasterovanje, 50+ izvora).
  server,

  /// Direktno iz RSS-a (rezerva kad server nije dostupan).
  direct,
}

/// Drži trenutne priče i osvežava ih: prvo sa servera, pa direktnim RSS-om.
class ArticleRepository extends ChangeNotifier {
  ArticleRepository({FeedClient? client, ApiClient? api, List<Source>? sources})
    : _client = client ?? FeedClient(),
      _api = api ?? ApiClient(baseUrl: apiBaseUrl),
      sources = sources ?? defaultSources;

  final FeedClient _client;
  final ApiClient _api;

  /// Izvori trenutnog režima (sa servera ili ugrađeni).
  List<Source> sources;

  List<Article> articles = const [];
  List<Story> stories = const [];
  List<BlindSpot> blindSpots = const [];
  bool loading = false;
  DataMode mode = DataMode.none;

  Source sourceOf(String id) => sources.firstWhere(
    (s) => s.id == id,
    orElse: () => Source(id: id, name: id, feedUrl: ''),
  );

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      await _loadFromServer();
    } catch (_) {
      await _loadDirect();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _loadFromServer() async {
    final feed = await _api.fetchFeed();
    if (feed.stories.isEmpty) throw StateError('server returned no stories');
    sources = feed.sources;
    stories = feed.stories;
    articles = [for (final s in feed.stories) ...s.articles];
    blindSpots = findBlindSpots(stories, sources, articles);
    mode = DataMode.server;
  }

  Future<void> _loadDirect() async {
    sources = defaultSources;
    final all = await _client.fetchAll(sources);
    all.sort(
      (a, b) => (b.publishedAt ?? DateTime(0)).compareTo(
        a.publishedAt ?? DateTime(0),
      ),
    );
    articles = all;
    stories = clusterArticles(all)
      ..sort((a, b) => b.sourceIds.length.compareTo(a.sourceIds.length));
    blindSpots = findBlindSpots(stories, sources, all);
    mode = DataMode.direct;
  }
}
