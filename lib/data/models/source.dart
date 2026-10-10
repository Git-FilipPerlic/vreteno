/// Odnos izvora prema vlasti, prema javnim izvorima navedenim u [Source.evidence].
enum Leaning {
  proGovernment('bliži vlasti'),
  critical('kritičan prema vlasti'),
  mixed('mešovit / komercijalni'),
  unknown('nepoznato');

  const Leaning(this.label);
  final String label;
}

class Source {
  const Source({
    required this.id,
    required this.name,
    required this.feedUrl,
    this.leaning = Leaning.unknown,
    this.rationale = '',
    this.evidence = '',
    this.country = '',
  });

  final String id;

  /// RS, BA, HR, ME; prazno kad se ne zna.
  final String country;
  final String name;
  final String feedUrl;
  final Leaning leaning;

  /// Kratko obrazloženje ocene.
  final String rationale;

  /// Javni izvor na kome ocena počiva (URL).
  final String evidence;
}
