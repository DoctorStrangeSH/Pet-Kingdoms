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
local buildMenuOpen = false
local currentCellX: number? = nil
local currentCellZ: number? = nil
local currentIsland: Model? = nil
local currentPreview: BasePart? = nil
local currentValid = false
local selectedBuildingModel: Model? = nil
local movingInstanceId: string? = nil
local demolitionArmed = false
local pointerPosition = UserInputService:GetMouseLocation()
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
	Size = UDim2.new(1, -24, 0, 340),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Visible = false,
}, gui) :: Frame
local panelSizeConstraint = make("UISizeConstraint", { MinSize = Vector2.new(300, 130), MaxSize = Vector2.new(420, 340) }, panel) :: UISizeConstraint
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
	Size = UDim2.new(1, -48, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "СТРОИТЕЛЬСТВО",
	TextColor3 = COLORS.gold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local closeBuildButton = make("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, -2),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = COLORS.panelLight,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "×",
	TextColor3 = COLORS.text,
	TextSize = 24,
}, panel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 10) }, closeBuildButton)

local status = make("TextLabel", {
	Name = "Status",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 30),
	Size = UDim2.new(1, 0, 0, 25),
	Font = Enum.Font.GothamMedium,
	Text = "Выбери здание и место для него",
	TextColor3 = COLORS.text,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel) :: TextLabel

