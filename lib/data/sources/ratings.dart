import '../models/source.dart';

// Orijentacije počivaju na javnim izvorima, ne na našem sudu:
//  - Reuters Institute Digital News Report 2025, Srbija
//  - Media Ownership Monitor Serbia (BIRN / RSF), serbia.mom-gmr.org
// Izvor koji ti izvori ne opisuju ostaje `unknown`.
const _reuters =
    'https://reutersinstitute.politics.ox.ac.uk/digital-news-report/2025/serbia';
const _mom =
    'https://serbia.mom-gmr.org/en/findings/local-media-concentrations-below-the-radar/';

class Rating {
  const Rating(this.name, this.leaning, this.rationale, this.evidence);

  final String name;
  final Leaning leaning;
  final String rationale;
  final String evidence;
}

const rN1 = Rating(
  'N1',
  Leaning.critical,
  'Opisan kao "highly critical of the government".',
  _reuters,
);
const rDanas = Rating(
  'Danas',
  Leaning.critical,
  'United Group; "critical approach towards the government".',
  _mom,
);
const rNova = Rating(
  'Nova',
  Leaning.critical,
  'United Group; "critical approach towards the government".',
  _mom,
);
const rVreme = Rating(
  'Vreme',
  Leaning.critical,
  'Navedeno među nezavisnim, pouzdanim medijima.',
  _reuters,
);
const rB92 = Rating(
  'B92',
  Leaning.mixed,
  'Komercijalni zaokret, "less critical"; isti vlasnik kao Prva TV.',
  'https://serbia.mom-gmr.org/en/media/detail/outlet/b92net/',
);
const rPink = Rating(
  'Pink',
  Leaning.proGovernment,
  'Pink Media Group: vlasnici bliski vlasti; "promote the government".',
  _mom,
);
const rRts = Rating(
  'RTS',
  Leaning.proGovernment,
  'Javni servis pod političkom kontrolom (Reuters Institute).',
  _reuters,
);

/// Ocene po domenu (ključ je domen iz kolektora).
const ratingsByDomain = <String, Rating>{
  'n1info.rs': rN1,
  'danas.rs': rDanas,
  'nova.rs': rNova,
  'vreme.com': rVreme,
  'b92.net': rB92,
  'pink.rs': rPink,
  'rts.rs': rRts,
};

/// Vrednost iz kolone `bias_label` (ručno uneta u bazi) -> Leaning.
Leaning? leaningFromLabel(String? label) {
  switch ((label ?? '').trim().toLowerCase()) {
    case 'critical':
      return Leaning.critical;
    case 'progovernment':
    case 'pro_government':
    case 'pro-government':
      return Leaning.proGovernment;
    case 'mixed':
      return Leaning.mixed;
    case 'unknown':
      return Leaning.unknown;
  }
  return null;
}
