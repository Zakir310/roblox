"""
designs_v2.py — les 40 fusées v2 : une silhouette et un thème uniques par fusée, style « métal cartoon ».

Chaque design est une fonction build(R) qui modélise la fusée avec le kit rocketlib2.Rocket.
"""

import math
import random

from mathutils import Vector

from rocketlib2 import wobble, D

DESIGNS = []


def design(rid, key, name, world, aura, mult, cost):
    def deco(fn):
        DESIGNS.append(dict(id=rid, key=key, name=name, world=world, aura=dict(color=aura[0], strength=aura[1]),
                            stats=dict(multiplier=mult, cost=cost), build=fn))
        return fn
    return deco


def circle(n, r, z, off=0.0):
    for i in range(n):
        a = D(off) + 2 * math.pi * i / n
        yield i, a, Vector((r * math.cos(a), r * math.sin(a), z))


# =========================================================================
# MONDE 1 — DÉBUTANT : objets du quotidien transformés en fusées
# =========================================================================

@design(1, "Firecracker", "Pétard", 1, ("#FFB13B", 0.4), 1, 0)
def _(R):
    R.nozzle(0.4, 0.5)
    R.cyl("Body", 0.72, 5.0, "#E8322E", "paint", loc=(0, 0, 0.5))
    for z in (1.0, 2.6, 4.2):
        R.band(0.5 + z, 0.75, 0.25, "#FFC23B", "metal")
    R.cone("Cap", 0.76, 0.9, "#FFC23B", "metal", loc=(0, 0, 5.5))
    pts = [Vector((0, 0, 6.3)), Vector((0.25, 0, 6.8)), Vector((0.05, 0.1, 7.3)), Vector((0.35, 0.05, 7.7))]
    for a, b in zip(pts, pts[1:]):
        R.tube("Fuse", a, b, 0.07, "#6B4A2B", "matte", seg=8)
    R.ball("Spark", 0.26, "#FFE45C", "glow", loc=tuple(pts[-1]))
    R.tube("Stick", (0.85, 0, -1.6), (0.85, 0, 3.0), 0.09, "#B07A45", "wood", seg=8)
    R.box("StickTie", (0.25, 0.3, 0.2), "#FFC23B", "metal", loc=(0.75, 0, 2.2))


@design(2, "SodaBottle", "Bouteille de soda", 1, ("#5CFFB0", 0.45), 1.3, 150)
def _(R):
    prof = [(0, 0), (0.32, 0), (0.34, 0.15), (0.3, 0.3), (0.32, 0.8), (0.55, 1.3), (0.88, 1.9), (0.92, 2.4),
            (0.86, 3.0), (0.92, 3.6), (0.92, 5.2), (0.75, 5.75), (0.35, 6.0), (0, 6.05)]
    R.lathe("Body", prof, "#2EC27E", "glass")
    R.band(3.15, 0.95, 0.9, "#E8322E", "paint", base="Label")
    R.band(3.45, 0.965, 0.3, "#FFFFFF", "paint", base="LabelStripe")
    R.cyl("Cap", 0.36, 0.3, "#E8322E", "paint", loc=(0, 0, -0.25))
    R.fins(3, [(0.75, 1.3), (1.8, 0.4), (1.9, 0.9), (0.9, 2.6)], 0.1, "#E9D7B0", "matte", offset=90, base="CardFin")
    R.dome("Fizz", 0.45, "#FFFFFF", "glass", loc=(0, 0, 6.0), scale=(1, 1, 0.5))


@design(3, "TinCans", "Boîtes de conserve", 1, ("#FFD27A", 0.45), 1.7, 400)
def _(R):
    R.cyl("Nozzle", 0.45, 0.6, "#9AA0A8", "metal")
    labels = ["#2F7BFF", "#E8322E", "#FFC23B"]
    for i, c in enumerate(labels):
        z = 0.6 + i * 1.45
        R.cyl("Can", 0.8, 1.4, "#C9CED6", "metal", loc=(0, 0, z), round_=0.1)
        R.band(z + 0.25, 0.83, 0.9, c, "paint", base="Label")
        R.ring("Rim", 0.8, 0.05, "#9AA0A8", "metal", loc=(0, 0, z + 1.4))
    R.cone("Funnel", 0.85, 1.6, "#9AA0A8", "metal", loc=(0, 0, 4.95))
    R.tube("Spout", (0, 0, 6.4), (0, 0, 7.0), 0.1, "#9AA0A8", "metal")
    R.box("Tape", (1.75, 0.28, 0.3), "#8C8F96", "matte", loc=(0, 0, 2.05), rot=(0, 0, 0))
    R.fins(3, R.fin_pts("stub", 0.8, 0.5, 1.0), 0.06, "#C9CED6", "metal", offset=90, base="LidFin")


@design(4, "Cardboard", "Fusée en carton", 1, ("#FFD27A", 0.4), 2.2, 900)
def _(R):
    R.cyl("Nozzle", 0.42, 0.8, "#F2F2F2", "matte")
    R.box("Body", (1.5, 1.5, 4.4), "#B98A55", "matte", loc=(0, 0, 3.0), bevel=0.08)
    R.lathe("Roof", [(0, 0), (1.12, 0), (0, 1.9)], "#9C7041", "matte", seg=4, loc=(0, 0, 5.2), rot=(0, 0, 45))
    for z in (1.6, 4.2):
        R.box("Tape", (1.56, 1.56, 0.22), "#D9D2C2", "matte", loc=(0, 0, z), bevel=0.02)
    R.ball("DrawnWindow", 0.42, "#5EC8FF", "paint", loc=(0, -0.76, 3.6), scale=(1, 0.12, 1))
    R.ring("DrawnFrame", 0.42, 0.06, "#1E1E1E", "matte", loc=(0, -0.78, 3.6), rot=(90, 0, 0))
    for i in range(4):
        R.fin("CardFin", [(0.7, 0.8), (1.7, 0.2), (1.6, 0.9), (0.7, 2.2)], 0.08, "#9C7041", "matte", angle=45 + 90 * i)


@design(5, "ToyRocket", "Fusée jouet", 1, ("#FFE45C", 0.5), 2.8, 1800)
def _(R):
    R.nozzle(0.5, 0.6, "#E8322E")
    prof = [(0, 0.5)] + [(1.2 * math.sin(math.pi * t / 20) ** 0.8, 0.5 + 5.0 * (1 - math.cos(math.pi * t / 20)) / 2) for t in range(1, 20)] + [(0, 5.5)]
    R.lathe("Body", prof, "#FFD23B", "paint")
    R.band(1.6, 1.13, 0.35, "#E8322E", "paint", base="Stripe")
    R.band(2.3, 1.2, 0.35, "#E8322E", "paint", base="Stripe")
    R.porthole(3.3, 1.18, 0.55, frame="#E8322E", frame_kind="paint")
    for i, a, p in circle(3, 0, 0, 90):
        R.fin("Fin", R.fin_pts("round", 1.0, 0.6, 1.2), 0.22, "#E8322E", "paint", angle=math.degrees(a), bevel=0.09)
    R.ball("NoseBall", 0.4, "#E8322E", "paint", loc=(0, 0, 5.5))
    R.tube("Antenna", (0, 0, 5.8), (0, 0, 6.6), 0.05, "#C9CED6", "metal")
    R.ball("AntennaBall", 0.15, "#5EC8FF", "glow", loc=(0, 0, 6.65))