local buttons = make("Frame", {
	Name = "Buttons",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 244),
	Size = UDim2.new(1, 0, 0, 54),
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
		Size = UDim2.fromOffset(width, 48),
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

local catalogRow = make("Frame", {
	Name = "Catalog",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 62),
	Size = UDim2.new(1, 0, 0, 176),
}, panel)
make("UIGridLayout", {
	CellSize = UDim2.new(0.5, -5, 0, 50),
	CellPadding = UDim2.fromOffset(10, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, catalogRow)

local function makeCatalogButton(name: string, label: string): TextButton
	local button = make("TextButton", {
		Name = name,
		Size = UDim2.new(0.5, -5, 0, 50),
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
	make("UIStroke", { Color = COLORS.gold, Transparency = 0.75, Thickness = 1 }, button)
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
	if type(instanceId) ~= "string" then
		setStatus("Не удалось определить постройку", false)
		return
	end
	demolishButton.Active = false
	demolishButton.Text = "..."
	local operationKey = "demolish:" .. instanceId
	local requestId = getPendingRequestId(operationKey)
	local ok, response = pcall(function()
		return remote:InvokeServer({
			requestId = requestId,
			action = "demolish",
			instanceId = instanceId,
		})
	end)
	demolishButton.Active = true
	demolishButton.Text = "⌫  ДЕМОНТИРОВАТЬ"
	demolitionArmed = false
	if ok and not shouldKeepPendingRequest(response) then clearPendingRequestId(operationKey) end
	if not ok then
		setStatus("Не удалось связаться с сервером", false)
		return
	end
	if type(response) == "table" and response.ok == true then
		selectBuilding(nil)
		setStatus("Постройка демонтирована", true)
	else
		local code = if type(response) == "table" then tostring(response.code) else "UNKNOWN"
		setStatus("Нельзя демонтировать: " .. code, false)
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
	currentCellX = nil
	currentCellZ = nil
	currentValid = false
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
	part.Transparency = 0.45
	part.Parent = Workspace
	currentPreview = part
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

local function updatePreview(screenPosition: Vector2)
	if not placing or currentPreview == nil then
		return
	end
	local top, width, depth, cellSize = getIslandGrid()
	if top == nil or width == nil or depth == nil or cellSize == nil then
		currentValid = false
		setStatus("Не удалось найти поверхность острова", false)
		return
	end

	local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded: { Instance } = { currentPreview }
	if player.Character then
		table.insert(excluded, player.Character)
	end
	if movingInstanceId ~= nil and selectedBuildingModel ~= nil then
		table.insert(excluded, selectedBuildingModel)
	end
	params.FilterDescendantsInstances = excluded
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if result == nil or result.Instance ~= top then
		currentValid = false
		currentCellX = nil
		currentCellZ = nil
		setStatus("Наведи на траву своего острова", false)
		return
	end

	local localPoint = top.CFrame:PointToObjectSpace(result.Position)
	local x = math.floor((localPoint.X + top.Size.X / 2) / cellSize)
	local z = math.floor((localPoint.Z + top.Size.Z / 2) / cellSize)
	local footprintWidth = if rotation % 180 == 0 then BUILDING_WIDTH else BUILDING_DEPTH
	local footprintDepth = if rotation % 180 == 0 then BUILDING_DEPTH else BUILDING_WIDTH
	local inside = x >= 0 and z >= 0 and x + footprintWidth <= width and z + footprintDepth <= depth
	local overlaps = inside and hasBuildingOverlap(x, z, footprintWidth, footprintDepth)
	local valid = inside and not overlaps
	currentCellX = x
	currentCellZ = z
	currentValid = valid

	local centerX = (x + footprintWidth / 2 - width / 2) * cellSize
	local centerZ = (z + footprintDepth / 2 - depth / 2) * cellSize
	local previewHeight = if selectedCatalogId == "stone_path" then 0.35 elseif selectedCatalogId == "garden_lantern" then cellSize * 0.8 elseif selectedCatalogId == "flower_bed" then cellSize * 0.5 else cellSize * 0.7
	local target = top.CFrame * CFrame.new(centerX, top.Size.Y / 2 + previewHeight / 2, centerZ)
	if currentPreview:IsA("BasePart") then
		currentPreview.Size = Vector3.new(footprintWidth * cellSize, previewHeight, footprintDepth * cellSize)
		currentPreview.CFrame = target * CFrame.Angles(0, math.rad(rotation), 0)
	end
	currentPreview.Color = if valid then COLORS.valid else COLORS.invalid
	local message = if not inside then "Объект выходит за границы острова" elseif overlaps then "Это место уже занято другим объектом" else "Место подходит — можно разместить"
	setStatus(message, valid)
end

local function setSelectedBuilding(catalogId: string)
	local size = BUILDING_SIZES[catalogId]
	if size == nil then return end
	selectedCatalogId = catalogId
	BUILDING_WIDTH = size.width
	BUILDING_DEPTH = size.depth
	mainHouseButton.BackgroundColor3 = if catalogId == "main_house" then Color3.fromRGB(91, 75, 126) else COLORS.panelLight
	petHouseButton.BackgroundColor3 = if catalogId == "pet_house" then Color3.fromRGB(91, 75, 126) else COLORS.panelLight
	stonePathButton.BackgroundColor3 = if catalogId == "stone_path" then Color3.fromRGB(91, 75, 126) else COLORS.panelLight
	gardenLanternButton.BackgroundColor3 = if catalogId == "garden_lantern" then Color3.fromRGB(91, 75, 126) else COLORS.panelLight
	flowerBedButton.BackgroundColor3 = if catalogId == "flower_bed" then Color3.fromRGB(91, 75, 126) else COLORS.panelLight
	woodenFenceButton.BackgroundColor3 = if catalogId == "wooden_fence" then Color3.fromRGB(91, 75, 126) else COLORS.panelLight
	if currentPreview then
		local _, _, _, cellSize = getIslandGrid()
		if cellSize then
			local previewHeight = if catalogId == "stone_path" then 0.35 elseif catalogId == "garden_lantern" then cellSize * 0.8 elseif catalogId == "flower_bed" then cellSize * 0.5 else cellSize * 0.7
			currentPreview.Size = Vector3.new(BUILDING_WIDTH * cellSize, previewHeight, BUILDING_DEPTH * cellSize)
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
	setStatus((labels[catalogId] or "Выбран объект") .. " — нажми «Выбрать место»")
	if buildMenuOpen and not placing then confirmButton.Text = "ВЫБРАТЬ МЕСТО" end
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
-- Keep the preview stage compact so the placement controls no longer
-- obscure the world. Reopen the catalogue at its normal height when needed.
local function updateBuildPanelMode()
	local currentCamera = Workspace.CurrentCamera
	if currentCamera == nil then return end
	local viewport = currentCamera.ViewportSize
	local compact = viewport.X < 370
	local width = math.clamp(viewport.X - 24, 300, 420)
	local height = if placing then 136 else math.clamp(viewport.Y - 48, 300, 340)
	panel.Size = UDim2.fromOffset(width, height)
	panel.Position = UDim2.new(0.5, 0, 1, -16)
	catalogRow.Visible = not placing
	buttons.Position = UDim2.fromOffset(0, if placing then 66 else 244)
	rotateButton.Size = UDim2.fromOffset(if compact then 78 else 94, 48)
	confirmButton.Size = UDim2.fromOffset(if compact then 96 else 104, 48)
	cancelButton.Size = UDim2.fromOffset(if compact then 68 else 78, 48)
	status.TextSize = if compact then 11 else 13
	for _, button in ipairs({ mainHouseButton, petHouseButton, stonePathButton, gardenLanternButton, flowerBedButton, woodenFenceButton }) do
		button.TextSize = if compact then 11 else 13
	end
end

local function beginMoveSelected()
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
	movingInstanceId = instanceId
	setSelectedBuilding(catalogId)
	rotation = if type(savedRotation) == "number" then savedRotation else 0
	placing = true
	buildMenuOpen = true
	updateBuildPanelMode()
	panel.Visible = true
	playerGui:SetAttribute("PetKingdomsActiveModal", "building")
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
		moveButton.Visible = true
		demolishButton.Visible = model:GetAttribute("BuildingCatalogId") ~= "main_house"
		return
	end
	setStatus("Выбери новое место для постройки")
end

moveButton.Activated:Connect(beginMoveSelected)


local function stopPlacing()
	placing = false
	buildMenuOpen = false
	movingInstanceId = nil
	updateBuildPanelMode()
	panel.Visible = false
	if playerGui:GetAttribute("PetKingdomsActiveModal") == "building" then playerGui:SetAttribute("PetKingdomsActiveModal", nil) end
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
	movingInstanceId = nil
	rotation = 0
	placing = false
	buildMenuOpen = true
	updateBuildPanelMode()
	panel.Visible = true
	playerGui:SetAttribute("PetKingdomsActiveModal", "building")
	moveButton.Visible = false
	demolishButton.Visible = false
	clearPreview()
	confirmButton.Text = "ВЫБРАТЬ МЕСТО"
	confirmButton.Active = true
	setStatus("1. Выбери постройку  2. Нажми «Выбрать место»")
end

local function beginPlacementPreview()
	if not buildMenuOpen or placing then return end
	placing = true
	updateBuildPanelMode()
	confirmButton.Text = "ПОДТВЕРДИТЬ"
	setStatus("Перемещай предпросмотр. Нажми «Подтвердить», когда место подходит")
	createPreview()
	if currentPreview == nil then
		placing = false
		updateBuildPanelMode()
		confirmButton.Text = "ВЫБРАТЬ МЕСТО"
		return
	end
	updatePreview(pointerPosition)
end

rotateButton.Activated:Connect(function()
	if not placing then return end
	rotation = (rotation + 90) % 360
end)

cancelButton.Activated:Connect(stopPlacing)
closeBuildButton.Activated:Connect(stopPlacing)
playerGui:GetAttributeChangedSignal("PetKingdomsActiveModal"):Connect(function()
	local owner = playerGui:GetAttribute("PetKingdomsActiveModal")
	if owner ~= nil and owner ~= "building" and buildMenuOpen then
		placing = false
		buildMenuOpen = false
		movingInstanceId = nil
		updateBuildPanelMode()
		panel.Visible = false
		clearPreview()
		mainHouseButton.Active = true
		petHouseButton.Active = true
		stonePathButton.Active = true
		gardenLanternButton.Active = true
		flowerBedButton.Active = true
		woodenFenceButton.Active = true
		confirmButton.Text = "ВЫБРАТЬ МЕСТО"
	end
end)

confirmButton.Activated:Connect(function()
	if buildMenuOpen and not placing then
		beginPlacementPreview()
		return
	end
	if not placing or not currentValid or currentCellX == nil or currentCellZ == nil then
		setStatus("Сначала выбери подходящее место", false)
		return
	end
	confirmButton.Active = false
	confirmButton.Text = "..."
	local operationKey = table.concat({
		"build",
		selectedCatalogId,
		tostring(currentCellX),
		tostring(currentCellZ),
		tostring(rotation),
		tostring(movingInstanceId or ""),
	}, ":")
	local requestId = getPendingRequestId(operationKey)
	local ok, response = pcall(function()
		return remote:InvokeServer({
			requestId = requestId,
			catalogId = selectedCatalogId,
			x = currentCellX,
			z = currentCellZ,
			rotation = rotation,
			movingInstanceId = movingInstanceId,
		})
	end)
	confirmButton.Active = true
	confirmButton.Text = if movingInstanceId ~= nil then "СОХРАНИТЬ" else "ПОДТВЕРДИТЬ"
	if ok and not shouldKeepPendingRequest(response) then clearPendingRequestId(operationKey) end
	if not ok then
		setStatus("Не удалось связаться с сервером", false)
		return
	end
	if type(response) == "table" and response.ok == true then
		local wasMoving = movingInstanceId ~= nil
		local successLabels = {
			main_house = "Главный дом построен!",
			pet_house = "Домик питомцев построен!",
			stone_path = "Каменная дорожка размещена!",
			garden_lantern = "Садовый фонарь размещён!",
			flower_bed = "Клумба размещена!",
			wooden_fence = "Секция забора установлена!",
		}
		setStatus(if wasMoving then "Объект перемещён!" else (successLabels[selectedCatalogId] or "Объект размещён!"), true)
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
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not placing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local mousePosition = if input.UserInputType == Enum.UserInputType.Touch then Vector2.new(input.Position.X, input.Position.Y) else UserInputService:GetMouseLocation()
		local ray = camera:ScreenPointToRay(mousePosition.X, mousePosition.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		if player.Character then params.FilterDescendantsInstances = { player.Character } end
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
		selectBuilding(if hit then findBuildingModel(hit.Instance) else nil)
		return
	end
	if not placing then
		if input.KeyCode == Enum.KeyCode.Escape and buildMenuOpen then stopPlacing() end
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		rotation = (rotation + 90) % 360
	elseif input.KeyCode == Enum.KeyCode.Escape then
		stopPlacing()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		pointerPosition = if input.UserInputType == Enum.UserInputType.Touch
			then Vector2.new(input.Position.X, input.Position.Y)
			else UserInputService:GetMouseLocation()
		updatePreview(pointerPosition)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		pointerPosition = UserInputService:GetMouseLocation()
	elseif input.UserInputType == Enum.UserInputType.Touch then
		pointerPosition = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

RunService.RenderStepped:Connect(function()
	if placing then
		updatePreview(pointerPosition)
	end
end)

local function resizeBuildingPanel()
	updateBuildPanelMode()
end

if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeBuildingPanel)
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeBuildingPanel)
		resizeBuildingPanel()
	end
end)
resizeBuildingPanel()

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
	if playerGui:GetAttribute("PetKingdomsActiveModal") == "kingdom" then
		playerGui:SetAttribute("PetKingdomsActiveModal", nil)
	end
end

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
	playerGui:SetAttribute("PetKingdomsActiveModal", "kingdom")
	refreshKingdomOverview()
	overviewShade.Visible = true
	overview.Visible = true
end

playerGui:GetAttributeChangedSignal("PetKingdomsActiveModal"):Connect(function()
	if overview.Visible and playerGui:GetAttribute("PetKingdomsActiveModal") ~= "kingdom" then
		closeKingdomOverview()
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not overview.Visible then return end
	if input.KeyCode == Enum.KeyCode.Escape then closeKingdomOverview() end
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
