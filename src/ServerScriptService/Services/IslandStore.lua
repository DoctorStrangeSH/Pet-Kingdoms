--!strict
-- DataStore adapter with DataStore-side session fencing.
-- The session generation is incremented atomically on claim and checked
-- inside every profile-writing UpdateAsync transform.
local DataStoreService = game:GetService("DataStoreService")

local IslandData = require(script.Parent:WaitForChild("IslandData"))
local BuildingCatalog = require(script.Parent:WaitForChild("BuildingCatalog"))
local IslandResources = require(script.Parent:WaitForChild("IslandResources"))
local QuestProgressData = require(script.Parent:WaitForChild("QuestProgressData"))
local IslandStoreConcurrencyData = require(script.Parent:WaitForChild("IslandStoreConcurrencyData"))

local IslandStore = {}
local STORE_NAME = "PetKingdoms_Islands_v1"
local MAX_ATTEMPTS = 4
local BASE_RETRY_DELAY = 1
local store = DataStoreService:GetDataStore(STORE_NAME)

local function makeKey(userId: number): string
	return "player_" .. tostring(userId)
end

local function isValidUserId(userId: number): boolean
	return type(userId) == "number" and userId == userId
		and userId ~= math.huge and userId ~= -math.huge
		and userId > 0 and userId == math.floor(userId)
end

local function retry<T>(operation: () -> T): (boolean, T?)
	local lastError: any = nil
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(operation)
		if ok then return true, result end
		lastError = result
		if attempt < MAX_ATTEMPTS then
			task.wait(BASE_RETRY_DELAY * (2 ^ (attempt - 1)))
		end
	end
	warn("[PetKingdoms] Island DataStore operation failed after retries:", lastError)
	return false, nil
end

function IslandStore.load(userId: number): (boolean, any, string)
	if not isValidUserId(userId) then return false, nil, "INVALID_USER_ID" end
	local ok, data = retry(function()
		return store:GetAsync(makeKey(userId))
	end)
	if not ok then return false, nil, "DATASTORE_UNAVAILABLE" end
	if data == nil then return true, nil, "NOT_FOUND" end
	local valid, reason = IslandData.validate(data, userId, BuildingCatalog)
	if not valid then
		warn(string.format("[PetKingdoms] Invalid island profile for user %d: %s", userId, reason))
		return false, nil, "INVALID_SAVED_PROFILE:" .. reason
	end
	if data.expansionLevel == nil then
		-- Legacy schema-v1 islands start at the original, unexpanded plot.
		data.expansionLevel = 0
	end
	if data.resources == nil then
		-- Backward-compatible migration for schema-v1 islands created before
		-- the wallet field existed. claimSession persists this migrated value.
		data.resources = IslandResources.create()
	end
	if data.buildingOperations == nil then
		-- Legacy profiles start with an empty durable construction receipt ledger.
		data.buildingOperations = {}
	end
	if data.resourceNodes == nil then
		-- Legacy profiles start with all canonical resource nodes available.
		data.resourceNodes = {}
	end
	if data.questProgress == nil then
		data.questProgress = QuestProgressData.create()
	end
	if data.trackedQuestId == nil then
		data.trackedQuestId = "gather_wood"
	end
	return true, data, "LOADED"
end

