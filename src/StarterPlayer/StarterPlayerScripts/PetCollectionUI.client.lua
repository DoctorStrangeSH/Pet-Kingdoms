--!strict
-- Responsive client pet collection UI. All ownership/equip decisions are verified by the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")
local PetCollectionData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetCollectionData"))

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

type PetRecord = { petId: string, speciesId: string, acquiredAt: number, level: number?, xp: number?, bondXp: number?, bondLevel: number?, lastInteractionAt: number?, isLocked: boolean?, isFavorite: boolean? }
type Collection = { revision: number, owned: { PetRecord }, equipped: { string }, maxEquipped: number }

local collection: Collection? = nil
local selectedPetId: string? = nil
local busy = false
local cardButtons: { [string]: TextButton } = {}
local activeFilter = "all"
local sortMode = "newest"
local pendingDeletePetId: string? = nil

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

local filterBar = make("Frame", {
	Name = "CollectionFilters",
	Position = UDim2.new(0, 24, 0, 132),
	Size = UDim2.new(0.48, -28, 0, 32),
	BackgroundTransparency = 1,
}, panel) :: Frame

local function makeFilterButton(name: string, text: string, x: number, width: number): TextButton
	local button = make("TextButton", {
		Name = name,
		Position = UDim2.new(x, 0, 0, 0),
		Size = UDim2.new(width, -4, 1, 0),
		BackgroundColor3 = COLORS.panelSoft,
		Text = text,
		TextSize = 10,
		Font = Enum.Font.GothamBold,
		TextColor3 = COLORS.cream,
		AutoButtonColor = true,
	}, filterBar) :: TextButton
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
	return button
end

local allFilterButton = makeFilterButton("All", "ВСЕ", 0, 0.25)
local teamFilterButton = makeFilterButton("Team", "КОМАНДА", 0.25, 0.25)
local favoriteFilterButton = makeFilterButton("Favorites", "★", 0.5, 0.18)
local sortButton = makeFilterButton("Sort", "НОВЫЕ", 0.68, 0.32)

local list = make("ScrollingFrame", {
	Name = "PetList",
	Position = UDim2.new(0, 24, 0, 172),
	Size = UDim2.new(0.48, -28, 1, -196),
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
	Size = UDim2.new(1, -112, 0, 30),
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

local favoriteButton = make("TextButton", {
	Name = "ToggleFavorite",
	Position = UDim2.new(1, -88, 0.55, 0),
	Size = UDim2.fromOffset(34, 30),
	BackgroundColor3 = COLORS.card,
	Text = "☆",
	TextSize = 19,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.gold,
}, detail) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 9) }, favoriteButton)

local lockButton = make("TextButton", {
	Name = "ToggleLock",
	Position = UDim2.new(1, -48, 0.55, 0),
	Size = UDim2.fromOffset(34, 30),
	BackgroundColor3 = COLORS.card,
	Text = "🔓",
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
}, detail) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 9) }, lockButton)

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


local progressionLabel = make("TextLabel", {
	Name = "PetProgression",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 0.55, 103),
	Size = UDim2.new(1, -32, 0, 20),
	Font = Enum.Font.GothamBold,
	Text = "УРОВЕНЬ 1 • 0 XP ВСЕГО",
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.mint,
}, detail) :: TextLabel

local bondLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 0.55, 127),
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

local PET_BUTTON_READY_TEXT = "♡ ПОГЛАДИТЬ"
local PLAY_BUTTON_READY_TEXT = "✦ ПОИГРАТЬ"
local function formatCooldown(seconds: number): string
	local safeSeconds = math.max(0, math.ceil(seconds))
	return string.format("%02d:%02d", math.floor(safeSeconds / 60), safeSeconds % 60)
end

