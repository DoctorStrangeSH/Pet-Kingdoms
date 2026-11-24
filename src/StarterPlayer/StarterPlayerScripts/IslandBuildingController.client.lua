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
local ModalManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModalManager"))
local function announcePanelOpened()
	ModalManager.Open(script.Name)
end

local camera = Workspace.CurrentCamera
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlaceBuilding") :: RemoteFunction
local GridMath = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Building"):WaitForChild("GridMath"))
local BUILDING_SIZES = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Building"):WaitForChild("BuildingFootprints"))

local selectedCatalogId = "main_house"
local BUILDING_WIDTH = BUILDING_SIZES.main_house.width
local BUILDING_DEPTH = BUILDING_SIZES.main_house.depth
local rotation = 0
local placing = false
local panelCollapsed = false
local currentCellX: number? = nil
local currentCellZ: number? = nil
local currentIsland: Model? = nil
local currentPreview: BasePart? = nil
local previewVisual: Model? = nil
local currentValid = false
local selectedBuildingModel: Model? = nil
local selectedBuildingDestroyConnection: RBXScriptConnection? = nil
local selectedBuildingHighlight: Highlight? = nil
local movingInstanceId: string? = nil
local demolitionArmed = false
local pointerPosition = UserInputService:GetMouseLocation()
local placementLocked = false
local buildRequestInFlight = false
local demolitionRequestInFlight = false
local upgradeRequestInFlight = false
local closeAfterBuildResponse = false
local touchPlacement = UserInputService.TouchEnabled
local pendingRequestIds: { [string]: string } = {}
local pendingBuildingOperationKey: string? = nil
local pendingBuildingOperation: { key: string, requestId: string, payload: { [string]: any }, description: string }? = nil

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

local InterfaceTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceTheme"))
local InterfaceComponents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceComponents"))
local NotificationManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NotificationManager"))
local RequestRunner = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RequestRunner"))
local COLORS = InterfaceTheme.Colors

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
	DisplayOrder = 16,
}, playerGui) :: ScreenGui

local recoveryPanel = make("Frame", {
	Name = "PendingOperationRecovery",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 18),
	Size = UDim2.new(1, -28, 0, 92),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.03,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 20,
}, gui) :: Frame
make("UISizeConstraint", { MinSize = Vector2.new(220, 92), MaxSize = Vector2.new(430, 92) }, recoveryPanel)
make("UICorner", { CornerRadius = UDim.new(0, 14) }, recoveryPanel)
make("UIStroke", { Color = COLORS.gold, Transparency = 0.2, Thickness = 1.5 }, recoveryPanel)
local recoveryTitle = make("TextLabel", {
	Name = "RecoveryTitle",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(12, 8),
	Size = UDim2.new(1, -24, 0, 24),
	Font = Enum.Font.GothamBold,
	Text = "ОПЕРАЦИЯ НЕ ПОДТВЕРЖДЕНА",
	TextColor3 = COLORS.gold,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 21,
}, recoveryPanel) :: TextLabel
local recoveryDescription = make("TextLabel", {
	Name = "RecoveryDescription",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(12, 32),
	Size = UDim2.new(1, -24, 0, 18),
	Font = Enum.Font.Gotham,
	Text = "Проверь результат, не создавая повторную операцию.",
	TextColor3 = COLORS.text,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 21,
}, recoveryPanel) :: TextLabel
local recoveryButton = make("TextButton", {
	Name = "RetryPendingOperation",
	Position = UDim2.new(0, 10, 0, 56),
	Size = UDim2.new(1, -20, 0, 28),
	BackgroundColor3 = COLORS.gold,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "ПРОВЕРИТЬ РЕЗУЛЬТАТ",
	TextColor3 = COLORS.panel,
	TextSize = 11,
	ZIndex = 21,
}, recoveryPanel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 8) }, recoveryButton)

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
local panelScale = make("UIScale", { Scale = 1 }, panel) :: UIScale
local panelConstraint = make("UISizeConstraint", { MinSize = Vector2.new(220, 190), MaxSize = Vector2.new(540, 245) }, panel) :: UISizeConstraint
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
	Text = InterfaceTheme.Icons.Close,
	TextColor3 = COLORS.text,
	TextSize = 24,
	ZIndex = 4,
}, panel) :: TextButton
InterfaceComponents.StyleCloseButton(panelCloseButton)

local collapseButton = make("TextButton", {
	Name = "CollapseConstruction",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -48, 0, 0),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = COLORS.panelLight,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "−",
	TextColor3 = COLORS.text,
	TextSize = 24,
	ZIndex = 4,
}, panel) :: TextButton
InterfaceComponents.StyleCloseButton(collapseButton)
collapseButton.Text = "-"

local reopenConstructionButton = make("TextButton", {
	Name = "ReopenConstruction",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 62),
	Size = UDim2.fromOffset(112, 38),
	BackgroundColor3 = COLORS.panel,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "СТРОЙКА",
	TextColor3 = COLORS.gold,
	TextSize = 12,
	Visible = false,
	ZIndex = 30,
}, gui) :: TextButton
InterfaceComponents.StyleActionButton(reopenConstructionButton, "gold")

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
	local variant = if name == "Confirm" then "primary" elseif name == "Cancel" then "danger" else "secondary"
	InterfaceComponents.StyleActionButton(button, variant)
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

local mainHouseButton = makeCatalogButton("MainHouse", "ГЛАВНЫЙ ДОМ")
local petHouseButton = makeCatalogButton("PetHouse", "ДОМИК ПИТОМЦЕВ\n5 дерева • 2 камня")
local stonePathButton = makeCatalogButton("StonePath", "КАМЕННАЯ ДОРОЖКА\n1 дерево • 1 камень")
local gardenLanternButton = makeCatalogButton("GardenLantern", "САДОВЫЙ ФОНАРЬ\n2 дерева • 1 камень")
local flowerBedButton = makeCatalogButton("FlowerBed", "КЛУМБА\n1 дерево")
local woodenFenceButton = makeCatalogButton("WoodenFence", "ЗАБОР\n1 дерево")
local setStatus: (string, boolean?) -> ()
local setPendingBuildingOperation: (string, string, { [string]: any }, string) -> ()
local clearPendingBuildingOperation: () -> ()
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
	Text = "ПЕРЕНЕСТИ",
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
	Text = "ДЕМОНТИРОВАТЬ",
	TextColor3 = COLORS.text,
	TextSize = 13,
	Visible = false,
}, gui) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 13) }, demolishButton)
make("UIStroke", { Color = COLORS.gold, Transparency = 0.5, Thickness = 1 }, demolishButton)

