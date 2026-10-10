/// Politička orijentacija izvora (grubo, za početak).
enum Leaning { pro, neutral, anti, unknown }

class Source {
  const Source({
    required this.id,
    required this.name,
    required this.feedUrl,
    this.leaning = Leaning.unknown,
  });

  final String id;
  final String name;
  final String feedUrl;
  final Leaning leaning;
}
