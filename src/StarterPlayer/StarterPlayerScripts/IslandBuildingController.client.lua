--!strict
-- First playable island construction controller.
-- Preview is client-only; the server validates and commits every placement.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
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
}
local BUILDING_WIDTH = BUILDING_SIZES.main_house.width
local BUILDING_DEPTH = BUILDING_SIZES.main_house.depth
local rotation = 0
local placing = false
local currentCellX: number? = nil
local currentCellZ: number? = nil
local currentIsland: Model? = nil
local currentPreview: BasePart? = nil
local currentValid = false
local selectedBuildingModel: Model? = nil
local demolitionArmed = false
local pointerPosition = UserInputService:GetMouseLocation()

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
	Size = UDim2.new(1, -24, 0, 218),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Visible = false,
}, gui) :: Frame
make("UISizeConstraint", { MinSize = Vector2.new(320, 218), MaxSize = Vector2.new(420, 218) }, panel)
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
	Size = UDim2.new(1, 0, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "СТРОИТЕЛЬСТВО",
	TextColor3 = COLORS.gold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

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
	Position = UDim2.fromOffset(0, 142),
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
	Size = UDim2.new(1, 0, 0, 62),
}, panel)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 10),
}, catalogRow)

local function makeCatalogButton(name: string, label: string): TextButton
	local button = make("TextButton", {
		Name = name,
		Size = UDim2.new(0.5, -5, 0, 54),
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
local petHouseButton = makeCatalogButton("PetHouse", "🐾  ДОМИК ПИТОМЦЕВ")
local setStatus: (string, boolean?) -> ()

local demolishButton = make("TextButton", {
	Name = "DemolishSelected",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0, 22, 0, 24),
	Size = UDim2.fromOffset(190, 46),
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
	local current = target
	while current and current ~= Workspace do
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
	demolishButton.Visible = model ~= nil
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
	local ok, response = pcall(function()
		return remote:InvokeServer({
			requestId = HttpService:GenerateGUID(false),
			action = "demolish",
			instanceId = instanceId,
		})
	end)
	demolishButton.Active = true
	demolishButton.Text = "⌫  ДЕМОНТИРОВАТЬ"
	demolitionArmed = false
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

local function findOwnIsland(): Model?
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
	currentCellX = x
	currentCellZ = z
	currentValid = inside

	local centerX = (x + footprintWidth / 2 - width / 2) * cellSize
	local centerZ = (z + footprintDepth / 2 - depth / 2) * cellSize
	local target = top.CFrame * CFrame.new(centerX, top.Size.Y / 2 + 2.6, centerZ)
	if currentPreview:IsA("BasePart") then
		currentPreview.Size = Vector3.new(footprintWidth * cellSize, 5, footprintDepth * cellSize)
		currentPreview.CFrame = target * CFrame.Angles(0, math.rad(rotation), 0)
	end
	currentPreview.Color = if inside then COLORS.valid else COLORS.invalid
	setStatus(if inside then "Место подходит — можно построить" else "Дом выходит за границы острова", inside)
end

local function setSelectedBuilding(catalogId: string)
	local size = BUILDING_SIZES[catalogId]
	if size == nil then return end
	selectedCatalogId = catalogId
	BUILDING_WIDTH = size.width
	BUILDING_DEPTH = size.depth
	mainHouseButton.BackgroundColor3 = if catalogId == "main_house" then Color3.fromRGB(91, 75, 126) else COLORS.panelLight
	petHouseButton.BackgroundColor3 = if catalogId == "pet_house" then Color3.fromRGB(91, 75, 126) else COLORS.panelLight
	if currentPreview then
		local _, _, _, cellSize = getIslandGrid()
		if cellSize then
			currentPreview.Size = Vector3.new(BUILDING_WIDTH * cellSize, 5, BUILDING_DEPTH * cellSize)
		end
	end
	setStatus(if catalogId == "pet_house" then "Выбран домик питомцев" else "Выбран главный дом")
end

mainHouseButton.Activated:Connect(function()
	setSelectedBuilding("main_house")
end)
petHouseButton.Activated:Connect(function()
	setSelectedBuilding("pet_house")
end)

local function stopPlacing()
	placing = false
	panel.Visible = false
	clearPreview()
end

local function beginPlacing()
	setSelectedBuilding(selectedCatalogId)
	rotation = 0
	placing = true
	panel.Visible = true
	createPreview()
	if currentPreview == nil then
		placing = false
		panel.Visible = false
		return
	end
	setStatus("Наведи на траву и выбери место")
end

rotateButton.Activated:Connect(function()
	if not placing then return end
	rotation = (rotation + 90) % 360
end)

cancelButton.Activated:Connect(stopPlacing)

confirmButton.Activated:Connect(function()
	if not placing or not currentValid or currentCellX == nil or currentCellZ == nil then
		setStatus("Сначала выбери подходящее место", false)
		return
	end
	confirmButton.Active = false
	confirmButton.Text = "..."
	local ok, response = pcall(function()
		return remote:InvokeServer({
			requestId = HttpService:GenerateGUID(false),
			catalogId = selectedCatalogId,
			x = currentCellX,
			z = currentCellZ,
			rotation = rotation,
		})
	end)
	confirmButton.Active = true
	confirmButton.Text = "ПОСТРОИТЬ"
	if not ok then
		setStatus("Не удалось связаться с сервером", false)
		return
	end
	if type(response) == "table" and response.ok == true then
		setStatus(if selectedCatalogId == "pet_house" then "Домик питомцев построен!" else "Главный дом построен!", true)
		stopPlacing()
	else
		local code = if type(response) == "table" then tostring(response.code) else "UNKNOWN"
		setStatus("Сервер отклонил постройку: " .. code, false)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not placing and input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mousePosition = UserInputService:GetMouseLocation()
		local ray = camera:ScreenPointToRay(mousePosition.X, mousePosition.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		if player.Character then params.FilterDescendantsInstances = { player.Character } end
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
		selectBuilding(if hit then findBuildingModel(hit.Instance) else nil)
		return
	end
	if not placing then return end
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

addBuildEntry()
print("[PetKingdoms] Building controller loaded.")
