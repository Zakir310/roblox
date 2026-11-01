"""
rocketlib.py — bibliothèque de modélisation procédurale de fusées pour Blender (bpy).

Conventions :
  - Axe Z vers le haut, base de la fusée (sortie de tuyère) à z = 0.
  - 1 unité Blender = 1 stud Roblox.
  - Chaque pièce est un objet mesh séparé, nommé "RXX_<Piece>", avec son propre
    matériau. Roblox importe chaque objet comme un MeshPart distinct, ce qui
    permet de recolorer chaque pièce et de mettre les parties lumineuses en Neon.

Pièces générées : Body, Nose, Fin_i, Nozzle_i, Booster_i, BoosterNose_i, Window_i,
Band_i, Ring_i, Halo_i, Panel_i, Arm_i, Antenna, Dish, Saucer, Dome, Leg_i,
Flame_i, Spike_i, Collar, Cockpit.
"""

import math
import bpy
from mathutils import Vector, Matrix

# --------------------------------------------------------------------------
# Matériaux
# --------------------------------------------------------------------------

_material_cache = {}


def srgb(hexstr):
    """'#RRGGBB' -> (r, g, b) linéaire (Blender travaille en linéaire)."""
    hexstr = hexstr.lstrip("#")
    r, g, b = (int(hexstr[i : i + 2], 16) / 255.0 for i in (0, 2, 4))

    def to_lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return (to_lin(r), to_lin(g), to_lin(b))


