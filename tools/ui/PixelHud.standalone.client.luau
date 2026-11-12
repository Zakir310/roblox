--!nocheck
-- PixelHud.standalone.client.luau — GÉNÉRÉ par tools/ui/build_standalone.py, ne pas éditer à la main
-- (modifie les fichiers de src/ puis relance le script).
--
-- Interface « pixel cubique » en un seul LocalScript, pour l'utiliser sans Rojo :
--   1. Dans Studio : StarterPlayer > StarterPlayerScripts > + > LocalScript, nomme-le PixelHud.
--   2. Colle tout ce fichier dedans, puis Play.
--   3. Pour tes icônes : modifie la section CONFIGURATION juste en dessous (champ `image`).

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
	ComingSoon = "Coming soon!",
	NotConnected = "%s : bientôt branché",
}

-- Où lire les valeurs du joueur.
Hud.Stats = {
	Folder = "leaderstats",
	Wins = "Wins",
	Rebirths = "Rebirths",
	Power = "Power",
	BoostAttribute = "Boost", -- attribut numérique posé sur le Player par le serveur (ex. 10.5)
	RebirthCostAttribute = "RebirthCost", -- attribut numérique : Power nécessaire au prochain rebirth
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
}

return Hud
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
			local shadow = create("Frame", {
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
			PixelFx.corner(shadow, 0.22)
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
	tween(holder, RAYS_INFO, { Rotation = 360 })
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

-- Petit message flottant (ex. « Coming soon! ») qui apparaît en rebondissant puis s'envole.
function PixelFx.toast(layer: GuiObject, at: Vector2, text: string, font: Font, unit: number)
	local origin = at - layer.AbsolutePosition
	local label, _ = PixelFx.text({
		parent = layer,
		name = "Toast",
		text = text,
		font = font,
		color = Color3.fromRGB(255, 230, 0),
		anchor = Vector2.new(0, 0.5),
		xAlign = Enum.TextXAlignment.Left,
		position = UDim2.fromOffset(origin.X, origin.Y),
		size = UDim2.fromOffset(unit * 2.6 * 0.6, unit * 0.34 * 0.6),
		maxSize = unit * 0.3,
		zIndex = 60,
	})
	local stroke = label:FindFirstChildOfClass("UIStroke")
	tween(label, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(unit * 2.6, unit * 0.34),
	})
	tween(label, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(origin.X, origin.Y - unit * 0.45),
	})
	local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.9)
	local vanish = tween(label, fade, { TextTransparency = 1 })
	if stroke then
		tween(stroke, fade, { Transparency = 1 })
	end
	vanish.Completed:Once(function()
		label:Destroy()
	end)
end

return PixelFx
end)()