@design(6, "BarrelCopter", "Tonneau à hélice", 1, ("#FFC46B", 0.5), 3.5, 3500)
def _(R):
    R.nozzle(0.5, 0.6)
    prof = [(0, 0.6)] + [(0.95 + 0.25 * math.sin(math.pi * t / 12), 0.6 + 3.6 * t / 12) for t in range(13)] + [(0, 4.2)]
    R.lathe("Body", prof, "#A0703F", "wood", seg=24)
    for z in (1.1, 3.7):
        R.ring("Hoop", 1.08, 0.08, "#4E4A44", "dark", loc=(0, 0, z))
    R.ring("HoopMid", 1.2, 0.08, "#4E4A44", "dark", loc=(0, 0, 2.4))
    R.cyl("Mast", 0.1, 1.0, "#9AA0A8", "metal", loc=(0, 0, 4.2))
    R.ball("Hub", 0.22, "#E8322E", "paint", loc=(0, 0, 5.25))
    for i in range(3):
        R.box("Blade", (2.6, 0.45, 0.08), "#E8322E", "paint", loc=(0, 0, 5.25), rot=(8, 0, 120 * i), bevel=0.05)
    for s in (1, -1):
        R.cyl("SideThruster", 0.28, 1.6, "#C9CED6", "metal", loc=(s * 1.3, 0, 0.6))
        R.cone("ThrusterTip", 0.28, 0.5, "#E8322E", "paint", loc=(s * 1.3, 0, 2.2))
        R.box("ThrusterStrap", (0.45, 0.2, 0.2), "#4E4A44", "dark", loc=(s * 1.1, 0, 1.5))
    R.porthole(2.6, 1.18, 0.38)


@design(7, "RetroClassic", "Rétro 1950", 1, ("#FFD27A", 0.55), 4.3, 6500)
def _(R):
    R.nozzle(0.42, 0.6)
    prof = [(0, 0.6), (0.55, 0.6), (0.85, 1.2), (1.0, 2.2), (1.0, 3.6), (0.85, 4.8), (0.55, 5.8), (0.25, 6.6), (0, 7.2)]
    R.lathe("Body", prof, "#D9DDE3", "metal")
    R.lathe("Nose", [(0, 5.8), (0.56, 5.8), (0.25, 6.6), (0, 7.25)], "#E8322E", "paint")
    for i in range(3):
        R.porthole(4.2 - i * 0.75, 0.95, 0.24, frame="#E8322E", frame_kind="paint", ang=-70)
    for i in range(3):
        R.fin("Fin", R.fin_pts("retro", 0.9, 0.9, 1.0), 0.16, "#E8322E", "paint", angle=90 + 120 * i, bevel=0.06)
    R.ring("Belt", 1.02, 0.07, "#E8322E", "paint", loc=(0, 0, 2.9))


@design(8, "Origami", "Fusée origami", 1, ("#9BD7FF", 0.55), 5.4, 12000)
def _(R):
    R.lathe("Nozzle", [(0, 0), (0.5, 0), (0.35, 0.6), (0, 0.6)], "#2F7BFF", "matte", seg=6)
    R.lathe("Body", [(0, 0.6), (0.7, 0.6), (1.0, 2.0), (0.8, 4.6), (0, 4.6)], "#F7F7F2", "matte", seg=6)
    R.lathe("Nose", [(0, 4.6), (0.8, 4.6), (0, 6.9)], "#2F7BFF", "matte", seg=6, rot=(0, 0, 30))
    for z in (1.5, 3.4):
        R.lathe("Fold", [(0, z), (0.98, z), (0.9, z + 0.12), (0, z + 0.12)], "#2F7BFF", "matte", seg=6)
    for i in range(3):
        R.fin("PaperFin", [(0.6, 0.3), (2.0, -0.5), (1.1, 1.0), (0.85, 2.6)], 0.04, "#F7F7F2", "matte", angle=120 * i + 30, bevel=0.0)


@design(9, "PlumberPipes", "Fusée plomberie", 1, ("#FFB04A", 0.6), 6.8, 22000)
def _(R):
    R.nozzle(0.48, 0.6, "#4E4A44")
    R.cyl("Body", 0.75, 4.6, "#C8743A", "metal", loc=(0, 0, 0.6), round_=0.1)
    for z in (0.6, 2.9, 5.2):
        R.cyl("Coupler", 0.86, 0.35, "#A35C2B", "metal", loc=(0, 0, z - 0.17))
    R.cone("Nose", 0.86, 1.4, "#A35C2B", "metal", loc=(0, 0, 5.37))
    for s in (1, -1):
        R.tube("SidePipe", (s * 1.4, 0, 0.3), (s * 1.4, 0, 3.0), 0.28, "#C8743A", "metal")
        R.tube("Elbow", (s * 1.4, 0, 3.0), (s * 0.8, 0, 3.6), 0.28, "#C8743A", "metal")
        R.ball("Joint", 0.32, "#A35C2B", "metal", loc=(s * 1.4, 0, 3.0))
        R.ring("Valve", 0.35, 0.07, "#E8322E", "paint", loc=(s * 1.75, 0, 2.0), rot=(0, 90, 0))
        R.cyl("ValveStem", 0.06, 0.4, "#9AA0A8", "metal", loc=(s * 1.4, 0, 2.0), rot=(0, 90 * s, 0))
    R.cyl("Gauge", 0.38, 0.12, "#F2F2F2", "paint", loc=(0, -0.8, 3.9), rot=(90, 0, 0))
    R.ring("GaugeRim", 0.38, 0.05, "#C9CED6", "metal", loc=(0, -0.92, 3.9), rot=(90, 0, 0))
    R.box("GaugeNeedle", (0.04, 0.02, 0.3), "#E8322E", "paint", loc=(0.06, -0.95, 3.98), rot=(0, 30, 0), bevel=0)


@design(10, "IceCream", "Cornet glacé", 1, ("#FF9AD5", 0.65), 8.5, 40000)
def _(R):
    R.cone("WaferTip", 0.25, 0.4, "#C88A4A", "matte", loc=(0, 0, 0.0))
    R.lathe("Cone", [(0, 0.2), (0.35, 0.3), (1.15, 3.8), (1.2, 4.05), (0, 4.05)], "#D9A35E", "matte", seg=12)
    for z in (1.2, 2.2, 3.2):
        R.ring("WaferLine", 0.4 + z * 0.22, 0.05, "#B07A3A", "matte", loc=(0, 0, z), seg=12)
    R.ball("ScoopPink", 1.15, "#FF8AC2", "paint", loc=(0, 0, 4.5), scale=(1, 1, 0.85))
    R.ball("ScoopVanilla", 0.95, "#FFF4D6", "paint", loc=(0, 0, 5.6), scale=(1, 1, 0.85))
    R.ball("ScoopChoco", 0.75, "#7A4A2A", "paint", loc=(0, 0, 6.5), scale=(1, 1, 0.85))
    R.ball("Cherry", 0.3, "#E8172E", "metal", loc=(0, 0, 7.25))
    R.tube("CherryStem", (0, 0, 7.45), (0.2, 0, 7.9), 0.04, "#3E7A2A", "matte", seg=6)
    rnd = random.Random(10)
    for k in range(10):
        a = rnd.uniform(0, 6.28)
        R.box("Sprinkle", (0.22, 0.07, 0.07), ["#5EC8FF", "#FFE45C", "#7CFF6A"][k % 3], "paint",
              loc=(1.0 * math.cos(a), 1.0 * math.sin(a), 4.6 + rnd.uniform(-0.3, 0.3)), rot=(0, rnd.uniform(0, 90), math.degrees(a)), bevel=0.02)
    for i in range(3):
        R.fin("WaferFin", [(0.5, 0.8), (1.6, 0.2), (1.5, 0.9), (0.9, 2.4)], 0.1, "#D9A35E", "matte", angle=90 + 120 * i)


# =========================================================================
# MONDE 2 — TECHNOLOGIE : grands lanceurs et machines spatiales
# =========================================================================

@design(11, "V2Checker", "V2 damier", 2, ("#9AD8FF", 0.8), 11, 75000)
def _(R):
    R.nozzle(0.45, 0.6)
    prof = [(0, 0.6), (0.7, 0.6), (0.95, 1.6), (1.0, 3.2), (0.8, 5.0), (0.45, 6.2), (0, 7.0)]
    R.lathe("Body", prof, "#F2F2F2", "paint")
    for i in range(4):
        R.lathe("CheckA", [(0, 1.6 + i * 1.1), (1.02, 1.6 + i * 1.1), (1.0, 2.15 + i * 1.1), (0, 2.15 + i * 1.1)], "#1E1F26", "paint", seg=4,
                rot=(0, 0, 45 + 90 * (i % 2)), scale=(1.0, 0.42, 1.0))
    for i in range(4):
        R.fin("Fin", R.fin_pts("swept", 0.85, 0.6, 1.0), 0.14, "#1E1F26", "paint", angle=45 + 90 * i)
        R.box("FinTip", (0.12, 0.25, 0.9), "#F2F2F2", "paint", loc=(2.0 * math.cos(D(45 + 90 * i)), 2.0 * math.sin(D(45 + 90 * i)), 0.4),
              rot=(0, 0, 45 + 90 * i))