local function applyInteractionCooldown(record: PetRecord?)
	local remaining = 0
	if record and type(record.lastInteractionAt) == "number" then
		local elapsed = Workspace:GetServerTimeNow() - record.lastInteractionAt
		remaining = math.max(0, PetCollectionData.BOND_INTERACTION_COOLDOWN_SECONDS - elapsed)
	end
	local coolingDown = remaining > 0
	local enabled = not coolingDown and not busy and record ~= nil
	petButton.Active = enabled
	playButton.Active = enabled
	petButton.AutoButtonColor = enabled
	playButton.AutoButtonColor = enabled
	petButton.BackgroundColor3 = if coolingDown then COLORS.panelSoft else COLORS.cardSelected
	playButton.BackgroundColor3 = if coolingDown then COLORS.panelSoft else COLORS.cardSelected
	if coolingDown then
		local timer = formatCooldown(remaining)
		petButton.Text = "🔒 ПОГЛАДИТЬ " .. timer
		playButton.Text = "🔒 ПОИГРАТЬ " .. timer
	else
		petButton.Text = PET_BUTTON_READY_TEXT
		playButton.Text = PLAY_BUTTON_READY_TEXT
	end
end

local equipButton = make("TextButton", {
	Position = UDim2.new(0, 14, 1, -58),
	Size = UDim2.new(0.50, -18, 0, 46),
	BackgroundColor3 = COLORS.mint,
	Text = "ЭКИПИРОВАТЬ",
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(30, 43, 43),
	AutoButtonColor = true,
}, detail) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 13) }, equipButton)

local mainButton = make("TextButton", {
	Name = "SetMainPet",
	Position = UDim2.new(0.50, 1, 1, -58),
	Size = UDim2.new(0.18, -2, 0, 46),
	BackgroundColor3 = COLORS.cardSelected,
	Text = "★",
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.gold,
}, detail) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 13) }, mainButton)

local deleteButton = make("TextButton", {
	Name = "DeletePet",
	Position = UDim2.new(0.68, 2, 1, -58),
	Size = UDim2.new(0.32, -16, 0, 46),
	BackgroundColor3 = COLORS.rose,
	Text = "УДАЛИТЬ",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(52, 30, 38),
}, detail) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 13) }, deleteButton)