-- A single compact context card replaces the old floating action buttons.
-- It is shown only while an owned building is selected.
local selectionPanel = make("Frame", {
	Name = "BuildingContextCard",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(12, 62),
	Size = UDim2.fromOffset(340, 124),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 15,
}, gui) :: Frame
make("UICorner", { CornerRadius = UDim.new(0, 16) }, selectionPanel)
make("UIStroke", { Color = COLORS.gold, Transparency = 0.28, Thickness = 1.3 }, selectionPanel)
make("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
}, selectionPanel)
local selectionTitle = make("TextLabel", {
	Name = "BuildingTitle",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.new(1, -34, 0, 24),
	Font = Enum.Font.GothamBold,
	Text = "ПОСТРОЙКА",
	TextColor3 = COLORS.gold,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 16,
}, selectionPanel) :: TextLabel
local selectionDetails = make("TextLabel", {
	Name = "BuildingDetails",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 26),
	Size = UDim2.new(1, 0, 0, 26),
	Font = Enum.Font.Gotham,
	Text = "Уровень 1",
	TextColor3 = COLORS.muted,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	ZIndex = 16,
}, selectionPanel) :: TextLabel
local selectionCloseButton = make("TextButton", {
	Name = "CloseBuildingContext",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, -3),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = COLORS.panelLight,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "×",
	TextColor3 = COLORS.text,
	TextSize = 21,
	ZIndex = 17,
}, selectionPanel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 9) }, selectionCloseButton)
local upgradeButton = make("TextButton", {
	Name = "UpgradeSelectedBuilding",
	BackgroundColor3 = Color3.fromRGB(75, 126, 102),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "УЛУЧШИТЬ",
	TextColor3 = COLORS.text,
	TextSize = 11,
	Visible = false,
	ZIndex = 16,
}, selectionPanel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 10) }, upgradeButton)
make("UIStroke", { Color = COLORS.gold, Transparency = 0.65, Thickness = 1 }, upgradeButton)
moveButton.Parent = selectionPanel
demolishButton.Parent = selectionPanel
moveButton.ZIndex = 16
demolishButton.ZIndex = 16

-- Fit all construction actions inside the actual panel content width.
-- A tiny phone should never require horizontal scrolling to reach Confirm/Cancel.
local compactBuildingUI = false
local buildEntryButton: TextButton? = nil

