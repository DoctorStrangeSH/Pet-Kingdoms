--!strict
-- Responsive client pet collection UI. All ownership/equip decisions are verified by the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ModalManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModalManager"))
local function announcePanelOpened()
	ModalManager.Open(script.Name)
end

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PetCollectionRequest") :: RemoteFunction

local InterfaceTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceTheme"))
local InterfaceComponents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceComponents"))
local RequestRunner = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RequestRunner"))
local COLORS = InterfaceTheme.Colors

type PetRecord = { petId: string, speciesId: string, acquiredAt: number, bondXp: number?, bondLevel: number?, isLocked: boolean?, isFavorite: boolean? }
type Collection = { revision: number, owned: { PetRecord }, equipped: { string }, maxEquipped: number }

local collection: Collection? = nil
local selectedPetId: string? = nil
local busy = false
local cardButtons: { [string]: TextButton } = {}
local activeFilter = "all"
local sortMode = "newest"
local pendingDeletePetId: string? = nil
local mobileDetailVisible = false
local compactCollection = false
local resize: () -> ()

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
	Text = InterfaceTheme.Icons.Pet,
	TextSize = 30,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, screen) :: TextButton
InterfaceComponents.StyleFloatingButton(openButton, "mint")

local shade = make("TextButton", {
	Name = "Shade",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.42,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
}, screen) :: TextButton

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
	Text = "МОЯ КОЛЛЕКЦИЯ",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.cream,
}, panel) :: TextLabel
InterfaceComponents.StyleText(title, "Display")

local subtitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 26, 0, 51),
	Size = UDim2.new(0.65, 0, 0, 24),
	Text = "Твои верные спутники",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.muted,
}, panel) :: TextLabel
InterfaceComponents.StyleText(subtitle, "Caption")

local mobileBackButton = make("TextButton", {
	Name = "BackToPetList",
	Position = UDim2.new(0, 24, 0, 88),
	Size = UDim2.new(1, -48, 0, 34),
	BackgroundColor3 = COLORS.panelSoft,
	Text = InterfaceTheme.Icons.Back .. "  К СПИСКУ ПИТОМЦЕВ",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	Visible = false,
}, panel) :: TextButton
make("UICorner", { CornerRadius = UDim.new(0, 10) }, mobileBackButton)

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
local favoriteFilterButton = makeFilterButton("Favorites", InterfaceTheme.Icons.FavoriteOn, 0.5, 0.18)
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
InterfaceComponents.StyleCard(detail, "surface")

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
	Text = InterfaceTheme.Icons.FavoriteOff,
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
	Text = InterfaceTheme.Icons.Unlocked,
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
	Text = InterfaceTheme.Icons.Affection .. " ПОГЛАДИТЬ",
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, interactionRow) :: TextButton
InterfaceComponents.StyleActionButton(petButton, "secondary")

local playButton = make("TextButton", {
	Position = UDim2.new(0.5, 5, 0, 0),
	Size = UDim2.new(0.5, -5, 1, 0),
	BackgroundColor3 = COLORS.cardSelected,
	Text = InterfaceTheme.Icons.Play .. " ПОИГРАТЬ",
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.cream,
	AutoButtonColor = true,
}, interactionRow) :: TextButton
InterfaceComponents.StyleActionButton(playButton, "secondary")

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
InterfaceComponents.StyleActionButton(equipButton, "primary")

