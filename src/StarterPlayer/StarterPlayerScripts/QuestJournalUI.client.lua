--!strict
-- Responsive quest journal. All progress is read from the server; this UI
-- never submits quest progress or reward claims.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("GetQuestProgress") :: RemoteFunction
local resourceUpdate = remotes:WaitForChild("IslandResourceUpdate") :: RemoteEvent

local COLORS = {
	panel = Color3.fromRGB(31, 35, 48),
	panelSoft = Color3.fromRGB(43, 48, 64),
	card = Color3.fromRGB(53, 59, 78),
	cream = Color3.fromRGB(255, 245, 222),
	muted = Color3.fromRGB(177, 185, 205),
	gold = Color3.fromRGB(255, 205, 112),
	mint = Color3.fromRGB(135, 225, 183),
	rose = Color3.fromRGB(244, 151, 169),
	track = Color3.fromRGB(76, 84, 105),
}

local function make(className: string, props: { [string]: any }, parent: Instance): Instance
	local object = Instance.new(className)
	for key, value in pairs(props) do (object :: any)[key] = value end
	object.Parent = parent
	return object
end

local screen = make("ScreenGui", {
	Name = "QuestJournalGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	DisplayOrder = 22,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui) :: ScreenGui

local openButton = make("TextButton", {
	Name = "OpenQuestJournal",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 20, 0.56, 0),
	Size = UDim2.fromOffset(58, 58),
	BackgroundColor3 = COLORS.panel,
	Text = "📜",
	TextSize = 27,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, screen) :: TextButton
make("UICorner", { CornerRadius = UDim.new(1, 0) }, openButton)
make("UIStroke", { Color = COLORS.gold, Thickness = 2, Transparency = 0.12 }, openButton)

local badge = make("TextLabel", {
	Name = "QuestCount",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 3, 0, -3),
	Size = UDim2.fromOffset(21, 21),
	BackgroundColor3 = COLORS.mint,
	Text = "!",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.panel,
}, openButton) :: TextLabel
make("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)

local shade = make("Frame", {
	Name = "Shade",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Visible = false,
}, screen) :: Frame

local panel = make("Frame", {
	Name = "QuestPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.new(0.9, 0, 0, 410),
	BackgroundColor3 = COLORS.panel,
	Visible = false,
}, shade) :: Frame
make("UISizeConstraint", { MinSize = Vector2.new(290, 340), MaxSize = Vector2.new(500, 440) }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 22) }, panel)
make("UIStroke", { Color = COLORS.gold, Thickness = 1.4, Transparency = 0.35 }, panel)

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 22, 0, 17),
	Size = UDim2.new(1, -78, 0, 31),
	Font = Enum.Font.GothamBold,
	Text = "ЖУРНАЛ ПРИКЛЮЧЕНИЙ",
	TextSize = 19,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, panel) :: TextLabel

local subtitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 24, 0, 51),
	Size = UDim2.new(1, -48, 0, 25),
	Font = Enum.Font.Gotham,
	Text = "Небольшие дела — большие открытия",
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.muted,
}, panel) :: TextLabel

local closeButton = make("TextButton", {
	Position = UDim2.new(1, -54, 0, 14),
	Size = UDim2.fromOffset(38, 38),
	BackgroundColor3 = COLORS.panelSoft,
	Text = "×",
	TextSize = 26,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
}, panel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 11) }, closeButton)

local list = make("ScrollingFrame", {
	Name = "QuestList",
	Position = UDim2.new(0, 20, 0, 88),
	Size = UDim2.new(1, -40, 1, -145),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = COLORS.gold,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel) :: ScrollingFrame
make("UIListLayout", { Padding = UDim.new(0, 11), SortOrder = Enum.SortOrder.LayoutOrder }, list)

local status = make("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.new(1, -44, 0, 32),
	Font = Enum.Font.Gotham,
	Text = "Загружаем задания...",
	TextSize = 11,
	TextWrapped = true,
	TextColor3 = COLORS.muted,
}, panel) :: TextLabel

local opened = false
local loading = false
local refreshQueued = false
local lastQuests: { any } = {}

