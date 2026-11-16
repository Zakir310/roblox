"""
render_shots.py — rend les plans 3D du teaser « SOON. » avec les vraies fusées du jeu (Blender/Cycles).

    python render_shots.py --out DIR [--shots 0,5] [--res 1536] [--samples 16] [--frames first]

Rendu en 16:9 ; le montage (edit.py) en tire la version YouTube et la version verticale TikTok/Shorts.
Le plan de montage (durée de chaque plan, en images) est dans SHOTS, à 30 i/s, un temps = 11 images (~164 BPM).
"""

import argparse
import json
import math
import os
import random
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "rockets"))

import rocketlib as L  # noqa: E402
from rocketlib2 import Rocket  # noqa: E402
from designs_v2 import DESIGNS  # noqa: E402
import render_thumbs as T  # noqa: E402

DESIGN = {d["id"]: d for d in DESIGNS}
CAT = {r["id"]: r for r in json.load(open(os.path.join(HERE, "..", "..", "assets", "rockets", "catalog.json"), encoding="utf-8"))["rockets"]}
BEAT = 11


# ---------------------------------------------------------------- utilitaires

def ease(u, p=2.2):
    return 1.0 - (1.0 - u) ** p


def lerp(a, b, u):
    return Vector(a) + (Vector(b) - Vector(a)) * u


def mat(name, hexcol, rough=0.7, emit=0.0, metal=0.0):
    return L.make_material(name, hexcol, metal, rough, hexcol if emit else None, emit)


def rocket(c, rid):
    R = Rocket(rid, DESIGN[rid]["key"], c)
    DESIGN[rid]["build"](R)
    return R.root


def camera(c, lens=40):
    cam = bpy.data.cameras.new("Cam")
    cam.lens = lens
    cam.sensor_width = 36
    cam.clip_end = 3000
    o = bpy.data.objects.new("Cam", cam)
    c.objects.link(o)
    bpy.context.scene.camera = o
    return o


def aim(cam, loc, target, roll=0.0):
    cam.location = loc
    q = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y")
    e = q.to_euler()
    cam.rotation_euler = e
    if roll:
        cam.rotation_mode = "QUATERNION"
        from mathutils import Quaternion
        cam.rotation_quaternion = q @ Quaternion((0, 0, 1), math.radians(roll))


def cone_tree(c, loc, s, rnd, mats):
    x, y = loc
    L.lathe("Trunk", [(0.35 * s, 0), (0.28 * s, 1.6 * s)], mats["trunk"], None, c, segments=6).location = (x, y, 0)
    z = 1.2 * s
    for k in range(3):
        r = (1.7 - 0.42 * k) * s
        o = L.lathe("Leaf", [(r, 0), (r * 0.25, 1.5 * s), (0, 1.55 * s)], mats["leaf%d" % (k % 2)], None, c, segments=7)
        o.location = (x, y, z)
        o.rotation_euler = (0, 0, rnd.uniform(0, 3))
        z += 1.05 * s


def round_tree(c, loc, s, rnd, mats):
    x, y = loc
    L.lathe("Trunk", [(0.4 * s, 0), (0.3 * s, 2.2 * s)], mats["trunk"], None, c, segments=6).location = (x, y, 0)
    for k in range(4):
        off = Vector((rnd.uniform(-0.8, 0.8), rnd.uniform(-0.8, 0.8), rnd.uniform(0, 1.2))) * s
        T.blob("Leaf", rnd.uniform(1.1, 1.6) * s, Vector((x, y, 2.9 * s)) + off, mats["leaf%d" % (k % 2)], c)


# ---------------------------------------------------------------- décors

PADS = [(-36, 6), (-24, 0), (-12, -4), (0, -6), (12, -4), (24, 0), (36, 6)]


