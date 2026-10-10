import '../data/models/article.dart';
import '../data/models/source.dart';
import '../data/models/story.dart';

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

  /// Postavljeno kad su svi izvori koji su pokrili priču iste poznate
  /// orijentacije, a izvori suprotne su je propustili.
  final Leaning? oneSided;
}

/// Nalazi slepe tačke.
///
/// Izvor se računa kao "mogao je da pokrije" priču samo ako njegov feed seže
/// unazad bar do najstarijeg članka priče; inače bi kratak feed (npr. samo
/// današnje vesti) izgledao kao da ignoriše stare teme.
///
/// Priča ulazi tek kad je pokrilo bar [minCovered] izvora.
List<BlindSpot> findBlindSpots(
  List<Story> stories,
  List<Source> sources,
  List<Article> allArticles, {
  int minCovered = 2,
}) {
  final oldest = <String, DateTime>{};
  for (final a in allArticles) {
    final t = a.publishedAt;
    if (t == null) continue;
    final cur = oldest[a.sourceId];
    if (cur == null || t.isBefore(cur)) oldest[a.sourceId] = t;
  }
  final active = oldest.keys.toSet(); // izvori koji su uopšte vratili članke

  final out = <BlindSpot>[];
  for (final story in stories) {
    final ids = story.sourceIds;
    if (ids.length < minCovered) continue;

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

    final known = covered.map((s) => s.leaning).toSet()
      ..remove(Leaning.unknown);
    Leaning? side;
    if (known.length == 1 &&
        covered.every((s) => s.leaning != Leaning.unknown)) {
      side = known.first;
      // Jednostrano samo ako je neka druga poznata strana propustila.
      final otherMissed = missing.any(
        (s) => s.leaning != Leaning.unknown && s.leaning != side,
      );
      if (!otherMissed) side = null;
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
