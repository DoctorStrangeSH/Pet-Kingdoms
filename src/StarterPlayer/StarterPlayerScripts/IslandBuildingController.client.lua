--!strict
-- First playable island construction controller.
-- Preview is client-only; the server validates and commits every placement.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local function getPanelSignal(): BindableEvent
	local existing = playerGui:FindFirstChild("PetKingdomsPanelSignal")
	if existing and existing:IsA("BindableEvent") then return existing end
	local signal = Instance.new("BindableEvent")
	signal.Name = "PetKingdomsPanelSignal"
	signal.Parent = playerGui
	return signal
end
local panelSignal = getPanelSignal()
local function announcePanelOpened()
	panelSignal:Fire(script.Name)
end

local camera = Workspace.CurrentCamera
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlaceBuilding") :: RemoteFunction

local selectedCatalogId = "main_house"
local BUILDING_SIZES = {
	main_house = { width = 3, depth = 3 },
	pet_house = { width = 3, depth = 3 },
	stone_path = { width = 1, depth = 1 },
	garden_lantern = { width = 1, depth = 1 },
	flower_bed = { width = 1, depth = 1 },
	wooden_fence = { width = 1, depth = 1 },
}
local BUILDING_WIDTH = BUILDING_SIZES.main_house.width
local BUILDING_DEPTH = BUILDING_SIZES.main_house.depth
local rotation = 0
local placing = false
local currentCellX: number? = nil
local currentCellZ: number? = nil
local currentIsland: Model? = nil
local currentPreview: BasePart? = nil
local previewVisual: Model? = nil
local currentValid = false
local selectedBuildingModel: Model? = nil
local movingInstanceId: string? = nil
local demolitionArmed = false
local pointerPosition = UserInputService:GetMouseLocation()
local placementLocked = false
local buildRequestInFlight = false
local demolitionRequestInFlight = false
local closeAfterBuildResponse = false
local touchPlacement = UserInputService.TouchEnabled
local pendingRequestIds: { [string]: string } = {}

local function getPendingRequestId(operationKey: string): string
	local requestId = pendingRequestIds[operationKey]
	if requestId == nil then
		requestId = HttpService:GenerateGUID(false)
		pendingRequestIds[operationKey] = requestId
	end
	return requestId
end

local function clearPendingRequestId(operationKey: string)
	pendingRequestIds[operationKey] = nil
end

local function shouldKeepPendingRequest(response: any): boolean
	if type(response) ~= "table" then return false end
	return response.code == "BUILDING_OPERATION_IN_PROGRESS"
		or response.code == "BUILDING_OPERATION_BUSY"
		or response.code == "PERSIST_TIMEOUT"
		or response.code == "SESSION_NOT_WRITABLE"
end

local COLORS = {
	panel = Color3.fromRGB(35, 31, 59),
	panelLight = Color3.fromRGB(54, 47, 86),
	gold = Color3.fromRGB(255, 211, 117),
	text = Color3.fromRGB(255, 250, 239),
	valid = Color3.fromRGB(91, 220, 143),
	invalid = Color3.fromRGB(245, 104, 105),
}

local function make(className: string, properties: { [string]: any }, parent: Instance): Instance
	local object = Instance.new(className)
	for key, value in pairs(properties) do
		(object :: any)[key] = value
	end
	object.Parent = parent
	return object
end

local gui = make("ScreenGui", {
	Name = "IslandBuildingGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	DisplayOrder = 30,
}, playerGui) :: ScreenGui

local panel = make("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -22),
	Size = UDim2.new(1, -24, 0, 228),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Visible = false,
}, gui) :: Frame
make("UISizeConstraint", { MinSize = Vector2.new(220, 210), MaxSize = Vector2.new(540, 245) }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 18) }, panel)
make("UIStroke", { Color = COLORS.gold, Transparency = 0.35, Thickness = 1.5 }, panel)
make("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingBottom = UDim.new(0, 12),
	PaddingLeft = UDim.new(0, 14),
	PaddingRight = UDim.new(0, 14),
}, panel)

make("TextLabel", {
	Name = "Title",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -44, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "СТРОИТЕЛЬСТВО",
	TextColor3 = COLORS.gold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local panelCloseButton = make("TextButton", {
	Name = "CloseConstruction",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = COLORS.panelLight,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "✕",
	TextColor3 = COLORS.text,
	TextSize = 19,
	ZIndex = 4,
}, panel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 12) }, panelCloseButton)

local status = make("TextLabel", {
	Name = "Status",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 30),
	Size = UDim2.new(1, 0, 0, 30),
	Font = Enum.Font.GothamMedium,
	Text = "Выбери здание и место для него",
	TextColor3 = COLORS.text,
	TextSize = 12,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel) :: TextLabel

local buttons = make("Frame", {
	Name = "Buttons",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 157),
	Size = UDim2.new(1, 0, 0, 48),
}, panel)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
}, buttons)

local function makeButton(name: string, label: string, width: number, color: Color3): TextButton
	local button = make("TextButton", {
		Name = name,
		Size = UDim2.fromOffset(width, 44),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		Text = label,
		TextColor3 = COLORS.text,
		TextSize = 14,
	}, buttons) :: TextButton
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, button)
	return button
end

local rotateButton = makeButton("Rotate", "↻  ПОВОРОТ", 94, COLORS.panelLight)
local confirmButton = makeButton("Confirm", "ПОСТРОИТЬ", 104, Color3.fromRGB(45, 137, 91))
local cancelButton = makeButton("Cancel", "ОТМЕНА", 78, Color3.fromRGB(139, 67, 76))

local catalogRow = make("ScrollingFrame", {
	Name = "Catalog",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(0, 62),
	Size = UDim2.new(1, 0, 0, 84),
	ScrollingDirection = Enum.ScrollingDirection.X,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = COLORS.gold,
	CanvasSize = UDim2.fromOffset(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
	Active = true,
}, panel) :: ScrollingFrame
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, catalogRow)

local function makeCatalogButton(name: string, label: string): TextButton
	local button = make("TextButton", {
		Name = name,
		Size = UDim2.fromOffset(130, 70),
		BackgroundColor3 = COLORS.panelLight,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		Text = label,
		TextColor3 = COLORS.text,
		TextSize = 13,
		TextWrapped = true,
	}, catalogRow) :: TextButton
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, button)
	make("UIStroke", { Name = "SelectionStroke", Color = COLORS.gold, Transparency = 0.75, Thickness = 1 }, button)
	return button
end

