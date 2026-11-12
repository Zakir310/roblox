--!strict
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

export type TextOpts = {
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
export type BlockStyle = {
	OutlineCells: number,
	CornerCells: number,
	LipCells: number,
	StudPitch: number,
	StudSize: number,
	RayColor: Color3,
	Outline: Color3,
}

export type Palette = { top: Color3, bottom: Color3, lip: Color3 }

export type BlockOpts = {
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

export type Block = {
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

export type ProgressBar = {
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
