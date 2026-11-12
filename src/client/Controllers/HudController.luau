--!strict
-- HudController.luau — construit l'interface « PixelHud » (menu, compteurs, barre, fenêtres), l'adapte à la
-- taille de l'écran et l'alimente avec les valeurs du joueur (leaderstats Wins / Rebirths / Power +
-- attributs Boost, RebirthCost, NextBoost, OwnedRockets, EquippedRocket).
--
-- Clic sur un bouton du menu :
--   • Rebirth, Backpack, Index, Settings → ouvre / ferme leur fenêtre (fond flouté, comme dans la vidéo) ;
--   • bouton marqué `comingSoon` ou sans fenêtre → « Trails coming soon! » en haut de l'écran.
--
-- Depuis un autre script client (version Rojo) :
--   local HudController = require(path.to.Controllers.HudController)
--   HudController.OnButton("Shop", function() ... end)          -- remplace l'action d'un bouton du menu
--   HudController.On("Rebirth", function() remote:FireServer() end)  -- bouton vert « Rebirth »
--   HudController.On("SkipRebirth", function() ... end)          -- bouton violet « Skip Rebirth »
--   HudController.On("Equip", function(id) ... end)              -- bouton EQUIP du Backpack
--   HudController.On("Buy", function(id) ... end)                -- bouton d'achat de l'Index
--   HudController.On("Setting", function(name, value) ... end)   -- réglages (Music, Sound, ReducedMotion)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HudConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Hud")) -- @bundle:HudConfig
local Rockets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Rockets")) -- @bundle:Rockets
local PixelFx = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("PixelFx")) -- @bundle:PixelFx
local PixelButton = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("PixelButton")) -- @bundle:PixelButton
local PixelPanel = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("PixelPanel")) -- @bundle:PixelPanel
local StatsHud = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("StatsHud")) -- @bundle:StatsHud
local RebirthPanel = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Panels"):WaitForChild("RebirthPanel")) -- @bundle:RebirthPanel
local SettingsPanel = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Panels"):WaitForChild("SettingsPanel")) -- @bundle:SettingsPanel
local RocketsPanel = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Panels"):WaitForChild("RocketsPanel")) -- @bundle:RocketsPanel

local create = PixelFx.create

local HudController = {}

local buttons: { [string]: PixelButton.Handle } = {}
local handlers: { [string]: { () -> () } } = {}
local listeners: { [string]: { (...any) -> () } } = {}
local panels: { [string]: PixelPanel.Panel } = {}
local screenGui: ScreenGui? = nil
local fxLayer: Frame? = nil

type State = {
	wins: number,
	rebirths: number,
	power: number,
	boost: number,
	cost: number,
	nextBoost: number,
	owned: { number },
	equipped: number?,
}

-- Remplace l'action d'un bouton du menu (« Shop », « Rebirth »…).
function HudController.OnButton(id: string, callback: () -> ())
	local list = handlers[id] or {}
	handlers[id] = list
	table.insert(list, callback)
end

-- Écoute une action des fenêtres : "Rebirth", "SkipRebirth", "Equip" (id), "Buy" (id), "Setting" (nom, valeur).
function HudController.On(event: string, callback: (...any) -> ())
	local list = listeners[event] or {}
	listeners[event] = list
	table.insert(list, callback)
end

local function fire(event: string, ...: any): boolean
	local list = listeners[event]
	if list == nil or #list == 0 then
		return false
	end
	for _, callback in list do
		task.spawn(callback, ...)
	end
	return true
end

function HudController.GetButton(id: string): PixelButton.Handle?
	return buttons[id]
end

function HudController.OpenPanel(id: string)
	local panel = panels[id]
	if panel then
		panel.open()
	end
end

-- Message centré en haut de l'écran (ex. « Trails coming soon! »).
function HudController.Banner(text: string)
	local layer = fxLayer
	if layer then
		PixelFx.banner(layer, text, HudConfig.Style.ButtonFont)
	end
end

function HudController.SetVisible(visible: boolean)
	local gui = screenGui
	if gui == nil then
		return
	end
	if not visible then
		PixelPanel.closeCurrent()
		for _, handle in buttons do
			handle.reset()
		end
	end
	gui.Enabled = visible
