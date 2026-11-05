"""
render_thumbs.py — rendus GFX (Blender/Cycles) pour les miniatures du jeu, à partir des vraies fusées.

    python render_thumbs.py --out DIR [--scene launch|before|after|hero] [--res 1920x1080] [--samples 96]

Scènes :
  launch : fusée 40 qui décolle en diagonale, gros panache de feu cartoon, nuages, ciel bleu (Action Freeze)
  before : fusée 01 (bois) sur l'herbe, lumière plate de jour (moitié « avant »)
  after  : fusée 40 dans l'espace, auras et halos (moitié « après »)
  hero   : fusée 37 (couronne solaire) géante au-dessus d'une planète, espace violet (Object as Hero)
"""

import argparse
import math
import os
import random
import sys

import bpy
from mathutils import Vector, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rocketlib  # noqa: E402
from specs import SPECS  # noqa: E402

SPEC = {s["id"]: s for s in SPECS}


# ---------------------------------------------------------------- utilitaires

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    rocketlib._material_cache.clear()
    return bpy.context.scene


def col(name):
    c = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(c)
    return c


def emissive(name, hexcol, strength):
    return rocketlib.make_material(name, hexcol, 0.0, 0.5, hexcol, strength)


def flat(name, hexcol, rough=0.6, emit=0.0):
    return rocketlib.make_material(name, hexcol, 0.0, rough, hexcol if emit else None, emit)


def blob(name, radius, loc, mat, c, squash=(1, 1, 1)):
    return rocketlib.sphere(name, radius, loc, mat, None, c, scale=squash, segments=20, rings=10)


def build(rid, c, hide_flames=True):
    root = rocketlib.build_rocket(SPEC[rid], c)
    if hide_flames:
        for o in list(bpy.data.objects):
            if o.type == "MESH" and "Flame" in o.name and o.name.startswith(f"R{rid:02d}_"):
                bpy.data.objects.remove(o, do_unlink=True)
    return root


def place(root, loc, tilt_deg=0.0, yaw_deg=0.0, scale=1.0):
    """Incline la fusée (axe +Z local) de tilt_deg vers +X, puis tourne autour de Z."""
    root.scale = (scale, scale, scale)
    root.rotation_euler = Euler((0.0, math.radians(tilt_deg), math.radians(yaw_deg)), "XYZ")
    root.location = loc
    bpy.context.view_layer.update()
    axis = (root.matrix_world.to_3x3() @ Vector((0, 0, 1))).normalized()
    base = root.matrix_world @ Vector((0, 0, 0))
    return base, axis


def fire_mat(name, hexcol, strength, alpha):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    r, g, b = rocketlib.srgb(hexcol)
    em.inputs["Color"].default_value = (r, g, b, 1)
    em.inputs["Strength"].default_value = strength
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    mix.inputs["Fac"].default_value = alpha
    nt.links.new(tr.outputs[0], mix.inputs[1])
    nt.links.new(em.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs["Surface"])
    return m


def flame_shape(name, base, d, length, radius, mat, c, wobble, seed):
    """Goutte de feu cartoon : renflement près de la tuyère, pointe ondulée."""
    rnd = random.Random(seed)
    prof = []
    n = 14
    for k in range(n + 1):
        t = k / n
        r = radius * (0.55 + 1.6 * t) * (1 - t) ** 1.15 * (1.0 if t < 0.05 else 1.0)
        prof.append((max(r, 0.0) if k < n else 0.0, length * t))
    o = rocketlib.lathe(name, prof, mat, None, c, segments=28)
    # ondulation cartoon : déformation des sommets
    me = o.data
    for v in me.vertices:
        t = v.co.z / length
        ang = math.atan2(v.co.y, v.co.x)
        k = 1.0 + wobble * t * math.sin(ang * 5 + t * 9 + seed)
        v.co.x *= k
        v.co.y *= k
    o.location = base
    o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    return o


