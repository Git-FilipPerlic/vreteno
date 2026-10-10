import '../models/source.dart';
import 'ratings.dart';

/// Izvori za direktno čitanje RSS-a (rezerva kad server nije dostupan).
/// Orijentacije dolaze iz ratings.dart; `unknown` gde javni izvori ćute.
final defaultSources = <Source>[
  Source(
    id: 'n1',
    name: rN1.name,
    feedUrl: 'https://n1info.rs/feed/',
    leaning: rN1.leaning,
    rationale: rN1.rationale,
    evidence: rN1.evidence,
    country: 'RS',
  ),
  Source(
    id: 'danas',
    name: rDanas.name,
    feedUrl: 'https://www.danas.rs/feed/',
    leaning: rDanas.leaning,
    rationale: rDanas.rationale,
    evidence: rDanas.evidence,
    country: 'RS',
  ),
  Source(
    id: 'nova',
    name: rNova.name,
    feedUrl: 'https://nova.rs/feed/',
    leaning: rNova.leaning,
    rationale: rNova.rationale,
    evidence: rNova.evidence,
    country: 'RS',
  ),
  Source(
    id: 'vreme',
    name: rVreme.name,
    feedUrl: 'https://www.vreme.com/feed/',
    leaning: rVreme.leaning,
    rationale: rVreme.rationale,
    evidence: rVreme.evidence,
    country: 'RS',
  ),
  const Source(
    id: 'blic',
    name: 'Blic',
    feedUrl: 'https://www.blic.rs/rss/danasnje-vesti',
    country: 'RS',
    // Ringier; pronađeni javni izvori ga ne svrstavaju ni na jednu stranu.
  ),
  const Source(
    id: 'juzne',
    name: 'Južne vesti',
    feedUrl: 'https://www.juznevesti.com/feed/',
    country: 'RS',
    // Regionalni portal (Niš); javni izvori koje smo čitali ga ne ocenjuju.
  ),
  Source(
    id: 'b92',
    name: rB92.name,
    feedUrl: 'https://www.b92.net/info/rss/vesti.xml',
    leaning: rB92.leaning,
    rationale: rB92.rationale,
    evidence: rB92.evidence,
    country: 'RS',
  ),
  Source(
    id: 'rts',
    name: rRts.name,
    feedUrl: 'https://www.rts.rs/page/stories/ci/rss.html',
    leaning: rRts.leaning,
    rationale: rRts.rationale,
    evidence: rRts.evidence,
    country: 'RS',
  ),
];
