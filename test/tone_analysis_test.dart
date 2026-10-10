import 'package:flutter_test/flutter_test.dart';
import 'package:vreteno/data/models/article.dart';
import 'package:vreteno/services/tone_analysis.dart';

Article a(String title, [String summary = '']) =>
    Article(sourceId: 's', title: title, url: 'u', summary: summary);

void main() {
  test('plain headline is neutral', () {
    final r = analyzeTone(a('Vlada usvojila budžet za 2027. godinu'));
    expect(r.level, ToneLevel.neutral);
    expect(r.score, 0);
  });

  test('caps, exclamation and loaded words raise the score', () {
    final r = analyzeTone(a('VUČIĆ SPREMA SEČU KNEZOVA! Horor u Beogradu'));
    expect(r.capsWords, greaterThanOrEqualTo(2));
    expect(r.exclamations, 1);
    expect(r.loadedWords, isNotEmpty);
    expect(r.level, ToneLevel.sensational);
  });

  test('short abbreviations are not shouting', () {
    expect(analyzeTone(a('SNS i SPS o RIK-u')).capsWords, 0);
  });

  test('counts quotes, also with Serbian quotation marks', () {
    final r = analyzeTone(
      a('Putin: „To je sabotaža“', 'Rekao je "ništa novo"'),
    );
    expect(r.quotes, 2);
  });

  test('works for Cyrillic', () {
    expect(
      analyzeTone(a('ШОК И ХОРОР: страшан напад!')).level,
      ToneLevel.sensational,
    );
  });
}
