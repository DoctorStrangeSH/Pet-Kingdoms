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

local RequestRunner = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RequestRunner"))
local VirtualList = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VirtualList"))
local PetCollectionQuery = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetCollectionQuery"))
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PetCollectionRequest") :: RemoteFunction

-- Bound every collection request so a stalled RemoteFunction cannot lock the
-- collection UI forever. Mutations carry expectedRevision and are server-checked.
local function invokeCollection(action: string, payload: { [string]: any }?)
	local response = RequestRunner.Invoke(function()
		return table.pack(remote:InvokeServer(action, payload))
	end, 12)
	if not response.ok then
		return false, nil, nil, response.errorCode
	end
	local values = response.value :: { [number]: any, n: number }
	return true, values[1], values[2], nil
end

local InterfaceTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceTheme"))
local InterfaceComponents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceComponents"))
local COLORS = InterfaceTheme.Colors

type PetRecord = { petId: string, speciesId: string, acquiredAt: number, bondXp: number?, bondLevel: number?, isLocked: boolean?, isFavorite: boolean? }
type Collection = { revision: number, owned: { PetRecord }, equipped: { string }, maxEquipped: number }

local collection: Collection? = nil
local selectedPetId: string? = nil
local busy = false
local collectionRefreshing = false
local cardButtons: { [string]: TextButton } = {}
local filteredRecords: { PetRecord } = {}
local renderedWindowStart = 0
local renderedWindowEnd = 0
local searchRenderVersion = 0
local activeFilter = "all"
local sortMode = "newest"
local normalizedSpeciesNames: { [string]: string } = {}

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
	AutomaticCanvasSize = Enum.AutomaticSize.None,
}, panel) :: ScrollingFrame

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
	-- Resolve selection against the authoritative owned collection, not the
	-- filtered list. A selected pet remains selected even when a filter hides it.
	local selected: PetRecord?
	selected, selectedPetId = PetCollectionQuery.ResolveSelection(collection.owned, selectedPetId)
	if selected == nil then
		petName.Text = "Пока пусто"
		petRarity.Text = "КОЛЛЕКЦИЯ"
		petDescription.Text = "Исследуй мир, чтобы найти новых друзей!"
		bondLabel.Text = "ДРУЖБА ПОЯВИТСЯ С ПЕРВЫМ ПИТОМЦЕМ"
		teamLabel.Text = "КОМАНДА: 0 / " .. tostring(collection.maxEquipped)
		favoriteButton.Visible = false
		lockButton.Visible = false
		deleteButton.Visible = false
		mainButton.Visible = false
		equipButton.Visible = false
		interactionRow.Visible = false
		bondLabel.Visible = false
		teamLabel.Visible = false
		preview:ClearAllChildren()
		local placeholder = Instance.new("TextLabel")
		placeholder.Name = "EmptyCollectionPreview"
		placeholder.BackgroundTransparency = 1
		placeholder.Size = UDim2.fromScale(1, 1)
		placeholder.Text = InterfaceTheme.Icons.Pet .. "\nЗдесь появится твой первый друг"
		placeholder.TextWrapped = true
		placeholder.TextColor3 = COLORS.muted
		placeholder.TextSize = 12
		placeholder.Font = Enum.Font.GothamMedium
		placeholder.Parent = preview
		return
	end

	petName.Text = if selected.speciesId == "bunny" then "Зайчик" else selected.speciesId
	favoriteButton.Visible = true
	lockButton.Visible = true
	bondLabel.Visible = true
	teamLabel.Visible = true
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

local PET_CARD_HEIGHT = 68
local PET_CARD_GAP = 9
local PET_CARD_STEP = PET_CARD_HEIGHT + PET_CARD_GAP
local PET_LIST_OVERSCAN = 2

local function clearRenderedCards()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	table.clear(cardButtons)
	renderedWindowStart = 0
	renderedWindowEnd = 0
end

