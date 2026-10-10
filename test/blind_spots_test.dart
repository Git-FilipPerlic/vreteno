import 'package:flutter_test/flutter_test.dart';
import 'package:vreteno/data/models/article.dart';
import 'package:vreteno/data/models/source.dart';
import 'package:vreteno/data/models/story.dart';
import 'package:vreteno/services/blind_spots.dart';

Article a(String src, int h) => Article(
  sourceId: src,
  title: 't$src$h',
  url: 'u$src$h',
  publishedAt: DateTime.utc(2026, 10, 10).add(Duration(hours: h)),
);

Source s(String id, Leaning l) =>
    Source(id: id, name: id.toUpperCase(), feedUrl: '', leaning: l);

void main() {
  final sources = [
    s('p1', Leaning.pro),
    s('p2', Leaning.pro),
    s('a1', Leaning.anti),
    s('a2', Leaning.anti),
    s('x', Leaning.unknown),
  ];
  // Svi izvori imaju članke od sata 0, pa su svi "aktivni".
  final base = [
    for (final id in ['p1', 'p2', 'a1', 'a2', 'x']) a(id, 0),
  ];

  test('flags one-sided story', () {
    final story = Story([a('p1', 5), a('p2', 6)]);
    final spots = findBlindSpots([story], sources, base);
    expect(spots, hasLength(1));
    expect(spots.first.oneSided, Leaning.pro);
    expect(
      spots.first.missing.map((e) => e.id),
      containsAll(['a1', 'a2', 'x']),
    );
  });

  test('story covered by both sides is not one-sided', () {
    final story = Story([a('p1', 5), a('a1', 6)]);
    final spots = findBlindSpots([story], sources, base);
    expect(spots.first.oneSided, isNull);
  });

  test('ignores single-source stories and fully covered ones', () {
    final single = Story([a('p1', 5)]);
    final all = Story([
      for (final id in ['p1', 'p2', 'a1', 'a2', 'x']) a(id, 5),
    ]);
    expect(findBlindSpots([single, all], sources, base), isEmpty);
  });

  test('source whose feed starts later could not have covered older story', () {
    final late = [
      for (final id in ['p1', 'p2', 'a1', 'a2']) a(id, 0),
      a('x', 20),
    ];
    final story = Story([a('p1', 5), a('p2', 6)]);
    final spots = findBlindSpots([story], sources, late);
    expect(spots.first.missing.map((e) => e.id), isNot(contains('x')));
  });
}