local function resizeBuildingPanel()
	local activeCamera = Workspace.CurrentCamera
	if activeCamera == nil then return end
	local viewport, safeOrigin, safeSize = InterfaceComponents.GetSafeViewport(activeCamera, gui)
	local compact = viewport.X < 520
	local ultraShort = compact and safeSize.Y < 220
	compactBuildingUI = compact
	local desiredWidth = math.min(compact and 380 or 480, safeSize.X - 20)
	local desiredHeight = if ultraShort then 126 elseif compact then 190 else 228
	local safePanelSize = InterfaceComponents.ClampPanelSize(
		Vector2.new(math.max(180, desiredWidth), desiredHeight),
		safeSize,
		10
	)
	local panelWidth = safePanelSize.X
	local panelHeight = safePanelSize.Y
	-- Keep all three placement actions at a full 44 px touch height on
	-- ultra-short landscape screens; reflow the panel instead of scaling taps down.
	panelScale.Scale = if ultraShort then 1
		elseif compact then math.clamp((viewport.Y - 100) / panelHeight, 0.82, 1)
		else math.clamp((viewport.Y - 72) / panelHeight, 0.82, 1)
	panelConstraint.MinSize = Vector2.new(math.min(180, panelWidth), math.min(if ultraShort then 116 elseif compact then 184 else 210, panelHeight))
	panelConstraint.MaxSize = safePanelSize
	panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
	status.Position = UDim2.fromOffset(0, if ultraShort then 4 elseif compact then 27 else 30)
	status.Size = UDim2.new(1, if ultraShort then -78 else 0, 0, if ultraShort then 18 elseif compact then 24 else 30)
	catalogRow.Position = UDim2.fromOffset(0, if ultraShort then 27 elseif compact then 52 else 62)
	catalogRow.Size = UDim2.new(1, 0, 0, if ultraShort then 40 elseif compact then 62 else 84)
	buttons.Position = UDim2.fromOffset(0, if ultraShort then 72 elseif compact then 120 else 157)
	buttons.Size = UDim2.new(1, 0, 0, 44)
	-- Keep the construction panel inside the Roblox safe area at the bottom.
	-- This changes only the panel; placement preview and grid coordinates stay world-driven.
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.fromOffset(
		safeOrigin.X + safeSize.X * 0.5,
		safeOrigin.Y + safeSize.Y - (if compact then 8 else 18)
	)
	local contentWidth = panelWidth - 28 -- 14-pixel left and right padding.
	local gap = 8
	local available = contentWidth - 2 * gap
	local narrow = panelWidth < 370
	local tiny = viewport.X < 360
	local title = panel:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Visible = not ultraShort
		title.TextSize = if compact then 14 else 16
		title.Size = UDim2.new(1, -52, 0, 28)
	end
	panelCloseButton.Size = UDim2.fromOffset(if ultraShort then 28 else 40, if ultraShort then 28 else 40)
	collapseButton.Size = UDim2.fromOffset(if ultraShort then 28 else 36, if ultraShort then 28 else 36)
	collapseButton.Position = UDim2.new(1, if ultraShort then -34 else -48, 0, 0)
	reopenConstructionButton.Size = UDim2.fromOffset(if tiny then 96 else 112, 38)
	status.TextSize = if ultraShort then 9 else (if tiny then 10 else (if compact then 11 else 12))
	for _, button in ipairs({ mainHouseButton, petHouseButton, stonePathButton, gardenLanternButton, flowerBedButton, woodenFenceButton }) do
		button.TextSize = if ultraShort then 8 else (if tiny then 9 else (if compact then 10 else 13))
		button.Size = UDim2.fromOffset(if ultraShort then 100 else (if compact then (if tiny then 106 else 112) else 130), if ultraShort then 40 else (if compact then 52 else 70))
	end
	catalogRow.ScrollBarThickness = if compact then 3 else 4
	local rotateWidth = if narrow then math.floor(available * 0.27) else 94
	local cancelWidth = if narrow then math.floor(available * 0.27) else 88
	local confirmWidth = available - rotateWidth - cancelWidth
	rotateButton.Size = UDim2.fromOffset(rotateWidth, 44)
	rotateButton.Text = "ПОВОРОТ"
	confirmButton.Size = UDim2.fromOffset(confirmWidth, 44)
	confirmButton.TextSize = if tiny then 10 else (if narrow then 11 else 14)
	cancelButton.Size = UDim2.fromOffset(cancelWidth, 44)
	cancelButton.Text = "ОТМЕНА"
	-- Selected-building controls live inside one safe-area card, below the
	-- build launcher. Its width follows the viewport instead of overflowing it.
	local cardWidth = math.max(180, math.min(340, safeSize.X - 20))
	local cardTop = safeOrigin.Y + (recoveryPanel.Visible and 118 or 60)
	local cardHeight = 124
	selectionPanel.Position = UDim2.fromOffset(safeOrigin.X + 10, cardTop)
	selectionPanel.Size = UDim2.fromOffset(cardWidth, cardHeight)
	local cardContentWidth = math.max(0, cardWidth - 24)
	local cardGap = 6
	local showUpgrade = upgradeButton.Visible
	local showDemolish = demolishButton.Visible
	local actionCount = 1 + (if showUpgrade then 1 else 0) + (if showDemolish then 1 else 0)
	local actionWidth = math.max(0, (cardContentWidth - cardGap * (actionCount - 1)) / actionCount)
	local actionY = 70
	local actionHeight = 42
	local nextActionX = 0
	moveButton.Position = UDim2.fromOffset(nextActionX, actionY)
	moveButton.Size = UDim2.fromOffset(actionWidth, actionHeight)
	moveButton.TextSize = if compact then 10 else 11
	nextActionX += actionWidth + cardGap
	if showUpgrade then
		upgradeButton.Position = UDim2.fromOffset(nextActionX, actionY)
		upgradeButton.Size = UDim2.fromOffset(actionWidth, actionHeight)
		nextActionX += actionWidth + cardGap
	end
	if showDemolish then
		demolishButton.Position = UDim2.fromOffset(nextActionX, actionY)
		demolishButton.Size = UDim2.fromOffset(actionWidth, actionHeight)
	end
	demolishButton.Text = if compact then "УДАЛИТЬ" else "ДЕМОНТАЖ"
	demolishButton.TextSize = if compact then 10 else 11
	local buildLauncher = gui:FindFirstChild("OpenBuildButton")
	if buildLauncher and buildLauncher:IsA("TextButton") then
		local launcherWidth = if tiny then 112 else (if compact then 128 else 154)
		buildLauncher.Size = UDim2.fromOffset(launcherWidth, compact and 42 or 48)
		buildLauncher.Position = UDim2.fromOffset(
			safeOrigin.X + safeSize.X - launcherWidth - (if compact then 10 else 22),
			safeOrigin.Y + (if compact then 12 else 24)
		)
		buildLauncher.TextSize = if tiny then 11 else (if compact then 12 else 15)
		-- The full-width recovery notice owns the top safe area until the
		-- uncertain server operation has been resolved.
		buildLauncher.Visible = not recoveryPanel.Visible and not placing
	end
end

local buildingViewportConnection: RBXScriptConnection? = nil

local function bindBuildingCamera()
	if buildingViewportConnection then
		buildingViewportConnection:Disconnect()
		buildingViewportConnection = nil
	end
	local activeCamera = Workspace.CurrentCamera
	if activeCamera then
		buildingViewportConnection = activeCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeBuildingPanel)
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

local BUILDING_DISPLAY = {
	main_house = { title = "Главный дом", maxLevel = 3, costs = { [2] = "12 дерева • 6 камня", [3] = "24 дерева • 14 камня" } },
	pet_house = { title = "Домик питомцев", maxLevel = 3, costs = { [2] = "10 дерева • 5 камня", [3] = "20 дерева • 12 камня" } },
	stone_path = { title = "Каменная дорожка", maxLevel = 2, costs = { [2] = "3 камня" } },
	garden_lantern = { title = "Садовый фонарь", maxLevel = 2, costs = { [2] = "4 дерева • 2 камня" } },
	flower_bed = { title = "Клумба", maxLevel = 2, costs = { [2] = "3 дерева" } },
	wooden_fence = { title = "Деревянный забор", maxLevel = 2, costs = { [2] = "3 дерева" } },
}

local function updateBuildingContext(model: Model?)
	if model == nil or model.Parent == nil then
		selectionPanel.Visible = false
		upgradeButton.Visible = false
		return
	end
	local catalogId = model:GetAttribute("BuildingCatalogId")
	local info = if type(catalogId) == "string" then BUILDING_DISPLAY[catalogId] else nil
	local levelAttribute = model:GetAttribute("UpgradeLevel")
	local level = if type(levelAttribute) == "number" then math.max(1, math.floor(levelAttribute)) else 1
	local maxLevel = if info then info.maxLevel else 1
	selectionTitle.Text = if info then info.title else "Постройка"
	if level >= maxLevel then
		selectionDetails.Text = "Уровень " .. tostring(level) .. " / " .. tostring(maxLevel) .. " • Максимум"
		upgradeButton.Visible = false
	else
		local nextLevel = level + 1
		local cost = if info then info.costs[nextLevel] else nil
		selectionDetails.Text = "Уровень " .. tostring(level) .. " / " .. tostring(maxLevel)
			.. (if cost then " • Улучшение: " .. cost else " • Улучшение доступно")
		upgradeButton.Visible = true
	end
	upgradeButton.Active = upgradeButton.Visible and not upgradeRequestInFlight
	upgradeButton.Text = if upgradeRequestInFlight then "УЛУЧШАЕМ..." else "УЛУЧШИТЬ"
	selectionPanel.Visible = true
	resizeBuildingPanel()