local mainButton = make("TextButton", {
	Name = "SetMainPet",
	Position = UDim2.new(0.50, 1, 1, -58),
	Size = UDim2.new(0.18, -2, 0, 46),
	BackgroundColor3 = COLORS.cardSelected,
	Text = InterfaceTheme.Icons.FavoriteOn,
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.gold,
}, detail) :: TextButton
InterfaceComponents.StyleActionButton(mainButton, "gold")

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
InterfaceComponents.StyleActionButton(deleteButton, "danger")

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
local confirmScale = make("UIScale", { Scale = 1 }, confirmPanel) :: UIScale
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
InterfaceComponents.StyleActionButton(cancelDeleteButton, "secondary")
local confirmDeleteButton = make("TextButton", {
	Position = UDim2.new(0.5, 6, 1, -48),
	Size = UDim2.new(0.5, -22, 0, 34),
	BackgroundColor3 = COLORS.rose,
	Text = "УДАЛИТЬ",
	TextColor3 = Color3.fromRGB(52, 30, 38),
	TextSize = 11,
	Font = Enum.Font.GothamBold,
}, confirmPanel) :: TextButton
InterfaceComponents.StyleActionButton(confirmDeleteButton, "danger")

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
	favoriteButton.Text = if selected.isFavorite then InterfaceTheme.Icons.FavoriteOn else InterfaceTheme.Icons.FavoriteOff
	favoriteButton.BackgroundColor3 = if selected.isFavorite then COLORS.cardSelected else COLORS.card
	lockButton.Text = if selected.isLocked then InterfaceTheme.Icons.Locked else InterfaceTheme.Icons.Unlocked
	lockButton.BackgroundColor3 = if selected.isLocked then COLORS.cardSelected else COLORS.card
	deleteButton.Visible = not selected.isLocked
	local equippedIndex = table.find(collection.equipped, selected.petId)
	mainButton.Visible = equippedIndex ~= nil
	mainButton.Text = if equippedIndex == 1 then InterfaceTheme.Icons.FavoriteOn else InterfaceTheme.Icons.FavoriteOff
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
				Text = if record.speciesId == "bunny" then InterfaceTheme.Icons.Bunny else InterfaceTheme.Icons.Pet,
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
					if record.isLocked then InterfaceTheme.Icons.Locked else "",
					if record.isFavorite then InterfaceTheme.Icons.FavoriteOn else "",
				}, "  "),
				TextSize = 10,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = if equipped then COLORS.mint else COLORS.muted,
			}, button)
			cardButtons[record.petId] = button
		button.Activated:Connect(function()
			selectedPetId = record.petId
			if compactCollection then mobileDetailVisible = true end
			renderList()
			updateDetail()
			resize()
		end)
	end
	if #visibleRecords == 0 then
		local emptyText = if #collection.owned == 0 then "Пока нет питомцев.\nИсследуй остров, чтобы найти первого друга!"
			elseif activeFilter == "favorites" then "Нет избранных питомцев.\nОтметь понравившегося питомца звёздочкой."
			elseif activeFilter == "team" then "Команда пока пуста.\nВыбери питомца и добавь его в команду."
			elseif filter ~= "" then "Ничего не найдено.\nПопробуй изменить поисковый запрос."
			else "Здесь пока пусто."
		local empty = make("TextLabel", {
			Name = "EmptyFilterState",
			Size = UDim2.new(1, -8, 0, 92),
			BackgroundTransparency = 1,
			Text = emptyText,
			TextWrapped = true,
			TextColor3 = COLORS.muted,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			LayoutOrder = 1,
		}, list) :: TextLabel
		InterfaceComponents.StyleEmptyState(empty, if #collection.owned == 0 then InterfaceTheme.Icons.Pet else InterfaceTheme.Icons.Search)
	end
	list.CanvasPosition = Vector2.zero
	allFilterButton.BackgroundColor3 = if activeFilter == "all" then COLORS.cardSelected else COLORS.panelSoft
	teamFilterButton.BackgroundColor3 = if activeFilter == "team" then COLORS.cardSelected else COLORS.panelSoft
	favoriteFilterButton.BackgroundColor3 = if activeFilter == "favorites" then COLORS.cardSelected else COLORS.panelSoft
	sortButton.Text = if sortMode == "newest" then "НОВЫЕ" elseif sortMode == "name" then "ИМЯ" else "ДРУЖБА"
end

local function refreshCollection()
	local requestResult = RequestRunner.Invoke(function()
		return table.pack(remote:InvokeServer("Get"))
	end, 12)
	local response = if requestResult.ok then requestResult.value else nil
	local success = if type(response) == "table" then response[1] else false
	local result = if type(response) == "table" then response[2] else nil
	if not requestResult.ok then
		showStatus(if requestResult.errorCode == "TIMEOUT"
			then "Сервер отвечает слишком долго. Попробуй обновить коллекцию ещё раз."
			else "Не удалось загрузить коллекцию. Попробуй ещё раз.", true)
		return false
	end
	if success ~= true or type(result) ~= "table" then
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

resize = function()
	local camera = workspace.CurrentCamera
	if camera == nil then return end
	local viewport = camera.ViewportSize
	compactCollection = viewport.X < 650
	local launcherCompact = viewport.X < 560
	openButton.Size = UDim2.fromOffset(launcherCompact and 52 or 62, launcherCompact and 52 or 62)
	openButton.Position = UDim2.new(1, launcherCompact and -12 or -22, launcherCompact and 0.46 or 0.55, 0)
	if compactCollection then
		panel.Size = UDim2.new(0.94, 0, 0.84, 0)
		panelScale.Scale = 1
		local contentWidth = math.max(180, math.floor(viewport.X * 0.94) - 48)
		search.Position = UDim2.fromOffset(24, 88)
		search.Size = UDim2.fromOffset(contentWidth, 38)
		filterBar.Position = UDim2.fromOffset(24, 132)
		filterBar.Size = UDim2.fromOffset(contentWidth, 32)
		list.Position = UDim2.fromOffset(24, 172)
		list.Size = UDim2.new(1, -48, 1, -196)
		mobileBackButton.Visible = mobileDetailVisible
		list.Visible = not mobileDetailVisible
		search.Visible = not mobileDetailVisible
		filterBar.Visible = not mobileDetailVisible
		detail.Position = UDim2.fromOffset(24, if mobileDetailVisible then 130 else 172)
		detail.Size = UDim2.new(1, -48, 1, if mobileDetailVisible then -154 else -196)
		detail.Visible = mobileDetailVisible
	else
		panel.Size = if viewport.X < 900 then UDim2.new(0.9, 0, 0.8, 0) else UDim2.fromScale(0.78, 0.78)
		panelScale.Scale = if viewport.X < 900 then 0.96 else 1
		if viewport.Y < 540 then
			panel.Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0.92, 0)
		end
		search.Position = UDim2.new(0, 24, 0, 88)
		search.Size = UDim2.new(0.48, -28, 0, 38)
		filterBar.Position = UDim2.new(0, 24, 0, 132)
		filterBar.Size = UDim2.new(0.48, -28, 0, 32)
		list.Position = UDim2.new(0, 24, 0, 172)
		list.Size = UDim2.new(0.48, -28, 1, -196)
		list.Visible = true
		search.Visible = true
		filterBar.Visible = true
		detail.Position = UDim2.new(0.52, 0, 0, 88)
		detail.Size = UDim2.new(0.48, -24, 1, -112)
		detail.Visible = true
		mobileBackButton.Visible = false
	end
	local confirmWidth = math.min(330, math.max(240, viewport.X - 32))
	confirmPanel.Size = UDim2.fromOffset(confirmWidth, 178)
	confirmScale.Scale = math.clamp((viewport.Y - 32) / 178, 0.82, 1)
	cancelDeleteButton.Size = UDim2.new(0.5, -22, 0, if compactCollection then 40 else 34)
	confirmDeleteButton.Size = UDim2.new(0.5, -22, 0, if compactCollection then 40 else 34)
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

