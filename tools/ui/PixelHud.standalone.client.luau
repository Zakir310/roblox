--!nocheck
-- PixelHud.standalone.client.luau — GÉNÉRÉ par tools/ui/build_standalone.py, ne pas éditer à la main
-- (modifie les fichiers de src/ puis relance le script).
--
-- Interface « pixel cubique » en un seul LocalScript, pour l'utiliser sans Rojo :
--   1. Dans Studio : StarterPlayer > StarterPlayerScripts > + > LocalScript, nomme-le PixelHud.
--   2. Colle tout ce fichier dedans, puis Play.
--   3. Pour tes icônes : modifie la section CONFIGURATION juste en dessous (champ `image`).
--   4. Pour brancher les boutons, ajoute ton code TOUT EN BAS, après HudController.Start() :
--        HudController.On("Rebirth", function() ... end)
-- N'utilise pas ce script ET la version Rojo (src/client) en même temps : choisis l'une ou l'autre.

local __modules = {}

----------------------------------------------------------------------------------------------------
-- CONFIGURATION — icônes, textes, couleurs  (source : src/shared/Config/Hud.luau)
----------------------------------------------------------------------------------------------------
__modules.HudConfig = (function()
-- Hud.luau — configuration de l'interface « pixel cubique » (colonne de boutons à gauche, compteurs en bas
-- à gauche, barre de puissance en bas au centre).
--
-- C'est LE fichier à modifier pour changer les icônes, les textes, les couleurs et les badges.
--
-- ICÔNES : chaque icône est `{ image = "rbxassetid://…", emoji = "🛒" }`.
--   - Tant que `image` est vide, l'emoji sert d'icône provisoire.
--   - Importe ton image dans Studio (Asset Manager → Import, ou Creator Hub → Images), copie son ID
--     et colle-le dans `image`, par exemple `image = "rbxassetid://1234567890"`.

type Palette = { top: Color3, bottom: Color3, lip: Color3 }
type IconDef = { image: string?, emoji: string? }
type BadgeDef = { text: string, palette: string?, rotation: number? }
type ButtonDef = {
	id: string, -- nom interne (sert à brancher le clic : HudController.OnButton("Shop", …))
	label: string, -- texte affiché sur le bouton
	palette: string, -- clé dans Hud.Palettes
	row: number, -- rangée (1 = en haut)
	col: number, -- colonne (1 = gauche)
	span: number?, -- nombre de colonnes occupées (2 pour le gros bouton Shop)
	icon: IconDef,
	badge: BadgeDef?, -- étiquette en haut à droite (« HOT! », « SOON », « 99% »)
	comingSoon: boolean?, -- clic → message « Coming soon! »
	rays: boolean?, -- rayons lumineux qui tournent derrière l'icône
}

local Hud = {}

local hex = Color3.fromHex

-- Couleurs relevées sur la capture : haut du dégradé, bas du dégradé, rebord 3D sous le bouton.
Hud.Palettes = {
	Amber = { top = hex("#FDBE04"), bottom = hex("#FD8F03"), lip = hex("#B85A00") },
	Purple = { top = hex("#C234F8"), bottom = hex("#9918E5"), lip = hex("#5E00B0") },
	Sky = { top = hex("#28C2FA"), bottom = hex("#119FED"), lip = hex("#0564AF") },
	Orange = { top = hex("#F79E08"), bottom = hex("#DB7205"), lip = hex("#8F4600") },
	Blue = { top = hex("#03AFFD"), bottom = hex("#036CFA"), lip = hex("#003BB3") },
	Lime = { top = hex("#A2F808"), bottom = hex("#5ADB0A"), lip = hex("#129E00") },
	Magenta = { top = hex("#EC27DF"), bottom = hex("#B018F0"), lip = hex("#6B04B7") },
	Gold = { top = hex("#FADD08"), bottom = hex("#FD9505"), lip = hex("#B85A00") },
	Red = { top = hex("#F7271C"), bottom = hex("#DF0F14"), lip = hex("#8F0010") },
	BadgeRed = { top = hex("#FB2A33"), bottom = hex("#D90511"), lip = hex("#A4030D") },
	BadgeBlue = { top = hex("#2ECDFE"), bottom = hex("#0EA1F1"), lip = hex("#0564AF") },
	BadgeGreen = { top = hex("#5EEB3C"), bottom = hex("#25B51C"), lip = hex("#127A0C") },
	Locked = { top = hex("#9A9AAE"), bottom = hex("#6E6E84"), lip = hex("#4A4A5C") },
	Bar = { top = hex("#00BEFF"), bottom = hex("#0064FF"), lip = hex("#003BB3") },
} :: { [string]: Palette }

-- Les 9 boutons, dans la disposition de la capture.
Hud.Buttons = {
	{
		id = "Shop", label = "Shop", palette = "Amber", row = 1, col = 1, span = 2, rays = true,
		icon = { image = "", emoji = "🛒" },
		badge = { text = "HOT!", palette = "BadgeRed", rotation = -8 },
	},
	{
		id = "Auras", label = "Auras", palette = "Purple", row = 2, col = 1, comingSoon = true,
		icon = { image = "", emoji = "🔥" },
		badge = { text = "SOON", palette = "BadgeRed", rotation = -5 },
	},
	{
		-- Le badge du Rebirth affiche automatiquement la progression (Power / coût du rebirth).
		id = "Rebirth", label = "Rebirth", palette = "Sky", row = 2, col = 2,
		icon = { image = "", emoji = "🔄" },
		badge = { text = "0%", palette = "BadgeBlue", rotation = -5 },
	},
	{
		id = "Pets", label = "Pets", palette = "Orange", row = 3, col = 1, comingSoon = true,
		icon = { image = "", emoji = "🐾" },
		badge = { text = "SOON", palette = "BadgeRed", rotation = -5 },
	},
	{
		id = "Trails", label = "Trails", palette = "Blue", row = 3, col = 2, comingSoon = true,
		icon = { image = "", emoji = "✨" },
		badge = { text = "SOON", palette = "BadgeRed", rotation = -5 },
	},
	{
		id = "Backpack", label = "Backpack", palette = "Lime", row = 4, col = 1,
		icon = { image = "", emoji = "🎒" },
	},
	{
		id = "Gifts", label = "Gifts", palette = "Magenta", row = 4, col = 2, comingSoon = true,
		icon = { image = "", emoji = "🎁" },
		badge = { text = "SOON", palette = "BadgeRed", rotation = -5 },
	},
	{
		id = "Index", label = "Index", palette = "Gold", row = 5, col = 1,
		icon = { image = "", emoji = "📘" },
	},
	{
		id = "Settings", label = "Settings", palette = "Red", row = 5, col = 2,
		icon = { image = "", emoji = "⚙️" },
	},
} :: { ButtonDef }

-- Icônes des compteurs du bas.
Hud.StatIcons = {
	Rebirths = { image = "", emoji = "🔄" },
	Wins = { image = "", emoji = "🏆" },
	Power = { image = "", emoji = "💪" },
} :: { [string]: IconDef }

-- Disposition de la colonne de gauche. Une « case » = la taille d'un bouton carré.
Hud.Layout = {
	Columns = 2,
	Gap = 0.1, -- espace entre deux boutons, en cases
	RowHeights = { [1] = 0.76 } :: { [number]: number }, -- hauteur des rangées en cases (1 par défaut)
	HeightOfScreen = 0.59, -- hauteur de la colonne / hauteur de l'écran
	HeightOfScreenSmall = 0.7, -- idem sur petit écran (téléphone)
	SmallScreenHeight = 520, -- en dessous de cette hauteur (pixels), on considère un petit écran
	CenterY = 0.41, -- centre vertical de la colonne (0 = haut, 1 = bas)
	Margin = 10, -- marge au bord de l'écran, en pixels
}

-- Style visuel. Toutes les tailles sont en cases (fraction de la taille d'un bouton carré).
Hud.Style = {
	ButtonFont = Font.fromEnum(Enum.Font.GothamBlack),
	StatFont = Font.fromEnum(Enum.Font.FredokaOne),
	Outline = Color3.new(0, 0, 0),
	OutlineCells = 0.04, -- épaisseur du contour noir
	CornerCells = 0.1, -- arrondi des coins
	LipCells = 0.095, -- hauteur du rebord 3D sombre en bas du bouton
	StudPitch = 0.195, -- espacement des cubes en relief (effet pixel cubique)
	StudSize = 0.6, -- taille d'un cube / espacement
	LabelCells = 0.17, -- taille du texte des boutons carrés
	WideLabelCells = 0.32, -- taille du texte du gros bouton (Shop)
	TextStroke = 0.13, -- épaisseur du contour des textes / hauteur du texte
	IconCells = 0.72, -- taille de l'icône
	RayColor = Color3.fromRGB(255, 246, 170),
	ShineEvery = NumberRange.new(3.5, 7), -- secondes entre deux reflets automatiques
	SparkleEvery = NumberRange.new(1.8, 4), -- secondes entre deux étincelles automatiques
	HoverScale = 1.07, -- grossissement du bouton au survol
	IconHoverScale = 1.18, -- grossissement de l'icône au survol
	IconWiggle = 11, -- angle (degrés) du balancement de l'icône au survol
	CubeColors = { Color3.fromRGB(255, 230, 0), Color3.new(1, 1, 1) } :: { Color3 }, -- + couleurs du bouton
}

-- Textes affichés.
Hud.Texts = {
	Power = "%s POWER",
	Boost = "x%s Boost",
	BarLeft = "Rebirth %s",
	BarRight = "%s/%s Power",
	ComingSoon = "%s coming soon!", -- message en haut de l'écran (%s = nom du bouton)
	Ready = "READY", -- badge du Rebirth quand la Power suffit
	-- Panneau Rebirth
	Before = "Before",
	After = "After",
	PowerTag = "POWER",
	Resets = "Resets your POWER!",
	RebirthPower = "%s/%s Power",
	RebirthButton = "Rebirth",
	SkipRebirth = "Skip Rebirth",
	NotEnoughPower = "Not enough Power!",
	NotEnoughWins = "Not enough Wins!",
	-- Panneaux Backpack / Index
	Category = "ROCKETS",
	Equip = "EQUIP",
	Equipped = "EQUIPPED",
	PowerStat = "POWER",
	PriceStat = "PRICE",
	Free = "FREE",
	Unknown = "???",
	Buy = "%s Wins",
	-- Panneau Settings
	Audio = "AUDIO",
	Gameplay = "GAMEPLAY",
	Music = "Music",
	MusicHint = "Background music",
	Sound = "Sound",
	SoundHint = "Splats and effects",
	ReducedMotion = "Reduced Motion",
	ReducedMotionHint = "Fewer flashes and effects",
	On = "ON",
	Off = "OFF",
}

-- Fenêtres (Rebirth, Backpack, Index, Settings).
Hud.Panel = {
	Background = hex("#ECECF8"), -- fond clair des fenêtres
	Blur = 16, -- flou du décor quand une fenêtre est ouverte (0 = pas de flou)
	-- Motif « plaque de briques » du fond : importe assets/ui/textures/brick_tile.png dans Roblox et colle
	-- son ID ici pour le rendu exact ; vide = quadrillage léger construit en code.
	BrickTile = "",
	BrickRatio = 0.026, -- taille d'une brique du fond / hauteur de la fenêtre
	CenterY = 0.47, -- centre vertical des fenêtres (0 = haut, 1 = bas)
	CellOfScreen = 0.114, -- taille d'une case (bouton carré du menu) en fraction de la hauteur d'écran
}

-- Couleur des cartes de fusées selon le monde (clés de Hud.Palettes).
Hud.WorldPalettes = { [1] = "Lime", [2] = "Blue", [3] = "Amber", [4] = "Magenta" } :: { [number]: string }

-- Icônes des fenêtres et des réglages.
Hud.PanelIcons = {
	Rocket = { image = "", emoji = "🚀" },
	Gear = { image = "", emoji = "⚙️" },
} :: { [string]: IconDef }

-- Réglages par défaut (panneau Settings).
Hud.Settings = {
	Music = 83, -- volume 0..100, appliqué au SoundGroup « Music » de SoundService s'il existe
	Sound = 61, -- volume 0..100, appliqué au SoundGroup « SFX » de SoundService s'il existe
	MusicGroup = "Music",
	SoundGroup = "SFX",
	ReducedMotion = false,
}

-- Boost après le prochain rebirth (panneau Rebirth, « After ») si le serveur ne pose pas l'attribut NextBoost.
function Hud.NextBoost(boost: number, _rebirths: number): number
	return boost + 0.5
end

-- Où lire les valeurs du joueur.
Hud.Stats = {
	Folder = "leaderstats",
	Wins = "Wins",
	Rebirths = "Rebirths",
	Power = "Power",
	BoostAttribute = "Boost", -- attribut numérique posé sur le Player par le serveur (ex. 10.5)
	RebirthCostAttribute = "RebirthCost", -- attribut numérique : Power nécessaire au prochain rebirth
	NextBoostAttribute = "NextBoost", -- attribut numérique : boost après le prochain rebirth
	OwnedAttribute = "OwnedRockets", -- attribut texte : ids des fusées possédées, ex. "1,2,5"
	EquippedAttribute = "EquippedRocket", -- attribut numérique : id de la fusée équipée
	ProgressButton = "Rebirth", -- bouton dont le badge affiche la progression du rebirth
	WaitForFolder = 4, -- secondes avant de passer en mode démo si leaderstats n'existe pas
}

-- Coût du prochain rebirth si le serveur ne pose pas l'attribut RebirthCost (formule provisoire).
function Hud.RebirthCost(rebirths: number): number
	return math.floor(1000 * 1.85 ^ rebirths)
end

-- Mode démo : tant que le jeu n'a pas de leaderstats, l'interface affiche les valeurs de la capture.
Hud.Demo = {
	Enabled = true,
	Wins = 9721,
	Rebirths = 19,
	Power = 157_000_000,
	Boost = 10.5,
	RebirthCost = 157_400_000,
	Owned = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
	Equipped = 1,
}

return Hud
end)()

----------------------------------------------------------------------------------------------------
-- Rockets  (source : src/shared/Config/Rockets.luau)
----------------------------------------------------------------------------------------------------
__modules.Rockets = (function()
-- Rockets.luau — catalogue des 40 fusées v2 (GÉNÉRÉ par tools/rockets/gen_luau.py, ne pas éditer).

type RocketPart = { name: string, color: Color3, kind: string }
type RocketAura = { color: Color3, strength: number }
type RocketDef = {
	id: number, key: string, name: string, world: number, height: number,
	multiplier: number, cost: number, file: string, aura: RocketAura, parts: { RocketPart },
}
type WorldDef = { id: number, name: string, subtitle: string, color: Color3 }

local Rockets = {}

-- (Luau n'accepte pas d'annotation de type sur un champ : `Rockets.X: T = …` ne compile pas, on caste.)
Rockets.Worlds = {
	{ id = 1, name = "Débutant", subtitle = "Fusées simples, bricolées et légères", color = Color3.fromRGB(56, 212, 48) },
	{ id = 2, name = "Technologie", subtitle = "Fusées améliorées, plus rapides et plus stables", color = Color3.fromRGB(48, 200, 255) },
	{ id = 3, name = "Expérimental", subtitle = "Fusées avancées, modules spéciaux et nouvelles énergies", color = Color3.fromRGB(255, 177, 59) },
	{ id = 4, name = "Légendaire", subtitle = "Fusées d'élite, ultra-performantes et à la technologie ultime", color = Color3.fromRGB(210, 59, 255) },
} :: { WorldDef }

Rockets.List = {
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
} :: { RocketDef }

Rockets.ById = {} :: { [number]: RocketDef }
Rockets.ByKey = {} :: { [string]: RocketDef }
for _, def in Rockets.List do
	Rockets.ById[def.id] = def
	Rockets.ByKey[def.key] = def
end

function Rockets.get(id: number): RocketDef?
	return Rockets.ById[id]
end

function Rockets.forWorld(world: number): { RocketDef }
	local out = {}
	for _, def in Rockets.List do
		if def.world == world then
			table.insert(out, def)
		end
	end
	return out
end

return Rockets
end)()

