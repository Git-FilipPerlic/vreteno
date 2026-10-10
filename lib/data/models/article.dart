class Article {
  const Article({
    required this.sourceId,
    required this.title,
    required this.url,
    this.summary = '',
    this.publishedAt,
  });

  final String sourceId;
  final String title;
  final String url;
  final String summary;
  final DateTime? publishedAt;
}