local collectionModalRevision = 0

local function openCollection()
	collectionModalRevision += 1
	announcePanelOpened()
	-- Never resurrect a stale destructive-confirmation dialog on reopen.
	confirmPanel.Visible = false
	mobileDetailVisible = false
	if not busy then pendingDeletePetId = nil end
	shade.Visible = true
	shade.BackgroundTransparency = 1
	panel.Visible = true
	resize()
	panel.Position = UDim2.fromScale(0.5, 0.54)
	TweenService:Create(shade, TweenInfo.new(0.16), { BackgroundTransparency = 0.42 }):Play()
	TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5),
	}):Play()
	refreshCollection()
end

local function closeCollection()
	if not shade.Visible then return end
	collectionModalRevision += 1
	local closingRevision = collectionModalRevision
	-- Closing the collection also dismisses its nested delete-confirmation layer.
	confirmPanel.Visible = false
	if not busy then pendingDeletePetId = nil end
	panel.Visible = false
	ModalManager.Close(script.Name)
	TweenService:Create(shade, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
	task.delay(0.13, function()
		-- A quick reopen invalidates this delayed hide, preventing a stuck/hidden modal.
		if collectionModalRevision == closingRevision and not panel.Visible then
			shade.Visible = false
		end
	end)
end

ModalManager.Register(script.Name, function(_reason: string)
	closeCollection()
end)

-- Escape closes the topmost layer first, never the collection behind a confirmation.
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.Escape or not ModalManager.IsActive(script.Name) then return end
	if confirmPanel.Visible then
		pendingDeletePetId = nil
		confirmPanel.Visible = false
	elseif panel.Visible then
		closeCollection()
	end
end)

shade.Activated:Connect(function()
	if confirmPanel.Visible then
		pendingDeletePetId = nil
		confirmPanel.Visible = false
	elseif panel.Visible then
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
mobileBackButton.Activated:Connect(function()
	if not compactCollection then return end
	mobileDetailVisible = false
	confirmPanel.Visible = false
	pendingDeletePetId = nil
	resize()
end)
equipButton.Activated:Connect(toggleEquip)
mainButton.Activated:Connect(setMainPet)
petButton.Activated:Connect(function() interactWithSelected("pet") end)
playButton.Activated:Connect(function() interactWithSelected("play") end)
search:GetPropertyChangedSignal("Text"):Connect(renderList)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportCamera)
bindViewportCamera()

-- Launcher placement is handled by resize() so touch devices and narrow desktop windows share one collision-free layout.

print("[PetKingdoms] Pet collection UI loaded.")
