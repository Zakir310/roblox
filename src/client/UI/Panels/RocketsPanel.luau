--!strict
-- RocketsPanel.luau — les fenêtres « Backpack » et « Index » de la vidéo, avec tes 40 fusées :
--   • Backpack : compteur « 9/40 » à côté du titre, grille des fusées possédées (cartes à cubes de la
--     couleur du monde, « E » vert sur celle équipée), fiche à droite avec rayons, POWER, PRICE et EQUIP ;
--   • Index : onglets des 4 mondes à gauche, grille de toutes les fusées du monde (celles pas encore
--     débloquées en silhouette noire « ??? »), barre de collection, fiche à droite (bouton d'achat).
-- L'aperçu d'une fusée est son modèle 3D (ReplicatedStorage.Assets.Rockets.<clé>) s'il a été importé,
-- sinon une icône provisoire.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Hud")) -- @bundle:HudConfig
local Rockets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Rockets")) -- @bundle:Rockets
local FormatNumber = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("FormatNumber")) -- @bundle:FormatNumber
local PixelFx = require(script.Parent.Parent:WaitForChild("PixelFx")) -- @bundle:PixelFx
local PixelButton = require(script.Parent.Parent:WaitForChild("PixelButton")) -- @bundle:PixelButton
local PixelPanel = require(script.Parent.Parent:WaitForChild("PixelPanel")) -- @bundle:PixelPanel

local create = PixelFx.create

local RocketsPanel = {}

export type Actions = { onEquip: (id: number) -> (), onBuy: (id: number) -> () }
export type Handle = {
	panel: PixelPanel.Panel,
	setOwned: (ids: { number }) -> (),
	setEquipped: (id: number?) -> (),
	setActions: (actions: Actions) -> (),
}

type Card = { setSelected: (on: boolean) -> (), setEquipped: (on: boolean) -> () }

local WIDTH, HEIGHT = 0.8, 0.57
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local YELLOW = Color3.fromRGB(255, 230, 0)

local function buttonIcon(id: string): HudConfig.IconDef
	for _, def in HudConfig.Buttons do
		if def.id == id then
			return def.icon
		end
	end
	return HudConfig.PanelIcons.Rocket
end

-- Aperçu de la fusée : modèle 3D dans un ViewportFrame s'il existe, sinon icône (ou « ? » si verrouillée).
local function rocketView(parent: Instance, def: Rockets.RocketDef, silhouette: boolean, zIndex: number): GuiObject
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = if assets then assets:FindFirstChild("Rockets") else nil
	local template = if folder then folder:FindFirstChild(def.key) else nil
	if template and template:IsA("Model") then
		local viewport: ViewportFrame = create("ViewportFrame", {
			Name = "View",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Ambient = Color3.fromRGB(190, 190, 200),
			LightColor = WHITE,
			LightDirection = Vector3.new(-1, -1.5, -1),
			ImageColor3 = if silhouette then BLACK else WHITE,
			ZIndex = zIndex,
			Parent = parent,
		})
		create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = viewport })
		local model = template:Clone()
		model:PivotTo(CFrame.Angles(0, 0, math.rad(-30))) -- penchée, comme au décollage
		model.Parent = viewport
		local camera: Camera = create("Camera", { FieldOfView = 30, Parent = viewport })
		viewport.CurrentCamera = camera
		local box, size = model:GetBoundingBox()
		local distance = (size.Magnitude / 2) / math.tan(math.rad(15))
		camera.CFrame = CFrame.lookAt(box.Position + Vector3.new(0.35, 0.25, 1).Unit * distance, box.Position)
		return viewport
	end
	if silhouette then
		local label, _ = PixelFx.text({
			parent = parent,
			name = "View",
			text = "?",
			font = HudConfig.Style.ButtonFont,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(1, 1),
			zIndex = zIndex,
			strokeRatio = 0.12,
		})
		return label
	end
	return PixelFx.icon(parent, HudConfig.PanelIcons.Rocket, zIndex)
end

