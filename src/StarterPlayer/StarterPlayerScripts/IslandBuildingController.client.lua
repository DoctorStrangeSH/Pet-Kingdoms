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

local CATALOG_ID = "main_house"
local BUILDING_WIDTH = 3
local BUILDING_DEPTH = 3
local rotation = 0
local placing = false
local currentCellX: number? = nil
local currentCellZ: number? = nil
local currentIsland: Model? = nil
local currentPreview: BasePart? = nil
local currentValid = false
local lastMessage = ""
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
	Size = UDim2.fromOffset(370, 150),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Visible = false,
}, gui) :: Frame
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
	Text = "Выбери место для главного дома",
	TextColor3 = COLORS.text,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel) :: TextLabel

local buttons = make("Frame", {
	Name = "Buttons",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 65),
	Size = UDim2.new(1, 0, 0, 60),
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

local rotateButton = makeButton("Rotate", "↻  ПОВОРОТ", 112, COLORS.panelLight)
local confirmButton = makeButton("Confirm", "ПОСТРОИТЬ", 112, Color3.fromRGB(45, 137, 91))
local cancelButton = makeButton("Cancel", "ОТМЕНА", 86, Color3.fromRGB(139, 67, 76))

local function setStatus(message: string, good: boolean?)
	lastMessage = message
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

	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
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

local function stopPlacing()
	placing = false
	panel.Visible = false
	clearPreview()
end

local function beginPlacing()
	rotation = 0
	placing = true
	panel.Visible = true
	createPreview()
	if currentPreview == nil then
		placing = false
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
			catalogId = CATALOG_ID,
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
		setStatus("Дом построен!", true)
		stopPlacing()
	else
		local code = if type(response) == "table" then tostring(response.code) else "UNKNOWN"
		setStatus("Сервер отклонил постройку: " .. code, false)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not placing then return end
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