def env_base(c, ids, lit=None, seed=3):
    """Base de lancement de jour : pelouse, aires de lancement, tour, hangar, arbres, collines, nuages."""
    rnd = random.Random(seed)
    T.sky_world("#1F7BFF", "#A6E1FF", 1.05)
    T.sun(c, (48, 8, -38), 4.2, (1.0, 0.96, 0.86), 4)
    M = dict(trunk=mat("Trunk", "#7A4A2A"), leaf0=mat("Leaf0", "#2FAE3A"), leaf1=mat("Leaf1", "#24923A"))
    grass = mat("Grass", "#5AD23A", 0.9)
    L.lathe("Ground", [(900, -0.2), (900, 0.0)], grass, None, c, segments=48)
    grass2 = mat("Grass2", "#49BE33", 0.9)
    for k in range(26):  # damier d'herbe : bandes plus sombres
        L.box("Stripe", (7, 300, 0.04), (-91 + k * 14, 40, 0.0), grass2, None, c)
    path = mat("Path", "#F2DFA0", 0.85)
    L.box("Road", (96, 7, 0.08), (0, -16, 0.02), path, None, c)
    L.box("Road2", (7, 60, 0.08), (0, -49.5, 0.02), path, None, c)
    pad = mat("Pad", "#9AA3AE", 0.75)
    pad2 = mat("Pad2", "#5D6672", 0.75)
    hazard = mat("Hazard", "#FFC928", 0.6, 0.6)
    roots = {}
    for i, (px, py) in enumerate(PADS):
        L.lathe("Pad", [(4.2, 0), (4.2, 0.45), (3.7, 0.6)], pad, None, c, segments=8).location = (px, py, 0)
        L.lathe("PadTop", [(2.6, 0.6), (2.6, 0.75)], pad2, None, c, segments=24).location = (px, py, 0)
        L.torus("PadRing", 3.3, 0.14, (px, py, 0.62), hazard, None, c, seg_major=32, seg_minor=6)
        L.box("PadPath", (2.4, abs(-12.5 - py) - 4, 0.08), (px, (py - 4 - 12.5) / 2, 0.02), path, None, c)
        if i < len(ids) and ids[i]:
            r = rocket(c, ids[i])
            r.location = (px, py, 0.95)
            r.rotation_euler = (0, 0, rnd.uniform(-0.6, 0.6))
            roots[ids[i]] = r
            for sx in (-1, 1):  # bras de maintien
                L.box("Clamp", (0.25, 0.25, 1.3), (px + sx * 1.6, py, 1.2), pad2, None, c, rotation=(0, -sx * 22, 0))
    # tour de lancement (derrière l'aire centrale)
    red, white, dark = mat("TowerR", "#EE4130", 0.5), mat("TowerW", "#F4F6FA", 0.5), mat("TowerD", "#39424E", 0.6)
    tx, ty = 5.5, -1.5
    for k in range(9):
        z = 1.0 + k * 2.0
        m = red if k % 2 == 0 else white
        for dx, dy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            L.box("TwPost", (0.3, 0.3, 2.0), (tx + dx * 1.1, ty + dy * 1.1, z), m, None, c)
        L.box("TwDeck", (2.5, 2.5, 0.12), (tx, ty, z + 1.0), white if k % 2 else red, None, c)
    L.box("TwArm", (3.6, 0.5, 0.4), (tx - 2.6, ty - 1.2, 9.0), white, None, c, rotation=(0, 0, 25))
    L.lathe("TwMast", [(0.12, 0), (0.05, 5)], dark, None, c, segments=6).location = (tx, ty, 19)
    T.blob("TwLamp", 0.3, (tx, ty, 24.1), mat("Lamp", "#FF3B3B", 0.4, 6.0), c)
    # hangar + centre de contrôle + cuves
    blue, roof, glass = mat("Hangar", "#3F7BEA", 0.6), mat("Roof", "#F4F6FA", 0.5), mat("Glass", "#7FE3FF", 0.15, 0.8)
    L.box("Hangar", (22, 14, 8), (-50, 34, 4), blue, None, c)
    o = L.lathe("HangarRoof", [(7.2, -11.2), (7.2, 11.2)], roof, None, c, segments=20)
    o.location, o.rotation_euler, o.scale = (-50, 34, 8), (0, math.radians(90), 0), (0.45, 1, 1)
    L.box("HangarDoor", (9, 0.3, 6), (-50, 26.9, 3), dark, None, c)
    L.box("Control", (12, 9, 6), (46, 32, 3), roof, None, c)
    L.box("ControlWin", (10.5, 0.3, 1.6), (46, 27.4, 4.2), glass, None, c)
    L.box("ControlTop", (5, 5, 3), (46, 32, 7.5), red, None, c)
    L.lathe("Dish", [(0, 0), (1.6, 0.5), (2.4, 1.4)], roof, None, c, segments=16).location = (48, 32, 9.5)
    for k in range(3):
        L.lathe("Tank", [(0, 0), (2, 0.3), (2, 4.2), (1.2, 5.2), (0, 5.5)], white, None, c, segments=16).location = (22 + k * 5.2, 24, 0)
    # arbres, collines, nuages
    for k in range(150):
        a, d = rnd.uniform(0, 2 * math.pi), rnd.uniform(34, 150)
        x, y = math.cos(a) * d, math.sin(a) * d + 12
        if abs(x) < 62 and -24 < y < 18 or abs(x + 50) < 16 and abs(y - 34) < 12 or abs(x - 40) < 26 and abs(y - 30) < 12 or abs(x) < 11 and y < -16:
            continue
        (cone_tree if k % 3 else round_tree)(c, (x, y), rnd.uniform(1.3, 2.6), rnd, M)
    hill = mat("Hill", "#3FB548", 0.95)
    for k in range(16):
        a = k / 16 * 2 * math.pi + rnd.uniform(-0.1, 0.1)
        d = rnd.uniform(210, 290)
        T.blob("Hill", rnd.uniform(60, 110), (math.cos(a) * d, math.sin(a) * d, -rnd.uniform(25, 50)), hill, c, squash=(1, 1, 0.75))
    cm = mat("Cloud", "#FFFFFF", 0.95, 0.12)
    for k in range(22):
        a, d = rnd.uniform(0, 2 * math.pi), rnd.uniform(90, 260)
        T.cloud(c, (math.cos(a) * d, math.sin(a) * d, rnd.uniform(38, 85)), rnd.uniform(6, 12), 100 + k, cm)
    return roots


