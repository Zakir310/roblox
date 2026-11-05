--[[
	AutoImportRockets.studio.luau — (GÉNÉRÉ) importe les 40 fusées v2 sans la fenêtre Import 3D.
	1. Télécharge le dépôt (GitHub → Code → Download ZIP) et décompresse-le.
	2. Remplace FBX_FOLDER par le chemin de assets/rockets/fbx sur ton ordinateur.
	3. Studio : View → Command Bar, colle tout, Entrée.
	Les anciennes fusées du même nom dans ReplicatedStorage.Assets.Rockets sont remplacées (REPLACE_EXISTING).
]]

local FBX_FOLDER = [[C:\Users\TonNom\Downloads\roblox-master\assets\rockets\fbx]]
local ONLY: { number }? = nil -- ex. { 1, 2, 3 }
local REPLACE_EXISTING = true
local CATALOG = {}
for _, def in ({
	{ id = 1, key = "Firecracker", name = "Pétard", world = 1, height = 7.96, multiplier = 1, cost = 0, file = "Rocket_01_Firecracker",
		aura = { color = Color3.fromRGB(255, 177, 59), strength = 0.4 },
		parts = {
			{ name = "Band", color = Color3.fromRGB(255, 194, 59), kind = "metal" },
			{ name = "Band_2", color = Color3.fromRGB(255, 194, 59), kind = "metal" },
			{ name = "Band_3", color = Color3.fromRGB(255, 194, 59), kind = "metal" },
			{ name = "Body", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Cap", color = Color3.fromRGB(255, 194, 59), kind = "metal" },
			{ name = "Fuse", color = Color3.fromRGB(107, 74, 43), kind = "matte" },
			{ name = "Fuse_2", color = Color3.fromRGB(107, 74, 43), kind = "matte" },
			{ name = "Fuse_3", color = Color3.fromRGB(107, 74, 43), kind = "matte" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Spark", color = Color3.fromRGB(255, 228, 92), kind = "glow" },
			{ name = "Stick", color = Color3.fromRGB(176, 122, 69), kind = "wood" },
			{ name = "StickTie", color = Color3.fromRGB(255, 194, 59), kind = "metal" },
		},
	},
	{ id = 2, key = "SodaBottle", name = "Bouteille de soda", world = 1, height = 6.22, multiplier = 1.3, cost = 150, file = "Rocket_02_SodaBottle",
		aura = { color = Color3.fromRGB(92, 255, 176), strength = 0.45 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(46, 194, 126), kind = "glass" },
			{ name = "Cap", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "CardFin", color = Color3.fromRGB(233, 215, 176), kind = "matte" },
			{ name = "CardFin_2", color = Color3.fromRGB(233, 215, 176), kind = "matte" },
			{ name = "CardFin_3", color = Color3.fromRGB(233, 215, 176), kind = "matte" },
			{ name = "Fizz", color = Color3.fromRGB(255, 255, 255), kind = "glass" },
			{ name = "Label", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "LabelStripe", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
		},
	},
	{ id = 3, key = "TinCans", name = "Boîtes de conserve", world = 1, height = 7, multiplier = 1.7, cost = 400, file = "Rocket_03_TinCans",
		aura = { color = Color3.fromRGB(255, 210, 122), strength = 0.45 },
		parts = {
			{ name = "Can", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Can_2", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Can_3", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Funnel", color = Color3.fromRGB(154, 160, 168), kind = "metal" },
			{ name = "Label", color = Color3.fromRGB(47, 123, 255), kind = "paint" },
			{ name = "Label_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Label_3", color = Color3.fromRGB(255, 194, 59), kind = "paint" },
			{ name = "LidFin", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "LidFin_2", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "LidFin_3", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(154, 160, 168), kind = "metal" },
			{ name = "Rim", color = Color3.fromRGB(154, 160, 168), kind = "metal" },
			{ name = "Rim_2", color = Color3.fromRGB(154, 160, 168), kind = "metal" },
			{ name = "Rim_3", color = Color3.fromRGB(154, 160, 168), kind = "metal" },
			{ name = "Spout", color = Color3.fromRGB(154, 160, 168), kind = "metal" },
			{ name = "Tape", color = Color3.fromRGB(140, 143, 150), kind = "matte" },
		},
	},
	{ id = 4, key = "Cardboard", name = "Fusée en carton", world = 1, height = 7.1, multiplier = 2.2, cost = 900, file = "Rocket_04_Cardboard",
		aura = { color = Color3.fromRGB(255, 210, 122), strength = 0.4 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(185, 138, 85), kind = "matte" },
			{ name = "CardFin", color = Color3.fromRGB(156, 112, 65), kind = "matte" },
			{ name = "CardFin_2", color = Color3.fromRGB(156, 112, 65), kind = "matte" },
			{ name = "CardFin_3", color = Color3.fromRGB(156, 112, 65), kind = "matte" },
			{ name = "CardFin_4", color = Color3.fromRGB(156, 112, 65), kind = "matte" },
			{ name = "DrawnFrame", color = Color3.fromRGB(30, 30, 30), kind = "matte" },
			{ name = "DrawnWindow", color = Color3.fromRGB(94, 200, 255), kind = "paint" },
			{ name = "Nozzle", color = Color3.fromRGB(242, 242, 242), kind = "matte" },
			{ name = "Roof", color = Color3.fromRGB(156, 112, 65), kind = "matte" },
			{ name = "Tape", color = Color3.fromRGB(217, 210, 194), kind = "matte" },
			{ name = "Tape_2", color = Color3.fromRGB(217, 210, 194), kind = "matte" },
		},
	},
	{ id = 5, key = "ToyRocket", name = "Fusée jouet", world = 1, height = 6.8, multiplier = 2.8, cost = 1800, file = "Rocket_05_ToyRocket",
		aura = { color = Color3.fromRGB(255, 228, 92), strength = 0.5 },
		parts = {
			{ name = "Antenna", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "AntennaBall", color = Color3.fromRGB(94, 200, 255), kind = "glow" },
			{ name = "Body", color = Color3.fromRGB(255, 210, 59), kind = "paint" },
			{ name = "Fin", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Fin_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Fin_3", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "NoseBall", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Nozzle", color = Color3.fromRGB(232, 50, 46), kind = "dark" },
			{ name = "Stripe", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Stripe_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Window", color = Color3.fromRGB(127, 227, 255), kind = "glass" },
			{ name = "WindowFrame", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
		},
	},
	{ id = 6, key = "BarrelCopter", name = "Tonneau à hélice", world = 1, height = 5.47, multiplier = 3.5, cost = 3500, file = "Rocket_06_BarrelCopter",
		aura = { color = Color3.fromRGB(255, 196, 107), strength = 0.5 },
		parts = {
			{ name = "Blade", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Blade_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Blade_3", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Body", color = Color3.fromRGB(160, 112, 63), kind = "wood" },
			{ name = "Hoop", color = Color3.fromRGB(78, 74, 68), kind = "dark" },
			{ name = "Hoop_2", color = Color3.fromRGB(78, 74, 68), kind = "dark" },
			{ name = "HoopMid", color = Color3.fromRGB(78, 74, 68), kind = "dark" },
			{ name = "Hub", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Mast", color = Color3.fromRGB(154, 160, 168), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "SideThruster", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "SideThruster_2", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "ThrusterStrap", color = Color3.fromRGB(78, 74, 68), kind = "dark" },
			{ name = "ThrusterStrap_2", color = Color3.fromRGB(78, 74, 68), kind = "dark" },
			{ name = "ThrusterTip", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "ThrusterTip_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Window", color = Color3.fromRGB(127, 227, 255), kind = "glass" },
			{ name = "WindowFrame", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
		},
	},
	{ id = 7, key = "RetroClassic", name = "Rétro 1950", world = 1, height = 7.25, multiplier = 4.3, cost = 6500, file = "Rocket_07_RetroClassic",
		aura = { color = Color3.fromRGB(255, 210, 122), strength = 0.55 },
		parts = {
			{ name = "Belt", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Body", color = Color3.fromRGB(217, 221, 227), kind = "metal" },
			{ name = "Fin", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Fin_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Fin_3", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Nose", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Window", color = Color3.fromRGB(127, 227, 255), kind = "glass" },
			{ name = "Window_2", color = Color3.fromRGB(127, 227, 255), kind = "glass" },
			{ name = "Window_3", color = Color3.fromRGB(127, 227, 255), kind = "glass" },
			{ name = "WindowFrame", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "WindowFrame_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "WindowFrame_3", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
		},
	},
	{ id = 8, key = "Origami", name = "Fusée origami", world = 1, height = 6.9, multiplier = 5.4, cost = 12000, file = "Rocket_08_Origami",
		aura = { color = Color3.fromRGB(155, 215, 255), strength = 0.55 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(247, 247, 242), kind = "matte" },
			{ name = "Fold", color = Color3.fromRGB(47, 123, 255), kind = "matte" },
			{ name = "Fold_2", color = Color3.fromRGB(47, 123, 255), kind = "matte" },
			{ name = "Nose", color = Color3.fromRGB(47, 123, 255), kind = "matte" },
			{ name = "Nozzle", color = Color3.fromRGB(47, 123, 255), kind = "matte" },
			{ name = "PaperFin", color = Color3.fromRGB(247, 247, 242), kind = "matte" },
			{ name = "PaperFin_2", color = Color3.fromRGB(247, 247, 242), kind = "matte" },
			{ name = "PaperFin_3", color = Color3.fromRGB(247, 247, 242), kind = "matte" },
		},
	},
	{ id = 9, key = "PlumberPipes", name = "Fusée plomberie", world = 1, height = 6.77, multiplier = 6.8, cost = 22000, file = "Rocket_09_PlumberPipes",
		aura = { color = Color3.fromRGB(255, 176, 74), strength = 0.6 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Coupler", color = Color3.fromRGB(163, 92, 43), kind = "metal" },
			{ name = "Coupler_2", color = Color3.fromRGB(163, 92, 43), kind = "metal" },
			{ name = "Coupler_3", color = Color3.fromRGB(163, 92, 43), kind = "metal" },
			{ name = "Elbow", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Elbow_2", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Gauge", color = Color3.fromRGB(242, 242, 242), kind = "paint" },
			{ name = "GaugeNeedle", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "GaugeRim", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Joint", color = Color3.fromRGB(163, 92, 43), kind = "metal" },
			{ name = "Joint_2", color = Color3.fromRGB(163, 92, 43), kind = "metal" },
			{ name = "Nose", color = Color3.fromRGB(163, 92, 43), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(78, 74, 68), kind = "dark" },
			{ name = "SidePipe", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "SidePipe_2", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Valve", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Valve_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "ValveStem", color = Color3.fromRGB(154, 160, 168), kind = "metal" },
			{ name = "ValveStem_2", color = Color3.fromRGB(154, 160, 168), kind = "metal" },
		},
	},
	{ id = 10, key = "IceCream", name = "Cornet glacé", world = 1, height = 7.91, multiplier = 8.5, cost = 40000, file = "Rocket_10_IceCream",
		aura = { color = Color3.fromRGB(255, 154, 213), strength = 0.65 },
		parts = {
			{ name = "Cherry", color = Color3.fromRGB(232, 23, 46), kind = "metal" },
			{ name = "CherryStem", color = Color3.fromRGB(62, 122, 42), kind = "matte" },
			{ name = "Cone", color = Color3.fromRGB(217, 163, 94), kind = "matte" },
			{ name = "ScoopChoco", color = Color3.fromRGB(122, 74, 42), kind = "paint" },
			{ name = "ScoopPink", color = Color3.fromRGB(255, 138, 194), kind = "paint" },
			{ name = "ScoopVanilla", color = Color3.fromRGB(255, 244, 214), kind = "paint" },
			{ name = "Sprinkle", color = Color3.fromRGB(94, 200, 255), kind = "paint" },
			{ name = "Sprinkle_10", color = Color3.fromRGB(94, 200, 255), kind = "paint" },
			{ name = "Sprinkle_2", color = Color3.fromRGB(255, 228, 92), kind = "paint" },
			{ name = "Sprinkle_3", color = Color3.fromRGB(124, 255, 106), kind = "paint" },
			{ name = "Sprinkle_4", color = Color3.fromRGB(94, 200, 255), kind = "paint" },
			{ name = "Sprinkle_5", color = Color3.fromRGB(255, 228, 92), kind = "paint" },
			{ name = "Sprinkle_6", color = Color3.fromRGB(124, 255, 106), kind = "paint" },
			{ name = "Sprinkle_7", color = Color3.fromRGB(94, 200, 255), kind = "paint" },
			{ name = "Sprinkle_8", color = Color3.fromRGB(255, 228, 92), kind = "paint" },
			{ name = "Sprinkle_9", color = Color3.fromRGB(124, 255, 106), kind = "paint" },
			{ name = "WaferFin", color = Color3.fromRGB(217, 163, 94), kind = "matte" },
			{ name = "WaferFin_2", color = Color3.fromRGB(217, 163, 94), kind = "matte" },
			{ name = "WaferFin_3", color = Color3.fromRGB(217, 163, 94), kind = "matte" },
			{ name = "WaferLine", color = Color3.fromRGB(176, 122, 58), kind = "matte" },
			{ name = "WaferLine_2", color = Color3.fromRGB(176, 122, 58), kind = "matte" },
			{ name = "WaferLine_3", color = Color3.fromRGB(176, 122, 58), kind = "matte" },
			{ name = "WaferTip", color = Color3.fromRGB(200, 138, 74), kind = "matte" },
		},
	},
	{ id = 11, key = "V2Checker", name = "V2 damier", world = 2, height = 7, multiplier = 11, cost = 75000, file = "Rocket_11_V2Checker",
		aura = { color = Color3.fromRGB(154, 216, 255), strength = 0.8 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(242, 242, 242), kind = "paint" },
			{ name = "CheckA", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "CheckA_2", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "CheckA_3", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "CheckA_4", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Fin", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Fin_2", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Fin_3", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Fin_4", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "FinTip", color = Color3.fromRGB(242, 242, 242), kind = "paint" },
			{ name = "FinTip_2", color = Color3.fromRGB(242, 242, 242), kind = "paint" },
			{ name = "FinTip_3", color = Color3.fromRGB(242, 242, 242), kind = "paint" },
			{ name = "FinTip_4", color = Color3.fromRGB(242, 242, 242), kind = "paint" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
		},
	},
	{ id = 12, key = "SaturnStack", name = "Saturne géante", world = 2, height = 9.8, multiplier = 14, cost = 140000, file = "Rocket_12_SaturnStack",
		aura = { color = Color3.fromRGB(154, 216, 255), strength = 0.85 },
		parts = {
			{ name = "Capsule", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Fin", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Fin_2", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Fin_3", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Fin_4", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Interstage", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_5", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Roll", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Roll_2", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Roll_3", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Stage1", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Stage2", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Stage3", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Tower", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "TowerTip", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
		},
	},
	{ id = 13, key = "Shuttle", name = "Navette", world = 2, height = 8.1, multiplier = 18, cost = 260000, file = "Rocket_13_Shuttle",
		aura = { color = Color3.fromRGB(255, 176, 74), strength = 0.9 },
		parts = {
			{ name = "CockpitGlass", color = Color3.fromRGB(94, 200, 255), kind = "glass" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Orbiter", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "OrbiterNose", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "SRB", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "SRB_2", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "SRBNose", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "SRBNose_2", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Tail", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Tank", color = Color3.fromRGB(226, 116, 43), kind = "paint" },
			{ name = "TankNose", color = Color3.fromRGB(226, 116, 43), kind = "paint" },
			{ name = "Wing", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Wing_2", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
		},
	},
	{ id = 14, key = "Soyuz", name = "Soyouz", world = 2, height = 8.9, multiplier = 23, cost = 480000, file = "Rocket_14_Soyuz",
		aura = { color = Color3.fromRGB(124, 255, 184), strength = 0.9 },
		parts = {
			{ name = "Band", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Booster", color = Color3.fromRGB(111, 138, 106), kind = "paint" },
			{ name = "Booster_2", color = Color3.fromRGB(111, 138, 106), kind = "paint" },
			{ name = "Booster_3", color = Color3.fromRGB(111, 138, 106), kind = "paint" },
			{ name = "Booster_4", color = Color3.fromRGB(111, 138, 106), kind = "paint" },
			{ name = "BoosterFin", color = Color3.fromRGB(226, 116, 43), kind = "paint" },
			{ name = "BoosterFin_2", color = Color3.fromRGB(226, 116, 43), kind = "paint" },
			{ name = "BoosterFin_3", color = Color3.fromRGB(226, 116, 43), kind = "paint" },
			{ name = "BoosterFin_4", color = Color3.fromRGB(226, 116, 43), kind = "paint" },
			{ name = "Core", color = Color3.fromRGB(111, 138, 106), kind = "paint" },
			{ name = "Fairing", color = Color3.fromRGB(242, 242, 242), kind = "paint" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_5", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
		},
	},
	{ id = 15, key = "Reusable", name = "Réutilisable", world = 2, height = 9.4, multiplier = 30, cost = 900000, file = "Rocket_15_Reusable",
		aura = { color = Color3.fromRGB(154, 216, 255), strength = 0.95 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Fairing", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Foot", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Foot_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Foot_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Foot_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "GridFin", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "GridFin_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "GridFin_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "GridFin_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Interstage", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Leg", color = Color3.fromRGB(30, 31, 38), kind = "dark" },
			{ name = "Leg_2", color = Color3.fromRGB(30, 31, 38), kind = "dark" },
			{ name = "Leg_3", color = Color3.fromRGB(30, 31, 38), kind = "dark" },
			{ name = "Leg_4", color = Color3.fromRGB(30, 31, 38), kind = "dark" },
			{ name = "Logo", color = Color3.fromRGB(47, 123, 255), kind = "paint" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_5", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_6", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_7", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_8", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_9", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
		},
	},
	{ id = 16, key = "Capsule", name = "Capsule lunaire", world = 2, height = 7.2, multiplier = 38, cost = 1700000, file = "Rocket_16_Capsule",
		aura = { color = Color3.fromRGB(207, 232, 255), strength = 0.95 },
		parts = {
			{ name = "Antenna", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Capsule.001", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Dish", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "EscapeMotor", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "HeatShield", color = Color3.fromRGB(184, 116, 47), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "RCS", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "RCS_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "RCS_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "RCS_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Service", color = Color3.fromRGB(217, 221, 227), kind = "metal" },
			{ name = "Tower", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Truss", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Truss_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Truss_3", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Window", color = Color3.fromRGB(127, 227, 255), kind = "glass" },
			{ name = "WindowFrame", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
		},
	},
	{ id = 17, key = "Hammerhead", name = "Coiffe marteau", world = 2, height = 8.9, multiplier = 48, cost = 3200000, file = "Rocket_17_Hammerhead",
		aura = { color = Color3.fromRGB(127, 208, 255), strength = 1 },
		parts = {
			{ name = "Adapter", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Band", color = Color3.fromRGB(47, 123, 255), kind = "paint" },
			{ name = "Belt", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Body", color = Color3.fromRGB(47, 123, 255), kind = "paint" },
			{ name = "Fairing", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Fin", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Fin_2", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Fin_3", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Fin_4", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
		},
	},
	{ id = 18, key = "DroneRocket", name = "Fusée drone", world = 2, height = 4.9, multiplier = 60, cost = 6000000, file = "Rocket_18_DroneRocket",
		aura = { color = Color3.fromRGB(94, 242, 255), strength = 1 },
		parts = {
			{ name = "Arm", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Arm_2", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Arm_3", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Arm_4", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Body", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Duct", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Duct_2", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Duct_3", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Duct_4", color = Color3.fromRGB(244, 244, 244), kind = "paint" },
			{ name = "Eye", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Hub", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Hub_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Hub_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Hub_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Light", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Light_2", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Light_3", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Light_4", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Prop", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_10", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_11", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_12", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_2", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_3", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_4", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_5", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_6", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_7", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_8", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Prop_9", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
		},
	},
	{ id = 19, key = "JetRocket", name = "Jet-fusée", world = 2, height = 7.4, multiplier = 75, cost = 11000000, file = "Rocket_19_JetRocket",
		aura = { color = Color3.fromRGB(255, 106, 74), strength = 1.05 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(217, 221, 227), kind = "metal" },
			{ name = "Canard", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Canard_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Cockpit", color = Color3.fromRGB(94, 200, 255), kind = "glass" },
			{ name = "Intake", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Intake_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "IntakeLip", color = Color3.fromRGB(30, 31, 38), kind = "dark" },
			{ name = "IntakeLip_2", color = Color3.fromRGB(30, 31, 38), kind = "dark" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Tail", color = Color3.fromRGB(217, 221, 227), kind = "metal" },
			{ name = "Wing", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "Wing_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
		},
	},
	{ id = 20, key = "MechRocket", name = "Méca-fusée", world = 2, height = 5.6, multiplier = 95, cost = 20000000, file = "Rocket_20_MechRocket",
		aura = { color = Color3.fromRGB(255, 211, 90), strength = 1.1 },
		parts = {
			{ name = "Chest", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Claw", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Claw_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Claw_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Claw_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Core", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Elbow", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Elbow_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Forearm", color = Color3.fromRGB(242, 181, 31), kind = "paint" },
			{ name = "Forearm_2", color = Color3.fromRGB(242, 181, 31), kind = "paint" },
			{ name = "Head", color = Color3.fromRGB(242, 181, 31), kind = "paint" },
			{ name = "Jet", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Jet_2", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Shoulder", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Shoulder_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Torso", color = Color3.fromRGB(242, 181, 31), kind = "paint" },
			{ name = "UpperArm", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "UpperArm_2", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Visor", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
		},
	},
	{ id = 21, key = "Steampunk", name = "Vapeur cuivrée", world = 3, height = 7.35, multiplier = 120, cost = 40000000, file = "Rocket_21_Steampunk",
		aura = { color = Color3.fromRGB(255, 176, 74), strength = 1.3 },
		parts = {
			{ name = "Boiler", color = Color3.fromRGB(184, 116, 47), kind = "metal" },
			{ name = "Chimney", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "ChimneyTop", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Dome", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Gauge", color = Color3.fromRGB(255, 244, 214), kind = "paint" },
			{ name = "Gear", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "GearAxle", color = Color3.fromRGB(78, 74, 68), kind = "dark" },
			{ name = "Nozzle", color = Color3.fromRGB(78, 74, 68), kind = "dark" },
			{ name = "Piston", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Piston_2", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "PistonHousing", color = Color3.fromRGB(138, 90, 42), kind = "metal" },
			{ name = "PistonHousing_2", color = Color3.fromRGB(138, 90, 42), kind = "metal" },
			{ name = "Rivet", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_10", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_11", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_12", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_13", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_14", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_15", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_16", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_17", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_18", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_19", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_2", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_20", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_21", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_22", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_23", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_24", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_25", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_26", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_27", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_28", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_29", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_3", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_30", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_4", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_5", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_6", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_7", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_8", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Rivet_9", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "RivetBand", color = Color3.fromRGB(138, 90, 42), kind = "metal" },
			{ name = "RivetBand_2", color = Color3.fromRGB(138, 90, 42), kind = "metal" },
			{ name = "RivetBand_3", color = Color3.fromRGB(138, 90, 42), kind = "metal" },
			{ name = "Tooth", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Tooth_10", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Tooth_2", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Tooth_3", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Tooth_4", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Tooth_5", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Tooth_6", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Tooth_7", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Tooth_8", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Tooth_9", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
		},
	},
	{ id = 22, key = "PlasmaOrb", name = "Orbe plasma", world = 3, height = 7, multiplier = 150, cost = 75000000, file = "Rocket_22_PlasmaOrb",
		aura = { color = Color3.fromRGB(179, 107, 255), strength = 1.4 },
		parts = {
			{ name = "Base", color = Color3.fromRGB(42, 44, 54), kind = "dark" },
			{ name = "Equator", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Fin", color = Color3.fromRGB(42, 44, 54), kind = "dark" },
			{ name = "Fin_2", color = Color3.fromRGB(42, 44, 54), kind = "dark" },
			{ name = "Fin_3", color = Color3.fromRGB(42, 44, 54), kind = "dark" },
			{ name = "Nozzle", color = Color3.fromRGB(42, 44, 54), kind = "dark" },
			{ name = "Plasma", color = Color3.fromRGB(179, 107, 255), kind = "glow" },
			{ name = "PlasmaShell", color = Color3.fromRGB(230, 214, 255), kind = "glass" },
			{ name = "Rib", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Rib_2", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Rib_3", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Rib_4", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Spire", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "SpireTip", color = Color3.fromRGB(179, 107, 255), kind = "glow" },
		},
	},
	{ id = 23, key = "RingDrive", name = "Propulseur à anneaux", world = 3, height = 9, multiplier = 190, cost = 140000000, file = "Rocket_23_RingDrive",
		aura = { color = Color3.fromRGB(94, 242, 255), strength = 1.4 },
		parts = {
			{ name = "DriveRing", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "DriveRing_2", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "DriveRing_3", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "DriveRingFrame", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "DriveRingFrame_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "DriveRingFrame_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Fin", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Fin_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Fin_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle", color = Color3.fromRGB(42, 44, 54), kind = "dark" },
			{ name = "Spear", color = Color3.fromRGB(232, 236, 242), kind = "metal" },
			{ name = "Spoke", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Spoke_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Spoke_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Spoke_4", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Spoke_5", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Spoke_6", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Spoke_7", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Spoke_8", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Spoke_9", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
		},
	},
	{ id = 24, key = "UFO", name = "Soucoupe", world = 3, height = 2.88, multiplier = 240, cost = 260000000, file = "Rocket_24_UFO",
		aura = { color = Color3.fromRGB(155, 255, 138), strength = 1.5 },
		parts = {
			{ name = "Alien", color = Color3.fromRGB(124, 255, 106), kind = "paint" },
			{ name = "AlienEye", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "AlienEye_2", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Beam", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Dome", color = Color3.fromRGB(155, 255, 138), kind = "glass" },
			{ name = "Foot", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Foot_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Foot_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Leg", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Leg_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Leg_3", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Light", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Light_10", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Light_2", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Light_3", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Light_4", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Light_5", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Light_6", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Light_7", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Light_8", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Light_9", color = Color3.fromRGB(155, 255, 138), kind = "glow" },
			{ name = "Rim", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Saucer", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
		},
	},
	{ id = 25, key = "TeslaCoil", name = "Bobine Tesla", world = 3, height = 7.15, multiplier = 300, cost = 500000000, file = "Rocket_25_TeslaCoil",
		aura = { color = Color3.fromRGB(127, 184, 255), strength = 1.55 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Bolt", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_10", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_11", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_12", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_13", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_14", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_15", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_16", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_17", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_18", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_2", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_3", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_4", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_5", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_6", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_7", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_8", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Bolt_9", color = Color3.fromRGB(191, 224, 255), kind = "glow" },
			{ name = "Coil", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Coil_2", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Coil_3", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Coil_4", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Coil_5", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Coil_6", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Coil_7", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Coil_8", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Coil_9", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Fin", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Fin_2", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Fin_3", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Fin_4", color = Color3.fromRGB(200, 116, 58), kind = "metal" },
			{ name = "Neck", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(42, 44, 54), kind = "dark" },
			{ name = "Pole", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Top", color = Color3.fromRGB(127, 184, 255), kind = "glow" },
			{ name = "Toroid", color = Color3.fromRGB(232, 236, 242), kind = "metal" },
		},
	},
	{ id = 26, key = "Jellyfish", name = "Méduse cosmique", world = 3, height = 6, multiplier = 380, cost = 900000000, file = "Rocket_26_Jellyfish",
		aura = { color = Color3.fromRGB(255, 138, 224), strength = 1.6 },
		parts = {
			{ name = "Bell", color = Color3.fromRGB(255, 138, 224), kind = "glass" },
			{ name = "BellRim", color = Color3.fromRGB(255, 79, 200), kind = "glow" },
			{ name = "Core", color = Color3.fromRGB(255, 79, 200), kind = "glow" },
			{ name = "Nozzle", color = Color3.fromRGB(178, 58, 142), kind = "dark" },
			{ name = "Oral", color = Color3.fromRGB(255, 79, 200), kind = "glow" },
			{ name = "Oral_2", color = Color3.fromRGB(255, 79, 200), kind = "glow" },
			{ name = "Oral_3", color = Color3.fromRGB(255, 79, 200), kind = "glow" },
			{ name = "Oral_4", color = Color3.fromRGB(255, 79, 200), kind = "glow" },
			{ name = "Tentacle", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_10", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_11", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_12", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_13", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_14", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_15", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_16", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_17", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_18", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_19", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_2", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_20", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_21", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_22", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_23", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_24", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_25", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_26", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_27", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_28", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_29", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_3", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_30", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_31", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_32", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_33", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_34", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_35", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_36", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_37", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_38", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_39", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_4", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_40", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_41", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_42", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_43", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_44", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_45", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_46", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_47", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_48", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_5", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_6", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_7", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_8", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
			{ name = "Tentacle_9", color = Color3.fromRGB(255, 184, 238), kind = "paint" },
		},
	},
	{ id = 27, key = "CrystalCluster", name = "Grappe de cristaux", world = 3, height = 7.2, multiplier = 470, cost = 1700000000, file = "Rocket_27_CrystalCluster",
		aura = { color = Color3.fromRGB(94, 242, 255), strength = 1.7 },
		parts = {
			{ name = "Base", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "BaseGlow", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Crystal", color = Color3.fromRGB(94, 242, 255), kind = "glass" },
			{ name = "Crystal_2", color = Color3.fromRGB(168, 246, 255), kind = "glass" },
			{ name = "Crystal_3", color = Color3.fromRGB(63, 184, 255), kind = "glass" },
			{ name = "Crystal_4", color = Color3.fromRGB(127, 208, 255), kind = "glass" },
			{ name = "Crystal_5", color = Color3.fromRGB(191, 247, 255), kind = "glass" },
			{ name = "Heart", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
		},
	},
	{ id = 28, key = "SolarSail", name = "Voile solaire", world = 3, height = 8.31, multiplier = 600, cost = 3200000000, file = "Rocket_28_SolarSail",
		aura = { color = Color3.fromRGB(255, 228, 92), strength = 1.75 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(232, 236, 242), kind = "metal" },
			{ name = "Boom", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Boom_2", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Boom_3", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Boom_4", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Fin", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Fin_2", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Fin_3", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Mast", color = Color3.fromRGB(201, 206, 214), kind = "metal" },
			{ name = "Nose", color = Color3.fromRGB(217, 165, 32), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Sail", color = Color3.fromRGB(255, 211, 90), kind = "metal" },
			{ name = "SailStripe", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
			{ name = "SailStripe_2", color = Color3.fromRGB(232, 50, 46), kind = "paint" },
		},
	},
	{ id = 29, key = "Catamaran", name = "Double coque", world = 3, height = 6.9, multiplier = 750, cost = 6000000000, file = "Rocket_29_Catamaran",
		aura = { color = Color3.fromRGB(255, 176, 74), strength = 1.8 },
		parts = {
			{ name = "Bridge", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "Cockpit", color = Color3.fromRGB(94, 200, 255), kind = "glass" },
			{ name = "Hull", color = Color3.fromRGB(214, 40, 40), kind = "paint" },
			{ name = "Hull_2", color = Color3.fromRGB(214, 40, 40), kind = "paint" },
			{ name = "HullBand", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "HullBand_2", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "HullFin", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "HullFin_2", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "Pod", color = Color3.fromRGB(232, 236, 242), kind = "metal" },
		},
	},
	{ id = 30, key = "Magma", name = "Fusée magma", world = 3, height = 6.4, multiplier = 950, cost = 12000000000, file = "Rocket_30_Magma",
		aura = { color = Color3.fromRGB(255, 106, 31), strength = 2 },
		parts = {
			{ name = "Crater", color = Color3.fromRGB(58, 42, 38), kind = "matte" },
			{ name = "Fin", color = Color3.fromRGB(42, 26, 20), kind = "matte" },
			{ name = "Fin_2", color = Color3.fromRGB(42, 26, 20), kind = "matte" },
			{ name = "Fin_3", color = Color3.fromRGB(42, 26, 20), kind = "matte" },
			{ name = "Lava", color = Color3.fromRGB(255, 177, 59), kind = "glow" },
			{ name = "LavaCrack", color = Color3.fromRGB(255, 106, 31), kind = "glow" },
			{ name = "LavaCrack_2", color = Color3.fromRGB(255, 106, 31), kind = "glow" },
			{ name = "LavaCrack_3", color = Color3.fromRGB(255, 106, 31), kind = "glow" },
			{ name = "Nozzle", color = Color3.fromRGB(42, 26, 20), kind = "dark" },
			{ name = "Rock", color = Color3.fromRGB(58, 42, 38), kind = "matte" },
			{ name = "Spike", color = Color3.fromRGB(42, 26, 20), kind = "matte" },
			{ name = "Spike_2", color = Color3.fromRGB(42, 26, 20), kind = "matte" },
			{ name = "Spike_3", color = Color3.fromRGB(42, 26, 20), kind = "matte" },
			{ name = "Spike_4", color = Color3.fromRGB(42, 26, 20), kind = "matte" },
			{ name = "Spike_5", color = Color3.fromRGB(42, 26, 20), kind = "matte" },
		},
	},
	{ id = 31, key = "Dragon", name = "Dragon", world = 4, height = 7.3, multiplier = 1300, cost = 25000000000, file = "Rocket_31_Dragon",
		aura = { color = Color3.fromRGB(124, 255, 106), strength = 2.1 },
		parts = {
			{ name = "BackSpike", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "BackSpike_2", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "BackSpike_3", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "BackSpike_4", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "BackSpike_5", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "BackSpike_6", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "Belly", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "Body", color = Color3.fromRGB(46, 158, 74), kind = "metal" },
			{ name = "Eye", color = Color3.fromRGB(255, 228, 92), kind = "glow" },
			{ name = "Eye_2", color = Color3.fromRGB(255, 228, 92), kind = "glow" },
			{ name = "Fin", color = Color3.fromRGB(31, 122, 56), kind = "metal" },
			{ name = "Fin_2", color = Color3.fromRGB(31, 122, 56), kind = "metal" },
			{ name = "Head", color = Color3.fromRGB(46, 158, 74), kind = "metal" },
			{ name = "Horn", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "Horn_2", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "Jaw", color = Color3.fromRGB(31, 122, 56), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(42, 44, 54), kind = "dark" },
			{ name = "Wing", color = Color3.fromRGB(31, 122, 56), kind = "metal" },
			{ name = "Wing_2", color = Color3.fromRGB(31, 122, 56), kind = "metal" },
		},
	},
	{ id = 32, key = "Phoenix", name = "Phénix", world = 4, height = 7.59, multiplier = 1700, cost = 50000000000, file = "Rocket_32_Phoenix",
		aura = { color = Color3.fromRGB(255, 138, 31), strength = 2.2 },
		parts = {
			{ name = "Beak", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Body", color = Color3.fromRGB(214, 40, 40), kind = "metal" },
			{ name = "Crest", color = Color3.fromRGB(255, 228, 92), kind = "glow" },
			{ name = "Crest_2", color = Color3.fromRGB(255, 177, 59), kind = "glow" },
			{ name = "Crest_3", color = Color3.fromRGB(255, 138, 31), kind = "glow" },
			{ name = "Eye", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Eye_2", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Feather", color = Color3.fromRGB(255, 228, 92), kind = "glow" },
			{ name = "Feather_2", color = Color3.fromRGB(255, 177, 59), kind = "metal" },
			{ name = "Feather_3", color = Color3.fromRGB(255, 138, 31), kind = "metal" },
			{ name = "Feather_4", color = Color3.fromRGB(255, 74, 31), kind = "metal" },
			{ name = "Feather_5", color = Color3.fromRGB(255, 228, 92), kind = "glow" },
			{ name = "Feather_6", color = Color3.fromRGB(255, 177, 59), kind = "metal" },
			{ name = "Feather_7", color = Color3.fromRGB(255, 138, 31), kind = "metal" },
			{ name = "Feather_8", color = Color3.fromRGB(255, 74, 31), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(58, 61, 70), kind = "dark" },
			{ name = "TailFeather", color = Color3.fromRGB(255, 177, 59), kind = "metal" },
			{ name = "TailFeather_2", color = Color3.fromRGB(255, 138, 31), kind = "metal" },
			{ name = "TailFeather_3", color = Color3.fromRGB(255, 74, 31), kind = "metal" },
		},
	},
	{ id = 33, key = "Shark", name = "Requin", world = 4, height = 7.2, multiplier = 2200, cost = 100000000000, file = "Rocket_33_Shark",
		aura = { color = Color3.fromRGB(94, 242, 255), strength = 2.3 },
		parts = {
			{ name = "Belly", color = Color3.fromRGB(242, 242, 242), kind = "paint" },
			{ name = "Body", color = Color3.fromRGB(159, 178, 204), kind = "metal" },
			{ name = "Dorsal", color = Color3.fromRGB(159, 178, 204), kind = "metal" },
			{ name = "Eye", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "Eye_2", color = Color3.fromRGB(30, 31, 38), kind = "paint" },
			{ name = "EyeShine", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "EyeShine_2", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Fin", color = Color3.fromRGB(124, 141, 166), kind = "metal" },
			{ name = "Fin_2", color = Color3.fromRGB(124, 141, 166), kind = "metal" },
			{ name = "Gill", color = Color3.fromRGB(58, 74, 98), kind = "dark" },
			{ name = "Gill_2", color = Color3.fromRGB(58, 74, 98), kind = "dark" },
			{ name = "Gill_3", color = Color3.fromRGB(58, 74, 98), kind = "dark" },
			{ name = "Mouth", color = Color3.fromRGB(58, 31, 42), kind = "paint" },
			{ name = "Nozzle", color = Color3.fromRGB(42, 44, 54), kind = "dark" },
			{ name = "Pectoral", color = Color3.fromRGB(159, 178, 204), kind = "metal" },
			{ name = "Pectoral_2", color = Color3.fromRGB(159, 178, 204), kind = "metal" },
			{ name = "TailFluke", color = Color3.fromRGB(159, 178, 204), kind = "metal" },
			{ name = "TailFluke_2", color = Color3.fromRGB(159, 178, 204), kind = "metal" },
			{ name = "Tooth", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "Tooth_2", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "Tooth_3", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "Tooth_4", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "Tooth_5", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
		},
	},
	{ id = 34, key = "SpaceWhale", name = "Baleine cosmique", world = 4, height = 7.75, multiplier = 2900, cost = 200000000000, file = "Rocket_34_SpaceWhale",
		aura = { color = Color3.fromRGB(127, 208, 255), strength = 2.3 },
		parts = {
			{ name = "Belly", color = Color3.fromRGB(191, 227, 255), kind = "paint" },
			{ name = "Blowhole", color = Color3.fromRGB(30, 42, 90), kind = "dark" },
			{ name = "Body", color = Color3.fromRGB(47, 91, 214), kind = "metal" },
			{ name = "Eye", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Eye_2", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Flipper", color = Color3.fromRGB(47, 91, 214), kind = "metal" },
			{ name = "Flipper_2", color = Color3.fromRGB(47, 91, 214), kind = "metal" },
			{ name = "Groove", color = Color3.fromRGB(127, 176, 230), kind = "paint" },
			{ name = "Groove_2", color = Color3.fromRGB(127, 176, 230), kind = "paint" },
			{ name = "Groove_3", color = Color3.fromRGB(127, 176, 230), kind = "paint" },
			{ name = "Groove_4", color = Color3.fromRGB(127, 176, 230), kind = "paint" },
			{ name = "Groove_5", color = Color3.fromRGB(127, 176, 230), kind = "paint" },
			{ name = "Groove_6", color = Color3.fromRGB(127, 176, 230), kind = "paint" },
			{ name = "Groove_7", color = Color3.fromRGB(127, 176, 230), kind = "paint" },
			{ name = "Nozzle", color = Color3.fromRGB(30, 42, 90), kind = "dark" },
			{ name = "Spout", color = Color3.fromRGB(191, 247, 255), kind = "glow" },
			{ name = "Spout_2", color = Color3.fromRGB(191, 247, 255), kind = "glow" },
			{ name = "Spout_3", color = Color3.fromRGB(191, 247, 255), kind = "glow" },
			{ name = "Star", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_10", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_11", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_12", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_13", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_14", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_2", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_3", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_4", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_5", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_6", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_7", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_8", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Star_9", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
		},
	},
	{ id = 35, key = "Galaxy", name = "Spirale galactique", world = 4, height = 7.85, multiplier = 3800, cost = 400000000000, file = "Rocket_35_Galaxy",
		aura = { color = Color3.fromRGB(179, 107, 255), strength = 2.4 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(42, 22, 80), kind = "metal" },
			{ name = "Core", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "Fin", color = Color3.fromRGB(75, 28, 143), kind = "metal" },
			{ name = "Fin_2", color = Color3.fromRGB(75, 28, 143), kind = "metal" },
			{ name = "Fin_3", color = Color3.fromRGB(75, 28, 143), kind = "metal" },
			{ name = "Fin_4", color = Color3.fromRGB(75, 28, 143), kind = "metal" },
			{ name = "GalaxyDisc", color = Color3.fromRGB(179, 107, 255), kind = "glow" },
			{ name = "GalaxyDisc_2", color = Color3.fromRGB(255, 138, 224), kind = "glow" },
			{ name = "Nozzle", color = Color3.fromRGB(26, 16, 38), kind = "dark" },
			{ name = "SpiralStar", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_10", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_11", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_12", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_13", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_14", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_15", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_16", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_17", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_18", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_19", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_2", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_20", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_21", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_22", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_23", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_24", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_25", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_26", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_27", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_28", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_29", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_3", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_30", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_31", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_32", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_33", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_34", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_35", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_36", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_37", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_38", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_39", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_4", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_40", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_41", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_42", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_43", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_44", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_45", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_46", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_47", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_48", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_49", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_5", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_50", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_51", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_52", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_6", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_7", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "SpiralStar_8", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
			{ name = "SpiralStar_9", color = Color3.fromRGB(230, 184, 255), kind = "glow" },
		},
	},
	{ id = 36, key = "Samurai", name = "Samouraï", world = 4, height = 8.8, multiplier = 5000, cost = 800000000000, file = "Rocket_36_Samurai",
		aura = { color = Color3.fromRGB(255, 74, 74), strength = 2.5 },
		parts = {
			{ name = "ArmorPlate", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_10", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_11", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_12", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_13", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_14", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_15", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_16", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_17", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_18", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_19", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_2", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_20", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_21", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_22", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_23", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_24", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_3", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_4", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_5", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_6", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_7", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_8", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "ArmorPlate_9", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "Blade", color = Color3.fromRGB(232, 236, 242), kind = "metal" },
			{ name = "Body", color = Color3.fromRGB(179, 22, 30), kind = "paint" },
			{ name = "Fin", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "Fin_2", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "Fin_3", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "Helmet", color = Color3.fromRGB(30, 31, 38), kind = "metal" },
			{ name = "Kuwagata", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Kuwagata_2", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Lace", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Lace_2", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Lace_3", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Lace_4", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(30, 31, 38), kind = "dark" },
			{ name = "Tsuba", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Visor", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
		},
	},
	{ id = 37, key = "RoyalCrown", name = "Couronne royale", world = 4, height = 7.1, multiplier = 6500, cost = 1600000000000, file = "Rocket_37_RoyalCrown",
		aura = { color = Color3.fromRGB(255, 211, 90), strength = 2.6 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "Cross", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "CrossBar", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "CrownBase", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "CrownGem", color = Color3.fromRGB(232, 23, 46), kind = "glass" },
			{ name = "CrownGem_2", color = Color3.fromRGB(47, 123, 255), kind = "glass" },
			{ name = "CrownGem_3", color = Color3.fromRGB(46, 194, 126), kind = "glass" },
			{ name = "CrownGem_4", color = Color3.fromRGB(179, 107, 255), kind = "glass" },
			{ name = "CrownGem_5", color = Color3.fromRGB(255, 255, 255), kind = "glass" },
			{ name = "CrownSpike", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "CrownSpike_2", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "CrownSpike_3", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "CrownSpike_4", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "CrownSpike_5", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Fin", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Fin_2", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Fin_3", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Fin_4", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Jewel", color = Color3.fromRGB(232, 23, 46), kind = "glass" },
			{ name = "Nozzle", color = Color3.fromRGB(138, 106, 26), kind = "dark" },
			{ name = "Orb", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Velvet", color = Color3.fromRGB(142, 27, 46), kind = "paint" },
			{ name = "Velvet_2", color = Color3.fromRGB(142, 27, 46), kind = "paint" },
		},
	},
	{ id = 38, key = "BlackHole", name = "Trou noir", world = 4, height = 8.24, multiplier = 8500, cost = 3200000000000, file = "Rocket_38_BlackHole",
		aura = { color = Color3.fromRGB(255, 138, 58), strength = 2.7 },
		parts = {
			{ name = "AccretionDisk", color = Color3.fromRGB(255, 177, 59), kind = "glow" },
			{ name = "AccretionDisk_2", color = Color3.fromRGB(255, 138, 58), kind = "glow" },
			{ name = "AccretionDisk_3", color = Color3.fromRGB(255, 74, 31), kind = "glow" },
			{ name = "Band", color = Color3.fromRGB(255, 138, 58), kind = "glow" },
			{ name = "Band_2", color = Color3.fromRGB(255, 138, 58), kind = "glow" },
			{ name = "Band_3", color = Color3.fromRGB(255, 138, 58), kind = "glow" },
			{ name = "Body", color = Color3.fromRGB(20, 20, 28), kind = "metal" },
			{ name = "Fin", color = Color3.fromRGB(42, 44, 54), kind = "metal" },
			{ name = "Fin_2", color = Color3.fromRGB(42, 44, 54), kind = "metal" },
			{ name = "Fin_3", color = Color3.fromRGB(42, 44, 54), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(11, 11, 18), kind = "dark" },
			{ name = "PhotonRing", color = Color3.fromRGB(255, 224, 160), kind = "glow" },
			{ name = "Singularity", color = Color3.fromRGB(5, 5, 10), kind = "matte" },
		},
	},
	{ id = 39, key = "Angel", name = "Ange", world = 4, height = 7.65, multiplier = 11000, cost = 6500000000000, file = "Rocket_39_Angel",
		aura = { color = Color3.fromRGB(255, 244, 194), strength = 2.8 },
		parts = {
			{ name = "Band", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "Band_2", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "Body", color = Color3.fromRGB(247, 247, 242), kind = "metal" },
			{ name = "Halo", color = Color3.fromRGB(255, 228, 92), kind = "glow" },
			{ name = "Nozzle", color = Color3.fromRGB(201, 162, 58), kind = "dark" },
			{ name = "Window", color = Color3.fromRGB(255, 228, 92), kind = "glass" },
			{ name = "WindowFrame", color = Color3.fromRGB(241, 200, 90), kind = "metal" },
			{ name = "WingFeather", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "WingFeather_10", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "WingFeather_2", color = Color3.fromRGB(241, 230, 200), kind = "paint" },
			{ name = "WingFeather_3", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "WingFeather_4", color = Color3.fromRGB(241, 230, 200), kind = "paint" },
			{ name = "WingFeather_5", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "WingFeather_6", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "WingFeather_7", color = Color3.fromRGB(241, 230, 200), kind = "paint" },
			{ name = "WingFeather_8", color = Color3.fromRGB(255, 255, 255), kind = "paint" },
			{ name = "WingFeather_9", color = Color3.fromRGB(241, 230, 200), kind = "paint" },
		},
	},
	{ id = 40, key = "CosmicLegend", name = "Légende cosmique", world = 4, height = 8.5, multiplier = 15000, cost = 15000000000000, file = "Rocket_40_CosmicLegend",
		aura = { color = Color3.fromRGB(255, 211, 90), strength = 3 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(247, 247, 242), kind = "metal" },
			{ name = "CrystalWing", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "CrystalWing_2", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Fin", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Fin_2", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Gem", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Gem_2", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Gem_3", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Gem_4", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Gem_5", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Gem_6", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "Nose", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "Nozzle", color = Color3.fromRGB(201, 162, 58), kind = "dark" },
			{ name = "Nozzle_2", color = Color3.fromRGB(201, 162, 58), kind = "dark" },
			{ name = "Nozzle_3", color = Color3.fromRGB(201, 162, 58), kind = "dark" },
			{ name = "OrbitRing", color = Color3.fromRGB(255, 211, 90), kind = "glow" },
			{ name = "OrbitRing_2", color = Color3.fromRGB(179, 107, 255), kind = "glow" },
			{ name = "OrbitRing_3", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "StarCore", color = Color3.fromRGB(255, 255, 255), kind = "glow" },
			{ name = "StarFrame", color = Color3.fromRGB(255, 194, 31), kind = "metal" },
			{ name = "WingGlow", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
			{ name = "WingGlow_2", color = Color3.fromRGB(94, 242, 255), kind = "glow" },
		},
	},
}) do
	CATALOG[def.id] = def
end

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

run()