----------------------------------------------------------------------------------------------------
-- FormatNumber  (source : src/shared/Util/FormatNumber.luau)
----------------------------------------------------------------------------------------------------
__modules.FormatNumber = (function()
-- FormatNumber.luau — nombres abrégés façon simulateur : 9721 → « 9.7K », 157000000 → « 157M ».

local FormatNumber = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function trimDecimal(value: number): string
	-- Une décimale tronquée (jamais arrondie vers le haut : 9.99K reste 9.9K et non 10K).
	local truncated = math.floor(value * 10 + 1e-9) / 10
	local text = string.format("%.1f", truncated)
	return (string.gsub(text, "%.0$", ""))
end

-- 0..999 tels quels, puis une décimale sous 100 (9.7K, 15.3M) et entier au-delà (157M).
function FormatNumber.short(n: number): string
	if n ~= n or n == math.huge or n == -math.huge then
		return "0"
	end
	local sign = if n < 0 then "-" else ""
	local value = math.abs(n)
	if value < 1000 then
		return sign .. tostring(math.floor(value))
	end
	local index = 1
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	local digits = if value < 100 then trimDecimal(value) else tostring(math.floor(value))
	return sign .. digits .. SUFFIXES[index]
end

-- Multiplicateur : 10.5 → « 10.5 », 3 → « 3 », 1250 → « 1.2K ».
function FormatNumber.multiplier(n: number): string
	if n ~= n or n == math.huge or n == -math.huge then
		return "1"
	end
	if n >= 1000 then
		return FormatNumber.short(n)
	end
	return trimDecimal(n)
end

return FormatNumber
end)()

----------------------------------------------------------------------------------------------------
-- PixelFx  (source : src/client/UI/PixelFx.luau)
----------------------------------------------------------------------------------------------------
__modules.PixelFx = (function()
-- PixelFx.luau — briques visuelles de l'interface « pixel cubique » :
--   • cubes en relief sur les boutons (studs façon briques),
--   • reflet blanc qui balaie le bouton (effet brillant),
--   • rayons lumineux qui tournent, étincelles qui scintillent,
--   • explosion de petits cubes au clic, petit message flottant,
--   • textes contourés de noir dont l'épaisseur suit la taille de l'écran.
-- Aucune image à importer : tout est construit avec des Frames, UIGradient et UIStroke.

local TweenService = game:GetService("TweenService")

local PixelFx = {}

-- « Mouvements réduits » (réglage du panneau Settings) : coupe reflets, étincelles, cubes et animations en boucle.
PixelFx.reducedMotion = false
local loops: { Tween } = {}

-- Animation en boucle (rayons, balancement des badges) : mise en pause quand les mouvements sont réduits.
function PixelFx.loop(tween: Tween): Tween
	table.insert(loops, tween)
	if PixelFx.reducedMotion then
		tween:Pause()
	end
	return tween
end

function PixelFx.setReducedMotion(on: boolean)
	PixelFx.reducedMotion = on
	for index = #loops, 1, -1 do
		local loop = loops[index]
		if loop.PlaybackState == Enum.PlaybackState.Cancelled then
			table.remove(loops, index)
		elseif on then
			loop:Pause()
		else
			loop:Play()
		end
	end
end

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

local SHINE_INFO = TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local RAYS_INFO = TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)

local function kp(time: number, value: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(time, value)
end

-- Crée une instance et règle ses propriétés (Parent en dernier, pour ne répliquer qu'une fois).
function PixelFx.create(className: string, props: { [string]: any }): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if props.Parent ~= nil then
		instance.Parent = props.Parent
	end
	return instance
end
local create = PixelFx.create

function PixelFx.tween(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local tween = TweenService:Create(instance, info, goal)
	tween:Play()
	return tween
end
local tween = PixelFx.tween

function PixelFx.corner(parent: GuiObject, scale: number): UICorner
	return create("UICorner", { CornerRadius = UDim.new(scale, 0), Parent = parent })
end

-- Dégradé vertical (haut → bas). L'objet doit avoir BackgroundColor3 blanc.
function PixelFx.vgradient(parent: GuiObject, top: Color3, bottom: Color3): UIGradient
	return create("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = 90, Parent = parent })
end

-- Contour noir (bordure) dont on règle l'épaisseur à la main via `.Thickness`.
function PixelFx.border(parent: GuiObject, color: Color3?): UIStroke
	return create("UIStroke", {
		Color = color or BLACK,
		Thickness = 2,
		LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

type TextOpts = {
	parent: Instance,
	text: string,
	font: Font,
	position: UDim2,
	size: UDim2,
	anchor: Vector2?,
	color: Color3?,
	xAlign: Enum.TextXAlignment?,
	zIndex: number?,
	name: string?,
	strokeRatio: number?,
	maxSize: number?,
}

-- Texte blanc (ou coloré) avec un gros contour noir, comme sur la capture. Le texte s'adapte à sa boîte
-- (TextScaled) sans dépasser `maxSize` pixels ; on change ce plafond avec le UITextSizeConstraint renvoyé.
-- L'épaisseur du contour suit la hauteur réelle du texte.
function PixelFx.text(opts: TextOpts): (TextLabel, UITextSizeConstraint)
	local label: TextLabel = create("TextLabel", {
		Name = opts.name or "Text",
		BackgroundTransparency = 1,
		AnchorPoint = opts.anchor or Vector2.new(0.5, 0.5),
		Position = opts.position,
		Size = opts.size,
		FontFace = opts.font,
		Text = opts.text,
		TextScaled = true,
		TextWrapped = false,
		TextColor3 = opts.color or WHITE,
		TextXAlignment = opts.xAlign or Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = opts.zIndex or 1,
	})
	local limit: UITextSizeConstraint = create("UITextSizeConstraint", {
		MaxTextSize = math.max(1, math.floor(opts.maxSize or 100)),
		MinTextSize = 1,
		Parent = label,
	})
	local stroke: UIStroke = create("UIStroke", {
		Color = BLACK,
		LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = label,
	})
	local ratio = opts.strokeRatio or 0.13
	local function updateStroke()
		stroke.Thickness = math.max(1, math.floor(label.TextBounds.Y * ratio + 0.5))
	end
	label:GetPropertyChangedSignal("TextBounds"):Connect(updateStroke)
	updateStroke()
	label.Parent = opts.parent
	return label, limit
end

-- Icône : l'image si elle est renseignée, sinon l'emoji provisoire.
function PixelFx.icon(parent: Instance, icon: { image: string?, emoji: string? }, zIndex: number): GuiObject
	local image = icon.image
	if image ~= nil and image ~= "" then
		return create("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = zIndex,
			Parent = parent,
		})
	end
	return create("TextLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Text = icon.emoji or "?",
		TextScaled = true,
		FontFace = Font.fromEnum(Enum.Font.GothamBold),
		TextColor3 = WHITE,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = zIndex,
		Parent = parent,
	})
end

-- EFFET PIXEL CUBIQUE : grille de petits cubes en relief (éclairés en haut à droite, ombre en bas à
-- gauche). Les couleurs sont du blanc et du noir semi-transparents : les cubes prennent donc
-- automatiquement la teinte du dégradé du bouton.
-- `wCells`/`hCells` : taille du bouton en cases, `pitch` : espacement en cases, `sizeFrac` : taille / pitch.
function PixelFx.studs(face: GuiObject, wCells: number, hCells: number, pitch: number, sizeFrac: number, zIndex: number): Frame
	local cols = math.max(1, math.floor(wCells / pitch))
	local rows = math.max(1, math.floor(hCells / pitch))
	local studW = sizeFrac * pitch / wCells
	local studH = sizeFrac * pitch / hCells
	local holder: Frame = create("Frame", {
		Name = "Studs",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = zIndex,
		Parent = face,
	})
	local highlight = NumberSequence.new({ kp(0, 0.55), kp(0.4, 0.82), kp(1, 0.9) })
	for row = 1, rows do
		for col = 1, cols do
			local x = (col - 0.5) / cols
			local y = (row - 0.5) / rows
			create("Frame", {
				Name = "Shadow",
				BackgroundColor3 = BLACK,
				BackgroundTransparency = 0.8,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x - studW * 0.14, y + studH * 0.16),
				Size = UDim2.fromScale(studW, studH),
				ZIndex = 1,
				Parent = holder,
			})
			local stud = create("Frame", {
				Name = "Stud",
				BackgroundColor3 = WHITE,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x, y),
				Size = UDim2.fromScale(studW, studH),
				ZIndex = 2,
				Parent = holder,
			})
			PixelFx.corner(stud, 0.22)
			-- Rotation 135 : le dégradé va du coin haut-droit (clair) au coin bas-gauche.
			create("UIGradient", { Rotation = 135, Transparency = highlight, Parent = stud })
		end
	end
	return holder
end

-- Reflet doux sur le haut du bouton.
function PixelFx.gloss(face: GuiObject, zIndex: number): Frame
	local gloss: Frame = create("Frame", {
		Name = "Gloss",
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0.5),
		ZIndex = zIndex,
		Parent = face,
	})
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ kp(0, 0.72), kp(0.25, 0.86), kp(1, 1) }),
		Parent = gloss,
	})
	return gloss
end

-- EFFET BRILLANT : bande blanche inclinée qui traverse le bouton. Renvoie la fonction qui lance un passage.
-- La bande doit être dans un CanvasGroup arrondi pour ne pas déborder des coins.
function PixelFx.shine(face: GuiObject, wCells: number, hCells: number, zIndex: number): () -> ()
	local bandW = 0.34 / wCells
	local margin = (0.3 + 0.45 * hCells) / wCells
	local band: Frame = create("Frame", {
		Name = "Shine",
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(-margin, 0.5),
		Size = UDim2.fromScale(bandW, 2.4),
		Rotation = 18,
		ZIndex = zIndex,
		Parent = face,
	})
	create("UIGradient", {
		Transparency = NumberSequence.new({ kp(0, 1), kp(0.35, 0.6), kp(0.5, 0.3), kp(0.65, 0.6), kp(1, 1) }),
		Parent = band,
	})
	local current: Tween? = nil
	return function()
		if PixelFx.reducedMotion then
			return
		end
		if current then
			current:Cancel()
		end
		band.Position = UDim2.fromScale(-margin, 0.5)
		current = tween(band, SHINE_INFO, { Position = UDim2.fromScale(1 + margin, 0.5) })
	end
end

-- Rayons lumineux qui tournent lentement (derrière l'icône du Shop).
function PixelFx.rays(face: GuiObject, center: UDim2, size: UDim2, color: Color3, zIndex: number): Frame
	local holder: Frame = create("Frame", {
		Name = "Rays",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = center,
		Size = size,
		ZIndex = zIndex,
		Parent = face,
	})
	create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = holder })
	local fade = NumberSequence.new({ kp(0, 1), kp(0.28, 0.6), kp(0.5, 0.45), kp(0.72, 0.6), kp(1, 1) })
	for i = 0, 5 do
		local bar = create("Frame", {
			Name = "Ray",
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.08, 1),
			Rotation = i * 30,
			ZIndex = zIndex,
			Parent = holder,
		})
		create("UIGradient", { Rotation = 90, Transparency = fade, Parent = bar })
	end
	PixelFx.loop(tween(holder, RAYS_INFO, { Rotation = 360 }))
	return holder
end

-- Étincelle (croix lumineuse à 4 branches). Invisible tant qu'on ne la fait pas scintiller.
function PixelFx.sparkle(parent: Instance, zIndex: number): Frame
	local holder: Frame = create("Frame", {
		Name = "Sparkle",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0, 0),
		ZIndex = zIndex,
		Parent = parent,
	})
	create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = holder })
	local taper = NumberSequence.new({ kp(0, 1), kp(0.5, 0), kp(1, 1) })
	for _, vertical in { false, true } do
		local bar = create("Frame", {
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = if vertical then UDim2.fromScale(0.2, 1) else UDim2.fromScale(1, 0.2),
			ZIndex = zIndex,
			Parent = holder,
		})
		PixelFx.corner(bar, 0.5)
		create("UIGradient", { Rotation = if vertical then 90 else 0, Transparency = taper, Parent = bar })
	end
	local core = create("Frame", {
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.3, 0.3),
		ZIndex = zIndex,
		Parent = holder,
	})
	PixelFx.corner(core, 0.5)
	return holder
end

-- Fait scintiller une étincelle : elle grossit en tournant puis disparaît.
function PixelFx.twinkle(sparkle: Frame, position: UDim2, size: number, duration: number)
	if PixelFx.reducedMotion then
		return
	end
	sparkle.Position = position
	sparkle.Size = UDim2.fromScale(0, 0)
	sparkle.Rotation = 0
	tween(sparkle, TweenInfo.new(duration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
		Size = UDim2.fromScale(size, size),
	})
	tween(sparkle, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Rotation = 90 })
end

-- Éclaircit (amount > 0) ou assombrit (amount < 0) une couleur.
function PixelFx.shade(color: Color3, amount: number): Color3
	if amount >= 0 then
		return color:Lerp(WHITE, amount)
	end
	return color:Lerp(BLACK, -amount)
end

