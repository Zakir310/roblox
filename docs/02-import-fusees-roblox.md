# Importer les 40 fusées dans Roblox Studio

Les fusées sont générées par un script Blender (`tools/rockets/`) et exportées dans `assets/rockets/`.
Chaque fusée est un fichier FBX (et OBJ) composé de plusieurs pièces nommées `RXX_Body`, `RXX_Nose`,
`RXX_Fin_1`… Roblox importe chaque pièce comme un **MeshPart** séparé, ce qui permet de la colorer et de
mettre les parties lumineuses en **Neon**.

## 1. Ce qu'il y a dans `assets/rockets/`

| Dossier / fichier | Contenu |
|---|---|
| `fbx/Rocket_XX_Nom.fbx` | Le modèle à importer dans Roblox (format recommandé) |
| `obj/Rocket_XX_Nom.obj` + `.mtl` | Même modèle au format OBJ (secours) |
| `previews/Rocket_XX.png` | Aperçu rendu dans Blender |
| `planche_40_fusees.png` | Planche des 40 fusées, 4 mondes × 10 |
| `catalog.json` | Toutes les données (couleurs par pièce, aura, stats) |
| `rockets_all.blend` | Scène Blender avec les 40 fusées en grille, pour les modifier |

Et dans le projet Roblox :

| Fichier | Rôle |
|---|---|
| `src/shared/Config/Rockets.luau` | Catalogue Luau généré (couleurs, aura, multiplicateur, prix) |
| `tools/rockets/ApplyRockets.studio.luau` | Script à coller dans la barre de commande de Studio après l'import |

## 2. Importer dans Studio (étapes)

1. Ouvre ton place dans Roblox Studio.
2. Mets le ModuleScript `Rockets.luau` dans `ReplicatedStorage > Shared > Config > Rockets`
   (si tu utilises Rojo, c'est déjà fait par le mapping de `default.project.json`).
3. Crée un dossier `RocketsImport` dans `Workspace`.
4. Onglet **Avatar** (ou **Home**) → **Import 3D** → sélectionne un ou plusieurs fichiers `.fbx`
   du dossier `assets/rockets/fbx/`. Tu peux en sélectionner **plusieurs d'un coup**.
5. Dans la fenêtre d'import, vérifie :
   - **Import Only As Model** : coché (un Model par fichier).
   - **Scale Unit** : *Studs* (1 unité Blender = 1 stud, les fusées font entre 5 et 10 studs de haut).
   - **Rig Type** : *No Rig*.
   - **Anchored** : coché.
   - **Merge Meshes** : **décoché** (sinon on perd les pièces séparées).
   - **Use Scene Origin As Pivot** : coché (le pivot est à la sortie de la tuyère).
   - Si Studio propose *Insert Using Scene Position* / *Insert With Scene Position*, laisse coché.
6. Clique **Import**. Chaque fichier devient un `Model` nommé `Rocket_XX_Nom` dans `Workspace`.
   Glisse tous ces modèles dans `Workspace > RocketsImport`.
7. Ouvre **View → Command Bar**, colle **tout** le contenu de `tools/rockets/ApplyRockets.studio.luau`,
   appuie sur Entrée. Le script :
   - colore chaque pièce, met Neon sur les parties lumineuses, Metal sur le chrome, Glass sur le cristal ;
   - soude les pièces au corps (`PrimaryPart = Body`) ;
   - ajoute l'aura (lumière + particules, Highlight pour le monde 4) ;
   - renomme le modèle par sa clé (`WoodenDart`, `UltimateLegend`…), pose les attributs `RocketId`,
     `RocketKey`, `World`, `Multiplier` ;
   - range le tout dans `ReplicatedStorage > Assets > Rockets`.
8. Vérifie dans la fenêtre Output : une ligne `✔ 01 Dard de bois (WoodenDart) — 12 pièces` par fusée.

Pour poser une fusée sur la rampe de lancement : `ReplicatedStorage.Assets.Rockets.WoodenDart:Clone()`,
puis `model:PivotTo(padCFrame)`. Le pivot est à la base de la tuyère, la fusée pointe vers +Y.

## 3. Si les couleurs n'apparaissent pas à l'import

C'est normal : Roblox n'importe pas fidèlement les matériaux Blender. **C'est le script
`ApplyRockets.studio.luau` qui applique les couleurs**, depuis le catalogue. Si une pièce reste grise,
c'est que son nom a été modifié par l'importeur : le script affiche `pièce inconnue …` dans Output.

## 4. Modifier une fusée ou en ajouter

1. Édite `tools/rockets/specs.py` (forme, couleurs, aura) — chaque fusée est un petit dictionnaire commenté.
2. Regénère : `python tools/rockets/build_rockets.py --ids 12` (ou sans `--ids` pour les 40).
3. Regénère le catalogue Luau : `python tools/rockets/gen_luau.py`.
4. Réimporte le FBX concerné et relance le script d'application.

Le script Blender tourne avec le module `bpy` (`pip install bpy`) ou dans Blender :
`blender -b -P tools/rockets/build_rockets.py -- --out assets/rockets`.

## 5. Limites Roblox respectées

- Chaque pièce fait moins de 10 000 triangles (la plupart entre 50 et 1 500).
- Les fusées de cristal (33, 34, 38) sont volontairement à facettes (6 à 8 côtés).
- 31 `Highlight` maximum actifs en même temps : seules les fusées du monde 4 en reçoivent un.
  Si tu affiches beaucoup de fusées à la fois (index, boutique), remplace le Highlight par le PointLight seul.
