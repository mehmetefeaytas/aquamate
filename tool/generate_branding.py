#!/usr/bin/env python3
"""AquaMate marka görsellerini üretir.

Çıktılar:
  assets/branding/icon_1024.png        -> App Store / iOS ikonu (alfa yok)
  assets/branding/icon_foreground.png  -> Android adaptive icon ön planı
  assets/branding/splash_logo.png      -> Açılış ekranı logosu

Kullanım: python3 tool/generate_branding.py
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "branding"
SCALE = 4  # supersampling


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))  # type: ignore[return-value]


def gradient(size: int, start: tuple[int, int, int], end: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGB", (size, size), start)
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / max(1, size - 1)
        color = lerp(start, end, t)
        draw.line([(0, y), (size, y)], fill=color)
    return image


def _quad(p0, p1, p2, t: float) -> tuple[float, float]:
    """İkinci dereceden Bezier noktası."""
    x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
    y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
    return (x, y)


def draw_symbol(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    r: float,
    color: tuple[int, int, int, int],
    leaf: bool = True,
) -> None:
    """Damlacık: alt yuvarlak gövde + üstte sivri uç (birleşim maskesi)."""
    alpha = color[3] if len(color) > 3 else 255
    bulb_cy = cy + r * 0.18

    # Gövde (daire) ve tepe (üçgen) tek renkte çizilir; üst üste binme sorun
    # çıkarmaz çünkü ikisi de aynı opak renktir.
    draw.ellipse(
        [cx - r, bulb_cy - r, cx + r, bulb_cy + r],
        fill=color,
    )
    # Üçgenin kenarları daireye TEPETEN teğet olacak şekilde seçilir
    # (teğet noktası: x = ±0.864r, y = -0.505r). Böylece omuzda kırılma olmaz.
    shoulder_y = bulb_cy - r * 0.505
    tip = (cx, cy - r * 1.80)
    draw.polygon(
        [
            tip,
            (cx + r * 0.864, shoulder_y),
            (cx - r * 0.864, shoulder_y),
        ],
        fill=color,
    )

    if not leaf:
        return

    # Yaprak: iki Bezier eğrisiyle, damlacığın sağ-alt bölümünde.
    base = (cx - r * 0.14, cy + r * 0.66)
    tip_leaf = (cx + r * 0.58, cy - r * 0.22)
    control_a = (cx - r * 0.30, cy + r * 0.02)
    control_b = (cx + r * 0.54, cy + r * 0.40)

    leaf_points: list[tuple[float, float]] = []
    for i in range(31):
        leaf_points.append(_quad(base, control_a, tip_leaf, i / 30))
    for i in range(1, 31):
        leaf_points.append(_quad(tip_leaf, control_b, base, i / 30))

    draw.polygon(leaf_points, fill=(16, 185, 129, alpha))
    draw.line(
        [base, tip_leaf],
        fill=(255, 255, 255, alpha),
        width=max(2, int(r * 0.05)),
    )


def build_icon() -> Image.Image:
    size = 1024
    big = size * SCALE
    base = gradient(big, (47, 128, 237), (86, 204, 242)).convert("RGBA")
    draw = ImageDraw.Draw(base)
    draw_symbol(
        draw,
        cx=big / 2,
        cy=big * 0.545,
        r=big * 0.20,
        color=(255, 255, 255, 255),
    )
    return base.resize((size, size), Image.LANCZOS).convert("RGB")


def build_foreground() -> Image.Image:
    size = 1024
    big = size * SCALE
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_symbol(
        draw,
        cx=big / 2,
        cy=big * 0.53,
        r=big * 0.155,
        color=(255, 255, 255, 255),
    )
    return image.resize((size, size), Image.LANCZOS)


def build_splash() -> Image.Image:
    size = 768
    big = size * SCALE
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_symbol(
        draw,
        cx=big / 2,
        cy=big * 0.50,
        r=big * 0.185,
        color=(47, 128, 237, 255),
    )
    return image.resize((size, size), Image.LANCZOS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    icon = build_icon()
    icon.save(OUT / "icon_1024.png", "PNG", optimize=True)
    build_foreground().save(OUT / "icon_foreground.png", "PNG", optimize=True)
    build_splash().save(OUT / "splash_logo.png", "PNG", optimize=True)
    print("Yazıldı:", ", ".join(sorted(p.name for p in OUT.iterdir())))


if __name__ == "__main__":
    main()
