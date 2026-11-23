--!strict
-- Read-only island expansion panel. The server owns all profile and unlock data.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ModalManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModalManager"))
local function announcePanelOpened()
	ModalManager.Open(script.Name)
end

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetIslandExpansionPreview") :: RemoteFunction

local InterfaceTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceTheme"))
local InterfaceComponents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceComponents"))
local RequestRunner = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RequestRunner"))
local COLORS = InterfaceTheme.Colors

local function make(className: string, props: { [string]: any }, parent: Instance): Instance
	local object = Instance.new(className)
	for key, value in pairs(props) do (object :: any)[key] = value end
	object.Parent = parent
	return object
end

local screen = make("ScreenGui", {
	Name = "IslandExpansionGui",
	ResetOnSpawn = false,
	DisplayOrder = 18,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui) :: ScreenGui

local openButton = make("TextButton", {
	Name = "OpenExpansion",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -22, 0.70, 0),
	Size = UDim2.fromOffset(62, 62),
	BackgroundColor3 = COLORS.panel,
	Text = InterfaceTheme.Icons.Island,
	TextSize = 28,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, screen) :: TextButton
InterfaceComponents.StyleFloatingButton(openButton, "gold")

local shade = make("TextButton", {
	Name = "Shade",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
}, screen) :: TextButton

local panel = make("Frame", {
	Name = "ExpansionPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.new(0.9, 0, 0, 390),
	BackgroundColor3 = COLORS.panel,
	Visible = false,
}, shade) :: Frame
local panelConstraint = make("UISizeConstraint", { MinSize = Vector2.new(250, 320), MaxSize = Vector2.new(440, 390) }, panel) :: UISizeConstraint
local panelScale = make("UIScale", { Scale = 1 }, panel) :: UIScale
make("UICorner", { CornerRadius = UDim.new(0, 22) }, panel)
make("UIStroke", { Color = COLORS.gold, Thickness = 1.4, Transparency = 0.35 }, panel)

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 22, 0, 18),
	Size = UDim2.new(1, -76, 0, 32),
	Text = "РАСШИРЕНИЕ ОСТРОВА",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, panel) :: TextLabel
InterfaceComponents.StyleText(title, "Display")

local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 14),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = COLORS.panelSoft,
	Text = InterfaceTheme.Icons.Close,
	TextSize = 24,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
}, panel) :: TextButton
InterfaceComponents.StyleCloseButton(closeButton)

local subtitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 24, 0, 57),
	Size = UDim2.new(1, -48, 0, 34),
	Text = "Увеличивай королевство и открывай место для новых построек.",
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.muted,
}, panel) :: TextLabel
InterfaceComponents.StyleText(subtitle, "Caption")

local currentCard = make("Frame", {
	Position = UDim2.new(0, 22, 0, 108),
	Size = UDim2.new(1, -44, 0, 82),
	BackgroundColor3 = COLORS.panelSoft,
}, panel) :: Frame
InterfaceComponents.StyleCard(currentCard, "surface")

local currentTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 12),
	Size = UDim2.new(1, -30, 0, 22),
	Text = "ТВОЙ ОСТРОВ",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.gold,
}, currentCard) :: TextLabel
InterfaceComponents.StyleText(currentTitle, "Micro")

local currentValue = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 36),
	Size = UDim2.new(1, -30, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Загрузка...",
	TextSize = 20,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, currentCard) :: TextLabel

local nextCard = make("Frame", {
	Position = UDim2.new(0, 22, 0, 202),
	Size = UDim2.new(1, -44, 0, 82),
	BackgroundColor3 = COLORS.card,
}, panel) :: Frame
InterfaceComponents.StyleCard(nextCard, "highlight")

local nextTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 12),
	Size = UDim2.new(1, -30, 0, 22),
	Text = "СЛЕДУЮЩИЙ УРОВЕНЬ",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.mint,
}, nextCard) :: TextLabel
InterfaceComponents.StyleText(nextTitle, "Micro")

local nextValue = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 36),
	Size = UDim2.new(1, -30, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Проверяем...",
	TextSize = 20,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, nextCard) :: TextLabel

local status = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 24, 0, 296),
	Size = UDim2.new(1, -48, 0, 38),
	Font = Enum.Font.GothamMedium,
	Text = "Получаем данные острова...",
	TextSize = 12,
	TextWrapped = true,
	TextColor3 = COLORS.muted,
}, panel) :: TextLabel

