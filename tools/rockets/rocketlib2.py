"""
rocketlib2.py — kit de modélisation v2 : pièces arrondies, biseautées, « métal cartoon ».

Chaque pièce est un objet mesh nommé RXX_<Piece>[_n], qui porte deux propriétés :
  kind  : metal | paint | matte | wood | dark | glass | glow   (→ matériau Roblox)
  hex   : couleur #RRGGBB                                      (→ Color Roblox)
Axe Z vers le haut, sortie de tuyère à z = 0, 1 unité = 1 stud.
"""

import math
import random

import bpy
from mathutils import Vector, Euler

import rocketlib as L

KINDS = {
    "metal": dict(metallic=0.85, rough=0.22, coat=0.6),
    "paint": dict(metallic=0.35, rough=0.28, coat=0.9),
    "matte": dict(metallic=0.0, rough=0.7, coat=0.0),
    "wood": dict(metallic=0.0, rough=0.75, coat=0.1),
    "dark": dict(metallic=0.7, rough=0.38, coat=0.3),
    "glass": dict(metallic=0.0, rough=0.05, coat=1.0),
    "glow": dict(metallic=0.0, rough=0.4, coat=0.0),
}


def D(a):
    return math.radians(a)


class Rocket:
    def __init__(self, rid, key, collection):
        self.id = rid
        self.prefix = f"R{rid:02d}_"
        self.col = collection
        self.root = bpy.data.objects.new(f"R{rid:02d}_{key}", None)
        collection.objects.link(self.root)
        self.names = {}
        self.mats = {}

    # ------------------------------------------------------------ matériaux
    def mat(self, hexcol, kind):
        k = (hexcol, kind)
        if k in self.mats:
            return self.mats[k]
        p = KINDS[kind]
        if kind == "glow":
            m = L.make_material(f"{self.prefix}{kind}_{hexcol}", hexcol, 0.0, 0.4, hexcol, 3.5)
        elif kind == "glass":
            m = L.make_material(f"{self.prefix}{kind}_{hexcol}", hexcol, 0.0, 0.05, hexcol, 0.8, clearcoat=1.0)
        else:
            m = L.make_material(f"{self.prefix}{kind}_{hexcol}", hexcol, p["metallic"], p["rough"], clearcoat=p["coat"])
        self.mats[k] = m
        return m

    def _name(self, base):
        n = self.names.get(base, 0) + 1
        self.names[base] = n
        return f"{self.prefix}{base}" if n == 1 else f"{self.prefix}{base}_{n}"

    def _finish(self, o, hexcol, kind, loc=None, rot=None, scale=None, bevel=0.0):
        o.parent = self.root
        o["kind"] = kind
        o["hex"] = hexcol
        if loc is not None:
            o.location = loc
        if rot is not None:
            o.rotation_euler = Euler(tuple(D(a) for a in rot), "XYZ")
        if scale is not None:
            o.scale = scale if isinstance(scale, (tuple, list)) else (scale, scale, scale)
        if bevel > 0:
            m = o.modifiers.new("Bevel", "BEVEL")
            m.width = bevel
            m.segments = 3
            m.limit_method = "ANGLE"
            m.angle_limit = D(35)
            for p in o.data.polygons:
                p.use_smooth = True
        return o

    # ------------------------------------------------------------ primitives
    def lathe(self, base, prof, hexcol, kind, seg=40, loc=None, rot=None, scale=None):
        """Profil (r, z). Commencer et finir par r = 0 donne un solide fermé."""
        o = L.lathe(self._name(base), prof, self.mat(hexcol, kind), None, self.col, segments=seg)
        return self._finish(o, hexcol, kind, loc, rot, scale)

    def cyl(self, base, r, h, hexcol, kind, loc=(0, 0, 0), rot=None, r2=None, seg=32, round_=0.06):
        r2 = r if r2 is None else r2
        e = min(round_, r * 0.3, max(r2, 0.001) * 0.3, h * 0.25)
        prof = [(0, 0), (max(r - e, 0.001), 0), (r, e), (r2, h - e), (max(r2 - e, 0.001), h), (0, h)]
        return self.lathe(base, prof, hexcol, kind, seg, loc, rot)

    def cone(self, base, r, h, hexcol, kind, loc=(0, 0, 0), rot=None, seg=32):
        return self.lathe(base, [(0, 0), (r, 0), (0, h)], hexcol, kind, seg, loc, rot)

    def ball(self, base, r, hexcol, kind, loc=(0, 0, 0), scale=None, rot=None, seg=24):
        o = L.sphere(self._name(base), r, (0, 0, 0), self.mat(hexcol, kind), None, self.col, segments=seg, rings=seg // 2)
        return self._finish(o, hexcol, kind, loc, rot, scale)

    def dome(self, base, r, hexcol, kind, loc=(0, 0, 0), scale=None, rot=None, seg=28):
        o = L.sphere(self._name(base), r, (0, 0, 0), self.mat(hexcol, kind), None, self.col, segments=seg, rings=seg // 2, hemisphere=True)
        return self._finish(o, hexcol, kind, loc, rot, scale)

    def ring(self, base, R, t, hexcol, kind, loc=(0, 0, 0), rot=None, seg=48):
        o = L.torus(self._name(base), R, t, (0, 0, 0), self.mat(hexcol, kind), None, self.col, seg_major=seg, seg_minor=12)
        return self._finish(o, hexcol, kind, loc, rot)

    def box(self, base, size, hexcol, kind, loc=(0, 0, 0), rot=None, bevel=0.06):
        o = L.box(self._name(base), size, (0, 0, 0), self.mat(hexcol, kind), None, self.col)
        return self._finish(o, hexcol, kind, loc, rot, bevel=bevel)

    def fin(self, base, pts, t, hexcol, kind, angle=0.0, bevel=0.04, tilt=0.0):
        o = L.fin(self._name(base), pts, t, angle, self.mat(hexcol, kind), None, self.col, tilt_deg=tilt)
        return self._finish(o, hexcol, kind, bevel=bevel)

    def fins(self, n, pts, t, hexcol, kind, offset=0.0, base="Fin", bevel=0.04):
        for i in range(n):
            self.fin(base, pts, t, hexcol, kind, angle=offset + 360.0 * i / n, bevel=bevel)

    def tube(self, base, p1, p2, r, hexcol, kind, seg=16):
        p1, p2 = Vector(p1), Vector(p2)
        d = p2 - p1
        o = self.cyl(base, r, d.length, hexcol, kind, loc=tuple(p1), seg=seg, round_=min(0.03, r * 0.3))
        o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
        return o

    def aim(self, o, direction):
        o.rotation_euler = Vector(direction).normalized().to_track_quat("Z", "Y").to_euler()
        return o

    # ------------------------------------------------------------ pièces composées
    def nozzle(self, r, h, hexcol="#3A3D46", loc=(0, 0, 0), base="Nozzle"):
        prof = [(0, h * 0.25), (r * 0.6, h * 0.2), (r, 0), (r * 1.04, 0.05), (r * 0.62, h * 0.7), (r * 0.7, h), (0, h)]
        return self.lathe(base, prof, hexcol, "dark", 32, loc)

    def porthole(self, z, body_r, r, glass="#7FE3FF", frame="#C9CED6", ang=-70, base="Window", frame_kind="metal"):
        a = D(ang)
        out = Vector((math.cos(a), math.sin(a), 0))
        p = Vector((0, 0, z)) + out * (body_r * 0.97)
        fr = self.ring(base + "Frame", r * 1.05, r * 0.22, frame, frame_kind, loc=tuple(p), seg=32)
        self.aim(fr, out)
        gl = self.ball(base, r, glass, "glass", loc=tuple(p), scale=(1, 1, 0.45))
        self.aim(gl, out)
        return gl

    def band(self, z, r, h, hexcol, kind="paint", base="Band", seg=40):
        return self.lathe(base, [(0, z), (r, z), (r * 1.0, z + h), (0, z + h)], hexcol, kind, seg)

    def fin_pts(self, shape, r, z0, s):
        u = r * 0.85
        P = {
            "tri": [(u, z0), (u + 1.3 * s, z0 - 0.2 * s), (u, z0 + 2.0 * s)],
            "swept": [(u, z0), (u + 1.5 * s, z0 - 0.5 * s), (u + 1.2 * s, z0 + 0.2 * s), (u, z0 + 2.2 * s)],
            "round": [(u, z0)] + [(u + 1.2 * s * math.sin(t * math.pi / 8), z0 + 1.8 * s * (1 - math.cos(t * math.pi / 8)) / 2 + 0.0) for t in range(1, 8)] + [(u, z0 + 1.8 * s)],
            "retro": [(u, z0 + 0.6 * s), (u + 1.0 * s, z0 - 0.9 * s), (u + 1.25 * s, z0 - 1.2 * s), (u + 0.9 * s, z0 + 0.6 * s), (u, z0 + 2.6 * s)],
            "delta": [(u, z0), (u + 1.9 * s, z0), (u + 1.3 * s, z0 + 0.5 * s), (u, z0 + 3.0 * s)],
            "stub": [(u, z0), (u + 0.8 * s, z0), (u + 0.6 * s, z0 + 0.9 * s), (u, z0 + 1.2 * s)],
            "blade": [(u, z0), (u + 0.6 * s, z0 - 0.4 * s), (u + 1.5 * s, z0 + 0.5 * s), (u + 0.5 * s, z0 + 1.9 * s), (u, z0 + 2.7 * s)],
            "wing": [(u, z0), (u + 2.8 * s, z0 - 0.2 * s), (u + 2.4 * s, z0 + 0.5 * s), (u, z0 + 2.4 * s)],
            "feather": [(u, z0), (u + 2.4 * s, z0 + 1.4 * s), (u + 2.6 * s, z0 + 2.0 * s), (u + 0.4 * s, z0 + 1.4 * s), (u, z0 + 1.6 * s)],
            "grid": [(u, z0), (u + 0.9 * s, z0), (u + 0.9 * s, z0 + 0.7 * s), (u, z0 + 0.7 * s)],
        }
        return P[shape]


def wobble(o, amount, seed, freq=3.0):
    """Déformation organique (roche, écailles) des sommets d'un objet."""
    rnd = random.Random(seed)
    ph = [rnd.uniform(0, 6.28) for _ in range(3)]
    for v in o.data.vertices:
        r = math.hypot(v.co.x, v.co.y)
        if r < 1e-4:
            continue
        a = math.atan2(v.co.y, v.co.x)
        k = 1 + amount * (math.sin(a * freq + ph[0]) * 0.5 + math.sin(v.co.z * freq * 1.3 + ph[1]) * 0.35 + math.sin((a + v.co.z) * freq * 2.1 + ph[2]) * 0.15)
        v.co.x *= k
        v.co.y *= k