local function renderVisibleCards()
	if collection == nil then return end
	local window = VirtualList.GetWindow(
		#filteredRecords,
		list.CanvasPosition.Y,
		list.AbsoluteWindowSize.Y,
		PET_CARD_STEP,
		PET_LIST_OVERSCAN
	)
	local firstIndex = window.firstIndex
	local lastIndex = window.lastIndex
	if firstIndex == renderedWindowStart and lastIndex == renderedWindowEnd then return end

	-- Reconcile the visible window instead of destroying every card on each
	-- scroll step. Cards in the overlap remain alive; only leaving/entering
	-- records are destroyed/created.
	local wanted: { [string]: boolean } = {}
	for index = firstIndex, lastIndex do
		local record = filteredRecords[index]
		if record then wanted[record.petId] = true end
	end
	for petId, button in pairs(cardButtons) do
		if not wanted[petId] then
			cardButtons[petId] = nil
			button:Destroy()
		end
	end

	renderedWindowStart = firstIndex
	renderedWindowEnd = lastIndex
	for index = firstIndex, lastIndex do
		local record = filteredRecords[index]
		if record == nil then continue end
		local petId = record.petId
		local name = if record.speciesId == "bunny" then "Зайчик" else record.speciesId
		local equipped = isEquipped(petId)
		local button = cardButtons[petId]
		if button == nil then
			button = make("TextButton", {
				Name = "Pet_" .. petId,
				Size = UDim2.new(1, -8, 0, PET_CARD_HEIGHT),
				Text = "",
				AutoButtonColor = true,
			}, list) :: TextButton
			make("UICorner", { CornerRadius = UDim.new(0, 13) }, button)
			make("UIStroke", {
				Name = "CardStroke",
				Color = COLORS.cardSelected,
				Thickness = 1,
				Transparency = 0.25,
			}, button)
			make("TextLabel", {
				Name = "PetIcon",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 5),
				Size = UDim2.fromOffset(46, 54),
				TextSize = 29,
				Font = Enum.Font.Gotham,
				TextColor3 = COLORS.cream,
			}, button)
			make("TextLabel", {
				Name = "PetName",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 66, 0, 12),
				Size = UDim2.new(1, -112, 0, 22),
				TextSize = 14,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextWrapped = false,
				TextColor3 = COLORS.cream,
			}, button)
			make("TextLabel", {
				Name = "PetMeta",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 66, 0, 34),
				Size = UDim2.new(1, -112, 0, 18),
				TextSize = 10,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextWrapped = false,
			}, button)
			button.Activated:Connect(function()
				local previousPetId = selectedPetId
				selectedPetId = petId
				local previousButton = if previousPetId then cardButtons[previousPetId] else nil
				if previousButton then previousButton.BackgroundColor3 = COLORS.card end
				button.BackgroundColor3 = COLORS.cardSelected
				if compactCollection then mobileDetailVisible = true end
				updateDetail()
				resize()
			end)
			cardButtons[petId] = button
		end

		button.Position = UDim2.fromOffset(0, (index - 1) * PET_CARD_STEP)
		button.BackgroundColor3 = if selectedPetId == petId then COLORS.cardSelected else COLORS.card
		local icon = button:FindFirstChild("PetIcon") :: TextLabel?
		local nameLabel = button:FindFirstChild("PetName") :: TextLabel?
		local metaLabel = button:FindFirstChild("PetMeta") :: TextLabel?
		-- Narrow phones have less horizontal room for the icon and labels. Keep
		-- the card readable by reclaiming width and truncating long metadata.
		local narrowCard = list.AbsoluteSize.X < 360
		if icon then
			icon.Position = UDim2.new(0, narrowCard and 8 or 12, 0, 5)
			icon.Size = UDim2.fromOffset(narrowCard and 40 or 46, 54)
			icon.TextSize = narrowCard and 25 or 29
		end
		if nameLabel then
			nameLabel.Position = UDim2.new(0, narrowCard and 56 or 66, 0, 12)
			nameLabel.Size = UDim2.new(1, narrowCard and -68 or -112, 0, 22)
			nameLabel.TextSize = narrowCard and 12 or 14
		end
		if metaLabel then
			metaLabel.Position = UDim2.new(0, narrowCard and 56 or 66, 0, 34)
			metaLabel.Size = UDim2.new(1, narrowCard and -68 or -112, 0, 18)
			metaLabel.TextSize = narrowCard and 9 or 10
		end
		local stroke = button:FindFirstChild("CardStroke") :: UIStroke?
		if icon then icon.Text = if record.speciesId == "bunny" then InterfaceTheme.Icons.Bunny else InterfaceTheme.Icons.Pet end
		if nameLabel then nameLabel.Text = name end
		if metaLabel then
			metaLabel.Text = table.concat({
				if equipped then "В КОМАНДЕ" else "В КОЛЛЕКЦИИ",
				if record.isLocked then InterfaceTheme.Icons.Locked else "",
				if record.isFavorite then InterfaceTheme.Icons.FavoriteOn else "",
			}, "  ")
			metaLabel.TextColor3 = if equipped then COLORS.mint else COLORS.muted
		end
		if stroke then
			local isSelected = selectedPetId == petId
			stroke.Color = if isSelected then COLORS.gold elseif equipped then COLORS.mint else COLORS.cardSelected
			stroke.Thickness = if isSelected then 2.5 else if equipped then 1.5 else 1
			stroke.Transparency = if isSelected then 0.05 else 0.25
		end
	end