SKIES = {
    "sky": dict(top="#1560FF", bottom="#8FD6FF", cloud="#FFFFFF", emit=0.14, sun=(1.0, 0.96, 0.88), rim=(0.6, 0.85, 1.0), stars=False),
    "sunset": dict(top="#4A2FB8", bottom="#FF9A4D", cloud="#FFC9B8", emit=0.22, sun=(1.0, 0.72, 0.45), rim=(1.0, 0.5, 0.7), stars=False),
    "space": dict(top="#0E0530", bottom="#5A1FA8", cloud=None, emit=0, sun=(1.0, 0.92, 0.8), rim=(0.8, 0.5, 1.0), stars=True),
}


def env_flight(c, kind, seed):
    """Ciel / coucher de soleil / espace autour d'une trajectoire verticale qui passe par l'origine."""
    k = SKIES[kind]
    rnd = random.Random(seed)
    T.sky_world(k["top"], k["bottom"], 1.0, stars=k["stars"])
    T.sun(c, (52, 6, -35 + rnd.uniform(-25, 25)), 3.6, k["sun"], 5)
    if k["cloud"]:
        cm = mat("Cloud", k["cloud"], 0.95, k["emit"])
        for i in range(46):
            a, d = rnd.uniform(0, 2 * math.pi), rnd.uniform(16, 95)
            T.cloud(c, (math.cos(a) * d, math.sin(a) * d, rnd.uniform(-70, 90)), rnd.uniform(2.6, 7.5), seed * 100 + i, cm)
        for i in range(40):  # mer de nuages, loin dessous
            T.cloud(c, (rnd.uniform(-240, 240), rnd.uniform(-60, 320), -120 + rnd.uniform(-12, 12)), rnd.uniform(16, 30), seed * 100 + 60 + i, cm)
    else:
        planet = mat("Planet", rnd.choice(["#2F7BFF", "#28B8A0", "#FF7A3D"]), 0.6)
        pc = Vector((rnd.uniform(-30, 30), 120, -150))
        T.blob("Planet", 130, pc, planet, c)
        L.torus("Atmo", 130.6, 0.9, pc, mat("Atmo", "#8FD8FF", 0.5, 3.0), None, c, seg_major=128, rotation=(70, 0, 0))
        T.blob("Moon", 9, (rnd.choice([-1, 1]) * rnd.uniform(40, 60), 110, rnd.uniform(15, 45)), mat("Moon", "#E9E4F5", 0.9, 0.05), c)
        rock = mat("Rock", "#6B5A8E", 0.9)
        rock2 = mat("Rock2", "#8E6BB8", 0.9)
        for i in range(70):
            a, d = rnd.uniform(0, 2 * math.pi), rnd.uniform(13, 80)
            s = rnd.uniform(0.5, 2.6)
            o = T.blob("Rock", s, (math.cos(a) * d, math.sin(a) * d, rnd.uniform(-60, 80)), rock if i % 2 else rock2, c,
                       squash=(rnd.uniform(0.6, 1), rnd.uniform(0.6, 1), rnd.uniform(0.5, 1)))
            o.rotation_euler = (rnd.uniform(0, 3), rnd.uniform(0, 3), 0)
        star = mat("Star", "#FFFFFF", 0.5, 8.0)
        for i in range(160):
            a, d = rnd.uniform(0, 2 * math.pi), rnd.uniform(25, 140)
            T.blob("StarDot", rnd.uniform(0.08, 0.22), (math.cos(a) * d, math.sin(a) * d, rnd.uniform(-90, 110)), star, c)
    return k


