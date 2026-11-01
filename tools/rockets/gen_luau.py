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


# ---------------------------------------------------------------------------
# Script autonome pour la barre de commande : importe les FBX via AssetImportService,
# puis applique couleurs, matériaux et auras (catalogue embarqué, aucun module requis).
# ---------------------------------------------------------------------------

def catalog_as_lua(cat):
    out = []
    w = out.append
    w("local CATALOG = {")
    for r in cat["rockets"]:
        w(f"\t[{r['id']}] = {{ id = {r['id']}, key = {lua_str(r['key'])}, name = {lua_str(r['name'])}, world = {r['world']}, finish = {lua_str(r['finish'])}, multiplier = {fmt_num(r['stats']['multiplier'])}, file = {lua_str(r['file'])},")
        w(f"\t\taura = {{ color = {lua_color(r['aura']['color'])}, strength = {fmt_num(r['aura']['strength'])} }},")
        w("\t\tparts = {")
        for p in r["parts"]:
            w(f"\t\t\t{{ name = {lua_str(p['name'])}, color = {lua_color(p['color'])}, glow = {'true' if p['glow'] else 'false'}, metallic = {fmt_num(p['metallic'])} }},")
        w("\t\t} },")
    w("}")
    return "\n".join(out)


AUTO_IMPORT_TEMPLATE = r'''--[[
	AutoImportRockets.studio.luau — importe les 40 fusées dans Roblox Studio SANS passer par la fenêtre Import 3D.

	1. Télécharge le dépôt (GitHub → Code → Download ZIP) et décompresse-le.
	2. Modifie la ligne FBX_FOLDER ci-dessous avec le chemin du dossier assets/rockets/fbx sur TON ordinateur.
	3. Ouvre ton place dans Studio, View → Command Bar, colle TOUT ce script, Entrée.

	Le script importe chaque FBX avec l'importeur 3D de Studio (les meshes sont envoyés sur ton compte comme
	avec un import manuel), colore chaque pièce, met les parties lumineuses en Neon, ajoute l'aura et range
	les fusées dans ReplicatedStorage.Assets.Rockets. Les fusées déjà présentes sont ignorées.
	Si l'import automatique échoue sur ta version de Studio, le script te le dit : utilise alors Import 3D
	puis le script ApplyRockets.studio.luau.
]]

-- >>> À MODIFIER : dossier contenant les .fbx (garde les doubles crochets) <<<
local FBX_FOLDER = [[C:\Users\TonNom\Downloads\roblox-master\assets\rockets\fbx]]

-- Mets à false pour n'importer que certaines fusées, ex. ONLY = { 1, 2, 3 }
local ONLY: { number }? = nil

__CATALOG__

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local AssetImportService = game:GetService("AssetImportService")

local sep = FBX_FOLDER:find("\\") and "\\" or "/"
if FBX_FOLDER:sub(-1) ~= sep then
	FBX_FOLDER ..= sep
end

local assets = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder")
assets.Name = "Assets"
assets.Parent = ReplicatedStorage
local targetFolder = assets:FindFirstChild("Rockets") or Instance.new("Folder")
targetFolder.Name = "Rockets"
targetFolder.Parent = assets

local importFolder = Workspace:FindFirstChild("RocketsImport") or Instance.new("Folder")
importFolder.Name = "RocketsImport"
importFolder.Parent = Workspace

local function materialFor(def, part): Enum.Material
	if part.glow then
		return Enum.Material.Neon
	end
	local name = part.name
	if name:match("^Nozzle") or name:match("^BoosterNozzle") or name:match("^Leg") or name:match("^Arm") or name:match("^Antenna") or name:match("^DishMast") then
		return Enum.Material.Metal
	end
	if name:match("^Window") or name:match("^Cockpit") or name:match("^Dome") or name:match("^Panel_") then
		return Enum.Material.Glass
	end
	if def.finish == "chrome" or def.finish == "metal" or part.metallic >= 0.6 then
		return Enum.Material.Metal
	elseif def.finish == "wood" then
		return Enum.Material.Wood
	elseif def.finish == "crystal" then
		return Enum.Material.Glass
	end
	return Enum.Material.SmoothPlastic
end

local function parsePartName(instanceName: string): (number?, string?)
	local idStr, partName = instanceName:match("^R(%d%d)_(.+)$")
	if idStr and partName then
		return tonumber(idStr), partName
	end
	return nil, nil
end

local function addAura(model: Model, body: BasePart, def)
	local aura = def.aura
	local strength = aura.strength
	local light = Instance.new("PointLight")
	light.Name = "AuraLight"
	light.Color = aura.color
	light.Brightness = 0.6 + strength * 0.8
	light.Range = 8 + strength * 5
	light.Shadows = false
	light.Parent = body

	local attachment = Instance.new("Attachment")
	attachment.Name = "AuraAttachment"
	attachment.Position = Vector3.new(0, -body.Size.Y / 2, 0)
	attachment.Parent = body

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AuraParticles"
	emitter.Color = ColorSequence.new(aura.color)
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15 + 0.1 * strength), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(1.0, 1.8)
	emitter.Rate = 6 + 10 * strength
	emitter.Speed = NumberRange.new(2, 4)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Shape = Enum.ParticleEmitterShape.Cylinder
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Acceleration = Vector3.new(0, 1, 0)
	emitter.Parent = attachment

	if def.world >= 4 then
		local highlight = Instance.new("Highlight")
		highlight.Name = "AuraHighlight"
		highlight.FillColor = aura.color
		highlight.FillTransparency = 0.9
		highlight.OutlineColor = aura.color
		highlight.OutlineTransparency = 0.3
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model
	end
end

-- Applique couleurs/matériaux/aura à un modèle importé. Renvoie true si OK.
local function applyToModel(model: Model, def): boolean
	local partsByName = {}
	for _, p in def.parts do
		partsByName[p.name] = p
	end
	local body: BasePart? = nil
	for _, inst in model:GetDescendants() do
		if not inst:IsA("BasePart") then
			continue
		end
		local _, partName = parsePartName(inst.Name)
		if not partName then
			continue
		end
		local pdef = partsByName[partName]
		if not pdef then
			warn(("  pièce inconnue %s dans %s"):format(partName, def.key))
			continue
		end
		inst.Name = partName
		inst.Color = pdef.color
		inst.Material = materialFor(def, pdef)
		inst.Anchored = true
		inst.CanCollide = false
		inst.CanTouch = false
		inst.CanQuery = false
		inst.Massless = true
		inst.CastShadow = not pdef.glow
		if inst.Material == Enum.Material.Glass then
			inst.Transparency = 0.15
		end
		local sa = inst:FindFirstChildOfClass("SurfaceAppearance")
		if sa then
			sa:Destroy()
		end
		if partName == "Body" then
			body = inst
		end
	end
	if not body then
		warn(("  %s : pas de pièce Body"):format(def.key))
		return false
	end
	model.PrimaryPart = body
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") and inst ~= body and not inst:FindFirstChildOfClass("WeldConstraint") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = inst
			weld.Parent = inst
		end
	end
	addAura(model, body, def)
	model.Name = def.key
	model:SetAttribute("RocketId", def.id)
	model:SetAttribute("RocketKey", def.key)
	model:SetAttribute("World", def.world)
	model:SetAttribute("Multiplier", def.multiplier)
	model.Parent = targetFolder
	return true
end

-- Règle les options de l'importeur sur tout l'arbre d'import (noms tolérants aux versions de Studio).
local function configureSession(session)
	local okTree, tree = pcall(function()
		return session:GetImportTree()
	end)
	if not okTree or not tree then
		return
	end
	local nodes = { tree }
	for _, d in tree:GetDescendants() do
		table.insert(nodes, d)
	end
	for _, node in nodes do
		local function trySet(prop, value)
			pcall(function()
				(node :: any)[prop] = value
			end)
		end
		trySet("ScaleUnit", Enum.MeshScaleUnit.Stud)
		trySet("MergeMeshes", false)
		trySet("Anchored", true)
		trySet("RigType", Enum.RigType.None)
		trySet("InsertInWorkspace", true)
		trySet("InsertWithScenePosition", true)
		trySet("UsePivotAsOrigin", true)
		trySet("ImportAsModelAsset", false)
		trySet("ImportOnlyAsModel", true)
		trySet("WorldForward", Enum.NormalId.Back)
		trySet("WorldUp", Enum.NormalId.Top)
	end
end

local function importOne(def): Model?
	local path = FBX_FOLDER .. def.file .. ".fbx"
	local ok, session = pcall(function()
		return AssetImportService:StartSessionWithPath(path)
	end)
	if not ok or not session then
		warn(("  impossible d'ouvrir %s : %s"):format(path, tostring(session)))
		return nil
	end
	configureSession(session)
	local okStatus, statuses = pcall(function()
		return session:GetStatuses()
	end)
	if okStatus and statuses and statuses.errors and #statuses.errors > 0 then
		for _, e in statuses.errors do
			warn("  erreur importeur : " .. tostring(e.statusType or e))
		end
	end
	local before = {}
	for _, c in Workspace:GetChildren() do
		before[c] = true
	end
	local okImport, result = pcall(function()
		return session:Import()
	end)
	if not okImport then
		warn("  Import() a échoué : " .. tostring(result))
		return nil
	end
	-- Retrouve le modèle inséré (retour de Import() ou nouveau Model dans Workspace)
	local candidates = {}
	if typeof(result) == "table" then
		for _, inst in result do
			if typeof(inst) == "Instance" then
				table.insert(candidates, inst)
			end
		end
	elseif typeof(result) == "Instance" then
		table.insert(candidates, result)
	end
	for _, c in Workspace:GetChildren() do
		if not before[c] then
			table.insert(candidates, c)
		end
	end
	for _, c in candidates do
		if c:IsA("Model") then
			return c
		end
		if c:IsA("BasePart") then
			-- certaines versions insèrent un Model sous une Folder
			local m = c:FindFirstAncestorOfClass("Model")
			if m then
				return m
			end
		end
	end
	return nil
end

local done, failed = 0, {}
for id = 1, 40 do
	local def = CATALOG[id]
	if ONLY and not table.find(ONLY, id) then
		continue
	end
	if targetFolder:FindFirstChild(def.key) then
		print(("= %02d %s déjà présent, ignoré"):format(id, def.key))
		continue
	end
	print(("… import %02d %s"):format(id, def.name))
	local model = importOne(def)
	if model then
		model.Parent = importFolder
		if applyToModel(model, def) then
			done += 1
			print(("✔ %02d %s (%s)"):format(id, def.name, def.key))
		else
			table.insert(failed, id)
		end
	else
		table.insert(failed, id)
	end
	task.wait(0.2)
end

print(("%d fusée(s) importée(s) → ReplicatedStorage.Assets.Rockets"):format(done))
if #failed > 0 then
	warn("Échec pour : " .. table.concat(failed, ", ") .. ". Vérifie FBX_FOLDER, ou importe-les avec Import 3D puis ApplyRockets.studio.luau.")
end
'''


