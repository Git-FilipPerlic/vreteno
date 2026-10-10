import 'package:flutter_test/flutter_test.dart';
import 'package:vreteno/data/models/article.dart';
import 'package:vreteno/services/clustering.dart';
import 'package:vreteno/services/text_normalizer.dart';

Article a(String src, String title, {String summary = '', int h = 0}) =>
    Article(
      sourceId: src,
      title: title,
      url: 'https://x.rs/$src/${title.hashCode}',
      summary: summary,
      publishedAt: DateTime.utc(2026, 10, 10, 8).add(Duration(hours: h)),
    );

void main() {
  test('transliterates cyrillic and folds diacritics', () {
    expect(transliterate('Љубав ђаци Шабац'), 'ljubav djaci sabac');
    expect(tokenize('Vlada usvojila budžet'), tokenize('Влада усвојила буџет'));
  });

  test('groups same story across sources, incl. Cyrillic', () {
    final stories = clusterArticles([
      a('n1', 'Vlada usvojila budžet za 2027. godinu'),
      a('rts', 'Влада усвојила буџет за 2027. годину', h: 1),
      a('blic', 'Budžet za 2027. usvojen na sednici Vlade', h: 1),
      a('danas', 'Zvezda pobedila Partizan u derbiju', h: 2),
      a('b92', 'Derbi: Crvena zvezda savladala Partizan', h: 2),
    ]);
    expect(stories, hasLength(2));
    final sizes = stories.map((s) => s.articles.length).toList()..sort();
    expect(sizes, [2, 3]);
  });

  test('does not merge same topic far apart in time', () {
    final stories = clusterArticles([
      a('n1', 'Vlada usvojila budžet'),
      a('danas', 'Vlada usvojila budžet', h: 24 * 5),
    ]);
    expect(stories, hasLength(2));
  });
}