def flying(c, rid, kind, tilt=0.0, yaw=0.0, palette=None, trail=True, seed=1):
    """Fusée en vol avec son panache, attachée à un rig qu'on déplace ; traînée de fumée fixe derrière."""
    h, rad = CAT[rid]["height"], CAT[rid]["radius"]
    rig = bpy.data.objects.new("Rig", None)
    c.objects.link(rig)
    root = rocket(c, rid)
    root.parent = rig
    pc = T.col("Plume")
    pl, pr = max(5.0, h * 0.85), max(0.55, min(1.0, rad * 0.4))
    T.cartoon_plume(pc, Vector((0, 0, 0.05)), Vector((0, 0, 1)), length=pl, radius=pr, seed=seed, palette=palette)
    flames = []
    for o in list(pc.objects):
        if o.name.startswith("Smoke"):
            bpy.data.objects.remove(o, do_unlink=True)
            continue
        o.parent = rig
        if o.name.startswith("Flame"):
            flames.append(o)
    k = SKIES[kind]
    for nm, loc, en, colr, size in (("Rim", (-5, 7, h + 2), 2600, k["rim"], 4), ("Key", (8, -9, h), 2100, k["sun"], 6)):
        ld = bpy.data.lights.new(nm, "AREA")
        ld.energy, ld.color, ld.size = en, colr, size
        lo = bpy.data.objects.new(nm, ld)
        c.objects.link(lo)
        lo.location = loc
        lo.rotation_euler = (Vector((0, 0, h * 0.45)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        lo.parent = rig
    rig.rotation_euler = (0, math.radians(tilt), math.radians(yaw))
    bpy.context.view_layer.update()
    axis = (rig.matrix_world.to_3x3() @ Vector((0, 0, 1))).normalized()
    if trail:
        rnd = random.Random(seed)
        sm = mat("Trail", "#F4F6FA" if kind != "sunset" else "#FFD9CC", 0.9, 0.15)
        for i in range(46):
            t = pl * 0.9 + i * 1.5
            p = -axis * t + Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))) * (0.3 + i * 0.05)
            T.blob("Trail", pr * (0.9 + i * 0.07) * rnd.uniform(0.8, 1.2), p, sm, c)
    return dict(rig=rig, axis=axis, flames=flames, h=h, rad=rad, rnd=random.Random(seed * 7))


