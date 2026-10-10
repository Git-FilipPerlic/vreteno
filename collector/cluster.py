"""Group articles about the same event into stories.

    python cluster.py                 recluster the last 3 days
    python cluster.py --days 7        wider window
    python cluster.py --show 20       print the 20 biggest multi-source stories

Method: TF-IDF vectors over title (weight 2) and summary (weight 1), cosine
similarity against story centroids, greedy assignment in chronological order.
Pure standard library. Stories are rebuilt for the chosen window on each run,
so story ids are not stable between runs.
"""

import argparse
import math
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone

import db
from textutils import normalize_title

STEM_LEN = 5        # crude stemming: first 5 letters handles most inflection
THRESHOLD = 0.30    # minimum cosine similarity to join a story
MAX_GAP_HOURS = 48  # an article only joins a story active within this gap
MAX_DF = 0.15       # ignore terms present in more than 15% of articles

# Normalized (no diacritics) common words in Serbian / Croatian / Bosnian / Montenegrin
# plus generic news tags that carry no topic information.
STOPWORDS = set("""
je su se da ne na u i a o od do za sa po iz ali ili koji koja koje koji kao bi ce
sam smo ste nije nisu to ovo sto pre posle nakon kroz pod nad oko jos sve vise
samo ima bio bila bilo bili nema ovaj ova ove taj ta te tom tih kod prema protiv
izmedu tijekom tokom zbog zato kako gdje gde kada kad jer pa ni ni li ce cemo
foto video uzivo fotogalerija vesti vijesti dana dan danas jucer sutra godine godina
nova novi novo nove vec bez ove ona oni one cini rekao rekla kaze kazao navodno
""".split())


def tokenize(text: str) -> list[str]:
    out = []
    for w in normalize_title(text).split():
        if len(w) < 3 or w in STOPWORDS:
            continue
        w = w.replace("ije", "e")  # ijekavian -> ekavian (vrijeme -> vreme)
        out.append(w[:STEM_LEN])
    return out


class _Story:
    __slots__ = ("vec", "norm2", "members", "last_time")

    def __init__(self) -> None:
        self.vec: dict[str, float] = defaultdict(float)  # unnormalized centroid sum
        self.norm2 = 0.0
        self.members: list[int] = []
        self.last_time: datetime | None = None

    def add(self, idx: int, vec: dict[str, float], t: datetime) -> None:
        for term, w in vec.items():
            old = self.vec[term]
            self.vec[term] = old + w
            self.norm2 += (old + w) ** 2 - old ** 2
        self.members.append(idx)
        if self.last_time is None or t > self.last_time:
            self.last_time = t


def _parse(ts: str) -> datetime:
    return datetime.fromisoformat(ts)


def cluster_articles(rows, threshold: float = THRESHOLD):
    """rows: list of sqlite rows (title_norm, summary, published_at). Returns list of lists of row indexes."""
    n = len(rows)
    counts = []
    df: Counter = Counter()
    for r in rows:
        c: Counter = Counter()
        for t in tokenize(r["title_norm"]):
            c[t] += 2
        for t in tokenize(r["summary"] or ""):
            c[t] += 1
        counts.append(c)
        df.update(c.keys())

    max_df = max(3, int(n * MAX_DF))
    idf = {t: math.log((n + 1) / (d + 1)) + 1 for t, d in df.items() if d <= max_df}

    vectors = []
    for c in counts:
        v = {t: w * idf[t] for t, w in c.items() if t in idf}
        norm = math.sqrt(sum(x * x for x in v.values())) or 1.0
        vectors.append({t: x / norm for t, x in v.items()})

    times = [_parse(r["published_at"]) for r in rows]
    order = sorted(range(n), key=lambda i: times[i])
    gap = timedelta(hours=MAX_GAP_HOURS)

    stories: list[_Story] = []
    postings: dict[str, set[int]] = defaultdict(set)  # term -> story indexes

    for i in order:
        v = vectors[i]
        scores: dict[int, float] = defaultdict(float)
        for term, w in v.items():
            for sid in postings.get(term, ()):
                scores[sid] += w * stories[sid].vec[term]
        best, best_sim = None, threshold
        for sid, dot in scores.items():
            st = stories[sid]
            if times[i] - st.last_time > gap:
                continue
            sim = dot / math.sqrt(st.norm2) if st.norm2 else 0.0
            if sim >= best_sim:
                best, best_sim = sid, sim
        if best is None:
            best = len(stories)
            stories.append(_Story())
        stories[best].add(i, v, times[i])
        for term in v:
            postings[term].add(best)

    return [s.members for s in stories]


