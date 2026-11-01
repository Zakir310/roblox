# +1 Rocket Launch — jeu Roblox de fusées

Jeu « +1 » incrémental sur le modèle de *+1 Plane Flight*, mais avec des fusées : on s'entraîne, on lance,
on monte toujours plus haut, on débloque 40 fusées réparties en 4 mondes.

| Dossier | Contenu |
|---|---|
| `docs/` | Analyse du jeu de référence et guides (import des fusées…) |
| `assets/rockets/` | Les 40 fusées 3D (FBX/OBJ), aperçus, planche, catalogue JSON, scène Blender |
| `tools/rockets/` | Générateur Blender des fusées, générateur du catalogue Luau, script d'import Studio |
| `src/shared/` | Code Luau partagé (configs, types) → `ReplicatedStorage.Shared` |
| `src/server/` | Code serveur → `ServerScriptService.Server` |
| `src/client/` | Code client → `StarterPlayer.StarterPlayerScripts.Client` |

Synchronisation avec Studio : [Rojo](https://rojo.space) et `default.project.json`.

Voir `docs/02-import-fusees-roblox.md` pour importer les fusées dans Roblox Studio.