@design(12, "SaturnStack", "Saturne géante", 2, ("#9AD8FF", 0.85), 14, 140000)
def _(R):
    for i, (x, y) in enumerate([(0, 0), (0.55, 0), (-0.55, 0), (0, 0.55), (0, -0.55)]):
        R.nozzle(0.28, 0.6, loc=(x, y, 0))
    R.cyl("Stage1", 1.1, 3.2, "#F4F4F4", "paint", loc=(0, 0, 0.6))
    R.lathe("Interstage", [(0, 3.8), (1.1, 3.8), (0.85, 4.3), (0, 4.3)], "#C9CED6", "metal")
    R.cyl("Stage2", 0.85, 2.0, "#F4F4F4", "paint", loc=(0, 0, 4.3))
    R.cyl("Stage3", 0.7, 1.2, "#F4F4F4", "paint", loc=(0, 0, 6.3))
    R.lathe("Capsule", [(0, 7.5), (0.7, 7.5), (0.25, 8.2), (0, 8.2)], "#C9CED6", "metal")
    R.tube("Tower", (0, 0, 8.2), (0, 0, 9.4), 0.07, "#E8322E", "paint")
    R.cone("TowerTip", 0.2, 0.4, "#E8322E", "paint", loc=(0, 0, 9.4))
    for z in (0.9, 2.2, 4.5):
        R.lathe("Roll", [(0, z), (1.12, z), (1.12, z + 0.5), (0, z + 0.5)], "#1E1F26", "paint", seg=4, rot=(0, 0, 45), scale=(1, 0.35, 1))
    for i in range(4):
        R.fin("Fin", R.fin_pts("stub", 1.05, 0.5, 0.9), 0.14, "#1E1F26", "paint", angle=45 + 90 * i)


@design(13, "Shuttle", "Navette", 2, ("#FFB04A", 0.9), 18, 260000)
def _(R):
    R.cyl("Tank", 1.0, 6.2, "#E2742B", "paint", loc=(0, 0, 0.5))
    R.lathe("TankNose", [(0, 6.7), (1.0, 6.7), (0.6, 7.6), (0, 8.1)], "#E2742B", "paint")
    for s in (1, -1):
        R.cyl("SRB", 0.42, 6.0, "#F4F4F4", "paint", loc=(s * 1.45, 0, 0.5))
        R.lathe("SRBNose", [(0, 6.5), (0.42, 6.5), (0.2, 7.1), (0, 7.4)], "#F4F4F4", "paint", loc=(s * 1.45, 0, 0))
        R.nozzle(0.36, 0.5, loc=(s * 1.45, 0, 0))
    R.lathe("Orbiter", [(0, 0.6), (0.62, 0.6), (0.7, 1.4), (0.7, 4.6), (0.5, 5.6), (0, 6.0)], "#F4F4F4", "paint", loc=(0, -1.6, 0))
    R.lathe("OrbiterNose", [(0, 5.3), (0.58, 5.3), (0.3, 5.75), (0, 6.02)], "#1E1F26", "paint", loc=(0, -1.6, 0))
    for ang in (0, 180):
        w = R.fin("Wing", [(0.4, 0.8), (2.6, 0.8), (2.4, 1.4), (0.4, 3.8)], 0.14, "#F4F4F4", "paint", angle=ang)
        w.location = (0, -1.6, 0)
    t = R.fin("Tail", [(0.5, 0.7), (1.4, 0.4), (1.5, 0.9), (0.5, 2.0)], 0.12, "#F4F4F4", "paint", angle=270)
    t.location = (0, -1.6, 0)
    for x in (-0.3, 0.3):
        R.nozzle(0.25, 0.5, loc=(x, -1.75, 0.1))
    R.ball("CockpitGlass", 0.4, "#5EC8FF", "glass", loc=(0, -2.15, 5.1), scale=(0.8, 0.4, 0.6))


@design(14, "Soyuz", "Soyouz", 2, ("#7CFFB8", 0.9), 23, 480000)
def _(R):
    R.nozzle(0.4, 0.6)
    R.cyl("Core", 0.65, 5.6, "#6F8A6A", "paint", loc=(0, 0, 0.6), r2=0.75)
    R.lathe("Fairing", [(0, 6.2), (0.78, 6.2), (0.95, 6.8), (0.95, 7.8), (0.5, 8.6), (0, 8.9)], "#F2F2F2", "paint")
    R.band(7.2, 0.97, 0.2, "#E8322E", "paint")
    for i, a, p in circle(4, 0.95, 0, 45):
        o = R.lathe("Booster", [(0, 0), (0.55, 0), (0.5, 1.0), (0.32, 3.0), (0.12, 3.8), (0, 3.9)], "#6F8A6A", "paint", loc=(p.x, p.y, 0.4))
        R.nozzle(0.28, 0.45, loc=(p.x, p.y, 0.0))
        f = R.fin("BoosterFin", [(0.3, 0.4), (1.0, 0.0), (1.0, 0.5), (0.3, 1.0)], 0.06, "#E2742B", "paint", angle=math.degrees(a))
        f.location = (p.x, p.y, 0.0)


@design(15, "Reusable", "Réutilisable", 2, ("#9AD8FF", 0.95), 30, 900000)
def _(R):
    for i, a, p in circle(8, 0.42, 0, 0):
        R.nozzle(0.16, 0.45, loc=(p.x, p.y, 0))
    R.nozzle(0.16, 0.45)
    R.cyl("Body", 0.75, 7.0, "#F4F4F4", "paint", loc=(0, 0, 0.45))
    R.band(5.6, 0.77, 0.6, "#1E1F26", "paint", base="Interstage")
    R.lathe("Fairing", [(0, 7.45), (0.8, 7.45), (0.85, 8.2), (0.45, 9.1), (0, 9.4)], "#F4F4F4", "paint")
    for i, a, p in circle(4, 0, 0, 45):
        R.box("GridFin", (0.7, 0.08, 0.6), "#3A3D46", "dark", loc=(1.05 * math.cos(a), 1.05 * math.sin(a), 6.1), rot=(0, 0, math.degrees(a) + 90), bevel=0.02)
        leg = R.box("Leg", (0.14, 0.24, 2.4), "#1E1F26", "dark", loc=(0, 0, 0), bevel=0.04)
        leg.location = (0.95 * math.cos(a), 0.95 * math.sin(a), 0.9)
        leg.rotation_euler = Vector((math.cos(a) * 0.35, math.sin(a) * 0.35, 1)).to_track_quat("Z", "Y").to_euler()
        R.ball("Foot", 0.18, "#3A3D46", "dark", loc=(1.3 * math.cos(a), 1.3 * math.sin(a), -0.15), scale=(1, 1, 0.5))
    R.box("Logo", (0.5, 0.06, 1.6), "#2F7BFF", "paint", loc=(0, -0.76, 3.5), bevel=0.02)


@design(16, "Capsule", "Capsule lunaire", 2, ("#CFE8FF", 0.95), 38, 1.7e6)
def _(R):
    R.nozzle(0.55, 0.8)
    R.cyl("Service", 1.05, 2.4, "#D9DDE3", "metal", loc=(0, 0, 0.8))
    for i, a, p in circle(4, 1.07, 2.0, 0):
        R.box("RCS", (0.25, 0.25, 0.35), "#3A3D46", "dark", loc=tuple(p), rot=(0, 0, math.degrees(a)))
    R.lathe("HeatShield", [(0, 3.2), (1.12, 3.2), (1.12, 3.4), (0, 3.4)], "#B8742F", "metal")
    R.lathe("Capsule", [(0, 3.4), (1.1, 3.4), (0.4, 5.0), (0, 5.1)], "#C9CED6", "metal")
    R.porthole(4.0, 0.82, 0.18, ang=-70)
    R.tube("Tower", (0, 0, 5.0), (0, 0, 6.6), 0.08, "#E8322E", "paint")
    for i, a, p in circle(3, 0.35, 5.0, 90):
        R.tube("Truss", tuple(p), (0, 0, 5.9), 0.04, "#E8322E", "paint", seg=6)
    R.cone("EscapeMotor", 0.22, 0.6, "#E8322E", "paint", loc=(0, 0, 6.6))
    R.box("Antenna", (0.06, 0.06, 0.8), "#C9CED6", "metal", loc=(0.8, 0, 2.6), rot=(0, 30, 0))
    R.ball("Dish", 0.3, "#C9CED6", "metal", loc=(1.05, 0, 3.0), scale=(1, 1, 0.3))