local refreshButton = make("TextButton", {
	Position = UDim2.new(0, 22, 1, -52),
	Size = UDim2.new(1, -44, 0, 44),
	BackgroundColor3 = COLORS.card,
	Text = "ОБНОВИТЬ ДАННЫЕ",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
}, panel) :: TextButton
InterfaceComponents.StyleActionButton(refreshButton, "secondary")

local opened = false
local loading = false
local requestGeneration = 0
local lastPreview: any = nil
local previewFolder: Folder? = nil

local function clearWorldPreview()
	if previewFolder then
		previewFolder:Destroy()
		previewFolder = nil
	end
end

local function showWorldPreview(data: any)
	clearWorldPreview()
	if not opened or type(data) ~= "table" or data.ok ~= true or data.canExpand ~= true then return end
	local islands = Workspace:FindFirstChild("PlayerIslands")
	if islands == nil then return end
	local world = islands:FindFirstChild("Island_" .. tostring(player.UserId))
	if not world or not world:IsA("Model") or world:GetAttribute("OwnerUserId") ~= player.UserId then return end
	local grass = world:FindFirstChild("Island_GrassTop")
	if not grass or not grass:IsA("BasePart") then return end
	if type(data.nextWidth) ~= "number" or type(data.nextDepth) ~= "number"
		or type(data.currentWidth) ~= "number" or type(data.currentDepth) ~= "number"
		or data.currentWidth <= 0 or data.currentDepth <= 0
		or data.nextWidth <= data.currentWidth or data.nextDepth <= data.currentDepth
	then return end

	local currentWidth = grass.Size.X
	local currentDepth = grass.Size.Z
	local nextWidth = data.nextWidth * (currentWidth / data.currentWidth)
	local nextDepth = data.nextDepth * (currentDepth / data.currentDepth)
	local addedX = (nextWidth - currentWidth) / 2
	local addedZ = (nextDepth - currentDepth) / 2
	if addedX <= 0 or addedZ <= 0 then return end

	local folder = Instance.new("Folder")
	folder.Name = "LocalIslandExpansionPreview"
	folder.Parent = Workspace
	previewFolder = folder

	local yOffset = grass.Size.Y / 2 + 0.16
	local function makeStrip(name: string, size: Vector3, offset: CFrame)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(115, 230, 171)
		part.Transparency = 0.58
		part.Size = size
		part.CFrame = grass.CFrame * offset
		part.Parent = folder
		local selection = Instance.new("SelectionBox")
		selection.Adornee = part
		selection.Color3 = Color3.fromRGB(177, 255, 208)
		selection.LineThickness = 0.035
		selection.SurfaceTransparency = 1
		selection.Parent = part
	end

	makeStrip("Preview_North", Vector3.new(nextWidth, 0.12, addedZ), CFrame.new(0, yOffset, -(currentDepth / 2 + addedZ / 2)))
	makeStrip("Preview_South", Vector3.new(nextWidth, 0.12, addedZ), CFrame.new(0, yOffset, currentDepth / 2 + addedZ / 2))
	makeStrip("Preview_West", Vector3.new(addedX, 0.12, currentDepth), CFrame.new(-(currentWidth / 2 + addedX / 2), yOffset, 0))
	makeStrip("Preview_East", Vector3.new(addedX, 0.12, currentDepth), CFrame.new(currentWidth / 2 + addedX / 2, yOffset, 0))
end

local function renderPreview(data: any)
	if type(data) ~= "table" or data.ok ~= true then
		local code = if type(data) == "table" and type(data.code) == "string" then data.code else "UNKNOWN"
		status.TextColor3 = COLORS.rose
		status.Text = if code == "SESSION_NOT_READY" then "Остров ещё загружается. Попробуй немного позже."
			elseif code == "RATE_LIMITED" then "Слишком частые запросы. Подожди секунду."
			else "Не удалось получить данные: " .. code
		return
	end

	if type(data.currentLevel) ~= "number" or type(data.currentWidth) ~= "number"
		or type(data.currentDepth) ~= "number" or type(data.maxLevel) ~= "number"
	then
		status.Text = "Сервер вернул неполные данные острова. Попробуй обновить."
		status.TextColor3 = COLORS.rose
		return
	end
	lastPreview = data
	currentValue.Text = string.format("Уровень %d  •  %d × %d", data.currentLevel, data.currentWidth, data.currentDepth)
	showWorldPreview(data)
	if data.canExpand and type(data.nextLevel) == "number" then
		nextValue.Text = string.format("Уровень %d  •  %d × %d", data.nextLevel, data.nextWidth, data.nextDepth)
		status.Text = "Предпросмотр новых земель. Покупка расширения пока не реализована."
		status.TextColor3 = COLORS.gold
	else
		nextValue.Text = "Максимальный размер"
		status.Text = string.format("Достигнут максимальный уровень: %d.", data.maxLevel)
		status.TextColor3 = COLORS.mint
	end
