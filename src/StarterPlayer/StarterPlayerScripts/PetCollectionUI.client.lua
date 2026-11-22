--!strict
-- Responsive client pet collection UI. All ownership/equip decisions are verified by the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PetCollectionRequest") :: RemoteFunction

local COLORS = {
	panel = Color3.fromRGB(31, 35, 48),
	panelSoft = Color3.fromRGB(43, 48, 64),
	card = Color3.fromRGB(53, 59, 78),
	cardSelected = Color3.fromRGB(76, 91, 125),
	cream = Color3.fromRGB(255, 245, 222),
	muted = Color3.fromRGB(177, 185, 205),
	gold = Color3.fromRGB(255, 205, 112),
	mint = Color3.fromRGB(135, 225, 183),
	rose = Color3.fromRGB(244, 151, 169),
	danger = Color3.fromRGB(255, 135, 135),
}

type PetRecord = { petId: string, speciesId: string, acquiredAt: number, bondXp: number?, bondLevel: number? }
type Collection = { revision: number, owned: { PetRecord }, equipped: { string }, maxEquipped: number }

local collection: Collection? = nil
local selectedPetId: string? = nil
local busy = false
local cardButtons: { [string]: TextButton } = {}

local function make(className: string, props: { [string]: any }, parent: Instance): Instance
	local object = Instance.new(className)
	for key, value in pairs(props) do
		(object :: any)[key] = value
	end
	object.Parent = parent
	return object
end

local screen = make("ScreenGui", {
	Name = "PetCollectionGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui) :: ScreenGui

local openButton = make("TextButton", {
	Name = "OpenPets",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -22, 0.55, 0),
	Size = UDim2.fromOffset(62, 62),
	BackgroundColor3 = COLORS.panel,
	Text = "🐾",
	TextSize = 30,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, screen) :: TextButton
make("UICorner", { CornerRadius = UDim.new(1, 0) }, openButton)
make("UIStroke", { Color = COLORS.gold, Thickness = 2, Transparency = 0.12 }, openButton)

local shade = make("Frame", {
	Name = "Shade",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.42,
	Visible = false,
}, screen) :: Frame

local panel = make("Frame", {
	Name = "CollectionPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.fromScale(0.82, 0.78),
	BackgroundColor3 = COLORS.panel,
	Visible = false,
}, shade) :: Frame
make("UICorner", { CornerRadius = UDim.new(0, 22) }, panel)
make("UIStroke", { Color = Color3.fromRGB(104, 117, 151), Thickness = 1.5, Transparency = 0.2 }, panel)
local panelScale = make("UIScale", { Scale = 1 }, panel) :: UIScale

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 24, 0, 15),
	Size = UDim2.new(0.55, 0, 0, 38),
	Font = Enum.Font.GothamBold,
	Text = "МОЯ КОЛЛЕКЦИЯ",
	TextSize = 23,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, panel) :: TextLabel

local subtitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 26, 0, 51),
	Size = UDim2.new(0.65, 0, 0, 24),
	Font = Enum.Font.Gotham,
	Text = "Твои верные спутники",
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.muted,
}, panel) :: TextLabel

local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 14),
	Size = UDim2.fromOffset(38, 38),
	BackgroundColor3 = COLORS.panelSoft,
	Text = "×",
	TextSize = 27,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
}, panel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 12) }, closeButton)

local search = make("TextBox", {
	Position = UDim2.new(0, 24, 0, 88),
	Size = UDim2.new(0.48, -28, 0, 38),
	BackgroundColor3 = COLORS.panelSoft,
	PlaceholderText = "Поиск питомца...",
	Text = "",
	PlaceholderColor3 = COLORS.muted,
	TextColor3 = COLORS.cream,
	TextSize = 14,
	Font = Enum.Font.Gotham,
	ClearTextOnFocus = false,
}, panel) :: TextBox
make("UICorner", { CornerRadius = UDim.new(0, 11) }, search)
make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }, search)

