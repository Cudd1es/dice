#!/usr/bin/env python3
"""Generate the app icon and iMessage app icon set (a d20 on a purple gradient).

Usage: python3 scripts/make_icons.py   (requires Pillow)
"""
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
TOP, BOTTOM = (88, 60, 190), (34, 22, 92)
FACE, EDGE, ACCENT = (250, 248, 255), (60, 40, 140), (255, 196, 64)

# (filename, idiom, size in points, scale) for the iMessage app icon set.
MESSAGES_ICONS = [
    ("icon-29@2x.png", "iphone", (29, 29), 2),
    ("icon-29@3x.png", "iphone", (29, 29), 3),
    ("icon-29-ipad@2x.png", "ipad", (29, 29), 2),
    ("icon-60x45@2x.png", "iphone", (60, 45), 2),
    ("icon-60x45@3x.png", "iphone", (60, 45), 3),
    ("icon-67x50@2x.png", "ipad", (67, 50), 2),
    ("icon-74x55@2x.png", "ipad", (74, 55), 2),
    ("icon-1024x768.png", "ios-marketing", (1024, 768), 1),
    # Required by App Store Connect validation; the simulator and device builds do not check these.
    ("icon-27x20@2x.png", "universal", (27, 20), 2),
    ("icon-27x20@3x.png", "universal", (27, 20), 3),
    ("icon-32x24@2x.png", "universal", (32, 24), 2),
    ("icon-32x24@3x.png", "universal", (32, 24), 3),
]


def font(size):
    for name in ("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", "/System/Library/Fonts/SFNSRounded.ttf",
                 "/System/Library/Fonts/Helvetica.ttc"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def render(width, height):
    """Draws at 2x and downsamples so edges stay smooth at every size."""
    w, h = width * 2, height * 2
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        draw.line([(0, y), (w, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))

    # Pointy-top hexagon silhouette of a d20, with its front triangle and edges.
    cx, cy, r = w / 2, h / 2, min(w, h) * 0.36
    hexagon = [(cx + r * math.sin(math.radians(a)), cy - r * math.cos(math.radians(a))) for a in range(0, 360, 60)]
    inner = [(cx, cy - r * 0.62), (cx - r * 0.66, cy + r * 0.38), (cx + r * 0.66, cy + r * 0.38)]
    stroke = max(2, round(r * 0.045))

    draw.polygon(hexagon, fill=FACE)
    draw.polygon(inner, fill=ACCENT)
    for a, b in zip(inner, inner[1:] + inner[:1]):
        draw.line([a, b], fill=EDGE, width=stroke)
    # Hexagon vertices run clockwise from the top; each inner corner fans out to the three nearest.
    links = {0: [5, 0, 1], 1: [3, 4, 5], 2: [1, 2, 3]}
    for i, outer in links.items():
        for j in outer:
            draw.line([inner[i], hexagon[j]], fill=EDGE, width=stroke)
    draw.line(hexagon + [hexagon[0]], fill=EDGE, width=stroke, joint="curve")

    label = font(round(r * 0.42))
    draw.text((cx, cy + r * 0.06), "20", font=label, fill=EDGE, anchor="mm")
    return img.resize((width, height), Image.LANCZOS)


def write_set(folder, images, info):
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "Contents.json").write_text(json.dumps({"images": images, "info": info}, indent=2) + "\n")


def main():
    info = {"author": "xcode", "version": 1}

    app = ROOT / "DiceApp/Assets.xcassets/AppIcon.appiconset"
    app.mkdir(parents=True, exist_ok=True)
    render(1024, 1024).save(app / "icon-1024.png")
    write_set(app, [{"filename": "icon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}], info)

    messages = ROOT / "DiceMessages/Assets.xcassets/iMessage App Icon.stickersiconset"
    messages.mkdir(parents=True, exist_ok=True)
    entries = []
    for filename, idiom, (pw, ph), scale in MESSAGES_ICONS:
        render(pw * scale, ph * scale).save(messages / filename)
        entry = {"filename": filename, "idiom": idiom, "size": f"{pw}x{ph}", "scale": f"{scale}x"}
        if idiom in ("ios-marketing", "universal"):
            entry["platform"] = "ios"
        entries.append(entry)
    write_set(messages, entries, info)

    for catalog in (app.parent, messages.parent):
        (catalog / "Contents.json").write_text(json.dumps({"info": info}, indent=2) + "\n")


if __name__ == "__main__":
    main()
