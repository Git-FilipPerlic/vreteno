import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vreteno/data/repositories/article_repository.dart';
import 'package:vreteno/data/sources/feed_client.dart';
import 'package:vreteno/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('feed shows articles', (tester) async {
    final mock = MockClient(
      (_) async => http.Response(
        '<rss><channel><item><title>Probna vest</title><link>https://x.rs/1</link></item></channel></rss>',
        200,
      ),
    );
    final repo = ArticleRepository(client: FeedClient(client: mock));
    await tester.pumpWidget(VretenoApp(repo: repo));
    await tester.pumpAndSettle();
    expect(find.text('Probna vest'), findsWidgets);
  });

  testWidgets('tapping a story opens its detail', (tester) async {
    final mock = MockClient(
      (_) async => http.Response(
        '<rss><channel><item><title>Probna vest</title><link>https://x.rs/1</link></item></channel></rss>',
        200,
      ),
    );
    final repo = ArticleRepository(client: FeedClient(client: mock));
    await tester.pumpWidget(VretenoApp(repo: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probna vest').first);
    await tester.pumpAndSettle();
    expect(find.text('Priča'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsWidgets);
  });
}
