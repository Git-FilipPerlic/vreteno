import 'package:xml/xml.dart';

import '../models/article.dart';

/// Parsira RSS 2.0 i Atom feed u listu članaka.
List<Article> parseFeed(String xml, {required String sourceId}) {
  final doc = XmlDocument.parse(xml);
  final items = doc.findAllElements('item').toList();
  final entries = items.isEmpty ? doc.findAllElements('entry').toList() : items;

  final out = <Article>[];
  for (final e in entries) {
    final title = _unescape(_text(e, 'title'));
    final url = _link(e);
    if (title.isEmpty || url.isEmpty) continue;
    out.add(
      Article(
        sourceId: sourceId,
        title: title,
        url: url,
        summary: _unescape(
          _strip(
            _text(e, 'description').isNotEmpty
                ? _text(e, 'description')
                : _text(e, 'summary'),
          ),
        ),
        publishedAt: _date(
          _text(e, 'pubDate').isNotEmpty
              ? _text(e, 'pubDate')
              : _text(e, 'updated'),
        ),
      ),
    );
  }
  return out;
}

String _text(XmlElement e, String name) =>
    e.getElement(name)?.innerText.trim() ?? '';

String _link(XmlElement e) {
  final l = e.getElement('link');
  if (l == null) return '';
  final href = l.getAttribute('href'); // Atom
  return (href ?? l.innerText).trim();
}

String _strip(String html) => html
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

const _months = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

/// ISO 8601 (Atom) ili RFC 822 (RSS), npr. "Tue, 10 Oct 2026 08:30:00 +0200".
DateTime? _date(String s) {
  if (s.isEmpty) return null;
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;
  final m = RegExp(
    r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|GMT|UTC|Z)?',
  ).firstMatch(s);
  if (m == null) return null;
  final month = _months.indexOf(m[2]!.toLowerCase()) + 1;
  if (month == 0) return null;
  var d = DateTime.utc(
    int.parse(m[3]!),
    month,
    int.parse(m[1]!),
    int.parse(m[4]!),
    int.parse(m[5]!),
    int.parse(m[6] ?? '0'),
  );
  final tz = m[7];
  if (tz != null && (tz.startsWith('+') || tz.startsWith('-'))) {
    final off = Duration(
      hours: int.parse(tz.substring(1, 3)),
      minutes: int.parse(tz.substring(3)),
    );
    d = tz.startsWith('+') ? d.subtract(off) : d.add(off);
  }
  return d;
}

/// Neki feedovi su dvostruko enkodovani (npr. `&amp;quot;` -> `&quot;`).
String _unescape(String s) => s
    .replaceAll('&quot;', '"')
    .replaceAll('&#039;', "'")
    .replaceAll('&#8220;', '„')
    .replaceAll('&#8221;', '"')
    .replaceAll('&#8211;', '–')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&');