def make_material(name, color_hex, metallic=0.0, roughness=0.5,
                  emission_hex=None, emission_strength=0.0, alpha=1.0,
                  clearcoat=0.0):
    """Crée (ou réutilise) un matériau Principled BSDF."""
    key = (name, color_hex, metallic, roughness, emission_hex, emission_strength, alpha, clearcoat)
    if key in _material_cache:
        return _material_cache[key]

    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    r, g, b = srgb(color_hex)
    bsdf.inputs["Base Color"].default_value = (r, g, b, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = clearcoat
    if emission_hex and emission_strength > 0:
        er, eg, eb = srgb(emission_hex)
        bsdf.inputs["Emission Color"].default_value = (er, eg, eb, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        mat.blend_method = "BLEND"
    # Couleur de la vue solide / export OBJ (.mtl Kd) : la couleur diffuse
    mat.diffuse_color = (r, g, b, 1.0)
    mat.metallic = metallic
    mat.roughness = roughness
    _material_cache[key] = mat
    return mat


# --------------------------------------------------------------------------
# Création de meshes
# --------------------------------------------------------------------------

def _new_object(name, verts, faces, material, parent, collection, smooth=True):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    if smooth:
        for p in mesh.polygons:
            p.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    if material is not None:
        obj.data.materials.append(material)
    if parent is not None:
        obj.parent = parent
    if smooth:
        # Lissage par angle (arêtes vives conservées) : modificateur natif 4.1+
        try:
            mod = obj.modifiers.new("Smooth", "NODES")
            obj.modifiers.remove(mod)
        except Exception:
            pass
        _smooth_by_angle(obj)
    return obj


def _smooth_by_angle(obj, angle_deg=40.0):
    """Marque les arêtes dont l'angle dépasse angle_deg comme vives."""
    mesh = obj.data
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.edges.ensure_lookup_table()
    thr = math.radians(angle_deg)
    for e in bm.edges:
        if len(e.link_faces) == 2:
            a = e.calc_face_angle(0.0)
            e.smooth = a <= thr
        else:
            e.smooth = False
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()


def lathe(name, profile, material, parent, collection, segments=32, close_bottom=True, close_top=True):
    """
    Surface de révolution autour de Z.
    profile : liste de (rayon, z) du bas vers le haut. Un rayon 0 crée une pointe.
    """
    verts = []
    faces = []
    rings = []
    for (r, z) in profile:
        if r <= 1e-6:
            idx = len(verts)
            verts.append((0.0, 0.0, z))
            rings.append(("pole", idx))
        else:
            start = len(verts)
            for i in range(segments):
                a = 2 * math.pi * i / segments
                verts.append((r * math.cos(a), r * math.sin(a), z))
            rings.append(("ring", start))

    for k in range(len(rings) - 1):
        ta, ia = rings[k]
        tb, ib = rings[k + 1]
        if ta == "ring" and tb == "ring":
            for i in range(segments):
                j = (i + 1) % segments
                faces.append((ia + i, ia + j, ib + j, ib + i))
        elif ta == "ring" and tb == "pole":
            for i in range(segments):
                j = (i + 1) % segments
                faces.append((ia + i, ia + j, ib))
        elif ta == "pole" and tb == "ring":
            for i in range(segments):
                j = (i + 1) % segments
                faces.append((ia, ib + j, ib + i))

    # Bouchons plats
    t0, i0 = rings[0]
    if close_bottom and t0 == "ring":
        faces.append(tuple(reversed(range(i0, i0 + segments))))
    tn, i_n = rings[-1]
    if close_top and tn == "ring":
        faces.append(tuple(range(i_n, i_n + segments)))

    return _new_object(name, verts, faces, material, parent, collection)


def fin(name, points, thickness, angle_deg, material, parent, collection, tilt_deg=0.0):
    """
    Aileron plan extrudé.
    points : polygone 2D (u, z) dans le plan contenant l'axe, u = distance radiale.
    Placé à l'angle angle_deg autour de Z.
    """
    n = len(points)
    h = thickness / 2.0
    verts = [(u, -h, z) for (u, z) in points] + [(u, h, z) for (u, z) in points]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    obj = _new_object(name, verts, faces, material, parent, collection, smooth=False)
    obj.rotation_euler = (0.0, math.radians(tilt_deg), math.radians(angle_deg))
    return obj


def box(name, size, location, material, parent, collection, rotation=(0, 0, 0)):
    sx, sy, sz = (s / 2.0 for s in size)
    verts = [(-sx, -sy, -sz), (sx, -sy, -sz), (sx, sy, -sz), (-sx, sy, -sz),
             (-sx, -sy, sz), (sx, -sy, sz), (sx, sy, sz), (-sx, sy, sz)]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    obj = _new_object(name, verts, faces, material, parent, collection, smooth=False)
    obj.location = location
    obj.rotation_euler = tuple(math.radians(a) for a in rotation)
    return obj


def torus(name, major, minor, location, material, parent, collection, seg_major=40, seg_minor=12, rotation=(0, 0, 0)):
    verts = []
    faces = []
    for i in range(seg_major):
        a = 2 * math.pi * i / seg_major
        ca, sa = math.cos(a), math.sin(a)
        for j in range(seg_minor):
            b = 2 * math.pi * j / seg_minor
            r = major + minor * math.cos(b)
            verts.append((r * ca, r * sa, minor * math.sin(b)))
    for i in range(seg_major):
        i2 = (i + 1) % seg_major
        for j in range(seg_minor):
            j2 = (j + 1) % seg_minor
            faces.append((i * seg_minor + j, i2 * seg_minor + j, i2 * seg_minor + j2, i * seg_minor + j2))
    obj = _new_object(name, verts, faces, material, parent, collection)
    obj.location = location
    obj.rotation_euler = tuple(math.radians(a) for a in rotation)
    return obj


def sphere(name, radius, location, material, parent, collection, scale=(1, 1, 1), segments=24, rings=12, hemisphere=False):
    profile = []
    start = 0.0 if hemisphere else -math.pi / 2
    n = rings
    for k in range(n + 1):
        t = start + (math.pi / 2 - start) * k / n
        profile.append((radius * math.cos(t) * (1.0 if abs(math.cos(t)) > 1e-6 else 0.0), radius * math.sin(t)))
    profile[-1] = (0.0, radius)
    if not hemisphere:
        profile[0] = (0.0, -radius)
    obj = lathe(name, profile, material, parent, collection, segments=segments, close_bottom=hemisphere)
    obj.location = location
    obj.scale = scale
    return obj


def cylinder(name, radius, height, location, material, parent, collection, rotation=(0, 0, 0), segments=16, r_top=None):
    rt = radius if r_top is None else r_top
    obj = lathe(name, [(radius, 0.0), (rt, height)], material, parent, collection, segments=segments)
    obj.location = location
    obj.rotation_euler = tuple(math.radians(a) for a in rotation)
    return obj


# --------------------------------------------------------------------------
# Profils de corps et de nez
# --------------------------------------------------------------------------

def body_profile(kind, h, r, r2=None):
    """Retourne le profil (rayon, z) du corps, de z=0 à z=h, sans fermeture pointue."""
    r2 = r if r2 is None else r2
    if kind == "cyl":
        return [(r, 0.0), (r, h)]
    if kind == "taper":  # plus large en bas
        return [(r, 0.0), (r2, h)]
    if kind == "capsule":  # ventru
        pts = []
        n = 10
        for k in range(n + 1):
            t = k / n
            bulge = 1.0 + 0.35 * math.sin(math.pi * t)
            pts.append((r * bulge, h * t))
        return pts
    if kind == "barrel":  # tonneau très rond
        pts = []
        n = 10
        for k in range(n + 1):
            t = k / n
            pts.append((r * (0.55 + 0.45 * math.sin(math.pi * t) ** 0.6), h * t))
        return pts
    if kind == "bullet":  # large en bas, se resserre progressivement
        pts = []
        n = 8
        for k in range(n + 1):
            t = k / n
            pts.append((r * (1.0 - 0.35 * t ** 2), h * t))
        return pts
    if kind == "stage2":  # deux étages
        return [(r, 0.0), (r, h * 0.55), (r2, h * 0.62), (r2, h)]
    if kind == "stage3":
        return [(r, 0.0), (r, h * 0.4), (r * 0.8, h * 0.46), (r * 0.8, h * 0.72), (r2, h * 0.78), (r2, h)]
    if kind == "waist":  # taille fine au milieu (style ovni/expérimental)
        return [(r, 0.0), (r * 0.7, h * 0.5), (r2, h)]
    if kind == "crystal":  # facettes : fait avec peu de segments par l'appelant
        return [(r * 0.6, 0.0), (r, h * 0.35), (r2, h)]
    raise ValueError(kind)


def nose_profile(kind, h, r, base_z):
    """Profil du nez, de base_z (rayon r) jusqu'à base_z+h (pointe)."""
    pts = []
    if kind == "cone":
        return [(r, base_z), (0.0, base_z + h)]
    if kind == "ogive":
        n = 10
        for k in range(n + 1):
            t = k / n
            pts.append((r * math.sqrt(max(0.0, 1 - t ** 2)) if k < n else 0.0, base_z + h * t))
        return pts
    if kind == "dome":
        n = 8
        for k in range(n + 1):
            t = k / n
            pts.append((r * math.cos(t * math.pi / 2) if k < n else 0.0, base_z + h * math.sin(t * math.pi / 2)))
        return pts
    if kind == "spike":
        return [(r, base_z), (r * 0.35, base_z + h * 0.35), (0.0, base_z + h)]
    if kind == "blunt":  # cône tronqué + petit dôme
        return [(r, base_z), (r * 0.4, base_z + h * 0.8), (0.0, base_z + h)]
    if kind == "crystal":
        return [(r, base_z), (r * 0.5, base_z + h * 0.5), (0.0, base_z + h)]
    raise ValueError(kind)


# --------------------------------------------------------------------------
# Ailerons
# --------------------------------------------------------------------------

def fin_shape(kind, size, root_z, r_body):
    """Polygone (u, z) pour un aileron de taille size attaché au corps."""
    s = size
    u0 = r_body * 0.85  # pénètre légèrement dans le corps
    if kind == "tri":
        return [(u0, root_z), (u0 + 1.3 * s, root_z), (u0, root_z + 2.0 * s)]
    if kind == "swept":
        return [(u0, root_z - 0.2 * s), (u0 + 1.5 * s, root_z - 0.2 * s), (u0 + 0.9 * s, root_z + 0.9 * s), (u0, root_z + 2.4 * s)]
    if kind == "delta":
        return [(u0, root_z), (u0 + 1.8 * s, root_z), (u0 + 1.2 * s, root_z + 0.5 * s), (u0, root_z + 3.0 * s)]
    if kind == "blade":
        return [(u0, root_z), (u0 + 0.6 * s, root_z - 0.3 * s), (u0 + 1.4 * s, root_z + 0.4 * s), (u0 + 0.5 * s, root_z + 1.8 * s), (u0, root_z + 2.6 * s)]
    if kind == "wing":  # grande aile style chasseur
        return [(u0, root_z), (u0 + 2.6 * s, root_z - 0.1 * s), (u0 + 2.2 * s, root_z + 0.5 * s), (u0, root_z + 2.2 * s)]
    if kind == "stub":  # petit aileron trapu
        return [(u0, root_z), (u0 + 0.8 * s, root_z), (u0 + 0.6 * s, root_z + 0.9 * s), (u0, root_z + 1.2 * s)]
    if kind == "crystal":
        return [(u0, root_z - 0.3 * s), (u0 + 1.0 * s, root_z + 0.1 * s), (u0 + 0.5 * s, root_z + 1.2 * s), (u0 + 0.1 * s, root_z + 3.0 * s)]
    raise ValueError(kind)


# --------------------------------------------------------------------------
# Construction d'une fusée complète
# --------------------------------------------------------------------------

DEFAULT_COLORS = {
    "body": "#F2F2F2", "accent": "#FF6A00", "nose": "#FF6A00", "fins": "#FF6A00",
    "window": "#5EC8FF", "nozzle": "#3A3A3A", "glow": "#00E5FF", "metal": "#9AA0A8",
    "panel": "#1E3A8A", "flame": "#FFB300",
}


def build_rocket(spec, collection):
    """
    Construit une fusée à partir d'une spec (dict) et renvoie l'Empty racine.
    Voir specs.py pour le format.
    """
    rid = spec["id"]
    prefix = f"R{rid:02d}_"
    col = {**DEFAULT_COLORS, **spec.get("colors", {})}
    aura = spec.get("aura", {"color": col["glow"], "strength": 1.0})
    glow_strength = 2.0 + 2.2 * aura.get("strength", 1.0)
    finish = spec.get("finish", "paint")  # paint | metal | chrome | wood | crystal | matte

    def mat(part_key, color_key=None, emissive=False, strength=None, alpha=1.0):
        color = col[color_key or part_key]
        if finish == "metal":
            metallic, rough = 0.85, 0.35
        elif finish == "chrome":
            metallic, rough = 1.0, 0.12
        elif finish == "wood":
            metallic, rough = 0.0, 0.8
        elif finish == "crystal":
            metallic, rough = 0.3, 0.15
        elif finish == "matte":
            metallic, rough = 0.0, 0.7
        else:
            metallic, rough = 0.15, 0.4
        if part_key in ("nozzle", "metal"):
            metallic, rough = 0.9, 0.4
        if emissive:
            return make_material(f"{prefix}{part_key}_glow", color, 0.0, 0.3, color, strength or glow_strength, alpha)
        return make_material(f"{prefix}{part_key}", color, metallic, rough, alpha=alpha,
                             clearcoat=0.6 if finish in ("paint", "crystal") else 0.0)

    root = bpy.data.objects.new(f"R{rid:02d}_{spec['key']}", None)
    root.empty_display_type = "PLAIN_AXES"
    collection.objects.link(root)

    seg = spec.get("segments", 32)

    # ---- Corps ----------------------------------------------------------
    b = spec["body"]
    bkind, bh, br = b["kind"], b["h"], b["r"]
    br2 = b.get("r2", br)
    nozzle_h = spec.get("nozzle_h", 0.8)
    body_z0 = nozzle_h
    prof = [(r, z + body_z0) for (r, z) in body_profile(bkind, bh, br, br2)]
    body_top_r = prof[-1][0]
    body_top_z = prof[-1][1]
    lathe(prefix + "Body", prof, mat("body"), root, collection, segments=seg)

    # ---- Nez ------------------------------------------------------------
    n = spec.get("nose", {"kind": "cone", "h": 2.0})
    nprof = nose_profile(n["kind"], n["h"], body_top_r, body_top_z)
    lathe(prefix + "Nose", nprof, mat("nose"), root, collection, segments=seg, close_bottom=True)
    top_z = body_top_z + n["h"]

    # ---- Collier entre corps et nez (optionnel) -------------------------
    if spec.get("collar"):
        lathe(prefix + "Collar", [(body_top_r * 1.08, body_top_z - 0.15), (body_top_r * 1.08, body_top_z + 0.15)],
              mat("accent"), root, collection, segments=seg)

    # ---- Bandes colorées ------------------------------------------------
    for i, band in enumerate(spec.get("bands", [])):
        zf, bh_ = band["z"], band.get("h", 0.3)
        # rayon local du corps à cette hauteur (interpolation sur le profil)
        rr = _radius_at(prof, body_z0 + zf * bh) * 1.03
        lathe(prefix + f"Band_{i+1}", [(rr, body_z0 + zf * bh - bh_ / 2), (rr, body_z0 + zf * bh + bh_ / 2)],
              mat("accent", band.get("color", "accent"), emissive=band.get("glow", False)), root, collection, segments=seg)

    # ---- Hublots --------------------------------------------------------
    w = spec.get("window")
    if w:
        count = w.get("n", 1)
        wr = w.get("r", 0.35)
        for i in range(count):
            zf = w.get("z", 0.6) - i * w.get("gap", 0.18)
            z = body_z0 + zf * bh
            rr = _radius_at(prof, z)
            ang = math.radians(w.get("angle", -90))
            # cadre + vitre : deux disques fins légèrement sortis du corps
            frame = lathe(prefix + f"WindowFrame_{i+1}", [(wr * 1.25, 0.0), (wr * 1.25, 0.12)], mat("accent", w.get("frame", "accent")), root, collection, segments=20)
            glass = lathe(prefix + f"Window_{i+1}", [(wr, 0.0), (wr, 0.16)], mat("window", emissive=True, strength=2.0), root, collection, segments=20)
            for o in (frame, glass):
                o.location = (rr * 0.95 * math.cos(ang), rr * 0.95 * math.sin(ang), z)
                o.rotation_euler = (math.radians(90), 0.0, ang + math.radians(90))

    # ---- Cockpit (verrière allongée le long de l'axe) --------------------
    if spec.get("cockpit"):
        c = spec["cockpit"]
        z = body_z0 + c.get("z", 0.75) * bh
        rr = _radius_at(prof, z)
        sphere(prefix + "Cockpit", c.get("r", 0.45), (0.0, -rr * 0.82, z), mat("window", emissive=True, strength=2.0), root, collection,
               scale=(0.9, 0.55, c.get("len", 2.0)))

    # ---- Ailerons -------------------------------------------------------
    f = spec.get("fins")
    if f:
        nf = f.get("n", 3)
        for i in range(nf):
            ang = 360.0 * i / nf + f.get("offset", 90)
            pts = fin_shape(f.get("kind", "tri"), f.get("size", 1.0), body_z0 + f.get("z", 0.0) * bh, _radius_at(prof, body_z0 + f.get("z", 0.0) * bh + 0.1))
            fin(prefix + f"Fin_{i+1}", pts, f.get("t", 0.12), ang, mat("fins"), root, collection)
            if f.get("tip_glow"):
                # petit bord lumineux le long de l'arête extérieure
                tip = [(u, z) for (u, z) in pts]
                umax = max(u for u, _ in tip)
                edge = [(p[0], p[1]) for p in tip if p[0] > umax * 0.55]
                if len(edge) >= 2:
                    fin(prefix + f"FinGlow_{i+1}", edge + [(edge[-1][0] - 0.15, edge[-1][1]), (edge[0][0] - 0.15, edge[0][1])], f.get("t", 0.12) * 1.3, ang,
                        mat("glow", emissive=True), root, collection)

    # ---- Tuyères --------------------------------------------------------
    nz = spec.get("nozzles", 1)
    nr = spec.get("nozzle_r", br * 0.45)
    positions = [(0.0, 0.0)] if nz == 1 else [((br * 0.5) * math.cos(2 * math.pi * k / nz + math.pi / 2), (br * 0.5) * math.sin(2 * math.pi * k / nz + math.pi / 2)) for k in range(nz)]
    if nz > 1:
        nr = min(nr, br * 0.3)
    for i, (x, y) in enumerate(positions):
        noz = lathe(prefix + f"Nozzle_{i+1}", [(nr * 1.1, 0.0), (nr * 0.6, nozzle_h * 0.6), (nr * 0.7, nozzle_h + 0.05)], mat("nozzle"), root, collection, segments=seg)
        noz.location = (x, y, 0.0)
        if spec.get("flame", True):
            fl = lathe(prefix + f"Flame_{i+1}", [(0.0, -0.9 - 0.5 * aura.get("strength", 1.0)), (nr * 0.9, -0.05), (nr * 0.75, 0.15)],
                       make_material(prefix + "flame", col["flame"], 0.0, 0.5, col["flame"], glow_strength * 1.2), root, collection, segments=16)
            fl.location = (x, y, 0.0)

    # ---- Boosters latéraux ----------------------------------------------
    bo = spec.get("boosters")
    if bo:
        nb = bo.get("n", 2)
        brad, bhgt = bo.get("r", br * 0.4), bo.get("h", bh * 0.6)
        for i in range(nb):
            ang = 2 * math.pi * i / nb + math.radians(bo.get("offset", 0))
            x, y = (br + brad * 0.95) * math.cos(ang), (br + brad * 0.95) * math.sin(ang)
            bz = bo.get("z", 0.0) + nozzle_h * 0.5
            bb = lathe(prefix + f"Booster_{i+1}", [(brad, 0.0), (brad, bhgt)], mat("accent", bo.get("color", "accent")), root, collection, segments=seg // 2)
            bb.location = (x, y, bz)
            bn = lathe(prefix + f"BoosterNose_{i+1}", nose_profile(bo.get("nose", "ogive"), brad * 1.6, brad, bhgt), mat("nose", bo.get("nose_color", "nose")), root, collection, segments=seg // 2)
            bn.location = (x, y, bz)
            bnz = lathe(prefix + f"BoosterNozzle_{i+1}", [(brad * 0.8, -0.35), (brad * 0.5, 0.0)], mat("nozzle"), root, collection, segments=seg // 2)
            bnz.location = (x, y, bz)
            if spec.get("flame", True):
                fl = lathe(prefix + f"BoosterFlame_{i+1}", [(0.0, -1.1), (brad * 0.7, -0.3), (brad * 0.6, -0.2)],
                           make_material(prefix + "flame", col["flame"], 0.0, 0.5, col["flame"], glow_strength * 1.2), root, collection, segments=12)
                fl.location = (x, y, bz)

    # ---- Anneaux physiques ---------------------------------------------
    for i, rg in enumerate(spec.get("rings", [])):
        z = body_z0 + rg["z"] * bh
        rr = _radius_at(prof, z)
        torus(prefix + f"Ring_{i+1}", rr * rg.get("scale", 1.15), rg.get("thick", 0.12), (0, 0, z),
              mat("accent", rg.get("color", "metal"), emissive=rg.get("glow", False)), root, collection)

    # ---- Halos lumineux (anneaux flottants) ------------------------------
    for i, hl in enumerate(spec.get("halos", [])):
        z = body_z0 + hl["z"] * bh
        R = hl.get("R", br * 2.2)
        tor = torus(prefix + f"Halo_{i+1}", R, hl.get("thick", 0.1), (0, 0, z), mat("glow", hl.get("color", "glow"), emissive=True, strength=glow_strength * 0.8),
                    root, collection, rotation=(hl.get("tilt", 0), 0, 0))

    # ---- Panneaux solaires ---------------------------------------------
    if spec.get("panels"):
        p = spec["panels"]
        z = body_z0 + p.get("z", 0.5) * bh
        rr = _radius_at(prof, z)
        L, W = p.get("len", 2.4), p.get("w", 1.0)
        for i, sgn in enumerate((1, -1)):
            cylinder(prefix + f"Arm_{i+1}", 0.08, rr + 0.4, (0, 0, z), mat("metal"), root, collection, rotation=(0, 90 * sgn, 0), segments=8)
            box(prefix + f"Panel_{i+1}", (L, 0.08, W), (sgn * (rr + 0.4 + L / 2), 0, z), mat("panel"), root, collection)
            box(prefix + f"PanelFrame_{i+1}", (L + 0.1, 0.05, W + 0.1), (sgn * (rr + 0.4 + L / 2), 0, z), mat("metal"), root, collection)

    # ---- Antenne / parabole ----------------------------------------------
    if spec.get("antenna"):
        a = spec["antenna"]
        base_z = top_z - 0.05
        cylinder(prefix + "Antenna", 0.05, a.get("h", 1.2), (0, 0, base_z), mat("metal"), root, collection, segments=8)
        sphere(prefix + "AntennaTip", 0.12, (0, 0, base_z + a.get("h", 1.2)), mat("glow", emissive=True), root, collection, segments=12, rings=6)
    if spec.get("dish"):
        d = spec["dish"]
        z = body_z0 + d.get("z", 1.0) * bh + d.get("dz", 0.0)
        R = d.get("R", br * 1.4)
        prof_d = [(0.0, 0.0)] + [(R * k / 6, 0.35 * (k / 6) ** 2) for k in range(1, 7)]
        dsh = lathe(prefix + "Dish", prof_d, mat("metal", d.get("color", "metal")), root, collection, segments=seg, close_bottom=False, close_top=False)
        dsh.location = (0, 0, z)
        dsh.rotation_euler = (math.radians(d.get("tilt", 0)), 0, 0)
        cylinder(prefix + "DishMast", 0.05, 0.45, (0, 0, z), mat("metal"), root, collection, segments=8)
        sphere(prefix + "DishTip", 0.1, (0, 0, z + 0.45), mat("glow", emissive=True), root, collection, segments=12, rings=6)

    # ---- Soucoupe ---------------------------------------------------------
    if spec.get("saucer"):
        s = spec["saucer"]
        z = body_z0 + s.get("z", 0.3) * bh
        R = s.get("R", br * 2.4)
        thick = s.get("thick", 0.35)
        prof_s = [(br * 0.9, z - thick), (R * 0.75, z - thick * 0.6), (R, z), (R * 0.75, z + thick * 0.6), (br * 0.9, z + thick)]
        lathe(prefix + "Saucer", prof_s, mat("accent", s.get("color", "accent")), root, collection, segments=seg)
        torus(prefix + "SaucerGlow", R * 0.98, 0.06, (0, 0, z), mat("glow", emissive=True), root, collection)
        if s.get("lights", 0):
            for i in range(s["lights"]):
                ang = 2 * math.pi * i / s["lights"]
                sphere(prefix + f"SaucerLight_{i+1}", 0.1, (R * 0.85 * math.cos(ang), R * 0.85 * math.sin(ang), z - thick * 0.5), mat("glow", emissive=True), root, collection, segments=10, rings=5)

    # ---- Pattes d'atterrissage -------------------------------------------
    if spec.get("legs"):
        lg = spec["legs"]
        nl = lg.get("n", 3)
        for i in range(nl):
            ang = 2 * math.pi * i / nl + math.radians(lg.get("offset", 30))
            L = lg.get("len", 2.0)
            x, y = br * 0.9 * math.cos(ang), br * 0.9 * math.sin(ang)
            leg = cylinder(prefix + f"Leg_{i+1}", 0.08, L, (x, y, nozzle_h + 0.3), mat("metal"), root, collection, segments=8)
            # orientée vers l'extérieur et vers le bas
            leg.rotation_euler = (0, 0, 0)
            direction = Vector((math.cos(ang), math.sin(ang), -1.4)).normalized()
            leg.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
            foot = sphere(prefix + f"Foot_{i+1}", 0.18, (x + direction.x * L, y + direction.y * L, nozzle_h + 0.3 + direction.z * L), mat("nozzle"), root, collection, segments=12, rings=6, scale=(1, 1, 0.5))

    # ---- Pointes latérales (fusées cristal / légendaires) ---------------
    if spec.get("spikes"):
        sp = spec["spikes"]
        ns = sp.get("n", 4)
        for i in range(ns):
            ang = 2 * math.pi * i / ns + math.radians(sp.get("offset", 45))
            z = body_z0 + sp.get("z", 0.5) * bh
            rr = _radius_at(prof, z)
            spk = lathe(prefix + f"Spike_{i+1}", [(sp.get("r", 0.2), 0.0), (0.0, sp.get("len", 1.4))], mat("glow", sp.get("color", "glow"), emissive=sp.get("glow", True)), root, collection, segments=8)
            spk.location = (rr * 0.9 * math.cos(ang), rr * 0.9 * math.sin(ang), z)
            direction = Vector((math.cos(ang), math.sin(ang), sp.get("up", 0.6))).normalized()
            spk.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()

    # ---- Dôme supérieur (ovni) ------------------------------------------
    if spec.get("dome"):
        d = spec["dome"]
        sphere(prefix + "Dome", d.get("r", br * 0.9), (0, 0, body_z0 + d.get("z", 1.0) * bh), mat("window", emissive=True, strength=1.5), root, collection, hemisphere=True)

    root["rocket_id"] = rid
    root["rocket_height"] = top_z
    return root


def _radius_at(prof, z):
    """Interpole le rayon du profil à la hauteur z."""
    if z <= prof[0][1]:
        return prof[0][0]
    for (r1, z1), (r2, z2) in zip(prof, prof[1:]):
        if z1 <= z <= z2:
            t = 0.0 if z2 == z1 else (z - z1) / (z2 - z1)
            return r1 + (r2 - r1) * t
    return prof[-1][0]


def rocket_objects(root):
    """Tous les objets mesh descendant de root."""
    out = []
    for o in bpy.data.objects:
        if o.type == "MESH":
            p = o.parent
            while p is not None:
                if p == root:
                    out.append(o)
                    break
                p = p.parent
    return out