-- EXPLOSION DE CUBES : petits cubes contourés qui jaillissent d'un point (coordonnées écran) et
-- retombent en tournant. `unit` = taille d'une case en pixels.
function PixelFx.cubeBurst(layer: GuiObject, center: Vector2, unit: number, colors: { Color3 }, count: number?)
	if PixelFx.reducedMotion then
		return
	end
	local total = count or 12
	local origin = center - layer.AbsolutePosition
	for i = 1, total do
		local size = unit * (0.07 + math.random() * 0.07)
		local color = colors[math.random(1, #colors)]
		local cube: Frame = create("Frame", {
			Name = "Cube",
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(origin.X, origin.Y),
			Size = UDim2.fromOffset(size, size),
			Rotation = math.random(0, 90),
			ZIndex = 50,
			Parent = layer,
		})
		create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(PixelFx.shade(color, 0.25), PixelFx.shade(color, -0.25)),
			Parent = cube,
		})
		local outline = PixelFx.border(cube)
		outline.Thickness = math.max(1, math.floor(size * 0.14 + 0.5))

		local angle = (i / total) * math.pi * 2 + (math.random() - 0.5) * 0.6
		local distance = unit * (0.45 + math.random() * 0.5)
		local target = origin + Vector2.new(math.cos(angle), math.sin(angle) - 0.25) * distance
		local info = TweenInfo.new(0.45 + math.random() * 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local move = tween(cube, info, {
			Position = UDim2.fromOffset(target.X, target.Y),
			Rotation = cube.Rotation + math.random(-200, 200),
			Size = UDim2.fromOffset(size * 0.35, size * 0.35),
			BackgroundTransparency = 1,
		})
		tween(outline, info, { Transparency = 1 })
		move.Completed:Once(function()
			cube:Destroy()
		end)
	end
end

-- Style commun des blocs à cubes (mêmes champs que Hud.Style).
type BlockStyle = {
	OutlineCells: number,
	CornerCells: number,
	LipCells: number,
	StudPitch: number,
	StudSize: number,
	RayColor: Color3,
	Outline: Color3,
}

type Palette = { top: Color3, bottom: Color3, lip: Color3 }

type BlockOpts = {
	parent: Instance,
	palette: Palette,
	style: BlockStyle,
	wCells: number, -- largeur en cases (1 case = taille d'un bouton carré du menu)
	hCells: number,
	name: string?,
	position: UDim2?,
	size: UDim2?,
	anchor: Vector2?,
	zIndex: number?,
	studs: boolean?, -- false = face lisse
	rays: UDim2?, -- centre des rayons tournants (dans la face), nil = pas de rayons
}

type Block = {
	body: Frame,
	face: CanvasGroup,
	outline: UIStroke,
	playShine: () -> (),
	setPalette: (palette: Palette) -> (),
}

-- BLOC À CUBES : le « matériau » de toute l'interface (boutons, cartes, lignes de réglages).
-- Contour noir, dégradé, cubes en relief, reflet doux, rebord 3D sombre, bande de brillance.
-- L'épaisseur du contour suit la taille réelle du bloc.
function PixelFx.block(opts: BlockOpts): Block
	local style = opts.style
	local w, h = opts.wCells, opts.hCells
	local cornerScale = style.CornerCells / math.min(w, h)
	local body: Frame = create("Frame", {
		Name = opts.name or "Block",
		BackgroundColor3 = opts.palette.lip,
		BorderSizePixel = 0,
		AnchorPoint = opts.anchor or Vector2.new(0, 0),
		Position = opts.position or UDim2.fromScale(0, 0),
		Size = opts.size or UDim2.fromScale(1, 1),
		ZIndex = opts.zIndex or 1,
		Parent = opts.parent,
	})
	PixelFx.corner(body, cornerScale)
	local outline = PixelFx.border(body, style.Outline)

	local face: CanvasGroup = create("CanvasGroup", {
		Name = "Face",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = body,
	})
	PixelFx.corner(face, cornerScale)
	local fill = create("Frame", {
		Name = "Fill",
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = face,
	})
	local gradient = PixelFx.vgradient(fill, opts.palette.top, opts.palette.bottom)
	if opts.studs ~= false then
		PixelFx.studs(face, w, h, style.StudPitch, style.StudSize, 2)
	end
	-- Deux CanvasGroups : la face (dégradé + cubes, fixe, rendue une fois) et un calque avant
	-- (rayons, reflet, rebord, brillance) qui est le seul à être redessiné quand il s'anime.
	local front: CanvasGroup = create("CanvasGroup", {
		Name = "Front",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Parent = body,
	})
	PixelFx.corner(front, cornerScale)
	if opts.rays then
		PixelFx.rays(front, opts.rays, UDim2.fromScale(2, 2), style.RayColor, 3)
	end
	PixelFx.gloss(front, 4)
	local lip: Frame = create("Frame", {
		Name = "Lip",
		BackgroundColor3 = opts.palette.lip,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, math.min(0.3, style.LipCells / h)),
		ZIndex = 5,
		Parent = front,
	})
	local playShine = PixelFx.shine(front, w, h, 6)

	local function relayout()
		local cell = body.AbsoluteSize.Y / h
		if cell > 0 then
			outline.Thickness = math.max(1, math.floor(cell * style.OutlineCells + 0.5))
		end
	end
	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()

	return {
		body = body,
		face = face,
		outline = outline,
		playShine = playShine,
		setPalette = function(palette: Palette)
			body.BackgroundColor3 = palette.lip
			lip.BackgroundColor3 = palette.lip
			gradient.Color = ColorSequence.new(palette.top, palette.bottom)
		end,
	}
end

-- Motif « plaque de briques » pour le fond des fenêtres : une image en mosaïque si `tileImage` est
-- renseigné (rendu identique à la vidéo), sinon un quadrillage léger construit avec des Frames.
-- `tileRatio` = taille d'une brique / hauteur du motif.
function PixelFx.brickPattern(parent: GuiObject, tileImage: string?, tileRatio: number, aspect: number, zIndex: number): GuiObject
	if tileImage ~= nil and tileImage ~= "" then
		local image: ImageLabel = create("ImageLabel", {
			Name = "Pattern",
			BackgroundTransparency = 1,
			Image = tileImage,
			ScaleType = Enum.ScaleType.Tile,
			Size = UDim2.fromScale(1, 1),
			ZIndex = zIndex,
			Parent = parent,
		})
		local function resize()
			local tile = math.max(4, math.floor(image.AbsoluteSize.Y * tileRatio + 0.5))
			image.TileSize = UDim2.fromOffset(tile, tile)
		end
		image:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
		resize()
		return image
	end
	-- Quadrillage en échelle (jamais reconstruit, même quand la fenêtre s'anime) :
	-- un joint sombre d'1 px suivi d'une arête claire d'1 px tous les `tileRatio`.
	local holder: Frame = create("Frame", {
		Name = "Pattern",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = zIndex,
		Parent = parent,
	})
	local rows = math.max(1, math.floor(1 / tileRatio + 0.5))
	local cols = math.max(1, math.floor(aspect / tileRatio + 0.5))
	local function line(horizontal: boolean, at: number, pixel: number, color: Color3, transparency: number)
		create("Frame", {
			BackgroundColor3 = color,
			BackgroundTransparency = transparency,
			BorderSizePixel = 0,
			Position = if horizontal then UDim2.new(0, 0, at, pixel) else UDim2.new(at, pixel, 0, 0),
			Size = if horizontal then UDim2.new(1, 0, 0, 1) else UDim2.new(0, 1, 1, 0),
			ZIndex = zIndex,
			Parent = holder,
		})
	end
	for row = 1, rows - 1 do
		line(true, row / rows, -1, BLACK, 0.92)
		line(true, row / rows, 0, WHITE, 0.4)
	end
	for col = 1, cols - 1 do
		line(false, col / cols, -1, BLACK, 0.92)
		line(false, col / cols, 0, WHITE, 0.4)
	end
	return holder
end

-- Message centré en haut de l'écran (ex. « Trails coming soon! ») : apparaît en rebondissant,
-- reste un moment puis s'efface. Un nouveau message remplace le précédent.
local currentBanner: TextLabel? = nil
function PixelFx.banner(layer: GuiObject, text: string, font: Font, color: Color3?)
	if currentBanner then
		currentBanner:Destroy()
		currentBanner = nil
	end
	local height = layer.AbsoluteSize.Y * 0.045
	local label, _ = PixelFx.text({
		parent = layer,
		name = "Banner",
		text = text,
		font = font,
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.035),
		size = UDim2.fromOffset(height * 12, height * 0.7),
		maxSize = height,
		zIndex = 70,
		strokeRatio = 0.14,
	})
	currentBanner = label
	local stroke = label:FindFirstChildOfClass("UIStroke")
	tween(label, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(height * 12, height),
	})
	local fade = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.6)
	local vanish = tween(label, fade, { TextTransparency = 1 })
	if stroke then
		tween(stroke, fade, { Transparency = 1 })
	end
	vanish.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed then
			label:Destroy()
			if currentBanner == label then
				currentBanner = nil
			end
		end
	end)
end

-- Flèche blanche contourée (➜) construite sans image : une tige + une pointe triangulaire.
-- La pointe est un carré dont un dégradé de transparence à bord franc ne garde qu'une moitié.
function PixelFx.arrow(parent: Instance, position: UDim2, size: UDim2, zIndex: number): Frame
	local holder: Frame = create("Frame", {
		Name = "Arrow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = size,
		ZIndex = zIndex,
		Parent = parent,
	})
	create("UIAspectRatioConstraint", { AspectRatio = 1.3, Parent = holder })
	local half = NumberSequence.new({ kp(0, 1), kp(0.499, 1), kp(0.5, 0), kp(1, 0) })
	local function triangle(scale: number, color: Color3, z: number, baseX: number)
		local square = create("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(baseX, 0.5),
			Size = UDim2.fromScale(0.62 * scale, 0.8 * scale),
			Rotation = -45,
			ZIndex = z,
			Parent = holder,
		})
		create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = square })
		create("UIGradient", { Rotation = 45, Transparency = half, Parent = square })
	end
	local shaft = create("Frame", {
		Name = "Shaft",
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.04, 0.5),
		Size = UDim2.fromScale(0.5, 0.36),
		ZIndex = zIndex,
		Parent = holder,
	})
	PixelFx.corner(shaft, 0.25)
	local shaftStroke = PixelFx.border(shaft)
	triangle(1.15, BLACK, zIndex + 1, 0.57) -- contour de la pointe, décalé pour border aussi sa base
	triangle(0.85, WHITE, zIndex + 2, 0.62)
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		shaftStroke.Thickness = math.max(1, math.floor(holder.AbsoluteSize.Y * 0.07 + 0.5))
	end)
	return holder
end

type ProgressBar = {
	frame: Frame,
	set: (fraction: number, text: string) -> (),
}

-- Barre de progression bleue contourée, texte centré (fenêtre Rebirth, collection de l'Index, compteur
-- du Backpack). `palette` = couleurs du remplissage.
function PixelFx.progressBar(
	parent: Instance,
	position: UDim2,
	size: UDim2,
	anchor: Vector2,
	palette: Palette,
	font: Font,
	zIndex: number
): ProgressBar
	local bar: Frame = create("Frame", {
		Name = "ProgressBar",
		BackgroundColor3 = Color3.fromRGB(8, 30, 60),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		AnchorPoint = anchor,
		Position = position,
		Size = size,
		ZIndex = zIndex,
		Parent = parent,
	})
	PixelFx.corner(bar, 0.3)
	local outline = PixelFx.border(bar)
	local fill: CanvasGroup = create("CanvasGroup", {
		Name = "Fill",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0, 1),
		ZIndex = zIndex + 1,
		Parent = bar,
	})
	PixelFx.corner(fill, 0.3)
	local color = create("Frame", {
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = fill,
	})
	PixelFx.vgradient(color, palette.top, palette.bottom)
	PixelFx.gloss(fill, 2)
	local label, limit = PixelFx.text({
		parent = bar,
		name = "Text",
		text = "",
		font = font,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.94, 0.72),
		zIndex = zIndex + 2,
		strokeRatio = 0.12,
	})
	local function relayout()
		local height = bar.AbsoluteSize.Y
		if height > 0 then
			outline.Thickness = math.max(1, math.floor(height * 0.08 + 0.5))
			limit.MaxTextSize = math.max(1, math.floor(height * 0.6 + 0.5))
		end
	end
	bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()
	return {
		frame = bar,
		set = function(fraction: number, text: string)
			fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
			label.Text = text
		end,
	}
end

return PixelFx
end)()

