import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import '../models/source.dart';
import '../models/story.dart';
import 'ratings.dart';

class ApiFeed {
  const ApiFeed({required this.sources, required this.stories});

  final List<Source> sources;
  final List<Story> stories;
}

/// Čita /api/feed sa Vreteno servera (collector/server.py).
class ApiClient {
  ApiClient({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<ApiFeed> fetchFeed({int days = 2}) async {
    final uri = Uri.parse('$baseUrl/api/feed?days=$days');
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', uri);
    }
    return parseFeed(utf8.decode(res.bodyBytes));
  }
}

ApiFeed parseFeed(String body) {
  final json = jsonDecode(body) as Map<String, dynamic>;

  final sources = <Source>[
    for (final s in json['sources'] as List<dynamic>)
      _source(s as Map<String, dynamic>),
  ];

  final stories = <Story>[
    for (final s in json['stories'] as List<dynamic>)
      Story([
        for (final a
            in (s as Map<String, dynamic>)['articles'] as List<dynamic>)
          Article(
            sourceId: (a as Map<String, dynamic>)['source'] as String,
            title: a['title'] as String,
            url: a['url'] as String,
            summary: (a['summary'] as String?) ?? '',
            publishedAt: DateTime.tryParse(
              (a['published_at'] as String?) ?? '',
            ),
          ),
      ]),
  ].where((s) => s.articles.isNotEmpty).toList();

  stories.sort((a, b) {
    final c = b.sourceIds.length.compareTo(a.sourceIds.length);
    if (c != 0) return c;
    return (b.latest ?? DateTime(0)).compareTo(a.latest ?? DateTime(0));
  });
  return ApiFeed(sources: sources, stories: stories);
}

Source _source(Map<String, dynamic> j) {
  final domain = j['domain'] as String;
  final rating = ratingsByDomain[domain];
  // Ocena ručno upisana u bazi (bias_label) ima prednost nad ugrađenom.
  final manual = leaningFromLabel(j['bias_label'] as String?);
  final leaning = manual ?? rating?.leaning ?? Leaning.unknown;
  return Source(
    id: j['id'] as String? ?? domain,
    name: rating?.name ?? domain,
    feedUrl: '',
    leaning: leaning,
    rationale: manual != null && rating == null
        ? 'Ručno uneta ocena.'
        : rating?.rationale ?? '',
    evidence: rating?.evidence ?? '',
    country: (j['country'] as String?) ?? '',
  );
}