def cartoon_plume(c, base, axis, length, radius, seed=1, palette=None):
    """Panache cartoon : gouttes emboîtées (rouge translucide dehors, cœur blanc), étincelles, fumée en boules."""
    rnd = random.Random(seed)
    pal = palette or ["#FFFFF0", "#FFE45C", "#FF9A1F", "#FF4A1F"]
    d = -axis
    layers = [  # (couleur, force, alpha, longueur, rayon, ondulation)
        (pal[3], 2.4, 0.8, 1.00, 1.35, 0.22),
        (pal[2], 2.6, 0.75, 0.80, 1.10, 0.18),
        (pal[1], 3.0, 0.9, 0.58, 0.85, 0.12),
        (pal[0], 4.0, 1.0, 0.34, 0.60, 0.06),
    ]
    for i, (hx, st, al, lm, rm, wb) in enumerate(layers):
        flame_shape(f"Flame{i}", base - d * 0.1, d, length * lm, radius * rm, fire_mat(f"FireM{i}", hx, st, al), c, wb, seed + i)
    side = d.cross(Vector((0, 1, 0)))
    if side.length < 1e-3:
        side = Vector((1, 0, 0))
    side.normalize()
    up = d.cross(side).normalized()
    # étincelles
    sp = fire_mat("Spark", pal[1], 4.0, 1.0)
    for k in range(18):
        t = rnd.uniform(0.2, 1.1)
        p = base + d * (length * t) + side * rnd.uniform(-1.6, 1.6) * radius * t + up * rnd.uniform(-1, 1) * radius * t
        blob(f"Spark_{k}", radius * rnd.uniform(0.06, 0.13), p, sp, c)
    # fumée en boules au bout du panache
    smoke = flat("Smoke", "#F4F6FA", 0.9, 0.12)
    smoke2 = flat("Smoke2", "#CDD5E2", 0.9, 0.05)
    end = base + d * (length * 1.0)
    for k in range(30):
        a = rnd.uniform(0, 2 * math.pi)
        rr = rnd.uniform(0.2, 1.0) * radius * 3.0
        p = end + side * (math.cos(a) * rr) + up * (math.sin(a) * rr * 0.6) + d * rnd.uniform(-0.4, 1.6) * radius
        blob(f"Smoke_{k}", radius * rnd.uniform(0.55, 1.1), p, smoke if k % 3 else smoke2, c)
    L = bpy.data.lights.new("PlumeLight", "POINT")
    L.energy = 3000 * radius
    L.color = (1.0, 0.6, 0.25)
    L.shadow_soft_size = radius
    lo = bpy.data.objects.new("PlumeLight", L)
    c.objects.link(lo)
    lo.location = base + d * (length * 0.25)


def cloud(c, center, size, seed, mat):
    rnd = random.Random(seed)
    for k in range(9):
        off = Vector((rnd.uniform(-1.4, 1.4) * size, rnd.uniform(-0.4, 0.4) * size, rnd.uniform(-0.2, 0.5) * size))
        blob(f"Cloud_{seed}_{k}", size * rnd.uniform(0.55, 0.95), Vector(center) + off, mat, c, squash=(1, 1, 0.8))