@design(17, "Hammerhead", "Coiffe marteau", 2, ("#7FD0FF", 1.0), 48, 3.2e6)
def _(R):
    R.nozzle(0.42, 0.6)
    R.cyl("Body", 0.62, 4.6, "#2F7BFF", "paint", loc=(0, 0, 0.6))
    R.lathe("Adapter", [(0, 5.2), (0.62, 5.2), (1.15, 5.8), (0, 5.8)], "#C9CED6", "metal")
    R.lathe("Fairing", [(0, 5.8), (1.15, 5.8), (1.2, 7.4), (0.8, 8.4), (0, 8.9)], "#F4F4F4", "paint")
    R.band(6.8, 1.22, 0.25, "#2F7BFF", "paint")
    for i in range(4):
        R.fin("Fin", R.fin_pts("delta", 0.6, 0.6, 0.6), 0.12, "#F4F4F4", "paint", angle=45 + 90 * i)
    R.ring("Belt", 0.65, 0.06, "#F4F4F4", "paint", loc=(0, 0, 3.0))


@design(18, "DroneRocket", "Fusée drone", 2, ("#5EF2FF", 1.0), 60, 6e6)
def _(R):
    R.nozzle(0.45, 0.6)
    R.lathe("Body", [(0, 0.6), (0.8, 0.6), (0.9, 1.4), (0.9, 3.6), (0.5, 4.6), (0, 4.9)], "#3A3D46", "dark")
    R.ball("Eye", 0.4, "#5EF2FF", "glow", loc=(0, -0.72, 3.6), scale=(1.2, 0.5, 0.6))
    for i, a, p in circle(4, 1.9, 2.4, 45):
        R.tube("Arm", (0, 0, 2.4), tuple(p), 0.12, "#C9CED6", "metal")
        R.ring("Duct", 0.62, 0.12, "#F4F4F4", "paint", loc=tuple(p))
        R.ball("Hub", 0.15, "#3A3D46", "dark", loc=tuple(p))
        for b in range(3):
            R.box("Prop", (1.0, 0.18, 0.04), "#5EF2FF", "glow", loc=tuple(p), rot=(0, 0, 60 * b + 15), bevel=0.02)
        R.ball("Light", 0.1, "#5EF2FF", "glow", loc=(p.x, p.y, p.z - 0.2))


@design(19, "JetRocket", "Jet-fusée", 2, ("#FF6A4A", 1.05), 75, 1.1e7)
def _(R):
    R.nozzle(0.5, 0.7)
    R.lathe("Body", [(0, 0.7), (0.75, 0.7), (0.85, 2.0), (0.8, 4.5), (0.45, 6.4), (0, 7.4)], "#D9DDE3", "metal")
    R.ball("Cockpit", 0.42, "#5EC8FF", "glass", loc=(0, -0.62, 5.2), scale=(0.8, 0.6, 1.8))
    for s in (1, -1):
        R.lathe("Intake", [(0, 0), (0.35, 0), (0.35, 1.8), (0.25, 2.2), (0, 2.2)], "#E8322E", "paint", loc=(s * 0.85, 0.15, 1.6))
        R.ring("IntakeLip", 0.3, 0.06, "#1E1F26", "dark", loc=(s * 0.85, 0.15, 3.8))
    R.fin("Wing", R.fin_pts("wing", 0.8, 1.6, 0.9), 0.12, "#E8322E", "paint", angle=0)
    R.fin("Wing", R.fin_pts("wing", 0.8, 1.6, 0.9), 0.12, "#E8322E", "paint", angle=180)
    R.fin("Canard", R.fin_pts("stub", 0.6, 5.0, 0.6), 0.08, "#E8322E", "paint", angle=0)
    R.fin("Canard", R.fin_pts("stub", 0.6, 5.0, 0.6), 0.08, "#E8322E", "paint", angle=180)
    R.fin("Tail", R.fin_pts("swept", 0.8, 0.7, 0.9), 0.1, "#D9DDE3", "metal", angle=90)


@design(20, "MechRocket", "Méca-fusée", 2, ("#FFD35A", 1.1), 95, 2e7)
def _(R):
    R.nozzle(0.55, 0.7)
    R.box("Torso", (1.7, 1.4, 3.4), "#F2B51F", "paint", loc=(0, 0, 2.5), bevel=0.15)
    R.box("Chest", (1.2, 0.2, 1.0), "#3A3D46", "dark", loc=(0, -0.72, 3.0), bevel=0.06)
    R.ball("Core", 0.28, "#5EF2FF", "glow", loc=(0, -0.82, 3.0))
    R.lathe("Head", [(0, 4.2), (0.75, 4.2), (0.8, 4.7), (0.5, 5.4), (0, 5.6)], "#F2B51F", "paint")
    R.box("Visor", (1.1, 0.3, 0.3), "#5EF2FF", "glow", loc=(0, -0.62, 4.85), bevel=0.08)
    for s in (1, -1):
        R.ball("Shoulder", 0.45, "#3A3D46", "dark", loc=(s * 1.1, 0, 3.8))
        R.tube("UpperArm", (s * 1.2, 0, 3.6), (s * 1.6, -0.2, 2.4), 0.2, "#C9CED6", "metal")
        R.ball("Elbow", 0.25, "#3A3D46", "dark", loc=(s * 1.6, -0.2, 2.4))
        R.tube("Forearm", (s * 1.6, -0.2, 2.4), (s * 1.6, -0.6, 1.4), 0.24, "#F2B51F", "paint")
        R.box("Claw", (0.15, 0.35, 0.5), "#3A3D46", "dark", loc=(s * 1.5, -0.65, 1.1), bevel=0.04)
        R.box("Claw", (0.15, 0.35, 0.5), "#3A3D46", "dark", loc=(s * 1.75, -0.65, 1.1), bevel=0.04)
        R.cyl("Jet", 0.3, 1.2, "#C9CED6", "metal", loc=(s * 0.55, 0.75, 1.0))


# =========================================================================
# MONDE 3 — EXPÉRIMENTAL : énergies étranges et inventions folles
# =========================================================================

@design(21, "Steampunk", "Vapeur cuivrée", 3, ("#FFB04A", 1.3), 120, 4e7)
def _(R):
    R.nozzle(0.5, 0.7, "#4E4A44")
    R.cyl("Boiler", 1.0, 4.0, "#B8742F", "metal", loc=(0, 0, 0.7), round_=0.2)
    R.lathe("Dome", [(0, 4.7), (1.0, 4.7), (0.9, 5.3), (0.5, 5.8), (0, 5.9)], "#D9A520", "metal")
    for z in (1.3, 2.7, 4.1):
        R.ring("RivetBand", 1.02, 0.07, "#8A5A2A", "metal", loc=(0, 0, z))
        for i, a, p in circle(10, 1.06, z, 0):
            R.ball("Rivet", 0.07, "#D9A520", "metal", loc=tuple(p), seg=8)
    R.cyl("Chimney", 0.22, 1.6, "#3A3D46", "dark", loc=(0.45, 0, 5.4))
    R.lathe("ChimneyTop", [(0, 0), (0.22, 0), (0.38, 0.35), (0, 0.35)], "#3A3D46", "dark", loc=(0.45, 0, 7.0))
    # engrenage
    R.cyl("Gear", 0.6, 0.18, "#D9A520", "metal", loc=(0, -1.0, 2.6), rot=(90, 0, 0))
    for i in range(10):
        a = 2 * math.pi * i / 10
        R.box("Tooth", (0.16, 0.18, 0.22), "#D9A520", "metal", loc=(0.68 * math.cos(a), -1.09, 2.6 + 0.68 * math.sin(a)), rot=(0, -math.degrees(a), 0), bevel=0.02)
    R.ball("GearAxle", 0.15, "#4E4A44", "dark", loc=(0, -1.2, 2.6))
    R.cyl("Gauge", 0.3, 0.1, "#FFF4D6", "paint", loc=(0.75, -0.7, 3.8), rot=(90, 0, 35))
    for s in (1, -1):
        R.tube("Piston", (s * 1.2, 0.2, 0.6), (s * 1.2, 0.2, 2.6), 0.15, "#C9CED6", "metal")
        R.cyl("PistonHousing", 0.25, 0.8, "#8A5A2A", "metal", loc=(s * 1.2, 0.2, 2.4))


