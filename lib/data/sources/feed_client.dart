import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import '../models/source.dart';
import 'rss_parser.dart';

class FeedClient {
  FeedClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Article>> fetch(Source source) async {
    final res = await _client
        .get(Uri.parse(source.feedUrl))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw http.ClientException(
        'HTTP ${res.statusCode}',
        Uri.parse(source.feedUrl),
      );
    }
    return parseFeed(
      utf8.decode(res.bodyBytes, allowMalformed: true),
      sourceId: source.id,
    );
  }

  /// Povlači sve izvore paralelno; izvor koji pukne se preskače.
  Future<List<Article>> fetchAll(List<Source> sources) async {
    final lists = await Future.wait(
      sources.map((s) => fetch(s).catchError((_) => <Article>[])),
    );
    return lists.expand((l) => l).toList();
  }
}
