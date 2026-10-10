"""Run with `python test_textutils.py` (or pytest)."""

from textutils import clean_url, cyr_to_latin, make_summary, normalize_title, strip_html


def test_transliteration():
    assert cyr_to_latin("Влада усвојила буџет") == "Vlada usvojila budžet"
    assert cyr_to_latin("љубав њива џем") == "ljubav njiva džem"
    assert cyr_to_latin("Љубљана и Њујорк") == "Ljubljana i Njujork"
    assert cyr_to_latin("ђак, ћуприја, чај, шума, жена") == "đak, ćuprija, čaj, šuma, žena"
    assert cyr_to_latin("ЉУБАВ") == "LJUBAV"
    assert cyr_to_latin("Beograd 2026") == "Beograd 2026"  # Latin passes through


def test_normalize():
    assert normalize_title("Đoković: „Čekam šampionski pehar!“") == "djokovic cekam sampionski pehar"
    assert normalize_title("Ћирилица, ЖЕНА & Ђаци") == "cirilica zena djaci"
    assert normalize_title("  RIK-u   podnet  prigovor ") == "rik u podnet prigovor"
    assert normalize_title("") == ""


def test_clean_url():
    assert (
        clean_url("HTTPS://Www.N1info.rs/vesti/a1?utm_source=fb&id=5&fbclid=xyz#komentari")
        == "https://www.n1info.rs/vesti/a1?id=5"
    )
    assert clean_url("https://x.rs/a/?utm_medium=rss") == "https://x.rs/a/"


def test_summary():
    assert strip_html("<p>Tekst &amp; <b>vesti</b></p><script>x()</script>") == "Tekst & vesti"
    long = "<p>" + "reč " * 200 + "</p>"
    assert len(make_summary(long)) <= 300
    assert make_summary("<b>kratko</b>") == "kratko"


if __name__ == "__main__":
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            fn()
            print("ok", name)
