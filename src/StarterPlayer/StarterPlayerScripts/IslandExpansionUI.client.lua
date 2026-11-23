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
	Text = "🏝️",
	TextSize = 28,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, screen) :: TextButton
make("UICorner", { CornerRadius = UDim.new(1, 0) }, openButton)
make("UIStroke", { Color = COLORS.gold, Thickness = 2, Transparency = 0.12 }, openButton)

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
	Font = Enum.Font.GothamBold,
	Text = "РАСШИРЕНИЕ ОСТРОВА",
	TextSize = 19,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, panel) :: TextLabel

local closeButton = make("TextButton", {
	Position = UDim2.new(1, -52, 0, 14),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = COLORS.panelSoft,
	Text = "×",
	TextSize = 24,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
}, panel) :: TextButton
InterfaceComponents.StyleCloseButton(closeButton)

local subtitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 24, 0, 57),
	Size = UDim2.new(1, -48, 0, 34),
	Font = Enum.Font.Gotham,
	Text = "Увеличивай королевство и открывай место для новых построек.",
	TextSize = 12,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.muted,
}, panel) :: TextLabel

local currentCard = make("Frame", {
	Position = UDim2.new(0, 22, 0, 108),
	Size = UDim2.new(1, -44, 0, 82),
	BackgroundColor3 = COLORS.panelSoft,
}, panel) :: Frame
make("UICorner", { CornerRadius = UDim.new(0, 15) }, currentCard)

local currentTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 12),
	Size = UDim2.new(1, -30, 0, 22),
	Font = Enum.Font.GothamBold,
	Text = "ТВОЙ ОСТРОВ",
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.gold,
}, currentCard) :: TextLabel

local currentValue = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 36),
	Size = UDim2.new(1, -30, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Загрузка...",
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, currentCard) :: TextLabel

local nextCard = make("Frame", {
	Position = UDim2.new(0, 22, 0, 202),
	Size = UDim2.new(1, -44, 0, 82),
	BackgroundColor3 = COLORS.card,
}, panel) :: Frame
make("UICorner", { CornerRadius = UDim.new(0, 15) }, nextCard)

local nextTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 12),
	Size = UDim2.new(1, -30, 0, 22),
	Font = Enum.Font.GothamBold,
	Text = "СЛЕДУЮЩИЙ УРОВЕНЬ",
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.mint,
}, nextCard) :: TextLabel

local nextValue = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 36),
	Size = UDim2.new(1, -30, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Проверяем...",
	TextSize = 20,
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
	Size = UDim2.new(1, -44, 0, 38),
	BackgroundColor3 = COLORS.card,
	Text = "ОБНОВИТЬ ДАННЫЕ",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
}, panel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 12) }, refreshButton)

local opened = false
local loading = false
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
	if type(data.nextWidth) ~= "number" or type(data.nextDepth) ~= "number" then return end

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

	lastPreview = data
	currentValue.Text = string.format("Уровень %d  •  %d × %d", data.currentLevel, data.currentWidth, data.currentDepth)
	showWorldPreview(data)
	if data.canExpand and type(data.nextLevel) == "number" then
		nextValue.Text = string.format("Уровень %d  •  %d × %d", data.nextLevel, data.nextWidth, data.nextDepth)
		status.Text = "Новые земли доступны по геометрии, но покупка пока отключена."
		status.TextColor3 = COLORS.gold
	else
		nextValue.Text = "Максимальный размер"
		status.Text = string.format("Достигнут максимальный уровень: %d.", data.maxLevel)
		status.TextColor3 = COLORS.mint
	end
end

local function refresh()
	if loading then return end
	loading = true
	refreshButton.Text = "ЗАГРУЗКА..."
	status.TextColor3 = COLORS.muted
	status.Text = "Получаем актуальные данные с сервера..."
	local ok, result = pcall(function()
		return remote:InvokeServer()
	end)
	if ok then
		renderPreview(result)
	else
		status.TextColor3 = COLORS.rose
		status.Text = "Связь с сервером не удалась. Попробуй ещё раз."
	end
	loading = false
	refreshButton.Text = "ОБНОВИТЬ ДАННЫЕ"
end

local function setOpen(value: boolean)
	if value then announcePanelOpened() end
	opened = value
	if not value then ModalManager.Close(script.Name) end
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
	if processed or input.KeyCode ~= Enum.KeyCode.Escape or not opened then return end
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
	openButton.Size = UDim2.fromOffset(compact and 52 or 62, compact and 52 or 62)
	openButton.Position = UDim2.new(1, compact and -12 or -22, 0.70, 0)
	panel.Size = UDim2.new(compact and 0.94 or 0.9, 0, 0, 390)
	-- Scale the fixed-height information cards on short screens instead of clipping them.
	panelScale.Scale = math.clamp((viewport.Y - 24) / 390, 0.72, 1)
end
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(resize)
resize()

print("[PetKingdoms] Island expansion preview UI loaded.")