end

local function onButtonClicked(def: HudConfig.ButtonDef)
	if def.comingSoon then
		HudController.Banner(string.format(HudConfig.Texts.ComingSoon, def.label))
		return
	end
	local list = handlers[def.id]
	if list ~= nil and #list > 0 then
		for _, callback in list do
			task.spawn(callback)
		end
		return
	end
	local panel = panels[def.id]
	if panel then
		panel.toggle()
	else
		HudController.Banner(string.format(HudConfig.Texts.ComingSoon, def.label))
	end
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
			onButtonClicked(def)
		end)
	end

	return menu, aspect
end

local function parseIds(value: any): { number }
	local ids: { number } = {}
	if typeof(value) == "string" then
		for piece in string.gmatch(value, "%d+") do
			local id = tonumber(piece)
			if id then
				table.insert(ids, id)
			end
		end
	end
	return ids
end

-- Lit les valeurs du joueur et met l'interface à jour à chaque changement.
local function startData(
	player: Player,
	stats: StatsHud.Handle,
	rebirth: RebirthPanel.Handle,
	backpack: RocketsPanel.Handle,
	index: RocketsPanel.Handle
)
	local cfg = HudConfig.Stats
	local texts = HudConfig.Texts
	local state: State = {
		wins = 0,
		rebirths = 0,
		power = 0,
		boost = 1,
		cost = 0,
		nextBoost = 0,
		owned = {},
		equipped = nil,
	}
	local live = false -- true dès que de vraies leaderstats sont branchées
	local demo = false

	local function currentCost(): number
		return if state.cost > 0 then state.cost else HudConfig.RebirthCost(state.rebirths)
	end

	local function refresh()
		local cost = currentCost()
		local nextBoost = if state.nextBoost > 0 then state.nextBoost else HudConfig.NextBoost(state.boost, state.rebirths)
		stats.setRebirths(state.rebirths)
		stats.setWins(state.wins)
		stats.setBoost(state.boost)
		stats.setPower(state.power, cost)
		rebirth.update({ power = state.power, cost = cost, boost = state.boost, nextBoost = nextBoost })
		local progressButton = buttons[cfg.ProgressButton]
		if progressButton then
			local percent = if cost > 0 then math.clamp(math.floor(state.power / cost * 100), 0, 100) else 0
			if percent >= 100 then
				progressButton.setBadge(texts.Ready, "BadgeGreen")
			else
				progressButton.setBadge(tostring(percent) .. "%", "BadgeBlue")
			end
			progressButton.setPulse(percent >= 100)
		end
	end

	local function refreshRockets()
		backpack.setOwned(state.owned)
		index.setOwned(state.owned)
		backpack.setEquipped(state.equipped)
		index.setEquipped(state.equipped)
	end

	-- Actions des fenêtres. Si aucun script ne les écoute : simulation en mode démo, message sinon.
	local rebirthActions = {
		onRebirth = function()
			if state.power < currentCost() then
				HudController.Banner(texts.NotEnoughPower)
				return
			end
			if fire("Rebirth") then
				return
			end
			if demo then
				local nextBoost = if state.nextBoost > 0 then state.nextBoost else HudConfig.NextBoost(state.boost, state.rebirths)
				state.rebirths += 1
				state.power = 0
				state.boost = nextBoost
				state.cost = HudConfig.RebirthCost(state.rebirths)
				state.nextBoost = 0
				refresh()
				PixelPanel.closeCurrent()
			else
				warn("[PixelHud] Bouton Rebirth : branche-le avec HudController.On(\"Rebirth\", …)")
			end
		end,
		onSkip = function()
			if not fire("SkipRebirth") then
				HudController.Banner(string.format(texts.ComingSoon, texts.SkipRebirth))
			end
		end,
	}
	rebirth.setActions(rebirthActions)

	local function equip(id: number)
		if fire("Equip", id) then
			return
		end
		state.equipped = id -- sans serveur : seulement à l'écran
		refreshRockets()
	end
	local function buy(id: number)
		if fire("Buy", id) then
			return
		end
		local def = Rockets.get(id)
		if def and demo and state.wins >= def.cost then
			state.wins -= def.cost
			table.insert(state.owned, id)
			refresh()
			refreshRockets()
		else
			HudController.Banner(texts.NotEnoughWins)
		end
	end
	backpack.setActions({ onEquip = equip, onBuy = buy })
	index.setActions({ onEquip = equip, onBuy = buy })

	-- Branchements (refaits si le serveur recrée leaderstats).
	local bindings: { RBXScriptConnection } = {}
	local function unbind()
		for _, connection in bindings do
			connection:Disconnect()
		end
		table.clear(bindings)
	end

	local function bindNumber(folder: Instance, name: string, apply: (number) -> ())
		local function try(child: Instance)
			if child.Name ~= name then
				return
			end
			if child:IsA("IntValue") then
				apply(child.Value)
				table.insert(bindings, child.Changed:Connect(apply))
			elseif child:IsA("NumberValue") then
				apply(child.Value)
				table.insert(bindings, child.Changed:Connect(apply))
			end
		end
		for _, child in folder:GetChildren() do
			try(child)
		end
		table.insert(bindings, folder.ChildAdded:Connect(try))
	end

	local function bindAttribute(name: string, apply: (any) -> ())
		local function read()
			apply(player:GetAttribute(name))
		end
		table.insert(bindings, player:GetAttributeChangedSignal(name):Connect(read))
		read()
	end

	local function toNumber(value: any, default: number): number
		return if typeof(value) == "number" and value == value then value else default
	end

	local function bindFolder(folder: Instance)
		unbind()
		live, demo = true, false
		state.wins, state.rebirths, state.power = 0, 0, 0
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
		bindAttribute(cfg.BoostAttribute, function(value: any)
			state.boost = toNumber(value, 1)
			refresh()
		end)
		bindAttribute(cfg.RebirthCostAttribute, function(value: any)
			state.cost = toNumber(value, 0)
			refresh()
		end)
		bindAttribute(cfg.NextBoostAttribute, function(value: any)
			state.nextBoost = toNumber(value, 0)
			refresh()
		end)
		bindAttribute(cfg.OwnedAttribute, function(value: any)
			state.owned = parseIds(value)
			refreshRockets()
		end)
		bindAttribute(cfg.EquippedAttribute, function(value: any)
			state.equipped = if typeof(value) == "number" then value else nil
			refreshRockets()
		end)
		refresh()
	end

	player.ChildAdded:Connect(function(child: Instance)
		if child.Name == cfg.Folder then
			bindFolder(child)
		end
	end)
	local existing = player:FindFirstChild(cfg.Folder)
	if existing then
		bindFolder(existing)
		return
	end
	refresh()
	refreshRockets()

	-- Pas encore de leaderstats (jeu sans serveur) : valeurs de démonstration, dans Studio seulement.
	task.delay(cfg.WaitForFolder, function()
		if live or not HudConfig.Demo.Enabled or not RunService:IsStudio() then
			return
		end
		local values = HudConfig.Demo
		demo = true
		state.wins, state.rebirths, state.power = values.Wins, values.Rebirths, values.Power
		state.boost, state.cost = values.Boost, values.RebirthCost
		state.owned = table.clone(values.Owned)
		state.equipped = values.Equipped
		refresh()
		refreshRockets()
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
	fxLayer = fx

	local layout = HudConfig.Layout
	local menu, aspect = buildMenu(screen, fx)
	local stats = StatsHud.new(screen, layout.Margin)

	-- Fenêtres.
	local rebirth = RebirthPanel.new(screen)
	local backpack = RocketsPanel.new(screen, "Backpack")
	local index = RocketsPanel.new(screen, "Index")
	local settings = SettingsPanel.new(screen, {
		onChange = function(name: string, value: number | boolean)
			fire("Setting", name, value)
		end,
	})
	panels.Rebirth = rebirth.panel
	panels.Backpack = backpack.panel
	panels.Index = index.panel
	panels.Settings = settings.panel

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
	startData(player, stats, rebirth, backpack, index)
end

return HudController