end

local function selectBuilding(model: Model?)
	if demolitionRequestInFlight or upgradeRequestInFlight then return end
	if selectedBuildingDestroyConnection then
		selectedBuildingDestroyConnection:Disconnect()
		selectedBuildingDestroyConnection = nil
	end
	if selectedBuildingHighlight then
		selectedBuildingHighlight:Destroy()
		selectedBuildingHighlight = nil
	end
	selectedBuildingModel = model
	demolitionArmed = false
	selectionPanel.Visible = model ~= nil
	moveButton.Visible = model ~= nil
	moveButton.Active = model ~= nil
	local catalogId = if model then model:GetAttribute("BuildingCatalogId") else nil
	demolishButton.Visible = model ~= nil and catalogId ~= "main_house"
	demolishButton.Active = model ~= nil and catalogId ~= "main_house"
	demolishButton.Text = if compactBuildingUI
		then "УДАЛИТЬ"
		else "ДЕМОНТИРОВАТЬ"
	if model then
		updateBuildingContext(model)
		-- Make world selection visible; action buttons alone are too subtle,
		-- especially on mobile where the player taps a small building model.
		local highlight = Instance.new("Highlight")
		highlight.Name = "SelectedBuildingHighlight"
		highlight.Adornee = model
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = COLORS.gold
		highlight.FillTransparency = 0.88
		highlight.OutlineColor = COLORS.gold
		highlight.OutlineTransparency = 0.04
		highlight.Parent = model
		selectedBuildingHighlight = highlight
		setStatus("Выбрана постройка: " .. model.Name)
		selectedBuildingDestroyConnection = model.Destroying:Connect(function()
			if selectedBuildingModel == model and not demolitionRequestInFlight then
				selectBuilding(nil)
			end
		end)
	else
		selectionPanel.Visible = false
		upgradeButton.Visible = false
		setStatus("Постройка не выбрана")
	end
	resizeBuildingPanel()
end

upgradeButton.Activated:Connect(function()
	if upgradeRequestInFlight or buildRequestInFlight or demolitionRequestInFlight or placing then return end
	local model = selectedBuildingModel
	if model == nil or model.Parent == nil then
		selectBuilding(nil)
		return
	end
	local instanceId = model:GetAttribute("BuildingInstanceId")
	if type(instanceId) ~= "string" or instanceId == "" then
		setStatus("Не удалось определить постройку", false)
		return
	end
	local operationKey = "upgrade:" .. instanceId
	if pendingBuildingOperationKey ~= nil and pendingBuildingOperationKey ~= operationKey then
		setStatus("Сначала проверь результат предыдущей операции", false)
		return
	end
	upgradeRequestInFlight = true
	InterfaceComponents.SetButtonLoading(upgradeButton, true, "УЛУЧШАЕМ...")
	moveButton.Active = false
	demolishButton.Active = false
	setStatus("Улучшаем постройку…")
	local requestId = getPendingRequestId(operationKey)
	local requestPayload = { requestId = requestId, action = "upgrade", instanceId = instanceId }
	local requestResult = RequestRunner.Invoke(function()
		return remote:InvokeServer(requestPayload)
	end, 12)
	local ok, response = requestResult.ok, requestResult.value
	upgradeRequestInFlight = false
	InterfaceComponents.SetButtonLoading(upgradeButton, false)
	moveButton.Active = true
	demolishButton.Active = model:GetAttribute("BuildingCatalogId") ~= "main_house"
	if ok and not shouldKeepPendingRequest(response) then
		if pendingBuildingOperationKey == operationKey then clearPendingBuildingOperation() else clearPendingRequestId(operationKey) end
	elseif not ok or shouldKeepPendingRequest(response) then
		setPendingBuildingOperation(operationKey, requestId, requestPayload, "Улучшение постройки")
	end
	if not ok then
		setStatus("Нет ответа сервера. Повтори попытку для проверки результата", false)
		NotificationManager.Notify("Результат улучшения пока неизвестен", "warning")
		return
	end
	if type(response) == "table" and response.ok == true then
		model:SetAttribute("UpgradeLevel", response.upgradeLevel)
		updateBuildingContext(model)
		setStatus("Постройка улучшена до уровня " .. tostring(response.upgradeLevel), true)
		NotificationManager.Notify("Постройка улучшена!", "success")
	else
		local code = if type(response) == "table" then tostring(response.code) else "UNKNOWN"
		local messages = {
			NOT_ENOUGH_WOOD = "Не хватает дерева для улучшения",
			NOT_ENOUGH_STONE = "Не хватает камня для улучшения",
			MAX_UPGRADE_LEVEL = "У постройки уже максимальный уровень",
			UPGRADE_NOT_AVAILABLE = "Для этой постройки улучшение недоступно",
			BUILDING_NOT_FOUND = "Постройка уже отсутствует",
			SESSION_NOT_WRITABLE = "Сохранение временно недоступно",
			BUILDING_OPERATION_BUSY = "Сервер занят. Попробуй позже",
		}
		setStatus(messages[code] or ("Не удалось улучшить: " .. code), false)
		NotificationManager.Notify(messages[code] or "Не удалось улучшить постройку", "error")
	end
	updateBuildingContext(if selectedBuildingModel == model then model else nil)
end)

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
	local operationKey = "demolish:" .. instanceId
	if pendingBuildingOperationKey ~= nil and pendingBuildingOperationKey ~= operationKey then
		setStatus("Сначала проверь результат предыдущей операции", false)
		return
	end
	demolitionRequestInFlight = true
	InterfaceComponents.SetButtonLoading(demolishButton, true, "УДАЛЕНИЕ...")
	moveButton.Active = false
	setStatus("Удаляем постройку…")
	local requestId = getPendingRequestId(operationKey)
	local requestPayload = { requestId = requestId, action = "demolish", instanceId = instanceId }
	local requestResult = RequestRunner.Invoke(function()
		return remote:InvokeServer(requestPayload)
	end, 12)
	local ok, response = requestResult.ok, requestResult.value
	demolitionRequestInFlight = false
	InterfaceComponents.SetButtonLoading(demolishButton, false)
	moveButton.Active = true
	demolishButton.Text = "ДЕМОНТИРОВАТЬ"
	demolitionArmed = false
	if ok and not shouldKeepPendingRequest(response) then
		if pendingBuildingOperationKey == operationKey then clearPendingBuildingOperation() else clearPendingRequestId(operationKey) end
	elseif not ok or shouldKeepPendingRequest(response) then
		setPendingBuildingOperation(operationKey, requestId, requestPayload, "Демонтаж постройки")
	end
	if not ok then
		if requestResult.errorCode == "TIMEOUT" then
			setStatus("Ответ задерживается. Результат демонтажа пока неизвестен — повтори попытку для проверки", false)
			NotificationManager.Notify("Нет ответа вовремя. Повтори ту же операцию — повторного демонтажа не будет", "warning")
		else
			setStatus("Не удалось связаться с сервером. Повтори попытку", false)
			NotificationManager.Notify("Не удалось связаться с сервером", "error")
		end
		return
	end
	if type(response) == "table" and response.ok == true then
		selectBuilding(nil)
		setStatus("Постройка демонтирована", true)
		NotificationManager.Notify("Постройка демонтирована", "success")
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
		NotificationManager.Notify(messages[code] or "Не удалось демонтировать постройку", "error")
	end