----------------------------------------------------------------------------------------------------
-- PixelButton  (source : src/client/UI/PixelButton.luau)
----------------------------------------------------------------------------------------------------
__modules.PixelButton = (function()
-- PixelButton.luau — les boutons de l'interface, à l'identique de la capture et de la vidéo :
--   • PixelButton.new : un bouton du menu de gauche (icône + texte + badge « HOT! », « SOON », « READY ») ;
--   • PixelButton.action : un bouton texte des fenêtres (« Rebirth », « EQUIP », « X », « OFF »…).
-- Matière : contour noir épais, dégradé, cubes en relief, rebord 3D, reflet qui balaie (PixelFx.block).
-- Au survol : le bouton grossit ; dans le menu, l'icône se soulève, grossit, se balance et flotte.
-- Au clic : le bouton s'enfonce puis rebondit ; dans le menu, une gerbe de petits cubes jaillit de l'icône.
--
-- La zone cliquable (TextButton) garde toujours la taille de son emplacement ; seul le visuel à l'intérieur
-- grossit ou rétrécit. Sinon un clic près du bord pourrait être perdu quand le bouton rétrécit sous la souris.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local HudConfig = __modules.HudConfig
local PixelFx = __modules.PixelFx

local create = PixelFx.create
local tween = PixelFx.tween

local PixelButton = {}

-- Emplacement du bouton dans la colonne : position/taille en échelle, taille en cases (1 = bouton carré).
type Geometry = { position: UDim2, size: UDim2, wCells: number, hCells: number }

type Handle = {
	id: string,
	slot: Frame,
	button: TextButton,
	setBadge: (text: string?, palette: string?) -> (),
	setPulse: (on: boolean) -> (),
	onClick: (callback: () -> ()) -> (),
	shine: () -> (),
	reset: () -> (), -- annule survol / enfoncement (à appeler quand l'interface est cachée)
	getCellSize: () -> number,
}

local WHITE = Color3.new(1, 1, 1)

local HOVER_IN = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HOVER_OUT = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TILT = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local WIGGLE = TweenInfo.new(0.34, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local BOB = TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local PRESS = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_UP = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_BACK = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BADGE_WOBBLE = TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local BADGE_PULSE = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-- Badge : taille et position en cases.
local BADGE_W, BADGE_H = 0.54, 0.24
local BADGE_INSET_X, BADGE_Y = 0.2, 0.04

local function randomIn(range: NumberRange): number
	return range.Min + math.random() * (range.Max - range.Min)
end

local function lastInputIsTouch(): boolean
	return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

local function px(value: number): number
	return math.max(1, math.floor(value + 0.5))
end

-- Zone cliquable fixe + calque visuel animé à l'intérieur.
local function makeHitArea(slot: Frame, zIndex: number): (TextButton, Frame)
	local button: TextButton = create("TextButton", {
		Name = "Button",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = zIndex,
		Parent = slot,
	})
	local visual: Frame = create("Frame", {
		Name = "Visual",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = zIndex,
		Parent = button,
	})
	return button, visual
end

type Controller = {
	hovered: () -> boolean,
	setHover: (on: boolean) -> (),
	reset: () -> (),
	checkMouse: () -> (),
}

-- Comportement commun : survol (souris ou manette), enfoncement, relâchement même en dehors du bouton,
-- rebond au clic. `onHover` reçoit chaque changement de survol, `onActivated` chaque clic validé.
local function bindInput(
	button: TextButton,
	visual: Frame,
	hoverScale: number,
	onHover: (on: boolean) -> (),
	onActivated: () -> ()
): Controller
	local hovered = false
	local mouseHover = false -- survol venu de la souris : vérifié régulièrement (MouseLeave peut manquer)
	local lastPop = 0

	local function settle(info: TweenInfo)
		local rest = if hovered then hoverScale else 1
		tween(visual, info, { Size = UDim2.fromScale(rest, rest) })
	end

	local function setHover(on: boolean)
		if not on then
			mouseHover = false
		end
		if hovered == on then
			return
		end
		hovered = on
		settle(if on then HOVER_IN else HOVER_OUT)
		onHover(on)
	end

	local function release()
		if os.clock() - lastPop > 0.15 then
			settle(POP_BACK)
		end
	end

	button.MouseEnter:Connect(function()
		-- Un doigt déclenche aussi MouseEnter (sans MouseLeave ensuite) : on l'ignore.
		if lastInputIsTouch() then
			return
		end
		mouseHover = true
		setHover(true)
	end)
	button.MouseLeave:Connect(function()
		if mouseHover then
			setHover(false)
		end
	end)
	button.SelectionGained:Connect(function()
		setHover(true)
	end)
	button.SelectionLost:Connect(function()
		setHover(false)
	end)

	button.MouseButton1Down:Connect(function()
		tween(visual, PRESS, { Size = UDim2.fromScale(0.93, 0.93) })
		-- Relâché n'importe où (même hors du bouton) : le bouton reprend sa taille.
		local connection: RBXScriptConnection? = nil
		connection = UserInputService.InputEnded:Connect(function(input: InputObject)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
				if connection then
					connection:Disconnect()
				end
				release()
			end
		end)
	end)

	button.Activated:Connect(function()
		lastPop = os.clock()
		onActivated()
		local up = tween(visual, POP_UP, { Size = UDim2.fromScale(hoverScale * 1.07, hoverScale * 1.07) })
		up.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				settle(POP_BACK)
			end
		end)
	end)

	return {
		hovered = function(): boolean
			return hovered
		end,
		setHover = setHover,
		reset = function()
			setHover(false)
			visual.Size = UDim2.fromScale(1, 1)
		end,
		-- Annule le survol si la souris n'est plus sur le bouton (MouseLeave manqué).
		checkMouse = function()
			if not mouseHover then
				return
			end
			local mouse = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
			local position, size = button.AbsolutePosition, button.AbsoluteSize
			if
				mouse.X < position.X
				or mouse.Y < position.Y
				or mouse.X > position.X + size.X
				or mouse.Y > position.Y + size.Y
			then
				setHover(false)
			end
		end,
	}
end

local function isHidden(instance: Instance): boolean
	local gui = instance:FindFirstAncestorOfClass("ScreenGui")
	return gui ~= nil and not gui.Enabled
end

function PixelButton.new(def: HudConfig.ButtonDef, parent: Instance, geom: Geometry, fxLayer: GuiObject): Handle
	local style = HudConfig.Style
	local palette = HudConfig.Palettes[def.palette] or HudConfig.Palettes.Amber
	local w, h = geom.wCells, geom.hCells
	local wide = w > h * 1.5

	-- Emplacement fixe dans la grille.
	local slot: Frame = create("Frame", {
		Name = def.id,
		BackgroundTransparency = 1,
		Position = geom.position,
		Size = geom.size,
		Parent = parent,
	})
	local button, visual = makeHitArea(slot, 1)

	-- Taille d'une case en pixels.
	local function cellSize(): number
		return slot.AbsoluteSize.Y / h
	end

	-- Corps : bloc à cubes (contour noir, dégradé, cubes en relief, rebord 3D, reflet).
	local iconCenter = if wide then Vector2.new(0.58 / w, 0.47) else Vector2.new(0.5, 0.4)
	local block = PixelFx.block({
		parent = visual,
		name = "Body",
		palette = palette,
		style = style,
		wCells = w,
		hCells = h,
		rays = if def.rays then UDim2.fromScale(iconCenter.X, iconCenter.Y) else nil,
	})
	local playShine = block.playShine

	-- Icône (au-dessus du corps, elle peut déborder un peu comme sur la capture).
	local icon = PixelFx.icon(visual, def.icon, 3)
	local restPos = UDim2.fromScale(iconCenter.X, iconCenter.Y)
	local restSize = UDim2.fromScale(style.IconCells / w, style.IconCells / h)
	local liftPos = UDim2.fromScale(iconCenter.X, iconCenter.Y - 0.07 / h)
	local bobPos = UDim2.fromScale(iconCenter.X, iconCenter.Y - 0.025 / h)
	local liftSize = UDim2.fromScale(restSize.X.Scale * style.IconHoverScale, restSize.Y.Scale * style.IconHoverScale)
	icon.Position = restPos
	icon.Size = restSize

	-- Texte du bouton.
	local labelPos = if wide then UDim2.fromScale(1.33 / w, 0.47) else UDim2.fromScale(0.5, 0.82)
	local labelSize = if wide then UDim2.fromScale(1.2 / w, 0.5 / h) else UDim2.fromScale(0.97, 0.27 / h)
	local labelCells = if wide then style.WideLabelCells else style.LabelCells
	local _, labelLimit = PixelFx.text({
		parent = visual,
		name = "Label",
		text = def.label,
		font = style.ButtonFont,
		position = labelPos,
		size = labelSize,
		zIndex = 4,
		strokeRatio = style.TextStroke,
	})

	-- Badge penché en haut à droite.
	local badgeFrame: Frame? = nil
	local badgeLabel: TextLabel? = nil
	local badgeLimit: UITextSizeConstraint? = nil
	local badgeOutline: UIStroke? = nil
	local badgeGradient: UIGradient? = nil
	local badgeSize = UDim2.fromScale(BADGE_W / w, BADGE_H / h)
	local badgeDef = def.badge
	if badgeDef then
		local badgePalette = HudConfig.Palettes[badgeDef.palette or "BadgeRed"] or HudConfig.Palettes.BadgeRed
		local rotation = badgeDef.rotation or -6
		local frame: Frame = create("Frame", {
			Name = "Badge",
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale((w - BADGE_INSET_X) / w, BADGE_Y / h),
			Size = badgeSize,
			Rotation = rotation - 3,
			ZIndex = 6,
			Parent = visual,
		})
		badgeGradient = PixelFx.vgradient(frame, badgePalette.top, badgePalette.bottom)
		PixelFx.corner(frame, 0.3)
		badgeOutline = PixelFx.border(frame)
		local label, limit = PixelFx.text({
			parent = frame,
			name = "Text",
			text = badgeDef.text,
			font = style.ButtonFont,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.86, 0.82),
			zIndex = 7,
			strokeRatio = 0.14,
		})
		PixelFx.loop(tween(frame, BADGE_WOBBLE, { Rotation = rotation + 3 }))
		badgeFrame, badgeLabel, badgeLimit = frame, label, limit
	end

	-- Étincelles réutilisées (3 par bouton).
	local sparkles = { PixelFx.sparkle(visual, 8), PixelFx.sparkle(visual, 8), PixelFx.sparkle(visual, 8) }
	local sparkleIndex = 1
	local function twinkleOne()
		local sparkle = sparkles[sparkleIndex]
		sparkleIndex = sparkleIndex % #sparkles + 1
		local angle = math.random() * math.pi * 2
		local radius = 0.26 + math.random() * 0.18 -- en cases, autour de l'icône
		local position = UDim2.fromScale(
			iconCenter.X + math.cos(angle) * radius / w,
			iconCenter.Y + math.sin(angle) * radius / h
		)
		PixelFx.twinkle(sparkle, position, (0.16 + math.random() * 0.12) / h, 0.55 + math.random() * 0.25)
	end

	-- Tailles de texte et contours en pixels, recalculés quand l'écran change de taille.
	local function relayout()
		local cell = cellSize()
		if cell <= 0 then
			return
		end
		labelLimit.MaxTextSize = px(cell * labelCells)
		if badgeLimit then
			badgeLimit.MaxTextSize = px(cell * 0.145)
		end
		if badgeOutline then
			badgeOutline.Thickness = px(cell * 0.026)
		end
	end
	slot:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()

	-- SURVOL : l'icône bouge.
	local hoverToken = 0
	local loops: { Tween } = {}

	local function iconHover(on: boolean)
		hoverToken += 1
		local token = hoverToken
		for _, loop in loops do
			loop:Cancel()
		end
		table.clear(loops)
		if not on then
			tween(icon, HOVER_OUT, { Position = restPos, Size = restSize, Rotation = 0 })
			return
		end
		local lift = tween(icon, HOVER_IN, { Position = liftPos, Size = liftSize })
		local tilt = tween(icon, TILT, { Rotation = -style.IconWiggle })
		-- Une fois penchée, l'icône se balance de gauche à droite tant que le survol dure…
		tilt.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and token == hoverToken and not PixelFx.reducedMotion then
				table.insert(loops, tween(icon, WIGGLE, { Rotation = style.IconWiggle }))
			end
		end)
		-- … et flotte doucement de haut en bas.
		lift.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and token == hoverToken and not PixelFx.reducedMotion then
				table.insert(loops, tween(icon, BOB, { Position = bobPos }))
			end
		end)
		playShine()
		for _ = 1, #sparkles do
			twinkleOne()
		end
	end

	-- CLIC : rebond, gerbe de cubes, reflet.
	local callbacks: { () -> () } = {}
	local cubeColors = { palette.top, palette.bottom, table.unpack(style.CubeColors) }
	local touchToken = 0
	local controller: Controller

	controller = bindInput(button, visual, style.HoverScale, iconHover, function()
		if lastInputIsTouch() then
			-- Pas de survol au doigt : l'icône bouge quand on touche le bouton.
			controller.setHover(true)
			touchToken += 1
			local token = touchToken
			task.delay(0.8, function()
				if token == touchToken then
					controller.setHover(false)
				end
			end)
		end
		PixelFx.cubeBurst(fxLayer, icon.AbsolutePosition + icon.AbsoluteSize / 2, cellSize(), cubeColors)
		playShine()
		for _, callback in callbacks do
			task.spawn(callback)
		end
	end)

	-- Reflets et étincelles automatiques, décalés d'un bouton à l'autre (en pause si l'interface est cachée).
	local alive = true
	slot.Destroying:Connect(function()
		alive = false
	end)
	task.spawn(function()
		local nextShine = os.clock() + math.random() * style.ShineEvery.Max
		local nextSparkle = os.clock() + randomIn(style.SparkleEvery)
		while alive do
			task.wait(0.25)
			if isHidden(slot) then
				continue
			end
			controller.checkMouse()
			local now = os.clock()
			if now >= nextShine then
				playShine()
				nextShine = now + randomIn(style.ShineEvery)
			end
			if now >= nextSparkle then
				twinkleOne()
				nextSparkle = now + randomIn(style.SparkleEvery) * (if controller.hovered() then 0.3 else 1)
			end
		end
	end)

	-- Badge : changer le texte (nil ou "" = caché) et, au besoin, la couleur (clé de Hud.Palettes).
	local function setBadge(text: string?, paletteName: string?)
		if badgeFrame == nil or badgeLabel == nil then
			return
		end
		if text == nil or text == "" then
			badgeFrame.Visible = false
		else
			badgeFrame.Visible = true
			badgeLabel.Text = text
		end
		local newPalette = if paletteName then HudConfig.Palettes[paletteName] else nil
		if newPalette and badgeGradient then
			badgeGradient.Color = ColorSequence.new(newPalette.top, newPalette.bottom)
		end
	end

	-- Badge qui pulse (Rebirth prêt).
	local pulse: Tween? = nil
	local function setPulse(on: boolean)
		if badgeFrame == nil then
			return
		end
		if on and pulse == nil then
			pulse = PixelFx.loop(tween(badgeFrame, BADGE_PULSE, {
				Size = UDim2.fromScale(badgeSize.X.Scale * 1.15, badgeSize.Y.Scale * 1.15),
			}))
		elseif not on and pulse ~= nil then
			pulse:Cancel()
			pulse = nil
			badgeFrame.Size = badgeSize
		end
	end

	return {
		id = def.id,
		slot = slot,
		button = button,
		setBadge = setBadge,
		setPulse = setPulse,
		onClick = function(callback: () -> ())
			table.insert(callbacks, callback)
		end,
		shine = playShine,
		reset = controller.reset,
		getCellSize = cellSize,
	}
end

type ActionOpts = {
	parent: Instance,
	text: string,
	palette: PixelFx.Palette,
	position: UDim2,
	size: UDim2,
	wCells: number, -- taille du bouton en cases (règle la taille des cubes et du contour)
	hCells: number,
	anchor: Vector2?,
	zIndex: number?,
	name: string?,
	textScale: number?, -- taille du texte / hauteur du bouton (0.5 par défaut)
	square: boolean?, -- garde le bouton carré
	studs: boolean?,
}

type Action = {
	slot: Frame,
	button: TextButton,
	visual: Frame, -- calque animé : y poser une icône supplémentaire
	label: TextLabel,
	setText: (text: string) -> (),
	setPalette: (palette: PixelFx.Palette) -> (),
	onClick: (callback: () -> ()) -> (),
	shine: () -> (),
}

-- Bouton texte des fenêtres (« Rebirth », « EQUIP », « X », « OFF »…) : même matière que le menu,
-- grossit au survol, s'enfonce au clic puis rebondit.
function PixelButton.action(opts: ActionOpts): Action
	local style = HudConfig.Style
	local z = opts.zIndex or 1
	local slot: Frame = create("Frame", {
		Name = opts.name or "Action",
		BackgroundTransparency = 1,
		AnchorPoint = opts.anchor or Vector2.new(0.5, 0.5),
		Position = opts.position,
		Size = opts.size,
		ZIndex = z,
		Parent = opts.parent,
	})
	if opts.square then
		create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = slot })
	end
	local button, visual = makeHitArea(slot, z)
	local block = PixelFx.block({
		parent = visual,
		name = "Body",
		palette = opts.palette,
		style = style,
		wCells = opts.wCells,
		hCells = opts.hCells,
		studs = opts.studs,
		zIndex = z,
	})
	local label, limit = PixelFx.text({
		parent = visual,
		name = "Label",
		text = opts.text,
		font = style.ButtonFont,
		position = UDim2.fromScale(0.5, 0.46),
		size = UDim2.fromScale(0.9, 0.7),
		zIndex = z + 1,
		strokeRatio = style.TextStroke,
	})
	local textScale = opts.textScale or 0.5
	local function relayout()
		limit.MaxTextSize = px(slot.AbsoluteSize.Y * textScale)
	end
	slot:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()

	local callbacks: { () -> () } = {}
	bindInput(button, visual, 1.06, function(on: boolean)
		if on then
			block.playShine()
		end
	end, function()
		for _, callback in callbacks do
			task.spawn(callback)
		end
	end)

	return {
		slot = slot,
		button = button,
		visual = visual,
		label = label,
		setText = function(text: string)
			label.Text = text
		end,
		setPalette = block.setPalette,
		onClick = function(callback: () -> ())
			table.insert(callbacks, callback)
		end,
		shine = block.playShine,
	}
end

return PixelButton
end)()