local mainHouseButton = makeCatalogButton("MainHouse", "🏡  ГЛАВНЫЙ ДОМ")
local petHouseButton = makeCatalogButton("PetHouse", "🐾  ДОМИК ПИТОМЦЕВ\n5 🌲  •  2 🪨")
local stonePathButton = makeCatalogButton("StonePath", "🪨  КАМЕННАЯ ДОРОЖКА\n1 🌲  •  1 🪨")
local gardenLanternButton = makeCatalogButton("GardenLantern", "🏮  САДОВЫЙ ФОНАРЬ\n2 🌲  •  1 🪨")
local flowerBedButton = makeCatalogButton("FlowerBed", "🌷  КЛУМБА\n1 🌲")
local woodenFenceButton = makeCatalogButton("WoodenFence", "🪵  ЗАБОР\n1 🌲")
local setStatus: (string, boolean?) -> ()
local findOwnIsland: () -> Model?

-- Filled after the overview UI is created farther down in this controller.
local dismissKingdomOverview: () -> () = function() end

local moveButton = make("TextButton", {
	Name = "MoveSelected",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0, 22, 0, 24),
	Size = UDim2.fromOffset(128, 46),
	BackgroundColor3 = Color3.fromRGB(65, 112, 153),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "↔  ПЕРЕНЕСТИ",
	TextColor3 = COLORS.text,
	TextSize = 12,
	Visible = false,
}, gui) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 13) }, moveButton)
make("UIStroke", { Color = COLORS.gold, Transparency = 0.5, Thickness = 1 }, moveButton)

local demolishButton = make("TextButton", {
	Name = "DemolishSelected",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0, 160, 0, 24),
	Size = UDim2.fromOffset(180, 46),
	BackgroundColor3 = Color3.fromRGB(139, 67, 76),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "⌫  ДЕМОНТИРОВАТЬ",
	TextColor3 = COLORS.text,
	TextSize = 13,
	Visible = false,
}, gui) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 13) }, demolishButton)
make("UIStroke", { Color = COLORS.gold, Transparency = 0.5, Thickness = 1 }, demolishButton)

-- Fit all construction actions inside the actual panel content width.
-- A tiny phone should never require horizontal scrolling to reach Confirm/Cancel.
local function resizeBuildingPanel()
	local activeCamera = Workspace.CurrentCamera
	if activeCamera == nil then return end
	local viewport = activeCamera.ViewportSize
	local compact = viewport.X < 520
	local panelWidth = math.max(220, math.min(viewport.X - 16, compact and 380 or 480))
	panel.Size = UDim2.fromOffset(panelWidth, 228)
	panel.Position = UDim2.new(0.5, 0, 1, compact and -10 or -22)
	local contentWidth = panelWidth - 28 -- 14-pixel left and right padding.
	local gap = 8
	local available = contentWidth - 2 * gap
	local narrow = panelWidth < 370
	local rotateWidth = if narrow then math.floor(available * 0.27) else 94
	local cancelWidth = if narrow then math.floor(available * 0.27) else 88
	local confirmWidth = available - rotateWidth - cancelWidth
	rotateButton.Size = UDim2.fromOffset(rotateWidth, 44)
	rotateButton.Text = if narrow then "↻" else "↻  ПОВОРОТ"
	confirmButton.Size = UDim2.fromOffset(confirmWidth, 44)
	confirmButton.TextSize = if narrow then 12 else 14
	cancelButton.Size = UDim2.fromOffset(cancelWidth, 44)
	cancelButton.Text = if narrow then "✕" else "ОТМЕНА"
	-- Selection actions share a row and remain within the mobile viewport.
	local outerMargin = compact and 10 or 22
	local actionGap = 8
	local actionAvailable = math.max(196, viewport.X - outerMargin * 2 - actionGap)
	local moveWidth = math.min(128, math.floor(actionAvailable * 0.43))
	local demolishWidth = math.min(180, actionAvailable - moveWidth)
	moveButton.Position = UDim2.fromOffset(outerMargin, compact and 80 or 24)
	moveButton.Size = UDim2.fromOffset(moveWidth, 46)
	demolishButton.Position = UDim2.fromOffset(outerMargin + moveWidth + actionGap, compact and 80 or 24)
	demolishButton.Size = UDim2.fromOffset(demolishWidth, 46)
	demolishButton.TextSize = if compact then 11 else 13
end

local function bindBuildingCamera()
	local activeCamera = Workspace.CurrentCamera
	if activeCamera then
		activeCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeBuildingPanel)
	end
	resizeBuildingPanel()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindBuildingCamera)
bindBuildingCamera()

local function findBuildingModel(target: Instance?): Model?
	local ownIsland = findOwnIsland()
	if ownIsland == nil or target == nil or not target:IsDescendantOf(ownIsland) then
		return nil
	end
	local current = target
	while current and current ~= ownIsland do
		if current:IsA("Model") and type(current:GetAttribute("BuildingInstanceId")) == "string" then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function selectBuilding(model: Model?)
	if demolitionRequestInFlight then return end
	selectedBuildingModel = model
	demolitionArmed = false
	moveButton.Visible = model ~= nil
	local catalogId = if model then model:GetAttribute("BuildingCatalogId") else nil
	demolishButton.Visible = model ~= nil and catalogId ~= "main_house"
	demolishButton.Text = "⌫  ДЕМОНТИРОВАТЬ"
	if model then
		setStatus("Выбрана постройка: " .. model.Name)
	end
end

demolishButton.Activated:Connect(function()
	if demolitionRequestInFlight or buildRequestInFlight or placing then return end
	local model = selectedBuildingModel
	if model == nil or model.Parent == nil then
		selectBuilding(nil)
		return
	end
	if not demolitionArmed then
		demolitionArmed = true
		demolishButton.Text = "ТОЧНО УДАЛИТЬ?"
		setStatus("Нажми ещё раз для подтверждения демонтажа", false)
		return
	end
	local instanceId = model:GetAttribute("BuildingInstanceId")
	if type(instanceId) ~= "string" or instanceId == "" then
		setStatus("Не удалось определить постройку", false)
		return
	end
	-- Capture the exact target before InvokeServer yields.
	demolitionRequestInFlight = true
	demolishButton.Active = false
	moveButton.Active = false
	demolishButton.Text = "..."
	setStatus("Удаляем постройку…")
	local operationKey = "demolish:" .. instanceId
	local requestId = getPendingRequestId(operationKey)
	local ok, response = pcall(function()
		return remote:InvokeServer({
			requestId = requestId,
			action = "demolish",
			instanceId = instanceId,
		})
	end)
	demolitionRequestInFlight = false
	demolishButton.Active = true
	moveButton.Active = true
	demolishButton.Text = "⌫  ДЕМОНТИРОВАТЬ"
	demolitionArmed = false
	if ok and not shouldKeepPendingRequest(response) then clearPendingRequestId(operationKey) end
	if not ok then
		setStatus("Нет ответа сервера. Выбери ту же постройку и повтори попытку", false)
		return
	end
	if type(response) == "table" and response.ok == true then
		selectBuilding(nil)
		setStatus("Постройка демонтирована", true)
	else
		local code = if type(response) == "table" then tostring(response.code) else "UNKNOWN"
		local messages = {
			BUILDING_NOT_FOUND = "Постройка уже отсутствует",
			MAIN_HOUSE_PROTECTED = "Главный дом демонтировать нельзя",
			BUILDING_OPERATION_BUSY = "Сервер занят. Повтори попытку",
			BUILDING_OPERATION_IN_PROGRESS = "Операция ещё выполняется. Повтори попытку",
			SESSION_NOT_WRITABLE = "Сохранение временно недоступно",
			PERSIST_TIMEOUT = "Сохранение задерживается. Повтори попытку",
			RATE_LIMITED = "Слишком много запросов. Попробуй позже",
		}
		setStatus(messages[code] or ("Нельзя демонтировать: " .. code), false)
	end
end)

