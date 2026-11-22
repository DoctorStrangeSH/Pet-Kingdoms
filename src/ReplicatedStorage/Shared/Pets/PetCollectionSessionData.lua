--!strict
-- DataStore-persisted fencing for pet collection writers.
-- A new session claims only the generation/revision it previously observed.
local PetCollectionSessionData = {}

local MAX_GENERATION = 2_000_000_000

local function validGeneration(value: any): boolean
	return type(value) == "number" and value == value
		and value >= 0 and value < MAX_GENERATION
		and value == math.floor(value)
end

local function validToken(value: any): boolean
	return type(value) == "string" and #value > 0 and #value <= 128
end

function PetCollectionSessionData.claim(current: any, observed: any, token: any, createDefault: () -> any): (any?, string)
	if not validToken(token) then return nil, "INVALID_TOKEN" end
	if current ~= nil and type(current) ~= "table" then return nil, "INVALID_PROFILE" end
	if observed ~= nil and type(observed) ~= "table" then return nil, "INVALID_OBSERVATION" end
	if current == nil and observed ~= nil then return nil, "STALE_OBSERVATION" end
	if current ~= nil and observed == nil then return nil, "STALE_OBSERVATION" end

	if current ~= nil and current.collectionSessionToken == token then
		return current, "ALREADY_CLAIMED"
	end

	if current ~= nil then
		if current.revision ~= observed.revision
			or (current.collectionSessionGeneration or 0) ~= (observed.collectionSessionGeneration or 0)
			or current.collectionSessionToken ~= observed.collectionSessionToken
		then
			return nil, "STALE_OBSERVATION"
		end
	end

	local generation = if current ~= nil then (current.collectionSessionGeneration or 0) else 0
	if not validGeneration(generation) or generation + 1 >= MAX_GENERATION then
		return nil, "INVALID_GENERATION"
	end
	local nextProfile = if current == nil then createDefault() else table.clone(current)
	if type(nextProfile) ~= "table" then return nil, "INVALID_DEFAULT_PROFILE" end
	nextProfile.collectionSessionGeneration = generation + 1
	nextProfile.collectionSessionToken = token
	return nextProfile, "CLAIMED"
end

function PetCollectionSessionData.owns(current: any, generation: any, token: any): boolean
	return type(current) == "table"
		and validGeneration(generation)
		and validToken(token)
		and current.collectionSessionGeneration == generation
		and current.collectionSessionToken == token
end

return PetCollectionSessionData
