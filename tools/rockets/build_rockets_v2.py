"""
build_rockets_v2.py — construit les 40 fusées v2, exporte FBX/OBJ, rend un aperçu cartoon (contours + feu)
et écrit catalog.json (couleur et type de matériau de chaque pièce).

    python build_rockets_v2.py --out ../../assets/rockets [--ids 1,2] [--samples 48] [--no-render]
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

import rocketlib as L  # noqa: E402
from rocketlib2 import Rocket  # noqa: E402
from designs_v2 import DESIGNS  # noqa: E402
from specs import WORLDS  # noqa: E402
import build_rockets as B1  # noqa: E402
import render_thumbs as T  # noqa: E402


def objects_of(root):
    out = []
    for o in bpy.data.objects:
        p = o.parent
        while p is not None:
            if p == root:
                if o.type == "MESH":
                    out.append(o)
                break
            p = p.parent
    return out


def build(d):
    B1.reset_scene()
    col = B1.new_collection(f"Rocket_{d['id']:02d}")
    R = Rocket(d["id"], d["key"], col)
    d["build"](R)
    bpy.context.view_layer.update()
    return R


def export(R, d, out_dir):
    objs = objects_of(R.root)
    B1.select_only(objs)
    base = f"Rocket_{d['id']:02d}_{d['key']}"
    for sub in ("fbx", "obj"):
        os.makedirs(os.path.join(out_dir, sub), exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, "fbx", base + ".fbx"), use_selection=True, object_types={"MESH"},
                             axis_forward="-Z", axis_up="Y", apply_unit_scale=True, apply_scale_options="FBX_SCALE_ALL",
                             bake_space_transform=True, mesh_smooth_type="FACE", use_mesh_modifiers=True,
                             use_custom_props=False, path_mode="STRIP", add_leaf_bones=False)
    bpy.ops.wm.obj_export(filepath=os.path.join(out_dir, "obj", base + ".obj"), export_selected_objects=True,
                          forward_axis="NEGATIVE_Z", up_axis="Y", export_materials=True, apply_modifiers=True, export_uv=False)
    dg = bpy.context.evaluated_depsgraph_get()
    parts = []
    zmax, rmax = 0.0, 0.0
    for o in objs:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        tris = sum(len(p.vertices) - 2 for p in me.polygons)
        for v in me.vertices:
            w = ev.matrix_world @ v.co
            zmax = max(zmax, w.z)
            rmax = max(rmax, math.hypot(w.x, w.y))
        ev.to_mesh_clear()
        if tris > 10000:
            print(f"  !! {o.name}: {tris} triangles")
        parts.append(dict(name=o.name.split("_", 1)[1], color=o["hex"], kind=o["kind"], tris=tris))
    return parts, zmax, rmax


def preview(R, d, height, radius, out_png, samples):
    scene = bpy.context.scene
    helpers = B1.new_collection("Helpers")
    B1.setup_render(scene, samples)
    scene.view_settings.view_transform = "Standard"
    B1.setup_world(scene, d["world"])
    B1.setup_lights(helpers, height, d["aura"]["color"], d["aura"]["strength"])
    B1.setup_pedestal(helpers, d["world"], d)
    # feu cartoon sous la fusée
    T.cartoon_plume(helpers, Vector((0, 0, 0.05)), Vector((0, 0, 1)), length=1.9, radius=0.5, seed=d["id"])
    B1.setup_camera(scene, helpers, height, radius)
    scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "..", "assets", "rockets"))
    ap.add_argument("--ids", default="")
    ap.add_argument("--samples", type=int, default=48)
    ap.add_argument("--no-render", action="store_true")
    a = ap.parse_args(argv)
    out = os.path.abspath(a.out)
    os.makedirs(os.path.join(out, "previews"), exist_ok=True)
    ids = [int(x) for x in a.ids.split(",") if x.strip()] if a.ids else [d["id"] for d in DESIGNS]
    cat_path = os.path.join(out, "catalog.json")
    catalog = {}
    if os.path.exists(cat_path) and a.ids:
        for r in json.load(open(cat_path, encoding="utf-8")).get("rockets", []):
            if r.get("version") == 2:
                catalog[r["id"]] = r
    for d in sorted(DESIGNS, key=lambda x: x["id"]):
        if d["id"] not in ids:
            continue
        R = build(d)
        parts, h, rad = export(R, d, out)
        print(f"== {d['id']:02d} {d['key']} : {len(parts)} pièces, {sum(p['tris'] for p in parts)} tris, h={h:.1f}")
        catalog[d["id"]] = dict(version=2, id=d["id"], key=d["key"], name=d["name"], world=d["world"], height=round(h, 2),
                                radius=round(rad, 2), aura=d["aura"], stats=d["stats"], parts=parts,
                                file=f"Rocket_{d['id']:02d}_{d['key']}")
        if not a.no_render:
            preview(R, d, h, rad, os.path.join(out, "previews", f"Rocket_{d['id']:02d}.png"), a.samples)
    rockets = [catalog[k] for k in sorted(catalog)]
    json.dump(dict(worlds={str(k): v for k, v in WORLDS.items()}, rockets=rockets), open(cat_path, "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)
    print("catalog.json :", len(rockets), "fusées")


if __name__ == "__main__":
    main()