setStatus = function(message: string, good: boolean?)
	status.Text = message
	status.TextColor3 = if good == true then COLORS.valid elseif good == false then COLORS.invalid else COLORS.text
end

findOwnIsland = function(): Model?
	local folder = Workspace:FindFirstChild("PlayerIslands")
	if folder == nil then
		return nil
	end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("OwnerUserId") == player.UserId then
			return child
		end
	end
	return nil
end


local function clearPreview()
	if currentPreview then
		currentPreview:Destroy()
		currentPreview = nil
	end
	if previewVisual then
		previewVisual:Destroy()
		previewVisual = nil
	end
	currentCellX = nil
	currentCellZ = nil
	currentValid = false
	placementLocked = false
end

-- Local, lightweight silhouettes match the procedural server blockouts.
-- The server remains the authority for actual construction.
local function makePreviewVisual(catalogId: string, unit: number): Model
	local model = Instance.new("Model")
	model.Name = "LocalBuildingSilhouette"
	-- Match the server fallback template's ground-level PrimaryPart pivot.
	local root = Instance.new("Part")
	root.Name = "Pivot"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.CFrame = CFrame.new()
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CastShadow = false
	root.Parent = model
	model.PrimaryPart = root
	local width = BUILDING_WIDTH * unit * 0.82
	local depth = BUILDING_DEPTH * unit * 0.82
	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = offset
		part.Color = color
		part.Material = material
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Transparency = 1 -- Reveal after the player targets an island cell.
		part.Parent = model
	end
	if catalogId == "stone_path" then
		local stones = {
			{ -0.25, -0.24, 0.39, 0.34, 0.10, 156 },
			{ 0.23, -0.20, 0.40, 0.31, -0.08, 180 },
			{ -0.22, 0.23, 0.36, 0.34, -0.06, 170 },
			{ 0.23, 0.22, 0.41, 0.37, 0.07, 150 },
		}
		for index, stone in ipairs(stones) do
			local tint = stone[6]
			piece("PavingStone_" .. index,
				Vector3.new(width * stone[3], unit * 0.085, depth * stone[4]),
				CFrame.new(width * stone[1], unit * 0.045, depth * stone[2]) * CFrame.Angles(0, stone[5], 0),
				Color3.fromRGB(tint, tint - 3, tint - 9), Enum.Material.Slate)
		end
	elseif catalogId == "wooden_fence" then
		for index, x in ipairs({-width * 0.4, width * 0.4}) do
			piece("Post_" .. index, Vector3.new(width * 0.12, unit * 0.70, depth * 0.12),
				CFrame.new(x, unit * 0.35, 0), Color3.fromRGB(128, 88, 55), Enum.Material.Wood)
			piece("PostCap_" .. index, Vector3.new(width * 0.17, unit * 0.075, depth * 0.17),
				CFrame.new(x, unit * 0.73, 0), Color3.fromRGB(192, 147, 91), Enum.Material.WoodPlanks)
		end
		for index, height in ipairs({0.25, 0.53}) do
			piece("Rail_" .. index, Vector3.new(width * 0.86, unit * 0.095, depth * 0.10),
				CFrame.new(0, unit * height, 0), Color3.fromRGB(157, 112, 69), Enum.Material.Wood)
		end
		piece("CenterMedallion", Vector3.new(width * 0.16, unit * 0.16, depth * 0.13),
			CFrame.new(0, unit * 0.53, -depth * 0.035), Color3.fromRGB(221, 174, 102), Enum.Material.Wood)
	elseif catalogId == "flower_bed" then
		piece("Planter", Vector3.new(width * 0.88, unit * 0.12, depth * 0.88), CFrame.new(0, unit * 0.06, 0), Color3.fromRGB(132, 91, 61), Enum.Material.WoodPlanks)
		piece("Soil", Vector3.new(width * 0.72, unit * 0.08, depth * 0.72), CFrame.new(0, unit * 0.15, 0), Color3.fromRGB(76, 58, 43), Enum.Material.Ground)
		for index, x in ipairs({-width * 0.23, 0, width * 0.23}) do
			piece("Flower_" .. index, Vector3.new(unit * 0.17, unit * 0.17, unit * 0.17), CFrame.new(x, unit * 0.43, 0), Color3.fromRGB(255, 155, 196), Enum.Material.SmoothPlastic)
		end
	elseif catalogId == "garden_lantern" then
		piece("Post", Vector3.new(width * 0.12, unit * 0.62, depth * 0.12), CFrame.new(0, unit * 0.36, 0), Color3.fromRGB(111, 77, 48), Enum.Material.Wood)
		piece("Lantern", Vector3.new(width * 0.42, unit * 0.28, depth * 0.42), CFrame.new(0, unit * 0.78, 0), Color3.fromRGB(255, 211, 125), Enum.Material.Neon)
		piece("Cap", Vector3.new(width * 0.56, unit * 0.08, depth * 0.56), CFrame.new(0, unit * 0.96, 0), Color3.fromRGB(83, 63, 49), Enum.Material.Wood)
	else
		local petHouse = catalogId == "pet_house"
		if petHouse then
			piece("Body", Vector3.new(width * 0.82, unit * 0.48, depth * 0.72), CFrame.new(0, unit * 0.24, 0), Color3.fromRGB(238, 190, 132), Enum.Material.Wood)
			piece("Roof", Vector3.new(width, unit * 0.16, depth * 0.9), CFrame.new(0, unit * 0.58, 0), Color3.fromRGB(105, 164, 205), Enum.Material.Slate)
			piece("Door", Vector3.new(width * 0.22, unit * 0.3, 0.12), CFrame.new(0, unit * 0.15, -depth * 0.365), Color3.fromRGB(91, 61, 47), Enum.Material.Wood)
			piece("Sign", Vector3.new(width * 0.38, unit * 0.13, 0.12), CFrame.new(0, unit * 0.82, -depth * 0.37), Color3.fromRGB(255, 218, 137), Enum.Material.SmoothPlastic)
			for index, x in ipairs({ -width * 0.30, width * 0.30 }) do
				piece("CornerBeam_" .. index, Vector3.new(width * 0.065, unit * 0.50, depth * 0.075), CFrame.new(x, unit * 0.25, -depth * 0.36), Color3.fromRGB(142, 97, 62), Enum.Material.Wood)
				piece("PetWindow_" .. index, Vector3.new(width * 0.105, unit * 0.14, 0.10), CFrame.new(x * 0.66, unit * 0.31, -depth * 0.37), Color3.fromRGB(255, 218, 149), Enum.Material.Glass)
			end
			piece("RoofRidge", Vector3.new(width * 0.92, unit * 0.075, depth * 0.12), CFrame.new(0, unit * 0.69, 0), Color3.fromRGB(73, 119, 165), Enum.Material.Slate)
			piece("PawBadge", Vector3.new(width * 0.13, unit * 0.09, 0.14), CFrame.new(0, unit * 0.825, -depth * 0.38), Color3.fromRGB(149, 91, 167), Enum.Material.SmoothPlastic)
		else
			piece("Foundation", Vector3.new(width, unit * 0.16, depth), CFrame.new(0, unit * 0.08, 0), Color3.fromRGB(119, 91, 72), Enum.Material.WoodPlanks)
			piece("Walls", Vector3.new(width * 0.9, unit * 0.68, depth * 0.84), CFrame.new(0, unit * 0.5, 0), Color3.fromRGB(246, 218, 169), Enum.Material.SmoothPlastic)
			piece("Roof", Vector3.new(width * 1.08, unit * 0.2, depth * 1.02), CFrame.new(0, unit * 0.94, 0), Color3.fromRGB(126, 83, 139), Enum.Material.Slate)
			piece("RoofRidge", Vector3.new(width * 0.97, unit * 0.09, depth * 0.14), CFrame.new(0, unit * 1.08, 0), Color3.fromRGB(93, 60, 114), Enum.Material.Slate)
			piece("Door", Vector3.new(width * 0.2, unit * 0.42, 0.14), CFrame.new(0, unit * 0.3, -depth * 0.425), Color3.fromRGB(126, 83, 57), Enum.Material.Wood)
			piece("DoorKnob", Vector3.new(unit * 0.055, unit * 0.055, unit * 0.055), CFrame.new(width * 0.055, unit * 0.28, -depth * 0.433 - 0.08), Color3.fromRGB(246, 202, 115), Enum.Material.Metal)
			for index, x in ipairs({ -width * 0.28, width * 0.28 }) do
				piece("Window_" .. index, Vector3.new(width * 0.16, unit * 0.17, 0.12), CFrame.new(x, unit * 0.58, -depth * 0.425), Color3.fromRGB(122, 214, 224), Enum.Material.Glass)
				piece("WindowSill_" .. index, Vector3.new(width * 0.2, unit * 0.045, 0.2), CFrame.new(x, unit * 0.47, -depth * 0.45), Color3.fromRGB(155, 104, 76), Enum.Material.Wood)
			end
			for index, x in ipairs({ -width * 0.40, width * 0.40 }) do
				piece("TimberTrim_" .. index, Vector3.new(width * 0.055, unit * 0.73, depth * 0.07), CFrame.new(x, unit * 0.48, -depth * 0.42), Color3.fromRGB(139, 91, 68), Enum.Material.Wood)
			end
		end
	end
	return model
