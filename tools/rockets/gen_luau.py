"""
gen_luau.py — génère src/shared/Config/Rockets.luau à partir de assets/rockets/catalog.json.

Usage : python gen_luau.py [--catalog ../../assets/rockets/catalog.json] [--out ../../src/shared/Config/Rockets.luau]
"""

import argparse
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))


def hex_to_rgb255(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def lua_color(h):
    r, g, b = hex_to_rgb255(h)
    return f"Color3.fromRGB({r}, {g}, {b})"


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def fmt_num(x):
    if isinstance(x, float) and x.is_integer():
        x = int(x)
    if isinstance(x, int):
        return str(x)
    return repr(x)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--catalog", default=os.path.join(HERE, "..", "..", "assets", "rockets", "catalog.json"))
    ap.add_argument("--out", default=os.path.join(HERE, "..", "..", "src", "shared", "Config", "Rockets.luau"))
    args = ap.parse_args()

    with open(args.catalog, encoding="utf-8") as f:
        cat = json.load(f)

    lines = []
    w = lines.append
    w("--!strict")
    w("-- Rockets.luau — catalogue des 40 fusées (GÉNÉRÉ par tools/rockets/gen_luau.py, ne pas éditer à la main).")
    w("-- Chaque fusée : identité, monde, stats d'équilibrage, couleur de chaque pièce (nom = nom de l'objet")
    w("-- dans le FBX, sans le préfixe RXX_), pièces lumineuses (Neon) et paramètres d'aura.")
    w("")
    w("export type RocketPart = {")
    w("\tname: string,")
    w("\tcolor: Color3,")
    w("\tglow: boolean,")
    w("\tmetallic: number,")
    w("\troughness: number,")
    w("}")
    w("")
    w("export type RocketAura = {")
    w("\tcolor: Color3,")
    w("\tstrength: number, -- 0.3 (faible) → 3.0 (légendaire)")
    w("}")
    w("")
    w("export type RocketDef = {")
    w("\tid: number,")
    w("\tkey: string,")
    w("\tname: string,")
    w("\tworld: number,")
    w("\tfinish: string, -- paint | metal | chrome | wood | crystal | matte")
    w("\theight: number, -- studs")
    w("\tmultiplier: number, -- multiplicateur d'altitude")
    w("\tcost: number, -- prix en Étoiles (Wins)")
    w("\tfile: string, -- nom du fichier FBX/OBJ dans assets/rockets")
    w("\taura: RocketAura,")
    w("\tparts: { RocketPart },")
    w("}")
    w("")
    w("export type WorldDef = {")
    w("\tid: number,")
    w("\tname: string,")
    w("\tsubtitle: string,")
    w("\tcolor: Color3,")
    w("}")
    w("")
    w("local Rockets = {}")
    w("")
    w("Rockets.Worlds: { WorldDef } = {")
    for wid, wd in sorted(cat["worlds"].items(), key=lambda kv: int(kv[0])):
        w(f"\t{{ id = {wid}, name = {lua_str(wd['name'])}, subtitle = {lua_str(wd['subtitle'])}, color = {lua_color(wd['color'])} }},")
    w("}")
    w("")
    w("Rockets.List: { RocketDef } = {")
    for r in cat["rockets"]:
        w("\t{")
        w(f"\t\tid = {r['id']},")
        w(f"\t\tkey = {lua_str(r['key'])},")
        w(f"\t\tname = {lua_str(r['name'])},")
        w(f"\t\tworld = {r['world']},")
        w(f"\t\tfinish = {lua_str(r['finish'])},")
        w(f"\t\theight = {fmt_num(r['height'])},")
        w(f"\t\tmultiplier = {fmt_num(r['stats']['multiplier'])},")
        w(f"\t\tcost = {fmt_num(r['stats']['cost'])},")
        w(f"\t\tfile = {lua_str(r['file'])},")
        w(f"\t\taura = {{ color = {lua_color(r['aura']['color'])}, strength = {fmt_num(r['aura']['strength'])} }},")
        w("\t\tparts = {")
        for p in r["parts"]:
            w(f"\t\t\t{{ name = {lua_str(p['name'])}, color = {lua_color(p['color'])}, glow = {'true' if p['glow'] else 'false'}, metallic = {fmt_num(p['metallic'])}, roughness = {fmt_num(p['roughness'])} }},")
        w("\t\t},")
        w("\t},")
    w("}")
    w("")
    w("Rockets.ById: { [number]: RocketDef } = {}")
    w("Rockets.ByKey: { [string]: RocketDef } = {}")
    w("for _, def in Rockets.List do")
    w("\tRockets.ById[def.id] = def")
    w("\tRockets.ByKey[def.key] = def")
    w("end")
    w("")
    w("function Rockets.get(id: number): RocketDef?")
    w("\treturn Rockets.ById[id]")
    w("end")
    w("")
    w("function Rockets.forWorld(world: number): { RocketDef }")
    w("\tlocal out = {}")
    w("\tfor _, def in Rockets.List do")
    w("\t\tif def.world == world then")
    w("\t\t\ttable.insert(out, def)")
    w("\t\tend")
    w("\tend")
    w("\treturn out")
    w("end")
    w("")
    w("return Rockets")

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"{args.out} écrit ({len(cat['rockets'])} fusées)")


if __name__ == "__main__":
    main()
