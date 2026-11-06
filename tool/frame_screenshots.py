#!/usr/bin/env python3
"""Mağaza ekran görüntülerini başlık şeritli (1320x2868) sürümlere çevirir.

Girdi : store/screenshots/*.png (simülatör ham çıktıları)
Çıktı : store/screenshots/framed/*.png

Kullanım: python3 tool/frame_screenshots.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "store" / "screenshots"
OUT = SRC / "framed"

CANVAS = (1320, 2868)
BG_TOP = (244, 248, 251)
BG_BOTTOM = (226, 238, 250)

CAPTIONS: dict[str, tuple[str, str]] = {
    "1_home": ("Günlük hidrasyonun", "Su, kafein ve atık tek ekranda"),
    "2_picker": ("Ambalajını seç", "9 kap türü, tek dokunuşla kayıt"),
    "3_eco": ("Sürdürülebilirlik skorun", "Atık ve karbon ayak izin ölçülür"),
    "4_caffeine": ("Kafein kontrolü", "Limit, kaynaklar ve son kafein saati"),
    "5_hydration": ("Dönemsel istatistik", "Hafta, ay ve yıl bazında takip"),
    "6_library": ("22 içecek + kendi tarifin", "Hidrasyon ve kafein değerini sen belirle"),
    "7_eco_report": ("Ay sonu raporun", "\"Şunu tercih etseydin\" karşılaştırması"),
    "8_settings": ("Her şey senin ayarın", "Hedef, kafein, uyku ve hatırlatmalar"),
}


def font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/SFNSDisplay-Bold.otf" if bold else "",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "",
    ]
    for path in candidates:
        if path and Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def vertical_gradient(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size, BG_TOP)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(
            round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)
        )
        draw.line([(0, y), (width, y)], fill=color)
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    title_font = font(78, bold=True)
    sub_font = font(40, bold=False)

    for path in sorted(SRC.glob("*.png")):
        if path.parent == OUT:
            continue
        key = path.stem
        title, subtitle = CAPTIONS.get(key, ("AquaMate", ""))

        canvas = vertical_gradient(CANVAS).convert("RGB")
        draw = ImageDraw.Draw(canvas)

        # Üst şerit: başlık + alt başlık
        top = 74
        for line in (title, subtitle):
            if not line:
                continue
            f = title_font if line == title else sub_font
            bbox = draw.textbbox((0, 0), line, font=f)
            w = bbox[2] - bbox[0]
            h = bbox[3] - bbox[1]
            color = (30, 41, 59) if line == title else (100, 116, 139)
            draw.text(
                ((CANVAS[0] - w) / 2, top - bbox[1]),
                line,
                font=f,
                fill=color,
            )
            top += h + (34 if line == title else 0)

        shot = Image.open(path).convert("RGB")
        # Ekran görüntüsünü hafifçe küçültüp yuvarlatılmış kart içine koy.
        target_w = 1120
        ratio = target_w / shot.width
        target_h = round(shot.height * ratio)
        shot = shot.resize((target_w, target_h), Image.LANCZOS)

        card_top = top + 40
        radius = 44
        mask = Image.new("L", (target_w, target_h), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, target_w - 1, target_h - 1], radius=radius, fill=255
        )
        x = (CANVAS[0] - target_w) // 2
        canvas.paste(shot, (x, card_top), mask)

        out_path = OUT / f"{key}.png"
        canvas.save(out_path, "PNG", optimize=True)
        print(f"{out_path.name}: {canvas.size[0]}x{canvas.size[1]}")

    print(f"Toplam {len(list(OUT.glob('*.png')))} görsel yazıldı.")


if __name__ == "__main__":
    main()
