#!/usr/bin/env python3
"""Assemble l'interface « pixel cubique » en UN SEUL LocalScript, pour l'utiliser sans Rojo.

Usage (depuis la racine du dépôt) :
    python3 tools/ui/build_standalone.py

Produit tools/ui/PixelHud.standalone.client.luau : à coller dans un LocalScript placé dans
StarterPlayer > StarterPlayerScripts. La configuration (icônes, textes, couleurs) est tout en haut.

Chaque module est enveloppé dans une fonction ; chaque ligne `require(...) -- @bundle:Nom` des sources
est remplacée par `__modules.Nom`. Les sources restent la référence : ne modifie pas le fichier généré.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/ui/PixelHud.standalone.client.luau"

# Ordre de dépendance : un module n'utilise que ceux listés avant lui.
MODULES = [
    ("HudConfig", "src/shared/Config/Hud.luau"),
    ("FormatNumber", "src/shared/Util/FormatNumber.luau"),
    ("PixelFx", "src/client/UI/PixelFx.luau"),
    ("PixelButton", "src/client/UI/PixelButton.luau"),
    ("StatsHud", "src/client/UI/StatsHud.luau"),
    ("HudController", "src/client/Controllers/HudController.luau"),
]
MAIN = "src/client/Main.client.luau"

REQUIRE_RE = re.compile(r"require\(.*\)(\s*)--\s*@bundle:(\w+)\s*$")


def transform(source: str, known: set[str], path: str) -> str:
    lines = source.splitlines()
    if lines and lines[0].startswith("--!"):
        lines = lines[1:]
    out = []
    for number, line in enumerate(lines, 1):
        if "@bundle:" in line:
            match = REQUIRE_RE.search(line)
            if not match:
                sys.exit(f"{path}:{number}: ligne @bundle mal formée : {line.strip()}")
            name = match.group(2)
            if name not in known:
                sys.exit(f"{path}:{number}: module {name} inconnu ou déclaré après ce fichier")
            line = line[: match.start()] + f"__modules.{name}"
        # `export type` n'est permis qu'au niveau supérieur d'un module ; ici on est dans une fonction.
        line = re.sub(r"^(\s*)export type ", r"\1type ", line)
        out.append(line)
    return "\n".join(out).strip("\n")


def main() -> None:
    parts = [
        "--!nocheck",
        "-- PixelHud.standalone.client.luau — GÉNÉRÉ par tools/ui/build_standalone.py, ne pas éditer à la main",
        "-- (modifie les fichiers de src/ puis relance le script).",
        "--",
        "-- Interface « pixel cubique » en un seul LocalScript, pour l'utiliser sans Rojo :",
        "--   1. Dans Studio : StarterPlayer > StarterPlayerScripts > + > LocalScript, nomme-le PixelHud.",
        "--   2. Colle tout ce fichier dedans, puis Play.",
        "--   3. Pour tes icônes : modifie la section CONFIGURATION juste en dessous (champ `image`).",
        "",
        "local __modules = {}",
    ]
    known: set[str] = set()
    for name, rel in MODULES:
        source = (ROOT / rel).read_text(encoding="utf-8")
        body = transform(source, known, rel)
        banner = "CONFIGURATION — icônes, textes, couleurs" if name == "HudConfig" else name
        parts += [
            "",
            "-" * 100,
            f"-- {banner}  (source : {rel})",
            "-" * 100,
            f"__modules.{name} = (function()",
            body,
            "end)()",
        ]
        known.add(name)
    main_body = transform((ROOT / MAIN).read_text(encoding="utf-8"), known, MAIN)
    parts += ["", "-" * 100, f"-- Démarrage  (source : {MAIN})", "-" * 100, main_body, ""]
    OUT.write_text("\n".join(parts), encoding="utf-8")
    print(f"écrit : {OUT.relative_to(ROOT)} ({sum(1 for _ in OUT.open(encoding='utf-8'))} lignes)")


if __name__ == "__main__":
    main()
