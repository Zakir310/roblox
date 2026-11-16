"""
make_music.py — bande-son originale du teaser, synthétisée (aucun sample, aucun droit à gérer).

    python make_music.py OUT.wav

Calée sur le montage : 30 i/s, intro de 16 images, puis une coupe toutes les 11 images (~164 BPM ressenti
en demi-tempo, façon trap). Sections : A (7 coupes) · décollage (3) · B ciel (12) · bascule espace (2) ·
C espace (6) · impact final (3) + queue.
"""

import sys

import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve

SR = 44100
CUT = 11 / 30.0
T0 = 16 / 30.0
TOTAL = 14.2
rng = np.random.default_rng(7)
N = int(TOTAL * SR)
BUS = {k: np.zeros((N, 2)) for k in ("drums", "bass", "lead", "fx")}


def t_of(cut):
    return T0 + cut * CUT


def env(n, a, d, curve=4.0):
    t = np.arange(n) / SR
    return np.minimum(1, t / max(a, 1e-4)) * np.exp(-t * curve / d)


def filt(x, kind, f, order=2):
    return sosfilt(butter(order, f, kind, fs=SR, output="sos"), x, axis=0)


def put(bus, x, t, gain=1.0, pan=0.0):
    i = int(t * SR)
    if x.ndim == 1:
        x = np.stack([x * (1 - max(0, pan)), x * (1 + min(0, pan))], 1)
    n = min(len(x), N - i)
    if n > 0:
        BUS[bus][i:i + n] += x[:n] * gain


def kick(punch=1.0):
    n = int(0.42 * SR)
    t = np.arange(n) / SR
    f = 44 + 130 * np.exp(-t * 34)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.001, 0.36)
    x += filt(rng.standard_normal(n), "high", 3000) * env(n, 0.0005, 0.012) * 0.25
    return np.tanh(x * 2.2 * punch) * 0.9


def snare():
    n = int(0.3 * SR)
    x = np.zeros(n)
    for dly in (0.0, 0.011, 0.023):  # clap : trois claquements serrés
        k = int(dly * SR)
        x[k:] += filt(rng.standard_normal(n - k), "band", (900, 4200)) * env(n - k, 0.001, 0.11)
    t = np.arange(n) / SR
    x += np.sin(2 * np.pi * 185 * t) * env(n, 0.001, 0.07) * 0.6
    return np.tanh(x * 1.4) * 0.7


def hat(open_=False):
    n = int((0.22 if open_ else 0.05) * SR)
    return filt(rng.standard_normal(n), "high", 7500) * env(n, 0.0005, 0.16 if open_ else 0.03) * 0.5


def bass808(freq, dur, glide=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = freq * (1 + glide * np.exp(-t * 18))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR)
    e = np.minimum(1, t / 0.004) * np.exp(-t * 2.2 / dur) * np.minimum(1, (dur - t) / 0.03)
    return np.tanh(x * 2.6) * e * 0.8  # la saturation ajoute les harmoniques audibles sur téléphone