def flicker(fl):
    for i, o in enumerate(fl["flames"]):
        s = 1.0 + fl["rnd"].uniform(-0.09, 0.12)
        o.scale = (1.0 + fl["rnd"].uniform(-0.05, 0.05), 1.0 + fl["rnd"].uniform(-0.05, 0.05), s)


# ---------------------------------------------------------------- plans

def base_shot(ids, p0, t0, p1, t1, lens=32, roll=(0, 0), launch=None, power=2.2):
    """Plan sur la base : caméra de p0→p1 en visant t0→t1. launch=(id, vitesse) fait décoller une fusée."""
    def make(c):
        roots = env_base(c, ids)
        cam = camera(c, lens)
        fl = None
        if launch:
            rid = launch[0]
            r = roots[rid]
            pc = T.col("Plume")
            T.cartoon_plume(pc, Vector(r.location) + Vector((0, 0, 0.05)), Vector((0, 0, 1)), length=6.0, radius=0.9, seed=5)
            mov = [o for o in pc.objects if not o.name.startswith("Smoke")] + [r]
            z0 = {o.name: o.location.z for o in mov}
            smoke = [o for o in pc.objects if o.name.startswith("Smoke")]
            rnd = random.Random(2)
            for o in smoke:  # fumée de décollage : couronne au sol
                a, d = rnd.uniform(0, 2 * math.pi), rnd.uniform(2.5, 9)
                o.location = (r.location.x + math.cos(a) * d, r.location.y + math.sin(a) * d, rnd.uniform(0.6, 2.2))
                o.scale = (1.8, 1.8, 1.5)
            fl = dict(flames=[o for o in mov if o.name.startswith("Flame")], rnd=random.Random(9))

        def anim(u, f):
            e = ease(u, power)
            aim(cam, lerp(p0, p1, e), lerp(t0, t1, e), roll[0] + (roll[1] - roll[0]) * e)
            if launch:
                dz = launch[1] * (u ** 1.6)
                for o in mov:
                    o.location.z = z0[o.name] + dz
                flicker(fl)
                for o in smoke:
                    s = 1.8 + 1.4 * u
                    o.scale = (s, s, s * 0.8)
        return anim
    return make


def fly_shot(rid, kind, style, tilt=12, yaw=0, lens=40, speed=1.1, seed=1, palette=None, frac=0.5, roll=0):
    """Plan en vol. style choisit le placement caméra, relatif à la fusée (h = sa hauteur)."""
    def make(c):
        env_flight(c, kind, seed)
        fl = flying(c, rid, kind, tilt, yaw, palette, seed=seed)
        cam = camera(c, lens)
        h = fl["h"]
        d = (max(h, 2.4 * fl["rad"]) * 1.15 / frac) / (2 * math.tan(math.atan(18 / lens)))  # distance pour que la fusée occupe frac du cadre
        A = {  # (pos0, pos1, visée0, visée1) relatifs à la fusée, en multiples de d / h
            "side": ((0.35 * d, -d, 0.05 * h), (0.15 * d, -d * 0.9, 0.2 * h), (0, 0, 0.35 * h), (0, 0, 0.45 * h)),
            "low": ((0.3 * d, -0.75 * d, -0.55 * d), (0.2 * d, -0.7 * d, -0.45 * d), (0, 0, 0.4 * h), (0, 0, 0.5 * h)),
            "high": ((-0.3 * d, -0.7 * d, 0.75 * d), (-0.2 * d, -0.65 * d, 0.6 * d), (0, 0, 0.45 * h), (0, 0, 0.4 * h)),
            "orbit": ((-0.6 * d, -0.8 * d, 0.1 * d), (-0.25 * d, -0.95 * d, 0.15 * d), (0, 0, 0.45 * h), (0, 0, 0.45 * h)),
            "close": ((0.4 * d, -0.72 * d, 0.2 * h), (0.28 * d, -0.66 * d, 0.4 * h), (0, 0, 0.5 * h), (0, 0, 0.58 * h)),
            "chase": ((0.25 * d, -0.5 * d, -0.9 * d), (0.15 * d, -0.45 * d, -0.8 * d), (0, 0, 0.3 * h), (0, 0, 0.5 * h)),
            "push": ((0.2 * d, -1.5 * d, 0.1 * h), (0.1 * d, -1.0 * d, 0.2 * h), (0, 0, 0.4 * h), (0, 0, 0.45 * h)),
            "pull": ((-0.15 * d, -0.9 * d, 0.3 * h), (-0.3 * d, -1.35 * d, 0.1 * h), (0, 0, 0.45 * h), (0, 0, 0.4 * h)),
        }[style]

        def anim(u, f):
            e = ease(u)
            pos = fl["axis"] * (speed * f)
            fl["rig"].location = pos
            flicker(fl)
            aim(cam, pos + lerp(A[0], A[1], e), pos + lerp(A[2], A[3], e), roll * (1 - e))
        return anim
    return make