@design(22, "PlasmaOrb", "Orbe plasma", 3, ("#B36BFF", 1.4), 150, 7.5e7)
def _(R):
    R.nozzle(0.55, 0.7, "#2A2C36")
    R.lathe("Base", [(0, 0.7), (1.1, 0.7), (1.2, 1.2), (0.7, 1.8), (0, 1.8)], "#2A2C36", "dark")
    R.ball("Plasma", 1.15, "#B36BFF", "glow", loc=(0, 0, 3.1))
    R.ball("PlasmaShell", 1.35, "#E6D6FF", "glass", loc=(0, 0, 3.1))
    for i in range(4):
        R.ring("Rib", 1.42, 0.08, "#C9CED6", "metal", loc=(0, 0, 3.1), rot=(90, 0, 45 * i))
    R.ring("Equator", 1.45, 0.1, "#C9CED6", "metal", loc=(0, 0, 3.1))
    R.lathe("Spire", [(0, 4.3), (0.5, 4.3), (0.25, 5.3), (0, 6.8)], "#C9CED6", "metal")
    R.ball("SpireTip", 0.15, "#B36BFF", "glow", loc=(0, 0, 6.85))
    for i in range(3):
        R.fin("Fin", R.fin_pts("blade", 1.0, 0.7, 0.8), 0.1, "#2A2C36", "dark", angle=90 + 120 * i)


@design(23, "RingDrive", "Propulseur à anneaux", 3, ("#5EF2FF", 1.4), 190, 1.4e8)
def _(R):
    R.nozzle(0.35, 0.6, "#2A2C36")
    R.lathe("Spear", [(0, 0.6), (0.4, 0.6), (0.45, 2.0), (0.38, 6.0), (0, 9.0)], "#E8ECF2", "metal", seg=24)
    for z, Rr in ((2.0, 1.7), (4.0, 1.35), (5.8, 1.0)):
        R.ring("DriveRing", Rr, 0.14, "#5EF2FF", "glow", loc=(0, 0, z))
        R.ring("DriveRingFrame", Rr, 0.2, "#3A3D46", "dark", loc=(0, 0, z - 0.1), seg=48)
        for i, a, p in circle(3, Rr * 0.5, z, 90):
            R.tube("Spoke", (0.4 * math.cos(a), 0.4 * math.sin(a), z), (Rr * math.cos(a), Rr * math.sin(a), z), 0.05, "#3A3D46", "dark", seg=6)
    R.fins(3, R.fin_pts("swept", 0.45, 0.4, 0.7), 0.08, "#3A3D46", "dark", offset=90)


@design(24, "UFO", "Soucoupe", 3, ("#9BFF8A", 1.5), 240, 2.6e8)
def _(R):
    R.lathe("Saucer", [(0, 0.8), (1.2, 0.8), (2.6, 1.3), (2.75, 1.45), (2.5, 1.65), (1.2, 1.95), (0, 1.95)], "#C9CED6", "metal", seg=48)
    R.ring("Rim", 2.7, 0.1, "#3A3D46", "dark", loc=(0, 0, 1.45), seg=64)
    for i, a, p in circle(10, 2.2, 1.35, 0):
        R.ball("Light", 0.14, "#9BFF8A", "glow", loc=tuple(p), seg=10)
    R.dome("Dome", 1.15, "#9BFF8A", "glass", loc=(0, 0, 1.9), scale=(1, 1, 0.85))
    R.ball("Alien", 0.38, "#7CFF6A", "paint", loc=(0, 0, 2.3))
    for s in (1, -1):
        R.ball("AlienEye", 0.1, "#1E1F26", "paint", loc=(s * 0.14, -0.33, 2.38), scale=(0.8, 0.5, 1.2))
    R.lathe("Beam", [(0, 0), (0.7, 0), (0.95, 0.8), (0, 0.8)], "#9BFF8A", "glow")
    for i, a, p in circle(3, 1.6, 0.8, 90):
        R.tube("Leg", tuple(p), (2.1 * math.cos(a), 2.1 * math.sin(a), 0.0), 0.07, "#3A3D46", "dark", seg=8)
        R.ball("Foot", 0.18, "#3A3D46", "dark", loc=(2.1 * math.cos(a), 2.1 * math.sin(a), 0.0), scale=(1, 1, 0.4))


@design(25, "TeslaCoil", "Bobine Tesla", 3, ("#7FB8FF", 1.55), 300, 5e8)
def _(R):
    R.nozzle(0.5, 0.7, "#2A2C36")
    R.cyl("Body", 0.75, 4.2, "#3A3D46", "dark", loc=(0, 0, 0.7))
    for k in range(9):
        R.ring("Coil", 0.8, 0.06, "#C8743A", "metal", loc=(0, 0, 1.2 + k * 0.36))
    R.lathe("Neck", [(0, 4.9), (0.75, 4.9), (0.3, 5.6), (0, 5.6)], "#C9CED6", "metal")
    R.cyl("Pole", 0.12, 0.8, "#C9CED6", "metal", loc=(0, 0, 5.5))
    R.ring("Toroid", 0.85, 0.32, "#E8ECF2", "metal", loc=(0, 0, 6.4))
    R.ball("Top", 0.35, "#7FB8FF", "glow", loc=(0, 0, 6.75))
    rnd = random.Random(25)
    for k in range(6):
        a = 2 * math.pi * k / 6
        p = Vector((0, 0, 6.6))
        for j in range(3):
            q = p + Vector((math.cos(a) * 0.45 + rnd.uniform(-0.15, 0.15), math.sin(a) * 0.45 + rnd.uniform(-0.15, 0.15), rnd.uniform(-0.2, 0.35)))
            R.tube("Bolt", tuple(p), tuple(q), 0.035, "#BFE0FF", "glow", seg=6)
            p = q
    R.fins(4, R.fin_pts("blade", 0.75, 0.7, 0.7), 0.1, "#C8743A", "metal", offset=45)


@design(26, "Jellyfish", "Méduse cosmique", 3, ("#FF8AE0", 1.6), 380, 9e8)
def _(R):
    bell = [(0, 3.3), (1.75, 3.3)] + [(1.72 * math.sin(th) ** 0.7, 3.4 + 2.6 * math.cos(th)) for th in [math.pi / 2 * (1 - k / 10) for k in range(1, 10)]] + [(0, 6.0)]
    R.lathe("Bell", bell, "#FF8AE0", "glass", seg=40)
    R.ball("Core", 0.65, "#FF4FC8", "glow", loc=(0, 0, 4.3))
    R.ring("BellRim", 1.72, 0.1, "#FF4FC8", "glow", loc=(0, 0, 3.35), seg=48)
    rnd = random.Random(26)
    for i, a, p in circle(8, 1.3, 3.2, 0):
        q = p
        for j in range(6):
            nq = q + Vector((math.cos(a + j * 0.6) * 0.18, math.sin(a + j * 0.6) * 0.18, -0.5))
            R.ball("Tentacle", 0.16 - j * 0.017, "#FFB8EE", "paint", loc=tuple(nq), seg=10)
            q = nq
    for i, a, p in circle(4, 0.45, 3.2, 45):
        R.tube("Oral", tuple(p), (p.x * 0.4, p.y * 0.4, 0.6), 0.12, "#FF4FC8", "glow", seg=8)
    R.nozzle(0.4, 0.5, "#B23A8E", loc=(0, 0, 0.2))


