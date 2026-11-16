"""
edit.py — montage du teaser « SOON. » à partir des plans rendus par render_shots.py.

    python edit.py --frames DIR --audio music.wav --out teaser.mp4 [--format yt|tiktok] [--preview N]

yt     : 1920x1080 (YouTube)
tiktok : 1080x1920 (TikTok / Shorts / Reels) — image recadrée en 3:4 sur fond flou de la même image

Montage : coupes sur le temps, petit « punch » de zoom à chaque coupe, texte central dont l'intérieur
montre l'image en négatif, tremblement caméra au décollage, flash + décalage RVB sur les trois temps forts,
barres noires qui s'ouvrent au début et se referment à la fin, grain léger.
"""

import argparse
import math
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

FPS = 30
# (dossier, images) — doit rester identique à SHOTS de render_shots.py
SHOTS = [("00_base_aerienne", 16), ("01_petard_contre_plongee", 11), ("02_rangee_travelling", 11), ("03_retro_gros_plan", 11),
         ("04_tour", 11), ("05_jouet_arbres", 11), ("06_carton_plongee", 11), ("07_allee", 11), ("08_decollage", 33),
         ("09_v2_cote", 11), ("10_saturne_dessous", 11), ("11_reutilisable_orbite", 11), ("12_soyouz_dessus", 11),
         ("13_marteau_proche", 11), ("14_jet_poursuite", 11), ("15_vapeur_cote", 11), ("16_soucoupe", 11), ("17_meduse", 11),
         ("18_cristaux_dessous", 11), ("19_double_coque", 11), ("20_magma_proche", 11), ("21_voile_solaire", 22),
         ("22_dragon", 11), ("23_phenix", 11), ("24_requin", 11), ("25_baleine", 11), ("26_samourai", 11),
         ("27_trou_noir", 11), ("28_legende", 33)]
HITS = {9: 1.0, 22: 0.8, 28: 1.2}      # plans qui tombent sur un temps fort : flash + décalage RVB
LIFTOFF, FINAL = 8, 28
TAIL = 22                               # images noires à la fin
OPEN, CLOSE = 14, 12                    # durée d'ouverture / fermeture des barres
TITLE = "SOON."
CAPTION = "+1 ROCKET LAUNCH"
FONT = "/usr/share/fonts/opentype/inter/InterDisplay-Black.otf"
FONT2 = "/usr/share/fonts/opentype/inter/InterDisplay-ExtraBold.otf"

TIMELINE = []
for si, (name, n) in enumerate(SHOTS):
    for f in range(n):
        TIMELINE.append((si, f))
NV = len(TIMELINE)
rng = np.random.default_rng(3)


def text_mask(size, text, font_path, px, tracking=0.0):
    """Masque L du texte centré, avec interlettrage (en fraction du corps)."""
    font = ImageFont.truetype(font_path, px)
    ws = [font.getlength(ch) for ch in text]
    total = sum(ws) + tracking * px * (len(text) - 1)
    im = Image.new("L", size, 0)
    d = ImageDraw.Draw(im)
    x = (size[0] - total) / 2
    asc, desc = font.getmetrics()
    bb = font.getbbox("SOON")
    y = (size[1] - (bb[3] + bb[1])) / 2
    for ch, w in zip(text, ws):
        d.text((x, y), ch, font=font, fill=255)
        x += w + tracking * px
    return im


def zoom(im, s, dx=0.0, dy=0.0, out=None):
    """Zoom centré (s >= 1) avec décalage en pixels source ; renvoie une image de taille out."""
    w, h = im.size
    cw, ch = w / s, h / s
    x0 = (w - cw) / 2 + dx
    y0 = (h - ch) / 2 + dy
    x0 = min(max(x0, 0), w - cw)
    y0 = min(max(y0, 0), h - ch)
    return im.resize(out or im.size, Image.BICUBIC, box=(x0, y0, x0 + cw, y0 + ch))


def grade(a):
    """Étalonnage : contraste en S doux, saturation, légère chaleur dans les hautes lumières."""
    a = a / 255.0
    a = a + 0.10 * (a - 0.5) * (1 - (2 * a - 1) ** 2) * 2.2          # S doux
    lum = a @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    a = lum[..., None] + (a - lum[..., None]) * 1.16
    return np.clip(a, 0, 1) * 255.0