end

local function renderList(preserveScroll: boolean?)
	if collection == nil then return end
	local savedCanvasPosition = if preserveScroll then list.CanvasPosition else Vector2.zero
	clearRenderedCards()

	filteredRecords = PetCollectionQuery.Build(
		collection.owned,
		collection.equipped,
		search.Text,
		activeFilter,
		sortMode,
		normalizedSpeciesNames
	)

	local contentHeight = VirtualList.GetContentHeight(#filteredRecords, PET_CARD_STEP, PET_CARD_GAP)
	list.CanvasSize = UDim2.fromOffset(0, contentHeight)
	if preserveScroll then
		list.CanvasPosition = Vector2.new(0, VirtualList.ClampCanvasY(
			savedCanvasPosition.Y,
			contentHeight,
			list.AbsoluteWindowSize.Y
		))
	else
		list.CanvasPosition = Vector2.zero
	end

	if #filteredRecords == 0 then
		local emptyText = if #collection.owned == 0 then "Пока нет питомцев.\nИсследуй остров, чтобы найти первого друга!"
			elseif activeFilter == "favorites" then "Нет избранных питомцев.\nОтметь понравившегося питомца звёздочкой."
			elseif activeFilter == "team" then "Команда пока пуста.\nВыбери питомца и добавь его в команду."
			elseif search.Text ~= "" then "Ничего не найдено.\nПопробуй изменить поисковый запрос."
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
		}, list) :: TextLabel
		InterfaceComponents.StyleEmptyState(empty, if #collection.owned == 0 then InterfaceTheme.Icons.Pet else InterfaceTheme.Icons.Search)
	else
		renderVisibleCards()
	end
	allFilterButton.BackgroundColor3 = if activeFilter == "all" then COLORS.cardSelected else COLORS.panelSoft
	teamFilterButton.BackgroundColor3 = if activeFilter == "team" then COLORS.cardSelected else COLORS.panelSoft
	favoriteFilterButton.BackgroundColor3 = if activeFilter == "favorites" then COLORS.cardSelected else COLORS.panelSoft
	sortButton.Text = if sortMode == "newest" then "НОВЫЕ" elseif sortMode == "name" then "ИМЯ" else "ДРУЖБА"
end

list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	if #filteredRecords > 0 then renderVisibleCards() end
end)

list:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if #filteredRecords > 0 then renderVisibleCards() end
end)


