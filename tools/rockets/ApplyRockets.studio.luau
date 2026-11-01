--!strict
--[[
	ApplyRockets.studio.luau — script à exécuter UNE FOIS dans la barre de commande de Roblox Studio
	(View → Command Bar) après avoir importé les FBX avec le 3D Importer.

	Ce qu'il fait, pour chaque modèle importé trouvé dans workspace.RocketsImport :
	  1. retrouve la fusée dans le catalogue (ReplicatedStorage.Shared.Config.Rockets) grâce au nom
	     des pièces (R07_Body → fusée 7, pièce "Body") ;
	  2. applique la couleur et le matériau Roblox de chaque pièce (Neon pour les pièces lumineuses,
	     Metal pour le chrome/métal, Wood, Glass pour le cristal, SmoothPlastic sinon) ;
	  3. soude toutes les pièces au corps (PrimaryPart = Body), ancre, désactive les collisions ;
	  4. ajoute l'aura : PointLight + ParticleEmitter (+ Highlight pour le monde 4) ;
	  5. renomme le modèle d'après sa clé, pose les attributs RocketId / RocketKey / World,
	     et le range dans ReplicatedStorage.Assets.Rockets.

	Prérequis :
	  - ReplicatedStorage.Shared.Config.Rockets (ModuleScript généré par tools/rockets/gen_luau.py)
	  - un dossier workspace.RocketsImport contenant les modèles importés (un Model par FBX)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Rockets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Rockets"))
type RocketDef = typeof(Rockets.List[1])
type RocketPart = typeof(Rockets.List[1].parts[1])

local importFolder = Workspace:FindFirstChild("RocketsImport")
assert(importFolder, "Crée un dossier workspace.RocketsImport et mets-y les modèles importés.")

local assets = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder")
assets.Name = "Assets"
assets.Parent = ReplicatedStorage
local targetFolder = assets:FindFirstChild("Rockets") or Instance.new("Folder")
targetFolder.Name = "Rockets"
targetFolder.Parent = assets

-- Matériau Roblox en fonction de la finition et de la pièce
local function materialFor(def: RocketDef, part: RocketPart): Enum.Material
	if part.glow then
		return Enum.Material.Neon
	end
	local name = part.name
	if name:match("^Nozzle") or name:match("^BoosterNozzle") or name:match("^Leg") or name:match("^Arm") or name:match("^Antenna") or name:match("^DishMast") then
		return Enum.Material.Metal
	end
	if name:match("^Window") or name:match("^Cockpit") or name:match("^Dome") then
		return Enum.Material.Glass
	end
	if name:match("^Panel_") then
		return Enum.Material.Glass
	end
	if def.finish == "chrome" or def.finish == "metal" or part.metallic >= 0.6 then
		return Enum.Material.Metal
	elseif def.finish == "wood" then
		return Enum.Material.Wood
	elseif def.finish == "crystal" then
		return Enum.Material.Glass
	elseif def.finish == "matte" then
		return Enum.Material.SmoothPlastic
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

local function addAura(model: Model, body: BasePart, def: RocketDef)
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
	-- base du corps (les particules montent le long de la fusée)
	attachment.Position = Vector3.new(0, -body.Size.Y / 2, 0)
	attachment.Parent = body

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AuraParticles"
	emitter.Color = ColorSequence.new(aura.color)
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15 + 0.1 * strength),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
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
		-- Contour lumineux : réservé aux légendaires (limite Roblox : 31 Highlights actifs)
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

local processed = 0
for _, model in importFolder:GetChildren() do
	if not model:IsA("Model") then
		continue
	end

	-- 1. Identifier la fusée grâce au nom d'une pièce
	local rocketId: number? = nil
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			local id = parsePartName(inst.Name)
			if id then
				rocketId = id
				break
			end
		end
	end
	if not rocketId then
		warn(("Modèle %s : aucune pièce nommée RXX_… trouvée, ignoré"):format(model.Name))
		continue
	end
	local def = Rockets.get(rocketId)
	if not def then
		warn(("Modèle %s : fusée %d absente du catalogue"):format(model.Name, rocketId))
		continue
	end

	local partsByName: { [string]: RocketPart } = {}
	for _, p in def.parts do
		partsByName[p.name] = p
	end

	-- 2. Couleurs et matériaux
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
		if inst:IsA("MeshPart") then
			-- Le 3D Importer peut laisser des SurfaceAppearance : on les retire pour que la couleur s'applique
			local sa = inst:FindFirstChildOfClass("SurfaceAppearance")
			if sa then
				sa:Destroy()
			end
		end
		if partName == "Body" then
			body = inst
		end
	end

	if not body then
		warn(("Modèle %s : pas de pièce Body"):format(model.Name))
		continue
	end

	-- 3. Soudures : tout est attaché au corps, qui devient PrimaryPart
	model.PrimaryPart = body
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") and inst ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = inst
			weld.Parent = inst
		end
	end

	-- 4. Aura
	addAura(model, body, def)

	-- 5. Identité et rangement
	model.Name = def.key
	model:SetAttribute("RocketId", def.id)
	model:SetAttribute("RocketKey", def.key)
	model:SetAttribute("World", def.world)
	model:SetAttribute("Multiplier", def.multiplier)
	model.Parent = targetFolder
	processed += 1
	print(("✔ %02d %s (%s) — %d pièces"):format(def.id, def.name, def.key, #def.parts))
end

print(("%d fusée(s) traitée(s) → ReplicatedStorage.Assets.Rockets"):format(processed))
