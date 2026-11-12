--!strict
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

local HudConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Hud")) -- @bundle:HudConfig
local PixelFx = require(script.Parent.Parent:WaitForChild("PixelFx")) -- @bundle:PixelFx
local PixelButton = require(script.Parent.Parent:WaitForChild("PixelButton")) -- @bundle:PixelButton
local PixelPanel = require(script.Parent.Parent:WaitForChild("PixelPanel")) -- @bundle:PixelPanel

local create = PixelFx.create

local SettingsPanel = {}

export type Actions = { onChange: (name: string, value: number | boolean) -> () }
export type Handle = { panel: PixelPanel.Panel }

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