local list = make("ScrollingFrame", {
	Name = "PetList",
	Position = UDim2.new(0, 24, 0, 140),
	Size = UDim2.new(0.48, -28, 1, -164),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = COLORS.gold,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel) :: ScrollingFrame
make("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }, list)

local detail = make("Frame", {
	Position = UDim2.new(0.52, 0, 0, 88),
	Size = UDim2.new(0.48, -24, 1, -112),
	BackgroundColor3 = COLORS.panelSoft,
}, panel) :: Frame
make("UICorner", { CornerRadius = UDim.new(0, 17) }, detail)

local preview = make("ViewportFrame", {
	Name = "PetPreview",
	Position = UDim2.new(0, 10, 0, 10),
	Size = UDim2.new(1, -20, 0.53, -10),
	BackgroundColor3 = Color3.fromRGB(67, 77, 94),
	Ambient = Color3.fromRGB(190, 190, 190),
	LightColor = Color3.fromRGB(255, 239, 210),
	LightDirection = Vector3.new(-1, -1, -1),
}, detail) :: ViewportFrame
make("UICorner", { CornerRadius = UDim.new(0, 13) }, preview)

local petName = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 0.55, 0),
	Size = UDim2.new(1, -32, 0, 30),
	Font = Enum.Font.GothamBold,
	Text = "Зайчик",
	TextSize = 21,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, detail) :: TextLabel

local petRarity = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 0.55, 31),
	Size = UDim2.new(1, -32, 0, 22),
	Font = Enum.Font.GothamMedium,
	Text = "ОБЫЧНЫЙ • СТАРТОВЫЙ ПИТОМЕЦ",
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.gold,
}, detail) :: TextLabel

local petDescription = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 0.55, 57),
	Size = UDim2.new(1, -32, 0, 44),
	Font = Enum.Font.Gotham,
	Text = "Твой первый верный друг. Всегда готов отправиться в приключение!",
	TextSize = 12,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = COLORS.muted,
}, detail) :: TextLabel

local teamLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 1, -145),
	Size = UDim2.new(1, -32, 0, 22),
	Font = Enum.Font.GothamMedium,
	Text = "КОМАНДА: 0 / 3",
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.mint,
}, detail) :: TextLabel


local bondLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 0.55, 103),
	Size = UDim2.new(1, -32, 0, 22),
	Font = Enum.Font.GothamBold,
	Text = "ДРУЖБА • УРОВЕНЬ 1",
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.gold,
}, detail) :: TextLabel

local interactionRow = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 1, -104),
	Size = UDim2.new(1, -28, 0, 38),
}, detail) :: Frame

local petButton = make("TextButton", {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0.5, -5, 1, 0),
	BackgroundColor3 = COLORS.cardSelected,
	Text = "♡ ПОГЛАДИТЬ",
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, interactionRow) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 10) }, petButton)

local playButton = make("TextButton", {
	Position = UDim2.new(0.5, 5, 0, 0),
	Size = UDim2.new(0.5, -5, 1, 0),
	BackgroundColor3 = COLORS.cardSelected,
	Text = "✦ ПОИГРАТЬ",
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, interactionRow) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 10) }, playButton)

local equipButton = make("TextButton", {
	Position = UDim2.new(0, 14, 1, -58),
	Size = UDim2.new(1, -28, 0, 46),
	BackgroundColor3 = COLORS.mint,
	Text = "ЭКИПИРОВАТЬ",
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(30, 43, 43),
	AutoButtonColor = true,
}, detail) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 13) }, equipButton)

local statusLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -8),
	Size = UDim2.new(1, -48, 0, 20),
	Font = Enum.Font.Gotham,
	Text = "",
	TextSize = 11,
	TextColor3 = COLORS.muted,
}, panel) :: TextLabel

local function isEquipped(petId: string): boolean
	if collection == nil then return false end
	return table.find(collection.equipped, petId) ~= nil
end

local function countEquipped(): number
	return if collection then #collection.equipped else 0
end

local function showStatus(message: string, isError: boolean?)
	statusLabel.Text = message
	statusLabel.TextColor3 = if isError then COLORS.danger else COLORS.mint
end

local function renderPreview(speciesId: string)
	preview:ClearAllChildren()
	local world = Instance.new("WorldModel")
	world.Parent = preview
	local camera = Instance.new("Camera")
	camera.FieldOfView = 34
	camera.Parent = preview
	preview.CurrentCamera = camera

	local root = Workspace:FindFirstChild("PlayerPets")
	local playerFolder = root and root:FindFirstChild(tostring(player.UserId))
	local sourceModel = playerFolder and playerFolder:FindFirstChild(selectedPetId or "")
	if sourceModel == nil or not sourceModel:IsA("Model") then
		local placeholder = Instance.new("TextLabel")
		placeholder.BackgroundTransparency = 1
		placeholder.Size = UDim2.fromScale(1, 1)
		placeholder.Text = "3D-модель появится после загрузки питомца"
		placeholder.TextWrapped = true
		placeholder.TextColor3 = COLORS.muted
		placeholder.TextSize = 12
		placeholder.Font = Enum.Font.Gotham
		placeholder.Parent = preview
		return
	end

	local model = sourceModel:Clone()
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
	model.Parent = world
	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local center = boundsCFrame.Position
	model:PivotTo(model:GetPivot() - center)
	local height = math.max(boundsSize.Y, 1)
	camera.CFrame = CFrame.lookAt(Vector3.new(0, height * 0.48, -height * 2.8), Vector3.new(0, height * 0.42, 0))
