# News collector

Collects titles, short summaries and links from ~55 Serbian / Bosnian / Croatian /
Montenegrin RSS feeds into a local SQLite database (`news.db`). It never downloads
full article text. Clustering, bias scoring and UI come later and read from this database.

## Setup (Windows)

```powershell
cd "D:\All Work\Vreteno\collector"
python -m pip install requests feedparser
```

## Run

```powershell
python collector.py --once        # one collection round
python collector.py --loop 15     # repeat every 15 minutes, Ctrl+C to stop
python collector.py --stats       # articles per country and per source, last errors
python test_textutils.py          # tests (plain asserts; pytest also works)
```

Optional: `--db other.db` and `--sources other.json`.

## Files

| File | Purpose |
|---|---|
| `collector.py` | fetching, parsing, CLI |
| `db.py` | schema, loading sources, inserts |
| `textutils.py` | Cyrillic→Latin, title normalization, URL cleaning, summaries, dates |
| `feed_results.json` | feed list; only entries with `"ok": true` are used |

## Notes

- `sources.bias_label` is left `NULL`; fill it by hand. Re-running never overwrites
  `bias_label` or edited `notes`.
- Two feeds are flagged in `notes`, not dropped: `slobodnaevropa.org` and `direktno.hr`.
- `title` is the original, `title_latin` the Latin transliteration, `title_norm` is lowercase
  Latin without diacritics (`đ`→`dj`) or punctuation, meant for clustering.
- Conditional GET (ETag / Last-Modified) is used; a source is set `active = 0` after
  10 consecutive failures (`sources.fail_count`, an extra column).
- Articles without a date, or dated in the future, get `published_at = fetched_at`.
