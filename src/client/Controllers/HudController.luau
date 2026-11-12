--!strict
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

local HudConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Hud")) -- @bundle:HudConfig
local PixelFx = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("PixelFx")) -- @bundle:PixelFx
local PixelButton = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("PixelButton")) -- @bundle:PixelButton
local StatsHud = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("StatsHud")) -- @bundle:StatsHud

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
