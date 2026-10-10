"""Generate the Vreteno launcher icon: a rectangle rotated 45 degrees with a
striped middle, like thread wound on a spindle.

    python tool/make_icon.py

Writes Android mipmaps (legacy + adaptive) into android/app/src/main/res.
Needs Pillow (pip install pillow).
"""

from pathlib import Path

from PIL import Image, ImageDraw

RES = Path(__file__).resolve().parent.parent / "android" / "app" / "src" / "main" / "res"

BG = (20, 23, 43)        # deep indigo
BODY = (242, 230, 201)   # cream wood
THREAD = (226, 120, 62)  # amber thread
THREAD_DARK = (150, 70, 35)
SS = 4                   # supersampling factor


def render(size: int, length: float, with_bg: bool, rounded_bg: bool = False) -> Image.Image:
    """Draw the spindle on a size x size canvas. `length` is a fraction of the canvas."""
    s = size * SS
    img = Image.new("RGBA", (s, s), BG + (255,) if with_bg else (0, 0, 0, 0))
    if with_bg and rounded_bg:
        img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        ImageDraw.Draw(img).rounded_rectangle((0, 0, s - 1, s - 1), radius=int(s * 0.22), fill=BG + (255,))

    # Draw the upright spindle on its own layer, then rotate 45 degrees.
    layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w = s * length * 0.16          # rectangle width
    h = s * length                 # rectangle length
    cx = cy = s / 2
    x0, x1 = cx - w / 2, cx + w / 2
    y0, y1 = cy - h / 2, cy + h / 2
    d.rectangle((x0, y0, x1, y1), fill=BODY)

    # Thread wound around the middle: a band of tilted stripes.
    band = h * 0.32
    by0, by1 = cy - band / 2, cy + band / 2
    d.rectangle((x0, by0, x1, by1), fill=THREAD)
    stripes = 6
    step = band / stripes
    tilt = w * 0.18
    for i in range(1, stripes):
        y = by0 + i * step
        d.line((x0, y + tilt, x1, y - tilt), fill=THREAD_DARK, width=max(2, int(s * 0.006)))

    layer = layer.rotate(-45, resample=Image.BICUBIC, center=(cx, cy))
    img.alpha_composite(layer)
    return img.resize((size, size), Image.LANCZOS)


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print("wrote", path.relative_to(RES.parent.parent.parent.parent))


def main() -> None:
    legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for dens, px in legacy.items():
        save(render(px, 0.74, with_bg=True, rounded_bg=True), RES / f"mipmap-{dens}" / "ic_launcher.png")

    # Adaptive icon: 108dp canvas, foreground kept inside the central 66% safe zone.
    adaptive = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for dens, px in adaptive.items():
        save(render(px, 0.56, with_bg=False), RES / f"mipmap-{dens}" / "ic_launcher_foreground.png")

    (RES / "values").mkdir(exist_ok=True)
    (RES / "values" / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        '    <color name="ic_launcher_background">#14172B</color>\n</resources>\n',
        encoding="utf-8",
    )
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n',
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
