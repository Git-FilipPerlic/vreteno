// Normalizacija srpskog teksta za poređenje: ćirilica -> latinica,
// bez dijakritika, mala slova, bez čestih reči, grubo "stemovanje".

const _cyr = {
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'ђ': 'dj',
  'е': 'e',
  'ж': 'z',
  'з': 'z',
  'и': 'i',
  'ј': 'j',
  'к': 'k',
  'л': 'l',
  'љ': 'lj',
  'м': 'm',
  'н': 'n',
  'њ': 'nj',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'ћ': 'c',
  'у': 'u',
  'ф': 'f',
  'х': 'h',
  'ц': 'c',
  'ч': 'c',
  'џ': 'dz',
  'ш': 's',
};

const _lat = {'č': 'c', 'ć': 'c', 'š': 's', 'ž': 'z', 'đ': 'dj'};

const _stop = {
  'je',
  'su',
  'se',
  'da',
  'ne',
  'na',
  'u',
  'i',
  'a',
  'o',
  'od',
  'do',
  'za',
  'sa',
  'po',
  'iz',
  'ali',
  'ili',
  'koji',
  'koja',
  'koje',
  'kao',
  'bi',
  'ce',
  'sam',
  'smo',
  'ste',
  'nije',
  'nisu',
  'to',
  'ovo',
  'sto',
  'pre',
  'posle',
  'nakon',
  'kroz',
  'pod',
  'nad',
  'oko',
  'jos',
  'sve',
  'vise',
  'samo',
  'ima',
};

const stemLength = 5;

String transliterate(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(_cyr[ch] ?? _lat[ch] ?? ch);
  }
  return b.toString();
}

/// Lista stemova (prvih [stemLength] slova) značajnih reči.
List<String> tokenize(String text) {
  return transliterate(text)
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length > 2 && !_stop.contains(w))
      .map((w) => w.length > stemLength ? w.substring(0, stemLength) : w)
      .toList();
}
