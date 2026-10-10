import '../models/source.dart';

/// Provereni RSS feedovi. Orijentacija je za sada `unknown` dok ne uvedemo
/// ocenjivanje sa jasnom metodologijom.
const defaultSources = <Source>[
  Source(id: 'n1', name: 'N1', feedUrl: 'https://n1info.rs/feed/'),
  Source(id: 'danas', name: 'Danas', feedUrl: 'https://www.danas.rs/feed/'),
  Source(id: 'nova', name: 'Nova', feedUrl: 'https://nova.rs/feed/'),
  Source(id: 'vreme', name: 'Vreme', feedUrl: 'https://www.vreme.com/feed/'),
  Source(
    id: 'blic',
    name: 'Blic',
    feedUrl: 'https://www.blic.rs/rss/danasnje-vesti',
  ),
  Source(
    id: 'b92',
    name: 'B92',
    feedUrl: 'https://www.b92.net/info/rss/vesti.xml',
  ),
  Source(
    id: 'rts',
    name: 'RTS',
    feedUrl: 'https://www.rts.rs/page/stories/ci/rss.html',
  ),
];