local function refreshCollection()
	-- Collection reads are single-flight. Multiple opens/refreshes must not race
	-- and let an older snapshot overwrite a newer server response.
	if collectionRefreshing or busy then return false end
	collectionRefreshing = true
	local requestResult = RequestRunner.Invoke(function()
		return table.pack(remote:InvokeServer("Get"))
	end, 12)
	collectionRefreshing = false

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
	-- Keep the selected identity when possible; only choose a fallback when
	-- the server confirms that the previously selected pet is no longer owned.
	local _, resolvedSelectedPetId = PetCollectionQuery.ResolveSelection(collection.owned, selectedPetId)
	selectedPetId = resolvedSelectedPetId
	if panel.Visible then
		renderList()
		updateDetail()
	end
	return true
end

local function setMainPet()
	if busy or collectionRefreshing or collection == nil or selectedPetId == nil then return end
	local currentIndex = table.find(collection.equipped, selectedPetId)
	if currentIndex == nil then
		showStatus("Сначала добавь питомца в команду.", true)
		return
	end
	if currentIndex == 1 then return end

	busy = true
	InterfaceComponents.SetButtonLoading(mainButton, true, "СОХРАНЯЕМ...")
	local nextEquipped = table.clone(collection.equipped)
	table.remove(nextEquipped, currentIndex)
	table.insert(nextEquipped, 1, selectedPetId)
	local ok, success, result, requestError = invokeCollection("Equip", {
		petIds = nextEquipped,
		expectedRevision = collection.revision,
	})
	busy = false
	InterfaceComponents.SetButtonLoading(mainButton, false)
	if not ok or success ~= true or type(result) ~= "table" then
		showStatus(if requestError == "TIMEOUT" then "Сервер отвечает слишком долго. Проверяю состояние команды..." else "Не удалось сменить главного питомца. Обновляю данные...", true)
		refreshCollection()
		return
	end
	collection = result :: Collection
	renderList(true)
	updateDetail()
	showStatus("Главный питомец изменён!")
end

local function toggleEquip()
	if busy or collectionRefreshing or collection == nil or selectedPetId == nil then return end
	busy = true
	InterfaceComponents.SetButtonLoading(equipButton, true, "СОХРАНЯЕМ...")
	local nextEquipped = table.clone(collection.equipped)
	local currentIndex = table.find(nextEquipped, selectedPetId)
	if currentIndex then
		table.remove(nextEquipped, currentIndex)
	elseif #nextEquipped < collection.maxEquipped then
		table.insert(nextEquipped, selectedPetId)
	else
		showStatus("Можно выбрать не больше трёх питомцев.", true)
		busy = false
		InterfaceComponents.SetButtonLoading(equipButton, false)
		updateDetail()
		return
	end

	local ok, success, result, requestError = invokeCollection("Equip", {
		petIds = nextEquipped,
		expectedRevision = collection.revision,
	})
	busy = false
	InterfaceComponents.SetButtonLoading(equipButton, false)
	if not ok or success ~= true or type(result) ~= "table" then
		showStatus(if requestError == "TIMEOUT" then "Сервер отвечает слишком долго. Проверяю состояние команды..." else "Не удалось изменить команду. Обновляю данные...", true)
		refreshCollection()
		return
	end
	collection = result :: Collection
	renderList(true)
	updateDetail()
	showStatus("Команда сохранена!")
end