end)

setStatus = function(message: string, good: boolean?)
	status.Text = message
	status.TextColor3 = if good == true then COLORS.valid elseif good == false then COLORS.invalid else COLORS.text
end

setPendingBuildingOperation = function(key: string, requestId: string, payload: { [string]: any }, description: string)
	pendingBuildingOperationKey = key
	pendingBuildingOperation = {
		key = key,
		requestId = requestId,
		payload = table.clone(payload),
		description = description,
	}
	recoveryDescription.Text = description .. " — результат пока неизвестен."
	recoveryPanel.Visible = true
	resizeBuildingPanel()
end

clearPendingBuildingOperation = function()
	if pendingBuildingOperation then
		clearPendingRequestId(pendingBuildingOperation.key)
	end
	pendingBuildingOperation = nil
	pendingBuildingOperationKey = nil
	recoveryPanel.Visible = false
	resizeBuildingPanel()
end

recoveryButton.Activated:Connect(function()
	local pending = pendingBuildingOperation
	if pending == nil or recoveryButton.Active == false then return end
	recoveryButton.Active = false
	recoveryButton.Text = "ПРОВЕРЯЕМ..."
	InterfaceComponents.SetButtonLoading(recoveryButton, true, "ПРОВЕРЯЕМ...")
	local requestResult = RequestRunner.Invoke(function()
		return remote:InvokeServer(pending.payload)
	end, 12)
	InterfaceComponents.SetButtonLoading(recoveryButton, false)
	recoveryButton.Active = true
	recoveryButton.Text = "ПРОВЕРИТЬ РЕЗУЛЬТАТ"
	if not requestResult.ok then
		recoveryDescription.Text = "Ответ не получен. Можно безопасно проверить ещё раз."
		NotificationManager.Notify("Результат операции пока не подтверждён", "warning")
		return
	end
	local response = requestResult.value
	if type(response) == "table" and response.ok == true then
		clearPendingBuildingOperation()
		setStatus(pending.description .. " — выполнено", true)
		NotificationManager.Notify(pending.description .. " выполнено", "success")
	elseif shouldKeepPendingRequest(response) then
		recoveryDescription.Text = "Сервер ещё обрабатывает операцию. Проверь немного позже."
		NotificationManager.Notify("Операция ещё не завершена", "warning")
	else
		local code = if type(response) == "table" then tostring(response.code) else "UNKNOWN"
		clearPendingBuildingOperation()
		setStatus("Операция не выполнена: " .. code, false)
		NotificationManager.Notify("Сервер подтвердил, что операция не выполнена", "error")
	end
end)

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
	local highlight = Instance.new("Highlight")
	highlight.Name = "PlacementHighlight"
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = COLORS.valid
	highlight.FillTransparency = 0.78
	highlight.OutlineColor = COLORS.valid
	highlight.OutlineTransparency = 0.04
	highlight.Parent = model
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
	local candidate = { x = x, z = z, width = footprintWidth, depth = footprintDepth }
	for _, child in ipairs(island:GetChildren()) do
		if child:IsA("Model")
			and (movingInstanceId == nil or child ~= selectedBuildingModel)
			and type(child:GetAttribute("BuildingInstanceId")) == "string"
		then
			local otherX = child:GetAttribute("GridX")
			local otherZ = child:GetAttribute("GridZ")
			local otherRotation = child:GetAttribute("GridRotation")
			local baseWidth = child:GetAttribute("FootprintWidth")
			local baseDepth = child:GetAttribute("FootprintDepth")
			if type(otherX) ~= "number" or type(otherZ) ~= "number"
				or type(otherRotation) ~= "number" or type(baseWidth) ~= "number" or type(baseDepth) ~= "number"
			then
				return true
			end
			local otherWidth, otherDepth = GridMath.getRotatedFootprint(baseWidth, baseDepth, otherRotation)
			if otherWidth == nil or otherDepth == nil then
				return true
			end
			local occupied = { x = otherX, z = otherZ, width = otherWidth, depth = otherDepth }
			if GridMath.footprintsOverlap(candidate, occupied) then
				return true
			end
		end
	end
	return false
end

local hideUnavailablePreview: () -> ()