end

local function updateDetail()
	if collection == nil then return end
	local selected: PetRecord? = nil
	for _, record in ipairs(collection.owned) do
		if record.petId == selectedPetId then
			selected = record
			break
		end
	end
	if selected == nil then
		selectedPetId = collection.owned[1] and collection.owned[1].petId or nil
		selected = collection.owned[1]
	end
	if selected == nil then
		petName.Text = "Пока пусто"
		petRarity.Text = "КОЛЛЕКЦИЯ"
		petDescription.Text = "Исследуй мир, чтобы найти новых друзей!"
		equipButton.Visible = false
		preview:ClearAllChildren()
		return
	end

	petName.Text = if selected.speciesId == "bunny" then "Зайчик" else selected.speciesId
	petRarity.Text = "ОБЫЧНЫЙ • " .. string.upper(selected.speciesId)
	petDescription.Text = "Твой верный спутник. Впереди ждёт много приключений!"
	local bondLevel = selected.bondLevel or 1
	local bondXp = selected.bondXp or 0
	bondLabel.Text = if bondLevel >= 10
		then string.format("ДРУЖБА • УРОВЕНЬ %d  •  МАКСИМУМ", bondLevel)
		else string.format("ДРУЖБА • УРОВЕНЬ %d  •  %d / 50 XP", bondLevel, bondXp % 50)
	local equipped = isEquipped(selected.petId)
	equipButton.Text = if equipped then "СНЯТЬ С КОМАНДЫ" else "ЭКИПИРОВАТЬ"
	equipButton.BackgroundColor3 = if equipped then COLORS.rose else COLORS.mint
	equipButton.TextColor3 = Color3.fromRGB(30, 43, 43)
	equipButton.Visible = true
	teamLabel.Text = string.format("КОМАНДА: %d / %d", countEquipped(), collection.maxEquipped)
	renderPreview(selected.speciesId)
end

local function renderList()
	if collection == nil then return end
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	table.clear(cardButtons)

	local filter = string.lower(search.Text)
	for index, record in ipairs(collection.owned) do
		local name = if record.speciesId == "bunny" then "Зайчик" else record.speciesId
		if filter == "" or string.find(string.lower(name), filter, 1, true) then
			local equipped = isEquipped(record.petId)
			local button = make("TextButton", {
				Name = "Pet_" .. record.petId,
				Size = UDim2.new(1, -8, 0, 68),
				BackgroundColor3 = if selectedPetId == record.petId then COLORS.cardSelected else COLORS.card,
				Text = "",
				LayoutOrder = index,
				AutoButtonColor = true,
			}, list) :: TextButton
			make("UICorner", { CornerRadius = UDim.new(0, 13) }, button)
			make("UIStroke", { Color = if equipped then COLORS.mint else COLORS.cardSelected, Thickness = 1, Transparency = 0.25 }, button)
			make("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 5),
				Size = UDim2.fromOffset(46, 54),
				Text = if record.speciesId == "bunny" then "🐰" else "🐾",
				TextSize = 29,
				Font = Enum.Font.Gotham,
				TextColor3 = COLORS.cream,
			}, button)
			make("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 66, 0, 12),
				Size = UDim2.new(1, -112, 0, 22),
				Text = name,
				TextSize = 14,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = COLORS.cream,
			}, button)
			make("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 66, 0, 34),
				Size = UDim2.new(1, -112, 0, 18),
				Text = if equipped then "В КОМАНДЕ" else "ОБЫЧНЫЙ",
				TextSize = 9,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = if equipped then COLORS.mint else COLORS.muted,
			}, button)
			cardButtons[record.petId] = button
			button.Activated:Connect(function()
				selectedPetId = record.petId
				renderList()
				updateDetail()
			end)
		end
	end
	list.CanvasPosition = Vector2.zero
end