----------------------------------------------------------------------------------------------------
-- PixelButton  (source : src/client/UI/PixelButton.luau)
----------------------------------------------------------------------------------------------------
__modules.PixelButton = (function()
-- PixelButton.luau — un bouton du menu de gauche, à l'identique de la capture :
--   contour noir épais, dégradé de couleur, rebord 3D sombre en bas, cubes en relief (pixel cubique),
--   reflet qui balaie le bouton (brillant), étincelles, badge penché qui se balance (« HOT! », « SOON »).
-- Au survol de la souris : le bouton grossit, l'icône se soulève, grossit, se balance et flotte.
-- Au clic : le bouton rebondit et une gerbe de petits cubes jaillit de l'icône.

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
	setBadge: (text: string?) -> (),
	setPulse: (on: boolean) -> (),
	onClick: (callback: () -> ()) -> (),
	shine: () -> (),
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

local function isTouchOnly(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function px(value: number): number
	return math.max(1, math.floor(value + 0.5))
end

function PixelButton.new(def: HudConfig.ButtonDef, parent: Instance, geom: Geometry, fxLayer: GuiObject): Handle
	local style = HudConfig.Style
	local palette = HudConfig.Palettes[def.palette] or HudConfig.Palettes.Amber
	local w, h = geom.wCells, geom.hCells
	local wide = w > h * 1.5
	local cornerScale = style.CornerCells / math.min(w, h)

	-- Emplacement fixe dans la grille : le bouton à l'intérieur peut grossir sans décaler les autres.
	local slot: Frame = create("Frame", {
		Name = def.id,
		BackgroundTransparency = 1,
		Position = geom.position,
		Size = geom.size,
		Parent = parent,
	})
	local button: TextButton = create("TextButton", {
		Name = "Button",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Parent = slot,
	})

	-- Taille d'une case en pixels (suit le grossissement du bouton au survol).
	local function cellSize(): number
		return button.AbsoluteSize.Y / h
	end

	-- Corps : fond = couleur du rebord, contour noir.
	local body: Frame = create("Frame", {
		Name = "Body",
		BackgroundColor3 = palette.lip,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = button,
	})
	PixelFx.corner(body, cornerScale)
	local outline = PixelFx.border(body, style.Outline)

	-- Face : CanvasGroup arrondi qui découpe proprement cubes, rayons et reflet aux coins.
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
	PixelFx.vgradient(fill, palette.top, palette.bottom)
	PixelFx.studs(face, w, h, style.StudPitch, style.StudSize, 2)

	local iconCenter = if wide then Vector2.new(0.58 / w, 0.47) else Vector2.new(0.5, 0.4)
	if def.rays then
		PixelFx.rays(face, UDim2.fromScale(iconCenter.X, iconCenter.Y), UDim2.fromScale(2, 2), style.RayColor, 3)
	end
	PixelFx.gloss(face, 4)
	create("Frame", {
		Name = "Lip",
		BackgroundColor3 = palette.lip,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, style.LipCells / h),
		ZIndex = 5,
		Parent = face,
	})
	local playShine = PixelFx.shine(face, w, h, 6)

	-- Icône (au-dessus du corps, elle peut déborder un peu comme sur la capture).
	local icon = PixelFx.icon(button, def.icon, 3)
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
		parent = button,
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
			Parent = button,
		})
		PixelFx.vgradient(frame, badgePalette.top, badgePalette.bottom)
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
		tween(frame, BADGE_WOBBLE, { Rotation = rotation + 3 })
		badgeFrame, badgeLabel, badgeLimit = frame, label, limit
	end

	-- Étincelles réutilisées (3 par bouton).
	local sparkles = { PixelFx.sparkle(button, 8), PixelFx.sparkle(button, 8), PixelFx.sparkle(button, 8) }
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

	-- Épaisseurs et tailles de texte en pixels, recalculées quand l'écran change de taille.
	local function relayout()
		local cell = cellSize()
		if cell <= 0 then
			return
		end
		outline.Thickness = px(cell * style.OutlineCells)
		labelLimit.MaxTextSize = px(cell * labelCells)
		if badgeLimit then
			badgeLimit.MaxTextSize = px(cell * 0.145)
		end
		if badgeOutline then
			badgeOutline.Thickness = px(cell * 0.026)
		end
	end
	button:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()

	-- SURVOL : l'icône bouge.
	local hovered = false
	local hoverToken = 0
	local loops: { Tween } = {}

	local function stopLoops()
		for _, loop in loops do
			loop:Cancel()
		end
		table.clear(loops)
	end

	local function setHover(on: boolean)
		if hovered == on then
			return
		end
		hovered = on
		hoverToken += 1
		local token = hoverToken
		stopLoops()
		if on then
			tween(button, HOVER_IN, { Size = UDim2.fromScale(style.HoverScale, style.HoverScale) })
			local lift = tween(icon, HOVER_IN, { Position = liftPos, Size = liftSize })
			local tilt = tween(icon, TILT, { Rotation = -style.IconWiggle })
			-- Une fois penchée, l'icône se balance de gauche à droite tant que la souris reste dessus…
			tilt.Completed:Once(function(state)
				if state == Enum.PlaybackState.Completed and token == hoverToken then
					table.insert(loops, tween(icon, WIGGLE, { Rotation = style.IconWiggle }))
				end
			end)
			-- … et flotte doucement de haut en bas.
			lift.Completed:Once(function(state)
				if state == Enum.PlaybackState.Completed and token == hoverToken then
					table.insert(loops, tween(icon, BOB, { Position = bobPos }))
				end
			end)
			playShine()
			for _ = 1, #sparkles do
				twinkleOne()
			end
		else
			tween(button, HOVER_OUT, { Size = UDim2.fromScale(1, 1) })
			tween(icon, HOVER_OUT, { Position = restPos, Size = restSize, Rotation = 0 })
		end
	end

	button.MouseEnter:Connect(function()
		if not isTouchOnly() then
			setHover(true)
		end
	end)
	-- Remet le bouton à sa taille de repos (doigt ou souris relâché sans clic).
	local lastPop = 0
	local function release()
		if os.clock() - lastPop < 0.15 then
			return
		end
		local rest = if hovered then style.HoverScale else 1
		tween(button, POP_BACK, { Size = UDim2.fromScale(rest, rest) })
	end

	button.MouseLeave:Connect(function()
		if isTouchOnly() then
			release()
		else
			setHover(false)
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
			release()
		end
	end)
	button.SelectionGained:Connect(function()
		setHover(true)
	end)
	button.SelectionLost:Connect(function()
		setHover(false)
	end)

	-- CLIC : enfoncement, rebond, gerbe de cubes.
	local callbacks: { () -> () } = {}
	local cubeColors = { palette.top, palette.bottom, table.unpack(style.CubeColors) }

	button.MouseButton1Down:Connect(function()
		tween(button, PRESS, { Size = UDim2.fromScale(0.93, 0.93) })
	end)

	button.Activated:Connect(function()
		lastPop = os.clock()
		if isTouchOnly() then
			-- Pas de souris sur mobile : l'icône bouge quand on touche le bouton.
			setHover(true)
			local token = hoverToken
			task.delay(0.8, function()
				if token == hoverToken then
					setHover(false)
				end
			end)
		end
		local up = tween(button, POP_UP, { Size = UDim2.fromScale(style.HoverScale * 1.07, style.HoverScale * 1.07) })
		up.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				local rest = if hovered then style.HoverScale else 1
				tween(button, POP_BACK, { Size = UDim2.fromScale(rest, rest) })
			end
		end)
		PixelFx.cubeBurst(fxLayer, icon.AbsolutePosition + icon.AbsoluteSize / 2, cellSize(), cubeColors)
		playShine()
		for _, callback in callbacks do
			task.spawn(callback)
		end
	end)

	-- Reflets et étincelles automatiques, décalés d'un bouton à l'autre.
	local alive = true
	slot.Destroying:Connect(function()
		alive = false
	end)
	task.spawn(function()
		local nextShine = os.clock() + math.random() * style.ShineEvery.Max
		local nextSparkle = os.clock() + randomIn(style.SparkleEvery)
		while alive do
			task.wait(0.25)
			local now = os.clock()
			if now >= nextShine then
				playShine()
				nextShine = now + randomIn(style.ShineEvery)
			end
			if now >= nextSparkle then
				twinkleOne()
				nextSparkle = now + randomIn(style.SparkleEvery) * (if hovered then 0.3 else 1)
			end
		end
	end)

	-- Badge : changer le texte (nil ou "" = caché) et faire pulser.
	local pulse: Tween? = nil

	local function setBadge(text: string?)
		if badgeFrame == nil or badgeLabel == nil then
			return
		end
		if text == nil or text == "" then
			badgeFrame.Visible = false
		else
			badgeFrame.Visible = true
			badgeLabel.Text = text
		end
	end

	local function setPulse(on: boolean)
		if badgeFrame == nil then
			return
		end
		if on and pulse == nil then
			pulse = tween(badgeFrame, BADGE_PULSE, {
				Size = UDim2.fromScale(badgeSize.X.Scale * 1.15, badgeSize.Y.Scale * 1.15),
			})
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
		getCellSize = cellSize,
	}