def sky_world(top_hex, bottom_hex, strength=1.0, stars=False):
    scene = bpy.context.scene
    w = bpy.data.worlds.new("World")
    scene.world = w
    w.use_nodes = True
    nt = w.node_tree
    bg = nt.nodes["Background"]
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    tr, tg, tb = rocketlib.srgb(top_hex)
    br, bgc, bb = rocketlib.srgb(bottom_hex)
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (br, bgc, bb, 1)
    ramp.color_ramp.elements[1].position = 0.55
    ramp.color_ramp.elements[1].color = (tr, tg, tb, 1)
    nt.links.new(coord.outputs["Window"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["Y"], ramp.inputs["Fac"])
    if stars:
        noise = nt.nodes.new("ShaderNodeTexVoronoi")
        noise.inputs["Scale"].default_value = 260.0
        nt.links.new(coord.outputs["Window"], noise.inputs["Vector"])
        mr = nt.nodes.new("ShaderNodeMapRange")
        mr.inputs["From Min"].default_value = 0.0
        mr.inputs["From Max"].default_value = 0.035
        mr.inputs["To Min"].default_value = 3.0
        mr.inputs["To Max"].default_value = 0.0
        mr.clamp = True
        nt.links.new(noise.outputs["Distance"], mr.inputs["Value"])
        add = nt.nodes.new("ShaderNodeMix")
        add.data_type = "RGBA"
        add.blend_type = "ADD"
        add.inputs["Factor"].default_value = 1.0
        nt.links.new(ramp.outputs["Color"], add.inputs[6])
        nt.links.new(mr.outputs["Result"], add.inputs[7])
        nt.links.new(add.outputs[2], bg.inputs["Color"])
    else:
        nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = strength


def sun(c, rot_deg, energy, color=(1, 1, 1), angle=3.0):
    L = bpy.data.lights.new("Sun", "SUN")
    L.energy = energy
    L.color = color
    L.angle = math.radians(angle)
    o = bpy.data.objects.new("Sun", L)
    c.objects.link(o)
    o.rotation_euler = tuple(math.radians(a) for a in rot_deg)
    return o


def area(c, name, loc, target, energy, color, size):
    L = bpy.data.lights.new(name, "AREA")
    L.energy = energy
    L.color = color
    L.size = size
    o = bpy.data.objects.new(name, L)
    c.objects.link(o)
    o.location = loc
    o.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()


def camera(c, loc, target, lens):
    cam = bpy.data.cameras.new("Cam")
    cam.lens = lens
    o = bpy.data.objects.new("Cam", cam)
    c.objects.link(o)
    o.location = loc
    o.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = o


def render_settings(scene, w, h, samples):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 4
    scene.render.resolution_x = w
    scene.render.resolution_y = h
    scene.render.compositor_device = "CPU"
    scene.view_settings.view_transform = "Standard"
    tree = bpy.data.node_groups.new("Comp", "CompositorNodeTree")
    scene.compositing_node_group = tree
    rl = tree.nodes.new("CompositorNodeRLayers")
    g = tree.nodes.new("CompositorNodeGlare")
    g.inputs["Type"].default_value = "Bloom"
    g.inputs["Threshold"].default_value = 0.95
    g.inputs["Strength"].default_value = 0.35
    g.inputs["Size"].default_value = 0.8
    out = tree.nodes.new("NodeGroupOutput")
    tree.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
    tree.links.new(rl.outputs["Image"], g.inputs["Image"])
    tree.links.new(g.outputs["Image"], out.inputs["Image"])


# ---------------------------------------------------------------- scènes

def scene_launch(c):
    sky_world("#2E7BFF", "#BFE8FF", 1.0)
    sun(c, (50, 10, -40), 4.0, (1.0, 0.95, 0.85))
    root = build(40, c)
    base, axis = place(root, (0, 0, 0), tilt_deg=28, scale=1.0)
    cartoon_plume(c, base, axis, length=7.5, radius=1.0, seed=4)
    area(c, "Rim", (-4, 8, 9), (0, 0, 4), 2500, (0.6, 0.85, 1.0), 4)
    area(c, "Key", (8, -9, 7), (0, 0, 4), 2200, (1.0, 0.93, 0.85), 6)
    cm = flat("Cloud", "#FFFFFF", 0.95, 0.1)
    cloud(c, (-14, 18, -6), 2.4, 1, cm)
    cloud(c, (16, 22, 2), 2.0, 2, cm)
    cloud(c, (10, 26, 12), 1.6, 3, cm)
    cloud(c, (-10, 30, 14), 1.8, 5, cm)
    camera(c, (3.0, -31, 0.5), (-3.6, 0, 1.6), 40)


def scene_before(c):
    sky_world("#9CC9F5", "#E8F4FF", 0.9)
    sun(c, (40, 0, 20), 2.5, (1.0, 1.0, 1.0), 10)
    root = build(1, c)
    place(root, (0, 0, 0), 0)
    grass = flat("Grass", "#5FB548", 0.9)
    g = rocketlib.lathe("Ground", [(80, -0.05), (80, 0.0)], grass, None, c, segments=24)
    pad = flat("Pad", "#8A8F96", 0.8)
    rocketlib.lathe("Pad", [(1.8, 0.0), (1.8, 0.25)], pad, None, c, segments=32)
    for o in bpy.data.objects:
        if o.name.startswith("R01_"):
            o.location.z += 0.0
    root.location.z = 0.25
    camera(c, (5.0, -17, 3.4), (0, 0, 3.9), 40)


def scene_after(c):
    sky_world("#2A0B5C", "#7A2BD6", 1.0, stars=True)
    root = build(40, c)
    base, axis = place(root, (0, 0, 0), tilt_deg=8, scale=1.0)
    cartoon_plume(c, base, axis, length=6.0, radius=0.9, seed=7, palette=["#FFFFF5", "#FFE45C", "#FFB13B", "#FF6AD5"])
    area(c, "Rim", (-5, 7, 9), (0, 0, 4), 3000, (0.85, 0.5, 1.0), 4)
    area(c, "Key", (8, -9, 7), (0, 0, 4), 2000, (1.0, 0.9, 0.75), 6)
    camera(c, (5.0, -24, 1.6), (0, 0, 2.6), 40)


def scene_hero(c):
    sky_world("#12062E", "#4B1C8F", 1.0, stars=True)
    # planète en bas
    planet = flat("Planet", "#2F7BFF", 0.6)
    p = blob("Planet", 60, (0, 30, -66), planet, c)
    atm = emissive("Atmo", "#7FD0FF", 2.5)
    rocketlib.torus("Atmo", 60.2, 0.5, (0, 30, -66), atm, None, c, seg_major=96, rotation=(78, 0, 0))
    root = build(37, c)
    base, axis = place(root, (0, 0, 0), tilt_deg=-14, yaw_deg=0, scale=1.0)
    cartoon_plume(c, base, axis, length=7.0, radius=0.95, seed=9, palette=["#FFFFF5", "#FFF07A", "#FFC23B", "#FF8A1F"])
    area(c, "Rim", (5, 8, 10), (0, 0, 4), 3500, (1.0, 0.85, 0.5), 4)
    area(c, "Key", (-8, -9, 6), (0, 0, 4), 1800, (0.8, 0.85, 1.0), 6)
    camera(c, (-4.0, -21, 0.6), (3.0, 0, 2.8), 40)


SCENES = {"launch": scene_launch, "before": scene_before, "after": scene_after, "hero": scene_hero}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--scene", default="all")
    ap.add_argument("--res", default="1920x1080")
    ap.add_argument("--samples", type=int, default=96)
    a = ap.parse_args(argv)
    w, h = (int(x) for x in a.res.split("x"))
    os.makedirs(a.out, exist_ok=True)
    names = list(SCENES) if a.scene == "all" else a.scene.split(",")
    for n in names:
        scene = reset()
        c = col("Thumb")
        SCENES[n](c)
        render_settings(scene, w, h, a.samples)
        scene.render.filepath = os.path.join(a.out, f"{n}.png")
        bpy.ops.render.render(write_still=True)
        print("rendu", n)


if __name__ == "__main__":
    main()