end

local function createPreview()
	clearPreview()
	local island = findOwnIsland()
	if island == nil then
		setStatus("Остров ещё загружается", false)
		return
	end
	currentIsland = island
	local width = island:GetAttribute("GridWidth")
	local depth = island:GetAttribute("GridDepth")
	local cellSize = island:GetAttribute("GridCellSize")
	if type(width) ~= "number" or type(depth) ~= "number" or type(cellSize) ~= "number" then
		setStatus("Не настроена сетка острова", false)
		return
	end

	local part = Instance.new("Part")
	part.Name = "LocalBuildingPreview"
	part.Size = Vector3.new(BUILDING_WIDTH * cellSize, 5, BUILDING_DEPTH * cellSize)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = Enum.Material.ForceField
	part.Transparency = 1 -- Do not flash the footprint at world origin.
	part.Parent = Workspace
	currentPreview = part
	previewVisual = makePreviewVisual(selectedCatalogId, cellSize)
	previewVisual.Parent = Workspace
end

local function getIslandGrid(): (BasePart?, number?, number?, number?)
	local island = currentIsland
	if island == nil or island.Parent == nil then
		island = findOwnIsland()
		currentIsland = island
	end
	if island == nil then
		return nil, nil, nil, nil
	end
	local top = island:FindFirstChild("Island_GrassTop")
	if top == nil or not top:IsA("BasePart") then
		return nil, nil, nil, nil
	end
	local width = island:GetAttribute("GridWidth")
	local depth = island:GetAttribute("GridDepth")
	local cellSize = island:GetAttribute("GridCellSize")
	if type(width) ~= "number" or type(depth) ~= "number" or type(cellSize) ~= "number" then
		return nil, nil, nil, nil
	end
	return top, width, depth, cellSize
end

local function hasBuildingOverlap(x: number, z: number, footprintWidth: number, footprintDepth: number): boolean
	local island = currentIsland
	if island == nil or island.Parent == nil then
		return true
	end
	for _, child in ipairs(island:GetChildren()) do
		if child:IsA("Model")
			and (movingInstanceId == nil or child ~= selectedBuildingModel)
			and type(child:GetAttribute("BuildingInstanceId")) == "string"
		then
			local catalogId = child:GetAttribute("BuildingCatalogId")
			local otherX = child:GetAttribute("GridX")
			local otherZ = child:GetAttribute("GridZ")
			local otherRotation = child:GetAttribute("GridRotation")
			local otherSize = if type(catalogId) == "string" then BUILDING_SIZES[catalogId] else nil
			if otherSize == nil or type(otherX) ~= "number" or type(otherZ) ~= "number" or type(otherRotation) ~= "number" then
				return true
			end
			local otherWidth = if otherRotation % 180 == 0 then otherSize.width else otherSize.depth
			local otherDepth = if otherRotation % 180 == 0 then otherSize.depth else otherSize.width
			local separated = x + footprintWidth <= otherX
				or otherX + otherWidth <= x
				or z + footprintDepth <= otherZ
				or otherZ + otherDepth <= z
			if not separated then
				return true
			end
		end
	end
	return false
end