FIRE_PINK = ["#FFFFF5", "#FFE45C", "#FFB13B", "#FF6AD5"]
FIRE_BLUE = ["#FFFFFF", "#B8F4FF", "#5EC8FF", "#3B6BFF"]
FIRE_GREEN = ["#FFFFF0", "#D8FF7A", "#7CFF6A", "#1FD08A"]
FIRE_GOLD = ["#FFFFF5", "#FFF07A", "#FFC23B", "#FF8A1F"]
ROW1 = [2, 3, 4, 1, 5, 6, 7]

# (nom, images, fabrique)  — 30 i/s, 1 temps = 11 images
SHOTS = [
    ("00_base_aerienne", 16, base_shot(ROW1, (0, -96, 84), (0, 0, 0), (0, -74, 62), (0, 2, 0), 30)),
    ("01_petard_contre_plongee", 11, base_shot(ROW1, (7, -22, 1.6), (0, -6, 5.5), (5, -19, 1.8), (0, -6, 5.6), 28)),
    ("02_rangee_travelling", 11, base_shot(ROW1, (-44, -22, 5), (-14, 0, 4), (-30, -20, 4.5), (-4, 0, 4), 30)),
    ("03_retro_gros_plan", 11, base_shot(ROW1, (42, -5, 7.5), (36, 6, 6.2), (41, -3, 8.5), (36, 6, 6.6), 40)),
    ("04_tour", 11, base_shot(ROW1, (-12, -30, 3), (4, -2, 11), (-8, -27, 3.5), (4, -2, 12), 26, roll=(-5, 0))),
    ("05_jouet_arbres", 11, base_shot(ROW1, (20, -17, 3), (12, -4, 4.5), (17, -16, 3.6), (12, -4, 4.6), 34)),
    ("06_carton_plongee", 11, base_shot(ROW1, (-18, -14, 17), (-12, -4, 4), (-16, -12, 15), (-12, -4, 4), 34)),
    ("07_allee", 11, base_shot(ROW1, (0, -60, 2.2), (0, -6, 6), (0, -50, 2.4), (0, -6, 6.4), 30)),
    ("08_decollage", 33, base_shot([2, 3, 4, 13, 5, 6, 7], (10, -26, 1.4), (0, -6, 5), (8, -23, 2.2), (0, -6, 30), 26,
                                   launch=(13, 30.0), power=1.4)),
    ("09_v2_cote", 11, fly_shot(11, "sky", "side", 14, seed=2)),
    ("10_saturne_dessous", 11, fly_shot(12, "sky", "low", 6, seed=3)),
    ("11_reutilisable_orbite", 11, fly_shot(15, "sky", "orbit", -10, seed=4, palette=FIRE_BLUE)),
    ("12_soyouz_dessus", 11, fly_shot(14, "sky", "high", 18, seed=5)),
    ("13_marteau_proche", 11, fly_shot(17, "sky", "close", -8, seed=6, palette=FIRE_BLUE)),
    ("14_jet_poursuite", 11, fly_shot(19, "sky", "chase", 20, seed=7)),
    ("15_vapeur_cote", 11, fly_shot(21, "sunset", "side", -12, seed=8)),
    ("16_soucoupe", 11, fly_shot(24, "sunset", "high", 10, seed=9, palette=FIRE_GREEN, frac=0.5)),
    ("17_meduse", 11, fly_shot(26, "sunset", "orbit", 8, seed=10, palette=FIRE_PINK)),
    ("18_cristaux_dessous", 11, fly_shot(27, "sunset", "low", -6, seed=11, palette=FIRE_BLUE)),
    ("19_double_coque", 11, fly_shot(29, "sunset", "push", 16, seed=12)),
    ("20_magma_proche", 11, fly_shot(30, "sunset", "close", -14, seed=13)),
    ("21_voile_solaire", 22, fly_shot(28, "space", "pull", 10, seed=14, palette=FIRE_GOLD, speed=0.8, roll=-6)),
    ("22_dragon", 11, fly_shot(31, "space", "side", -16, seed=15, palette=FIRE_GREEN)),
    ("23_phenix", 11, fly_shot(32, "space", "low", 12, seed=16, palette=FIRE_GOLD, frac=0.42)),
    ("24_requin", 11, fly_shot(33, "space", "orbit", -20, seed=17, palette=FIRE_BLUE)),
    ("25_baleine", 11, fly_shot(34, "space", "high", 14, seed=18, palette=FIRE_BLUE)),
    ("26_samourai", 11, fly_shot(36, "space", "close", -10, seed=19)),
    ("27_trou_noir", 11, fly_shot(38, "space", "push", 8, seed=20, palette=FIRE_GOLD)),
    ("28_legende", 33, fly_shot(40, "space", "push", 10, seed=21, palette=FIRE_PINK, speed=0.7, frac=0.55, lens=36)),
]