def pluck(freq, dur=0.5, bright=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for det in (-0.006, 0.0, 0.007):
        ph = (freq * (1 + det) * t) % 1.0
        x += 2 * ph - 1 + 0.5 * np.sign(np.sin(2 * np.pi * freq * (1 + det) * 0.5 * t)) * 0.3
    e = env(n, 0.002, dur * 0.7, 5)
    lo = filt(x, "low", min(9000, 900 * bright + freq * 2))
    hi = filt(x, "low", min(12000, 5200 * bright))
    k = np.exp(-t * 16)
    return (hi * k + lo * (1 - k)) * e * 0.22


def noise_sweep(dur, f0, f1, rise=True):
    n = int(dur * SR)
    x = rng.standard_normal((n, 2))
    out = np.zeros((n, 2))
    blocks = 48
    edges = np.linspace(0, n, blocks + 1).astype(int)
    for b in range(blocks):  # balayage par blocs (passe-bande qui monte ou descend)
        f = f0 * (f1 / f0) ** (b / (blocks - 1))
        seg = filt(x, "band", (f * 0.6, min(f * 1.6, 20000)))
        w = np.zeros(n)
        a, z = edges[b], edges[b + 1]
        w[a:z] = 1
        w = np.convolve(w, np.hanning(max(8, (z - a))) / max(4, (z - a) / 2), "same")
        out += seg * w[:, None]
    t = np.linspace(0, 1, n)
    amp = t ** 2 if rise else (1 - t) ** 2
    return out * amp[:, None] * 0.35


def impact():
    n = int(3.2 * SR)
    t = np.arange(n) / SR
    f = 34 + 70 * np.exp(-t * 9)
    x = np.tanh(np.sin(2 * np.pi * np.cumsum(f) / SR) * 3) * np.exp(-t * 1.5)
    nz = filt(rng.standard_normal(n), "low", 1800) * np.exp(-t * 4.5) * 0.8
    cr = filt(rng.standard_normal(n), "high", 5000) * np.exp(-t * 3.0) * 0.25
    return (x + nz + cr) * 0.8


F = {"F": 174.61, "G": 196.0, "Ab": 207.65, "Bb": 233.08, "C": 261.63, "Db": 277.18, "Eb": 311.13}


def note(nm, octv):
    return F[nm] * 2 ** (octv - 3)


# ---------------------------------------------------------------- arrangement
# intro : montée
put("fx", noise_sweep(T0 + 0.02, 300, 9000), 0.0, 0.8)
n = int(T0 * SR)
tt = np.arange(n) / SR
put("fx", np.sin(2 * np.pi * np.cumsum(110 * (1 + 2.5 * (tt / T0) ** 2)) / SR) * (tt / T0) ** 2 * 0.25, 0.0)

# section A (coupes 0-6) : kick + charley + basse, mélodie filtrée
A_MEL = [("F", 4), None, ("Ab", 4), ("C", 5), None, ("Eb", 5), ("C", 5)]
for c in range(7):
    t = t_of(c)
    if c in (0, 3, 5):
        put("drums", kick(), t)
        put("bass", bass808(note("F", 1) if c < 5 else note("Eb", 1), CUT * 1.9, 0.5), t)
    if c == 4:
        put("drums", snare(), t)
    put("drums", hat(), t, 0.8, 0.2)
    put("drums", hat(), t + CUT / 2, 0.45, -0.2)
    if A_MEL[c]:
        put("lead", pluck(note(*A_MEL[c]), 0.5, 0.55), t, 0.8)

# décollage (coupes 7-9) : grondement + montée, la batterie se tait
put("drums", kick(1.3), t_of(7))
put("fx", noise_sweep(3 * CUT, 120, 7000), t_of(7), 1.5)
n = int(3 * CUT * SR)
tt = np.arange(n) / SR
u = tt / (3 * CUT)
rumble = np.tanh(np.sin(2 * np.pi * np.cumsum(48 + 60 * u ** 2) / SR) * 3) * (0.35 + 0.65 * u) * 0.5
put("bass", rumble * np.minimum(1, (3 * CUT - tt) / 0.02), t_of(7))
for k in range(12):  # roulement de caisse claire qui accélère
    put("drums", snare(), t_of(8) + 2 * CUT * (k / 12) ** 0.75, 0.25 + 0.05 * k)

# section B (coupes 10-21) : plein régime
B_MEL = [("F", 5), ("Ab", 5), ("C", 6), ("Ab", 5), ("G", 5), ("Eb", 5), ("F", 5), ("C", 5), ("Db", 5), ("F", 5), ("Ab", 5), ("C", 6)]
B_BASS = {0: ("F", 1), 3: ("F", 1), 5: ("Ab", 1), 8: ("Db", 1), 11: ("C", 1)}
put("fx", impact()[: int(1.2 * SR)], t_of(10), 0.55)
for c in range(12):
    t = t_of(10 + c)
    if c in (0, 3, 5, 8, 10, 11):
        put("drums", kick(), t)
    if c in B_BASS:
        put("bass", bass808(note(*B_BASS[c]), CUT * 2.4, 0.6), t)
    if c in (4, 9):
        put("drums", snare(), t)
    put("drums", hat(), t, 0.9, 0.25)
    put("drums", hat(), t + CUT / 2, 0.5, -0.25)
    if c in (2, 7):  # roulés de charley
        for k in range(4):
            put("drums", hat(), t + k * CUT / 4, 0.35 + 0.1 * k, -0.3 + 0.2 * k)
    if c in (6,):
        put("drums", hat(True), t + CUT / 2, 0.7)
    put("lead", pluck(note(*B_MEL[c]), 0.55, 1.0), t, 1.0, 0.15 if c % 2 else -0.15)
    put("lead", pluck(note(B_MEL[c][0], B_MEL[c][1] - 1), 0.4, 0.7), t, 0.5)

# bascule vers l'espace (coupes 22-23) : aspiration
put("fx", noise_sweep(2 * CUT, 9000, 400, rise=True), t_of(22), 1.3)
put("bass", bass808(note("C", 1), 2 * CUT, 0.0), t_of(22), 0.8)
put("lead", pluck(note("C", 6), 0.7, 1.2), t_of(22), 0.9)
put("lead", pluck(note("Eb", 6), 0.6, 1.2), t_of(23), 0.9)
for k in range(6):
    put("drums", snare(), t_of(23) + CUT * k / 6, 0.3 + 0.08 * k)

# section C (coupes 24-29) : espace, mélodie à l'octave, charley doublé
C_MEL = [("F", 6), ("C", 6), ("Ab", 5), ("F", 6), ("Eb", 6), ("C", 6)]
C_BASS = {0: ("F", 1), 2: ("F", 1), 3: ("Db", 1), 5: ("Eb", 1)}
put("fx", impact()[: int(1.2 * SR)], t_of(24), 0.6)
for c in range(6):
    t = t_of(24 + c)
    if c in (0, 2, 3, 5):
        put("drums", kick(), t)
        put("bass", bass808(note(*C_BASS[c]), CUT * 1.8, 0.6), t)
    if c in (1, 4):
        put("drums", snare(), t)
    for k in range(4 if c in (2, 5) else 2):
        put("drums", hat(), t + k * CUT / (4 if c in (2, 5) else 2), 0.75 - 0.1 * (k % 2), 0.3 * (-1) ** k)
    put("lead", pluck(note(*C_MEL[c]), 0.55, 1.3), t, 1.0, 0.2 * (-1) ** c)
    put("lead", pluck(note(C_MEL[c][0], C_MEL[c][1] - 1), 0.45, 0.9), t, 0.6)

# impact final (coupe 30) + accord tenu
put("fx", impact(), t_of(30), 1.25)
put("drums", kick(1.4), t_of(30))
for nm, o, g in (("F", 3, 0.9), ("C", 4, 0.7), ("Ab", 4, 0.6), ("F", 5, 0.6), ("C", 6, 0.35)):
    put("lead", pluck(note(nm, o), 2.6, 0.8), t_of(30), g)
put("fx", noise_sweep(1.0, 8000, 300, rise=False), t_of(30), 0.9)

# ---------------------------------------------------------------- mixage
def reverb(x, secs, damp, mix):
    n = int(secs * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal((n, 2)) * np.exp(-t * 6.9 / secs)[:, None]
    ir = filt(ir, "low", damp)
    ir /= np.sqrt((ir ** 2).sum(0))
    wet = np.stack([fftconvolve(x[:, k], ir[:, k])[:N] for k in (0, 1)], 1)
    return x + wet * mix


def delay(x, secs, fb, mix):
    out = x.copy()
    d = int(secs * SR)
    tap = x.copy()
    for k in range(4):
        tap = np.roll(tap, d, 0)[:, ::-1] * fb
        tap[:d] = 0
        out += tap * mix
    return out


# pompe (sidechain) : la basse et la mélodie s'effacent sous chaque kick
duck = np.ones(N)
kd = np.abs(BUS["drums"]).max(1)
envk = np.zeros(N)
a = 0.0
for i in range(0, N, 64):
    a = max(kd[i:i + 64].max(), a * 0.985)
    envk[i:i + 64] = a
duck = 1 - 0.45 * np.clip(envk / 0.9, 0, 1)

lead = delay(BUS["lead"], CUT * 1.5, 0.45, 0.35)
lead = reverb(lead, 1.8, 6000, 0.3) * duck[:, None]
bass = BUS["bass"] * (0.6 + 0.4 * duck[:, None])
drums = reverb(BUS["drums"], 0.5, 8000, 0.08)
fx = reverb(BUS["fx"], 2.6, 5000, 0.35)
mix = drums * 0.95 + bass * 0.8 + lead * 0.9 + fx * 0.75
mix = filt(mix, "high", 28)
mix = np.tanh(mix * 1.35)
mix *= 0.89 / np.abs(mix).max()
fade = np.minimum(1, (TOTAL - np.arange(N) / SR) / 0.6)
mix *= fade[:, None]

import wave

with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((mix * 32767).astype("<i2").tobytes())
print("ok", sys.argv[1], round(TOTAL, 2), "s")
