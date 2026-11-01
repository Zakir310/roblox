"""
build_rockets.py — construit les 40 fusées, les exporte (FBX + OBJ) pour Roblox,
rend un aperçu de chacune et sauvegarde un .blend avec toutes les fusées.

Usage (avec le module bpy installé dans un venv, ou via Blender) :
    python build_rockets.py --out ../../assets/rockets [--ids 1,2,3] [--no-render] [--samples 64]
    blender -b -P build_rockets.py -- --out ../../assets/rockets
"""

import argparse
import json
import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import rocketlib  # noqa: E402
from specs import SPECS, WORLDS  # noqa: E402


# --------------------------------------------------------------------------
# Scène
# --------------------------------------------------------------------------

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    rocketlib._material_cache.clear()
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    return scene


def new_collection(name):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col


def select_only(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    if objs:
        bpy.context.view_layer.objects.active = objs[0]


# --------------------------------------------------------------------------
# Export
# --------------------------------------------------------------------------

def export_rocket(root, out_dir, spec):
    objs = rocketlib.rocket_objects(root)
    select_only(objs)
    base = f"Rocket_{spec['id']:02d}_{spec['key']}"

    fbx_dir = os.path.join(out_dir, "fbx")
    obj_dir = os.path.join(out_dir, "obj")
    os.makedirs(fbx_dir, exist_ok=True)
    os.makedirs(obj_dir, exist_ok=True)

    bpy.ops.export_scene.fbx(
        filepath=os.path.join(fbx_dir, base + ".fbx"),
        use_selection=True,
        object_types={"MESH"},
        axis_forward="-Z",
        axis_up="Y",
        global_scale=1.0,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        bake_space_transform=True,
        mesh_smooth_type="FACE",
        use_mesh_modifiers=True,
        use_custom_props=False,
        path_mode="STRIP",
        embed_textures=False,
        add_leaf_bones=False,
    )
    bpy.ops.wm.obj_export(
        filepath=os.path.join(obj_dir, base + ".obj"),
        export_selected_objects=True,
        forward_axis="NEGATIVE_Z",
        up_axis="Y",
        export_materials=True,
        export_normals=True,
        export_uv=False,
        apply_modifiers=True,
        export_triangulated_mesh=False,
    )

    # Statistiques de triangles par pièce (limite Roblox : 10 000 par mesh)
    parts = []
    for o in objs:
        mesh = o.data
        tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
        mat = o.data.materials[0] if o.data.materials else None
        color_hex = "#FFFFFF"
        glow = False
        metallic = 0.0
        rough = 0.5
        if mat is not None:
            bsdf = mat.node_tree.nodes.get("Principled BSDF")
            c = bsdf.inputs["Base Color"].default_value
            color_hex = lin_to_hex(c[0], c[1], c[2])
            glow = bsdf.inputs["Emission Strength"].default_value > 0.0
            metallic = bsdf.inputs["Metallic"].default_value
            rough = bsdf.inputs["Roughness"].default_value
        if tris > 10000:
            print(f"  !! {o.name}: {tris} triangles (> 10 000, dépasse la limite Roblox)")
        parts.append(dict(name=o.name.split("_", 1)[1], tris=tris, color=color_hex, glow=glow,
                          metallic=round(metallic, 2), roughness=round(rough, 2)))
    return parts


def lin_to_hex(r, g, b):
    def to_srgb(c):
        c = max(0.0, min(1.0, c))
        return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
    return "#%02X%02X%02X" % tuple(int(round(to_srgb(c) * 255)) for c in (r, g, b))


# --------------------------------------------------------------------------
# Rendu d'aperçu
# --------------------------------------------------------------------------

def setup_render(scene, samples, width=640, height=800):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.render.compositor_device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 4
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.view_settings.view_transform = "AgX"

    # Compositing : glare pour l'aura (bloom) — API Blender 5 (compositing_node_group)
    tree = bpy.data.node_groups.new("Compositing", "CompositorNodeTree")
    scene.compositing_node_group = tree
    rl = tree.nodes.new("CompositorNodeRLayers")
    glare = tree.nodes.new("CompositorNodeGlare")
    glare.inputs["Type"].default_value = "Bloom"
    glare.inputs["Threshold"].default_value = 1.5
    glare.inputs["Strength"].default_value = 0.25
    glare.inputs["Size"].default_value = 0.85
    comp = tree.nodes.new("NodeGroupOutput")
    tree.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
    tree.links.new(rl.outputs["Image"], glare.inputs["Image"])
    tree.links.new(glare.outputs["Image"], comp.inputs["Image"])


def setup_world(scene, world_id):
    """Fond sombre teinté vu par la caméra, mais environnement clair pour les reflets du chrome."""
    w = WORLDS[world_id]
    world = bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    bg = nt.nodes["Background"]
    out = nt.nodes["World Output"]
    r, g, b = rocketlib.srgb(w["bg"])
    cam_bg = nt.nodes.new("ShaderNodeBackground")
    cam_bg.inputs["Color"].default_value = (r * 0.07, g * 0.07, b * 0.09, 1.0)
    cam_bg.inputs["Strength"].default_value = 1.0
    # environnement de studio : dégradé gris-bleu plus clair en haut
    sky = nt.nodes.new("ShaderNodeTexGradient")
    sky.gradient_type = "LINEAR"
    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.inputs["Rotation"].default_value = (0.0, math.radians(-90), 0.0)
    coord = nt.nodes.new("ShaderNodeTexCoord")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.05, 0.06, 0.08, 1.0)
    ramp.color_ramp.elements[1].color = (0.9, 0.95, 1.0, 1.0)
    nt.links.new(coord.outputs["Generated"], mapping.inputs["Vector"])
    nt.links.new(mapping.outputs["Vector"], sky.inputs["Vector"])
    nt.links.new(sky.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 0.8
    lp = nt.nodes.new("ShaderNodeLightPath")
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(lp.outputs["Is Camera Ray"], mix.inputs["Fac"])
    nt.links.new(bg.outputs["Background"], mix.inputs[1])
    nt.links.new(cam_bg.outputs["Background"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])


def setup_lights(collection, height, aura_hex, aura_strength):
    def light(name, kind, loc, energy, color=(1, 1, 1), size=3.0):
        ld = bpy.data.lights.new(name, kind)
        ld.energy = energy
        ld.color = color
        if kind == "AREA":
            ld.size = size
        lo = bpy.data.objects.new(name, ld)
        collection.objects.link(lo)
        lo.location = loc
        direction = Vector((0, 0, height * 0.45)) - Vector(loc)
        lo.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        return lo

    light("Key", "AREA", (6, -7, height * 0.9), 1800, (1.0, 0.97, 0.92), 4.0)
    light("Fill", "AREA", (-7, -4, height * 0.5), 500, (0.85, 0.9, 1.0), 6.0)
    light("Rim", "AREA", (2, 8, height * 1.1), 1200, (0.9, 0.95, 1.0), 3.0)
    ar, ag, ab = rocketlib.srgb(aura_hex)
    aura = bpy.data.lights.new("AuraLight", "POINT")
    aura.energy = 150 * aura_strength
    aura.color = (ar, ag, ab)
    aura.shadow_soft_size = 2.0
    ao = bpy.data.objects.new("AuraLight", aura)
    collection.objects.link(ao)
    ao.location = (0, 0, -1.2)


def setup_pedestal(collection, world_id, spec):
    w = WORLDS[world_id]
    base = rocketlib.make_material("Pedestal", "#2B2F36", 0.2, 0.6)
    glow = rocketlib.make_material("PedestalGlow", w["color"], 0.0, 0.4, w["color"], 6.0)
    z = -2.0
    ped = rocketlib.lathe("Pedestal", [(3.2, z - 0.7), (3.4, z - 0.2), (3.2, z)], base, None, collection, segments=48)
    ring = rocketlib.torus("PedestalRing", 3.3, 0.08, (0, 0, z - 0.05), glow, None, collection)
    ground = rocketlib.make_material("Ground", "#0B0C10", 0.0, 0.95)
    g = rocketlib.lathe("Ground", [(60, z - 0.8), (60, z - 0.7)], ground, None, collection, segments=24)
    return [ped, ring, g]


def setup_camera(scene, collection, height, radius):
    cam = bpy.data.cameras.new("Camera")
    cam.lens = 50
    cam.sensor_fit = "VERTICAL"
    cam.sensor_height = 24.0
    co = bpy.data.objects.new("Camera", cam)
    collection.objects.link(co)
    bottom = -2.6  # socle + flamme
    top = height + 0.4
    target = Vector((0, 0, (top + bottom) / 2))
    aspect = scene.render.resolution_x / scene.render.resolution_y
    vfov = 2 * math.atan((cam.sensor_height / 2) / cam.lens)
    hfov = 2 * math.atan(math.tan(vfov / 2) * aspect)
    d_v = ((top - bottom) / 2) / math.tan(vfov / 2)
    d_h = (radius + 0.6) / math.tan(hfov / 2)
    dist = max(d_v, d_h) * 1.12
    elev = math.radians(12)
    co.location = (dist * math.cos(elev) * 0.55, -dist * math.cos(elev) * 0.835, target.z + dist * math.sin(elev))
    direction = target - co.location
    co.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = co
    return co


def render_preview(scene, path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

def rocket_extent(root):
    objs = rocketlib.rocket_objects(root)
    zmax, rmax = 0.0, 0.0
    bpy.context.view_layer.update()
    for o in objs:
        for v in o.bound_box:
            p = o.matrix_world @ Vector(v)
            zmax = max(zmax, p.z)
            rmax = max(rmax, math.hypot(p.x, p.y))
    return zmax, rmax


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "..", "assets", "rockets"))
    ap.add_argument("--ids", default="")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--samples", type=int, default=64)
    ap.add_argument("--no-blend", action="store_true")
    args = ap.parse_args(argv)

    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)
    prev_dir = os.path.join(out_dir, "previews")
    os.makedirs(prev_dir, exist_ok=True)

    wanted = [int(x) for x in args.ids.split(",") if x.strip()] if args.ids else [s["id"] for s in SPECS]
    specs = [s for s in SPECS if s["id"] in wanted]

    catalog = []
    for spec in specs:
        print(f"== Fusée {spec['id']:02d} {spec['key']} ({spec['name']})")
        scene = reset_scene()
        col = new_collection(f"Rocket_{spec['id']:02d}")
        root = rocketlib.build_rocket(spec, col)
        height, radius = rocket_extent(root)

        parts = export_rocket(root, out_dir, spec)
        total = sum(p["tris"] for p in parts)
        print(f"   {len(parts)} pièces, {total} triangles, hauteur {height:.1f} studs")

        entry = dict(id=spec["id"], key=spec["key"], name=spec["name"], world=spec["world"],
                     height=round(height, 2), radius=round(radius, 2), finish=spec.get("finish", "paint"),
                     aura=spec["aura"], stats=spec["stats"], colors=spec.get("colors", {}), parts=parts,
                     file=f"Rocket_{spec['id']:02d}_{spec['key']}")
        catalog.append(entry)

        if not args.no_render:
            helpers = new_collection("Helpers")
            setup_render(scene, args.samples)
            setup_world(scene, spec["world"])
            setup_lights(helpers, height, spec["aura"]["color"], spec["aura"]["strength"])
            setup_pedestal(helpers, spec["world"], spec)
            setup_camera(scene, helpers, height, radius)
            render_preview(scene, os.path.join(prev_dir, f"Rocket_{spec['id']:02d}.png"))

    with open(os.path.join(out_dir, "catalog.json"), "w", encoding="utf-8") as f:
        json.dump(dict(worlds={str(k): v for k, v in WORLDS.items()}, rockets=catalog), f, ensure_ascii=False, indent=2)
    print("catalog.json écrit")

    # .blend avec toutes les fusées en grille (4 mondes × 10)
    if not args.no_blend and len(specs) == len(SPECS):
        reset_scene()
        for spec in SPECS:
            col = new_collection(f"Monde{spec['world']}_R{spec['id']:02d}_{spec['key']}")
            root = rocketlib.build_rocket(spec, col)
            i = (spec["id"] - 1) % 10
            w = spec["world"] - 1
            root.location = (i * 9.0, -w * 14.0, 0.0)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out_dir, "rockets_all.blend"), compress=True)
        print("rockets_all.blend écrit")


if __name__ == "__main__":
    main()
