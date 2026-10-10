"""SQLite storage for sources and articles."""

import json
import sqlite3
from pathlib import Path

from textutils import now_iso

BASE_DIR = Path(__file__).resolve().parent
DEFAULT_DB = BASE_DIR / "news.db"
DEFAULT_SOURCES = BASE_DIR / "feed_results.json"

MAX_FAILURES = 10

SCHEMA = """
CREATE TABLE IF NOT EXISTS sources (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    domain        TEXT NOT NULL UNIQUE,
    country       TEXT NOT NULL,
    feed_url      TEXT NOT NULL,
    bias_label    TEXT,
    notes         TEXT,
    active        INTEGER NOT NULL DEFAULT 1,
    etag          TEXT,
    last_modified TEXT,
    last_fetch_at TEXT,
    last_error    TEXT,
    fail_count    INTEGER NOT NULL DEFAULT 0  -- consecutive failures
);

CREATE TABLE IF NOT EXISTS articles (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id    INTEGER NOT NULL REFERENCES sources(id),
    guid         TEXT,
    url          TEXT NOT NULL UNIQUE,
    title        TEXT NOT NULL,
    title_latin  TEXT NOT NULL,
    title_norm   TEXT NOT NULL,
    summary      TEXT,
    published_at TEXT NOT NULL,
    fetched_at   TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_articles_source    ON articles(source_id);
CREATE INDEX IF NOT EXISTS idx_articles_published ON articles(published_at);
"""

# Feeds that look wrong: kept and flagged, never dropped.
SUSPICIOUS_NOTES = {
    "slobodnaevropa.org": "SUSPICIOUS: feed url is just /api/, probably not a real RSS feed",
    "direktno.hr": "SUSPICIOUS: sample title is just 'Direktno.hr vijesti', check feed content",
}


def connect(path: Path | str = DEFAULT_DB) -> sqlite3.Connection:
    conn = sqlite3.connect(str(path))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    conn.executescript(SCHEMA)
    return conn


def load_sources(conn: sqlite3.Connection, json_path: Path | str = DEFAULT_SOURCES) -> int:
    """Upsert working feeds ("ok": true). Never overwrites bias_label or edited notes."""
    with open(json_path, encoding="utf-8") as f:
        entries = json.load(f)
    count = 0
    for e in entries:
        if not e.get("ok"):
            continue
        domain = e["d"].strip().lower()
        conn.execute(
            """
            INSERT INTO sources (domain, country, feed_url, notes)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(domain) DO UPDATE SET
                country  = excluded.country,
                feed_url = excluded.feed_url,
                notes    = COALESCE(sources.notes, excluded.notes)
            """,
            (domain, e["c"], e["feed"], SUSPICIOUS_NOTES.get(domain)),
        )
        count += 1
    conn.commit()
    return count


def active_sources(conn: sqlite3.Connection) -> list[sqlite3.Row]:
    return conn.execute("SELECT * FROM sources WHERE active = 1 ORDER BY domain").fetchall()


def record_success(conn, source_id: int, etag, last_modified) -> None:
    conn.execute(
        """UPDATE sources SET etag = ?, last_modified = ?, last_fetch_at = ?,
           last_error = NULL, fail_count = 0 WHERE id = ?""",
        (etag, last_modified, now_iso(), source_id),
    )


def record_failure(conn, source_id: int, error: str) -> bool:
    """Store the error; deactivate after MAX_FAILURES in a row. Returns True if deactivated."""
    conn.execute(
        "UPDATE sources SET last_error = ?, last_fetch_at = ?, fail_count = fail_count + 1 WHERE id = ?",
        (error[:500], now_iso(), source_id),
    )
    row = conn.execute("SELECT fail_count FROM sources WHERE id = ?", (source_id,)).fetchone()
    if row["fail_count"] >= MAX_FAILURES:
        conn.execute("UPDATE sources SET active = 0 WHERE id = ?", (source_id,))
        return True
    return False


def insert_article(conn, source_id: int, a: dict) -> bool:
    """Insert one article; returns False if its URL already exists."""
    cur = conn.execute(
        """INSERT OR IGNORE INTO articles
           (source_id, guid, url, title, title_latin, title_norm, summary, published_at, fetched_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            source_id, a["guid"], a["url"], a["title"], a["title_latin"],
            a["title_norm"], a["summary"], a["published_at"], a["fetched_at"],
        ),
    )
    return cur.rowcount > 0
