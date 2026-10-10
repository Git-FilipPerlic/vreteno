"""Text helpers: transliteration, normalization, URL cleaning, HTML stripping, dates."""

import html
import re
import unicodedata
from datetime import datetime, timezone
from html.parser import HTMLParser
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

# --- Serbian Cyrillic -> Latin -------------------------------------------------

_CYR_LOWER = {
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "ђ": "đ", "е": "e",
    "ж": "ž", "з": "z", "и": "i", "ј": "j", "к": "k", "л": "l", "љ": "lj",
    "м": "m", "н": "n", "њ": "nj", "о": "o", "п": "p", "р": "r", "с": "s",
    "т": "t", "ћ": "ć", "у": "u", "ф": "f", "х": "h", "ц": "c", "ч": "č",
    "џ": "dž", "ш": "š",
}
_CYR_MAP = dict(_CYR_LOWER)
_CYR_MAP.update({k.upper(): v.capitalize() for k, v in _CYR_LOWER.items()})
_CYR_RE = re.compile("[Ѐ-ӿ]")


def has_cyrillic(text: str) -> bool:
    return bool(_CYR_RE.search(text or ""))


def cyr_to_latin(text: str) -> str:
    """Transliterate Serbian Cyrillic to Latin, keeping case.

    Digraph letters (Љ, Њ, Џ) become "Lj"/"Nj"/"Dž", or "LJ"/"NJ"/"DŽ" when
    they sit next to another capital letter (all-caps words).
    """
    if not text:
        return text
    out = []
    for i, ch in enumerate(text):
        rep = _CYR_MAP.get(ch)
        if rep is None:
            out.append(ch)
            continue
        if len(rep) > 1 and ch.isupper():
            prev_up = i > 0 and text[i - 1].isupper()
            next_up = i + 1 < len(text) and text[i + 1].isupper()
            if prev_up or next_up:
                rep = rep.upper()
        out.append(rep)
    return "".join(out)


# --- Normalization for clustering -----------------------------------------------

_DIACRITIC_MAP = str.maketrans({
    "č": "c", "ć": "c", "š": "s", "ž": "z",
})
_PUNCT_RE = re.compile(r"[^\w\s]|_", re.UNICODE)
_WS_RE = re.compile(r"\s+")


def normalize_title(text: str) -> str:
    """Lowercase, Latin, diacritics stripped (đ -> dj), punctuation removed."""
    if not text:
        return ""
    s = cyr_to_latin(text).lower()
    s = s.replace("đ", "dj").translate(_DIACRITIC_MAP)
    # Strip any remaining combining marks (é, ö, ...), e.g. from foreign names.
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = _PUNCT_RE.sub(" ", s)
    return _WS_RE.sub(" ", s).strip()


# --- URLs -----------------------------------------------------------------------

_TRACKING_PARAMS = {
    "fbclid", "gclid", "dclid", "msclkid", "igshid", "mc_cid", "mc_eid",
    "yclid", "_ga", "_gl", "ref", "ref_src", "cmpid", "ocid", "s_cid", "spm",
}


def clean_url(url: str) -> str:
    """Drop fragments and tracking params; lowercase scheme and host."""
    url = (url or "").strip()
    if not url:
        return url
    parts = urlsplit(url)
    query = [
        (k, v)
        for k, v in parse_qsl(parts.query, keep_blank_values=True)
        if not k.lower().startswith("utm_") and k.lower() not in _TRACKING_PARAMS
    ]
    return urlunsplit(
        (parts.scheme.lower(), parts.netloc.lower(), parts.path, urlencode(query), "")
    )


# --- HTML / summaries -----------------------------------------------------------

class _TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._skip = 0

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self._skip += 1
        elif tag in ("p", "br", "div", "li"):
            self.parts.append(" ")

    def handle_endtag(self, tag):
        if tag in ("script", "style") and self._skip:
            self._skip -= 1

    def handle_data(self, data):
        if not self._skip:
            self.parts.append(data)


def strip_html(text: str) -> str:
    if not text:
        return ""
    p = _TextExtractor()
    try:
        p.feed(text)
        p.close()
        plain = "".join(p.parts)
    except Exception:  # malformed markup: fall back to a crude strip
        plain = re.sub(r"<[^>]*>", " ", text)
    plain = html.unescape(plain).replace("\xa0", " ")
    return _WS_RE.sub(" ", plain).strip()


def make_summary(text: str, limit: int = 300) -> str:
    """Plain-text summary, at most `limit` characters (cut on a word boundary)."""
    plain = strip_html(text)
    if len(plain) <= limit:
        return plain
    cut = plain[: limit - 1]
    if " " in cut[limit // 2:]:
        cut = cut.rsplit(" ", 1)[0]
    return cut.rstrip(" ,.;:-") + "…"


# --- Dates ----------------------------------------------------------------------

def utc_iso(struct_time) -> str | None:
    """Convert a feedparser time struct (already UTC) to ISO-8601 UTC."""
    if not struct_time:
        return None
    try:
        dt = datetime(*struct_time[:6], tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return None
    return dt.isoformat(timespec="seconds")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")