def write_auto_import(catalog_path, out_path):
    with open(catalog_path, encoding="utf-8") as f:
        cat = json.load(f)
    script = AUTO_IMPORT_TEMPLATE.replace("__CATALOG__", catalog_as_lua(cat))
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(script)
    print(f"{out_path} écrit")


if __name__ == "__main__":
    write_auto_import(
        os.path.join(HERE, "..", "..", "assets", "rockets", "catalog.json"),
        os.path.join(HERE, "AutoImportRockets.studio.luau"),
    )


# ---------------------------------------------------------------------------
# Version plugin Studio : même logique, déclenchée par un bouton de barre d'outils.
# S'installe en copiant le fichier dans le dossier Plugins local de Studio
# (Windows : %LOCALAPPDATA%\Roblox\Plugins ; Mac : ~/Documents/Roblox/Plugins).
# ---------------------------------------------------------------------------

def write_plugin(catalog_path, out_path):
    with open(catalog_path, encoding="utf-8") as f:
        cat = json.load(f)
    body = AUTO_IMPORT_TEMPLATE.replace("__CATALOG__", catalog_as_lua(cat))
    # Isole le corps dans une fonction run() ; la config et le catalogue restent globaux au plugin.
    marker = 'local ReplicatedStorage = game:GetService("ReplicatedStorage")'
    head, tail = body.split(marker, 1)
    tail = marker + tail
    tail = "\n".join("\t" + ln if ln.strip() else ln for ln in tail.splitlines())
    plugin = (
        head
        + "local RunService = game:GetService(\"RunService\")\n"
        + "if RunService:IsRunning() then\n\treturn\nend\n\n"
        + "local function run()\n" + tail + "\nend\n\n"
        + "local toolbar = plugin:CreateToolbar(\"Fusées\")\n"
        + "local button = toolbar:CreateButton(\"Importer les 40 fusées\", \"Importe les FBX et applique couleurs et auras\", \"rbxassetid://4458901886\")\n"
        + "button.ClickableWhenViewportHidden = true\n"
        + "button.Click:Connect(function()\n\tprint(\"[Fusées] import en cours…\")\n\tlocal ok, err = pcall(run)\n\tif not ok then\n\t\twarn(\"[Fusées] \" .. tostring(err))\n\tend\nend)\n"
    )
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(plugin)
    print(f"{out_path} écrit")


if __name__ == "__main__":
    write_plugin(
        os.path.join(HERE, "..", "..", "assets", "rockets", "catalog.json"),
        os.path.join(HERE, "RocketImporterPlugin.lua"),
    )