def setup(scene, res, samples):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_adaptive_sampling = False
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 3
    scene.cycles.diffuse_bounces = 2
    scene.cycles.glossy_bounces = 2
    scene.cycles.transparent_max_bounces = 6
    scene.cycles.caustics_reflective = False
    scene.cycles.caustics_refractive = False
    scene.render.use_persistent_data = True
    scene.render.resolution_x, scene.render.resolution_y = res, res * 9 // 16
    scene.cycles.denoising_prefilter = "FAST"
    scene.cycles.denoising_quality = "FAST"
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.compression = 15
    scene.view_settings.view_transform = "Standard"


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--shots", default="")
    ap.add_argument("--res", type=int, default=1440)
    ap.add_argument("--samples", type=int, default=6)
    ap.add_argument("--frames", default="all", help="all | first | mid")
    a = ap.parse_args(argv)
    sel = [int(x) for x in a.shots.split(",")] if a.shots else range(len(SHOTS))
    for i in sel:
        name, n, make = SHOTS[i]
        d = os.path.join(a.out, name)
        os.makedirs(d, exist_ok=True)
        frames = {"all": range(n), "first": [0], "mid": [n // 2]}[a.frames]
        todo = [f for f in frames if not os.path.exists(os.path.join(d, f"{f:03d}.png"))]
        if not todo:
            continue
        scene = T.reset()
        c = T.col("Shot")
        anim = make(c)
        setup(scene, a.res, a.samples)
        for f in range(n):  # on rejoue l'animation depuis le début : le scintillement reste déterministe
            anim(f / max(1, n - 1), f)
            if f in todo:
                scene.render.filepath = os.path.join(d, f"{f:03d}.png")
                bpy.ops.render.render(write_still=True)
        print("plan", name, "ok", flush=True)


if __name__ == "__main__":
    main()
