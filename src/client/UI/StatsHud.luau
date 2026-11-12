--!strict
-- StatsHud.luau — bas de l'écran, à l'identique de la capture :
--   • en bas à gauche : icône rebirth + nombre (cyan), trophée + wins (jaune) ;
--   • en bas au centre : « 💪157M POWER » (jaune), « x10.5 Boost » (blanc) et la barre bleue
--     « Rebirth 19 … 157M/157M Power » avec reflet qui la traverse.
-- Les nombres défilent jusqu'à leur nouvelle valeur au lieu de sauter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Hud")) -- @bundle:HudConfig
local FormatNumber = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("FormatNumber")) -- @bundle:FormatNumber
local PixelFx = require(script.Parent:WaitForChild("PixelFx")) -- @bundle:PixelFx

local create = PixelFx.create
local tween = PixelFx.tween

local StatsHud = {}

export type Handle = {
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
