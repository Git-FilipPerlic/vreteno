import '../data/models/article.dart';
import 'text_normalizer.dart';

enum ToneLevel {
  neutral('neutralan'),
  emphasized('naglašen'),
  sensational('senzacionalan');

  const ToneLevel(this.label);
  final String label;
}

/// Rezultat grube heuristike nad naslovom i sažetkom. To je pomoć pri čitanju,
/// ne presuda: meri površinske signale (VELIKA SLOVA, uzvičnici, nabijene reči).
class ToneResult {
  const ToneResult({
    required this.score,
    required this.level,
    required this.capsWords,
    required this.exclamations,
    required this.loadedWords,
    required this.quotes,
  });

  /// 0 = potpuno neutralno; veće = naglašenije.
  final double score;
  final ToneLevel level;
  final int capsWords;
  final int exclamations;
  final List<String> loadedWords;

  /// Broj citata u navodnicima u naslovu i sažetku.
  final int quotes;
}

// Stemovi (posle transliteracije) reči koje su tipične za senzacionalizam
// ili emotivno nabijeno izveštavanje. Namerno kratka i lako promenljiva lista.
const _loaded = {
  'sok',
  'horor',
  'skand',
  'bruk',
  'sram',
  'haos',
  'drama',
  'katas',
  'jeziv',
  'stravi',
  'potres',
  'bes',
  'besan',
  'bizar',
  'neverov',
  'ludil',
  'napad',
  'razoc',
  'ponizi',
  'ostro',
  'zesto',
  'sprem',
  'otkriv',
  'tajn',
  'afera',
  'lopov',
  'izdaj',
  'klevet',
  'propag',
  'sabot',
  'sece',
  'prete',
  'udar',
};

final _quoteRe = RegExp(r'[„“"«]([^„“"»”]{3,})[“”"»]');

ToneResult analyzeTone(Article a) {
  final text = '${a.title} ${a.summary}';

  // Reči u VELIKIM SLOVIMA (3+ slova), osim skraćenica od 2-4 slova poput "SNS".
  final caps = RegExp(
    r'\b[\p{Lu}]{5,}\b',
    unicode: true,
  ).allMatches(text).length;
  final exclamations = '!'.allMatches(text).length;

  final stems = tokenize(text);
  final loaded = <String>{
    for (final s in stems)
      if (_loaded.any((l) => s.startsWith(l))) s,
  }.toList();

  final quotes = _quoteRe.allMatches(text).length;

  final score = caps * 1.5 + exclamations * 1.0 + loaded.length * 1.0;
  final level = score >= 4
      ? ToneLevel.sensational
      : score >= 2
      ? ToneLevel.emphasized
      : ToneLevel.neutral;

  return ToneResult(
    score: score,
    level: level,
    capsWords: caps,
    exclamations: exclamations,
    loadedWords: loaded,
    quotes: quotes,
  );
}

/// Prosečan skor tona po izvoru za jednu priču.
Map<String, double> averageToneBySource(List<Article> articles) {
  final sums = <String, double>{};
  final counts = <String, int>{};
  for (final a in articles) {
    sums[a.sourceId] = (sums[a.sourceId] ?? 0) + analyzeTone(a).score;
    counts[a.sourceId] = (counts[a.sourceId] ?? 0) + 1;
  }
  return {for (final id in sums.keys) id: sums[id]! / counts[id]!};
}
