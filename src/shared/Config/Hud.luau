--!strict
-- Hud.luau — configuration de l'interface « pixel cubique » (colonne de boutons à gauche, compteurs en bas
-- à gauche, barre de puissance en bas au centre).
--
-- C'est LE fichier à modifier pour changer les icônes, les textes, les couleurs et les badges.
--
-- ICÔNES : chaque icône est `{ image = "rbxassetid://…", emoji = "🛒" }`.
--   - Tant que `image` est vide, l'emoji sert d'icône provisoire.
--   - Importe ton image dans Studio (Asset Manager → Import, ou Creator Hub → Images), copie son ID
--     et colle-le dans `image`, par exemple `image = "rbxassetid://1234567890"`.

export type Palette = { top: Color3, bottom: Color3, lip: Color3 }
export type IconDef = { image: string?, emoji: string? }
export type BadgeDef = { text: string, palette: string?, rotation: number? }
export type ButtonDef = {
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
