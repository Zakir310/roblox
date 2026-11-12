"""
gen_luau.py — génère, depuis assets/rockets/catalog.json (fusées v2) :
  src/shared/Config/Rockets.luau                  catalogue typé (ModuleScript)
  tools/rockets/ApplyRockets.studio.luau          applique couleurs/matériaux/auras à des modèles déjà importés
  tools/rockets/AutoImportRockets.studio.luau     importe les FBX (AssetImportService) puis applique (barre de commande)
  tools/rockets/RocketImporterPlugin.lua          même chose en plugin Studio (bouton)
"""

import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def c3(h):
    r, g, b = rgb(h)
    return f"Color3.fromRGB({r}, {g}, {b})"


def s(x):
    return '"' + str(x).replace("\\", "\\\\").replace('"', '\\"') + '"'


def num(x):
    if isinstance(x, float) and x.is_integer():
        return str(int(x))
    return repr(x)


def catalog_lua(cat, indent=""):
    out = [f"{indent}{{"]
    for r in cat["rockets"]:
        out.append(f"{indent}\t{{ id = {r['id']}, key = {s(r['key'])}, name = {s(r['name'])}, world = {r['world']}, "
                   f"height = {num(r['height'])}, multiplier = {num(r['stats']['multiplier'])}, cost = {num(r['stats']['cost'])}, file = {s(r['file'])},")
        out.append(f"{indent}\t\taura = {{ color = {c3(r['aura']['color'])}, strength = {num(r['aura']['strength'])} }},")
        out.append(f"{indent}\t\tparts = {{")
        for p in r["parts"]:
            out.append(f"{indent}\t\t\t{{ name = {s(p['name'])}, color = {c3(p['color'])}, kind = {s(p['kind'])} }},")
        out.append(f"{indent}\t\t}},")
        out.append(f"{indent}\t}},")
    out.append(f"{indent}}}")
    return "\n".join(out)


# Corps commun : applique un catalogue à un modèle importé (pièces nommées RXX_<Piece>)
APPLY_LIB = r'''
-- Style « métal cartoon » : chaque type de pièce → matériau Roblox
local KIND_STYLE = {
	metal = { material = Enum.Material.SmoothPlastic, reflectance = 0.22 },
	paint = { material = Enum.Material.SmoothPlastic, reflectance = 0.06 },
	matte = { material = Enum.Material.SmoothPlastic, reflectance = 0 },
	wood = { material = Enum.Material.Wood, reflectance = 0 },
	dark = { material = Enum.Material.Metal, reflectance = 0.05 },
	glass = { material = Enum.Material.Glass, reflectance = 0.1, transparency = 0.25 },
	glow = { material = Enum.Material.Neon, reflectance = 0 },
}

local function parsePartName(instanceName: string): (number?, string?)
	local idStr, partName = instanceName:match("^R(%d%d)_(.+)$")
	if idStr and partName then
		return tonumber(idStr), partName
	end
	return nil, nil
end

local function rocketIdOf(model: Instance): number?
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			local id = parsePartName(inst.Name)
			if id then
				return id
			end
		end
	end
	return nil
end

local function addAura(model: Model, body: BasePart, def)
	local aura = def.aura
	local strength = aura.strength
	local light = Instance.new("PointLight")
	light.Name = "AuraLight"
	light.Color = aura.color
	light.Brightness = 0.6 + strength * 0.7
	light.Range = 8 + strength * 4
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
	emitter.Rate = 4 + 8 * strength
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
		highlight.FillTransparency = 1
		highlight.OutlineColor = aura.color
		highlight.OutlineTransparency = 0.2
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model
	end
end

-- Renvoie true si le modèle a été traité et rangé dans targetFolder.
local function applyToModel(model: Model, def, targetFolder: Instance): boolean
	local partsByName = {}
	for _, p in def.parts do
		partsByName[p.name] = p
	end
	local body: BasePart? = nil
	local first: BasePart? = nil
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
		local style = KIND_STYLE[pdef.kind] or KIND_STYLE.paint
		inst.Name = partName
		inst.Color = pdef.color
		inst.Material = style.material
		inst.Reflectance = style.reflectance
		inst.Transparency = style.transparency or 0
		inst.Anchored = true
		inst.CanCollide = false
		inst.CanTouch = false
		inst.CanQuery = false
		inst.Massless = true
		inst.CastShadow = pdef.kind ~= "glow" and pdef.kind ~= "glass"
		local sa = inst:FindFirstChildOfClass("SurfaceAppearance")
		if sa then
			sa:Destroy()
		end
		first = first or inst
		if partName == "Body" then
			body = inst
		end
	end
	body = body or first
	if not body then
		warn(("  %s : aucune pièce reconnue"):format(def.key))
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

local function rocketsFolder(): Folder
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local assets = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder")
	assets.Name = "Assets"
	assets.Parent = ReplicatedStorage
	local f = assets:FindFirstChild("Rockets") or Instance.new("Folder")
	f.Name = "Rockets"
	f.Parent = assets
	return f :: Folder
end
'''