@design(27, "CrystalCluster", "Grappe de cristaux", 3, ("#5EF2FF", 1.7), 470, 1.7e9)
def _(R):
    R.lathe("Base", [(0, 0), (1.3, 0), (1.4, 0.35), (1.1, 0.8), (0, 0.8)], "#C9CED6", "metal", seg=8)
    R.ring("BaseGlow", 1.38, 0.07, "#5EF2FF", "glow", loc=(0, 0, 0.35), seg=8)
    spec = [((0, 0), 0.6, 6.5, "#5EF2FF"), ((0.75, 0.2), 0.38, 4.2, "#A8F6FF"), ((-0.7, 0.3), 0.42, 4.8, "#3FB8FF"),
            ((0.2, -0.7), 0.35, 3.6, "#7FD0FF"), ((-0.3, 0.75), 0.3, 3.0, "#BFF7FF")]
    for (x, y), r, h, c in spec:
        o = R.lathe("Crystal", [(0, 0), (r, 0), (r, h * 0.72), (0, h)], c, "glass", seg=6, loc=(x, y, 0.7))
        o.rotation_euler = (D(-y * 12), D(x * 12), D(x * 40))
    R.ball("Heart", 0.35, "#FFFFFF", "glow", loc=(0, 0, 2.2))


@design(28, "SolarSail", "Voile solaire", 3, ("#FFE45C", 1.75), 600, 3.2e9)
def _(R):
    R.nozzle(0.35, 0.6)
    R.cyl("Body", 0.5, 4.0, "#E8ECF2", "metal", loc=(0, 0, 0.6))
    R.lathe("Nose", [(0, 4.6), (0.5, 4.6), (0, 5.6)], "#D9A520", "metal")
    R.cyl("Mast", 0.08, 3.6, "#C9CED6", "metal", loc=(0, 0, 4.0))
    R.box("Sail", (4.4, 0.04, 4.4), "#FFD35A", "metal", loc=(0, 0.25, 5.2), rot=(0, 45, 0), bevel=0.0)
    for i in range(4):
        a = D(45 + 90 * i)
        R.tube("Boom", (0, 0.2, 5.2), (3.1 * math.cos(a), 0.2, 5.2 + 3.1 * math.sin(a)), 0.05, "#C9CED6", "metal", seg=6)
    R.box("SailStripe", (4.45, 0.05, 0.25), "#E8322E", "paint", loc=(0, 0.22, 5.2), rot=(0, 45, 0), bevel=0.0)
    R.box("SailStripe", (4.45, 0.05, 0.25), "#E8322E", "paint", loc=(0, 0.22, 5.2), rot=(0, -45, 0), bevel=0.0)
    R.fins(3, R.fin_pts("stub", 0.5, 0.6, 0.6), 0.08, "#D9A520", "metal", offset=90)


@design(29, "Catamaran", "Double coque", 3, ("#FFB04A", 1.8), 750, 6e9)
def _(R):
    for s in (1, -1):
        R.nozzle(0.38, 0.6, loc=(s * 1.15, 0, 0))
        R.lathe("Hull", [(0, 0.6), (0.6, 0.6), (0.65, 1.6), (0.6, 4.8), (0.3, 6.3), (0, 6.9)], "#D62828", "paint", loc=(s * 1.15, 0, 0))
        R.ring("HullBand", 0.66, 0.07, "#F1C85A", "metal", loc=(s * 1.15, 0, 2.0))
        f = R.fin("HullFin", R.fin_pts("swept", 0.6, 0.6, 0.7), 0.1, "#F1C85A", "metal", angle=0 if s > 0 else 180)
        f.location = (s * 1.15, 0, 0)
    R.box("Bridge", (2.2, 0.5, 1.4), "#F1C85A", "metal", loc=(0, 0, 3.6), bevel=0.15)
    R.lathe("Pod", [(0, 3.0), (0.55, 3.2), (0.6, 4.4), (0.3, 5.3), (0, 5.5)], "#E8ECF2", "metal")
    R.ball("Cockpit", 0.38, "#5EC8FF", "glass", loc=(0, -0.42, 4.6), scale=(0.9, 0.6, 1.3))


@design(30, "Magma", "Fusée magma", 3, ("#FF6A1F", 2.0), 950, 1.2e10)
def _(R):
    R.nozzle(0.55, 0.7, "#2A1A14")
    o = R.lathe("Rock", [(0, 0.7), (1.0, 0.7), (1.2, 1.8), (1.1, 3.6), (0.9, 5.0), (0.6, 5.8), (0, 5.9)], "#3A2A26", "matte", seg=18)
    wobble(o, 0.12, 30)
    for z, r in ((1.7, 1.24), (3.0, 1.18), (4.3, 1.02)):
        b = R.ring("LavaCrack", r, 0.09, "#FF6A1F", "glow", loc=(0, 0, z), seg=18)
        wobble(b, 0.1, int(z * 10))
    R.lathe("Crater", [(0, 5.4), (0.55, 5.8), (0.75, 6.3), (0.6, 6.4), (0.3, 5.9), (0, 5.9)], "#3A2A26", "matte", seg=18)
    R.ball("Lava", 0.42, "#FFB13B", "glow", loc=(0, 0, 6.0), scale=(1, 1, 0.5))
    for i, a, p in circle(5, 1.05, 2.4, 20):
        R.aim(R.cone("Spike", 0.25, 0.7, "#2A1A14", "matte", loc=tuple(p), seg=6), (math.cos(a), math.sin(a), 0.4))
    R.fins(3, R.fin_pts("blade", 1.0, 0.7, 0.9), 0.16, "#2A1A14", "matte", offset=90)


# =========================================================================
# MONDE 4 — LÉGENDAIRE : créatures et reliques cosmiques
# =========================================================================

@design(31, "Dragon", "Dragon", 4, ("#7CFF6A", 2.1), 1300, 2.5e10)
def _(R):
    R.nozzle(0.5, 0.7, "#2A2C36")
    body = R.lathe("Body", [(0, 0.7), (0.85, 0.7), (1.0, 2.0), (0.95, 4.0), (0.75, 5.4), (0, 5.6)], "#2E9E4A", "metal")
    R.lathe("Belly", [(0, 0.8), (0.4, 0.8), (0.45, 5.0), (0, 5.2)], "#F1C85A", "metal", loc=(0, -0.62, 0), scale=(1.0, 0.5, 1.0))
    R.lathe("Head", [(0, 5.2), (0.75, 5.3), (0.8, 6.0), (0.5, 6.9), (0, 7.3)], "#2E9E4A", "metal")
    R.box("Jaw", (0.9, 0.9, 0.3), "#1F7A38", "metal", loc=(0, -0.45, 5.55), bevel=0.12)
    for s in (1, -1):
        R.ball("Eye", 0.16, "#FFE45C", "glow", loc=(s * 0.38, -0.6, 6.2), scale=(1, 0.6, 0.8))
        R.aim(R.cone("Horn", 0.16, 1.1, "#F1C85A", "metal", loc=(s * 0.45, 0.2, 6.4)), (s * 0.5, 0.6, 1))
        R.fin("Wing", [(0.8, 2.6), (3.2, 4.6), (2.6, 3.3), (2.9, 2.6), (2.1, 2.2), (2.3, 1.4), (0.8, 1.6)], 0.08, "#1F7A38", "metal",
              angle=0 if s > 0 else 180, bevel=0.03)
    for k in range(6):
        R.aim(R.cone("BackSpike", 0.2, 0.55, "#F1C85A", "metal", loc=(0, 0.9 - k * 0.01, 1.2 + k * 0.75), seg=8), (0, 1, 0.5))
    R.fins(2, R.fin_pts("blade", 0.85, 0.7, 0.8), 0.12, "#1F7A38", "metal", offset=90)