local confirmPanel = make("Frame", {
	Name = "DeleteConfirmation",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(330, 178),
	BackgroundColor3 = COLORS.panel,
	Visible = false,
	ZIndex = 30,
}, shade) :: Frame
make("UICorner", { CornerRadius = UDim.new(0, 18) }, confirmPanel)
make("UIStroke", { Color = COLORS.rose, Thickness = 1.5, Transparency = 0.15 }, confirmPanel)
local confirmTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 18, 0, 14),
	Size = UDim2.new(1, -36, 0, 30),
	Text = "Удалить питомца?",
	TextColor3 = COLORS.cream,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
}, confirmPanel) :: TextLabel
local confirmMessage = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 18, 0, 48),
	Size = UDim2.new(1, -36, 0, 48),
	Text = "Это действие нельзя отменить.",
	TextWrapped = true,
	TextColor3 = COLORS.muted,
	TextSize = 12,
	Font = Enum.Font.Gotham,
}, confirmPanel) :: TextLabel
local cancelDeleteButton = make("TextButton", {
	Position = UDim2.new(0, 16, 1, -48),
	Size = UDim2.new(0.5, -22, 0, 34),
	BackgroundColor3 = COLORS.panelSoft,
	Text = "ОТМЕНА",
	TextColor3 = COLORS.cream,
	TextSize = 11,
	Font = Enum.Font.GothamBold,
}, confirmPanel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 10) }, cancelDeleteButton)
local confirmDeleteButton = make("TextButton", {
	Position = UDim2.new(0.5, 6, 1, -48),
	Size = UDim2.new(0.5, -22, 0, 34),
	BackgroundColor3 = COLORS.rose,
	Text = "УДАЛИТЬ",
	TextColor3 = Color3.fromRGB(52, 30, 38),
	TextSize = 11,
	Font = Enum.Font.GothamBold,
}, confirmPanel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 10) }, confirmDeleteButton)

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
		progressionLabel.Text = "УРОВЕНЬ — • XP —"
		bondLabel.Text = "ДРУЖБА —"
		applyInteractionCooldown(nil)
		equipButton.Visible = false
		preview:ClearAllChildren()
		return
	end

	petName.Text = if selected.speciesId == "bunny" then "Зайчик" else selected.speciesId
	petRarity.Text = "ОБЫЧНЫЙ • " .. string.upper(selected.speciesId)
	petDescription.Text = "Твой верный спутник. Впереди ждёт много приключений!"
	local petLevel = selected.level or 1
	local petXp = selected.xp or 0
	progressionLabel.Text = string.format("УРОВЕНЬ %d  •  %s XP ВСЕГО", petLevel, tostring(petXp))
	local bondLevel = selected.bondLevel or 1
	local bondXp = selected.bondXp or 0
	applyInteractionCooldown(selected)
	bondLabel.Text = if bondLevel >= 10
		then string.format("ДРУЖБА • УРОВЕНЬ %d  •  МАКСИМУМ", bondLevel)
		else string.format("ДРУЖБА • УРОВЕНЬ %d  •  %d / 50 XP", bondLevel, bondXp % 50)
	local equipped = isEquipped(selected.petId)
	favoriteButton.Text = if selected.isFavorite then "★" else "☆"
	favoriteButton.BackgroundColor3 = if selected.isFavorite then COLORS.cardSelected else COLORS.card
	lockButton.Text = if selected.isLocked then "🔒" else "🔓"
	lockButton.BackgroundColor3 = if selected.isLocked then COLORS.cardSelected else COLORS.card
	deleteButton.Visible = not selected.isLocked
	local equippedIndex = table.find(collection.equipped, selected.petId)
	mainButton.Visible = equippedIndex ~= nil
	mainButton.Text = if equippedIndex == 1 then "★" else "☆"
	mainButton.BackgroundColor3 = if equippedIndex == 1 then COLORS.cardSelected else COLORS.card
	mainButton.Active = equippedIndex ~= nil and equippedIndex ~= 1
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
	local visibleRecords = {}
	for _, record in ipairs(collection.owned) do
		local name = if record.speciesId == "bunny" then "Зайчик" else record.speciesId
		local matchesSearch = filter == "" or string.find(string.lower(name), filter, 1, true) ~= nil
		local matchesFilter = activeFilter == "all"
			or (activeFilter == "team" and isEquipped(record.petId))
			or (activeFilter == "favorites" and record.isFavorite == true)
		if matchesSearch and matchesFilter then table.insert(visibleRecords, record) end
	end
	table.sort(visibleRecords, function(a, b)
		if (a.isFavorite == true) ~= (b.isFavorite == true) then return a.isFavorite == true end
		if sortMode == "name" then
			return string.lower(a.speciesId) < string.lower(b.speciesId)
		elseif sortMode == "bond" then
			local aBond = a.bondLevel or 1
			local bBond = b.bondLevel or 1
			if aBond ~= bBond then return aBond > bBond end
			return (a.bondXp or 0) > (b.bondXp or 0)
		end
		return a.acquiredAt > b.acquiredAt
	end)
	for index, record in ipairs(visibleRecords) do
		local name = if record.speciesId == "bunny" then "Зайчик" else record.speciesId
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
				Text = table.concat({
					if equipped then "В КОМАНДЕ" else "В КОЛЛЕКЦИИ",
					if record.isLocked then "🔒" else "",
					if record.isFavorite then "★" else "",
				}, "  "),
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
	if #visibleRecords == 0 then
		local empty = make("TextLabel", {
			Name = "EmptyFilterState",
			Size = UDim2.new(1, -8, 0, 64),
			BackgroundTransparency = 1,
			Text = if activeFilter == "favorites" then "Пока нет избранных питомцев"
				elseif activeFilter == "team" then "В команде пока никого нет"
				else "Ничего не найдено",
			TextWrapped = true,
			TextColor3 = COLORS.muted,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			LayoutOrder = 1,
		}, list)
	end
	list.CanvasPosition = Vector2.zero
	allFilterButton.BackgroundColor3 = if activeFilter == "all" then COLORS.cardSelected else COLORS.panelSoft
	teamFilterButton.BackgroundColor3 = if activeFilter == "team" then COLORS.cardSelected else COLORS.panelSoft
	favoriteFilterButton.BackgroundColor3 = if activeFilter == "favorites" then COLORS.cardSelected else COLORS.panelSoft
	sortButton.Text = if sortMode == "newest" then "НОВЫЕ" elseif sortMode == "name" then "ИМЯ" else "ДРУЖБА"
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