----------------------------------------------------------------------------------------------------
-- PixelPanel  (source : src/client/UI/PixelPanel.luau)
----------------------------------------------------------------------------------------------------
__modules.PixelPanel = (function()
-- PixelPanel.luau — fenêtre (Rebirth, Backpack, Index, Settings), comme dans la vidéo :
--   fond clair en plaque de briques, gros contour noir, icône penchée et titre posés sur le bord du haut,
--   bouton X rouge dans le coin ;
--   ouverture : la fenêtre jaillit en rebondissant (75 % → un peu plus de 100 % → 100 %) et le décor se floute ;
--   fermeture : elle rétrécit et disparaît, le flou s'en va. Une seule fenêtre ouverte à la fois.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = __modules.HudConfig
local PixelFx = __modules.PixelFx
local PixelButton = __modules.PixelButton

local create = PixelFx.create
local tween = PixelFx.tween

local PixelPanel = {}

type PanelOpts = {
	parent: Instance,
	name: string,
	title: string,
	icon: HudConfig.IconDef,
	width: number, -- largeur en fraction de la hauteur d'écran
	height: number, -- hauteur en fraction de la hauteur d'écran
	centerTitle: boolean?,
}

type Panel = {
	root: Frame,
	scale: UIScale, -- échelle d'animation (ouverture en rebond)
	title: TextLabel,
	content: Frame, -- calque où poser le contenu (positions en fraction de la fenêtre)
	open: () -> (),
	close: () -> (),
	toggle: () -> (),
	isOpen: () -> boolean,
	onOpen: (callback: () -> ()) -> (),
	-- Taille en cases (pour PixelFx.block / PixelButton.action) d'une zone de la fenêtre.
	cells: (fracW: number, fracH: number) -> (number, number),
}

local OPEN_INFO = TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local BLUR_IN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BLUR_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local current: Panel? = nil
local blur: BlurEffect? = nil

-- Flou du décor : un BlurEffect dans Lighting, créé par le client (donc visible par ce joueur seulement).
local function getBlur(): BlurEffect
	local existing = blur
	if existing and existing.Parent then
		return existing
	end
	local found = Lighting:FindFirstChild("PixelHudBlur")
	if found and found:IsA("BlurEffect") then
		blur = found
		return found
	end
	local created: BlurEffect = create("BlurEffect", { Name = "PixelHudBlur", Size = 0, Parent = Lighting })
	blur = created
	return created
end

function PixelPanel.closeCurrent()
	local panel = current
	if panel then
		panel.close()
	end
end

function PixelPanel.new(opts: PanelOpts): Panel
	local cfg = HudConfig.Panel
	local style = HudConfig.Style
	local aspect = opts.width / opts.height

	local root: Frame = create("Frame", {
		Name = opts.name .. "Panel",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, cfg.CenterY),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Size = UDim2.fromScale(opts.width, opts.height),
		Visible = false,
		ZIndex = 20,
		Parent = opts.parent,
	})
	local scale: UIScale = create("UIScale", { Scale = 1, Parent = root })

	-- Corps : fond clair + motif de briques découpé aux coins arrondis.
	local body: Frame = create("Frame", {
		Name = "Body",
		BackgroundColor3 = cfg.Background,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = root,
	})
	PixelFx.corner(body, 0.045)
	local outline = PixelFx.border(body, style.Outline)
	local surface: CanvasGroup = create("CanvasGroup", {
		Name = "Surface",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = body,
	})
	PixelFx.corner(surface, 0.045)
	PixelFx.brickPattern(surface, cfg.BrickTile, cfg.BrickRatio, aspect, 1)

	local content: Frame = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Parent = root,
	})

	-- En-tête : icône penchée dans le coin + titre sur le bord du haut.
	local icon = PixelFx.icon(root, opts.icon, 6)
	icon.Position = UDim2.fromScale(0.035, 0.035)
	icon.Size = UDim2.fromScale(1, 0.17)
	icon.Rotation = -10
	create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = icon })
	local titleX = if opts.centerTitle then 0.5 else 0.085
	local titleLabel, titleLimit = PixelFx.text({
		parent = root,
		name = "Title",
		text = opts.title,
		font = style.ButtonFont,
		anchor = Vector2.new(if opts.centerTitle then 0.5 else 0, 0.5),
		position = UDim2.fromScale(titleX, 0.02),
		size = UDim2.fromScale(0.6, 0.12),
		xAlign = if opts.centerTitle then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
		zIndex = 6,
		strokeRatio = style.TextStroke,
	})

	local function relayout()
		local height = root.AbsoluteSize.Y
		if height <= 0 then
			return
		end
		outline.Thickness = math.max(1, math.floor(height * 0.014 + 0.5))
		titleLimit.MaxTextSize = math.max(1, math.floor(height * 0.085 + 0.5))
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()

	local function cells(fracW: number, fracH: number): (number, number)
		return fracW * opts.width / cfg.CellOfScreen, fracH * opts.height / cfg.CellOfScreen
	end

	-- Bouton X rouge dans le coin haut droit.
	local closeW, closeH = cells(0.12 / aspect, 0.12)
	local closeButton = PixelButton.action({
		parent = root,
		name = "Close",
		text = "X",
		palette = HudConfig.Palettes.BadgeRed,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.985, 0.025),
		size = UDim2.fromScale(1, 0.125),
		wCells = closeW,
		hCells = closeH,
		square = true,
		zIndex = 8,
		textScale = 0.62,
	})

	local isOpen = false
	local openCallbacks: { () -> () } = {}
	local handle: Panel

	local function open()
		if isOpen then
			return
		end
		local previous = current
		if previous and previous ~= handle then
			previous.close()
		end
		isOpen = true
		current = handle
		root.Visible = true
		if PixelFx.reducedMotion then
			scale.Scale = 1
		else
			scale.Scale = 0.75
			tween(scale, OPEN_INFO, { Scale = 1 })
		end
		tween(getBlur(), BLUR_IN, { Size = cfg.Blur })
		for _, callback in openCallbacks do
			task.spawn(callback)
		end
	end

	local function close()
		if not isOpen then
			return
		end
		isOpen = false
		if current == handle then
			current = nil
			tween(getBlur(), BLUR_OUT, { Size = 0 })
		end
		if PixelFx.reducedMotion then
			root.Visible = false
			return
		end
		local shrink = tween(scale, CLOSE_INFO, { Scale = 0.8 })
		shrink.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and not isOpen then
				root.Visible = false
			end
		end)
	end

	closeButton.onClick(close)

	handle = {
		root = root,
		scale = scale,
		title = titleLabel,
		content = content,
		open = open,
		close = close,
		toggle = function()
			if isOpen then
				close()
			else
				open()
			end
		end,
		isOpen = function(): boolean
			return isOpen
		end,
		onOpen = function(callback: () -> ())
			table.insert(openCallbacks, callback)
		end,
		cells = cells,
	}
	return handle
end

return PixelPanel
end)()

----------------------------------------------------------------------------------------------------
-- StatsHud  (source : src/client/UI/StatsHud.luau)
----------------------------------------------------------------------------------------------------
__modules.StatsHud = (function()
-- StatsHud.luau — bas de l'écran, à l'identique de la capture :
--   • en bas à gauche : icône rebirth + nombre (cyan), trophée + wins (jaune) ;
--   • en bas au centre : « 💪157M POWER » (jaune), « x10.5 Boost » (blanc) et la barre bleue
--     « Rebirth 19 … 157M/157M Power » avec reflet qui la traverse.
-- Les nombres défilent jusqu'à leur nouvelle valeur au lieu de sauter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = __modules.HudConfig
local FormatNumber = __modules.FormatNumber
local PixelFx = __modules.PixelFx

local create = PixelFx.create
local tween = PixelFx.tween

local StatsHud = {}

type Handle = {
	counters: Frame,
	power: Frame,
	setRebirths: (n: number) -> (),
	setWins: (n: number) -> (),
	setPower: (power: number, cost: number) -> (),
	setBoost: (boost: number) -> (),
	relayout: (screenSize: Vector2, small: boolean) -> (),
}

local WHITE = Color3.new(1, 1, 1)
local YELLOW = Color3.fromRGB(255, 230, 0)
local CYAN = Color3.fromRGB(47, 208, 255)

local COUNT_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Proportions relevées sur la capture (hauteurs en fraction de la hauteur d'écran).
local COUNTERS_W, COUNTERS_H = 0.17, 0.13
local POWER_W, POWER_H = 0.8, 0.11
local POWER_ASPECT = 803 / 110
local TOP_ROW = 0.36 -- hauteur de la ligne « POWER / Boost » dans le bloc du bas
local BAR_Y = 0.39 -- début de la barre dans le bloc du bas

local function px(value: number): number
	return math.max(1, math.floor(value + 0.5))
end

-- Compteur animé : renvoie une fonction `set(cible)` ; `render` reçoit la valeur intermédiaire.
-- La première valeur s'affiche directement, les suivantes défilent.
local function makeCounter(holder: Instance, render: (number) -> ()): (number) -> ()
	local value: NumberValue = create("NumberValue", { Name = "Counter", Value = 0, Parent = holder })
	local target: number? = nil
	local current: Tween? = nil
	value.Changed:Connect(render)
	render(0)
	return function(newTarget: number)
		if target == newTarget then
			return
		end
		local first = target == nil
		target = newTarget
		if current then
			current:Cancel()
			current = nil
		end
		if first then
			value.Value = newTarget
			render(newTarget)
		else
			current = tween(value, COUNT_INFO, { Value = newTarget })
		end
	end
end

function StatsHud.new(parent: Instance, margin: number): Handle
	local style = HudConfig.Style
	local texts = HudConfig.Texts
	local font = style.StatFont

	---------------------------------------------------------------- en bas à gauche
	local counters: Frame = create("Frame", {
		Name = "Counters",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, margin, 1, -margin),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Size = UDim2.fromScale(COUNTERS_W, COUNTERS_H),
		Parent = parent,
	})

	local function counterRow(name: string, y: number, icon: HudConfig.IconDef, color: Color3): TextLabel
		local row = create("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0, y),
			Size = UDim2.fromScale(1, 0.48),
			Parent = counters,
		})
		local iconView = PixelFx.icon(row, icon, 2)
		iconView.AnchorPoint = Vector2.new(0, 0.5)
		iconView.Position = UDim2.fromScale(0, 0.5)
		iconView.Size = UDim2.fromScale(1, 1)
		create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = iconView })
		local label, _ = PixelFx.text({
			parent = row,
			name = "Value",
			text = "0",
			font = font,
			color = color,
			anchor = Vector2.new(0, 0.5),
			position = UDim2.fromScale(0.34, 0.52),
			size = UDim2.fromScale(0.7, 0.92),
			xAlign = Enum.TextXAlignment.Left,
			zIndex = 3,
			strokeRatio = 0.12,
		})
		return label
	end

	local rebirthsLabel = counterRow("Rebirths", 0, HudConfig.StatIcons.Rebirths, CYAN)
	local winsLabel = counterRow("Wins", 0.52, HudConfig.StatIcons.Wins, YELLOW)

	---------------------------------------------------------------- en bas au centre
	local power: Frame = create("Frame", {
		Name = "PowerHud",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -math.floor(margin * 0.8)),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Size = UDim2.fromScale(POWER_W, POWER_H),
		Parent = parent,
	})
	create("UIAspectRatioConstraint", {
		AspectRatio = POWER_ASPECT,
		AspectType = Enum.AspectType.FitWithinMaxSize,
		DominantAxis = Enum.DominantAxis.Width,
		Parent = power,
	})

	-- « 💪157M POWER »
	local powerRow = create("Frame", {
		Name = "PowerLabel",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.6, TOP_ROW),
		Parent = power,
	})
	local powerIcon = PixelFx.icon(powerRow, HudConfig.StatIcons.Power, 2)
	powerIcon.AnchorPoint = Vector2.new(0, 0.5)
	powerIcon.Position = UDim2.fromScale(0, 0.5)
	powerIcon.Size = UDim2.fromScale(1, 1.1)
	create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = powerIcon })
	local powerLabel, _ = PixelFx.text({
		parent = powerRow,
		name = "Value",
		text = "",
		font = font,
		color = YELLOW,
		anchor = Vector2.new(0, 0.5),
		position = UDim2.fromScale(0.07, 0.5),
		size = UDim2.fromScale(0.93, 1),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
		strokeRatio = 0.12,
	})

	-- « x10.5 Boost »
	local boostLabel, _ = PixelFx.text({
		parent = power,
		name = "Boost",
		text = "",
		font = font,
		anchor = Vector2.new(1, 0),
		position = UDim2.fromScale(1, 0.02),
		size = UDim2.fromScale(0.4, TOP_ROW * 0.92),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 3,
		strokeRatio = 0.12,
	})

	-- Barre de progression du rebirth.
	local barPalette = HudConfig.Palettes.Bar
	local bar: Frame = create("Frame", {
		Name = "Bar",
		BackgroundColor3 = Color3.fromRGB(8, 30, 60),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, BAR_Y),
		Size = UDim2.fromScale(1, 1 - BAR_Y),
		Parent = power,
	})
	PixelFx.corner(bar, 0.16)
	local barOutline = PixelFx.border(bar)

	local fill: CanvasGroup = create("CanvasGroup", {
		Name = "Fill",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 2,
		Parent = bar,
	})
	PixelFx.corner(fill, 0.16)
	local fillColor = create("Frame", {
		Name = "Color",
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = fill,
	})
	PixelFx.vgradient(fillColor, barPalette.top, barPalette.bottom)
	PixelFx.gloss(fill, 2)
	local barShine = PixelFx.shine(fill, 12, 1, 3)

	local barLeft, barLeftLimit = PixelFx.text({
		parent = bar,
		name = "Left",
		text = "",
		font = font,
		anchor = Vector2.new(0, 0.5),
		position = UDim2.fromScale(0.025, 0.5),
		size = UDim2.fromScale(0.5, 0.66),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
		strokeRatio = 0.12,
	})
	local barRight, barRightLimit = PixelFx.text({
		parent = bar,
		name = "Right",
		text = "",
		font = font,
		anchor = Vector2.new(1, 0.5),
		position = UDim2.fromScale(0.975, 0.5),
		size = UDim2.fromScale(0.5, 0.66),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 4,
		strokeRatio = 0.12,
	})

	local function updateBarSizes()
		local barHeight = bar.AbsoluteSize.Y
		if barHeight <= 0 then
			return
		end
		barOutline.Thickness = px(barHeight * 0.055)
		barLeftLimit.MaxTextSize = px(barHeight * 0.5)
		barRightLimit.MaxTextSize = px(barHeight * 0.4)
	end
	bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBarSizes)
	updateBarSizes()

	---------------------------------------------------------------- valeurs
	local cost = 1
	local progress = 0

	local setWinsAnimated = makeCounter(counters, function(value: number)
		winsLabel.Text = FormatNumber.short(value)
	end)

	local shownPower = 0
	local function drawPower()
		local shown = FormatNumber.short(shownPower)
		powerLabel.Text = string.format(texts.Power, shown)
		barRight.Text = string.format(texts.BarRight, shown, FormatNumber.short(cost))
		progress = if cost > 0 then math.clamp(shownPower / cost, 0, 1) else 0
		fill.Size = UDim2.fromScale(progress, 1)
	end
	local setPowerAnimated = makeCounter(power, function(value: number)
		shownPower = value
		drawPower()
	end)

	-- Le reflet traverse la barre régulièrement, plus souvent quand elle est pleine.
	local alive = true
	power.Destroying:Connect(function()
		alive = false
	end)
	task.spawn(function()
		while alive do
			task.wait(if progress >= 1 then 1.4 else 3)
			local gui = power:FindFirstAncestorOfClass("ScreenGui")
			if progress > 0 and (gui == nil or gui.Enabled) then
				barShine()
			end
		end
	end)

	return {
		counters = counters,
		power = power,
		setRebirths = function(n: number)
			local shown = FormatNumber.short(n)
			rebirthsLabel.Text = shown
			barLeft.Text = string.format(texts.BarLeft, shown)
		end,
		setWins = setWinsAnimated,
		setPower = function(value: number, newCost: number)
			cost = newCost
			setPowerAnimated(value)
			drawPower() -- le coût a pu changer sans que la valeur change
		end,
		setBoost = function(boost: number)
			boostLabel.Text = string.format(texts.Boost, FormatNumber.multiplier(boost))
		end,
		relayout = function(screenSize: Vector2, small: boolean)
			local k = if small then 1.25 else 1
			counters.Size = UDim2.fromScale(COUNTERS_W * k, COUNTERS_H * k)
			local maxWidth = 0.92 * screenSize.X / math.max(1, screenSize.Y)
			power.Size = UDim2.fromScale(math.min(POWER_W * k, maxWidth), POWER_H * k)
		end,
	}
end

return StatsHud
end)()