@design(32, "Phoenix", "Phénix", 4, ("#FF8A1F", 2.2), 1700, 5e10)
def _(R):
    R.nozzle(0.5, 0.7)
    R.lathe("Body", [(0, 0.7), (0.75, 0.7), (0.9, 2.0), (0.8, 4.4), (0.4, 6.0), (0, 6.6)], "#D62828", "metal")
    R.lathe("Beak", [(0, 5.8), (0.3, 5.8), (0, 6.8)], "#FFC21F", "metal", loc=(0, -0.55, 0), rot=(-25, 0, 0))
    for s in (1, -1):
        R.ball("Eye", 0.13, "#FFFFFF", "glow", loc=(s * 0.28, -0.52, 5.4))
    cols = ["#FFE45C", "#FFB13B", "#FF8A1F", "#FF4A1F"]
    for s in (1, -1):
        for k in range(4):
            o = R.fin("Feather", R.fin_pts("feather", 0.8, 1.8 + k * 0.35, 1.0 - k * 0.12), 0.06, cols[k], "glow" if k == 0 else "metal",
                      angle=(0 if s > 0 else 180), tilt=0)
            o.rotation_euler = (0, D(s * (10 - k * 12)), D(0 if s > 0 else 180))
    for k in range(3):
        R.fin("Crest", [(0.0, 6.0), (0.5 + k * 0.2, 7.0 + k * 0.3), (0.2, 6.2)], 0.05, cols[k], "glow", angle=90 + (k - 1) * 20)
    for k in range(3):
        R.fin("TailFeather", [(0.4, 0.9), (1.4 + k * 0.2, -0.6 - k * 0.3), (0.9, 0.9)], 0.05, cols[k + 1], "metal", angle=90 + (k - 1) * 25)


@design(33, "Shark", "Requin", 4, ("#5EF2FF", 2.3), 2200, 1e11)
def _(R):
    R.nozzle(0.48, 0.7, "#2A2C36")
    R.lathe("Body", [(0, 0.7), (0.7, 0.7), (1.05, 2.4), (1.05, 4.0), (0.8, 5.6), (0.35, 6.8), (0, 7.2)], "#9FB2CC", "metal")
    R.lathe("Belly", [(0, 1.0), (0.6, 1.2), (0.7, 4.0), (0.4, 6.2), (0, 6.6)], "#F2F2F2", "paint", loc=(0, -0.48, 0), scale=(1, 0.6, 1))
    R.box("Mouth", (0.9, 0.2, 0.18), "#3A1F2A", "paint", loc=(0, -0.95, 5.3), bevel=0.06)
    for k in range(5):
        R.cone("Tooth", 0.07, 0.16, "#FFFFFF", "paint", loc=(-0.32 + k * 0.16, -1.0, 5.38), rot=(180, 0, 0), seg=6)
    for s in (1, -1):
        R.ball("Eye", 0.12, "#1E1F26", "paint", loc=(s * 0.55, -0.62, 5.8))
        R.ball("EyeShine", 0.04, "#FFFFFF", "glow", loc=(s * 0.55 + 0.03, -0.72, 5.86))
        R.fin("Pectoral", [(0.9, 3.4), (2.2, 2.4), (2.0, 2.7), (0.9, 4.2)], 0.12, "#9FB2CC", "metal", angle=0 if s > 0 else 180)
    R.fin("Dorsal", [(0.9, 3.4), (2.0, 4.4), (1.3, 4.5), (0.85, 5.0)], 0.14, "#9FB2CC", "metal", angle=90)
    for s in (1, -1):
        R.fin("TailFluke", [(0.5, 1.4), (1.8, 0.0 if s > 0 else 2.6), (1.0, 1.4)], 0.12, "#9FB2CC", "metal", angle=90 if s > 0 else 90)
    R.fins(2, R.fin_pts("stub", 0.7, 0.7, 0.8), 0.12, "#7C8DA6", "metal", offset=0)
    for k in range(3):
        R.box("Gill", (0.04, 0.05, 0.5), "#3A4A62", "dark", loc=(0.98, -0.25 - k * 0.15, 4.4), rot=(0, 0, 20), bevel=0)


@design(34, "SpaceWhale", "Baleine cosmique", 4, ("#7FD0FF", 2.3), 2900, 2e11)
def _(R):
    R.nozzle(0.55, 0.6, "#1E2A5A")
    prof = [(0, 0.6)] + [(1.45 * math.sin(math.pi * t / 18) ** 0.6 * (1 - 0.25 * t / 18), 0.6 + 6.0 * t / 18) for t in range(1, 18)] + [(0, 6.6)]
    R.lathe("Body", prof, "#2F5BD6", "metal")
    R.lathe("Belly", [(0, 1.0), (0.9, 1.4), (1.0, 4.0), (0.5, 5.8), (0, 6.0)], "#BFE3FF", "paint", loc=(0, -0.62, 0), scale=(1, 0.55, 1))
    for k in range(7):
        R.box("Groove", (0.05, 0.06, 2.5), "#7FB0E6", "paint", loc=(-0.45 + k * 0.15, -1.05, 3.4), bevel=0)
    for s in (1, -1):
        R.ball("Eye", 0.13, "#FFFFFF", "glow", loc=(s * 0.9, -0.62, 4.7))
        R.fin("Flipper", [(1.1, 3.0), (2.6, 2.0), (2.7, 2.4), (1.2, 3.6)], 0.14, "#2F5BD6", "metal", angle=0 if s > 0 else 180, bevel=0.06)
    rnd = random.Random(34)
    for k in range(14):
        a = rnd.uniform(-1.2, 4.3)
        z = rnd.uniform(1.6, 5.6)
        r = 1.45 * math.sin(math.pi * (z - 0.6) / 6.0) ** 0.6 * (1 - 0.25 * (z - 0.6) / 6) + 0.02
        R.ball("Star", 0.08, "#FFFFFF", "glow", loc=(r * math.cos(a), r * math.sin(a), z), seg=8)
    R.cyl("Blowhole", 0.12, 0.3, "#1E2A5A", "dark", loc=(0, 0.25, 6.45))
    for k in range(3):
        R.ball("Spout", 0.18 - k * 0.04, "#BFF7FF", "glow", loc=(0, 0.25, 6.95 + k * 0.35))


@design(35, "Galaxy", "Spirale galactique", 4, ("#B36BFF", 2.4), 3800, 4e11)
def _(R):
    R.nozzle(0.48, 0.7, "#1A1026")
    R.lathe("Body", [(0, 0.7), (0.75, 0.7), (0.9, 2.0), (0.85, 4.6), (0.4, 6.6), (0, 7.6)], "#2A1650", "metal")
    for arm in range(2):
        for k in range(26):
            t = k / 26
            a = arm * math.pi + t * 4 * math.pi
            z = 1.0 + t * 5.6
            r = 0.92 * (1 - 0.45 * t) + 0.03
            R.ball("SpiralStar", 0.11 - 0.05 * t, "#E6B8FF" if k % 3 else "#FFFFFF", "glow", loc=(r * math.cos(a), r * math.sin(a), z), seg=8)
    R.ring("GalaxyDisc", 2.0, 0.05, "#B36BFF", "glow", loc=(0, 0, 2.6), rot=(18, 0, 0), seg=64)
    R.ring("GalaxyDisc", 1.6, 0.04, "#FF8AE0", "glow", loc=(0, 0, 2.6), rot=(18, 0, 0), seg=64)
    R.ball("Core", 0.25, "#FFFFFF", "glow", loc=(0, 0, 7.6))
    R.fins(4, R.fin_pts("blade", 0.85, 0.7, 0.85), 0.12, "#4B1C8F", "metal", offset=45)


