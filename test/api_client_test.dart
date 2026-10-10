import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vreteno/data/models/source.dart';
import 'package:vreteno/data/repositories/article_repository.dart';
import 'package:vreteno/data/sources/api_client.dart';
import 'package:vreteno/data/sources/feed_client.dart';

const _feed = {
  'sources': [
    {
      'id': 'n1info.rs',
      'domain': 'n1info.rs',
      'country': 'RS',
      'bias_label': null,
    },
    {'id': 'pink.rs', 'domain': 'pink.rs', 'country': 'RS', 'bias_label': null},
    {
      'id': 'klix.ba',
      'domain': 'klix.ba',
      'country': 'BA',
      'bias_label': 'mixed',
    },
    {
      'id': 'xx.rs',
      'domain': 'xx.rs',
      'country': 'RS',
      'bias_label': 'critical',
    },
  ],
  'stories': [
    {
      'id': 1,
      'articles': [
        {
          'source': 'pink.rs',
          'title': 'B',
          'url': 'u2',
          'summary': '',
          'published_at': '2026-10-10T08:00:00+00:00',
        },
        {
          'source': 'n1info.rs',
          'title': 'A',
          'url': 'u1',
          'summary': 's',
          'published_at': '2026-10-10T07:00:00+00:00',
        },
      ],
    },
    {'id': 2, 'articles': []},
  ],
};

void main() {
  test('parses server feed, applies ratings and manual bias labels', () {
    final feed = parseFeed(jsonEncode(_feed));
    expect(feed.stories, hasLength(1)); // empty story dropped
    expect(feed.stories.single.title, 'B'); // newest first

    Source s(String id) => feed.sources.firstWhere((x) => x.id == id);
    expect(s('n1info.rs').name, 'N1');
    expect(s('n1info.rs').leaning, Leaning.critical);
    expect(s('pink.rs').leaning, Leaning.proGovernment);
    expect(s('klix.ba').leaning, Leaning.mixed); // manual label
    expect(s('klix.ba').country, 'BA');
    expect(s('xx.rs').rationale, 'Ručno uneta ocena.');
  });

  test('repository uses the server when it answers', () async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient(
        (_) async => http.Response.bytes(utf8.encode(jsonEncode(_feed)), 200),
      ),
    );
    final repo = ArticleRepository(api: api);
    await repo.refresh();
    expect(repo.mode, DataMode.server);
    expect(repo.stories, hasLength(1));
    expect(repo.sourceOf('pink.rs').name, 'Pink');
  });

  test('repository falls back to direct RSS when the server is down', () async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async => http.Response('no', 500)),
    );
    final rss = MockClient(
      (_) async => http.Response(
        '<rss><channel><item><title>T</title><link>https://x.rs/1</link></item></channel></rss>',
        200,
      ),
    );
    final repo = ArticleRepository(
      api: api,
      client: FeedClient(client: rss),
    );
    await repo.refresh();
    expect(repo.mode, DataMode.direct);
    expect(repo.stories, isNotEmpty);
  });
}