----------------------------------------------------------------------------------------------------
-- RebirthPanel  (source : src/client/UI/Panels/RebirthPanel.luau)
----------------------------------------------------------------------------------------------------
__modules.RebirthPanel = (function()
-- RebirthPanel.luau — fenêtre « Rebirth » de la vidéo :
--   « Before » [💪 x10.5 POWER]  ➜  « After » [💪 x11 POWER]
--   « Resets your POWER! » en rouge, barre « 598M/157M Power », boutons « Rebirth » (vert) et
--   « Skip Rebirth » (violet).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = __modules.HudConfig
local FormatNumber = __modules.FormatNumber
local PixelFx = __modules.PixelFx
local PixelButton = __modules.PixelButton
local PixelPanel = __modules.PixelPanel

local create = PixelFx.create

local RebirthPanel = {}

type State = { power: number, cost: number, boost: number, nextBoost: number }
type Actions = { onRebirth: () -> (), onSkip: () -> () }
type Handle = {
	panel: PixelPanel.Panel,
	update: (state: State) -> (),
	setActions: (actions: Actions) -> (),
}

local WIDTH, HEIGHT = 0.47, 0.37 -- en fraction de la hauteur d'écran
local RED = Color3.fromRGB(255, 52, 48)

function RebirthPanel.new(parent: Instance): Handle
	local style = HudConfig.Style
	local texts = HudConfig.Texts
	local palettes = HudConfig.Palettes

	local panel = PixelPanel.new({
		parent = parent,
		name = "Rebirth",
		title = texts.RebirthButton,
		icon = HudConfig.StatIcons.Rebirths,
		width = WIDTH,
		height = HEIGHT,
		centerTitle = true,
	})
	local content = panel.content
	local actions: Actions = {
		onRebirth = function() end,
		onSkip = function() end,
	}

	local function label(text: string, x: number, y: number, w: number, h: number, color: Color3?): TextLabel
		local textLabel, _ = PixelFx.text({
			parent = content,
			text = text,
			font = style.ButtonFont,
			color = color,
			position = UDim2.fromScale(x, y),
			size = UDim2.fromScale(w, h),
			zIndex = 4,
			strokeRatio = style.TextStroke,
		})
		return textLabel
	end

	label(texts.Before, 0.27, 0.19, 0.3, 0.075)
	label(texts.After, 0.73, 0.19, 0.3, 0.075)

	-- Carte orange « 💪 x10.5 POWER ».
	local function card(x: number): TextLabel
		local holder: Frame = create("Frame", {
			Name = "Card",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.335),
			Size = UDim2.fromScale(0.36, 0.17),
			ZIndex = 4,
			Parent = content,
		})
		local wCells, hCells = panel.cells(0.36, 0.17)
		PixelFx.block({
			parent = holder,
			palette = palettes.Amber,
			style = style,
			wCells = wCells,
			hCells = hCells,
		})
		local icon = PixelFx.icon(holder, HudConfig.StatIcons.Power, 5)
		icon.Position = UDim2.fromScale(0.2, 0.5)
		icon.Size = UDim2.fromScale(1, 0.95)
		icon.Rotation = -8
		create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = icon })
		local value, _ = PixelFx.text({
			parent = holder,
			name = "Value",
			text = "x1",
			font = style.ButtonFont,
			position = UDim2.fromScale(0.64, 0.4),
			size = UDim2.fromScale(0.6, 0.56),
			zIndex = 6,
			strokeRatio = style.TextStroke,
		})
		PixelFx.text({
			parent = holder,
			name = "Tag",
			text = texts.PowerTag,
			font = style.ButtonFont,
			position = UDim2.fromScale(0.64, 0.78),
			size = UDim2.fromScale(0.5, 0.26),
			zIndex = 6,
			strokeRatio = style.TextStroke,
		})
		return value
	end

	local before = card(0.27)
	local after = card(0.73)
	PixelFx.arrow(content, UDim2.fromScale(0.5, 0.335), UDim2.fromScale(0.11, 0.1), 5)

	label(texts.Resets, 0.5, 0.49, 0.8, 0.075, RED)

	local bar = PixelFx.progressBar(
		content,
		UDim2.fromScale(0.5, 0.625),
		UDim2.fromScale(0.8, 0.105),
		Vector2.new(0.5, 0.5),
		palettes.Bar,
		style.ButtonFont,
		4
	)

	local rebirthW, rebirthH = panel.cells(0.3, 0.15)
	local rebirthButton = PixelButton.action({
		parent = content,
		name = "Rebirth",
		text = texts.RebirthButton,
		palette = palettes.Lime,
		position = UDim2.fromScale(0.31, 0.82),
		size = UDim2.fromScale(0.3, 0.15),
		wCells = rebirthW,
		hCells = rebirthH,
		zIndex = 5,
		textScale = 0.55,
	})
	rebirthButton.onClick(function()
		actions.onRebirth()
	end)

	local skipW, skipH = panel.cells(0.34, 0.13)
	local skipButton = PixelButton.action({
		parent = content,
		name = "Skip",
		text = texts.SkipRebirth,
		palette = palettes.Purple,
		position = UDim2.fromScale(0.69, 0.82),
		size = UDim2.fromScale(0.34, 0.13),
		wCells = skipW,
		hCells = skipH,
		zIndex = 5,
		textScale = 0.42,
	})
	skipButton.onClick(function()
		actions.onSkip()
	end)

	return {
		panel = panel,
		setActions = function(newActions: Actions)
			actions = newActions
		end,
		update = function(state: State)
			before.Text = "x" .. FormatNumber.multiplier(state.boost)
			after.Text = "x" .. FormatNumber.multiplier(state.nextBoost)
			local fraction = if state.cost > 0 then state.power / state.cost else 0
			bar.set(
				fraction,
				string.format(texts.RebirthPower, FormatNumber.short(state.power), FormatNumber.short(state.cost))
			)
		end,
	}
end

return RebirthPanel
end)()

----------------------------------------------------------------------------------------------------
-- SettingsPanel  (source : src/client/UI/Panels/SettingsPanel.luau)
----------------------------------------------------------------------------------------------------
__modules.SettingsPanel = (function()
-- SettingsPanel.luau — fenêtre « Settings » de la vidéo :
--   AUDIO    : ligne bleue « Music / Background music » et ligne rose « Sound / Splats and effects »,
--              chacune avec un curseur vert à bouton orange et sa valeur en jaune ;
--   GAMEPLAY : ligne verte « Reduced Motion / Fewer flashes and effects » avec un bouton OFF (rouge) / ON (vert).
--   Deux onglets à droite de la fenêtre : « Audio » et « Gameplay ».
-- Les volumes s'appliquent aux SoundGroups « Music » et « SFX » de SoundService s'ils existent ;
-- « Reduced Motion » coupe les reflets, étincelles, cubes et animations en boucle de l'interface.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local HudConfig = __modules.HudConfig
local PixelFx = __modules.PixelFx
local PixelButton = __modules.PixelButton
local PixelPanel = __modules.PixelPanel

local create = PixelFx.create

local SettingsPanel = {}

type Actions = { onChange: (name: string, value: number | boolean) -> () }
type Handle = { panel: PixelPanel.Panel }

local WIDTH, HEIGHT = 0.8, 0.57
local WHITE = Color3.new(1, 1, 1)
local YELLOW = Color3.fromRGB(255, 230, 0)
local KNOB_TOP, KNOB_BOTTOM = Color3.fromRGB(255, 198, 30), Color3.fromRGB(245, 135, 0)

local baseVolumes: { [string]: number } = {}

local function applyVolume(groupName: string, value: number)
	local group = SoundService:FindFirstChild(groupName)
	if group and group:IsA("SoundGroup") then
		local base = baseVolumes[groupName] or group.Volume
		baseVolumes[groupName] = base
		group.Volume = base * value / 100
	end
end

-- Curseur 0..100 : piste blanche, remplissage vert, bouton orange, valeur en jaune à droite.
local function slider(row: Frame, initial: number, onChange: (value: number) -> ())
	local track: TextButton = create("TextButton", {
		Name = "Slider",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.53, 0.5),
		Size = UDim2.fromScale(0.33, 0.27),
		ZIndex = 5,
		Parent = row,
	})
	PixelFx.corner(track, 0.5)
	local trackOutline = PixelFx.border(track)
	local fill: Frame = create("Frame", {
		Name = "Fill",
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(initial / 100, 1),
		ZIndex = 6,
		Parent = track,
	})
	PixelFx.corner(fill, 0.5)
	PixelFx.vgradient(fill, HudConfig.Palettes.Lime.top, HudConfig.Palettes.Lime.bottom)
	local knob: Frame = create("Frame", {
		Name = "Knob",
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(initial / 100, 0.5),
		Size = UDim2.fromScale(1, 1.6),
		ZIndex = 7,
		Parent = track,
	})
	create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = knob })
	PixelFx.corner(knob, 0.5)
	PixelFx.vgradient(knob, KNOB_TOP, KNOB_BOTTOM)
	local knobOutline = PixelFx.border(knob)
	local valueLabel, _ = PixelFx.text({
		parent = row,
		name = "Value",
		text = tostring(initial),
		font = HudConfig.Style.ButtonFont,
		color = YELLOW,
		position = UDim2.fromScale(0.93, 0.5),
		size = UDim2.fromScale(0.08, 0.36),
		zIndex = 5,
		strokeRatio = 0.13,
	})

	track:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local height = track.AbsoluteSize.Y
		trackOutline.Thickness = math.max(1, math.floor(height * 0.14 + 0.5))
		knobOutline.Thickness = math.max(1, math.floor(height * 0.14 + 0.5))
	end)

	local function set(value: number)
		fill.Size = UDim2.fromScale(value / 100, 1)
		knob.Position = UDim2.fromScale(value / 100, 0.5)
		valueLabel.Text = tostring(value)
	end

	local dragging = false
	local function fromScreenX(x: number)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local value = math.floor(math.clamp((x - track.AbsolutePosition.X) / width, 0, 1) * 100 + 0.5)
		set(value)
		onChange(value)
	end
	local function isPointer(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	track.InputBegan:Connect(function(input: InputObject)
		if isPointer(input) then
			dragging = true
			fromScreenX(input.Position.X)
		end
	end)
	local moved = UserInputService.InputChanged:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if dragging and (kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch) then
			fromScreenX(input.Position.X)
		end
	end)
	local ended = UserInputService.InputEnded:Connect(function(input: InputObject)
		if isPointer(input) then
			dragging = false
		end
	end)
	track.Destroying:Connect(function()
		moved:Disconnect()
		ended:Disconnect()
	end)
end

function SettingsPanel.new(parent: Instance, actions: Actions): Handle
	local style = HudConfig.Style
	local texts = HudConfig.Texts
	local palettes = HudConfig.Palettes
	local defaults = HudConfig.Settings

	local panel = PixelPanel.new({
		parent = parent,
		name = "Settings",
		title = "Settings",
		icon = HudConfig.PanelIcons.Gear,
		width = WIDTH,
		height = HEIGHT,
	})
	local content = panel.content

	local function sectionTitle(text: string, y: number)
		PixelFx.text({
			parent = content,
			text = text,
			font = style.ButtonFont,
			position = UDim2.fromScale(0.5, y),
			size = UDim2.fromScale(0.4, 0.065),
			zIndex = 4,
			strokeRatio = style.TextStroke,
		})
	end

	-- Ligne colorée à cubes : icône engrenage, titre, sous-titre.
	local function row(y: number, palette: PixelFx.Palette, title: string, hint: string): (Frame, () -> ())
		local holder: Frame = create("Frame", {
			Name = title,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, y),
			Size = UDim2.fromScale(0.94, 0.15),
			ZIndex = 4,
			Parent = content,
		})
		local wCells, hCells = panel.cells(0.94, 0.15)
		local block = PixelFx.block({
			parent = holder,
			palette = palette,
			style = style,
			wCells = wCells,
			hCells = hCells,
		})
		local icon = PixelFx.icon(holder, HudConfig.PanelIcons.Gear, 5)
		icon.Position = UDim2.fromScale(0.055, 0.5)
		icon.Size = UDim2.fromScale(1, 0.8)
		create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = icon })
		PixelFx.text({
			parent = holder,
			name = "Title",
			text = title,
			font = style.ButtonFont,
			anchor = Vector2.new(0, 0.5),
			xAlign = Enum.TextXAlignment.Left,
			position = UDim2.fromScale(0.115, 0.36),
			size = UDim2.fromScale(0.36, 0.38),
			zIndex = 5,
			strokeRatio = style.TextStroke,
		})
		PixelFx.text({
			parent = holder,
			name = "Hint",
			text = hint,
			font = style.ButtonFont,
			anchor = Vector2.new(0, 0.5),
			xAlign = Enum.TextXAlignment.Left,
			position = UDim2.fromScale(0.115, 0.7),
			size = UDim2.fromScale(0.4, 0.24),
			zIndex = 5,
			strokeRatio = 0.12,
		})
		return holder, block.playShine
	end

	sectionTitle(texts.Audio, 0.11)
	local musicRow, musicShine = row(0.235, palettes.Blue, texts.Music, texts.MusicHint)
	local soundRow, soundShine = row(0.41, palettes.Magenta, texts.Sound, texts.SoundHint)
	sectionTitle(texts.Gameplay, 0.555)
	local motionRow, motionShine = row(0.685, palettes.Lime, texts.ReducedMotion, texts.ReducedMotionHint)

	applyVolume(defaults.MusicGroup, defaults.Music)
	applyVolume(defaults.SoundGroup, defaults.Sound)
	slider(musicRow, defaults.Music, function(value: number)
		applyVolume(defaults.MusicGroup, value)
		actions.onChange("Music", value)
	end)
	slider(soundRow, defaults.Sound, function(value: number)
		applyVolume(defaults.SoundGroup, value)
		actions.onChange("Sound", value)
	end)

	-- Bouton OFF (rouge) / ON (vert).
	local reduced = defaults.ReducedMotion
	local toggleW, toggleH = panel.cells(0.94 * 0.2, 0.15 * 0.64)
	local toggle = PixelButton.action({
		parent = motionRow,
		name = "Toggle",
		text = if reduced then texts.On else texts.Off,
		palette = if reduced then palettes.Lime else palettes.Red,
		position = UDim2.fromScale(0.86, 0.5),
		size = UDim2.fromScale(0.2, 0.64),
		wCells = toggleW,
		hCells = toggleH,
		zIndex = 6,
		textScale = 0.5,
	})
	PixelFx.setReducedMotion(reduced)
	toggle.onClick(function()
		reduced = not reduced
		toggle.setText(if reduced then texts.On else texts.Off)
		toggle.setPalette(if reduced then palettes.Lime else palettes.Red)
		PixelFx.setReducedMotion(reduced)
		actions.onChange("ReducedMotion", reduced)
	end)

	-- Onglets à droite de la fenêtre : font briller leur section.
	local function tab(y: number, text: string, palette: PixelFx.Palette, shines: { () -> () })
		local tabW, tabH = panel.cells(0.14 * HEIGHT / WIDTH, 0.14)
		local button = PixelButton.action({
			parent = panel.root,
			name = text .. "Tab",
			text = text,
			palette = palette,
			position = UDim2.fromScale(1 + 0.085 * HEIGHT / WIDTH, y),
			size = UDim2.fromScale(1, 0.14),
			wCells = tabW,
			hCells = tabH,
			square = true,
			zIndex = 4,
			textScale = 0.2,
		})
		button.label.Position = UDim2.fromScale(0.5, 0.8)
		button.label.Size = UDim2.fromScale(0.95, 0.3)
		local icon = PixelFx.icon(button.visual, HudConfig.PanelIcons.Gear, 6)
		icon.Position = UDim2.fromScale(0.5, 0.4)
		icon.Size = UDim2.fromScale(0.6, 0.6)
		button.onClick(function()
			for _, shine in shines do
				shine()
			end
		end)
	end
	tab(0.15, "Audio", palettes.Blue, { musicShine, soundShine })
	tab(0.33, "Gameplay", palettes.Amber, { motionShine })

	return { panel = panel }
end

return SettingsPanel
end)()