APPLY_SCRIPT = r'''--[[
	ApplyRockets.studio.luau — (GÉNÉRÉ) après un import manuel avec Import 3D.
	Mets les modèles importés dans workspace.RocketsImport, puis colle ce script dans View → Command Bar.
	Il colore chaque pièce (style métal cartoon), soude, ajoute l'aura et range dans ReplicatedStorage.Assets.Rockets.
]]
__CATALOG__
__LIB__
local importFolder = workspace:FindFirstChild("RocketsImport")
assert(importFolder, "Crée un dossier workspace.RocketsImport et mets-y les modèles importés.")
local target = rocketsFolder()
local done = 0
for _, model in importFolder:GetChildren() do
	if model:IsA("Model") then
		local id = rocketIdOf(model)
		local def = id and CATALOG[id]
		if def then
			local old = target:FindFirstChild(def.key)
			if old then
				old:Destroy()
			end
			if applyToModel(model, def, target) then
				done += 1
				print(("✔ %02d %s (%s)"):format(def.id, def.name, def.key))
			end
		else
			warn(("Modèle %s ignoré : aucune pièce RXX_ reconnue"):format(model.Name))
		end
	end
end
print(("%d fusée(s) → ReplicatedStorage.Assets.Rockets"):format(done))
'''

AUTO_BODY = r'''
local AssetImportService = game:GetService("AssetImportService")
local Workspace = game:GetService("Workspace")

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
	end
end

local function importOne(path: string): Model?
	local ok, session = pcall(function()
		return AssetImportService:StartSessionWithPath(path)
	end)
	if not ok or not session then
		warn(("  impossible d'ouvrir %s : %s"):format(path, tostring(session)))
		return nil
	end
	configureSession(session)
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
		local m = c:IsA("BasePart") and c:FindFirstAncestorOfClass("Model")
		if m then
			return m
		end
	end
	return nil
end

local function run()
	local sep = FBX_FOLDER:find("\\") and "\\" or "/"
	local folder = FBX_FOLDER
	if folder:sub(-1) ~= sep then
		folder ..= sep
	end
	local target = rocketsFolder()
	local done, failed = 0, {}
	for id = 1, 40 do
		local def = CATALOG[id]
		if ONLY and not table.find(ONLY, id) then
			continue
		end
		local old = target:FindFirstChild(def.key)
		if old and not REPLACE_EXISTING then
			print(("= %02d %s déjà présent, ignoré"):format(id, def.key))
			continue
		end
		print(("… import %02d %s"):format(id, def.name))
		local model = importOne(folder .. def.file .. ".fbx")
		if model then
			if old then
				old:Destroy()
			end
			if applyToModel(model, def, target) then
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
		warn("Échec pour : " .. table.concat(failed, ", ") .. ". Vérifie FBX_FOLDER, ou passe par Import 3D + ApplyRockets.studio.luau.")
	end
end
'''

AUTO_HEAD = r'''--[[
	AutoImportRockets.studio.luau — (GÉNÉRÉ) importe les 40 fusées v2 sans la fenêtre Import 3D.
	1. Télécharge le dépôt (GitHub → Code → Download ZIP) et décompresse-le.
	2. Remplace FBX_FOLDER par le chemin de assets/rockets/fbx sur ton ordinateur.
	3. Studio : View → Command Bar, colle tout, Entrée.
	Les anciennes fusées du même nom dans ReplicatedStorage.Assets.Rockets sont remplacées (REPLACE_EXISTING).
]]

local FBX_FOLDER = [[C:\Users\TonNom\Downloads\roblox-master\assets\rockets\fbx]]
local ONLY: { number }? = nil -- ex. { 1, 2, 3 }
local REPLACE_EXISTING = true
'''


