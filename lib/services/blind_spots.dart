import '../data/models/article.dart';
import '../data/models/source.dart';
import '../data/models/story.dart';
import 'text_normalizer.dart';

/// Priča koju su neki izvori pokrili, a neki (koji su mogli) nisu.
class BlindSpot {
  const BlindSpot({
    required this.story,
    required this.covered,
    required this.missing,
    this.oneSided,
  });

  final Story story;
  final List<Source> covered;
  final List<Source> missing;

  /// Postavljeno kad priču pokrivaju izvori samo jedne strane (vlada/kritični),
  /// a neki izvor suprotne strane je propustio.
  final Leaning? oneSided;
}

/// Nalazi slepe tačke.
///
/// Izvor se računa kao "mogao je da pokrije" priču samo ako njegov feed seže
/// unazad bar do najstarijeg članka priče; inače bi kratak feed (npr. samo
/// današnje vesti) izgledao kao da ignoriše stare teme.
///
/// Izvori sa retkim objavljivanjem (nedeljnici, spor feed) ne računaju se kao
/// da su "propustili" priču: potrebno je bar [minPerDay] članaka dnevno u feedu.
///
/// Priča ulazi tek kad je pokrilo bar [minCovered] izvora, i ako nije
/// nepolitička tema (sport, saobraćaj, vreme...), osim ako [politicalOnly]
/// nije isključen.
List<BlindSpot> findBlindSpots(
  List<Story> stories,
  List<Source> sources,
  List<Article> allArticles, {
  int minCovered = 3,
  double minPerDay = 5,
  bool politicalOnly = true,
}) {
  final oldest = <String, DateTime>{};
  final newest = <String, DateTime>{};
  final counts = <String, int>{};
  for (final a in allArticles) {
    counts[a.sourceId] = (counts[a.sourceId] ?? 0) + 1;
    final t = a.publishedAt;
    if (t == null) continue;
    final o = oldest[a.sourceId];
    if (o == null || t.isBefore(o)) oldest[a.sourceId] = t;
    final n = newest[a.sourceId];
    if (n == null || t.isAfter(n)) newest[a.sourceId] = t;
  }
  final active = <String>{
    for (final id in oldest.keys)
      if (_perDay(counts[id]!, oldest[id]!, newest[id]!) >= minPerDay) id,
  };

  final out = <BlindSpot>[];
  for (final story in stories) {
    final ids = story.sourceIds;
    if (ids.length < minCovered) continue;
    if (politicalOnly && _isNonPolitical(story)) continue;

    final times = story.articles
        .map((a) => a.publishedAt)
        .whereType<DateTime>();
    final storyStart = times.isEmpty
        ? null
        : times.reduce((a, b) => a.isBefore(b) ? a : b);

    final covered = sources.where((s) => ids.contains(s.id)).toList();
    final missing = sources.where((s) {
      if (ids.contains(s.id) || !active.contains(s.id)) return false;
      final from = oldest[s.id]!;
      return storyStart == null || !storyStart.isBefore(from);
    }).toList();
    if (missing.isEmpty) continue;

    // Strane su samo proVlada i kritican; mesoviti i nepoznati ne ulaze.
    final sides = covered
        .map((s) => s.leaning)
        .where((l) => l == Leaning.proGovernment || l == Leaning.critical)
        .toSet();
    Leaning? side;
    if (sides.length == 1) {
      final other = sides.first == Leaning.proGovernment
          ? Leaning.critical
          : Leaning.proGovernment;
      if (missing.any((s) => s.leaning == other)) side = sides.first;
    }
    out.add(
      BlindSpot(
        story: story,
        covered: covered,
        missing: missing,
        oneSided: side,
      ),
    );
  }

  // Jednostrane prve, pa po tome koliko je izvora propustilo.
  out.sort((a, b) {
    final s = (b.oneSided != null ? 1 : 0) - (a.oneSided != null ? 1 : 0);
    return s != 0 ? s : b.missing.length.compareTo(a.missing.length);
  });
  return out;
}

/// Koliko je priča svaki izvor propustio (id -> broj).
Map<String, int> missedCounts(List<BlindSpot> spots) {
  final m = <String, int>{};
  for (final s in spots) {
    for (final src in s.missing) {
      m[src.id] = (m[src.id] ?? 0) + 1;
    }
  }
  return m;
}

double _perDay(int n, DateTime oldest, DateTime newest) {
  // Najmanje 6 h raspona, da brz feed od nekoliko stavki ne dobije beskonačnu stopu.
  final days = newest.difference(oldest).inMinutes / (60 * 24);
  return n / (days < 0.25 ? 0.25 : days);
}

/// Grube oznake tema koje nisu političke. Lista je namerno kratka i lako se menja.
const _nonPolitical = {
  'sport',
  'fudbal',
  'kosark',
  'tenis',
  'rukomet',
  'odbojk',
  'utakm',
  'derbi',
  'saobrac',
  'kolovoz',
  'prognoz',
  'vremens',
  'horoskop',
  'zadusn',
  'recept',
  'estrad',
  'pevac',
  'serij',
  'rijalit',
  'zadruga',
  'tuci',
  'saobra',
};

bool _isNonPolitical(Story story) {
  for (final a in story.articles) {
    final text = transliterate('${a.title} ${a.summary}');
    if (_nonPolitical.any(text.contains)) return true;
  }
  return false;
}