-- Re-check the selected grid cell without using the screen pointer.
local function updatePreviewAtCell(x: number, z: number)
	if not placing or currentPreview == nil then return end
	local top, width, depth, cellSize = getIslandGrid()
	if top == nil or width == nil or depth == nil or cellSize == nil then
		currentValid = false
		setStatus("Не удалось найти поверхность острова", false)
		return
	end
	local footprintWidth = if rotation % 180 == 0 then BUILDING_WIDTH else BUILDING_DEPTH
	local footprintDepth = if rotation % 180 == 0 then BUILDING_DEPTH else BUILDING_WIDTH
	local inside = x >= 0 and z >= 0 and x + footprintWidth <= width and z + footprintDepth <= depth
	local overlaps = inside and hasBuildingOverlap(x, z, footprintWidth, footprintDepth)
	local valid = inside and not overlaps
	currentCellX, currentCellZ = x, z
	currentValid = valid
	local centerX = (x + footprintWidth / 2 - width / 2) * cellSize
	local centerZ = (z + footprintDepth / 2 - depth / 2) * cellSize
	local previewHeight = if selectedCatalogId == "stone_path" then 0.35 elseif selectedCatalogId == "garden_lantern" then cellSize * 0.8 elseif selectedCatalogId == "flower_bed" then cellSize * 0.5 else cellSize * 0.7
	currentPreview.Size = Vector3.new(footprintWidth * cellSize, previewHeight, footprintDepth * cellSize)
	currentPreview.CFrame = top.CFrame * CFrame.new(centerX, top.Size.Y / 2 + previewHeight / 2, centerZ) * CFrame.Angles(0, math.rad(rotation), 0)
	if previewVisual then
		previewVisual:PivotTo(top.CFrame * CFrame.new(centerX, top.Size.Y / 2, centerZ) * CFrame.Angles(0, math.rad(rotation), 0))
		for _, descendant in ipairs(previewVisual:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant ~= previewVisual.PrimaryPart then
				descendant.Transparency = if valid then 0.3 else 0.65
			end
		end
	end
	currentPreview.Transparency = 0.65
	currentPreview.Color = if valid then COLORS.valid else COLORS.invalid
	local message = if not inside then "Объект выходит за границы острова" elseif overlaps then "Это место уже занято другим объектом" else "Место подходит — можно разместить"
	setStatus(message, valid)
end

local function updatePreview(screenPosition: Vector2)
	if not placing or currentPreview == nil then return end
	local top, _, _, cellSize = getIslandGrid()
	if top == nil or cellSize == nil then
		currentValid = false
		setStatus("Не удалось найти поверхность острова", false)
		return
	end
	local activeCamera = Workspace.CurrentCamera
	if activeCamera == nil then return end
	local ray = activeCamera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	-- Only the player's island ground is selectable in building mode.
	-- Trees, decorative meshes and existing buildings must not intercept the
	-- pointer: the footprint validator decides whether the chosen cell is free.
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { top }
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if result == nil or result.Instance ~= top then
		currentValid = false
		currentCellX, currentCellZ = nil, nil
		if currentPreview then currentPreview.Transparency = 1 end
		if previewVisual then
			for _, descendant in ipairs(previewVisual:GetDescendants()) do
				if descendant:IsA("BasePart") then descendant.Transparency = 1 end
			end
		end
		setStatus("Нажми на траву своего острова", false)
		return
	end
	local localPoint = top.CFrame:PointToObjectSpace(result.Position)
	local x = math.floor((localPoint.X + top.Size.X / 2) / cellSize)
	local z = math.floor((localPoint.Z + top.Size.Z / 2) / cellSize)
	updatePreviewAtCell(x, z)
end

local function setSelectedBuilding(catalogId: string)
	if buildRequestInFlight or demolitionRequestInFlight then return end
	-- A move keeps the original building type; catalog entries must not mutate it.
	if movingInstanceId ~= nil and catalogId ~= selectedCatalogId then return end
	local size = BUILDING_SIZES[catalogId]
	if size == nil then return end
	selectedCatalogId = catalogId
	BUILDING_WIDTH = size.width
	BUILDING_DEPTH = size.depth
	local catalogButtons = {
		main_house = mainHouseButton, pet_house = petHouseButton,
		stone_path = stonePathButton, garden_lantern = gardenLanternButton,
		flower_bed = flowerBedButton, wooden_fence = woodenFenceButton,
	}
	for id, button in pairs(catalogButtons) do
		local active = id == catalogId
		button.BackgroundColor3 = if active then Color3.fromRGB(91, 75, 126) else COLORS.panelLight
		local outline = button:FindFirstChild("SelectionStroke")
		if outline and outline:IsA("UIStroke") then
			outline.Transparency = if active then 0 else 0.75
			outline.Thickness = if active then 2.5 else 1
		end
		button:SetAttribute("Selected", active)
	end
	if currentPreview then
		local _, _, _, cellSize = getIslandGrid()
		if cellSize then
			if previewVisual then previewVisual:Destroy() end
			previewVisual = makePreviewVisual(catalogId, cellSize)
			previewVisual.Parent = Workspace
		end
	end
	local labels = {
		main_house = "Выбран главный дом",
		pet_house = "Выбран домик питомцев",
		stone_path = "Выбрана каменная дорожка",
		garden_lantern = "Выбран садовый фонарь",
		flower_bed = "Выбрана цветочная клумба",
		wooden_fence = "Выбран деревянный забор",
	}
	setStatus(labels[catalogId] or "Выбран объект")
	-- Keep the saved cell fixed while the player changes the catalog item.
	if placing and placementLocked and currentCellX ~= nil and currentCellZ ~= nil then
		updatePreviewAtCell(currentCellX, currentCellZ)
	end
end

mainHouseButton.Activated:Connect(function()
	setSelectedBuilding("main_house")
end)
petHouseButton.Activated:Connect(function()
	setSelectedBuilding("pet_house")
end)
stonePathButton.Activated:Connect(function()
	setSelectedBuilding("stone_path")
end)
gardenLanternButton.Activated:Connect(function()
	setSelectedBuilding("garden_lantern")
end)
flowerBedButton.Activated:Connect(function()
	setSelectedBuilding("flower_bed")
end)
woodenFenceButton.Activated:Connect(function()
	setSelectedBuilding("wooden_fence")
end)
local function beginMoveSelected()
	if buildRequestInFlight or demolitionRequestInFlight then return end
	local model = selectedBuildingModel
	if model == nil or model.Parent == nil then
		setStatus("Сначала выбери свою постройку", false)
		return
	end
	local instanceId = model:GetAttribute("BuildingInstanceId")
	local catalogId = model:GetAttribute("BuildingCatalogId")
	local savedRotation = model:GetAttribute("GridRotation")
	if type(instanceId) ~= "string" or type(catalogId) ~= "string" or BUILDING_SIZES[catalogId] == nil then
		setStatus("Не удалось прочитать данные постройки", false)
		return
	end
	-- Switching into Move is still a panel transition: close other open screens.
	dismissKingdomOverview()
	announcePanelOpened()
	-- Select the actual catalog type before the move lock becomes active.
	setSelectedBuilding(catalogId)
	movingInstanceId = instanceId
	rotation = if type(savedRotation) == "number" then savedRotation else 0
	placing = true
	panel.Visible = true
	moveButton.Visible = false
	demolishButton.Visible = false
	mainHouseButton.Active = false
	petHouseButton.Active = false
	stonePathButton.Active = false
	gardenLanternButton.Active = false
	flowerBedButton.Active = false
	woodenFenceButton.Active = false
	confirmButton.Text = "СОХРАНИТЬ"
	createPreview()
	if currentPreview == nil then
		placing = false
		movingInstanceId = nil
		panel.Visible = false
		confirmButton.Text = "ПОСТРОИТЬ"
		mainHouseButton.Active = true
		petHouseButton.Active = true
		stonePathButton.Active = true
		gardenLanternButton.Active = true
		flowerBedButton.Active = true
		woodenFenceButton.Active = true
		moveButton.Visible = true
		demolishButton.Visible = model:GetAttribute("BuildingCatalogId") ~= "main_house"
		return
	end
	placementLocked = false
	setStatus("Коснись земли, чтобы выбрать новое место")
end

moveButton.Activated:Connect(beginMoveSelected)


local function stopPlacing()
	if buildRequestInFlight then
		setStatus("Дождись ответа о строительстве", false)
		return
	end
	placing = false
	movingInstanceId = nil
	panel.Visible = false
	clearPreview()
	mainHouseButton.Active = true
	petHouseButton.Active = true
	stonePathButton.Active = true
	gardenLanternButton.Active = true
	flowerBedButton.Active = true
	woodenFenceButton.Active = true
	confirmButton.Text = "ПОСТРОИТЬ"
	if selectedBuildingModel and selectedBuildingModel.Parent then
		local selectedCatalog = selectedBuildingModel:GetAttribute("BuildingCatalogId")
		moveButton.Visible = true
		demolishButton.Visible = selectedCatalog ~= "main_house"
	end
end

local function beginPlacing()
	if buildRequestInFlight or demolitionRequestInFlight then return end
	dismissKingdomOverview()
	announcePanelOpened()
	movingInstanceId = nil
	setSelectedBuilding(selectedCatalogId)
	rotation = 0
	placing = true
	panel.Visible = true
	moveButton.Visible = false
	demolishButton.Visible = false
	createPreview()
	if currentPreview == nil then
		placing = false
		panel.Visible = false
		if selectedBuildingModel and selectedBuildingModel.Parent then
			moveButton.Visible = true
			demolishButton.Visible = selectedBuildingModel:GetAttribute("BuildingCatalogId") ~= "main_house"
		end
		return
	end
	placementLocked = false
	setStatus("Нажми на свободную траву, чтобы закрепить место")
end

rotateButton.Activated:Connect(function()
	if not placing or buildRequestInFlight then return end
	rotation = (rotation + 90) % 360
	if placementLocked and currentCellX ~= nil and currentCellZ ~= nil then updatePreviewAtCell(currentCellX, currentCellZ) end
end)

cancelButton.Activated:Connect(stopPlacing)
panelCloseButton.Activated:Connect(stopPlacing)

confirmButton.Activated:Connect(function()
	if buildRequestInFlight or not placing or not placementLocked or not currentValid or currentCellX == nil or currentCellZ == nil then
		setStatus("Сначала выбери подходящее место", false)
		return
	end
	-- Freeze the complete payload before InvokeServer yields to other UI input.
	local requestedCatalogId = selectedCatalogId
	local requestedX, requestedZ = currentCellX, currentCellZ
	local requestedRotation = rotation
	local requestedMoveId = movingInstanceId
	buildRequestInFlight = true
	closeAfterBuildResponse = false
	confirmButton.Active = false
	confirmButton.Text = "..."
	rotateButton.Active = false
	cancelButton.Active = false
	local operationKey = table.concat({
		"build",
		requestedCatalogId,
		tostring(requestedX),
		tostring(requestedZ),
		tostring(requestedRotation),
		tostring(requestedMoveId or ""),
	}, ":")
	local requestId = getPendingRequestId(operationKey)
	local ok, response = pcall(function()
		return remote:InvokeServer({
			requestId = requestId,
			catalogId = requestedCatalogId,
			x = requestedX,
			z = requestedZ,
			rotation = requestedRotation,
			movingInstanceId = requestedMoveId,
		})
	end)
	buildRequestInFlight = false
	local shouldCloseAfterResponse = closeAfterBuildResponse
	closeAfterBuildResponse = false
	confirmButton.Active = true
	rotateButton.Active = true
	cancelButton.Active = true
	confirmButton.Text = if requestedMoveId ~= nil then "СОХРАНИТЬ" else "ПОСТРОИТЬ"
	if ok and not shouldKeepPendingRequest(response) then clearPendingRequestId(operationKey) end
	if not ok then
		setStatus("Не удалось связаться с сервером", false)
		if shouldCloseAfterResponse then stopPlacing() end
		return
	end
	if type(response) == "table" and response.ok == true then
		local wasMoving = requestedMoveId ~= nil
		local successLabels = {
			main_house = "Главный дом построен!",
			pet_house = "Домик питомцев построен!",
			stone_path = "Каменная дорожка размещена!",
			garden_lantern = "Садовый фонарь размещён!",
			flower_bed = "Клумба размещена!",
			wooden_fence = "Секция забора установлена!",
		}
		setStatus(if wasMoving then "Объект перемещён!" else (successLabels[requestedCatalogId] or "Объект размещён!"), true)
		if wasMoving then selectBuilding(nil) end
		stopPlacing()
	else
		local code = if type(response) == "table" then tostring(response.code) else "UNKNOWN"
		local messages = {
			INSUFFICIENT_RESOURCES = "Не хватает ресурсов для этой постройки",
			SESSION_NOT_READY = "Остров ещё загружается",
			SESSION_NOT_WRITABLE = "Сейчас нельзя сохранить изменения. Попробуй позже",
			BUILDING_LIMIT_REACHED = "На острове больше нельзя размещать постройки",
			FOOTPRINT_OVERLAP = "Это место уже занято",
			OUT_OF_BOUNDS = "Постройка выходит за границы острова",
		}
		setStatus(messages[code] or ("Сервер отклонил постройку: " .. code), false)
		if shouldCloseAfterResponse then stopPlacing() end
	end
end)

local TAP_DRAG_THRESHOLD = 18
local MAX_TAP_DURATION = 0.55
local TOUCH_MOUSE_SUPPRESSION = 0.35
local activeTouches: { [InputObject]: boolean } = {}
local touchCount = 0
local gestureBlocked = false
local lastTouchTime = -math.huge
local touchCandidate: InputObject? = nil
local touchStartPosition: Vector2? = nil
local touchStartTime = 0
local touchStartedPlacing = false

local function isOverInteractiveGui(screenPosition: Vector2): boolean
	for _, object in ipairs(playerGui:GetGuiObjectsAtPosition(screenPosition.X, screenPosition.Y)) do
		if object:IsA("GuiButton") or object:IsA("ScrollingFrame") or object:IsA("TextBox") then
			return true
		end
	end
	return false
end

local function selectBuildingAt(screenPosition: Vector2)
	local activeCamera = Workspace.CurrentCamera
	if activeCamera == nil then return end
	local ray = activeCamera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if player.Character then params.FilterDescendantsInstances = { player.Character } end
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	selectBuilding(if hit then findBuildingModel(hit.Instance) else nil)
end

local function chooseWorldPoint(screenPosition: Vector2)
	if isOverInteractiveGui(screenPosition) then return end
	if placing then
		pointerPosition = screenPosition
		updatePreview(pointerPosition)
		placementLocked = currentValid
		if placementLocked then setStatus("Место закреплено. Нажми «Построить» или выбери другое", true) end
	else
		selectBuildingAt(screenPosition)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.Touch then
		lastTouchTime = os.clock()
		if not activeTouches[input] then
			activeTouches[input] = true
			touchCount += 1
		end
		-- Once two fingers participate, neither is allowed to select the world.
		if touchCount > 1 then
			gestureBlocked = true
			touchCandidate = nil
			touchStartPosition = nil
			return
		end
		if processed or buildRequestInFlight or demolitionRequestInFlight or gestureBlocked then return end
		local position = Vector2.new(input.Position.X, input.Position.Y)
		if isOverInteractiveGui(position) then return end
		touchCandidate = input
		touchStartPosition = position
		touchStartTime = os.clock()
		touchStartedPlacing = placing
		return
	end
	if processed or buildRequestInFlight or demolitionRequestInFlight then return end
	if input.KeyCode == Enum.KeyCode.R and placing then
		rotation = (rotation + 90) % 360
		if placementLocked and currentCellX ~= nil and currentCellZ ~= nil then updatePreviewAtCell(currentCellX, currentCellZ) end
	elseif input.KeyCode == Enum.KeyCode.Escape and placing then
		stopPlacing()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Some touch devices emit a synthetic mouse event for the same tap.
		if UserInputService.TouchEnabled and os.clock() - lastTouchTime < TOUCH_MOUSE_SUPPRESSION then return end
		chooseWorldPoint(UserInputService:GetMouseLocation())
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Touch then return end
	lastTouchTime = os.clock()
	if activeTouches[input] then
		activeTouches[input] = nil
		touchCount = math.max(0, touchCount - 1)
	end
	local isCandidate = input == touchCandidate
	local startPosition = touchStartPosition
	local elapsed = os.clock() - touchStartTime
	local sameMode = touchStartedPlacing == placing
	if isCandidate then
		touchCandidate = nil
		touchStartPosition = nil
	end
	local blocked = gestureBlocked
	if touchCount == 0 then gestureBlocked = false end
	if not isCandidate or blocked or touchCount ~= 0 then return end
	if buildRequestInFlight or demolitionRequestInFlight or startPosition == nil or not sameMode then return end
	if elapsed > MAX_TAP_DURATION then return end
	local endPosition = Vector2.new(input.Position.X, input.Position.Y)
	if (endPosition - startPosition).Magnitude > TAP_DRAG_THRESHOLD then return end
	chooseWorldPoint(endPosition)
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and not placementLocked then
		pointerPosition = UserInputService:GetMouseLocation()
	end
end)