local function setMainPet()
	if busy or collection == nil or selectedPetId == nil then return end
	local currentIndex = table.find(collection.equipped, selectedPetId)
	if currentIndex == nil then
		showStatus("Сначала добавь питомца в команду.", true)
		return
	end
	if currentIndex == 1 then return end

	busy = true
	mainButton.Active = false
	local nextEquipped = table.clone(collection.equipped)
	table.remove(nextEquipped, currentIndex)
	table.insert(nextEquipped, 1, selectedPetId)
	local ok, success, result = pcall(function()
		return remote:InvokeServer("Equip", {
			petIds = nextEquipped,
			expectedRevision = collection.revision,
		})
	end)
	busy = false
	if not ok or success ~= true or type(result) ~= "table" then
		showStatus("Не удалось сменить главного питомца. Обновляю данные...", true)
		refreshCollection()
		return
	end
	collection = result :: Collection
	renderList()
	updateDetail()
	showStatus("Главный питомец изменён!")
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
	petButton.AutoButtonColor = false
	playButton.AutoButtonColor = false
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
	petButton.Active = false
	playButton.Active = false
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

local function updatePetFlags(isFavorite: boolean, isLocked: boolean)
	if busy or collection == nil or selectedPetId == nil then return end
	busy = true
	favoriteButton.Active = false
	lockButton.Active = false
	local ok, success, result = pcall(function()
		return remote:InvokeServer("Protect", {
			petId = selectedPetId,
			isFavorite = isFavorite,
			isLocked = isLocked,
			expectedRevision = collection.revision,
		})
	end)
	busy = false
	favoriteButton.Active = true
	lockButton.Active = true
	if not ok or success ~= true or type(result) ~= "table" then
		local reason = if ok and type(result) == "string" then result else "UNKNOWN"
		showStatus(if reason == "STALE_REVISION" then "Коллекция обновилась. Загружаю..." else "Не удалось сохранить настройки питомца.", true)
		refreshCollection()
		return
	end
	collection = result :: Collection
	renderList()
	updateDetail()
	showStatus("Настройки питомца сохранены.")
end

local function requestDeleteSelected()
	if busy or collection == nil or selectedPetId == nil then return end
	local selected: PetRecord? = nil
	for _, record in ipairs(collection.owned) do
		if record.petId == selectedPetId then selected = record break end
	end
	if selected == nil then return end
	if selected.isLocked then
		showStatus("Сначала сними защиту с питомца.", true)
		return
	end
	pendingDeletePetId = selected.petId
	confirmTitle.Text = "Удалить питомца?"
	confirmMessage.Text = "Питомец будет навсегда удалён из коллекции. Это действие нельзя отменить."
	confirmPanel.Visible = true
end

local function confirmDeleteSelected()
	if busy or collection == nil or pendingDeletePetId == nil then return end
	busy = true
	confirmDeleteButton.Active = false
	confirmDeleteButton.Text = "УДАЛЯЕМ..."
	local ok, success, result = pcall(function()
		return remote:InvokeServer("Delete", {
			petId = pendingDeletePetId,
			expectedRevision = collection.revision,
		})
	end)
	busy = false
	confirmDeleteButton.Active = true
	confirmDeleteButton.Text = "УДАЛИТЬ"
	confirmPanel.Visible = false
	pendingDeletePetId = nil
	if not ok or success ~= true or type(result) ~= "table" then
		local reason = if ok and type(result) == "string" then result else "UNKNOWN"
		local messages = {
			STARTER_PET_PROTECTED = "Стартового питомца нельзя удалить.",
			LAST_PET_PROTECTED = "В коллекции должен остаться хотя бы один питомец.",
			PET_LOCKED = "Сначала сними защиту с питомца.",
			PET_EQUIPPED = "Сначала убери питомца из команды.",
			STALE_REVISION = "Коллекция обновилась. Загружаю изменения...",
		}
		showStatus(messages[reason] or "Не удалось удалить питомца. Обновляю коллекцию...", true)
		refreshCollection()
		return
	end
	collection = result :: Collection
	selectedPetId = collection.owned[1] and collection.owned[1].petId or nil
	renderList()
	updateDetail()
	showStatus("Питомец удалён из коллекции.")
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

local viewportConnection: RBXScriptConnection? = nil

local function bindViewportCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end

	local camera = Workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
		resize()
	end
