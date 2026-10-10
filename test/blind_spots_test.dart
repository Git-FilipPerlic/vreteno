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
    s('p1', Leaning.proGovernment),
    s('p2', Leaning.proGovernment),
    s('a1', Leaning.critical),
    s('a2', Leaning.critical),
    s('x', Leaning.unknown),
  ];
  // Svi izvori imaju članke od sata 0, pa su svi "aktivni".
  final base = [
    for (final id in ['p1', 'p2', 'a1', 'a2', 'x']) a(id, 0),
  ];

  test('flags one-sided story', () {
    final story = Story([a('p1', 5), a('p2', 6)]);
    final spots = findBlindSpots(
      [story],
      sources,
      base,
      minCovered: 2,
      minPerDay: 0,
    );
    expect(spots, hasLength(1));
    expect(spots.first.oneSided, Leaning.proGovernment);
    expect(
      spots.first.missing.map((e) => e.id),
      containsAll(['a1', 'a2', 'x']),
    );
  });

  test('story covered by both sides is not one-sided', () {
    final story = Story([a('p1', 5), a('a1', 6)]);
    final spots = findBlindSpots(
      [story],
      sources,
      base,
      minCovered: 2,
      minPerDay: 0,
    );
    expect(spots.first.oneSided, isNull);
  });

  test('ignores single-source stories and fully covered ones', () {
    final single = Story([a('p1', 5)]);
    final all = Story([
      for (final id in ['p1', 'p2', 'a1', 'a2', 'x']) a(id, 5),
    ]);
    expect(
      findBlindSpots([single, all], sources, base, minCovered: 2, minPerDay: 0),
      isEmpty,
    );
  });

  test('source whose feed starts later could not have covered older story', () {
    final late = [
      for (final id in ['p1', 'p2', 'a1', 'a2']) a(id, 0),
      a('x', 20),
    ];
    final story = Story([a('p1', 5), a('p2', 6)]);
    final spots = findBlindSpots(
      [story],
      sources,
      late,
      minCovered: 2,
      minPerDay: 0,
    );
    expect(spots.first.missing.map((e) => e.id), isNot(contains('x')));
  });

  test('slow-publishing source is not blamed for missing a story', () {
    // x ima 2 članka u 10 dana: nedeljnik.
    final feed = [
      for (final id in ['p1', 'p2', 'a1', 'a2'])
        for (var h = 0; h < 60; h++) a(id, h),
      a('x', 0),
      a('x', 240),
    ];
    final story = Story([a('p1', 50), a('p2', 51), a('a1', 52)]);
    final spots = findBlindSpots([story], sources, feed);
    expect(
      spots.expand((e) => e.missing).map((e) => e.id),
      isNot(contains('x')),
    );
  });

  test('non-political stories are skipped', () {
    final sport = Story([
      Article(sourceId: 'p1', title: 'Zvezda pobedila u derbiju', url: '1'),
      Article(
        sourceId: 'p2',
        title: 'Derbi: Zvezda savladala Partizan',
        url: '2',
      ),
      Article(sourceId: 'a1', title: 'Fudbal: Zvezda slavi', url: '3'),
    ]);
    expect(findBlindSpots([sport], sources, base, minPerDay: 0), isEmpty);
  });
}
