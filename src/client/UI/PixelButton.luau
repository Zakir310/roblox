--!strict
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

local HudConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Hud")) -- @bundle:HudConfig
local PixelFx = require(script.Parent:WaitForChild("PixelFx")) -- @bundle:PixelFx

local create = PixelFx.create
local tween = PixelFx.tween

local PixelButton = {}

-- Emplacement du bouton dans la colonne : position/taille en échelle, taille en cases (1 = bouton carré).
export type Geometry = { position: UDim2, size: UDim2, wCells: number, hCells: number }

export type Handle = {
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

export type ActionOpts = {
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

export type Action = {
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