end

return PixelButton
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
			if progress > 0 then
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
-- HudController  (source : src/client/Controllers/HudController.luau)
----------------------------------------------------------------------------------------------------
__modules.HudController = (function()
-- HudController.luau — construit l'interface « PixelHud », l'adapte à la taille de l'écran et l'alimente
-- avec les valeurs du joueur (leaderstats Wins / Rebirths / Power + attributs Boost et RebirthCost).
--
-- Brancher un bouton depuis un autre script client :
--   local HudController = require(path.to.Controllers.HudController)
--   HudController.OnButton("Shop", function()
--       print("ouvrir la boutique")
--   end)
-- Un bouton marqué `comingSoon = true` dans la config affiche « Coming soon! » au lieu d'appeler la fonction.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = __modules.HudConfig
local PixelFx = __modules.PixelFx
local PixelButton = __modules.PixelButton
local StatsHud = __modules.StatsHud

local create = PixelFx.create

local HudController = {}

local buttons: { [string]: PixelButton.Handle } = {}
local handlers: { [string]: { () -> () } } = {}
local screenGui: ScreenGui? = nil

type State = { wins: number, rebirths: number, power: number, boost: number, cost: number }

-- Appelle `callback` quand le joueur clique sur le bouton `id` (ex. "Shop", "Rebirth", "Settings").
function HudController.OnButton(id: string, callback: () -> ())
	local list = handlers[id] or {}
	handlers[id] = list
	table.insert(list, callback)
end

function HudController.GetButton(id: string): PixelButton.Handle?
	return buttons[id]
end

function HudController.SetVisible(visible: boolean)
	if screenGui then
		screenGui.Enabled = visible
	end
end

local function onButtonClicked(def: HudConfig.ButtonDef, handle: PixelButton.Handle, fx: Frame)
	local list = handlers[def.id]
	if not def.comingSoon and list ~= nil and #list > 0 then
		for _, callback in list do
			task.spawn(callback)
		end
		return
	end
	local position = handle.slot.AbsolutePosition
	local size = handle.slot.AbsoluteSize
	local at = Vector2.new(position.X + size.X + 8, position.Y + size.Y * 0.5)
	local text = if def.comingSoon
		then HudConfig.Texts.ComingSoon
		else string.format(HudConfig.Texts.NotConnected, def.label)
	PixelFx.toast(fx, at, text, HudConfig.Style.ButtonFont, handle.getCellSize())
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
			onButtonClicked(def, handle, fx)
		end)
	end

	return menu, aspect
