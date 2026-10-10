"""RSS news collector.

    python collector.py --once       one collection round
    python collector.py --loop 15    repeat every 15 minutes (Ctrl+C to stop)
    python collector.py --stats      show what is in the database
"""

import argparse
import sys
import threading
import time
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlsplit

import feedparser
import requests

import db
from textutils import clean_url, cyr_to_latin, make_summary, normalize_title, now_iso, utc_iso

USER_AGENT = "MediaTrackerBot/0.1 (personal research project)"
TIMEOUT = 15
MAX_WORKERS = 8

# At most one request per host at a time, even across sources.
_host_locks: dict[str, threading.Lock] = defaultdict(threading.Lock)
_host_locks_guard = threading.Lock()


def _host_lock(url: str) -> threading.Lock:
    host = urlsplit(url).netloc.lower()
    with _host_locks_guard:
        return _host_locks[host]


def fetch_feed(src) -> dict:
    """Download and parse one feed. Runs in a worker thread; never touches the DB.

    Returns {"status": "ok"|"not_modified"|"error", ...}.
    """
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "application/rss+xml, application/atom+xml, application/xml;q=0.9, */*;q=0.5",
    }
    if src["etag"]:
        headers["If-None-Match"] = src["etag"]
    if src["last_modified"]:
        headers["If-Modified-Since"] = src["last_modified"]

    last_err = "unknown error"
    for attempt in range(2):  # first try + one retry
        if attempt:
            time.sleep(1)
        try:
            with _host_lock(src["feed_url"]):
                resp = requests.get(src["feed_url"], headers=headers, timeout=TIMEOUT)
            if resp.status_code == 304:
                return {"status": "not_modified"}
            if resp.status_code >= 400:
                last_err = f"HTTP {resp.status_code}"
                if resp.status_code < 500:
                    break  # client errors will not fix themselves on retry
                continue
            parsed = feedparser.parse(resp.content)
            if not parsed.entries:
                last_err = "no entries in feed"
                if parsed.get("bozo"):
                    last_err += f" ({parsed.bozo_exception})"
                continue
            return {
                "status": "ok",
                "etag": resp.headers.get("ETag"),
                "last_modified": resp.headers.get("Last-Modified"),
                "entries": parsed.entries,
            }
        except Exception as exc:  # network, TLS, parsing: never crash the run
            last_err = f"{type(exc).__name__}: {exc}"
    return {"status": "error", "error": last_err}


def entry_to_article(entry, fetched_at: str) -> dict | None:
    """Turn a feedparser entry into a row dict, or None if unusable."""
    title = " ".join((entry.get("title") or "").split())
    link = clean_url(entry.get("link") or "")
    if not title or not link:
        return None
    published = utc_iso(entry.get("published_parsed") or entry.get("updated_parsed"))
    # Missing or future-dated (broken feeds) -> use fetch time.
    if not published or published > fetched_at:
        published = fetched_at
    return {
        "guid": entry.get("id") or link,
        "url": link,
        "title": title,
        "title_latin": cyr_to_latin(title),
        "title_norm": normalize_title(title),
        # Only a short plain-text summary is stored, never full article text.
        "summary": make_summary(entry.get("summary") or entry.get("description") or ""),
        "published_at": published,
        "fetched_at": fetched_at,
    }


def run_round(conn) -> dict:
    sources = db.active_sources(conn)
    print(f"Fetching {len(sources)} sources ...")
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        results = list(pool.map(fetch_feed, sources))

    new_total, fetched, failed = 0, 0, []
    for src, res in zip(sources, results):  # all DB writes happen here, single thread
        if res["status"] == "error":
            deactivated = db.record_failure(conn, src["id"], res["error"])
            failed.append(src["domain"] + (" (deactivated)" if deactivated else ""))
            continue
        fetched += 1
        if res["status"] == "ok":
            fetched_at = now_iso()
            for entry in res["entries"]:
                art = entry_to_article(entry, fetched_at)
                if art and db.insert_article(conn, src["id"], art):
                    new_total += 1
            db.record_success(conn, src["id"], res["etag"], res["last_modified"])
        else:  # 304 Not Modified
            db.record_success(conn, src["id"], src["etag"], src["last_modified"])
    conn.commit()

    print(
        f"Done: {fetched}/{len(sources)} sources fetched, "
        f"{new_total} new articles, {len(failed)} failed"
        + (f": {', '.join(failed)}" if failed else "")
    )
    return {"fetched": fetched, "new": new_total, "failed": failed}


def print_stats(conn) -> None:
    print("Per country:")
    for r in conn.execute(
        """SELECT s.country, COUNT(DISTINCT s.id) AS sources, COUNT(a.id) AS articles
           FROM sources s LEFT JOIN articles a ON a.source_id = s.id
           GROUP BY s.country ORDER BY s.country"""
    ):
        print(f"  {r['country']}: {r['sources']} sources, {r['articles']} articles")

    print("\nPer source:")
    print(f"  {'domain':<28}{'cty':<5}{'articles':>9}  {'newest':<26}last error")
    for r in conn.execute(
        """SELECT s.domain, s.country, s.active, s.last_error, s.notes,
                  COUNT(a.id) AS n, MAX(a.published_at) AS newest
           FROM sources s LEFT JOIN articles a ON a.source_id = s.id
           GROUP BY s.id ORDER BY s.country, s.domain"""
    ):
        flags = ("" if r["active"] else " [INACTIVE]") + (" [NOTE]" if r["notes"] else "")
        print(
            f"  {r['domain']:<28}{r['country']:<5}{r['n']:>9}  "
            f"{(r['newest'] or '-'):<26}{r['last_error'] or ''}{flags}"
        )


def main() -> int:
    ap = argparse.ArgumentParser(description="RSS news collector")
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--once", action="store_true", help="run one collection round")
    mode.add_argument("--loop", type=float, metavar="MINUTES", help="repeat every N minutes")
    mode.add_argument("--stats", action="store_true", help="print database statistics")
    ap.add_argument("--db", default=str(db.DEFAULT_DB), help="SQLite file (default: news.db)")
    ap.add_argument("--sources", default=str(db.DEFAULT_SOURCES), help="feed_results.json path")
    args = ap.parse_args()

    # Windows consoles default to cp1252; force UTF-8 so titles print safely.
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")
        except Exception:
            pass

    conn = db.connect(args.db)
    n = db.load_sources(conn, args.sources)

    if args.stats:
        print_stats(conn)
        return 0
    print(f"{n} sources loaded.")

    if args.once:
        run_round(conn)
        return 0

    try:
        while True:
            run_round(conn)
            print(f"Next round in {args.loop:g} min (Ctrl+C to stop)\n")
            time.sleep(args.loop * 60)
    except KeyboardInterrupt:
        print("\nStopped.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
