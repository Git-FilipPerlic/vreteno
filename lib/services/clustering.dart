import 'dart:math' as math;

import '../data/models/article.dart';
import '../data/models/story.dart';
import 'text_normalizer.dart';

/// Grupiše članke o istoj temi: TF-IDF vektori nad naslovom (težina 2) i
/// sažetkom (težina 1), kosinusna sličnost, pohlepno spajanje u klastere.
/// Članci udaljeni više od [maxGap] se ne spajaju.
List<Story> clusterArticles(
  List<Article> articles, {
  double threshold = 0.3,
  Duration maxGap = const Duration(hours: 48),
}) {
  if (articles.isEmpty) return [];

  final docs = articles.map(_termCounts).toList();

  // IDF
  final df = <String, int>{};
  for (final d in docs) {
    for (final t in d.keys) {
      df[t] = (df[t] ?? 0) + 1;
    }
  }
  final n = docs.length;
  final vectors = [
    for (final d in docs)
      _normalize({
        for (final e in d.entries)
          e.key: e.value * (math.log((n + 1) / (df[e.key]! + 1)) + 1),
      }),
  ];

  // Pohlepno: svaki članak ide u klaster sa najsličnijim centroidom.
  final clusters = <_Cluster>[];
  final order = List.generate(n, (i) => i)
    ..sort(
      (a, b) => (articles[b].publishedAt ?? DateTime(0)).compareTo(
        articles[a].publishedAt ?? DateTime(0),
      ),
    );

  for (final i in order) {
    _Cluster? best;
    var bestSim = threshold;
    for (final c in clusters) {
      if (!_close(articles[i], c.articles.first, maxGap)) continue;
      final s = _cosine(vectors[i], c.centroid);
      if (s >= bestSim) {
        bestSim = s;
        best = c;
      }
    }
    if (best == null) {
      clusters.add(_Cluster()..add(articles[i], vectors[i]));
    } else {
      best.add(articles[i], vectors[i]);
    }
  }

  return [for (final c in clusters) Story(c.articles)];
}

Map<String, double> _termCounts(Article a) {
  final m = <String, double>{};
  for (final t in tokenize(a.title)) {
    m[t] = (m[t] ?? 0) + 2;
  }
  for (final t in tokenize(a.summary)) {
    m[t] = (m[t] ?? 0) + 1;
  }
  return m;
}

Map<String, double> _normalize(Map<String, double> v) {
  final norm = math.sqrt(v.values.fold<double>(0, (s, x) => s + x * x));
  if (norm == 0) return v;
  return {for (final e in v.entries) e.key: e.value / norm};
}

double _cosine(Map<String, double> a, Map<String, double> b) {
  final small = a.length <= b.length ? a : b;
  final big = identical(small, a) ? b : a;
  var dot = 0.0;
  for (final e in small.entries) {
    final o = big[e.key];
    if (o != null) dot += e.value * o;
  }
  return dot;
}

bool _close(Article a, Article b, Duration gap) {
  final x = a.publishedAt, y = b.publishedAt;
  if (x == null || y == null) return true;
  return x.difference(y).abs() <= gap;
}

class _Cluster {
  final articles = <Article>[];
  final centroid = <String, double>{};

  void add(Article a, Map<String, double> v) {
    articles.add(a);
    for (final e in v.entries) {
      centroid[e.key] = (centroid[e.key] ?? 0) + e.value;
    }
    final n = _normalize(centroid);
    centroid
      ..clear()
      ..addAll(n);
  }
}