end

local function openCollection()
	playerGui:SetAttribute("PetKingdomsActiveModal", "pets")
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
	if playerGui:GetAttribute("PetKingdomsActiveModal") == "pets" then
		playerGui:SetAttribute("PetKingdomsActiveModal", nil)
	end
end

playerGui:GetAttributeChangedSignal("PetKingdomsActiveModal"):Connect(function()
	local owner = playerGui:GetAttribute("PetKingdomsActiveModal")
	if owner ~= nil and owner ~= "pets" then
		panel.Visible = false
		shade.Visible = false
		confirmPanel.Visible = false
		pendingDeletePetId = nil
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not panel.Visible then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		if confirmPanel.Visible then
			confirmPanel.Visible = false
			pendingDeletePetId = nil
		else
			closeCollection()
		end
	end
end)

-- Dismiss the collection by tapping the backdrop, without accidentally
-- dismissing the confirmation layer when the user taps inside the panel.
shade.InputBegan:Connect(function(input)
	if not panel.Visible then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local position = input.Position
	local origin = panel.AbsolutePosition
	local size = panel.AbsoluteSize
	if position.X < origin.X or position.X > origin.X + size.X
		or position.Y < origin.Y or position.Y > origin.Y + size.Y then
		closeCollection()
	end
end)

openButton.Activated:Connect(openCollection)
allFilterButton.Activated:Connect(function() activeFilter = "all" renderList() end)
teamFilterButton.Activated:Connect(function() activeFilter = "team" renderList() end)
favoriteFilterButton.Activated:Connect(function() activeFilter = "favorites" renderList() end)
sortButton.Activated:Connect(function()
	sortMode = if sortMode == "newest" then "name" elseif sortMode == "name" then "bond" else "newest"
	renderList()
end)
favoriteButton.Activated:Connect(function()
	if collection == nil or selectedPetId == nil then return end
	for _, record in ipairs(collection.owned) do
		if record.petId == selectedPetId then
			updatePetFlags(not (record.isFavorite == true), record.isLocked == true)
			return
		end
	end
end)
lockButton.Activated:Connect(function()
	if collection == nil or selectedPetId == nil then return end
	for _, record in ipairs(collection.owned) do
		if record.petId == selectedPetId then
			updatePetFlags(record.isFavorite == true, not (record.isLocked == true))
			return
		end
	end
end)
deleteButton.Activated:Connect(requestDeleteSelected)
cancelDeleteButton.Activated:Connect(function()
	pendingDeletePetId = nil
	confirmPanel.Visible = false
end)
confirmDeleteButton.Activated:Connect(confirmDeleteSelected)

local function isOwnedPetHousePrompt(prompt: ProximityPrompt): boolean
	if prompt.Name ~= "PetHousePrompt" then return false end
	local foundPetHouse = false
	local current: Instance? = prompt
	while current do
		if current:IsA("Model") and current:GetAttribute("BuildingCatalogId") == "pet_house" then
			foundPetHouse = true
		end
		if current:IsA("Model") and current:GetAttribute("OwnerUserId") == player.UserId then
			return foundPetHouse
		end
		current = current.Parent
	end
	return false
end

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	if isOwnedPetHousePrompt(prompt) then
		openCollection()
	end
end)
closeButton.Activated:Connect(closeCollection)
equipButton.Activated:Connect(toggleEquip)
mainButton.Activated:Connect(setMainPet)
petButton.Activated:Connect(function() interactWithSelected("pet") end)
playButton.Activated:Connect(function() interactWithSelected("play") end)
search:GetPropertyChangedSignal("Text"):Connect(renderList)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportCamera)
bindViewportCamera()

if UserInputService.TouchEnabled then
	openButton.Position = UDim2.new(1, -14, 0.72, 0)
end

task.spawn(function()
	while screen.Parent do
		if panel.Visible and collection ~= nil and selectedPetId ~= nil then
			local selectedRecord = nil
			for _, record in ipairs(collection.owned) do
				if record.petId == selectedPetId then selectedRecord = record break end
			end
			applyInteractionCooldown(selectedRecord)
		end
		task.wait(0.25)
	end
end)

print("[PetKingdoms] Pet collection UI loaded.")
