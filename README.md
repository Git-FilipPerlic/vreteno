# Vreteno

Agregator vesti sa analizom pristrasnosti: prikuplja članke iz RSS feedova, grupiše ih po temi,
ocenjuje izvore i pokazuje „slepe tačke“ u pokrivenosti.

## Struktura
- `lib/core` – tema, pomoćne funkcije
- `lib/data` – modeli, izvori podataka (RSS), repozitorijumi
- `lib/services` – klasterovanje, analiza tona/citata
- `lib/features/feed|story|sources|blindspots|analysis` – ekrani po funkcijama
