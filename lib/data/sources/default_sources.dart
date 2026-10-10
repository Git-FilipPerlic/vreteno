import '../models/source.dart';

// Orijentacije počivaju na javnim izvorima, ne na našem sudu:
//  - Reuters Institute Digital News Report 2025, Srbija
//  - Media Ownership Monitor Serbia (BIRN / RSF), serbia.mom-gmr.org
// Za izvor koji ti izvori ne opisuju stoji `unknown`.
const _reuters =
    'https://reutersinstitute.politics.ox.ac.uk/digital-news-report/2025/serbia';
const _mom =
    'https://serbia.mom-gmr.org/en/findings/local-media-concentrations-below-the-radar/';

const defaultSources = <Source>[
  Source(
    id: 'n1',
    name: 'N1',
    feedUrl: 'https://n1info.rs/feed/',
    leaning: Leaning.critical,
    rationale: 'Opisan kao "highly critical of the government".',
    evidence: _reuters,
  ),
  Source(
    id: 'danas',
    name: 'Danas',
    feedUrl: 'https://www.danas.rs/feed/',
    leaning: Leaning.critical,
    rationale: 'United Group; "critical approach towards the government".',
    evidence: _mom,
  ),
  Source(
    id: 'nova',
    name: 'Nova',
    feedUrl: 'https://nova.rs/feed/',
    leaning: Leaning.critical,
    rationale: 'United Group; "critical approach towards the government".',
    evidence: _mom,
  ),
  Source(
    id: 'vreme',
    name: 'Vreme',
    feedUrl: 'https://www.vreme.com/feed/',
    leaning: Leaning.critical,
    rationale: 'Navedeno među nezavisnim, pouzdanim medijima.',
    evidence: _reuters,
  ),
  Source(
    id: 'blic',
    name: 'Blic',
    feedUrl: 'https://www.blic.rs/rss/danasnje-vesti',
    // Ringier; pronađeni javni izvori ga ne svrstavaju ni na jednu stranu.
  ),
  Source(
    id: 'b92',
    name: 'B92',
    feedUrl: 'https://www.b92.net/info/rss/vesti.xml',
    leaning: Leaning.mixed,
    rationale:
        'Komercijalni zaokret, "less critical"; isti vlasnik kao Prva TV.',
    evidence: 'https://serbia.mom-gmr.org/en/media/detail/outlet/b92net/',
  ),
  Source(
    id: 'rts',
    name: 'RTS',
    feedUrl: 'https://www.rts.rs/page/stories/ci/rss.html',
    leaning: Leaning.proGovernment,
    rationale: 'Javni servis pod političkom kontrolom (Reuters Institute).',
    evidence: _reuters,
  ),
];