-- Re-check the selected grid cell without using the screen pointer.
local function updatePreviewAtCell(x: number, z: number)
	if not placing or currentPreview == nil then return end
	local top, width, depth, cellSize = getIslandGrid()
	if top == nil or width == nil or depth == nil or cellSize == nil then
		hideUnavailablePreview()
		setStatus("Не удалось найти поверхность острова", false)
		return
	end
	local footprintWidth, footprintDepth = GridMath.getRotatedFootprint(BUILDING_WIDTH, BUILDING_DEPTH, rotation)
	if footprintWidth == nil or footprintDepth == nil then
		hideUnavailablePreview()
		setStatus("Поворот постройки недоступен", false)
		return
	end
	local inside = GridMath.isWithinBounds(
		{ x = x, z = z, width = footprintWidth, depth = footprintDepth },
		width,
		depth
	)
	local overlaps = inside and hasBuildingOverlap(x, z, footprintWidth, footprintDepth)
	local valid = inside and not overlaps
	currentCellX, currentCellZ = x, z
	currentValid = valid
	local centerX, centerZ = GridMath.getFootprintCenterOffset(
		{ x = x, z = z, width = footprintWidth, depth = footprintDepth },
		width,
		depth,
		cellSize
	)
	if centerX == nil or centerZ == nil then
		hideUnavailablePreview()
		setStatus("Не удалось рассчитать положение постройки", false)
		return
	end
	local previewHeight = if selectedCatalogId == "stone_path" then 0.35 elseif selectedCatalogId == "garden_lantern" then cellSize * 0.8 elseif selectedCatalogId == "flower_bed" then cellSize * 0.5 else cellSize * 0.7
	currentPreview.Size = Vector3.new(footprintWidth * cellSize, previewHeight, footprintDepth * cellSize)
	currentPreview.CFrame = top.CFrame * CFrame.new(centerX, top.Size.Y / 2 + previewHeight / 2, centerZ) * CFrame.Angles(0, math.rad(rotation), 0)
	if previewVisual then
		previewVisual:PivotTo(top.CFrame * CFrame.new(centerX, top.Size.Y / 2, centerZ) * CFrame.Angles(0, math.rad(rotation), 0))
		for _, descendant in ipairs(previewVisual:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant ~= previewVisual.PrimaryPart then
				descendant.Transparency = if valid then 0.18 else 0.52
			end
		end
		local highlight = previewVisual:FindFirstChild("PlacementHighlight")
		if highlight and highlight:IsA("Highlight") then
			highlight.Enabled = true
			highlight.FillColor = if valid then COLORS.valid else COLORS.invalid
			highlight.OutlineColor = if valid then COLORS.valid else COLORS.invalid
			highlight.FillTransparency = 0.78
			highlight.OutlineTransparency = 0.02
		end
	end
	currentPreview.Transparency = 0.65
	currentPreview.Color = if valid then COLORS.valid else COLORS.invalid
	local message = if not inside then "Объект выходит за границы острова" elseif overlaps then "Это место уже занято другим объектом" else "Место подходит — можно разместить"
	setStatus(message, valid)
end

-- Hide every placement indicator and invalidate its coordinates when
-- there is no selectable ground/cell. Never leave a stale ghost on screen.
hideUnavailablePreview = function()
	currentValid = false
	currentCellX, currentCellZ = nil, nil
	placementLocked = false
	if currentPreview then currentPreview.Transparency = 1 end
	if previewVisual then
		for _, descendant in ipairs(previewVisual:GetDescendants()) do
			if descendant:IsA("BasePart") then descendant.Transparency = 1 end
		end
		local highlight = previewVisual:FindFirstChild("PlacementHighlight")
		if highlight and highlight:IsA("Highlight") then highlight.Enabled = false end
	end
end

-- Show a tangible preview as soon as construction starts, even when the
-- cursor remains over the catalogue or the player is using touch.
-- This is a visual starting point only: the player still taps/clicks to lock it.
local function seedPreview()
	if not placing or currentPreview == nil then return end
	local _, width, depth = getIslandGrid()
	if width == nil or depth == nil then
		hideUnavailablePreview()
		setStatus("Не удалось найти сетку острова", false)
		return
	end
	local footprintWidth, footprintDepth = GridMath.getRotatedFootprint(BUILDING_WIDTH, BUILDING_DEPTH, rotation)
	if footprintWidth == nil or footprintDepth == nil then
		hideUnavailablePreview()
		setStatus("Поворот постройки недоступен", false)
		return
	end
	local centerX = math.floor((width - footprintWidth) / 2)
	local centerZ = math.floor((depth - footprintDepth) / 2)
	local bestX: number? = nil
	local bestZ: number? = nil
	local bestDistance = math.huge
	for x = 0, width - footprintWidth do
		for z = 0, depth - footprintDepth do
			if not hasBuildingOverlap(x, z, footprintWidth, footprintDepth) then
				local distance = (x - centerX) ^ 2 + (z - centerZ) ^ 2
				if distance < bestDistance then
					bestX, bestZ, bestDistance = x, z, distance
				end
			end
		end
	end
	if bestX ~= nil and bestZ ~= nil then
		updatePreviewAtCell(bestX, bestZ)
		placementLocked = false
	else
		hideUnavailablePreview()
		setStatus("На острове нет свободного места для этой постройки", false)
	end
end

local function updatePreview(screenPosition: Vector2)
	if not placing or currentPreview == nil then return end
	local top, _, _, cellSize = getIslandGrid()
	if top == nil or cellSize == nil then
		hideUnavailablePreview()
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
		hideUnavailablePreview()
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
	-- Keep the chosen cell when locked; otherwise show the newly selected
	-- building at a free starting position instead of an invisible preview.
	if placing and placementLocked and currentCellX ~= nil and currentCellZ ~= nil then
		updatePreviewAtCell(currentCellX, currentCellZ)
	elseif placing then
		seedPreview()
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
	local savedX = model:GetAttribute("GridX")
	local savedZ = model:GetAttribute("GridZ")
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
	panelCollapsed = false
	reopenConstructionButton.Visible = false
	panel.Visible = true
	if buildEntryButton then buildEntryButton.Visible = false end
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
		if buildEntryButton then buildEntryButton.Visible = not recoveryPanel.Visible end
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
	-- Start the move ghost exactly where the selected building currently
	-- stands. Starting from the island center can make the object appear to
	-- jump away before the player has chosen a destination.
	if type(savedX) == "number" and type(savedZ) == "number" then
		updatePreviewAtCell(math.floor(savedX), math.floor(savedZ))
		placementLocked = currentValid
	else
		placementLocked = false
		seedPreview()
	end
	setStatus(if currentValid
		then "Постройка на исходном месте — выбери новую точку или нажми «СОХРАНИТЬ»"
		else (if touchPlacement then "Перетащи постройку или коснись свободной травы" else "Выбери новое место на свободной траве"))
end

moveButton.Activated:Connect(beginMoveSelected)


local function stopPlacing()
	if buildRequestInFlight then
		setStatus("Дождись ответа о строительстве", false)
		return
	end
	placing = false
	panelCollapsed = false
	reopenConstructionButton.Visible = false
	movingInstanceId = nil
	panel.Visible = false
	if buildEntryButton then buildEntryButton.Visible = not recoveryPanel.Visible end
	if not overview.Visible then ModalManager.Close(script.Name) end
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
	panelCollapsed = false
	reopenConstructionButton.Visible = false
	panel.Visible = true
	if buildEntryButton then buildEntryButton.Visible = false end
	moveButton.Visible = false
	demolishButton.Visible = false
	createPreview()
	if currentPreview == nil then
		placing = false
		panel.Visible = false
		if buildEntryButton then buildEntryButton.Visible = not recoveryPanel.Visible end
		if selectedBuildingModel and selectedBuildingModel.Parent then
			moveButton.Visible = true
			demolishButton.Visible = selectedBuildingModel:GetAttribute("BuildingCatalogId") ~= "main_house"
		end
		return
	end
	placementLocked = false
	seedPreview()
	setStatus(if touchPlacement then "Перетащи модель или коснись травы • отпусти, чтобы выбрать место" else "Наведи на свободную траву • R — поворот • ПОСТРОИТЬ — подтвердить")
end

local function rotatePlacement()
	if not placing or buildRequestInFlight then return end
	rotation = (rotation + 90) % 360
	if currentCellX ~= nil and currentCellZ ~= nil then
		local wasLocked = placementLocked
		updatePreviewAtCell(currentCellX, currentCellZ)
		placementLocked = wasLocked and currentValid
	else
		-- Keep a visible ghost on touch devices even before the player locks
		-- a target cell. Rotation must be reflected immediately.
		seedPreview()
		placementLocked = false
	end
end

rotateButton.Activated:Connect(rotatePlacement)

cancelButton.Activated:Connect(stopPlacing)
collapseButton.Activated:Connect(function()
	if not placing or buildRequestInFlight then return end
	panelCollapsed = true
	panel.Visible = false
	reopenConstructionButton.Visible = true
end)

reopenConstructionButton.Activated:Connect(function()
	if not placing then
		reopenConstructionButton.Visible = false
		return
	end
	panelCollapsed = false
	panel.Visible = true
	reopenConstructionButton.Visible = false
end)

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
	InterfaceComponents.SetButtonLoading(confirmButton, true, "СОХРАНЕНИЕ...")
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
	if pendingBuildingOperationKey ~= nil and pendingBuildingOperationKey ~= operationKey then
		buildRequestInFlight = false
		InterfaceComponents.SetButtonLoading(confirmButton, false)
		rotateButton.Active = true
		cancelButton.Active = true
		setStatus("Сначала проверь результат предыдущей операции", false)
		return
	end
	local requestId = getPendingRequestId(operationKey)
	local requestPayload = {
		requestId = requestId,
		catalogId = requestedCatalogId,
		x = requestedX,
		z = requestedZ,
		rotation = requestedRotation,
		movingInstanceId = requestedMoveId,
	}
	local requestResult = RequestRunner.Invoke(function()
		return remote:InvokeServer(requestPayload)
	end, 12)
	local ok, response = requestResult.ok, requestResult.value
	buildRequestInFlight = false
	local shouldCloseAfterResponse = closeAfterBuildResponse
	closeAfterBuildResponse = false
	InterfaceComponents.SetButtonLoading(confirmButton, false)
	rotateButton.Active = true
	cancelButton.Active = true
	confirmButton.Text = if requestedMoveId ~= nil then "СОХРАНИТЬ" else "ПОСТРОИТЬ"
	if ok and not shouldKeepPendingRequest(response) then
		if pendingBuildingOperationKey == operationKey then clearPendingBuildingOperation() else clearPendingRequestId(operationKey) end
	elseif not ok or shouldKeepPendingRequest(response) then
		setPendingBuildingOperation(operationKey, requestId, requestPayload, if requestedMoveId ~= nil then "Перемещение постройки" else "Строительство")
	end
	if not ok then
		if requestResult.errorCode == "TIMEOUT" then
			setStatus("Ответ задерживается. Результат операции пока неизвестен — нажми повторить", false)
			NotificationManager.Notify("Нет ответа вовремя. Повтор той же операции защищён от дублирования", "warning")
		else
			setStatus("Не удалось связаться с сервером. Повтори попытку", false)
			NotificationManager.Notify("Не удалось связаться с сервером", "error")
		end
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
		NotificationManager.Notify(if wasMoving then "Объект перемещён!" else (successLabels[requestedCatalogId] or "Объект размещён!"), "success")
		if wasMoving then selectBuilding(nil) end
		stopPlacing()
	else
		local code = if type(response) == "table" then tostring(response.code) else "UNKNOWN"
		local messages = {
			INSUFFICIENT_RESOURCES = "Не хватает ресурсов: деревья дают +3 дерева, жилы — +2 камня",
			SESSION_NOT_READY = "Остров ещё загружается",
			SESSION_NOT_WRITABLE = "Сейчас нельзя сохранить изменения. Попробуй позже",
			BUILDING_LIMIT_REACHED = "На острове больше нельзя размещать постройки",
			FOOTPRINT_OVERLAP = "Это место уже занято",
			OUT_OF_BOUNDS = "Постройка выходит за границы острова",
		}
		setStatus(messages[code] or ("Сервер отклонил постройку: " .. code), false)
		NotificationManager.Notify(messages[code] or "Сервер отклонил постройку", "error")
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
local touchDraggingPlacement = false

local function isOverInteractiveGui(screenPosition: Vector2): boolean
	-- Any visible GUI surface owns its screen-space area, not only buttons.
	-- Ignoring plain Frames/TextLabels let clicks on empty panel padding or
	-- labels pass through and select the island cell underneath the UI.
	for _, object in ipairs(playerGui:GetGuiObjectsAtPosition(screenPosition.X, screenPosition.Y)) do
		if object:IsA("GuiObject") and object.Visible then
			return true
		end
	end
	return false
end

selectionCloseButton.Activated:Connect(function()
	selectBuilding(nil)
end)

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
		touchDraggingPlacement = false
		return
	end
	if processed or buildRequestInFlight or demolitionRequestInFlight then return end
	if input.KeyCode == Enum.KeyCode.R and placing then
		rotatePlacement()
	elseif input.KeyCode == Enum.KeyCode.Escape and ModalManager.IsActive(script.Name) then
		if overview.Visible then
			dismissKingdomOverview()
		elseif placing then
			stopPlacing()
		end
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
	local wasDraggingPlacement = touchDraggingPlacement
	if isCandidate then
		touchCandidate = nil
		touchStartPosition = nil
		touchDraggingPlacement = false
	end
	local blocked = gestureBlocked
	if touchCount == 0 then gestureBlocked = false end
	if not isCandidate or blocked or touchCount ~= 0 then return end
	if buildRequestInFlight or demolitionRequestInFlight or startPosition == nil or not sameMode then return end
	local endPosition = Vector2.new(input.Position.X, input.Position.Y)
	-- A deliberate drag moves the ghost continuously and locks the final
	-- valid cell on release. Short stationary touches remain simple tap-to-place.
	if wasDraggingPlacement then
		chooseWorldPoint(endPosition)
		return
	end
	if elapsed > MAX_TAP_DURATION then return end
	if (endPosition - startPosition).Magnitude > TAP_DRAG_THRESHOLD then return end
	chooseWorldPoint(endPosition)
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and not placementLocked then
		pointerPosition = UserInputService:GetMouseLocation()
	elseif input.UserInputType == Enum.UserInputType.Touch
		and input == touchCandidate and placing and touchStartedPlacing
		and touchStartPosition ~= nil and not buildRequestInFlight then
		local position = Vector2.new(input.Position.X, input.Position.Y)
		if not touchDraggingPlacement
			and (position - touchStartPosition).Magnitude > TAP_DRAG_THRESHOLD then
			touchDraggingPlacement = true
			placementLocked = false
		end
		if touchDraggingPlacement then
			pointerPosition = position
			updatePreview(position)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if placing and not buildRequestInFlight and not placementLocked and not touchPlacement
		and ModalManager.IsActive(script.Name) and not isOverInteractiveGui(pointerPosition) then
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
		Text = "СТРОИТЬ",
		TextColor3 = COLORS.gold,
		TextSize = 15,
	}, gui) :: TextButton
	InterfaceComponents.StyleActionButton(open, "gold")
	buildEntryButton = open
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
local overviewConstraint = make("UISizeConstraint", {
	MinSize = Vector2.new(220, 286),
	MaxSize = Vector2.new(420, 286),
}, overview) :: UISizeConstraint
local overviewScale = make("UIScale", { Scale = 1 }, overview) :: UIScale
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
	Text = InterfaceTheme.Icons.Close,
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
	Text = InterfaceTheme.Icons.Build .. "  Тихий остров",
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