def rebuild(conn, days: int) -> dict:
    cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat(timespec="seconds")

    # Stories touching the window are dissolved and rebuilt, including their older members.
    affected = [
        r[0] for r in conn.execute(
            "SELECT DISTINCT story_id FROM articles WHERE story_id IS NOT NULL AND published_at >= ?",
            (cutoff,),
        )
    ]
    conn.execute(
        f"UPDATE articles SET story_id = NULL WHERE published_at >= ? OR story_id IN ({','.join('?' * len(affected))})"
        if affected else "UPDATE articles SET story_id = NULL WHERE published_at >= ?",
        (cutoff, *affected),
    )
    if affected:
        conn.execute(f"DELETE FROM stories WHERE id IN ({','.join('?' * len(affected))})", affected)

    # Unassigned articles in the window, plus a margin for older members of dissolved stories.
    margin = (datetime.fromisoformat(cutoff) - timedelta(hours=MAX_GAP_HOURS * 2)).isoformat(timespec="seconds")
    rows = conn.execute(
        """SELECT a.id, a.source_id, a.title, a.title_norm, a.summary, a.published_at, s.country
           FROM articles a JOIN sources s ON s.id = a.source_id
           WHERE a.story_id IS NULL AND a.published_at >= ?
           ORDER BY a.published_at""",
        (margin,),
    ).fetchall()

    groups = cluster_articles(rows)
    multi = cross = 0
    for members in groups:
        mem = [rows[i] for i in members]
        first, last = mem[0]["published_at"], mem[-1]["published_at"]
        sources = {m["source_id"] for m in mem}
        countries = {m["country"] for m in mem}
        cur = conn.execute(
            """INSERT INTO stories (title, first_at, last_at, article_count, source_count, country_count)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (mem[0]["title"], first, last, len(mem), len(sources), len(countries)),
        )
        conn.executemany(
            "UPDATE articles SET story_id = ? WHERE id = ?",
            [(cur.lastrowid, m["id"]) for m in mem],
        )
        multi += len(sources) > 1
        cross += len(countries) > 1
    conn.commit()
    return {"articles": len(rows), "stories": len(groups), "multi_source": multi, "cross_country": cross}


def show(conn, limit: int, min_sources: int) -> None:
    stories = conn.execute(
        """SELECT * FROM stories WHERE source_count >= ?
           ORDER BY source_count DESC, article_count DESC LIMIT ?""",
        (min_sources, limit),
    ).fetchall()
    for st in stories:
        print(f"\n[{st['source_count']} sources, {st['country_count']} countries, {st['article_count']} articles]")
        for m in conn.execute(
            """SELECT s.domain, s.country, a.title_latin FROM articles a
               JOIN sources s ON s.id = a.source_id WHERE a.story_id = ?
               ORDER BY a.published_at LIMIT 6""",
            (st["id"],),
        ):
            print(f"  {m['country']} {m['domain']}: {m['title_latin'][:110]}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Cluster articles into stories")
    ap.add_argument("--days", type=int, default=3, help="recluster articles from the last N days")
    ap.add_argument("--show", type=int, default=0, metavar="N", help="print N biggest stories")
    ap.add_argument("--min-sources", type=int, default=3, help="for --show: minimum sources")
    ap.add_argument("--db", default=str(db.DEFAULT_DB))
    args = ap.parse_args()

    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")
        except Exception:
            pass

    conn = db.connect(args.db)
    res = rebuild(conn, args.days)
    print(
        f"{res['articles']} articles -> {res['stories']} stories "
        f"({res['multi_source']} with 2+ sources, {res['cross_country']} across countries)"
    )
    if args.show:
        show(conn, args.show, args.min_sources)
    return 0


if __name__ == "__main__":
    sys.exit(main())
