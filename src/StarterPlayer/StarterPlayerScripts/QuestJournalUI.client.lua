--!strict
-- Responsive quest journal. All progress is read from the server; this UI
-- never submits quest progress or reward claims.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ModalManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModalManager"))
local function announcePanelOpened()
	ModalManager.Open(script.Name)
end

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("GetQuestProgress") :: RemoteFunction
local trackingRequest = remotes:WaitForChild("SetTrackedQuest") :: RemoteFunction
local resourceUpdate = remotes:WaitForChild("IslandResourceUpdate") :: RemoteEvent

local InterfaceTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceTheme"))
local InterfaceComponents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceComponents"))
local NotificationManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NotificationManager"))
local RequestRunner = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RequestRunner"))
local COLORS = InterfaceTheme.Colors

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
	Text = InterfaceTheme.Icons.Quest,
	TextSize = 27,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, screen) :: TextButton
InterfaceComponents.StyleFloatingButton(openButton, "gold")

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
	Name = "QuestPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.new(0.9, 0, 0, 410),
	BackgroundColor3 = COLORS.panel,
	Visible = false,
}, shade) :: Frame
local panelConstraint = make("UISizeConstraint", { MinSize = Vector2.new(250, 300), MaxSize = Vector2.new(500, 440) }, panel) :: UISizeConstraint
local panelScale = make("UIScale", { Scale = 1 }, panel) :: UIScale
make("UICorner", { CornerRadius = UDim.new(0, 22) }, panel)
make("UIStroke", { Color = COLORS.gold, Thickness = 1.4, Transparency = 0.35 }, panel)

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 22, 0, 17),
	Size = UDim2.new(1, -132, 0, 31),
	Text = "ЖУРНАЛ ПРИКЛЮЧЕНИЙ",
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, panel) :: TextLabel
InterfaceComponents.StyleText(title, "Display")

local subtitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 24, 0, 51),
	Size = UDim2.new(1, -48, 0, 25),
	Text = "Небольшие дела — большие открытия",
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.muted,
}, panel) :: TextLabel
InterfaceComponents.StyleText(subtitle, "Caption")

local refreshButton = make("TextButton", {
	Name = "RefreshQuests",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -62, 0, 14),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = COLORS.panelSoft,
	Text = InterfaceTheme.Icons.Refresh,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
}, panel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 10) }, refreshButton)

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
local trackedQuestId: string? = nil
local hasLoadedSnapshot = false
local hasActiveTrackedQuest = false

local tracker = make("Frame", {
	Name = "TrackedQuestHUD",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 20, 1, -22),
	Size = UDim2.fromOffset(260, 78),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.06,
	Visible = false,
}, screen) :: Frame
make("UICorner", { CornerRadius = UDim.new(0, 15) }, tracker)
make("UIStroke", { Color = COLORS.gold, Transparency = 0.42, Thickness = 1.2 }, tracker)
local trackerTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 13, 0, 9),
	Size = UDim2.new(1, -26, 0, 20),
	Font = Enum.Font.GothamBold,
	Text = "ОТСЛЕЖИВАЕМОЕ ЗАДАНИЕ",
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.gold,
}, tracker) :: TextLabel
local trackerName = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 13, 0, 29),
	Size = UDim2.new(1, -26, 0, 19),
	Font = Enum.Font.GothamBold,
	Text = "",
	TextSize = 12,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, tracker) :: TextLabel
local trackerProgress = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -56, 0, 29),
	Size = UDim2.fromOffset(43, 19),
	Font = Enum.Font.GothamBold,
	Text = "",
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = COLORS.mint,
}, tracker) :: TextLabel
local trackerTrack = make("Frame", {
	Position = UDim2.new(0, 13, 1, -15),
	Size = UDim2.new(1, -26, 0, 5),
	BackgroundColor3 = COLORS.track,
}, tracker) :: Frame
make("UICorner", { CornerRadius = UDim.new(1, 0) }, trackerTrack)
local trackerFill = make("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = COLORS.mint,
}, trackerTrack) :: Frame
make("UICorner", { CornerRadius = UDim.new(1, 0) }, trackerFill)

