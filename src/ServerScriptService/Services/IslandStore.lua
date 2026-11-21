--!strict
-- DataStore adapter for compact island profiles.
-- Call only from server scripts. This module never spawns world Instances.
-- Save uses revision-aware UpdateAsync to prevent an older server snapshot overwriting newer data.

local DataStoreService = game:GetService("DataStoreService")

local IslandData = require(script.Parent:WaitForChild("IslandData"))
local BuildingCatalog = require(script.Parent:WaitForChild("BuildingCatalog"))

local IslandStore = {}

local STORE_NAME = "PetKingdoms_Islands_v1"
local MAX_ATTEMPTS = 4
local BASE_RETRY_DELAY = 1

local store = DataStoreService:GetDataStore(STORE_NAME)

local function makeKey(userId: number): string
	return "player_" .. tostring(userId)
end

local function isValidUserId(userId: number): boolean
	return type(userId) == "number"
		and userId == userId
		and userId ~= math.huge
		and userId ~= -math.huge
		and userId > 0
		and userId == math.floor(userId)
end

local function retry<T>(operation: () -> T): (boolean, T?)
	local lastError: any = nil

	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end

		lastError = result
		if attempt < MAX_ATTEMPTS then
			task.wait(BASE_RETRY_DELAY * (2 ^ (attempt - 1)))
		end
	end

	warn("[PetKingdoms] Island DataStore operation failed after retries:", lastError)
	return false, nil
end

function IslandStore.load(userId: number): (boolean, any, string)
	if not isValidUserId(userId) then
		return false, nil, "INVALID_USER_ID"
	end

	local ok, data = retry(function()
		return store:GetAsync(makeKey(userId))
	end)

	if not ok then
		return false, nil, "DATASTORE_UNAVAILABLE"
	end

	if data == nil then
		return true, nil, "NOT_FOUND"
	end

	local valid, reason = IslandData.validate(data, userId, BuildingCatalog)
	if not valid then
		warn(string.format(
			"[PetKingdoms] Quarantining invalid island profile for user %d: %s",
			userId,
			reason
		))
		return false, nil, "INVALID_SAVED_PROFILE:" .. reason
	end

	return true, data, "LOADED"
end

function IslandStore.save(profile: any): (boolean, string)
	if type(profile) ~= "table" or not isValidUserId(profile.ownerUserId) then
		return false, "INVALID_PROFILE"
	end

	local valid, reason = IslandData.validate(profile, profile.ownerUserId, BuildingCatalog)
	if not valid then
		return false, "INVALID_PROFILE:" .. reason
	end

	local key = makeKey(profile.ownerUserId)
	local snapshot = table.clone(profile)

	local ok, result = retry(function()
		return store:UpdateAsync(key, function(current)
			if current == nil then
				return snapshot
			end

			if type(current) ~= "table" or type(current.revision) ~= "number" then
				-- Do not overwrite data whose format/revision cannot be trusted.
				return nil
			end

			if current.revision > snapshot.revision then
				return nil
			end

			return snapshot
		end)
	end)

	if not ok then
		return false, "DATASTORE_UNAVAILABLE"
	end

	if result == nil then
		return false, "STALE_OR_UNRECOGNIZED_SAVED_DATA"
	end

	return true, "SAVED"
end

return IslandStore