end

local function refresh()
	if loading or not opened then return end
	loading = true
	requestGeneration += 1
	local generation = requestGeneration
	InterfaceComponents.SetButtonLoading(refreshButton, true, "ЗАГРУЗКА...")
	status.TextColor3 = COLORS.muted
	status.Text = "Получаем актуальные данные с сервера..."
	local requestResult = RequestRunner.Invoke(function()
		return remote:InvokeServer()
	end, 12)
	-- Ignore responses from a previous open/close cycle.
	if generation ~= requestGeneration or not opened then return end
	if requestResult.ok then
		renderPreview(requestResult.value)
	else
		status.TextColor3 = COLORS.rose
		if requestResult.errorCode == "TIMEOUT" then
			status.Text = "Сервер отвечает слишком долго. Попробуй обновить ещё раз."
		else
			status.Text = "Связь с сервером не удалась. Попробуй ещё раз."
		end
	end
	loading = false
	InterfaceComponents.SetButtonLoading(refreshButton, false)
	if status.TextColor3 == COLORS.rose then
		InterfaceComponents.SetButtonFeedback(refreshButton, "error", "ОШИБКА", 2)
	elseif status.TextColor3 == COLORS.gold then
		InterfaceComponents.SetButtonFeedback(refreshButton, "warning", "ИНФО", 1.8)
	else
		InterfaceComponents.SetButtonFeedback(refreshButton, "success", "ГОТОВО", 1.5)
	end
end

