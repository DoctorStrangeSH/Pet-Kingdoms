--!strict
-- Server-authoritative pet collection loading and equip requests.
-- Pet ownership and equipped IDs are never accepted from client-provided profile data.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local sharedPets = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets")
local PetCollectionData = require(sharedPets:WaitForChild("PetCollectionData"))
local PetModelFactory = require(sharedPets:WaitForChild("PetModelFactory"))

local PetCollectionService = {}
local STORE_NAME = "PetKingdoms_PetCollections_v1"
local MAX_ATTEMPTS = 4
local store = DataStoreService:GetDataStore(STORE_NAME)

type PlayerCollection = {
	profile: any,
	loading: boolean,
}

local collections: { [number]: PlayerCollection } = {}
local remote: RemoteFunction? = nil
local characterConnections: { [number]: RBXScriptConnection } = {}

local function keyFor(userId: number): string
	return "player_" .. tostring(userId)
end

local function cloneForClient(profile: any): any
	return {
		schemaVersion = profile.schemaVersion,
		revision = profile.revision,
		owned = table.clone(profile.owned),
		equipped = table.clone(profile.equipped),
		maxEquipped = PetCollectionData.MAX_EQUIPPED_PETS,
	}
end

local function updateWithRetry(userId: number, transform: (any) -> any): (boolean, any)
	local lastError = nil
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(function()
			return store:UpdateAsync(keyFor(userId), transform)
		end)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < MAX_ATTEMPTS then
			task.wait(0.5 * (2 ^ (attempt - 1)))
		end
	end
	warn("[PetKingdoms] Pet collection DataStore failed:", userId, lastError)
	return false, nil
end


local function getPlayerPetFolder(player: Player): Folder
	local root = Workspace:FindFirstChild("PlayerPets")
	if root == nil then
		root = Instance.new("Folder")
		root.Name = "PlayerPets"
		root.Parent = Workspace
	end
	local playerFolder = root:FindFirstChild(tostring(player.UserId))
	if playerFolder == nil then
		playerFolder = Instance.new("Folder")
		playerFolder.Name = tostring(player.UserId)
		playerFolder.Parent = root
	end
	return playerFolder :: Folder
end

local function clearSpawnedPets(player: Player)
	local root = Workspace:FindFirstChild("PlayerPets")
	local playerFolder = root and root:FindFirstChild(tostring(player.UserId))
	if playerFolder then
		playerFolder:Destroy()
	end
end

local function spawnEquippedPets(player: Player)
	local state = collections[player.UserId]
	local character = player.Character
	local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
	if state == nil or state.loading or state.profile == nil or targetRoot == nil or not targetRoot:IsA("BasePart") then
		return
	end

	clearSpawnedPets(player)
	local playerFolder = getPlayerPetFolder(player)
	for slotIndex, petId in ipairs(state.profile.equipped) do
		local record = nil
		for _, ownedRecord in ipairs(state.profile.owned) do
			if ownedRecord.petId == petId then
				record = ownedRecord
				break
			end
		end
		if record then
			local petModel, status = PetModelFactory.create(record.speciesId, 1)
			if petModel and status == "CREATED" then
				petModel.Name = petId
				petModel:SetAttribute("PetId", petId)
				petModel:SetAttribute("OwnerUserId", player.UserId)
				petModel:SetAttribute("FormationSlot", slotIndex)
				petModel.Parent = playerFolder
				petModel:PivotTo((targetRoot :: BasePart).CFrame * CFrame.new((slotIndex - 2) * 2.4, 0, 4.5))
			else
				warn("[PetKingdoms] Could not create equipped pet", petId, status)
			end
		end
	end
end

local function loadPlayer(player: Player)
	local userId = player.UserId
	if collections[userId] then
		return
	end
	collections[userId] = { profile = nil, loading = true }

	local ok, result = updateWithRetry(userId, function(current)
		if current == nil then
			return PetCollectionData.createDefault(userId)
		end
		return current
	end)

	local state = collections[userId]
	if state == nil or player.Parent ~= Players then
		collections[userId] = nil
		return
	end
	if not ok or type(result) ~= "table" then
		collections[userId] = nil
		warn("[PetKingdoms] Pet collection unavailable for", player.Name)
		return
	end

	local valid, reason = PetCollectionData.validate(result, userId)
	if not valid then
		collections[userId] = nil
		warn("[PetKingdoms] Invalid pet collection for", userId, reason)
		return
	end

	state.profile = result
	state.loading = false
	spawnEquippedPets(player)
	if characterConnections[userId] then
		characterConnections[userId]:Disconnect()
	end
	characterConnections[userId] = player.CharacterAdded:Connect(function()
		task.delay(0.75, function()
			spawnEquippedPets(player)
		end)
	end)
	print("[PetKingdoms] Pet collection ready for", player.Name)
end

local function handleRequest(player: Player, action: any, payload: any): (boolean, any)
	local state = collections[player.UserId]
	if state == nil or state.loading or state.profile == nil then
		return false, "COLLECTION_NOT_READY"
	end

	if action == "Get" then
		return true, cloneForClient(state.profile)
	end

	if action ~= "Equip" then
		return false, "UNKNOWN_ACTION"
	end
	if type(payload) ~= "table" or type(payload.petIds) ~= "table"
		or type(payload.expectedRevision) ~= "number"
		or payload.expectedRevision ~= math.floor(payload.expectedRevision)
	then
		return false, "INVALID_REQUEST"
	end
	if payload.expectedRevision ~= state.profile.revision then
		return false, "STALE_REVISION"
	end

	local requestedIds = table.clone(payload.petIds)
	local updatedProfile: any = nil
	local mutationStatus = "NOT_UPDATED"
	local ok, result = updateWithRetry(player.UserId, function(current)
		if type(current) ~= "table" then
			mutationStatus = "PROFILE_MISSING"
			return current
		end
		local valid, reason = PetCollectionData.validate(current, player.UserId)
		if not valid then
			mutationStatus = "INVALID_SAVED_PROFILE:" .. reason
			return current
		end
		if current.revision ~= payload.expectedRevision then
			mutationStatus = "STALE_REVISION"
			return current
		end
		local changed, status, nextProfile = PetCollectionData.setEquipped(current, requestedIds)
		if not changed then
			mutationStatus = status
			return current
		end
		updatedProfile = nextProfile
		mutationStatus = status
		return nextProfile
	end)

	if not ok then
		return false, "DATASTORE_UNAVAILABLE"
	end
	if mutationStatus ~= "UPDATED" or type(result) ~= "table" or updatedProfile == nil then
		return false, mutationStatus
	end

	local valid, reason = PetCollectionData.validate(result, player.UserId)
	if not valid then
		warn("[PetKingdoms] Equip result invalid:", player.UserId, reason)
		return false, "INVALID_SAVE_RESULT"
	end

	state.profile = result
	spawnEquippedPets(player)
	return true, cloneForClient(result)
end

function PetCollectionService.start()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes == nil then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	local collectionRemote = Instance.new("RemoteFunction")
	collectionRemote.Name = "PetCollectionRequest"
	collectionRemote.OnServerInvoke = handleRequest
	collectionRemote.Parent = remotes
	remote = collectionRemote

	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadPlayer, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		if characterConnections[player.UserId] then
			characterConnections[player.UserId]:Disconnect()
			characterConnections[player.UserId] = nil
		end
		clearSpawnedPets(player)
		collections[player.UserId] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadPlayer, player)
	end
end

return PetCollectionService
