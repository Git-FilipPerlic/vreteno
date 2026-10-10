"""Run with `python test_cluster.py` (or pytest)."""

from cluster import cluster_articles, tokenize


def row(title, hours=0, summary=""):
    from textutils import normalize_title
    return {
        "title_norm": normalize_title(title),
        "summary": summary,
        "published_at": f"2026-10-10T{8 + hours:02d}:00:00+00:00",
    }


def test_tokenize_handles_variants():
    assert tokenize("Vrijeme u Zagrebu") == tokenize("Vreme u Zagrebu")
    assert tokenize("Влада усвојила буџет") == tokenize("Vlada usvojila budžet")


def test_groups_same_event_across_variants():
    rows = [
        row("Preminuo hrvatski muzičar Goran Bare"),
        row("Преминуо Горан Баре, frontmen benda Majke", 1),
        row("Goran Bare preminuo, oglasili se kolege", 2),
        row("Zemljotres pogodio Panamu, izdato upozorenje na cunami", 1),
        row("Potres magnitude 7,6 pogodio Panamu, cunami upozorenje", 2),
        row("Moody's potvrdio kreditni rejting Hrvatske", 2),
    ]
    groups = sorted(sorted(g) for g in cluster_articles(rows))
    assert [0, 1, 2] in groups
    assert [3, 4] in groups
    assert [5] in groups


def test_far_apart_in_time_is_not_merged():
    rows = [row("Preminuo Goran Bare"), {**row("Preminuo Goran Bare"), "published_at": "2026-10-20T08:00:00+00:00"}]
    assert len(cluster_articles(rows)) == 2


if __name__ == "__main__":
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            fn()
            print("ok", name)