@design(36, "Samurai", "Samouraï", 4, ("#FF4A4A", 2.5), 5000, 8e11)
def _(R):
    R.nozzle(0.5, 0.7, "#1E1F26")
    R.lathe("Body", [(0, 0.7), (0.8, 0.7), (0.9, 2.0), (0.85, 4.6), (0.7, 5.4), (0, 5.5)], "#B3161E", "paint")
    for k in range(4):
        z = 1.3 + k * 0.85
        for i, a, p in circle(6, 0.92, z, 30 * (k % 2)):
            R.box("ArmorPlate", (0.55, 0.12, 0.5), "#1E1F26", "metal", loc=tuple(p), rot=(0, 0, math.degrees(a) + 90), bevel=0.04)
        R.ring("Lace", 0.93, 0.04, "#FFC21F", "metal", loc=(0, 0, z - 0.32))
    R.lathe("Helmet", [(0, 5.3), (0.95, 5.3), (0.9, 5.8), (0.5, 6.3), (0, 6.4)], "#1E1F26", "metal")
    R.box("Visor", (1.0, 0.25, 0.22), "#FFC21F", "metal", loc=(0, -0.7, 5.6), bevel=0.06)
    for s in (1, -1):
        R.fin("Kuwagata", [(0.1, 6.0), (0.9, 7.6), (1.0, 7.8), (0.3, 6.1)], 0.08, "#FFC21F", "metal", angle=90 + s * 60 - 90 + (0 if s > 0 else 180))
    R.lathe("Blade", [(0, 6.3), (0.12, 6.3), (0.08, 8.3), (0, 8.8)], "#E8ECF2", "metal", seg=4, scale=(1.0, 0.35, 1.0))
    R.ring("Tsuba", 0.3, 0.07, "#FFC21F", "metal", loc=(0, 0, 6.35))
    R.fins(3, R.fin_pts("blade", 0.85, 0.7, 0.85), 0.1, "#1E1F26", "metal", offset=90)


@design(37, "RoyalCrown", "Couronne royale", 4, ("#FFD35A", 2.6), 6500, 1.6e12)
def _(R):
    R.nozzle(0.5, 0.7, "#8A6A1A")
    R.lathe("Body", [(0, 0.7), (0.75, 0.7), (0.9, 1.8), (0.9, 4.4), (0.8, 5.0), (0, 5.0)], "#F1C85A", "metal")
    R.band(2.0, 0.93, 0.5, "#8E1B2E", "paint", base="Velvet")
    R.band(3.4, 0.93, 0.5, "#8E1B2E", "paint", base="Velvet")
    R.ball("Jewel", 0.3, "#E8172E", "glass", loc=(0, -0.88, 3.0), scale=(1, 0.5, 1.2))
    R.lathe("CrownBase", [(0, 5.0), (1.0, 5.0), (1.05, 5.5), (0, 5.5)], "#FFC21F", "metal")
    for i, a, p in circle(5, 0.9, 5.4, 90):
        R.cone("CrownSpike", 0.28, 1.2, "#FFC21F", "metal", loc=tuple(p), seg=8)
        R.ball("CrownGem", 0.14, ["#E8172E", "#2F7BFF", "#2EC27E", "#B36BFF", "#FFFFFF"][i], "glass", loc=(p.x, p.y, p.z + 1.25))
    R.ball("Orb", 0.35, "#FFC21F", "metal", loc=(0, 0, 6.2))
    R.lathe("Cross", [(0, 0), (0.07, 0), (0.07, 0.6), (0, 0.6)], "#FFC21F", "metal", seg=8, loc=(0, 0, 6.5))
    R.box("CrossBar", (0.4, 0.1, 0.1), "#FFC21F", "metal", loc=(0, 0, 6.85), bevel=0.03)
    R.fins(4, R.fin_pts("swept", 0.85, 0.7, 0.85), 0.12, "#FFC21F", "metal", offset=45)


@design(38, "BlackHole", "Trou noir", 4, ("#FF8A3A", 2.7), 8500, 3.2e12)
def _(R):
    R.nozzle(0.5, 0.7, "#0B0B12")
    R.lathe("Body", [(0, 0.7), (0.65, 0.7), (0.75, 2.0), (0.6, 4.0), (0, 4.4)], "#14141C", "metal")
    R.ball("Singularity", 1.25, "#05050A", "matte", loc=(0, 0, 5.4))
    R.ring("PhotonRing", 1.3, 0.06, "#FFE0A0", "glow", loc=(0, 0, 5.4), rot=(90, 0, 15), seg=64)
    for k, (Rr, c) in enumerate(((1.9, "#FFB13B"), (2.4, "#FF8A3A"), (2.9, "#FF4A1F"))):
        R.ring("AccretionDisk", Rr, 0.14 - k * 0.03, c, "glow", loc=(0, 0, 5.4), rot=(72, 0, 15), seg=72)
    R.fins(3, R.fin_pts("blade", 0.65, 0.7, 0.9), 0.1, "#2A2C36", "metal", offset=90)
    for k in range(3):
        R.ring("Band", 0.72, 0.04, "#FF8A3A", "glow", loc=(0, 0, 1.6 + k * 0.7))


@design(39, "Angel", "Ange", 4, ("#FFF4C2", 2.8), 11000, 6.5e12)
def _(R):
    R.nozzle(0.48, 0.7, "#C9A23A")
    R.lathe("Body", [(0, 0.7), (0.75, 0.7), (0.9, 2.0), (0.85, 4.4), (0.45, 6.0), (0, 6.8)], "#F7F7F2", "metal")
    R.band(2.4, 0.93, 0.18, "#F1C85A", "metal")
    R.band(4.2, 0.88, 0.18, "#F1C85A", "metal")
    for s in (1, -1):
        for k in range(5):
            o = R.fin("WingFeather", R.fin_pts("feather", 0.8, 2.2 + k * 0.28, 1.25 - k * 0.15), 0.07, "#FFFFFF" if k % 2 == 0 else "#F1E6C8", "paint",
                      angle=(0 if s > 0 else 180), bevel=0.03)
            o.rotation_euler = (0, D(s * (25 - k * 10)), D(0 if s > 0 else 180) + D(s * 8))
    R.ring("Halo", 0.75, 0.1, "#FFE45C", "glow", loc=(0, 0, 7.4), rot=(12, 0, 0))
    R.porthole(4.8, 0.7, 0.24, glass="#FFE45C", frame="#F1C85A")


@design(40, "CosmicLegend", "Légende cosmique", 4, ("#FFD35A", 3.0), 15000, 1.5e13)
def _(R):
    for i, a, p in circle(3, 0.42, 0, 90):
        R.nozzle(0.24, 0.6, "#C9A23A", loc=(p.x, p.y, 0))
    R.lathe("Body", [(0, 0.6), (0.85, 0.6), (1.0, 2.0), (0.95, 4.8), (0.55, 6.8), (0, 8.4)], "#F7F7F2", "metal")
    R.lathe("Nose", [(0, 6.6), (0.6, 6.6), (0.25, 7.8), (0, 8.5)], "#FFC21F", "metal")
    R.ball("StarCore", 0.42, "#FFFFFF", "glow", loc=(0, -0.85, 4.2), scale=(1, 0.5, 1))
    R.ring("StarFrame", 0.48, 0.08, "#FFC21F", "metal", loc=(0, -0.9, 4.2), rot=(90, 0, 0))
    for k, (z, Rr, tilt, c) in enumerate(((2.4, 2.6, 14, "#FFD35A"), (4.6, 2.1, -18, "#B36BFF"), (6.2, 1.5, 24, "#5EF2FF"))):
        R.ring("OrbitRing", Rr, 0.09, c, "glow", loc=(0, 0, z), rot=(tilt, tilt * 0.5, 0), seg=72)
    for s in (1, -1):
        R.fin("CrystalWing", [(0.9, 1.2), (3.0, 0.2), (3.4, 0.6), (2.0, 2.4), (2.8, 3.4), (0.9, 4.2)], 0.12, "#FFC21F", "metal",
              angle=0 if s > 0 else 180, bevel=0.04)
        R.fin("WingGlow", [(2.0, 2.4), (2.8, 3.4), (2.95, 3.25), (2.15, 2.25)], 0.16, "#5EF2FF", "glow", angle=0 if s > 0 else 180, bevel=0)
    R.fins(2, R.fin_pts("blade", 0.95, 0.6, 0.9), 0.12, "#FFC21F", "metal", offset=90)
    for i, a, p in circle(6, 1.05, 5.6, 0):
        R.ball("Gem", 0.1, "#5EF2FF", "glow", loc=tuple(p), seg=10)


assert len(DESIGNS) == 40, len(DESIGNS)
assert sorted(d["id"] for d in DESIGNS) == list(range(1, 41))