local function clearCards()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function render(quests: any)
	if type(quests) ~= "table" then
		status.Text = "Не удалось прочитать задания."
		status.TextColor3 = COLORS.rose
		return
	end
	lastQuests = quests
	clearCards()
	local completedCount = 0
	for index, quest in ipairs(quests) do
		if type(quest) ~= "table" or type(quest.id) ~= "string"
			or type(quest.name) ~= "string" or type(quest.description) ~= "string"
			or type(quest.count) ~= "number" or type(quest.target) ~= "number"
		then
			continue
		end
		local done = quest.completed == true
		if done then completedCount += 1 end
		local card = make("Frame", {
			Name = "Quest_" .. quest.id,
			Size = UDim2.new(1, -6, 0, 112),
			BackgroundColor3 = COLORS.panelSoft,
			LayoutOrder = index,
		}, list) :: Frame
		make("UICorner", { CornerRadius = UDim.new(0, 15) }, card)
		make("UIStroke", { Color = if done then COLORS.mint else COLORS.track, Transparency = 0.58, Thickness = 1 }, card)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0, 11),
			Size = UDim2.new(1, -30, 0, 23),
			Font = Enum.Font.GothamBold,
			Text = (if done then "✓  " else "✦  ") .. quest.name,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if done then COLORS.mint else COLORS.cream,
		}, card)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 37),
			Size = UDim2.new(1, -32, 0, 21),
			Font = Enum.Font.Gotham,
			Text = quest.description,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = COLORS.muted,
		}, card)
		local count = math.clamp(quest.count, 0, quest.target)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 65),
			Size = UDim2.new(0.5, 0, 0, 18),
			Font = Enum.Font.GothamBold,
			Text = if done then "ВЫПОЛНЕНО" else "ПРОГРЕСС",
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if done then COLORS.mint else COLORS.gold,
		}, card)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -76, 0, 64),
			Size = UDim2.fromOffset(60, 19),
			Font = Enum.Font.GothamBold,
			Text = string.format("%d / %d", count, quest.target),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = COLORS.cream,
		}, card)
		local track = make("Frame", {
			Position = UDim2.new(0, 16, 1, -17),
			Size = UDim2.new(1, -32, 0, 6),
			BackgroundColor3 = COLORS.track,
		}, card) :: Frame
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
		local fill = make("Frame", {
			Size = UDim2.new(count / math.max(quest.target, 1), 0, 1, 0),
			BackgroundColor3 = if done then COLORS.mint else COLORS.gold,
		}, track) :: Frame
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	end
	badge.Text = if #quests == 0 then "—" else tostring(math.max(0, #quests - completedCount))
	badge.BackgroundColor3 = if completedCount == #quests and #quests > 0 then COLORS.mint else COLORS.gold
	status.Text = string.format("Выполнено: %d из %d  •  Награды появятся в следующем этапе", completedCount, #quests)
	status.TextColor3 = COLORS.muted
end

local function refresh()
	if loading then return end
	loading = true
	status.Text = "Получаем прогресс с сервера..."
	status.TextColor3 = COLORS.muted
	local ok, result = pcall(function() return request:InvokeServer() end)
	if ok and type(result) == "table" and result.ok == true then
		render(result.quests)
	elseif ok and type(result) == "table" and result.code == "RATE_LIMITED" then
		status.Text = "Подожди немного перед обновлением."
		status.TextColor3 = COLORS.gold
	else
		status.Text = "Не удалось загрузить задания. Нажми обновить."
		status.TextColor3 = COLORS.rose
	end
	loading = false
end

local function queueRefresh()
	if refreshQueued then return end
	refreshQueued = true
	task.delay(0.65, function()
		refreshQueued = false
		if opened then refresh() end
	end)
end

local function setOpen(value: boolean)
	opened = value
	panel.Visible = value
	shade.Visible = value
	if value then
		shade.BackgroundTransparency = 1
		TweenService:Create(shade, TweenInfo.new(0.16), { BackgroundTransparency = 0.42 }):Play()
		refresh()
	else
		TweenService:Create(shade, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
		task.delay(0.13, function()
			if not opened then shade.Visible = false end
		end)
	end
end

openButton.Activated:Connect(function() setOpen(not opened) end)
closeButton.Activated:Connect(function() setOpen(false) end)
resourceUpdate.OnClientEvent:Connect(function(_snapshot, _resourceId, _amount, code)
	if code == "GATHERED" then queueRefresh() end
end)

local function resize()
	local camera = workspace.CurrentCamera
	if camera == nil then return end
	local compact = camera.ViewportSize.X < 520
	openButton.Size = UDim2.fromOffset(compact and 50 or 58, compact and 50 or 58)
	openButton.Position = UDim2.new(0, compact and 10 or 20, 0.56, 0)
	panel.Size = UDim2.new(compact and 0.94 or 0.9, 0, 0, compact and 390 or 410)
end
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(resize)
resize()

print("[PetKingdoms] Quest journal UI loaded.")
