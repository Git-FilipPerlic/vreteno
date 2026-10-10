import 'package:flutter_test/flutter_test.dart';
import 'package:vreteno/data/sources/rss_parser.dart';

void main() {
  test('parses RSS 2.0', () {
    const xml = '''<rss version="2.0"><channel>
<item><title>Naslov</title><link>https://x.rs/a</link>
<description>&lt;p&gt;Tekst &lt;b&gt;vesti&lt;/b&gt;&lt;/p&gt;</description>
<pubDate>Sat, 10 Oct 2026 08:30:00 +0200</pubDate></item>
<item><title></title><link>https://x.rs/b</link></item>
</channel></rss>''';
    final a = parseFeed(xml, sourceId: 's');
    expect(a, hasLength(1));
    expect(a.first.title, 'Naslov');
    expect(a.first.summary, 'Tekst vesti');
    expect(a.first.publishedAt, DateTime.utc(2026, 10, 10, 6, 30));
  });

  test('parses Atom', () {
    const xml = '''<feed xmlns="http://www.w3.org/2005/Atom"><entry>
<title>Atom naslov</title><link href="https://y.rs/1"/>
<summary>Sažetak</summary><updated>2026-10-10T08:00:00Z</updated></entry></feed>''';
    final a = parseFeed(xml, sourceId: 's');
    expect(a.single.url, 'https://y.rs/1');
    expect(a.single.publishedAt, DateTime.utc(2026, 10, 10, 8));
  });
}
