--!strict
-- Pure validation and normalization for a player's pet collection.
local PetCollectionData = {}

PetCollectionData.SCHEMA_VERSION = 1
PetCollectionData.MAX_OWNED_PETS = 100
PetCollectionData.MAX_EQUIPPED_PETS = 3

local VALID_SPECIES: { [string]: boolean } = {
	bunny = true,
}

local function isPositiveInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value > 0
		and value == math.floor(value)
end

function PetCollectionData.createDefault(userId: number): any?
	if not isPositiveInteger(userId) then
		return nil
	end
	return {
		schemaVersion = PetCollectionData.SCHEMA_VERSION,
		ownerUserId = userId,
		revision = 0,
		owned = {
			{
				petId = "starter-bunny",
				speciesId = "bunny",
				acquiredAt = 0,
			},
		},
		equipped = { "starter-bunny" },
	}
end

function PetCollectionData.validate(profile: any, expectedUserId: number): (boolean, string)
	if type(profile) ~= "table" then
		return false, "PROFILE_NOT_TABLE"
	end
	if profile.schemaVersion ~= PetCollectionData.SCHEMA_VERSION then
		return false, "UNSUPPORTED_SCHEMA_VERSION"
	end
	if not isPositiveInteger(expectedUserId) or profile.ownerUserId ~= expectedUserId then
		return false, "OWNER_MISMATCH"
	end
	if not isPositiveInteger(profile.revision + 1) then
		return false, "INVALID_REVISION"
	end
	if type(profile.owned) ~= "table" or type(profile.equipped) ~= "table" then
		return false, "INVALID_COLLECTIONS"
	end

	local ownedCount = 0
	local highestIndex = 0
	local ownedById: { [string]: boolean } = {}
	for key, record in pairs(profile.owned) do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			return false, "INVALID_OWNED_LIST"
		end
		ownedCount += 1
		highestIndex = math.max(highestIndex, key)
		if type(record) ~= "table"
			or type(record.petId) ~= "string"
			or record.petId == ""
			or ownedById[record.petId]
			or type(record.speciesId) ~= "string"
			or not VALID_SPECIES[record.speciesId]
			or type(record.acquiredAt) ~= "number"
			or record.acquiredAt < 0
			or record.acquiredAt ~= record.acquiredAt
		then
			return false, "INVALID_OWNED_RECORD"
		end
		ownedById[record.petId] = true
	end
	if ownedCount > PetCollectionData.MAX_OWNED_PETS or highestIndex ~= ownedCount then
		return false, "INVALID_OWNED_COUNT"
	end

	local equippedCount = 0
	local equippedSeen: { [string]: boolean } = {}
	local equippedHighest = 0
	for key, petId in pairs(profile.equipped) do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			return false, "INVALID_EQUIPPED_LIST"
		end
		equippedCount += 1
		equippedHighest = math.max(equippedHighest, key)
		if type(petId) ~= "string" or not ownedById[petId] or equippedSeen[petId] then
			return false, "INVALID_EQUIPPED_PET"
		end
		equippedSeen[petId] = true
	end
	if equippedCount > PetCollectionData.MAX_EQUIPPED_PETS or equippedHighest ~= equippedCount then
		return false, "INVALID_EQUIPPED_COUNT"
	end

	return true, "VALID"
end

function PetCollectionData.clone(profile: any): any
	local copy = {
		schemaVersion = profile.schemaVersion,
		ownerUserId = profile.ownerUserId,
		revision = profile.revision,
		owned = {},
		equipped = table.clone(profile.equipped),
	}
	for index, record in ipairs(profile.owned) do
		copy.owned[index] = table.clone(record)
	end
	return copy
end

function PetCollectionData.setEquipped(profile: any, petIds: { string }): (boolean, string, any?)
	if type(petIds) ~= "table" or #petIds > PetCollectionData.MAX_EQUIPPED_PETS then
		return false, "INVALID_EQUIPPED_COUNT", nil
	end
	local ownedById: { [string]: boolean } = {}
	for _, record in ipairs(profile.owned) do
		ownedById[record.petId] = true
	end
	local seen: { [string]: boolean } = {}
	for _, petId in ipairs(petIds) do
		if type(petId) ~= "string" or not ownedById[petId] then
			return false, "PET_NOT_OWNED", nil
		end
		if seen[petId] then
			return false, "DUPLICATE_EQUIPPED_PET", nil
		end
		seen[petId] = true
	end
	local updated = PetCollectionData.clone(profile)
	updated.equipped = table.clone(petIds)
	updated.revision += 1
	return true, "UPDATED", updated
end

return PetCollectionData
