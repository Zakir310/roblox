--!strict
-- PixelPanel.luau — fenêtre (Rebirth, Backpack, Index, Settings), comme dans la vidéo :
--   fond clair en plaque de briques, gros contour noir, icône penchée et titre posés sur le bord du haut,
--   bouton X rouge dans le coin ;
--   ouverture : la fenêtre jaillit en rebondissant (75 % → un peu plus de 100 % → 100 %) et le décor se floute ;
--   fermeture : elle rétrécit et disparaît, le flou s'en va. Une seule fenêtre ouverte à la fois.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Hud")) -- @bundle:HudConfig
local PixelFx = require(script.Parent:WaitForChild("PixelFx")) -- @bundle:PixelFx
local PixelButton = require(script.Parent:WaitForChild("PixelButton")) -- @bundle:PixelButton

local create = PixelFx.create
local tween = PixelFx.tween

local PixelPanel = {}

export type PanelOpts = {
	parent: Instance,
	name: string,
	title: string,
	icon: HudConfig.IconDef,
	width: number, -- largeur en fraction de la hauteur d'écran
	height: number, -- hauteur en fraction de la hauteur d'écran
	centerTitle: boolean?,
}

export type Panel = {
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
