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
