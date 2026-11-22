--!strict
-- Pure validation and normalization for a player's pet collection.
local PetCollectionData = {}

PetCollectionData.SCHEMA_VERSION = 1
PetCollectionData.MAX_OWNED_PETS = 100
PetCollectionData.MAX_EQUIPPED_PETS = 3
PetCollectionData.MAX_PET_LEVEL = 50
PetCollectionData.MAX_BOND_LEVEL = 10
PetCollectionData.BOND_XP_PER_LEVEL = 50
PetCollectionData.MAX_BOND_XP = (PetCollectionData.MAX_BOND_LEVEL - 1) * PetCollectionData.BOND_XP_PER_LEVEL
PetCollectionData.BOND_XP_PER_INTERACTION = 10
PetCollectionData.BOND_INTERACTION_COOLDOWN_SECONDS = 30

local VALID_SPECIES: { [string]: boolean } = {
	bunny = true,
}

local function isNonNegativeInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value >= 0
		and value == math.floor(value)
end

local function isPositiveInteger(value: any): boolean
	return isNonNegativeInteger(value) and value > 0
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
				level = 1,
				xp = 0,
				bondXp = 0,
				bondLevel = 1,
				lastInteractionAt = 0,
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
	if not isNonNegativeInteger(profile.revision) then
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
			or not isNonNegativeInteger(record.acquiredAt)
			or (record.level ~= nil and (not isPositiveInteger(record.level) or record.level > PetCollectionData.MAX_PET_LEVEL))
			or (record.xp ~= nil and not isNonNegativeInteger(record.xp))
			or (record.bondXp ~= nil and (not isNonNegativeInteger(record.bondXp) or record.bondXp > PetCollectionData.MAX_BOND_XP))
			or (record.bondLevel ~= nil and (not isPositiveInteger(record.bondLevel) or record.bondLevel > PetCollectionData.MAX_BOND_LEVEL))
			or (record.lastInteractionAt ~= nil and not isNonNegativeInteger(record.lastInteractionAt))
		then
			return false, "INVALID_OWNED_RECORD"
		end
		local bondXp = record.bondXp or 0
		local bondLevel = record.bondLevel or 1
		local expectedBondLevel = math.min(
			PetCollectionData.MAX_BOND_LEVEL,
			1 + math.floor(bondXp / PetCollectionData.BOND_XP_PER_LEVEL)
		)
		if bondLevel ~= expectedBondLevel then
			return false, "BOND_LEVEL_XP_MISMATCH"
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
		local clonedRecord = table.clone(record)
		clonedRecord.level = clonedRecord.level or 1
		clonedRecord.xp = clonedRecord.xp or 0
		clonedRecord.bondXp = clonedRecord.bondXp or 0
		clonedRecord.bondLevel = clonedRecord.bondLevel or 1
		clonedRecord.lastInteractionAt = clonedRecord.lastInteractionAt or 0
		copy.owned[index] = clonedRecord
	end
	return copy
end

function PetCollectionData.interact(profile: any, petId: string, interactionType: string, now: number): (boolean, string, any?)
	if type(petId) ~= "string" or petId == "" then
		return false, "INVALID_PET_ID", nil
	end
	if interactionType ~= "pet" and interactionType ~= "play" then
		return false, "INVALID_INTERACTION", nil
	end
	if not isNonNegativeInteger(now) then
		return false, "INVALID_TIMESTAMP", nil
	end
	local updated = PetCollectionData.clone(profile)
	local selected = nil
	for _, record in ipairs(updated.owned) do
		if record.petId == petId then selected = record break end
	end
	if selected == nil then
		return false, "PET_NOT_OWNED", nil
	end
	local lastInteractionAt = selected.lastInteractionAt or 0
	if now - lastInteractionAt < PetCollectionData.BOND_INTERACTION_COOLDOWN_SECONDS then
		return false, "INTERACTION_COOLDOWN", nil
	end
	selected.bondXp = math.min(PetCollectionData.MAX_BOND_XP, (selected.bondXp or 0) + PetCollectionData.BOND_XP_PER_INTERACTION)
	selected.bondLevel = math.min(
		PetCollectionData.MAX_BOND_LEVEL,
		1 + math.floor(selected.bondXp / PetCollectionData.BOND_XP_PER_LEVEL)
	)
	selected.lastInteractionAt = now
	updated.revision += 1
	return true, "UPDATED", updated
end

-- This pure mutation is intended for trusted server-side reward systems only.
-- The caller must derive amount from validated server gameplay state, never client payloads.
function PetCollectionData.grantExperience(profile: any, petId: string, amount: number): (boolean, string, any?)
	if type(petId) ~= "string" or petId == "" then
		return false, "INVALID_PET_ID", nil
	end
	if not isPositiveInteger(amount) then
		return false, "INVALID_XP_AMOUNT", nil
	end
	local valid, reason = PetCollectionData.validate(profile, profile.ownerUserId)
	if not valid then
		return false, "INVALID_PROFILE:" .. reason, nil
	end

	local updated = PetCollectionData.clone(profile)
	local selected = nil
	for _, record in ipairs(updated.owned) do
		if record.petId == petId then
			selected = record
			break
		end
	end
	if selected == nil then
		return false, "PET_NOT_OWNED", nil
	end

	local nextXp = selected.xp + amount
	if not isNonNegativeInteger(nextXp) then
		return false, "XP_OVERFLOW", nil
	end
	selected.xp = nextXp
	updated.revision += 1
	return true, "UPDATED", updated
end

function PetCollectionData.setEquipped(profile: any, petIds: { string }): (boolean, string, any?)
	if type(petIds) ~= "table" then
		return false, "INVALID_EQUIPPED_COUNT", nil
	end
	local requestedCount = 0
	local highestIndex = 0
	for key in pairs(petIds) do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			return false, "INVALID_EQUIPPED_LIST", nil
		end
		requestedCount += 1
		highestIndex = math.max(highestIndex, key)
	end
	if requestedCount > PetCollectionData.MAX_EQUIPPED_PETS or highestIndex ~= requestedCount then
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