local function setOpen(value: boolean)
	if value then announcePanelOpened() end
	opened = value
	if not value then
		requestGeneration += 1
		loading = false
		InterfaceComponents.SetButtonLoading(refreshButton, false)
		ModalManager.Close(script.Name)
	end end
	panel.Visible = value
	shade.Visible = value
	if value then
		shade.BackgroundTransparency = 1
		TweenService:Create(shade, TweenInfo.new(0.16), { BackgroundTransparency = 0.42 }):Play()
		refresh()
	else
		clearWorldPreview()
		TweenService:Create(shade, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
		task.delay(0.13, function()
			if not opened then shade.Visible = false end
		end)
	end
end

ModalManager.Register(script.Name, function(_reason: string)
	if opened then setOpen(false) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.Escape or not opened or not ModalManager.IsActive(script.Name) then return end
	setOpen(false)
end)

shade.Activated:Connect(function()
	if opened then setOpen(false) end
end)

openButton.Activated:Connect(function() setOpen(not opened) end)
closeButton.Activated:Connect(function() setOpen(false) end)
refreshButton.Activated:Connect(refresh)

local function resize()
	local camera = Workspace.CurrentCamera
	if camera == nil then return end
	local viewport = camera.ViewportSize
	local compact = viewport.X < 520
	local narrow = viewport.X < 360
	local short = viewport.Y < 500
	local veryShort = viewport.Y < 360
	local launcherSize = if veryShort then 44 elseif compact then 52 else 62
	openButton.Size = UDim2.fromOffset(launcherSize, launcherSize)
	-- Keep the three right-side launchers separated on short landscape screens.
	openButton.Position = UDim2.new(1, compact and -12 or -22, if veryShort then 0.82 elseif compact then 0.72 else 0.70, 0)
	if veryShort then
		-- A dedicated landscape layout keeps the preview readable instead of
		-- shrinking the entire 390 px desktop panel into a tiny card.
		local panelWidth = math.max(210, math.min(viewport.X - 16, 440))
		local panelHeight = math.max(144, viewport.Y - 12)
		panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
		panel.Position = UDim2.fromScale(0.5, 0.5)
		panelConstraint.MinSize = Vector2.new(panelWidth, panelHeight)
		panelConstraint.MaxSize = Vector2.new(panelWidth, panelHeight)
		panelScale.Scale = 1

		title.Position = UDim2.fromOffset(12, 7)
		title.Size = UDim2.new(1, -54, 0, 22)
		title.TextSize = 14
		closeButton.Position = UDim2.new(1, -10, 0, 5)
		closeButton.Size = UDim2.fromOffset(30, 30)
		closeButton.TextSize = 19
		subtitle.Position = UDim2.fromOffset(12, 30)
		subtitle.Size = UDim2.new(1, -24, 0, 18)
		subtitle.TextSize = 9
		subtitle.TextWrapped = false
		subtitle.TextTruncate = Enum.TextTruncate.AtEnd

		local cardGap = 8
		local cardWidth = math.floor((panelWidth - 32 - cardGap) / 2)
		currentCard.Position = UDim2.fromOffset(12, 53)
		currentCard.Size = UDim2.fromOffset(cardWidth, 44)
		nextCard.Position = UDim2.fromOffset(12 + cardWidth + cardGap, 53)
		nextCard.Size = UDim2.fromOffset(cardWidth, 44)
		for _, entry in ipairs({
			{ title = currentTitle, value = currentValue },
			{ title = nextTitle, value = nextValue },
		}) do
			entry.title.Position = UDim2.fromOffset(8, 4)
			entry.title.Size = UDim2.new(1, -16, 0, 13)
			entry.title.TextSize = 8
			entry.value.Position = UDim2.fromOffset(8, 19)
			entry.value.Size = UDim2.new(1, -16, 0, 18)
			entry.value.TextSize = 11
		end

		status.Position = UDim2.fromOffset(12, 102)
		status.Size = UDim2.new(1, -24, 0, 24)
		status.TextSize = 9
		status.TextWrapped = false
		status.TextTruncate = Enum.TextTruncate.AtEnd
		refreshButton.Position = UDim2.new(0, 12, 1, -36)
		refreshButton.Size = UDim2.new(1, -24, 0, 28)
		refreshButton.Text = "ОБНОВИТЬ"
		refreshButton.TextSize = 10
	else
		panel.Size = UDim2.new(compact and 0.94 or 0.9, 0, 0, 390)
		panelConstraint.MinSize = Vector2.new(math.min(250, math.max(210, viewport.X - 20)), 280)
		panelConstraint.MaxSize = Vector2.new(math.min(440, math.max(210, viewport.X - 12)), 390)
		panelScale.Scale = math.clamp((viewport.Y - 24) / 390, short and 0.72 or 0.82, 1)
		panel.Position = UDim2.fromScale(0.5, 0.52)

		title.Position = UDim2.new(0, 22, 0, 18)
		title.Size = UDim2.new(1, -76, 0, 32)
		title.TextSize = if compact then 15 else 18
		closeButton.Position = UDim2.new(1, -16, 0, 14)
		closeButton.Size = UDim2.fromOffset(40, 40)
		closeButton.TextSize = 24
		subtitle.Position = UDim2.new(0, 24, 0, 57)
		subtitle.Size = UDim2.new(1, -48, 0, if narrow then 42 else 34)
		subtitle.TextSize = if narrow then 10 else 11
		subtitle.TextWrapped = true
		subtitle.TextTruncate = Enum.TextTruncate.None
		currentCard.Position = UDim2.new(0, 22, 0, 108)
		currentCard.Size = UDim2.new(1, -44, 0, 82)
		nextCard.Position = UDim2.new(0, 22, 0, 202)
		nextCard.Size = UDim2.new(1, -44, 0, 82)
		for _, entry in ipairs({
			{ title = currentTitle, value = currentValue },
			{ title = nextTitle, value = nextValue },
		}) do
			entry.title.Position = UDim2.new(0, 15, 0, 12)
			entry.title.Size = UDim2.new(1, -30, 0, 22)
			entry.title.TextSize = 12
			entry.value.Position = UDim2.new(0, 15, 0, 36)
			entry.value.Size = UDim2.new(1, -30, 0, 28)
			entry.value.TextSize = if compact then 16 else 20
		end
		status.Position = UDim2.new(0, 24, 0, 296)
		status.Size = UDim2.new(1, -48, 0, 38)
		status.TextSize = if compact then 11 else 12
		status.TextWrapped = true
		status.TextTruncate = Enum.TextTruncate.None
		refreshButton.Position = UDim2.new(0, 22, 1, -52)
		refreshButton.Size = UDim2.new(1, -44, 0, 44)
		refreshButton.Text = "ОБНОВИТЬ ДАННЫЕ"
		refreshButton.TextSize = if compact then 11 else 12
	end
end

local viewportConnection: RBXScriptConnection? = nil
local function bindViewportCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	end
	resize()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportCamera)
bindViewportCamera()

print("[PetKingdoms] Island expansion preview UI loaded.")