RunService.RenderStepped:Connect(function()
	if placing and not buildRequestInFlight and not placementLocked and not touchPlacement then
		updatePreview(pointerPosition)
	end
end)

local function addBuildEntry()
	if gui:FindFirstChild("OpenBuildButton") then return end
	local open = make("TextButton", {
		Name = "OpenBuildButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -22, 0, 24),
		Size = UDim2.fromOffset(154, 48),
		BackgroundColor3 = COLORS.panel,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "🏡  СТРОИТЬ",
		TextColor3 = COLORS.gold,
		TextSize = 15,
	}, gui) :: TextButton
	make("UICorner", { CornerRadius = UDim.new(0, 14) }, open)
	make("UIStroke", { Color = COLORS.gold, Transparency = 0.3, Thickness = 1.3 }, open)
	open.Activated:Connect(beginPlacing)
end


local overviewShade = make("TextButton", {
	Name = "KingdomOverviewShade",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(12, 12, 22),
	BackgroundTransparency = 0.38,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 40,
}, gui) :: TextButton

local overview = make("Frame", {
	Name = "KingdomOverview",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, -32, 0, 286),
	BackgroundColor3 = COLORS.panel,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 41,
}, gui) :: Frame
make("UISizeConstraint", { MinSize = Vector2.new(300, 286), MaxSize = Vector2.new(420, 286) }, overview)
make("UICorner", { CornerRadius = UDim.new(0, 20) }, overview)
make("UIStroke", { Color = COLORS.gold, Transparency = 0.28, Thickness = 1.5 }, overview)
make("UIPadding", {
	PaddingTop = UDim.new(0, 18),
	PaddingBottom = UDim.new(0, 16),
	PaddingLeft = UDim.new(0, 20),
	PaddingRight = UDim.new(0, 20),
}, overview)

