"""Backend for the Vreteno app: keeps collecting + clustering and serves the result as JSON.

    python server.py                    # port 8080, refresh every 15 minutes
    python server.py --port 9000 --every 10

Endpoints (GET):
    /api/health                     {"ok": true, ...}
    /api/feed?days=2                sources + stories (with their articles) from the last N days

Plain HTTP on all interfaces: meant for a home network. Do not expose it to the
internet as is. Only titles, short summaries and links are served, never article text.
"""

import argparse
import gzip
import json
import sys
import threading
import time
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

import cluster
import collector
import db

MAX_DAYS = 7


def build_feed(conn, days: int) -> dict:
    cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat(timespec="seconds")

    sources = [
        {
            "id": r["domain"],
            "domain": r["domain"],
            "country": r["country"],
            # Filled by hand in the sources table; the app maps known values.
            "bias_label": r["bias_label"],
            "notes": r["notes"],
        }
        for r in conn.execute("SELECT domain, country, bias_label, notes FROM sources WHERE active = 1")
    ]

    stories: dict[int, dict] = {}
    for r in conn.execute(
        """SELECT a.story_id, s.domain, a.title_latin, a.url, a.summary, a.published_at
           FROM articles a
           JOIN sources s ON s.id = a.source_id AND s.active = 1
           WHERE a.story_id IN (SELECT id FROM stories WHERE last_at >= ?)
           ORDER BY a.published_at DESC""",
        (cutoff,),
    ):
        st = stories.setdefault(r["story_id"], {"id": r["story_id"], "articles": []})
        st["articles"].append(
            {
                "source": r["domain"],
                "title": r["title_latin"],
                "url": r["url"],
                "summary": r["summary"] or "",
                "published_at": r["published_at"],
            }
        )

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "days": days,
        "sources": sources,
        "stories": list(stories.values()),
    }


def make_handler(db_path: str):
    class Handler(BaseHTTPRequestHandler):
        server_version = "VretenoAPI/0.1"

        def _send(self, status: int, payload: dict) -> None:
            body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            headers = {"Content-Type": "application/json; charset=utf-8"}
            if "gzip" in self.headers.get("Accept-Encoding", "") and len(body) > 1024:
                body = gzip.compress(body)
                headers["Content-Encoding"] = "gzip"
            self.send_response(status)
            for k, v in headers.items():
                self.send_header(k, v)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self) -> None:  # noqa: N802 (http.server naming)
            url = urlsplit(self.path)
            try:
                if url.path == "/api/health":
                    self._send(200, {"ok": True, "time": datetime.now(timezone.utc).isoformat(timespec="seconds")})
                elif url.path == "/api/feed":
                    q = parse_qs(url.query)
                    days = max(1, min(MAX_DAYS, int(q.get("days", ["2"])[0])))
                    conn = db.connect(db_path)  # one connection per request (thread safety)
                    try:
                        self._send(200, build_feed(conn, days))
                    finally:
                        conn.close()
                else:
                    self._send(404, {"error": "not found"})
            except Exception as exc:  # never let one bad request kill the server
                self._send(500, {"error": f"{type(exc).__name__}: {exc}"})

        def log_message(self, fmt, *args) -> None:
            sys.stderr.write("%s %s\n" % (self.address_string(), fmt % args))

    return Handler


def refresh_loop(db_path: str, every_min: float, days: int, stop: threading.Event) -> None:
    """Background: collect feeds, then recluster. Errors are printed, never fatal."""
    while not stop.is_set():
        try:
            conn = db.connect(db_path)
            db.load_sources(conn)
            collector.run_round(conn)
            res = cluster.rebuild(conn, days)
            print(f"Clustered: {res['articles']} articles -> {res['stories']} stories", flush=True)
            conn.close()
        except Exception as exc:
            print(f"Refresh failed: {type(exc).__name__}: {exc}", flush=True)
        stop.wait(every_min * 60)


def main() -> int:
    ap = argparse.ArgumentParser(description="Vreteno backend (collector + clustering + JSON API)")
    ap.add_argument("--port", type=int, default=8080)
    ap.add_argument("--every", type=float, default=15, metavar="MINUTES", help="refresh interval")
    ap.add_argument("--days", type=int, default=3, help="recluster window in days")
    ap.add_argument("--db", default=str(db.DEFAULT_DB))
    ap.add_argument("--no-refresh", action="store_true", help="only serve what is in the database")
    args = ap.parse_args()

    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")
        except Exception:
            pass

    db.connect(args.db).close()  # make sure the schema exists before serving
    stop = threading.Event()
    if not args.no_refresh:
        threading.Thread(
            target=refresh_loop, args=(args.db, args.every, args.days, stop), daemon=True
        ).start()

    httpd = ThreadingHTTPServer(("0.0.0.0", args.port), make_handler(args.db))
    print(f"Serving on http://0.0.0.0:{args.port}  (Ctrl+C to stop)", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping.")
    finally:
        stop.set()
        httpd.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