local function interactWithSelected(interactionType: string)
	if busy or collectionRefreshing or collection == nil or selectedPetId == nil then return end
	busy = true
	InterfaceComponents.SetButtonLoading(petButton, true, "...")
	InterfaceComponents.SetButtonLoading(playButton, true, "...")
	local ok, success, result, requestError = invokeCollection("Interact", {
		petId = selectedPetId,
		interactionType = interactionType,
		expectedRevision = collection.revision,
	})
	busy = false
	InterfaceComponents.SetButtonLoading(petButton, false)
	InterfaceComponents.SetButtonLoading(playButton, false)
	if not ok or success ~= true or type(result) ~= "table" then
		local reason = if ok and type(result) == "string" then result else "UNKNOWN"
		local messages = {
			INTERACTION_COOLDOWN = "Питомцу нужно немного отдохнуть. Попробуй позже.",
			REQUEST_RATE_LIMITED = "Подожди секунду перед следующим действием.",
			STALE_REVISION = "Данные коллекции обновились. Загружаю изменения...",
			DATASTORE_UNAVAILABLE = "Не удалось сохранить дружбу. Проверь соединение и попробуй позже.",
			COLLECTION_NOT_READY = "Коллекция ещё загружается. Попробуй немного позже.",
		}
		showStatus(if requestError == "TIMEOUT" then "Сервер отвечает слишком долго. Проверяю состояние питомца..." else (messages[reason] or "Не удалось выполнить действие. Обновляю данные..."), true)
		refreshCollection()
		return
	end
	collection = result :: Collection
	renderList(true)
	updateDetail()
	showStatus(if interactionType == "pet" then "Питомцу приятно! +10 дружбы" else "Вы отлично провели время! +10 дружбы")
end

local function updatePetFlags(isFavorite: boolean, isLocked: boolean)
	if busy or collectionRefreshing or collection == nil or selectedPetId == nil then return end
	busy = true
	InterfaceComponents.SetButtonLoading(favoriteButton, true, "...")
	InterfaceComponents.SetButtonLoading(lockButton, true, "...")
	local ok, success, result, requestError = invokeCollection("Protect", {
		petId = selectedPetId,
		isFavorite = isFavorite,
		isLocked = isLocked,
		expectedRevision = collection.revision,
	})
	busy = false
	InterfaceComponents.SetButtonLoading(favoriteButton, false)
	InterfaceComponents.SetButtonLoading(lockButton, false)
	if not ok or success ~= true or type(result) ~= "table" then
		local reason = if ok and type(result) == "string" then result else "UNKNOWN"
		showStatus(if requestError == "TIMEOUT" then "Сервер отвечает слишком долго. Проверяю настройки питомца..." elseif reason == "STALE_REVISION" then "Коллекция обновилась. Загружаю..." else "Не удалось сохранить настройки питомца.", true)
		refreshCollection()
		return
	end
	collection = result :: Collection
	renderList(true)
	updateDetail()
	showStatus("Настройки питомца сохранены.")
end

local function requestDeleteSelected()
	if busy or collectionRefreshing or collection == nil or selectedPetId == nil then return end
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
	local petName = if selected.speciesId == "bunny" then "Зайчик" else selected.speciesId
	confirmMessage.Text = string.format("«%s» будет навсегда удалён из коллекции. Это действие нельзя отменить.", petName)
	confirmPanel.Visible = true
end