local overviewTitle = make("TextLabel", {
	Name = "Title",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -44, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "МОЁ КОРОЛЕВСТВО",
	TextColor3 = COLORS.gold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
}, overview) :: TextLabel

local overviewClose = make("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, -4),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = COLORS.panelLight,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "×",
	TextColor3 = COLORS.text,
	TextSize = 24,
	ZIndex = 43,
}, overview) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 11) }, overviewClose)

local overviewStage = make("TextLabel", {
	Name = "Stage",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 48),
	Size = UDim2.new(1, 0, 0, 34),
	Font = Enum.Font.GothamBold,
	Text = "🏡  Тихий остров",
	TextColor3 = COLORS.text,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
}, overview) :: TextLabel

local overviewStats = make("TextLabel", {
	Name = "Stats",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 88),
	Size = UDim2.new(1, 0, 0, 24),
	Font = Enum.Font.GothamMedium,
	Text = "0 очков развития  •  0 построек",
	TextColor3 = COLORS.text,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
}, overview) :: TextLabel

local progressBack = make("Frame", {
	Name = "ProgressBack",
	Position = UDim2.fromOffset(0, 128),
	Size = UDim2.new(1, 0, 0, 13),
	BackgroundColor3 = COLORS.panelLight,
	BorderSizePixel = 0,
	ZIndex = 42,
}, overview) :: Frame
make("UICorner", { CornerRadius = UDim.new(1, 0) }, progressBack)

