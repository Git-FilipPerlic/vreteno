import 'article.dart';

/// Grupa članaka različitih izvora o istoj temi.
class Story {
  const Story(this.articles);

  final List<Article> articles;

  Set<String> get sourceIds => articles.map((a) => a.sourceId).toSet();

  /// Naslov prvog (najnovijeg) članka.
  String get title => articles.first.title;

  DateTime? get latest => articles.first.publishedAt;
}