end

-- Lit les valeurs du joueur et met l'interface à jour à chaque changement.
local function startData(player: Player, stats: StatsHud.Handle)
	local cfg = HudConfig.Stats
	local state: State = { wins = 0, rebirths = 0, power = 0, boost = 1, cost = 0 }
	local live = false

	local function refresh()
		local cost = if state.cost > 0 then state.cost else HudConfig.RebirthCost(state.rebirths)
		stats.setRebirths(state.rebirths)
		stats.setWins(state.wins)
		stats.setBoost(state.boost)
		stats.setPower(state.power, cost)
		local progressButton = buttons[cfg.ProgressButton]
		if progressButton then
			local percent = if cost > 0 then math.clamp(math.floor(state.power / cost * 100), 0, 100) else 0
			progressButton.setBadge(tostring(percent) .. "%")
			progressButton.setPulse(percent >= 100)
		end
	end

	local function bindNumber(folder: Instance, name: string, apply: (number) -> ())
		local function try(child: Instance)
			if child.Name ~= name then
				return
			end
			if child:IsA("IntValue") then
				apply(child.Value)
				child.Changed:Connect(apply)
			elseif child:IsA("NumberValue") then
				apply(child.Value)
				child.Changed:Connect(apply)
			end
		end
		for _, child in folder:GetChildren() do
			try(child)
		end
		folder.ChildAdded:Connect(try)
	end

	local function bindAttribute(name: string, apply: (number) -> ())
		local function read()
			local value = player:GetAttribute(name)
			if typeof(value) == "number" then
				apply(value)
			end
		end
		player:GetAttributeChangedSignal(name):Connect(read)
		read()
	end

	local function bindFolder(folder: Instance)
		live = true
		state.wins, state.rebirths, state.power, state.boost, state.cost = 0, 0, 0, 1, 0
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
		bindAttribute(cfg.BoostAttribute, function(value: number)
			state.boost = value
			refresh()
		end)
		bindAttribute(cfg.RebirthCostAttribute, function(value: number)
			state.cost = value
			refresh()
		end)
		refresh()
	end

	local existing = player:FindFirstChild(cfg.Folder)
	if existing then
		bindFolder(existing)
		return
	end

	local connection: RBXScriptConnection? = nil
	connection = player.ChildAdded:Connect(function(child: Instance)
		if child.Name == cfg.Folder and not live then
			if connection then
				connection:Disconnect()
			end
			bindFolder(child)
		end
	end)
	refresh()

	-- Pas encore de leaderstats (jeu sans serveur) : on affiche les valeurs de démonstration.
	task.delay(cfg.WaitForFolder, function()
		if live or not HudConfig.Demo.Enabled then
			return
		end
		local demo = HudConfig.Demo
		state.wins, state.rebirths, state.power = demo.Wins, demo.Rebirths, demo.Power
		state.boost, state.cost = demo.Boost, demo.RebirthCost
		refresh()
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

	local layout = HudConfig.Layout
	local menu, aspect = buildMenu(screen, fx)
	local stats = StatsHud.new(screen, layout.Margin)

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
	startData(player, stats)
end

return HudController
end)()

----------------------------------------------------------------------------------------------------
-- Démarrage  (source : src/client/Main.client.luau)
----------------------------------------------------------------------------------------------------
-- Main.client.luau — point d'entrée côté client : affiche l'interface « pixel cubique ».

local HudController = __modules.HudController

HudController.Start()