local function resizeKingdomOverview()
	local camera = Workspace.CurrentCamera
	if camera == nil then return end
	local viewport = camera.ViewportSize
	local compact = viewport.X < 520
	local width = math.max(220, math.min(viewport.X - 24, 420))
	overview.Size = UDim2.fromOffset(width, 286)
	overviewConstraint.MinSize = Vector2.new(math.min(220, width), 286)
	overviewConstraint.MaxSize = Vector2.new(width, 286)
	-- Keep the complete overview and its close/action buttons visible in short landscape viewports.
	overviewScale.Scale = math.clamp((viewport.Y - 32) / 286, 0.68, 1)
	overviewTitle.TextSize = if compact then 15 else 18
	overviewStage.TextSize = if compact then 16 else 20
	overviewStats.TextSize = if compact then 11 else 13
	overviewHint.TextSize = if compact then 10 else 11
	overviewBuild.TextSize = if compact then 12 else 14
end

local overviewCameraConnection: RBXScriptConnection? = nil
local function bindOverviewCamera()
	if overviewCameraConnection then
		overviewCameraConnection:Disconnect()
		overviewCameraConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		overviewCameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeKingdomOverview)
	end
	resizeKingdomOverview()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindOverviewCamera)
bindOverviewCamera()

local function closeKingdomOverview()
	overview.Visible = false
	overviewShade.Visible = false
	if not placing then ModalManager.Close(script.Name) end
end
dismissKingdomOverview = closeKingdomOverview

local function refreshKingdomOverview()
	local island = findOwnIsland()
	if island == nil then
		overviewStage.Text = InterfaceTheme.Icons.Build .. "  Остров загружается"
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

	overviewStage.Text = InterfaceTheme.Icons.Build .. "  " .. stageName
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
	resizeKingdomOverview()
	overviewShade.Visible = true
	overview.Visible = true
end

ModalManager.Register(script.Name, function(_reason: string)
	closeKingdomOverview()
	if not demolitionRequestInFlight then selectBuilding(nil) end
	if buildRequestInFlight then
		-- Another modal takes focus immediately; do not cancel an in-flight transaction.
		panel.Visible = false
		closeAfterBuildResponse = true
	else
		stopPlacing()
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
ModalManager.ActiveChanged:Connect(function(activeName: string?)
	if buildEntryButton then
		buildEntryButton.Visible = activeName == nil and not placing and not overview.Visible and not recoveryPanel.Visible
	end
end)
if buildEntryButton then
	buildEntryButton.Visible = ModalManager.GetActive() == nil and not placing and not overview.Visible and not recoveryPanel.Visible
end
resizeBuildingPanel()
print("[PetKingdoms] Building controller loaded.")