def main():
    cat = json.load(open(os.path.join(ROOT, "assets", "rockets", "catalog.json"), encoding="utf-8"))
    assert all(r.get("version") == 2 for r in cat["rockets"]) and len(cat["rockets"]) == 40, "catalogue v2 incomplet"

    # 1. ModuleScript typé
    m = ["--!strict", "-- Rockets.luau — catalogue des 40 fusées v2 (GÉNÉRÉ par tools/rockets/gen_luau.py, ne pas éditer).", "",
         "export type RocketPart = { name: string, color: Color3, kind: string }",
         "export type RocketAura = { color: Color3, strength: number }",
         "export type RocketDef = {", "\tid: number, key: string, name: string, world: number, height: number,",
         "\tmultiplier: number, cost: number, file: string, aura: RocketAura, parts: { RocketPart },", "}",
         "export type WorldDef = { id: number, name: string, subtitle: string, color: Color3 }", "",
         "local Rockets = {}", "",
         "-- (Luau n'accepte pas d'annotation de type sur un champ : `Rockets.X: T = …` ne compile pas, on caste.)",
         "Rockets.Worlds = {"]
    for wid, wd in sorted(cat["worlds"].items(), key=lambda kv: int(kv[0])):
        m.append(f"\t{{ id = {wid}, name = {s(wd['name'])}, subtitle = {s(wd['subtitle'])}, color = {c3(wd['color'])} }},")
    m += ["} :: { WorldDef }", "", "Rockets.List = " + catalog_lua(cat) + " :: { RocketDef }", "",
          "Rockets.ById = {} :: { [number]: RocketDef }", "Rockets.ByKey = {} :: { [string]: RocketDef }",
          "for _, def in Rockets.List do", "\tRockets.ById[def.id] = def", "\tRockets.ByKey[def.key] = def", "end", "",
          "function Rockets.get(id: number): RocketDef?", "\treturn Rockets.ById[id]", "end", "",
          "function Rockets.forWorld(world: number): { RocketDef }", "\tlocal out = {}", "\tfor _, def in Rockets.List do",
          "\t\tif def.world == world then", "\t\t\ttable.insert(out, def)", "\t\tend", "\tend", "\treturn out", "end", "",
          "return Rockets", ""]
    os.makedirs(os.path.join(ROOT, "src", "shared", "Config"), exist_ok=True)
    open(os.path.join(ROOT, "src", "shared", "Config", "Rockets.luau"), "w", encoding="utf-8").write("\n".join(m))

    by_id = "local CATALOG = {}\nfor _, def in (" + catalog_lua(cat) + ") do\n\tCATALOG[def.id] = def\nend\n"

    # 2. Application seule
    open(os.path.join(HERE, "ApplyRockets.studio.luau"), "w", encoding="utf-8").write(
        APPLY_SCRIPT.replace("__CATALOG__", by_id).replace("__LIB__", APPLY_LIB))

    # 3. Import automatique (barre de commande)
    open(os.path.join(HERE, "AutoImportRockets.studio.luau"), "w", encoding="utf-8").write(
        AUTO_HEAD + by_id + APPLY_LIB + AUTO_BODY + "\nrun()\n")

    # 4. Plugin
    plugin = (AUTO_HEAD + by_id + APPLY_LIB + AUTO_BODY +
              '\nif game:GetService("RunService"):IsRunning() then\n\treturn\nend\n'
              'local toolbar = plugin:CreateToolbar("Fusées")\n'
              'local button = toolbar:CreateButton("Importer les 40 fusées", "Importe les FBX v2 et applique le style métal cartoon", "rbxassetid://4458901886")\n'
              'button.ClickableWhenViewportHidden = true\n'
              'button.Click:Connect(function()\n\tprint("[Fusées] import en cours…")\n\tlocal ok, err = pcall(run)\n\tif not ok then\n\t\twarn("[Fusées] " .. tostring(err))\n\tend\nend)\n')
    open(os.path.join(HERE, "RocketImporterPlugin.lua"), "w", encoding="utf-8").write(plugin)
    print("Rockets.luau, ApplyRockets, AutoImportRockets et RocketImporterPlugin générés (40 fusées v2)")


if __name__ == "__main__":
    main()