def punch(k, amp, n=5):
    """Impulsion qui retombe : amp à l'image 0 d'un plan, 0 après n images."""
    return amp * (1 - k / n) ** 2 if k < n else 0.0


def render(a):
    W, H = (1920, 1080) if a.format == "yt" else (1080, 1920)
    if a.format == "yt":
        PW, PH, PY = W, H, 0                       # zone image
        title_px, cap_px = 330, 34
    else:
        PW, PH = 1080, 1440
        PY = (H - PH) // 2
        title_px, cap_px = 300, 34
    cy = H // 2
    base_mask = text_mask((W, H), TITLE, FONT, title_px, -0.035)
    cap_mask = text_mask((W, H), CAPTION, FONT2, cap_px, 0.42)
    cap_dy = int(title_px * 0.56)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    vig = 1 - 0.22 * np.clip(((xx - W / 2) / (W * 0.62)) ** 2 + ((yy - H / 2) / (H * 0.62)) ** 2, 0, 1)
    vig = vig[..., None].astype(np.float32)

    frames = range(NV + TAIL)
    if a.preview:
        frames = [int(x) for x in a.preview.split(",")]
        os.makedirs(a.out, exist_ok=True)
        pipe = None
    else:
        cmd = ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
               "-i", a.audio, "-c:v", "libx264", "-preset", "slow", "-crf", "15", "-pix_fmt", "yuv420p", "-profile:v", "high",
               "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709",
               "-c:a", "aac", "-b:a", "256k", "-af", f"afade=t=out:st={(NV + TAIL) / FPS - 0.5}:d=0.5",
               "-t", f"{(NV + TAIL) / FPS:.3f}", "-movflags", "+faststart", a.out]
        pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE)

    cache = {}
    for g in frames:
        if g >= NV:
            out = np.zeros((H, W, 3), np.uint8)
        else:
            si, k = TIMELINE[g]
            name, n = SHOTS[si]
            src = Image.open(os.path.join(a.frames, name, f"{k:03d}.png")).convert("RGB")
            sw, sh = src.size
            # --- mouvement 2D ajouté au mouvement 3D : punch de coupe, tremblement
            hit = HITS.get(si, 0.0)
            z = 1.02 + punch(k, 0.035 + 0.03 * hit)
            dx = dy = 0.0
            if si == LIFTOFF:
                amp = 5.0 * (k / n) ** 0.7 + 2
                dx, dy = rng.normal(0, amp), rng.normal(0, amp)
                z += 0.02
            if hit:
                amp = punch(k, 14 * hit, 7)
                dx, dy = dx + rng.normal(0, amp), dy + rng.normal(0, amp)
            if si == FINAL:
                z += 0.03 * (k / n)                                   # lente poussée finale
            if a.format == "yt":
                pic = zoom(src, z, dx, dy, (PW, PH))
                bg = None
            else:
                cw = sh * 3 / 4                                       # recadrage 3:4 centré
                box_im = src.crop((int((sw - cw) / 2), 0, int((sw + cw) / 2), sh))
                pic = zoom(box_im, z, dx * 0.6, dy, (PW, PH))
                bg = zoom(src, 1.0, 0, 0, (W * 16 // 9 // 4 * 4 // 3, H // 3)).filter(ImageFilter.GaussianBlur(14))
                bw = bg.size[0]
                bg = bg.crop(((bw - W // 3) // 2, 0, (bw + W // 3) // 2, H // 3)).resize((W, H), Image.BILINEAR)
            p = np.asarray(pic, np.float32)
            # halo des hautes lumières
            small = pic.resize((PW // 4, PH // 4), Image.BILINEAR)
            hl = np.clip((np.asarray(small, np.float32) - 190) * 3.0, 0, 255).astype(np.uint8)
            glow = Image.fromarray(hl).filter(ImageFilter.GaussianBlur(9)).resize((PW, PH), Image.BILINEAR)
            p = grade(np.minimum(p + np.asarray(glow, np.float32) * 0.28, 255))
            if a.format == "yt":
                canvas = p
            else:
                canvas = grade(np.asarray(bg, np.float32)) * 0.42
                canvas[PY:PY + PH] = p
            if hit and k < 4:                                         # décalage RVB sur le temps fort
                s = int(round((10 - 3 * k) * hit))
                canvas[..., 0] = np.roll(canvas[..., 0], s, 1)
                canvas[..., 2] = np.roll(canvas[..., 2], -s, 1)
            # --- texte : l'intérieur des lettres montre l'image en négatif, zoomée
            ts = 1.0 + punch(k, 0.07 + 0.06 * hit, 5)
            if si == FINAL:
                ts *= 1.0 + 0.04 * (k / n)
            m_im = base_mask if abs(ts - 1) < 1e-4 else zoom_out_mask(base_mask, ts)
            if si == LIFTOFF:
                m_im = m_im.transform(m_im.size, Image.AFFINE, (1, 0, -dx * 0.5, 0, 1, -dy * 0.5))
            m = np.asarray(m_im, np.float32)[..., None] / 255.0
            inner = Image.fromarray(canvas.astype(np.uint8))
            inner = zoom(inner, 1.35, 0, 0)
            neg = 255.0 - np.asarray(inner, np.float32)
            lum = neg @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
            neg = np.clip(lum[..., None] + (neg - lum[..., None]) * 1.35, 0, 255)
            neg = neg * 0.82 + 255 * 0.18                             # éclaircit : le texte reste lisible partout
            sh_im = m_im.filter(ImageFilter.GaussianBlur(10)).transform(m_im.size, Image.AFFINE, (1, 0, 0, 0, 1, -8))
            shadow = np.asarray(sh_im, np.float32)[..., None] / 255.0
            canvas = canvas * (1 - 0.38 * shadow)
            canvas = canvas * (1 - m) + neg * m
            if si == FINAL and k >= 8:                                # nom du jeu, sous le titre
                al = min(1.0, (k - 8) / 5.0)
                off = int((1 - al) * 14)
                cm = np.asarray(cap_mask.transform(cap_mask.size, Image.AFFINE, (1, 0, 0, 0, 1, -(cap_dy + off))), np.float32)[..., None] / 255.0
                cs = np.asarray(cap_mask.filter(ImageFilter.GaussianBlur(5)).transform(cap_mask.size, Image.AFFINE, (1, 0, 0, 0, 1, -(cap_dy + off + 3))), np.float32)[..., None] / 255.0
                canvas = canvas * (1 - 0.5 * cs * al)
                canvas = canvas * (1 - cm * al) + 255.0 * cm * al
            canvas = canvas * vig
            if hit and k < 3:                                         # flash blanc
                canvas = canvas + (255 - canvas) * (0.55, 0.28, 0.1)[k] * min(1.0, hit)
            canvas = canvas + rng.normal(0, 2.2, (H, W, 1)).astype(np.float32)   # grain
            # --- barres noires : ouverture / fermeture
            op = 1.0
            if g < OPEN:
                op = 1 - (1 - g / OPEN) ** 3
            elif g >= NV - CLOSE:
                op = 1 - ((g - (NV - CLOSE) + 1) / CLOSE) ** 2.2
            if op < 1:
                half = int(H / 2 * op)
                canvas[: cy - half] = 0
                canvas[cy + half:] = 0
            out = np.clip(canvas, 0, 255).astype(np.uint8)
        if pipe:
            pipe.stdin.write(out.tobytes())
        else:
            Image.fromarray(out).save(os.path.join(a.out, f"{a.format}_{g:04d}.jpg"), quality=90)
    if pipe:
        pipe.stdin.close()
        pipe.wait()
        print("ok", a.out, f"{(NV + TAIL) / FPS:.2f} s")


def zoom_out_mask(mask, s):
    """Agrandit le masque du texte autour du centre (s > 1)."""
    w, h = mask.size
    return mask.transform((w, h), Image.AFFINE, (1 / s, 0, w / 2 * (1 - 1 / s), 0, 1 / s, h / 2 * (1 - 1 / s)), Image.BICUBIC)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--frames", required=True)
    ap.add_argument("--audio")
    ap.add_argument("--out", required=True)
    ap.add_argument("--format", default="yt", choices=["yt", "tiktok"])
    ap.add_argument("--preview", default="", help="numéros d'images à sortir en JPEG dans --out (pas de vidéo)")
    render(ap.parse_args())