function RocketsPanel.new(parent: Instance, mode: "Backpack" | "Index"): Handle
	local style = HudConfig.Style
	local texts = HudConfig.Texts
	local palettes = HudConfig.Palettes
	local isIndex = mode == "Index"

	local panel = PixelPanel.new({
		parent = parent,
		name = mode,
		title = mode,
		icon = buttonIcon(mode),
		width = WIDTH,
		height = HEIGHT,
	})
	local content = panel.content
	local actions: Actions = {
		onEquip = function(_id: number) end,
		onBuy = function(_id: number) end,
	}

	local owned: { [number]: boolean } = {}
	local ownedCount = 0
	local equipped: number? = nil
	local selected: number? = nil
	local world = 1

	local function isKnown(id: number): boolean
		return owned[id] == true
	end

	local function worldPalette(worldId: number): PixelFx.Palette
		return palettes[HudConfig.WorldPalettes[worldId] or "Lime"] or palettes.Lime
	end

	---------------------------------------------------------------- en-tête
	local counter: PixelFx.ProgressBar? = nil
	local collection: PixelFx.ProgressBar? = nil
	local gridX = if isIndex then 0.115 else 0.03
	local gridW = if isIndex then 0.515 else 0.6
	local columns = if isIndex then 5 else 4

	local heading, _ = PixelFx.text({
		parent = content,
		name = "Category",
		text = texts.Category,
		font = style.ButtonFont,
		position = UDim2.fromScale(gridX + gridW / 2, 0.1),
		size = UDim2.fromScale(gridW * 0.7, 0.06),
		zIndex = 4,
		strokeRatio = style.TextStroke,
	})
	if isIndex then
		collection = PixelFx.progressBar(
			content,
			UDim2.fromScale(gridX, 0.89),
			UDim2.fromScale(gridW, 0.065),
			Vector2.new(0, 0.5),
			palettes.Lime,
			style.ButtonFont,
			4
		)
	else
		local pill = PixelFx.progressBar(
			panel.root,
			UDim2.fromScale(0.43, 0.02),
			UDim2.fromScale(0.13, 0.06),
			Vector2.new(0, 0.5),
			palettes.Bar,
			style.ButtonFont,
			7
		)
		counter = pill
		-- Le compteur « 9/40 » se cale juste après le titre, quelle que soit sa largeur.
		local title = panel.title
		local function placeCounter()
			local width = panel.root.AbsoluteSize.X
			if width > 0 then
				local x = title.Position.X.Scale + title.TextBounds.X / width + 0.02
				pill.frame.Position = UDim2.fromScale(x, 0.02)
			end
		end
		title:GetPropertyChangedSignal("TextBounds"):Connect(placeCounter)
		panel.root:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeCounter)
		placeCounter()
	end

	---------------------------------------------------------------- grille
	local grid: ScrollingFrame = create("ScrollingFrame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(gridX, 0.15),
		Size = UDim2.fromScale(gridW, if isIndex then 0.69 else 0.8),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(70, 70, 100),
		ZIndex = 4,
		Parent = content,
	})
	local layout: UIGridLayout = create("UIGridLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	create("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 6),
		Parent = grid,
	})
	-- Cases carrées en pixels. On divise par l'échelle d'animation de la fenêtre : pendant l'ouverture
	-- en rebond, la taille affichée change mais la taille des cases ne doit pas bouger.
	local function resizeCells()
		local scale = math.max(0.01, panel.scale.Scale)
		local width = grid.AbsoluteSize.X / scale - 14
		if width <= 0 then
			return
		end
		local gap = math.floor(width * 0.025)
		local cell = math.floor((width - gap * (columns - 1)) / columns)
		layout.CellPadding = UDim2.fromOffset(gap, gap)
		layout.CellSize = UDim2.fromOffset(cell, cell)
	end
	grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeCells)
	resizeCells()

	---------------------------------------------------------------- fiche de droite
	local detail: Frame = create("Frame", {
		Name = "Detail",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.655, 0.075),
		Size = UDim2.fromScale(0.32, 0.88),
		ZIndex = 4,
		Parent = content,
	})
	local detailW, detailH = panel.cells(0.32, 0.88)
	local detailBlock = PixelFx.block({
		parent = detail,
		palette = palettes.Lime,
		style = style,
		wCells = detailW,
		hCells = detailH,
		rays = UDim2.fromScale(0.5, 0.34),
	})
	local function detailText(name: string, y: number, h: number, x: number?, align: Enum.TextXAlignment?, color: Color3?): TextLabel
		local anchorX = if align == Enum.TextXAlignment.Left then 0 elseif align == Enum.TextXAlignment.Right then 1 else 0.5
		local label, _ = PixelFx.text({
			parent = detail,
			name = name,
			text = "",
			font = style.ButtonFont,
			color = color,
			anchor = Vector2.new(anchorX, 0.5),
			xAlign = align,
			position = UDim2.fromScale(x or 0.5, y),
			size = UDim2.fromScale(if align then 0.46 else 0.9, h),
			zIndex = 6,
			strokeRatio = style.TextStroke,
		})
		return label
	end
	local title = detailText("Title", 0.075, 0.085)
	local viewHolder: Frame = create("Frame", {
		Name = "ViewHolder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.34),
		Size = UDim2.fromScale(0.8, 0.36),
		ZIndex = 6,
		Parent = detail,
	})
	local subtitle = detailText("Subtitle", 0.56, 0.05)
	local powerName = detailText("PowerName", 0.66, 0.05, 0.08, Enum.TextXAlignment.Left)
	local powerValue = detailText("PowerValue", 0.66, 0.05, 0.92, Enum.TextXAlignment.Right, YELLOW)
	local priceName = detailText("PriceName", 0.735, 0.05, 0.08, Enum.TextXAlignment.Left)
	local priceValue = detailText("PriceValue", 0.735, 0.05, 0.92, Enum.TextXAlignment.Right, YELLOW)
	powerName.Text = texts.PowerStat
	priceName.Text = texts.PriceStat

	local actionW, actionH = panel.cells(0.32 * 0.84, 0.88 * 0.13)
	local actionButton = PixelButton.action({
		parent = detail,
		name = "Action",
		text = texts.Equip,
		palette = palettes.Lime,
		position = UDim2.fromScale(0.5, 0.88),
		size = UDim2.fromScale(0.84, 0.13),
		wCells = actionW,
		hCells = actionH,
		zIndex = 6,
		textScale = 0.5,
	})

	local function showDetail()
		local id = selected
		local def = if id then Rockets.get(id) else nil
		detail.Visible = def ~= nil
		if def == nil then
			return
		end
		local known = isKnown(def.id)
		detailBlock.setPalette(if known then worldPalette(def.world) else palettes.Red)
		title.Text = if known then def.name else texts.Unknown
		viewHolder:ClearAllChildren()
		local view = rocketView(viewHolder, def, not known, 7)
		view.Position = UDim2.fromScale(0.5, 0.5)
		view.Size = UDim2.fromScale(1, 1)
		local worldDef = Rockets.Worlds[def.world]
		subtitle.Text = if known and worldDef then worldDef.name else texts.Unknown
		powerValue.Text = if known then "x" .. FormatNumber.multiplier(def.multiplier) else texts.Unknown
		priceValue.Text = if def.cost <= 0 then texts.Free else FormatNumber.short(def.cost)
		if known then
			local isEquipped = equipped == def.id
			actionButton.setText(if isEquipped then texts.Equipped else texts.Equip)
			actionButton.setPalette(if isEquipped then palettes.Locked else palettes.Lime)
		else
			actionButton.setText(string.format(texts.Buy, FormatNumber.short(def.cost)))
			actionButton.setPalette(palettes.Lime)
		end
	end

	actionButton.onClick(function()
		local id = selected
		if id == nil then
			return
		end
		if isKnown(id) then
			if equipped ~= id then
				actions.onEquip(id)
			end
		else
			actions.onBuy(id)
		end
	end)

	---------------------------------------------------------------- cartes
	local cards: { [number]: Card } = {}

	local function select(id: number)
		local previous = selected
		if previous and cards[previous] then
			cards[previous].setSelected(false)
		end
		selected = id
		local card = cards[id]
		if card then
			card.setSelected(true)
		end
		showDetail()
	end

	local function makeCard(def: Rockets.RocketDef, order: number)
		local known = isKnown(def.id)
		local slot: Frame = create("Frame", {
			Name = def.key,
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Parent = grid,
		})
		local button: TextButton = create("TextButton", {
			Name = "Button",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
			Parent = slot,
		})
		local block = PixelFx.block({
			parent = button,
			palette = if known then worldPalette(def.world) else palettes.Locked,
			style = style,
			wCells = 0.95,
			hCells = 0.95,
			zIndex = 5,
		})
		local view = rocketView(button, def, not known, 9)
		view.Position = UDim2.fromScale(0.5, 0.42)
		view.Size = UDim2.fromScale(0.7, 0.62)
		PixelFx.text({
			parent = button,
			name = "Name",
			text = if known then def.name else texts.Unknown,
			font = style.ButtonFont,
			position = UDim2.fromScale(0.5, 0.84),
			size = UDim2.fromScale(0.92, 0.2),
			zIndex = 10,
			strokeRatio = 0.13,
		})
		-- « E » vert sur la fusée équipée.
		local marker: Frame = create("Frame", {
			Name = "Equipped",
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.85, 0.14),
			Size = UDim2.fromScale(0.26, 0.26),
			Visible = false,
			ZIndex = 11,
			Parent = button,
		})
		PixelFx.vgradient(marker, palettes.BadgeGreen.top, palettes.BadgeGreen.bottom)
		PixelFx.corner(marker, 0.25)
		PixelFx.border(marker)
		PixelFx.text({
			parent = marker,
			name = "E",
			text = "E",
			font = style.ButtonFont,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.8, 0.8),
			zIndex = 12,
			strokeRatio = 0.14,
		})
		button.MouseEnter:Connect(block.playShine)
		button.Activated:Connect(function()
			block.playShine()
			select(def.id)
		end)
		cards[def.id] = {
			setSelected = function(on: boolean)
				block.outline.Color = if on then YELLOW else BLACK
			end,
			setEquipped = function(on: boolean)
				marker.Visible = on
			end,
		}
	end

	local function rebuild()
		for _, child in grid:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		table.clear(cards)

		local list: { Rockets.RocketDef } = {}
		if isIndex then
			list = Rockets.forWorld(world)
		else
			for _, def in Rockets.List do
				if owned[def.id] then
					table.insert(list, def)
				end
			end
		end
		local knownInList = 0
		for order, def in list do
			makeCard(def, order)
			cards[def.id].setEquipped(def.id == equipped)
			if isKnown(def.id) then
				knownInList += 1
			end
		end

		-- Garde la sélection si possible, sinon la fusée équipée, sinon la première.
		local keep: number? = nil
		if selected and cards[selected] then
			keep = selected
		elseif equipped and cards[equipped] then
			keep = equipped
		elseif list[1] then
			keep = list[1].id
		end
		selected = nil
		if keep then
			select(keep)
		else
			showDetail()
		end

		if collection then
			collection.set(if #list > 0 then knownInList / #list else 0, knownInList .. "/" .. #list)
		end
		if counter then
			counter.set(1, ownedCount .. "/" .. #Rockets.List)
		end
	end

	---------------------------------------------------------------- onglets des mondes (Index)
	if isIndex then
		local tabs: { [number]: PixelButton.Action } = {}
		local function refreshTabs()
			for worldId, tab in tabs do
				tab.setPalette(if worldId == world then worldPalette(worldId) else palettes.Locked)
			end
			local worldDef = Rockets.Worlds[world]
			heading.Text = if worldDef then string.upper(worldDef.name) else texts.Category
		end
		for index, worldDef in Rockets.Worlds do
			local tabW, tabH = panel.cells(0.13 * HEIGHT / WIDTH, 0.13)
			local tab = PixelButton.action({
				parent = content,
				name = "World" .. worldDef.id,
				text = tostring(worldDef.id),
				palette = palettes.Locked,
				position = UDim2.fromScale(0.06, 0.2 + (index - 1) * 0.165),
				size = UDim2.fromScale(1, 0.13),
				square = true,
				wCells = tabW,
				hCells = tabH,
				zIndex = 5,
				textScale = 0.5,
			})
			tabs[worldDef.id] = tab
			tab.onClick(function()
				world = worldDef.id
				refreshTabs()
				rebuild()
			end)
		end
		refreshTabs()
	end

	rebuild()

	return {
		panel = panel,
		setActions = function(newActions: Actions)
			actions = newActions
		end,
		setOwned = function(ids: { number })
			table.clear(owned)
			ownedCount = 0
			for _, id in ids do
				if not owned[id] then
					owned[id] = true
					ownedCount += 1
				end
			end
			rebuild()
		end,
		setEquipped = function(id: number?)
			equipped = id
			for cardId, card in cards do
				card.setEquipped(cardId == id)
			end
			showDetail()
		end,
	}
end

return RocketsPanel