----------------------------------------------------------------------------------------------------
-- RocketsPanel  (source : src/client/UI/Panels/RocketsPanel.luau)
----------------------------------------------------------------------------------------------------
__modules.RocketsPanel = (function()
-- RocketsPanel.luau — les fenêtres « Backpack » et « Index » de la vidéo, avec tes 40 fusées :
--   • Backpack : compteur « 9/40 » à côté du titre, grille des fusées possédées (cartes à cubes de la
--     couleur du monde, « E » vert sur celle équipée), fiche à droite avec rayons, POWER, PRICE et EQUIP ;
--   • Index : onglets des 4 mondes à gauche, grille de toutes les fusées du monde (celles pas encore
--     débloquées en silhouette noire « ??? »), barre de collection, fiche à droite (bouton d'achat).
-- L'aperçu d'une fusée est son modèle 3D (ReplicatedStorage.Assets.Rockets.<clé>) s'il a été importé,
-- sinon une icône provisoire.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = __modules.HudConfig
local Rockets = __modules.Rockets
local FormatNumber = __modules.FormatNumber
local PixelFx = __modules.PixelFx
local PixelButton = __modules.PixelButton
local PixelPanel = __modules.PixelPanel

local create = PixelFx.create

local RocketsPanel = {}

type Actions = { onEquip: (id: number) -> (), onBuy: (id: number) -> () }
type Handle = {
	panel: PixelPanel.Panel,
	setOwned: (ids: { number }) -> (),
	setEquipped: (id: number?) -> (),
	setActions: (actions: Actions) -> (),
}

type Card = { setSelected: (on: boolean) -> (), setEquipped: (on: boolean) -> () }

local WIDTH, HEIGHT = 0.8, 0.57
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local YELLOW = Color3.fromRGB(255, 230, 0)

local function buttonIcon(id: string): HudConfig.IconDef
	for _, def in HudConfig.Buttons do
		if def.id == id then
			return def.icon
		end
	end
	return HudConfig.PanelIcons.Rocket
end

-- Aperçu de la fusée : modèle 3D dans un ViewportFrame s'il existe, sinon icône (ou « ? » si verrouillée).
local function rocketView(parent: Instance, def: Rockets.RocketDef, silhouette: boolean, zIndex: number): GuiObject
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = if assets then assets:FindFirstChild("Rockets") else nil
	local template = if folder then folder:FindFirstChild(def.key) else nil
	if template and template:IsA("Model") then
		local viewport: ViewportFrame = create("ViewportFrame", {
			Name = "View",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Ambient = Color3.fromRGB(190, 190, 200),
			LightColor = WHITE,
			LightDirection = Vector3.new(-1, -1.5, -1),
			ImageColor3 = if silhouette then BLACK else WHITE,
			ZIndex = zIndex,
			Parent = parent,
		})
		create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = viewport })
		local model = template:Clone()
		model:PivotTo(CFrame.Angles(0, 0, math.rad(-30))) -- penchée, comme au décollage
		model.Parent = viewport
		local camera: Camera = create("Camera", { FieldOfView = 30, Parent = viewport })
		viewport.CurrentCamera = camera
		local box, size = model:GetBoundingBox()
		local distance = (size.Magnitude / 2) / math.tan(math.rad(15))
		camera.CFrame = CFrame.lookAt(box.Position + Vector3.new(0.35, 0.25, 1).Unit * distance, box.Position)
		return viewport
	end
	if silhouette then
		local label, _ = PixelFx.text({
			parent = parent,
			name = "View",
			text = "?",
			font = HudConfig.Style.ButtonFont,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(1, 1),
			zIndex = zIndex,
			strokeRatio = 0.12,
		})
		return label
	end
	return PixelFx.icon(parent, HudConfig.PanelIcons.Rocket, zIndex)
end

