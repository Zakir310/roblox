"""
contact_sheet.py — assemble les 40 aperçus en une planche "4 mondes × 10 fusées".

Usage : python contact_sheet.py [--previews ../../assets/rockets/previews] [--out ../../assets/rockets/planche_40_fusees.png]
"""

import argparse
import json
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def load_font(size):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                 "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--previews", default=os.path.join(HERE, "..", "..", "assets", "rockets", "previews"))
    ap.add_argument("--catalog", default=os.path.join(HERE, "..", "..", "assets", "rockets", "catalog.json"))
    ap.add_argument("--out", default=os.path.join(HERE, "..", "..", "assets", "rockets", "planche_40_fusees.png"))
    ap.add_argument("--thumb", type=int, default=200)
    args = ap.parse_args()

    with open(args.catalog, encoding="utf-8") as f:
        cat = json.load(f)
    worlds = {int(k): v for k, v in cat["worlds"].items()}
    rockets = {r["id"]: r for r in cat["rockets"]}

    tw = args.thumb
    th = int(tw * 1.25)
    label_h = 26
    header_w = 230
    pad = 8
    title_h = 80
    cols, rows = 10, 4
    W = header_w + cols * (tw + pad) + pad
    H = title_h + rows * (th + label_h + pad) + pad

    img = Image.new("RGB", (W, H), (18, 19, 26))
    draw = ImageDraw.Draw(img)
    f_title = load_font(34)
    f_world = load_font(22)
    f_sub = load_font(13)
    f_lbl = load_font(14)

    draw.text((W // 2, 22), "40 FUSÉES — PROGRESSION CONTINUE", font=f_title, fill=(255, 255, 255), anchor="mm")
    draw.text((W // 2, 58), "De la première fusée… à la légende ultime !", font=f_sub, fill=(200, 200, 210), anchor="mm")

    for row in range(rows):
        wid = row + 1
        wd = worlds[wid]
        y0 = title_h + row * (th + label_h + pad)
        band_color = tuple(int(c * 0.25) for c in hex_to_rgb(wd["bg"]))
        draw.rectangle([0, y0, W, y0 + th + label_h], fill=band_color)
        draw.text((pad + 6, y0 + 18), f"MONDE {wid}", font=f_world, fill=hex_to_rgb(wd["color"]))
        draw.text((pad + 6, y0 + 48), wd["name"].upper(), font=f_world, fill=(255, 255, 255))
        # sous-titre sur deux lignes max
        words = wd["subtitle"].split()
        lines, cur = [], ""
        for wrd in words:
            if draw.textlength(cur + " " + wrd, font=f_sub) > header_w - 20:
                lines.append(cur.strip())
                cur = wrd
            else:
                cur += " " + wrd
        lines.append(cur.strip())
        for i, ln in enumerate(lines[:3]):
            draw.text((pad + 6, y0 + 82 + i * 16), ln, font=f_sub, fill=(210, 210, 220))

        for col in range(cols):
            rid = row * 10 + col + 1
            x0 = header_w + pad + col * (tw + pad)
            path = os.path.join(args.previews, f"Rocket_{rid:02d}.png")
            if os.path.exists(path):
                thumb = Image.open(path).convert("RGB").resize((tw, th), Image.LANCZOS)
                img.paste(thumb, (x0, y0 + 4))
            else:
                draw.rectangle([x0, y0 + 4, x0 + tw, y0 + 4 + th], fill=(40, 40, 50))
            r = rockets.get(rid)
            label = f"{rid:02d}  {r['name']}" if r else f"{rid:02d}"
            draw.rectangle([x0, y0 + 4 + th, x0 + tw, y0 + 4 + th + label_h - 4], fill=hex_to_rgb(wd["color"]))
            draw.text((x0 + tw // 2, y0 + 4 + th + (label_h - 4) // 2), label, font=f_lbl, fill=(10, 10, 12), anchor="mm")

    img.save(args.out, optimize=True)
    print(f"{args.out} écrit ({W}x{H})")


if __name__ == "__main__":
    main()
