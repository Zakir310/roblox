--!strict
-- PixelButton.luau — un bouton du menu de gauche, à l'identique de la capture :
--   contour noir épais, dégradé de couleur, rebord 3D sombre en bas, cubes en relief (pixel cubique),
--   reflet qui balaie le bouton (brillant), étincelles, badge penché qui se balance (« HOT! », « SOON »).
-- Au survol de la souris : le bouton grossit, l'icône se soulève, grossit, se balance et flotte.
-- Au clic : le bouton rebondit et une gerbe de petits cubes jaillit de l'icône.

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
