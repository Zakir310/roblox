--[[
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

local CATALOG = {
	[1] = { id = 1, key = "WoodenDart", name = "Dard de bois", world = 1, finish = "wood", multiplier = 1, file = "Rocket_01_WoodenDart",
		aura = { color = Color3.fromRGB(255, 176, 74), strength = 0.3 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(61, 42, 23), glow = false, metallic = 0 },
			{ name = "Band_2", color = Color3.fromRGB(61, 42, 23), glow = false, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(107, 74, 43), glow = false, metallic = 0 },
			{ name = "Fin_1", color = Color3.fromRGB(90, 62, 38), glow = false, metallic = 0 },
			{ name = "Fin_2", color = Color3.fromRGB(90, 62, 38), glow = false, metallic = 0 },
			{ name = "Fin_3", color = Color3.fromRGB(90, 62, 38), glow = false, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(74, 50, 32), glow = false, metallic = 0 },
			{ name = "Nozzle_1", color = Color3.fromRGB(43, 43, 43), glow = false, metallic = 0.9 },
		} },
	[2] = { id = 2, key = "BrassBarrel", name = "Tonneau de cuivre", world = 1, finish = "metal", multiplier = 1.3, file = "Rocket_02_BrassBarrel",
		aura = { color = Color3.fromRGB(255, 196, 107), strength = 0.35 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(140, 109, 74), glow = false, metallic = 0.85 },
			{ name = "Fin_1", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
			{ name = "Fin_2", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
			{ name = "Fin_3", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Ring_1", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.85 },
			{ name = "Ring_2", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.85 },
			{ name = "Window_1", color = Color3.fromRGB(143, 227, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
		} },
	[3] = { id = 3, key = "OrangePod", name = "Capsule orange", world = 1, finish = "paint", multiplier = 1.7, file = "Rocket_03_OrangePod",
		aura = { color = Color3.fromRGB(255, 210, 122), strength = 0.4 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(255, 122, 26), glow = false, metallic = 0.15 },
			{ name = "Fin_1", color = Color3.fromRGB(46, 46, 46), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(46, 46, 46), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(46, 46, 46), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(255, 122, 26), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(46, 46, 46), glow = false, metallic = 0.15 },
		} },
	[4] = { id = 4, key = "ClassicWhite", name = "Classique blanche", world = 1, finish = "paint", multiplier = 2.2, file = "Rocket_04_ClassicWhite",
		aura = { color = Color3.fromRGB(255, 210, 122), strength = 0.45 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_4", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(127, 255, 176), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
		} },
	[5] = { id = 5, key = "SkyBlue", name = "Bleu ciel", world = 1, finish = "paint", multiplier = 2.8, file = "Rocket_05_SkyBlue",
		aura = { color = Color3.fromRGB(143, 200, 255), strength = 0.5 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Fin_4", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "Window_2", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "WindowFrame_2", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
		} },
	[6] = { id = 6, key = "TallNeedle", name = "Aiguille blanche", world = 1, finish = "paint", multiplier = 3.5, file = "Rocket_06_TallNeedle",
		aura = { color = Color3.fromRGB(143, 200, 255), strength = 0.5 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(246, 246, 246), glow = false, metallic = 0.15 },
			{ name = "Collar", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Fin_1", color = Color3.fromRGB(217, 217, 217), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(217, 217, 217), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(217, 217, 217), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
		} },
	[7] = { id = 7, key = "TwinOrange", name = "Double orange", world = 1, finish = "paint", multiplier = 4.3, file = "Rocket_07_TwinOrange",
		aura = { color = Color3.fromRGB(255, 210, 122), strength = 0.5 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Booster_1", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Booster_2", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "BoosterFlame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "BoosterFlame_2", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "BoosterNose_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "BoosterNose_2", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "BoosterNozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "BoosterNozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Fin_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
		} },
	[8] = { id = 8, key = "NavySleek", name = "Marine furtive", world = 1, finish = "metal", multiplier = 5.4, file = "Rocket_08_NavySleek",
		aura = { color = Color3.fromRGB(143, 200, 255), strength = 0.55 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(30, 42, 90), glow = false, metallic = 0.85 },
			{ name = "Booster_1", color = Color3.fromRGB(154, 160, 168), glow = false, metallic = 0.85 },
			{ name = "Booster_2", color = Color3.fromRGB(154, 160, 168), glow = false, metallic = 0.85 },
			{ name = "BoosterFlame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "BoosterFlame_2", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "BoosterNose_1", color = Color3.fromRGB(154, 160, 168), glow = false, metallic = 0.85 },
			{ name = "BoosterNose_2", color = Color3.fromRGB(154, 160, 168), glow = false, metallic = 0.85 },
			{ name = "BoosterNozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "BoosterNozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Fin_1", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 0.85 },
			{ name = "Fin_2", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 0.85 },
			{ name = "Fin_3", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 0.85 },
			{ name = "Fin_4", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 0.85 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 0.85 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 0.85 },
		} },
	[9] = { id = 9, key = "BigFin", name = "Grands ailerons", world = 1, finish = "paint", multiplier = 6.8, file = "Rocket_09_BigFin",
		aura = { color = Color3.fromRGB(255, 210, 122), strength = 0.6 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_4", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
		} },
	[10] = { id = 10, key = "SunsetSwept", name = "Couchant", world = 1, finish = "paint", multiplier = 8.5, file = "Rocket_10_SunsetSwept",
		aura = { color = Color3.fromRGB(255, 210, 122), strength = 0.65 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 122, 26), glow = false, metallic = 0.15 },
			{ name = "Band_2", color = Color3.fromRGB(255, 122, 26), glow = false, metallic = 0.15 },
			{ name = "Body", color = Color3.fromRGB(255, 122, 26), glow = false, metallic = 0.15 },
			{ name = "Fin_1", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 179, 0), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
		} },
	[11] = { id = 11, key = "OrbiterDish", name = "Orbiteur à parabole", world = 2, finish = "metal", multiplier = 11, file = "Rocket_11_OrbiterDish",
		aura = { color = Color3.fromRGB(94, 200, 255), strength = 0.8 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 0.85 },
			{ name = "Dish", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "DishMast", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "DishTip", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Fin_1", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Fin_2", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Fin_3", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Fin_4", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Foot_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Foot_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Foot_3", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Leg_1", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "Leg_2", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "Leg_3", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "Nose", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Window_2", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.85 },
			{ name = "WindowFrame_2", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.85 },
		} },
	[12] = { id = 12, key = "SolarSat", name = "Satellite solaire", world = 2, finish = "metal", multiplier = 14, file = "Rocket_12_SolarSat",
		aura = { color = Color3.fromRGB(94, 200, 255), strength = 0.85 },
		parts = {
			{ name = "Antenna", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "AntennaTip", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Arm_1", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "Arm_2", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "Body", color = Color3.fromRGB(217, 221, 227), glow = false, metallic = 0.85 },
			{ name = "Fin_1", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Fin_2", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Fin_3", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Panel_1", color = Color3.fromRGB(30, 58, 138), glow = false, metallic = 0.85 },
			{ name = "Panel_2", color = Color3.fromRGB(30, 58, 138), glow = false, metallic = 0.85 },
			{ name = "PanelFrame_1", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "PanelFrame_2", color = Color3.fromRGB(111, 117, 125), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.85 },
		} },
	[13] = { id = 13, key = "SilverArrow", name = "Flèche d'argent", world = 2, finish = "chrome", multiplier = 18, file = "Rocket_13_SilverArrow",
		aura = { color = Color3.fromRGB(255, 154, 31), strength = 0.9 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 1 },
			{ name = "Body", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_1", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_2", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_3", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_4", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 1 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 1 },
		} },
	[14] = { id = 14, key = "AzureJet", name = "Jet azur", world = 2, finish = "paint", multiplier = 23, file = "Rocket_14_AzureJet",
		aura = { color = Color3.fromRGB(94, 200, 255), strength = 0.9 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(47, 123, 255), glow = true, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
		} },
	[15] = { id = 15, key = "TwinStack", name = "Double étage", world = 2, finish = "metal", multiplier = 30, file = "Rocket_15_TwinStack",
		aura = { color = Color3.fromRGB(255, 154, 31), strength = 0.95 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Fin_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.85 },
			{ name = "Fin_2", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.85 },
			{ name = "Fin_3", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.85 },
			{ name = "Fin_4", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.85 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Flame_2", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Flame_3", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.85 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_3", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Ring_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.85 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.85 },
		} },
	[16] = { id = 16, key = "StratoWing", name = "Aile strato", world = 2, finish = "paint", multiplier = 38, file = "Rocket_16_StratoWing",
		aura = { color = Color3.fromRGB(94, 200, 255), strength = 1 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Cockpit", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Fin_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
		} },
	[17] = { id = 17, key = "ClusterCore", name = "Cœur en grappe", world = 2, finish = "metal", multiplier = 48, file = "Rocket_17_ClusterCore",
		aura = { color = Color3.fromRGB(94, 200, 255), strength = 1 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Booster_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.85 },
			{ name = "Booster_2", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.85 },
			{ name = "Booster_3", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.85 },
			{ name = "Booster_4", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.85 },
			{ name = "BoosterFlame_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "BoosterFlame_2", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "BoosterFlame_3", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "BoosterFlame_4", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "BoosterNose_1", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.85 },
			{ name = "BoosterNose_2", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.85 },
			{ name = "BoosterNose_3", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.85 },
			{ name = "BoosterNose_4", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.85 },
			{ name = "BoosterNozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "BoosterNozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "BoosterNozzle_3", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "BoosterNozzle_4", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Fin_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.85 },
			{ name = "Fin_2", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.85 },
			{ name = "Fin_3", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.85 },
			{ name = "Fin_4", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.85 },
			{ name = "Flame_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.85 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.85 },
		} },
	[18] = { id = 18, key = "HaloProbe", name = "Sonde à halo", world = 2, finish = "chrome", multiplier = 60, file = "Rocket_18_HaloProbe",
		aura = { color = Color3.fromRGB(255, 154, 31), strength = 1.05 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_1", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_2", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_3", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Halo_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 1 },
		} },
	[19] = { id = 19, key = "CobaltTower", name = "Tour cobalt", world = 2, finish = "paint", multiplier = 75, file = "Rocket_19_CobaltTower",
		aura = { color = Color3.fromRGB(94, 200, 255), strength = 1.1 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.15 },
			{ name = "Fin_1", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_4", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "FinGlow_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Window_2", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "WindowFrame_2", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
		} },
	[20] = { id = 20, key = "HeavyLifter", name = "Lanceur lourd", world = 2, finish = "paint", multiplier = 95, file = "Rocket_20_HeavyLifter",
		aura = { color = Color3.fromRGB(255, 154, 31), strength = 1.15 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Booster_1", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Booster_2", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "BoosterFlame_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "BoosterFlame_2", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "BoosterNose_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "BoosterNose_2", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "BoosterNozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "BoosterNozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Fin_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Fin_4", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Flame_2", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Flame_3", color = Color3.fromRGB(255, 154, 31), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_3", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 106, 0), glow = false, metallic = 0.15 },
		} },
	[21] = { id = 21, key = "BronzeLander", name = "Atterrisseur bronze", world = 3, finish = "metal", multiplier = 120, file = "Rocket_21_BronzeLander",
		aura = { color = Color3.fromRGB(255, 176, 74), strength = 1.3 },
		parts = {
			{ name = "Antenna", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "AntennaTip", color = Color3.fromRGB(255, 176, 74), glow = true, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(163, 118, 62), glow = false, metallic = 0.85 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 176, 74), glow = true, metallic = 0 },
			{ name = "Foot_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Foot_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Foot_3", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Foot_4", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Leg_1", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Leg_2", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Leg_3", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Leg_4", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Nose", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Ring_1", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.85 },
			{ name = "Window_1", color = Color3.fromRGB(255, 210, 122), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
		} },
	[22] = { id = 22, key = "CopperSolar", name = "Cuivre solaire", world = 3, finish = "metal", multiplier = 150, file = "Rocket_22_CopperSolar",
		aura = { color = Color3.fromRGB(94, 200, 255), strength = 1.3 },
		parts = {
			{ name = "Arm_1", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Arm_2", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Body", color = Color3.fromRGB(184, 116, 47), glow = false, metallic = 0.85 },
			{ name = "Fin_1", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
			{ name = "Fin_2", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
			{ name = "Fin_3", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 176, 74), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Panel_1", color = Color3.fromRGB(30, 58, 138), glow = false, metallic = 0.85 },
			{ name = "Panel_2", color = Color3.fromRGB(30, 58, 138), glow = false, metallic = 0.85 },
			{ name = "PanelFrame_1", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "PanelFrame_2", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(92, 70, 48), glow = false, metallic = 0.85 },
		} },
	[23] = { id = 23, key = "TripodDish", name = "Trépied radar", world = 3, finish = "metal", multiplier = 190, file = "Rocket_23_TripodDish",
		aura = { color = Color3.fromRGB(94, 200, 255), strength = 1.35 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(138, 144, 153), glow = false, metallic = 0.85 },
			{ name = "Dish", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "DishMast", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "DishTip", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Foot_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Foot_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Foot_3", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Halo_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Leg_1", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Leg_2", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Leg_3", color = Color3.fromRGB(78, 74, 68), glow = false, metallic = 0.9 },
			{ name = "Nose", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 0.85 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
		} },
	[24] = { id = 24, key = "FrostLance", name = "Lance givrée", world = 3, finish = "chrome", multiplier = 240, file = "Rocket_24_FrostLance",
		aura = { color = Color3.fromRGB(94, 200, 255), strength = 1.4 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(232, 236, 242), glow = false, metallic = 1 },
			{ name = "Fin_1", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_2", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_3", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_4", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "FinGlow_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 200, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(94, 200, 255), glow = false, metallic = 1 },
		} },
	[25] = { id = 25, key = "VioletViper", name = "Vipère violette", world = 3, finish = "paint", multiplier = 300, file = "Rocket_25_VioletViper",
		aura = { color = Color3.fromRGB(255, 106, 213), strength = 1.5 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(122, 43, 214), glow = false, metallic = 0.15 },
			{ name = "Cockpit", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Fin_1", color = Color3.fromRGB(90, 31, 163), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(90, 31, 163), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(90, 31, 163), glow = false, metallic = 0.15 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
		} },
	[26] = { id = 26, key = "GoldSaucer", name = "Soucoupe dorée", world = 3, finish = "chrome", multiplier = 380, file = "Rocket_26_GoldSaucer",
		aura = { color = Color3.fromRGB(155, 232, 255), strength = 1.6 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "Dome", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "Flame_2", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "Flame_3", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_3", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Saucer", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 1 },
			{ name = "SaucerGlow", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_1", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_2", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_3", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_4", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_5", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_6", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_7", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_8", color = Color3.fromRGB(155, 232, 255), glow = true, metallic = 0 },
		} },
	[27] = { id = 27, key = "CrimsonTrio", name = "Trio cramoisi", world = 3, finish = "paint", multiplier = 470, file = "Rocket_27_CrimsonTrio",
		aura = { color = Color3.fromRGB(255, 176, 74), strength = 1.6 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "Body", color = Color3.fromRGB(214, 40, 40), glow = false, metallic = 0.15 },
			{ name = "Booster_1", color = Color3.fromRGB(214, 40, 40), glow = false, metallic = 0.15 },
			{ name = "Booster_2", color = Color3.fromRGB(214, 40, 40), glow = false, metallic = 0.15 },
			{ name = "BoosterFlame_1", color = Color3.fromRGB(255, 176, 74), glow = true, metallic = 0 },
			{ name = "BoosterFlame_2", color = Color3.fromRGB(255, 176, 74), glow = true, metallic = 0 },
			{ name = "BoosterNose_1", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "BoosterNose_2", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "BoosterNozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "BoosterNozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Fin_1", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 176, 74), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(255, 210, 122), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
		} },
	[28] = { id = 28, key = "ScarletSpear", name = "Épieu écarlate", world = 3, finish = "chrome", multiplier = 600, file = "Rocket_28_ScarletSpear",
		aura = { color = Color3.fromRGB(255, 77, 77), strength = 1.7 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(214, 40, 40), glow = false, metallic = 1 },
			{ name = "Band_2", color = Color3.fromRGB(255, 77, 77), glow = true, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(214, 40, 40), glow = false, metallic = 1 },
			{ name = "Fin_1", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_2", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_3", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_4", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 77, 77), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 77, 77), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(255, 77, 77), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(255, 77, 77), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 77, 77), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(255, 210, 122), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
		} },
	[29] = { id = 29, key = "GoldenHawk", name = "Faucon doré", world = 3, finish = "paint", multiplier = 750, file = "Rocket_29_GoldenHawk",
		aura = { color = Color3.fromRGB(255, 176, 74), strength = 1.8 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(214, 40, 40), glow = false, metallic = 0.15 },
			{ name = "Cockpit", color = Color3.fromRGB(255, 210, 122), glow = true, metallic = 0 },
			{ name = "Fin_1", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 176, 74), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 176, 74), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 176, 74), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Spike_1", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
			{ name = "Spike_2", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 0.15 },
		} },
	[30] = { id = 30, key = "AureateHalo", name = "Halo auréolé", world = 3, finish = "chrome", multiplier = 950, file = "Rocket_30_AureateHalo",
		aura = { color = Color3.fromRGB(255, 211, 90), strength = 2 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 1 },
			{ name = "Fin_1", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "Fin_2", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "Fin_3", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Halo_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Halo_2", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(255, 210, 122), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
		} },
	[31] = { id = 31, key = "ShadowStriker", name = "Frappeur d'ombre", world = 4, finish = "matte", multiplier = 1300, file = "Rocket_31_ShadowStriker",
		aura = { color = Color3.fromRGB(255, 47, 168), strength = 2.1 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 47, 168), glow = true, metallic = 0 },
			{ name = "Band_2", color = Color3.fromRGB(255, 47, 168), glow = true, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(21, 22, 28), glow = false, metallic = 0 },
			{ name = "Fin_1", color = Color3.fromRGB(42, 44, 54), glow = false, metallic = 0 },
			{ name = "Fin_2", color = Color3.fromRGB(42, 44, 54), glow = false, metallic = 0 },
			{ name = "Fin_3", color = Color3.fromRGB(42, 44, 54), glow = false, metallic = 0 },
			{ name = "Fin_4", color = Color3.fromRGB(42, 44, 54), glow = false, metallic = 0 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 47, 168), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 47, 168), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(255, 47, 168), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(255, 47, 168), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 47, 168), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(42, 44, 54), glow = false, metallic = 0 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(255, 47, 168), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 47, 168), glow = false, metallic = 0 },
		} },
	[32] = { id = 32, key = "VoidSaucer", name = "Soucoupe du vide", world = 4, finish = "matte", multiplier = 1700, file = "Rocket_32_VoidSaucer",
		aura = { color = Color3.fromRGB(94, 242, 255), strength = 2.2 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(21, 22, 28), glow = false, metallic = 0 },
			{ name = "Dome", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Flame_2", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Flame_3", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(21, 22, 28), glow = false, metallic = 0 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_3", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Saucer", color = Color3.fromRGB(31, 34, 48), glow = false, metallic = 0 },
			{ name = "SaucerGlow", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_1", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_10", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_2", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_3", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_4", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_5", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_6", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_7", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_8", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "SaucerLight_9", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
		} },
	[33] = { id = 33, key = "AmethystShard", name = "Éclat d'améthyste", world = 4, finish = "crystal", multiplier = 2200, file = "Rocket_33_AmethystShard",
		aura = { color = Color3.fromRGB(255, 106, 213), strength = 2.3 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(162, 59, 255), glow = false, metallic = 0.3 },
			{ name = "Fin_1", color = Color3.fromRGB(122, 43, 214), glow = false, metallic = 0.3 },
			{ name = "Fin_2", color = Color3.fromRGB(122, 43, 214), glow = false, metallic = 0.3 },
			{ name = "Fin_3", color = Color3.fromRGB(122, 43, 214), glow = false, metallic = 0.3 },
			{ name = "Fin_4", color = Color3.fromRGB(122, 43, 214), glow = false, metallic = 0.3 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(199, 125, 255), glow = false, metallic = 0.3 },
			{ name = "Nozzle_1", color = Color3.fromRGB(42, 44, 54), glow = false, metallic = 0.9 },
			{ name = "Spike_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Spike_2", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Spike_3", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Spike_4", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
		} },
	[34] = { id = 34, key = "ObsidianFang", name = "Croc d'obsidienne", world = 4, finish = "crystal", multiplier = 2900, file = "Rocket_34_ObsidianFang",
		aura = { color = Color3.fromRGB(162, 59, 255), strength = 2.3 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(162, 59, 255), glow = true, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(26, 16, 38), glow = false, metallic = 0.3 },
			{ name = "Fin_1", color = Color3.fromRGB(42, 24, 64), glow = false, metallic = 0.3 },
			{ name = "Fin_2", color = Color3.fromRGB(42, 24, 64), glow = false, metallic = 0.3 },
			{ name = "Fin_3", color = Color3.fromRGB(42, 24, 64), glow = false, metallic = 0.3 },
			{ name = "FinGlow_1", color = Color3.fromRGB(162, 59, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(162, 59, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(162, 59, 255), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(162, 59, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(42, 24, 64), glow = false, metallic = 0.3 },
			{ name = "Nozzle_1", color = Color3.fromRGB(42, 44, 54), glow = false, metallic = 0.9 },
		} },
	[35] = { id = 35, key = "CyanHalo", name = "Halo cyan", world = 4, finish = "chrome", multiplier = 3800, file = "Rocket_35_CyanHalo",
		aura = { color = Color3.fromRGB(94, 242, 255), strength = 2.4 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 1 },
			{ name = "Fin_1", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_2", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_3", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Fin_4", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "FinGlow_1", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Halo_1", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(201, 206, 214), glow = false, metallic = 1 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(94, 242, 255), glow = false, metallic = 1 },
		} },
	[36] = { id = 36, key = "InfernoFighter", name = "Chasseur infernal", world = 4, finish = "paint", multiplier = 5000, file = "Rocket_36_InfernoFighter",
		aura = { color = Color3.fromRGB(255, 138, 31), strength = 2.5 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 138, 31), glow = true, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(214, 40, 40), glow = false, metallic = 0.15 },
			{ name = "Cockpit", color = Color3.fromRGB(255, 210, 122), glow = true, metallic = 0 },
			{ name = "Fin_1", color = Color3.fromRGB(181, 30, 30), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(181, 30, 30), glow = false, metallic = 0.15 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 138, 31), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 138, 31), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 138, 31), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(255, 138, 31), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Spike_1", color = Color3.fromRGB(255, 138, 31), glow = true, metallic = 0 },
			{ name = "Spike_2", color = Color3.fromRGB(255, 138, 31), glow = true, metallic = 0 },
		} },
	[37] = { id = 37, key = "SolarCrown", name = "Couronne solaire", world = 4, finish = "chrome", multiplier = 6500, file = "Rocket_37_SolarCrown",
		aura = { color = Color3.fromRGB(255, 211, 90), strength = 2.6 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 1 },
			{ name = "Fin_1", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "Fin_2", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "Fin_3", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "Fin_4", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Halo_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Halo_2", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(217, 165, 32), glow = false, metallic = 1 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(255, 210, 122), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(255, 211, 90), glow = false, metallic = 1 },
		} },
	[38] = { id = 38, key = "GlacierCrystal", name = "Cristal glacier", world = 4, finish = "crystal", multiplier = 8500, file = "Rocket_38_GlacierCrystal",
		aura = { color = Color3.fromRGB(94, 242, 255), strength = 2.7 },
		parts = {
			{ name = "Body", color = Color3.fromRGB(47, 123, 255), glow = false, metallic = 0.3 },
			{ name = "Fin_1", color = Color3.fromRGB(30, 79, 204), glow = false, metallic = 0.3 },
			{ name = "Fin_2", color = Color3.fromRGB(30, 79, 204), glow = false, metallic = 0.3 },
			{ name = "Fin_3", color = Color3.fromRGB(30, 79, 204), glow = false, metallic = 0.3 },
			{ name = "Fin_4", color = Color3.fromRGB(30, 79, 204), glow = false, metallic = 0.3 },
			{ name = "FinGlow_1", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(143, 227, 255), glow = false, metallic = 0.3 },
			{ name = "Nozzle_1", color = Color3.fromRGB(42, 44, 54), glow = false, metallic = 0.9 },
			{ name = "Spike_1", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Spike_2", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Spike_3", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
			{ name = "Spike_4", color = Color3.fromRGB(94, 242, 255), glow = true, metallic = 0 },
		} },
	[39] = { id = 39, key = "NebulaLance", name = "Lance nébuleuse", world = 4, finish = "paint", multiplier = 11000, file = "Rocket_39_NebulaLance",
		aura = { color = Color3.fromRGB(255, 106, 213), strength = 2.8 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Band_2", color = Color3.fromRGB(122, 43, 214), glow = false, metallic = 0.15 },
			{ name = "Body", color = Color3.fromRGB(122, 43, 214), glow = false, metallic = 0.15 },
			{ name = "Fin_1", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_2", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_3", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Fin_4", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "FinGlow_3", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "FinGlow_4", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Halo_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Window_1", color = Color3.fromRGB(255, 106, 213), glow = true, metallic = 0 },
			{ name = "WindowFrame_1", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 0.15 },
		} },
	[40] = { id = 40, key = "UltimateLegend", name = "Légende ultime", world = 4, finish = "chrome", multiplier = 15000, file = "Rocket_40_UltimateLegend",
		aura = { color = Color3.fromRGB(255, 211, 90), strength = 3 },
		parts = {
			{ name = "Band_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Body", color = Color3.fromRGB(244, 244, 244), glow = false, metallic = 1 },
			{ name = "Cockpit", color = Color3.fromRGB(255, 210, 122), glow = true, metallic = 0 },
			{ name = "Fin_1", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 1 },
			{ name = "Fin_2", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 1 },
			{ name = "FinGlow_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "FinGlow_2", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Flame_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Flame_2", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Flame_3", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Halo_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Halo_2", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Nose", color = Color3.fromRGB(241, 200, 90), glow = false, metallic = 1 },
			{ name = "Nozzle_1", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_2", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Nozzle_3", color = Color3.fromRGB(58, 58, 58), glow = false, metallic = 0.9 },
			{ name = "Spike_1", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
			{ name = "Spike_2", color = Color3.fromRGB(255, 211, 90), glow = true, metallic = 0 },
		} },
}

local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	return
end

local function run()
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
end

local toolbar = plugin:CreateToolbar("Fusées")
local button = toolbar:CreateButton("Importer les 40 fusées", "Importe les FBX et applique couleurs et auras", "rbxassetid://4458901886")
button.ClickableWhenViewportHidden = true
button.Click:Connect(function()
	print("[Fusées] import en cours…")
	local ok, err = pcall(run)
	if not ok then
		warn("[Fusées] " .. tostring(err))
	end
end)