local function confirmDeleteSelected()
	if busy or collectionRefreshing or collection == nil or pendingDeletePetId == nil then return end
	busy = true
	InterfaceComponents.SetButtonLoading(confirmDeleteButton, true, "УДАЛЯЕМ...")
	InterfaceComponents.SetButtonLoading(cancelDeleteButton, true, "ПОДОЖДИ...")
	local deleteTargetPetId = pendingDeletePetId
	local ok, success, result, requestError = invokeCollection("Delete", {
		petId = deleteTargetPetId,
		expectedRevision = collection.revision,
	})
	busy = false
	InterfaceComponents.SetButtonLoading(confirmDeleteButton, false)
	InterfaceComponents.SetButtonLoading(cancelDeleteButton, false)
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
		showStatus(if requestError == "TIMEOUT" then "Сервер отвечает слишком долго. Проверяю результат удаления..." else (messages[reason] or "Не удалось удалить питомца. Обновляю коллекцию..."), true)
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
	local veryShort = viewport.Y < 360
	local launcherSize = if veryShort then 44 elseif launcherCompact then 52 else 62
	openButton.Size = UDim2.fromOffset(launcherSize, launcherSize)
	openButton.Position = UDim2.new(1, launcherCompact and -12 or -22, if veryShort then 0.52 elseif launcherCompact then 0.46 else 0.55, 0)
	if compactCollection then
		if veryShort then
			-- Dedicated landscape layout: the previous portrait coordinates placed
			-- the list below the bottom edge on 180–300 px tall displays.
			panel.Size = UDim2.new(0.96, 0, 1, -12)
			panelScale.Scale = 1
			title.Position = UDim2.fromOffset(12, 5)
			title.Size = UDim2.new(1, -92, 0, 22)
			title.TextSize = 15
			subtitle.Visible = false
			closeButton.Position = UDim2.new(1, -8, 0, 4)
			closeButton.Size = UDim2.fromOffset(30, 30)
			closeButton.TextSize = 18
			local contentWidth = math.max(160, math.floor(viewport.X * 0.96) - 36)
			search.Position = UDim2.fromOffset(12, 32)
			search.Size = UDim2.fromOffset(contentWidth, 30)
			search.TextSize = 12
			filterBar.Position = UDim2.fromOffset(12, 66)
			filterBar.Size = UDim2.fromOffset(contentWidth, 28)
			list.Position = UDim2.fromOffset(12, 98)
			list.Size = UDim2.new(1, -24, 1, -110)
			list.ScrollBarThickness = 3
			mobileBackButton.Position = UDim2.fromOffset(12, 32)
			mobileBackButton.Size = UDim2.new(1, -24, 0, 26)
			mobileBackButton.TextSize = 10
			mobileBackButton.Visible = mobileDetailVisible
			list.Visible = not mobileDetailVisible
			search.Visible = not mobileDetailVisible
			filterBar.Visible = not mobileDetailVisible
			detail.Position = UDim2.fromOffset(12, 64)
			detail.Size = UDim2.new(1, -24, 1, -76)
			detail.Visible = mobileDetailVisible
			if mobileDetailVisible then
				preview.Position = UDim2.fromOffset(6, 6)
				preview.Size = UDim2.new(0.28, -6, 0, 40)
				petName.Position = UDim2.new(0.30, 0, 0, 5)
				petName.Size = UDim2.new(0.70, -12, 0, 20)
				petName.TextSize = 13
				petRarity.Position = UDim2.new(0.30, 0, 0, 25)
				petRarity.Size = UDim2.new(0.70, -12, 0, 14)
				petRarity.TextSize = 8
				favoriteButton.Visible = false
				lockButton.Visible = false
				petDescription.Visible = false
				bondLabel.Visible = false
				teamLabel.Visible = false
				interactionRow.Visible = false
				equipButton.Position = UDim2.new(0, 6, 1, -36)
				equipButton.Size = UDim2.new(0.50, -9, 0, 30)
				equipButton.TextSize = 9
				mainButton.Position = UDim2.new(0.50, 2, 1, -36)
				mainButton.Size = UDim2.new(0.22, -4, 0, 30)
				deleteButton.Position = UDim2.new(0.72, 4, 1, -36)
				deleteButton.Size = UDim2.new(0.28, -10, 0, 30)
				deleteButton.TextSize = 8
			else
				favoriteButton.Visible = false
				lockButton.Visible = false
				petDescription.Visible = false
				bondLabel.Visible = false
				teamLabel.Visible = false
				interactionRow.Visible = false
			end
		else
			subtitle.Visible = true
			closeButton.Position = UDim2.new(1, -16, 0, 14)
			closeButton.Size = UDim2.fromOffset(40, 40)
			closeButton.TextSize = 24
			-- Give the mobile detail view as much vertical room as the viewport allows.
			panel.Size = UDim2.new(0.94, 0, 0.90, 0)
		panelScale.Scale = 1
		local contentWidth = math.max(180, math.floor(viewport.X * 0.94) - 48)
		search.Position = UDim2.fromOffset(24, 88)
		search.Size = UDim2.fromOffset(contentWidth, 38)
		filterBar.Position = UDim2.fromOffset(24, 132)
		filterBar.Size = UDim2.fromOffset(contentWidth, 32)
		list.Position = UDim2.fromOffset(24, 172)
		list.Size = UDim2.new(1, -48, 1, -196)
		list.ScrollBarThickness = 5
		mobileBackButton.Visible = mobileDetailVisible
		list.Visible = not mobileDetailVisible
		search.Visible = not mobileDetailVisible
		filterBar.Visible = not mobileDetailVisible
		detail.Position = UDim2.fromOffset(24, if mobileDetailVisible then 130 else 172)
		detail.Size = UDim2.new(1, -48, 1, if mobileDetailVisible then -150 else -196)
		detail.Visible = mobileDetailVisible

		if mobileDetailVisible then
			-- A compact two-column summary avoids stacking the desktop preview,
			-- description, team and interaction rows on top of one another.
			preview.Position = UDim2.fromOffset(8, 8)
			preview.Size = UDim2.new(0.34, -8, 0, 54)
			petName.Position = UDim2.new(0.36, 0, 0, 8)
			petName.Size = UDim2.new(0.64, -16, 0, 22)
			petName.TextSize = 16
			petRarity.Position = UDim2.new(0.36, 0, 0, 31)
			petRarity.Size = UDim2.new(0.64, -16, 0, 16)
			petRarity.TextSize = 9
			favoriteButton.Position = UDim2.fromOffset(8, 68)
			lockButton.Position = UDim2.fromOffset(50, 68)
			favoriteButton.Size = UDim2.fromOffset(36, 34)
			lockButton.Size = UDim2.fromOffset(36, 34)

			if viewport.Y >= 500 then
				-- On normal-height phones keep useful pet information and care
				-- actions visible instead of leaving a large empty detail area.
				petDescription.Visible = true
				petDescription.Position = UDim2.fromOffset(8, 98)
				petDescription.Size = UDim2.new(1, -16, 0, 40)
				petDescription.TextSize = 11
				bondLabel.Position = UDim2.fromOffset(8, 142)
				bondLabel.Size = UDim2.new(1, -16, 0, 18)
				bondLabel.TextSize = 10
				teamLabel.Visible = true
				teamLabel.Position = UDim2.fromOffset(8, 164)
				teamLabel.Size = UDim2.new(1, -16, 0, 18)
				teamLabel.TextSize = 10
				interactionRow.Visible = true
				interactionRow.Position = UDim2.fromOffset(8, 190)
				interactionRow.Size = UDim2.new(1, -16, 0, 38)
			else
				petDescription.Visible = false
				bondLabel.Position = UDim2.new(0.36, 0, 0, 50)
				bondLabel.Size = UDim2.new(0.64, -16, 0, 18)
				bondLabel.TextSize = 9
				teamLabel.Visible = false
				interactionRow.Visible = false
			end
			equipButton.Position = UDim2.new(0, 8, 1, -42)
			equipButton.Size = UDim2.new(0.50, -12, 0, 34)
			equipButton.TextSize = 10
			mainButton.Position = UDim2.new(0.50, 2, 1, -42)
			mainButton.Size = UDim2.new(0.18, -4, 0, 34)
			deleteButton.Position = UDim2.new(0.68, 4, 1, -42)
			deleteButton.Size = UDim2.new(0.32, -12, 0, 34)
			deleteButton.TextSize = 9
		else
			petDescription.Visible = true
			teamLabel.Visible = true
			interactionRow.Visible = true
			favoriteButton.Visible = true
			lockButton.Visible = true
		end
		end
	else
		subtitle.Visible = true
		closeButton.Position = UDim2.new(1, -16, 0, 14)
		closeButton.Size = UDim2.fromOffset(40, 40)
		closeButton.TextSize = 24
		favoriteButton.Visible = true
		lockButton.Visible = true
		petDescription.Visible = true
		teamLabel.Visible = true
		interactionRow.Visible = true
		preview.Position = UDim2.new(0, 10, 0, 10)
		preview.Size = UDim2.new(1, -20, 0.53, -10)
		petName.Position = UDim2.new(0, 16, 0.55, 0)
		petName.Size = UDim2.new(1, -112, 0, 30)
		petName.TextSize = 21
		petRarity.Position = UDim2.new(0, 16, 0.55, 31)
		petRarity.Size = UDim2.new(1, -32, 0, 22)
		petRarity.TextSize = 10
		petDescription.Position = UDim2.new(0, 16, 0.55, 57)
		petDescription.Size = UDim2.new(1, -32, 0, 44)
		petDescription.TextSize = 12
		favoriteButton.Position = UDim2.new(1, -88, 0.55, 0)
		favoriteButton.Size = UDim2.fromOffset(34, 30)
		lockButton.Position = UDim2.new(1, -48, 0.55, 0)
		lockButton.Size = UDim2.fromOffset(34, 30)
		teamLabel.Position = UDim2.new(0, 16, 1, -145)
		teamLabel.Size = UDim2.new(1, -32, 0, 22)
		bondLabel.Position = UDim2.new(0, 16, 0.55, 103)
		bondLabel.Size = UDim2.new(1, -32, 0, 22)
		interactionRow.Position = UDim2.new(0, 14, 1, -104)
		interactionRow.Size = UDim2.new(1, -28, 0, 38)
		equipButton.Position = UDim2.new(0, 14, 1, -58)
		equipButton.Size = UDim2.new(0.50, -18, 0, 46)
		equipButton.TextSize = 14
		mainButton.Position = UDim2.new(0.50, 1, 1, -58)
		mainButton.Size = UDim2.new(0.18, -2, 0, 46)
		deleteButton.Position = UDim2.new(0.68, 2, 1, -58)
		deleteButton.Size = UDim2.new(0.32, -16, 0, 46)
		deleteButton.TextSize = 12
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
	-- Larger hit areas on compact screens; UIScale keeps the dialog inside
	-- very short landscape viewports without pushing actions off-screen.
	cancelDeleteButton.Size = UDim2.new(0.5, -22, 0, if compactCollection then 50 else 38)
	confirmDeleteButton.Size = UDim2.new(0.5, -22, 0, if compactCollection then 50 else 38)

	-- Resize can run after an empty collection was rendered. Re-apply the
	-- empty-state visibility rules so layout changes never resurrect dead actions.
	if collection ~= nil and #collection.owned == 0 then
		favoriteButton.Visible = false
		lockButton.Visible = false
		deleteButton.Visible = false
		mainButton.Visible = false
		equipButton.Visible = false
		interactionRow.Visible = false
		bondLabel.Visible = false
		teamLabel.Visible = false
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
		if busy then return end
		pendingDeletePetId = nil
		confirmPanel.Visible = false
	elseif panel.Visible then
		closeCollection()
	end
end)

shade.Activated:Connect(function()
	if confirmPanel.Visible then
		if busy then return end
		pendingDeletePetId = nil
		confirmPanel.Visible = false
	elseif panel.Visible then
		closeCollection()
	end
end)

openButton.Activated:Connect(openCollection)
allFilterButton.Activated:Connect(function() activeFilter = "all" renderList(true) end)
teamFilterButton.Activated:Connect(function() activeFilter = "team" renderList(true) end)
favoriteFilterButton.Activated:Connect(function() activeFilter = "favorites" renderList(true) end)
sortButton.Activated:Connect(function()
	sortMode = if sortMode == "newest" then "name" elseif sortMode == "name" then "bond" else "newest"
	renderList(true)
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
	if busy then return end
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
search:GetPropertyChangedSignal("Text"):Connect(function()
	searchRenderVersion += 1
	local version = searchRenderVersion
	-- Coalesce fast typing into one list update after the user pauses briefly.
	task.delay(0.12, function()
		if version ~= searchRenderVersion or not screen.Parent then return end
		renderList()
	end)
end)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportCamera)
bindViewportCamera()

-- Launcher placement is handled by resize() so touch devices and narrow desktop windows share one collision-free layout.

print("[PetKingdoms] Pet collection UI loaded.")