function RocketsPanel.new(parent: Instance, mode: "Backpack" | "Index"): Handle
	local style = HudConfig.Style
	local texts = HudConfig.Texts
	local palettes = HudConfig.Palettes
	local isIndex = mode == "Index"

	local panel = PixelPanel.new({
		parent = parent,
		name = mode,
		title = mode,
		icon = buttonIcon(mode),
		width = WIDTH,
		height = HEIGHT,
	})
	local content = panel.content
	local actions: Actions = {
		onEquip = function(_id: number) end,
		onBuy = function(_id: number) end,
	}

	local owned: { [number]: boolean } = {}
	local ownedCount = 0
	local equipped: number? = nil
	local selected: number? = nil
	local world = 1

	local function isKnown(id: number): boolean
		return owned[id] == true
	end

	local function worldPalette(worldId: number): PixelFx.Palette
		return palettes[HudConfig.WorldPalettes[worldId] or "Lime"] or palettes.Lime
	end

	---------------------------------------------------------------- en-tête
	local counter: PixelFx.ProgressBar? = nil
	local collection: PixelFx.ProgressBar? = nil
	local gridX = if isIndex then 0.115 else 0.03
	local gridW = if isIndex then 0.515 else 0.6
	local columns = if isIndex then 5 else 4

	local heading, _ = PixelFx.text({
		parent = content,
		name = "Category",
		text = texts.Category,
		font = style.ButtonFont,
		position = UDim2.fromScale(gridX + gridW / 2, 0.1),
		size = UDim2.fromScale(gridW * 0.7, 0.06),
		zIndex = 4,
		strokeRatio = style.TextStroke,
	})
	if isIndex then
		collection = PixelFx.progressBar(
			content,
			UDim2.fromScale(gridX, 0.89),
			UDim2.fromScale(gridW, 0.065),
			Vector2.new(0, 0.5),
			palettes.Lime,
			style.ButtonFont,
			4
		)
	else
		local pill = PixelFx.progressBar(
			panel.root,
			UDim2.fromScale(0.43, 0.02),
			UDim2.fromScale(0.13, 0.06),
			Vector2.new(0, 0.5),
			palettes.Bar,
			style.ButtonFont,
			7
		)
		counter = pill
		-- Le compteur « 9/40 » se cale juste après le titre, quelle que soit sa largeur.
		local title = panel.title
		local function placeCounter()
			local width = panel.root.AbsoluteSize.X
			if width > 0 then
				local x = title.Position.X.Scale + title.TextBounds.X / width + 0.02
				pill.frame.Position = UDim2.fromScale(x, 0.02)
			end
		end
		title:GetPropertyChangedSignal("TextBounds"):Connect(placeCounter)
		panel.root:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeCounter)
		placeCounter()
	end

	---------------------------------------------------------------- grille
	local grid: ScrollingFrame = create("ScrollingFrame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(gridX, 0.15),
		Size = UDim2.fromScale(gridW, if isIndex then 0.69 else 0.8),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(70, 70, 100),
		ZIndex = 4,
		Parent = content,
	})
	local layout: UIGridLayout = create("UIGridLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	create("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 6),
		Parent = grid,
	})
	-- Cases carrées en pixels. On divise par l'échelle d'animation de la fenêtre : pendant l'ouverture
	-- en rebond, la taille affichée change mais la taille des cases ne doit pas bouger.
	local function resizeCells()
		local scale = math.max(0.01, panel.scale.Scale)
		local width = grid.AbsoluteSize.X / scale - 14
		if width <= 0 then
			return
		end
		local gap = math.floor(width * 0.025)
		local cell = math.floor((width - gap * (columns - 1)) / columns)
		layout.CellPadding = UDim2.fromOffset(gap, gap)
		layout.CellSize = UDim2.fromOffset(cell, cell)
	end
	grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeCells)
	resizeCells()

	---------------------------------------------------------------- fiche de droite
	local detail: Frame = create("Frame", {
		Name = "Detail",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.655, 0.075),
		Size = UDim2.fromScale(0.32, 0.88),
		ZIndex = 4,
		Parent = content,
	})
	local detailW, detailH = panel.cells(0.32, 0.88)
	local detailBlock = PixelFx.block({
		parent = detail,
		palette = palettes.Lime,
		style = style,
		wCells = detailW,
		hCells = detailH,
		rays = UDim2.fromScale(0.5, 0.34),
	})
	local function detailText(name: string, y: number, h: number, x: number?, align: Enum.TextXAlignment?, color: Color3?): TextLabel
		local anchorX = if align == Enum.TextXAlignment.Left then 0 elseif align == Enum.TextXAlignment.Right then 1 else 0.5
		local label, _ = PixelFx.text({
			parent = detail,
			name = name,
			text = "",
			font = style.ButtonFont,
			color = color,
			anchor = Vector2.new(anchorX, 0.5),
			xAlign = align,
			position = UDim2.fromScale(x or 0.5, y),
			size = UDim2.fromScale(if align then 0.46 else 0.9, h),
			zIndex = 6,
			strokeRatio = style.TextStroke,
		})
		return label
	end
	local title = detailText("Title", 0.075, 0.085)
	local viewHolder: Frame = create("Frame", {
		Name = "ViewHolder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.34),
		Size = UDim2.fromScale(0.8, 0.36),
		ZIndex = 6,
		Parent = detail,
	})
	local subtitle = detailText("Subtitle", 0.56, 0.05)
	local powerName = detailText("PowerName", 0.66, 0.05, 0.08, Enum.TextXAlignment.Left)
	local powerValue = detailText("PowerValue", 0.66, 0.05, 0.92, Enum.TextXAlignment.Right, YELLOW)
	local priceName = detailText("PriceName", 0.735, 0.05, 0.08, Enum.TextXAlignment.Left)
	local priceValue = detailText("PriceValue", 0.735, 0.05, 0.92, Enum.TextXAlignment.Right, YELLOW)
	powerName.Text = texts.PowerStat
	priceName.Text = texts.PriceStat

	local actionW, actionH = panel.cells(0.32 * 0.84, 0.88 * 0.13)
	local actionButton = PixelButton.action({
		parent = detail,
		name = "Action",
		text = texts.Equip,
		palette = palettes.Lime,
		position = UDim2.fromScale(0.5, 0.88),
		size = UDim2.fromScale(0.84, 0.13),
		wCells = actionW,
		hCells = actionH,
		zIndex = 6,
		textScale = 0.5,
	})

	local function showDetail()
		local id = selected
		local def = if id then Rockets.get(id) else nil
		detail.Visible = def ~= nil
		if def == nil then
			return
		end
		local known = isKnown(def.id)
		detailBlock.setPalette(if known then worldPalette(def.world) else palettes.Red)
		title.Text = if known then def.name else texts.Unknown
		viewHolder:ClearAllChildren()
		local view = rocketView(viewHolder, def, not known, 7)
		view.Position = UDim2.fromScale(0.5, 0.5)
		view.Size = UDim2.fromScale(1, 1)
		local worldDef = Rockets.Worlds[def.world]
		subtitle.Text = if known and worldDef then worldDef.name else texts.Unknown
		powerValue.Text = if known then "x" .. FormatNumber.multiplier(def.multiplier) else texts.Unknown
		priceValue.Text = if def.cost <= 0 then texts.Free else FormatNumber.short(def.cost)
		if known then
			local isEquipped = equipped == def.id
			actionButton.setText(if isEquipped then texts.Equipped else texts.Equip)
			actionButton.setPalette(if isEquipped then palettes.Locked else palettes.Lime)
		else
			actionButton.setText(string.format(texts.Buy, FormatNumber.short(def.cost)))
			actionButton.setPalette(palettes.Lime)
		end
	end

	actionButton.onClick(function()
		local id = selected
		if id == nil then
			return
		end
		if isKnown(id) then
			if equipped ~= id then
				actions.onEquip(id)
			end
		else
			actions.onBuy(id)
		end
	end)

	---------------------------------------------------------------- cartes
	local cards: { [number]: Card } = {}

	local function select(id: number)
		local previous = selected
		if previous and cards[previous] then
			cards[previous].setSelected(false)
		end
		selected = id
		local card = cards[id]
		if card then
			card.setSelected(true)
		end
		showDetail()
	end

	local function makeCard(def: Rockets.RocketDef, order: number)
		local known = isKnown(def.id)
		local slot: Frame = create("Frame", {
			Name = def.key,
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Parent = grid,
		})
		local button: TextButton = create("TextButton", {
			Name = "Button",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
			Parent = slot,
		})
		local block = PixelFx.block({
			parent = button,
			palette = if known then worldPalette(def.world) else palettes.Locked,
			style = style,
			wCells = 0.95,
			hCells = 0.95,
			zIndex = 5,
		})
		local view = rocketView(button, def, not known, 9)
		view.Position = UDim2.fromScale(0.5, 0.42)
		view.Size = UDim2.fromScale(0.7, 0.62)
		PixelFx.text({
			parent = button,
			name = "Name",
			text = if known then def.name else texts.Unknown,
			font = style.ButtonFont,
			position = UDim2.fromScale(0.5, 0.84),
			size = UDim2.fromScale(0.92, 0.2),
			zIndex = 10,
			strokeRatio = 0.13,
		})
		-- « E » vert sur la fusée équipée.
		local marker: Frame = create("Frame", {
			Name = "Equipped",
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.85, 0.14),
			Size = UDim2.fromScale(0.26, 0.26),
			Visible = false,
			ZIndex = 11,
			Parent = button,
		})
		PixelFx.vgradient(marker, palettes.BadgeGreen.top, palettes.BadgeGreen.bottom)
		PixelFx.corner(marker, 0.25)
		PixelFx.border(marker)
		PixelFx.text({
			parent = marker,
			name = "E",
			text = "E",
			font = style.ButtonFont,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.8, 0.8),
			zIndex = 12,
			strokeRatio = 0.14,
		})
		button.MouseEnter:Connect(block.playShine)
		button.Activated:Connect(function()
			block.playShine()
			select(def.id)
		end)
		cards[def.id] = {
			setSelected = function(on: boolean)
				block.outline.Color = if on then YELLOW else BLACK
			end,
			setEquipped = function(on: boolean)
				marker.Visible = on
			end,
		}
	end

	local function rebuild()
		for _, child in grid:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		table.clear(cards)

		local list: { Rockets.RocketDef } = {}
		if isIndex then
			list = Rockets.forWorld(world)
		else
			for _, def in Rockets.List do
				if owned[def.id] then
					table.insert(list, def)
				end
			end
		end
		local knownInList = 0
		for order, def in list do
			makeCard(def, order)
			cards[def.id].setEquipped(def.id == equipped)
			if isKnown(def.id) then
				knownInList += 1
			end
		end

		-- Garde la sélection si possible, sinon la fusée équipée, sinon la première.
		local keep: number? = nil
		if selected and cards[selected] then
			keep = selected
		elseif equipped and cards[equipped] then
			keep = equipped
		elseif list[1] then
			keep = list[1].id
		end
		selected = nil
		if keep then
			select(keep)
		else
			showDetail()
		end

		if collection then
			collection.set(if #list > 0 then knownInList / #list else 0, knownInList .. "/" .. #list)
		end
		if counter then
			counter.set(1, ownedCount .. "/" .. #Rockets.List)
		end
	end

	---------------------------------------------------------------- onglets des mondes (Index)
	if isIndex then
		local tabs: { [number]: PixelButton.Action } = {}
		local function refreshTabs()
			for worldId, tab in tabs do
				tab.setPalette(if worldId == world then worldPalette(worldId) else palettes.Locked)
			end
			local worldDef = Rockets.Worlds[world]
			heading.Text = if worldDef then string.upper(worldDef.name) else texts.Category
		end
		for index, worldDef in Rockets.Worlds do
			local tabW, tabH = panel.cells(0.13 * HEIGHT / WIDTH, 0.13)
			local tab = PixelButton.action({
				parent = content,
				name = "World" .. worldDef.id,
				text = tostring(worldDef.id),
				palette = palettes.Locked,
				position = UDim2.fromScale(0.06, 0.2 + (index - 1) * 0.165),
				size = UDim2.fromScale(1, 0.13),
				square = true,
				wCells = tabW,
				hCells = tabH,
				zIndex = 5,
				textScale = 0.5,
			})
			tabs[worldDef.id] = tab
			tab.onClick(function()
				world = worldDef.id
				refreshTabs()
				rebuild()
			end)
		end
		refreshTabs()
	end

	rebuild()

	return {
		panel = panel,
		setActions = function(newActions: Actions)
			actions = newActions
		end,
		setOwned = function(ids: { number })
			table.clear(owned)
			ownedCount = 0
			for _, id in ids do
				if not owned[id] then
					owned[id] = true
					ownedCount += 1
				end
			end
			rebuild()
		end,
		setEquipped = function(id: number?)
			equipped = id
			for cardId, card in cards do
				card.setEquipped(cardId == id)
			end
			showDetail()
		end,
	}
end

return RocketsPanel
end)()

----------------------------------------------------------------------------------------------------
-- HudController  (source : src/client/Controllers/HudController.luau)
----------------------------------------------------------------------------------------------------
__modules.HudController = (function()
-- HudController.luau — construit l'interface « PixelHud » (menu, compteurs, barre, fenêtres), l'adapte à la
-- taille de l'écran et l'alimente avec les valeurs du joueur (leaderstats Wins / Rebirths / Power +
-- attributs Boost, RebirthCost, NextBoost, OwnedRockets, EquippedRocket).
--
-- Clic sur un bouton du menu :
--   • Rebirth, Backpack, Index, Settings → ouvre / ferme leur fenêtre (fond flouté, comme dans la vidéo) ;
--   • bouton marqué `comingSoon` ou sans fenêtre → « Trails coming soon! » en haut de l'écran.
--
-- Depuis un autre script client (version Rojo) :
--   local HudController = require(path.to.Controllers.HudController)
--   HudController.OnButton("Shop", function() ... end)          -- remplace l'action d'un bouton du menu
--   HudController.On("Rebirth", function() remote:FireServer() end)  -- bouton vert « Rebirth »
--   HudController.On("SkipRebirth", function() ... end)          -- bouton violet « Skip Rebirth »
--   HudController.On("Equip", function(id) ... end)              -- bouton EQUIP du Backpack
--   HudController.On("Buy", function(id) ... end)                -- bouton d'achat de l'Index
--   HudController.On("Setting", function(name, value) ... end)   -- réglages (Music, Sound, ReducedMotion)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HudConfig = __modules.HudConfig
local Rockets = __modules.Rockets
local PixelFx = __modules.PixelFx
local PixelButton = __modules.PixelButton
local PixelPanel = __modules.PixelPanel
local StatsHud = __modules.StatsHud
local RebirthPanel = __modules.RebirthPanel
local SettingsPanel = __modules.SettingsPanel
local RocketsPanel = __modules.RocketsPanel

local create = PixelFx.create

local HudController = {}

local buttons: { [string]: PixelButton.Handle } = {}
local handlers: { [string]: { () -> () } } = {}
local listeners: { [string]: { (...any) -> () } } = {}
local panels: { [string]: PixelPanel.Panel } = {}
local screenGui: ScreenGui? = nil
local fxLayer: Frame? = nil

type State = {
	wins: number,
	rebirths: number,
	power: number,
	boost: number,
	cost: number,
	nextBoost: number,
	owned: { number },
	equipped: number?,
}

-- Remplace l'action d'un bouton du menu (« Shop », « Rebirth »…).
function HudController.OnButton(id: string, callback: () -> ())
	local list = handlers[id] or {}
	handlers[id] = list
	table.insert(list, callback)
end

-- Écoute une action des fenêtres : "Rebirth", "SkipRebirth", "Equip" (id), "Buy" (id), "Setting" (nom, valeur).
function HudController.On(event: string, callback: (...any) -> ())
	local list = listeners[event] or {}
	listeners[event] = list
	table.insert(list, callback)
end

local function fire(event: string, ...: any): boolean
	local list = listeners[event]
	if list == nil or #list == 0 then
		return false
	end
	for _, callback in list do
		task.spawn(callback, ...)
	end
	return true
end

function HudController.GetButton(id: string): PixelButton.Handle?
	return buttons[id]
end

function HudController.OpenPanel(id: string)
	local panel = panels[id]
	if panel then
		panel.open()
	end
end

-- Message centré en haut de l'écran (ex. « Trails coming soon! »).
function HudController.Banner(text: string)
	local layer = fxLayer
	if layer then
		PixelFx.banner(layer, text, HudConfig.Style.ButtonFont)
	end
end

function HudController.SetVisible(visible: boolean)
	local gui = screenGui
	if gui == nil then
		return
	end
	if not visible then
		PixelPanel.closeCurrent()
		for _, handle in buttons do
			handle.reset()
		end
	end
	gui.Enabled = visible
end

local function onButtonClicked(def: HudConfig.ButtonDef)
	if def.comingSoon then
		HudController.Banner(string.format(HudConfig.Texts.ComingSoon, def.label))
		return
	end
	local list = handlers[def.id]
	if list ~= nil and #list > 0 then
		for _, callback in list do
			task.spawn(callback)
		end
		return
	end
	local panel = panels[def.id]
	if panel then
		panel.toggle()
	else
		HudController.Banner(string.format(HudConfig.Texts.ComingSoon, def.label))
	end
end

-- Colonne de boutons de gauche. Renvoie le cadre et son rapport largeur / hauteur.
local function buildMenu(screen: ScreenGui, fx: Frame): (Frame, number)
	local layout = HudConfig.Layout
	local columns = layout.Columns
	local gap = layout.Gap

	local function rowHeight(row: number): number
		return layout.RowHeights[row] or 1
	end

	local lastRow = 1
	for _, def in HudConfig.Buttons do
		lastRow = math.max(lastRow, def.row)
	end
	local rowTop: { number } = {}
	local y = 0
	for row = 1, lastRow do
		rowTop[row] = y
		y += rowHeight(row)
		if row < lastRow then
			y += gap
		end
	end
	local totalH = y
	local totalW = columns + (columns - 1) * gap
	local aspect = totalW / totalH

	local menu: Frame = create("Frame", {
		Name = "LeftMenu",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, layout.Margin, layout.CenterY, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Size = UDim2.fromScale(layout.HeightOfScreen * aspect, layout.HeightOfScreen),
		Parent = screen,
	})

	for _, def in HudConfig.Buttons do
		local span = def.span or 1
		local wCells = span + (span - 1) * gap
		local hCells = rowHeight(def.row)
		local x = (def.col - 1) * (1 + gap)
		local handle = PixelButton.new(def, menu, {
			position = UDim2.fromScale(x / totalW, rowTop[def.row] / totalH),
			size = UDim2.fromScale(wCells / totalW, hCells / totalH),
			wCells = wCells,
			hCells = hCells,
		}, fx)
		buttons[def.id] = handle
		handle.onClick(function()
			onButtonClicked(def)
		end)
	end

	return menu, aspect
end

local function parseIds(value: any): { number }
	local ids: { number } = {}
	if typeof(value) == "string" then
		for piece in string.gmatch(value, "%d+") do
			local id = tonumber(piece)
			if id then
				table.insert(ids, id)
			end
		end
	end
	return ids
end

-- Lit les valeurs du joueur et met l'interface à jour à chaque changement.
local function startData(
	player: Player,
	stats: StatsHud.Handle,
	rebirth: RebirthPanel.Handle,
	backpack: RocketsPanel.Handle,
	index: RocketsPanel.Handle
)
	local cfg = HudConfig.Stats
	local texts = HudConfig.Texts
	local state: State = {
		wins = 0,
		rebirths = 0,
		power = 0,
		boost = 1,
		cost = 0,
		nextBoost = 0,
		owned = {},
		equipped = nil,
	}
	local live = false -- true dès que de vraies leaderstats sont branchées
	local demo = false

	local function currentCost(): number
		return if state.cost > 0 then state.cost else HudConfig.RebirthCost(state.rebirths)
	end

	local function refresh()
		local cost = currentCost()
		local nextBoost = if state.nextBoost > 0 then state.nextBoost else HudConfig.NextBoost(state.boost, state.rebirths)
		stats.setRebirths(state.rebirths)
		stats.setWins(state.wins)
		stats.setBoost(state.boost)
		stats.setPower(state.power, cost)
		rebirth.update({ power = state.power, cost = cost, boost = state.boost, nextBoost = nextBoost })
		local progressButton = buttons[cfg.ProgressButton]
		if progressButton then
			local percent = if cost > 0 then math.clamp(math.floor(state.power / cost * 100), 0, 100) else 0
			if percent >= 100 then
				progressButton.setBadge(texts.Ready, "BadgeGreen")
			else
				progressButton.setBadge(tostring(percent) .. "%", "BadgeBlue")
			end
			progressButton.setPulse(percent >= 100)
		end
	end

	local function refreshRockets()
		backpack.setOwned(state.owned)
		index.setOwned(state.owned)
		backpack.setEquipped(state.equipped)
		index.setEquipped(state.equipped)
	end

	-- Actions des fenêtres. Si aucun script ne les écoute : simulation en mode démo, message sinon.
	local rebirthActions = {
		onRebirth = function()
			if state.power < currentCost() then
				HudController.Banner(texts.NotEnoughPower)
				return
			end
			if fire("Rebirth") then
				return
			end
			if demo then
				local nextBoost = if state.nextBoost > 0 then state.nextBoost else HudConfig.NextBoost(state.boost, state.rebirths)
				state.rebirths += 1
				state.power = 0
				state.boost = nextBoost
				state.cost = HudConfig.RebirthCost(state.rebirths)
				state.nextBoost = 0
				refresh()
				PixelPanel.closeCurrent()
			else
				warn("[PixelHud] Bouton Rebirth : branche-le avec HudController.On(\"Rebirth\", …)")
			end
		end,
		onSkip = function()
			if not fire("SkipRebirth") then
				HudController.Banner(string.format(texts.ComingSoon, texts.SkipRebirth))
			end
		end,
	}
	rebirth.setActions(rebirthActions)

	local function equip(id: number)
		if fire("Equip", id) then
			return
		end
		state.equipped = id -- sans serveur : seulement à l'écran
		refreshRockets()
	end
	local function buy(id: number)
		if fire("Buy", id) then
			return
		end
		local def = Rockets.get(id)
		if def and demo and state.wins >= def.cost then
			state.wins -= def.cost
			table.insert(state.owned, id)
			refresh()
			refreshRockets()
		else
			HudController.Banner(texts.NotEnoughWins)
		end
	end
	backpack.setActions({ onEquip = equip, onBuy = buy })
	index.setActions({ onEquip = equip, onBuy = buy })

	-- Branchements (refaits si le serveur recrée leaderstats).
	local bindings: { RBXScriptConnection } = {}
	local function unbind()
		for _, connection in bindings do
			connection:Disconnect()
		end
		table.clear(bindings)
	end

	local function bindNumber(folder: Instance, name: string, apply: (number) -> ())
		local function try(child: Instance)
			if child.Name ~= name then
				return
			end
			if child:IsA("IntValue") then
				apply(child.Value)
				table.insert(bindings, child.Changed:Connect(apply))
			elseif child:IsA("NumberValue") then
				apply(child.Value)
				table.insert(bindings, child.Changed:Connect(apply))
			end
		end
		for _, child in folder:GetChildren() do
			try(child)
		end
		table.insert(bindings, folder.ChildAdded:Connect(try))
	end

	local function bindAttribute(name: string, apply: (any) -> ())
		local function read()
			apply(player:GetAttribute(name))
		end
		table.insert(bindings, player:GetAttributeChangedSignal(name):Connect(read))
		read()
	end

	local function toNumber(value: any, default: number): number
		return if typeof(value) == "number" and value == value then value else default
	end

	local function bindFolder(folder: Instance)
		unbind()
		live, demo = true, false
		state.wins, state.rebirths, state.power = 0, 0, 0
		bindNumber(folder, cfg.Wins, function(value: number)
			state.wins = value
			refresh()
		end)
		bindNumber(folder, cfg.Rebirths, function(value: number)
			state.rebirths = value
			refresh()
		end)
		bindNumber(folder, cfg.Power, function(value: number)
			state.power = value
			refresh()
		end)
		bindAttribute(cfg.BoostAttribute, function(value: any)
			state.boost = toNumber(value, 1)
			refresh()
		end)
		bindAttribute(cfg.RebirthCostAttribute, function(value: any)
			state.cost = toNumber(value, 0)
			refresh()
		end)
		bindAttribute(cfg.NextBoostAttribute, function(value: any)
			state.nextBoost = toNumber(value, 0)
			refresh()
		end)
		bindAttribute(cfg.OwnedAttribute, function(value: any)
			state.owned = parseIds(value)
			refreshRockets()
		end)
		bindAttribute(cfg.EquippedAttribute, function(value: any)
			state.equipped = if typeof(value) == "number" then value else nil
			refreshRockets()
		end)
		refresh()
	end

	player.ChildAdded:Connect(function(child: Instance)
		if child.Name == cfg.Folder then
			bindFolder(child)
		end
	end)
	local existing = player:FindFirstChild(cfg.Folder)
	if existing then
		bindFolder(existing)
		return
	end
	refresh()
	refreshRockets()

	-- Pas encore de leaderstats (jeu sans serveur) : valeurs de démonstration, dans Studio seulement.
	task.delay(cfg.WaitForFolder, function()
		if live or not HudConfig.Demo.Enabled or not RunService:IsStudio() then
			return
		end
		local values = HudConfig.Demo
		demo = true
		state.wins, state.rebirths, state.power = values.Wins, values.Rebirths, values.Power
		state.boost, state.cost = values.Boost, values.RebirthCost
		state.owned = table.clone(values.Owned)
		state.equipped = values.Equipped
		refresh()
		refreshRockets()
	end)
end

-- Construit l'interface (une seule fois) et la branche sur les données du joueur.
function HudController.Start()
	if screenGui then
		return
	end
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("PixelHud")
	if old then
		old:Destroy()
	end

	local screen: ScreenGui = create("ScreenGui", {
		Name = "PixelHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 5,
	})
	screenGui = screen

	-- Couche d'effets (cubes, messages) au-dessus de tout ; elle ne bloque pas les clics.
	local fx: Frame = create("Frame", {
		Name = "Fx",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 40,
		Parent = screen,
	})
	fxLayer = fx

	local layout = HudConfig.Layout
	local menu, aspect = buildMenu(screen, fx)
	local stats = StatsHud.new(screen, layout.Margin)

	-- Fenêtres.
	local rebirth = RebirthPanel.new(screen)
	local backpack = RocketsPanel.new(screen, "Backpack")
	local index = RocketsPanel.new(screen, "Index")
	local settings = SettingsPanel.new(screen, {
		onChange = function(name: string, value: number | boolean)
			fire("Setting", name, value)
		end,
	})
	panels.Rebirth = rebirth.panel
	panels.Backpack = backpack.panel
	panels.Index = index.panel
	panels.Settings = settings.panel

	-- Sur petit écran (téléphone), tout est un peu plus grand pour rester cliquable.
	local function relayout()
		local size = screen.AbsoluteSize
		if size.Y <= 0 then
			return
		end
		local small = size.Y < layout.SmallScreenHeight
		local height = if small then layout.HeightOfScreenSmall else layout.HeightOfScreen
		menu.Size = UDim2.fromScale(height * aspect, height)
		menu.Position = UDim2.new(0, layout.Margin, if small then 0.44 else layout.CenterY, 0)
		stats.relayout(size, small)
	end
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)

	screen.Parent = playerGui
	relayout()
	startData(player, stats, rebirth, backpack, index)
end

return HudController
end)()

----------------------------------------------------------------------------------------------------
-- Démarrage  (source : src/client/Main.client.luau)
----------------------------------------------------------------------------------------------------
-- Main.client.luau — point d'entrée côté client : affiche l'interface « pixel cubique ».

local HudController = __modules.HudController

HudController.Start()