local function refreshCollection()
	local ok, success, result = pcall(function()
		return remote:InvokeServer("Get")
	end)
	if not ok or success ~= true or type(result) ~= "table" then
		showStatus("Не удалось загрузить коллекцию. Попробуй ещё раз.", true)
		return false
	end
	collection = result :: Collection
	if selectedPetId == nil and collection.owned[1] then
		selectedPetId = collection.owned[1].petId
	end
	renderList()
	updateDetail()
	return true
end

local function toggleEquip()
	if busy or collection == nil or selectedPetId == nil then return end
	busy = true
	equipButton.Active = false
	equipButton.Text = "СОХРАНЯЕМ..."
	local nextEquipped = table.clone(collection.equipped)
	local currentIndex = table.find(nextEquipped, selectedPetId)
	if currentIndex then
		table.remove(nextEquipped, currentIndex)
	elseif #nextEquipped < collection.maxEquipped then
		table.insert(nextEquipped, selectedPetId)
	else
		showStatus("Можно выбрать не больше трёх питомцев.", true)
		busy = false
		equipButton.Active = true
		updateDetail()
		return
	end

	local ok, success, result = pcall(function()
		return remote:InvokeServer("Equip", {
			petIds = nextEquipped,
			expectedRevision = collection.revision,
		})
	end)
	busy = false
	equipButton.Active = true
	if not ok or success ~= true or type(result) ~= "table" then
		showStatus("Не удалось изменить команду. Обновляю данные...", true)
		refreshCollection()
		return
	end
	collection = result :: Collection
	renderList()
	updateDetail()
	showStatus("Команда сохранена!")
end


local function interactWithSelected(interactionType: string)
	if busy or collection == nil or selectedPetId == nil then return end
	busy = true
	petButton.Active = false
	playButton.Active = false
	local originalPetText = petButton.Text
	local originalPlayText = playButton.Text
	petButton.Text = "..."
	playButton.Text = "..."
	local ok, success, result = pcall(function()
		return remote:InvokeServer("Interact", {
			petId = selectedPetId,
			interactionType = interactionType,
			expectedRevision = collection.revision,
		})
	end)
	busy = false
	petButton.Active = true
	playButton.Active = true
	petButton.Text = originalPetText
	playButton.Text = originalPlayText
	if not ok or success ~= true or type(result) ~= "table" then
		local reason = if ok and type(result) == "string" then result else "UNKNOWN"
		local messages = {
			INTERACTION_COOLDOWN = "Питомцу нужно немного отдохнуть. Попробуй позже.",
			REQUEST_RATE_LIMITED = "Подожди секунду перед следующим действием.",
			STALE_REVISION = "Данные коллекции обновились. Загружаю изменения...",
			DATASTORE_UNAVAILABLE = "Не удалось сохранить дружбу. Проверь соединение и попробуй позже.",
			COLLECTION_NOT_READY = "Коллекция ещё загружается. Попробуй немного позже.",
		}
		showStatus(messages[reason] or "Не удалось выполнить действие. Обновляю данные...", true)
		refreshCollection()
		return
	end
	collection = result :: Collection
	renderList()
	updateDetail()
	showStatus(if interactionType == "pet" then "Питомцу приятно! +10 дружбы" else "Вы отлично провели время! +10 дружбы")
end

local function resize()
	local camera = workspace.CurrentCamera
	if camera == nil then return end
	local viewport = camera.ViewportSize
	if viewport.X < 650 then
		panel.Size = UDim2.new(0.94, 0, 0.82, 0)
		panelScale.Scale = 0.94
	elseif viewport.X < 900 then
		panel.Size = UDim2.new(0.9, 0, 0.8, 0)
		panelScale.Scale = 0.96
	else
		panel.Size = UDim2.fromScale(0.78, 0.78)
		panelScale.Scale = 1
	end
	if viewport.Y < 540 then
		panel.Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0.92, 0)
	end
end

local function openCollection()
	shade.Visible = true
	panel.Visible = true
	resize()
	panel.Position = UDim2.fromScale(0.5, 0.54)
	TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5),
	}):Play()
	refreshCollection()
end

local function closeCollection()
	panel.Visible = false
	shade.Visible = false
end

openButton.Activated:Connect(openCollection)
closeButton.Activated:Connect(closeCollection)
equipButton.Activated:Connect(toggleEquip)
petButton.Activated:Connect(function() interactWithSelected("pet") end)
playButton.Activated:Connect(function() interactWithSelected("play") end)
search:GetPropertyChangedSignal("Text"):Connect(renderList)

if UserInputService.TouchEnabled then
	openButton.Position = UDim2.new(1, -14, 0.72, 0)
end

print("[PetKingdoms] Pet collection UI loaded.")
