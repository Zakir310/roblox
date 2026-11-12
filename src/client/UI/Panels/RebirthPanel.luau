--!strict
-- RebirthPanel.luau — fenêtre « Rebirth » de la vidéo :
--   « Before » [💪 x10.5 POWER]  ➜  « After » [💪 x11 POWER]
--   « Resets your POWER! » en rouge, barre « 598M/157M Power », boutons « Rebirth » (vert) et
--   « Skip Rebirth » (violet).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Hud")) -- @bundle:HudConfig
local FormatNumber = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("FormatNumber")) -- @bundle:FormatNumber
local PixelFx = require(script.Parent.Parent:WaitForChild("PixelFx")) -- @bundle:PixelFx
local PixelButton = require(script.Parent.Parent:WaitForChild("PixelButton")) -- @bundle:PixelButton
local PixelPanel = require(script.Parent.Parent:WaitForChild("PixelPanel")) -- @bundle:PixelPanel

local create = PixelFx.create

local RebirthPanel = {}

export type State = { power: number, cost: number, boost: number, nextBoost: number }
export type Actions = { onRebirth: () -> (), onSkip: () -> () }
export type Handle = {
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