-- Atomically claims the next monotonically increasing generation in the
-- same DataStore key as the profile. The returned profile is the only
-- generation allowed to write until a later claim increments it.
function IslandStore.claimSession(profile: any): (boolean, any, string)
	if type(profile) ~= "table" or not isValidUserId(profile.ownerUserId) then
		return false, nil, "INVALID_PROFILE"
	end
	local valid, reason = IslandData.validate(profile, profile.ownerUserId, BuildingCatalog)
	if not valid then return false, nil, "INVALID_PROFILE:" .. reason end

	local key = makeKey(profile.ownerUserId)
	local seed = table.clone(profile)
	if seed.expansionLevel == nil then
		seed.expansionLevel = 0
	end
	if seed.resources == nil then
		seed.resources = IslandResources.create()
	end
	if seed.buildingOperations == nil then
		seed.buildingOperations = {}
	end
	if seed.resourceNodes == nil then
		seed.resourceNodes = {}
	end
	if seed.questProgress == nil then
		seed.questProgress = QuestProgressData.create()
	end
	if seed.trackedQuestId == nil then
		seed.trackedQuestId = "gather_wood"
	end
	-- Claim only if the generation observed during load is still current.
	-- This prevents a delayed loader from superseding a newer session.
	local expectedGeneration = seed.sessionGeneration or 0
	local claimed = false
	local ok, result = retry(function()
		claimed = false
		return store:UpdateAsync(key, function(current)
			claimed = false
			local nextProfile
			if current == nil then
				if expectedGeneration ~= 0 then
					return nil
				end
				nextProfile = table.clone(seed)
			else
				local currentValid = IslandData.validate(current, seed.ownerUserId, BuildingCatalog)
				if not currentValid then return current end
				nextProfile = table.clone(current)
			end

			if nextProfile.expansionLevel == nil then
				nextProfile.expansionLevel = 0
			end
			if nextProfile.resources == nil then
				nextProfile.resources = IslandResources.create()
			end
			if nextProfile.buildingOperations == nil then
				nextProfile.buildingOperations = {}
			end
			if nextProfile.resourceNodes == nil then
				nextProfile.resourceNodes = {}
			end
			if nextProfile.questProgress == nil then
				nextProfile.questProgress = QuestProgressData.create()
			end
			if nextProfile.trackedQuestId == nil then
				nextProfile.trackedQuestId = "gather_wood"
			end
			local nextGeneration = IslandStoreConcurrencyData.nextSessionGeneration(
				nextProfile.sessionGeneration,
				expectedGeneration
			)
			if nextGeneration == nil then
				return current
			end
			nextProfile.sessionGeneration = nextGeneration
			claimed = true
			return nextProfile
		end)
	end)
	if not ok then return false, nil, "DATASTORE_UNAVAILABLE" end
	if not claimed or type(result) ~= "table" then
		return false, nil, "SESSION_CLAIM_REJECTED"
	end
	local resultValid, resultReason = IslandData.validate(result, profile.ownerUserId, BuildingCatalog)
	if not resultValid then return false, nil, "INVALID_CLAIMED_PROFILE:" .. resultReason end
	return true, result, "CLAIMED"
end

function IslandStore.save(profile: any): (boolean, string)
	if type(profile) ~= "table" or not isValidUserId(profile.ownerUserId) then
		return false, "INVALID_PROFILE"
	end
	local valid, reason = IslandData.validate(profile, profile.ownerUserId, BuildingCatalog)
	if not valid then return false, "INVALID_PROFILE:" .. reason end
	if type(profile.sessionGeneration) ~= "number" or profile.sessionGeneration < 1
		or profile.sessionGeneration ~= math.floor(profile.sessionGeneration)
	then
		return false, "INVALID_SESSION_GENERATION"
	end

	local key = makeKey(profile.ownerUserId)
	local snapshot = table.clone(profile)
	local snapshotDurable = false
	local ok, result = retry(function()
		snapshotDurable = false
		return store:UpdateAsync(key, function(current)
			snapshotDurable = false
			if type(current) ~= "table" then return current end
			-- Fencing check is atomic with the profile write. A stale server's
			-- generation can never overwrite a newer claimed generation.
			local disposition = IslandStoreConcurrencyData.classifySave(
				current.sessionGeneration,
				current.revision,
				snapshot.sessionGeneration,
				snapshot.revision
			)
			if disposition == "ALREADY_DURABLE" then
				-- An earlier retry may have committed this snapshot but lost its
				-- acknowledgement. A newer revision from the same generation also
				-- proves this revision was durably superseded.
				snapshotDurable = true
				return current
			end
			if disposition ~= "WRITE" then return current end
			snapshotDurable = true
			return snapshot
		end)
	end)
	if not ok then return false, "DATASTORE_UNAVAILABLE" end
	if not snapshotDurable or type(result) ~= "table"
		or type(result.revision) ~= "number" or result.revision < snapshot.revision
		or result.sessionGeneration ~= snapshot.sessionGeneration
	then
		return false, "STALE_SESSION_OR_REVISION"
	end
	return true, "SAVED"
end

return IslandStore