local progressFill = make("Frame", {
	Name = "ProgressFill",
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = COLORS.gold,
	BorderSizePixel = 0,
	ZIndex = 43,
}, progressBack) :: Frame
make("UICorner", { CornerRadius = UDim.new(1, 0) }, progressFill)

local progressCaption = make("TextLabel", {
	Name = "ProgressCaption",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 150),
	Size = UDim2.new(1, 0, 0, 24),
	Font = Enum.Font.GothamMedium,
	Text = "До следующего этапа: 10 очков",
	TextColor3 = COLORS.gold,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
}, overview) :: TextLabel

local overviewHint = make("TextLabel", {
	Name = "Hint",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 180),
	Size = UDim2.new(1, 0, 0, 30),
	Font = Enum.Font.Gotham,
	Text = "Разнообразные постройки помогают развивать остров.",
	TextColor3 = COLORS.text,
	TextTransparency = 0.18,
	TextSize = 11,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
}, overview)

local overviewBuild = make("TextButton", {
	Name = "OpenConstruction",
	Position = UDim2.new(0, 0, 1, -54),
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundColor3 = Color3.fromRGB(45, 137, 91),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "ПЕРЕЙТИ К СТРОИТЕЛЬСТВУ",
	TextColor3 = COLORS.text,
	TextSize = 14,
	ZIndex = 42,
}, overview) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 13) }, overviewBuild)

local function closeKingdomOverview()
	overview.Visible = false
	overviewShade.Visible = false
end
dismissKingdomOverview = closeKingdomOverview

local function refreshKingdomOverview()
	local island = findOwnIsland()
	if island == nil then
		overviewStage.Text = "🏡  Остров загружается"
		overviewStats.Text = "Данные королевства пока недоступны"
		progressFill.Size = UDim2.fromScale(0, 1)
		progressCaption.Text = "Подожди завершения загрузки острова"
		return
	end

	local stageName = island:GetAttribute("KingdomBondStageName")
	local points = island:GetAttribute("KingdomBondPoints")
	local totalBuildingCount = island:GetAttribute("KingdomBondTotalBuildingCount")
	local stageId = island:GetAttribute("KingdomBondStage")
	local nextPoints = island:GetAttribute("KingdomBondNextStagePoints")
	if type(stageName) ~= "string" then stageName = "Тихий остров" end
	if type(points) ~= "number" then points = 0 end
	if type(totalBuildingCount) ~= "number" then totalBuildingCount = 0 end
	if type(stageId) ~= "string" then stageId = "quiet" end

	local buildingWord = if totalBuildingCount % 10 == 1 and totalBuildingCount % 100 ~= 11
		then "постройка"
		elseif totalBuildingCount % 10 >= 2 and totalBuildingCount % 10 <= 4
			and (totalBuildingCount % 100 < 12 or totalBuildingCount % 100 > 14)
		then "постройки"
		else "построек"

	overviewStage.Text = "🏡  " .. stageName
	overviewStats.Text = string.format("%d очков развития  •  %d %s", points, totalBuildingCount, buildingWord)

	if type(nextPoints) == "number" and nextPoints > 0 then
		local previousThresholdByStage = {
			quiet = 0,
			cozy = 10,
			blooming = 30,
			thriving = 50,
		}
		local previousThreshold = previousThresholdByStage[stageId] or 0
		local span = math.max(1, nextPoints - previousThreshold)
		local progress = math.clamp((points - previousThreshold) / span, 0, 1)
		progressFill.Size = UDim2.fromScale(progress, 1)
		progressCaption.Text = string.format("До следующего этапа: %d очков", math.max(0, nextPoints - points))
	else
		progressFill.Size = UDim2.fromScale(1, 1)
		progressCaption.Text = "Максимальный доступный этап развития"
	end
end

local function openKingdomOverview()
	if buildRequestInFlight then
		closeAfterBuildResponse = true
		panel.Visible = false
	else
		stopPlacing()
	end
	-- Move/Demolish action buttons must not float over the overview.
	if not demolitionRequestInFlight then selectBuilding(nil) end
	announcePanelOpened()
	refreshKingdomOverview()
	overviewShade.Visible = true
	overview.Visible = true
end

panelSignal.Event:Connect(function(origin)
	if origin ~= script.Name then
		closeKingdomOverview()
		if not demolitionRequestInFlight then selectBuilding(nil) end
		if buildRequestInFlight then
			-- Another panel takes focus immediately; do not cancel an in-flight transaction.
			panel.Visible = false
			closeAfterBuildResponse = true
		else
			stopPlacing()
		end
	end
end)

overviewClose.Activated:Connect(closeKingdomOverview)
overviewShade.Activated:Connect(closeKingdomOverview)
overviewBuild.Activated:Connect(function()
	closeKingdomOverview()
	beginPlacing()
end)

local function bindKingdomOverview(island: Instance)
	if not island:IsA("Model") or island:GetAttribute("OwnerUserId") ~= player.UserId then return end
	for _, attribute in ipairs({
		"KingdomBondStageName",
		"KingdomBondPoints",
		"KingdomBondBuildingCount",
		"KingdomBondTotalBuildingCount",
		"KingdomBondStage",
		"KingdomBondNextStagePoints",
	}) do
		island:GetAttributeChangedSignal(attribute):Connect(function()
			if overview.Visible then refreshKingdomOverview() end
		end)
	end
end

task.spawn(function()
	local folder = Workspace:WaitForChild("PlayerIslands", 30)
	if folder == nil then return end
	for _, island in ipairs(folder:GetChildren()) do bindKingdomOverview(island) end
	folder.ChildAdded:Connect(bindKingdomOverview)
end)

local function isOwnedMainHousePrompt(prompt: ProximityPrompt): boolean
	if prompt.Name ~= "MainHousePrompt" then return false end
	local foundMainHouse = false
	local current: Instance? = prompt
	while current do
		if current:IsA("Model") and current:GetAttribute("BuildingCatalogId") == "main_house" then
			foundMainHouse = true
		end
		if current:IsA("Model") and current:GetAttribute("OwnerUserId") == player.UserId then
			return foundMainHouse
		end
		current = current.Parent
	end
	return false
end

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	if isOwnedMainHousePrompt(prompt) then
		openKingdomOverview()
	end
end)

addBuildEntry()
print("[PetKingdoms] Building controller loaded.")