local function showCompletionToast(name: string)
	NotificationManager.Notify("Задание выполнено: " .. name, "success", 3.2)
end

local function updateTracker(quests: { any })
	local selected = nil
	for _, quest in ipairs(quests) do
		if quest.id == trackedQuestId then selected = quest break end
	end
	if selected == nil or selected.completed == true then
		hasActiveTrackedQuest = false
		tracker.Visible = false
		return
	end
	hasActiveTrackedQuest = true
	trackerName.Text = selected.name
	trackerProgress.Text = string.format("%d/%d", selected.count, selected.target)
	trackerFill.Size = UDim2.new(math.clamp(selected.count / math.max(selected.target, 1), 0, 1), 0, 1, 0)
	-- The tracked-quest HUD is a world overlay, not part of the journal.
	-- Hide it whenever any modal is active so it cannot cover another window.
	tracker.Visible = ModalManager.GetActive() == nil
end

ModalManager.ActiveChanged:Connect(function(activeName)
	if activeName ~= nil then
		tracker.Visible = false
	elseif hasActiveTrackedQuest then
		tracker.Visible = true
	end
end)

local function clearCards()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function render(quests: any, serverTrackedQuestId: string?)
	if type(quests) ~= "table" then
		status.Text = "Не удалось прочитать задания."
		status.TextColor3 = COLORS.rose
		return
	end
	trackedQuestId = serverTrackedQuestId
	clearCards()
	local completedCount = 0
	local renderedCount = 0
	for index, quest in ipairs(quests) do
		if type(quest) ~= "table" or type(quest.id) ~= "string"
			or type(quest.name) ~= "string" or type(quest.description) ~= "string"
			or type(quest.count) ~= "number" or type(quest.target) ~= "number"
		then
			continue
		end
		local done = quest.completed == true
		renderedCount += 1
		if done then completedCount += 1 end
		local card = make("Frame", {
			Name = "Quest_" .. quest.id,
			Size = UDim2.new(1, -6, 0, if (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 520) then 164 else 124),
			BackgroundColor3 = COLORS.panelSoft,
			LayoutOrder = index,
		}, list) :: Frame
		InterfaceComponents.StyleCard(card, "surface")
		local compactCard = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 520) or false
		local trackButton = make("TextButton", {
			Name = "TrackQuest",
			AnchorPoint = if compactCard then Vector2.new(0, 0) else Vector2.new(1, 0),
			Position = if compactCard then UDim2.new(0, 15, 0, 104) else UDim2.new(1, -10, 0, 9),
			Size = UDim2.fromOffset(if compactCard then 112 else 102, if compactCard then 32 else 27),
			BackgroundColor3 = if trackedQuestId == quest.id then COLORS.mint else COLORS.card,
			Text = if trackedQuestId == quest.id then "СЛЕЖУ" else "СЛЕДИТЬ",
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			TextColor3 = if trackedQuestId == quest.id then COLORS.panel else COLORS.cream,
			AutoButtonColor = true,
		}, card) :: TextButton
		InterfaceComponents.StyleActionButton(trackButton, if trackedQuestId == quest.id then "primary" else "secondary")
		trackButton.TextTruncate = Enum.TextTruncate.AtEnd
		trackButton.Activated:Connect(function()
			if quest.completed == true then return end
			InterfaceComponents.SetButtonLoading(trackButton, true, "СОХРАНЕНИЕ...")
			local trackingResult = RequestRunner.Invoke(function()
				return trackingRequest:InvokeServer(quest.id)
			end, 12)
			local result = if trackingResult.ok then trackingResult.value else nil
			InterfaceComponents.SetButtonLoading(trackButton, false)
			if trackingResult.ok and type(result) == "table" and result.ok == true then
				trackedQuestId = quest.id
				updateTracker(lastQuests)
				for _, sibling in ipairs(list:GetChildren()) do
					if sibling:IsA("Frame") then
						local action = sibling:FindFirstChild("TrackQuest")
						if action and action:IsA("TextButton") then
							local active = sibling.Name == "Quest_" .. quest.id
							action.Text = if active then "СЛЕЖУ" else "СЛЕДИТЬ"
							action.BackgroundColor3 = if active then COLORS.mint else COLORS.card
							action.TextColor3 = if active then COLORS.panel else COLORS.cream
						end
					end
				end
				InterfaceComponents.SetButtonFeedback(trackButton, "success", "СЛЕЖУ", 1.2)
			else
				InterfaceComponents.SetButtonFeedback(trackButton, "error", "ПОВТОРИТЬ", 2.2)
			end
		end)
		make("UIStroke", { Color = if done then COLORS.mint else COLORS.track, Transparency = 0.58, Thickness = 1 }, card)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0, 9),
			Size = UDim2.new(1, if compactCard then -30 else -126, 0, 23),
			Font = Enum.Font.GothamBold,
			Text = (if done then InterfaceTheme.Icons.Confirm .. "  " else "✦  ") .. quest.name,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if done then COLORS.mint else COLORS.cream,
		}, card)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 35),
			Size = UDim2.new(1, -32, 0, if compactCard then 38 else 21),
			Font = Enum.Font.Gotham,
			Text = quest.description,
			TextSize = if compactCard then 12 else 11,
			TextWrapped = compactCard,
			TextTruncate = if compactCard then Enum.TextTruncate.None else Enum.TextTruncate.AtEnd,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = COLORS.muted,
		}, card)
		local count = math.clamp(quest.count, 0, quest.target)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, if compactCard then 77 else 65),
			Size = UDim2.new(0.5, 0, 0, 18),
			Font = Enum.Font.GothamBold,
			Text = if done then "ВЫПОЛНЕНО" else "ПРОГРЕСС",
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if done then COLORS.mint else COLORS.gold,
		}, card)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -76, 0, if compactCard then 76 else 64),
			Size = UDim2.fromOffset(60, 19),
			Font = Enum.Font.GothamBold,
			Text = string.format("%d / %d", count, quest.target),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = COLORS.cream,
		}, card)
		local track = make("Frame", {
			Position = UDim2.new(0, 16, 1, -11),
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
	if renderedCount == 0 then
		local emptyText = if #quests == 0 then "Пока нет заданий.\nНовые приключения появятся здесь."
			else "Не удалось отобразить задания.\nПопробуй обновить список."
		local emptyState = make("TextLabel", {
			Name = "EmptyQuestState",
			Size = UDim2.new(1, -12, 0, 104),
			BackgroundTransparency = 1,
			Text = emptyText,
			TextWrapped = true,
			LayoutOrder = 1,
		}, list) :: TextLabel
		InterfaceComponents.StyleEmptyState(emptyState, InterfaceTheme.Icons.Quest)
		if #quests > 0 then
			status.Text = "Данные заданий повреждены. Нажми обновить."
			status.TextColor3 = COLORS.rose
			return
		end
	end
	badge.Text = if #quests == 0 then "—" else tostring(math.max(0, #quests - completedCount))
	badge.BackgroundColor3 = if completedCount == #quests and #quests > 0 then COLORS.mint else COLORS.gold
	status.Text = string.format("Выполнено: %d из %d  •  Награды появятся в следующем этапе", completedCount, #quests)
	status.TextColor3 = COLORS.muted
	for _, quest in ipairs(quests) do
		if quest.completed == true then
			local wasCompleted = false
			for _, previous in ipairs(lastQuests) do
				if previous.id == quest.id and previous.completed == true then wasCompleted = true break end
			end
			if hasLoadedSnapshot and not wasCompleted then showCompletionToast(quest.name) end
		end
	end
	local trackedIsComplete = true
	for _, quest in ipairs(quests) do
		if quest.id == trackedQuestId and quest.completed ~= true then trackedIsComplete = false break end
	end
	if trackedQuestId == nil or trackedIsComplete then
		trackedQuestId = nil
		for _, quest in ipairs(quests) do
			if quest.completed ~= true then trackedQuestId = quest.id break end
		end
		if trackedQuestId ~= nil then
			local nextTrackedId = trackedQuestId
			task.spawn(function()
				pcall(function() trackingRequest:InvokeServer(nextTrackedId) end)
			end)
		end
	end
	updateTracker(quests)
	lastQuests = quests
	hasLoadedSnapshot = true
end

local function refresh()
	if loading then return end
	loading = true
	status.Text = "Получаем прогресс с сервера..."
	status.TextColor3 = COLORS.muted
	local requestResult = RequestRunner.Invoke(function()
		return request:InvokeServer()
	end, 12)
	local result = requestResult.value
	if requestResult.ok and type(result) == "table" and result.ok == true then
		render(result.quests, result.trackedQuestId)
	elseif requestResult.ok and type(result) == "table" and result.code == "RATE_LIMITED" then
		status.Text = "Подожди немного перед обновлением."
		status.TextColor3 = COLORS.gold
	elseif requestResult.errorCode == "TIMEOUT" then
		status.Text = "Сервер отвечает слишком долго. Нажми обновить ещё раз."
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
	if value then announcePanelOpened() end
	opened = value
	if value then
		-- ModalManager.Open is called before the panel becomes visible.
	else
		ModalManager.Close(script.Name)
	end
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

ModalManager.Register(script.Name, function(_reason: string)
	if opened then setOpen(false) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.Escape or not opened or not ModalManager.IsActive(script.Name) then return end
	setOpen(false)
end)

-- Backdrop dismissal is handled exclusively by the panel-bound hit test.
-- A full-screen TextButton can receive Activated from non-interactive
-- children, accidentally closing the window when its content is tapped.
-- Some device/input combinations do not dispatch TextButton.Activated on
-- the full-screen shade. Check the actual panel bounds on pointer-down.
UserInputService.InputBegan:Connect(function(input)
	if not opened or not ModalManager.IsActive(script.Name) then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local point = Vector2.new(input.Position.X, input.Position.Y)
	local origin = panel.AbsolutePosition
	local size = panel.AbsoluteSize
	if point.X < origin.X or point.X > origin.X + size.X
		or point.Y < origin.Y or point.Y > origin.Y + size.Y then
		setOpen(false)
	end
end)

openButton.Activated:Connect(function() setOpen(not opened) end)
closeButton.Activated:Connect(function() setOpen(false) end)
refreshButton.Activated:Connect(function()
	if loading then return end
	refresh()
end)
resourceUpdate.OnClientEvent:Connect(function(_snapshot, _resourceId, _amount, code)
	if code == "GATHERED" then queueRefresh() end
end)

local function resize()
	local camera = workspace.CurrentCamera
	if camera == nil then return end
	local viewport = camera.ViewportSize
	local compact = viewport.X < 520
	local narrow = viewport.X < 360
	local short = viewport.Y < 500
	title.Text = if compact then "ЗАДАНИЯ" else "ЖУРНАЛ ПРИКЛЮЧЕНИЙ"
	title.TextSize = if compact then 15 else 18
	subtitle.Text = if narrow then "Твои текущие задания" else "Небольшие дела — большие открытия"
	subtitle.TextSize = if compact then 10 else 12
	openButton.Size = UDim2.fromOffset(compact and 48 or 58, compact and 48 or 58)
	openButton.TextSize = if compact then 23 else 27
	closeButton.Size = UDim2.fromOffset(compact and 36 or 40, compact and 36 or 40)
	refreshButton.Size = UDim2.fromOffset(compact and 36 or 40, compact and 36 or 40)
	openButton.Position = UDim2.new(0, compact and 10 or 20, 0.56, 0)
	-- Compact screens get a shorter, reflowed journal instead of a scaled
	-- desktop panel with tiny text and cramped touch targets.
	local veryShort = viewport.Y < 380
	local ultraShort = viewport.Y < 220
	local compactHeight = if ultraShort then math.max(144, viewport.Y - 20)
		elseif veryShort then 320 elseif short then 350 else 380
	panel.Size = UDim2.new(compact and 0.94 or 0.9, 0, 0, if compact then compactHeight else 410)
	panelConstraint.MinSize = Vector2.new(math.min(250, math.max(220, viewport.X - 24)), if compact then compactHeight else 300)
	panelConstraint.MaxSize = Vector2.new(math.min(500, math.max(220, viewport.X - 16)), if compact then compactHeight else 440)
	panelScale.Scale = if compact then 1 else math.clamp((viewport.Y - 24) / 410, 0.82, 1)
	if compact then
		local listTop = if ultraShort then 50 elseif veryShort then 76 else 82
		title.Position = UDim2.fromOffset(ultraShort and 10 or 16, ultraShort and 5 or 14)
		title.Size = UDim2.new(1, ultraShort and -92 or -112, 0, ultraShort and 24 or 28)
		title.TextSize = if ultraShort then 13 else (if compact then 15 else 18)
		subtitle.Position = UDim2.fromOffset(ultraShort and 12 or 18, ultraShort and 29 or 44)
		subtitle.Size = UDim2.new(1, ultraShort and -24 or -36, 0, ultraShort and 16 or 22)
		subtitle.Visible = not ultraShort or not narrow
		closeButton.Position = UDim2.new(1, -10, 0, ultraShort and 5 or 10)
		refreshButton.Position = UDim2.new(1, -52, 0, ultraShort and 5 or 10)
		closeButton.Size = UDim2.fromOffset(ultraShort and 32 or 36, ultraShort and 32 or 36)
		refreshButton.Size = UDim2.fromOffset(ultraShort and 32 or 36, ultraShort and 32 or 36)
		list.Position = UDim2.fromOffset(ultraShort and 10 or 14, listTop)
		list.Size = UDim2.new(1, ultraShort and -20 or -28, 1, -(listTop + (ultraShort and 28 or 54)))
		status.Position = UDim2.new(0.5, 0, 1, ultraShort and -3 or -8)
		status.Size = UDim2.new(1, -32, 0, ultraShort and 18 or 34)
		status.TextSize = if ultraShort then 9 else (if compact then 11 else 12)
	else
		title.Position = UDim2.new(0, 22, 0, 17)
		title.Size = UDim2.new(1, -132, 0, 31)
		subtitle.Position = UDim2.new(0, 24, 0, 51)
		subtitle.Size = UDim2.new(1, -48, 0, 25)
		closeButton.Position = UDim2.new(1, -16, 0, 14)
		refreshButton.Position = UDim2.new(1, -62, 0, 14)
		closeButton.Size = UDim2.fromOffset(40, 40)
		refreshButton.Size = UDim2.fromOffset(40, 40)
		list.Position = UDim2.new(0, 20, 0, 88)
		list.Size = UDim2.new(1, -40, 1, -145)
		status.Position = UDim2.new(0.5, 0, 1, -10)
		status.Size = UDim2.new(1, -44, 0, 32)
	end
	tracker.Position = UDim2.new(0, compact and 10 or 20, 1, short and -8 or -12)
	tracker.Size = UDim2.fromOffset(math.max(190, math.min(compact and 220 or 260, viewport.X - 20)), compact and 68 or 78)
	trackerTitle.TextSize = if compact then 9 else 10
	trackerName.TextSize = if compact then 11 else 12
	trackerProgress.TextSize = if compact then 10 else 11
end

local viewportConnection: RBXScriptConnection? = nil
local function bindViewportCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportCamera)
bindViewportCamera()

ModalManager.ActiveChanged:Connect(function(activeName: string?)
	openButton.Visible = activeName == nil
end)
openButton.Visible = ModalManager.GetActive() == nil

print("[PetKingdoms] Quest journal UI loaded.")
