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

## Clustering

```powershell
python cluster.py --days 3 --show 15   # group the last 3 days into stories, print the 15 biggest
```

Fills the `stories` table and `articles.story_id`. TF-IDF over normalized title and summary,
cosine similarity against story centroids, 48 h time gap. Stories for the chosen window are
rebuilt on every run, so story ids change between runs.

## Server for the app

```powershell
python server.py                 # collects + clusters every 15 min, serves http://0.0.0.0:8080/api/feed
```

Autostart at Windows logon (scheduled task "Vreteno server", runs `run_server.ps1`, log in `server.log`):

```powershell
$a = New-ScheduledTaskAction -Execute powershell.exe -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "D:\All Work\Vreteno\collector\run_server.ps1"'
Register-ScheduledTask -TaskName 'Vreteno server' -Action $a -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) -Force
Start-ScheduledTask -TaskName 'Vreteno server'     # start now; Stop-ScheduledTask / Unregister-ScheduledTask to undo
```

The app reaches it at the address in `lib/core/config.dart` (override with
`--dart-define=API_URL=http://<pc-ip>:8080`). Plain HTTP, home network only.
