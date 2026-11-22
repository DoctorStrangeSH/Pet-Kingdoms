--!strict
-- Pure validation and normalization for a player's pet collection.
local PetCollectionData = {}

local PetProgressionData = require(script.Parent:WaitForChild("PetProgressionData"))

PetCollectionData.SCHEMA_VERSION = 1
PetCollectionData.MAX_SAFE_INTEGER = 9007199254740991
PetCollectionData.MAX_OWNED_PETS = 100
PetCollectionData.MAX_EQUIPPED_PETS = 3
PetCollectionData.MAX_PET_LEVEL = 50
PetCollectionData.MAX_BOND_LEVEL = 10
PetCollectionData.BOND_XP_PER_LEVEL = 50
PetCollectionData.MAX_BOND_XP = (PetCollectionData.MAX_BOND_LEVEL - 1) * PetCollectionData.BOND_XP_PER_LEVEL
PetCollectionData.BOND_XP_PER_INTERACTION = 10
PetCollectionData.BOND_INTERACTION_COOLDOWN_SECONDS = 30
PetCollectionData.MAX_REWARD_RECEIPTS = 128
PetCollectionData.REWARD_RECEIPT_RETENTION_SECONDS = 7 * 24 * 60 * 60
PetCollectionData.MAX_ACQUISITION_RECEIPTS = 128

local VALID_SPECIES: { [string]: boolean } = {
	bunny = true,
}

local function isNonNegativeInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value >= 0
		and value <= PetCollectionData.MAX_SAFE_INTEGER
		and value == math.floor(value)
end

local function canIncrementRevision(profile: any): boolean
	return isNonNegativeInteger(profile.revision)
		and profile.revision < PetCollectionData.MAX_SAFE_INTEGER
end

local function validateMutationProfile(profile: any): (boolean, string)
	if type(profile) ~= "table" then
		return false, "PROFILE_NOT_TABLE"
	end
	return PetCollectionData.validate(profile, profile.ownerUserId)
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
	-- Legacy profiles may omit both fencing fields. Modern profiles require
	-- a complete matching pair so mutations cannot silently erase ownership.
	local generation = profile.collectionSessionGeneration
	local token = profile.collectionSessionToken
	if (generation == nil) ~= (token == nil) then
		return false, "INCOMPLETE_COLLECTION_SESSION"
	end
	if generation ~= nil and (not isPositiveInteger(generation)
		or generation > 2_000_000_000
		or type(token) ~= "string" or #token < 1 or #token > 128)
	then
		return false, "INVALID_COLLECTION_SESSION"
	end
	if type(profile.owned) ~= "table" or type(profile.equipped) ~= "table" then
		return false, "INVALID_COLLECTIONS"
	end
	local acquisitionByPetId: { [string]: any } = {}
	if profile.acquisitionReceipts ~= nil then
		if type(profile.acquisitionReceipts) ~= "table" then
			return false, "INVALID_ACQUISITION_RECEIPTS"
		end
		local receiptCount = 0
		local receiptHighestIndex = 0
		local seenAcquisitions: { [string]: boolean } = {}
		local seenAcquiredPetIds: { [string]: boolean } = {}
		for key, receipt in pairs(profile.acquisitionReceipts) do
			if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
				return false, "INVALID_ACQUISITION_RECEIPT_LIST"
			end
			receiptCount += 1
			receiptHighestIndex = math.max(receiptHighestIndex, key)
			if type(receipt) ~= "table"
				or type(receipt.acquisitionId) ~= "string"
				or #receipt.acquisitionId < 1
				or #receipt.acquisitionId > 128
				or string.match(receipt.acquisitionId, "^[%w][%w:_%-]*$") == nil
				or seenAcquisitions[receipt.acquisitionId]
				or type(receipt.petId) ~= "string"
				or receipt.petId == ""
				or seenAcquiredPetIds[receipt.petId]
				or type(receipt.speciesId) ~= "string"
				or not VALID_SPECIES[receipt.speciesId]
				or not isPositiveInteger(receipt.rarityTier)
				or receipt.rarityTier > 6
				or not isNonNegativeInteger(receipt.processedAt)
				or (receipt.transactionId ~= nil and (type(receipt.transactionId) ~= "string"
					or #receipt.transactionId < 1 or #receipt.transactionId > 128
					or string.match(receipt.transactionId, "^[%w][%w:_%-]*$") == nil))
				or (receipt.completedAt ~= nil and (receipt.transactionId == nil
					or not isNonNegativeInteger(receipt.completedAt)
					or receipt.completedAt < receipt.processedAt))
			then
				return false, "INVALID_ACQUISITION_RECEIPT"
			end
			seenAcquisitions[receipt.acquisitionId] = true
			seenAcquiredPetIds[receipt.petId] = true
			acquisitionByPetId[receipt.petId] = receipt
		end
		if receiptCount > PetCollectionData.MAX_ACQUISITION_RECEIPTS or receiptHighestIndex ~= receiptCount then
			return false, "INVALID_ACQUISITION_RECEIPT_COUNT"
		end
	end
	if profile.rewardReceipts ~= nil then
		if type(profile.rewardReceipts) ~= "table" then
			return false, "INVALID_REWARD_RECEIPTS"
		end
		local receiptCount = 0
		local receiptHighestIndex = 0
		local seenRewardIds: { [string]: boolean } = {}
		for key, receipt in pairs(profile.rewardReceipts) do
			if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
				return false, "INVALID_REWARD_RECEIPT_LIST"
			end
			receiptCount += 1
			receiptHighestIndex = math.max(receiptHighestIndex, key)
			if type(receipt) ~= "table"
				or type(receipt.rewardId) ~= "string"
				or #receipt.rewardId < 1
				or #receipt.rewardId > 128
				or string.match(receipt.rewardId, "^[%w][%w:_%-]*$") == nil
				or seenRewardIds[receipt.rewardId]
				or type(receipt.petId) ~= "string"
				or receipt.petId == ""
				or not isPositiveInteger(receipt.amount)
				or not isNonNegativeInteger(receipt.processedAt)
			then
				return false, "INVALID_REWARD_RECEIPT"
			end
			seenRewardIds[receipt.rewardId] = true
		end
		if receiptCount > PetCollectionData.MAX_REWARD_RECEIPTS or receiptHighestIndex ~= receiptCount then
			return false, "INVALID_REWARD_RECEIPT_COUNT"
		end
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
			or (record.rarityTier ~= nil and (not isPositiveInteger(record.rarityTier) or record.rarityTier > 6))
			or (record.level ~= nil and (not isPositiveInteger(record.level) or record.level > PetCollectionData.MAX_PET_LEVEL))
			or (record.xp ~= nil and not isNonNegativeInteger(record.xp))
			or (record.bondXp ~= nil and (not isNonNegativeInteger(record.bondXp) or record.bondXp > PetCollectionData.MAX_BOND_XP))
			or (record.bondLevel ~= nil and (not isPositiveInteger(record.bondLevel) or record.bondLevel > PetCollectionData.MAX_BOND_LEVEL))
			or (record.lastInteractionAt ~= nil and not isNonNegativeInteger(record.lastInteractionAt))
			or (record.isLocked ~= nil and type(record.isLocked) ~= "boolean")
			or (record.isFavorite ~= nil and type(record.isFavorite) ~= "boolean")
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
		local acquisitionReceipt = acquisitionByPetId[record.petId]
		if acquisitionReceipt ~= nil
			and (acquisitionReceipt.speciesId ~= record.speciesId
				or acquisitionReceipt.rarityTier ~= (record.rarityTier or 1))
		then
			return false, "ACQUISITION_RECEIPT_PET_MISMATCH"
		end
		ownedById[record.petId] = true
	end
	if ownedCount > PetCollectionData.MAX_OWNED_PETS or highestIndex ~= ownedCount then
		return false, "INVALID_OWNED_COUNT"
	end

	if profile.reservedAcquisitions ~= nil then
		if type(profile.reservedAcquisitions) ~= "table" then
			return false, "INVALID_RESERVED_ACQUISITIONS"
		end
		local reservationCount = 0
		local highestReservationIndex = 0
		local seenReservations: { [string]: boolean } = {}
		for key, reservation in pairs(profile.reservedAcquisitions) do
			if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
				return false, "INVALID_RESERVATION_LIST"
			end
			reservationCount += 1
			highestReservationIndex = math.max(highestReservationIndex, key)
			if type(reservation) ~= "table"
				or type(reservation.acquisitionId) ~= "string"
				or #reservation.acquisitionId < 1 or #reservation.acquisitionId > 128
				or string.match(reservation.acquisitionId, "^[%w][%w:_%-]*$") == nil
				or seenReservations[reservation.acquisitionId]
				or type(reservation.speciesId) ~= "string" or not VALID_SPECIES[reservation.speciesId]
				or not isPositiveInteger(reservation.rarityTier) or reservation.rarityTier > 6
				or not isNonNegativeInteger(reservation.reservedAt)
			then
				return false, "INVALID_RESERVED_ACQUISITION"
			end
			seenReservations[reservation.acquisitionId] = true
		end
		if reservationCount > PetCollectionData.MAX_OWNED_PETS
			or highestReservationIndex ~= reservationCount
			or ownedCount + reservationCount > PetCollectionData.MAX_OWNED_PETS
		then
			return false, "INVALID_RESERVATION_COUNT"
		end
		for _, receipt in ipairs(profile.acquisitionReceipts or {}) do
			if seenReservations[receipt.acquisitionId] then
				return false, "ACQUISITION_ALREADY_RESERVED"
			end
		end
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
		collectionSessionGeneration = profile.collectionSessionGeneration,
		collectionSessionToken = profile.collectionSessionToken,
		owned = {},
		equipped = table.clone(profile.equipped),
		rewardReceipts = {},
	}
	for index, receipt in ipairs(profile.rewardReceipts or {}) do
		copy.rewardReceipts[index] = table.clone(receipt)
	end
	copy.acquisitionReceipts = {}
	for index, receipt in ipairs(profile.acquisitionReceipts or {}) do
		copy.acquisitionReceipts[index] = table.clone(receipt)
	end
	copy.reservedAcquisitions = {}
	for index, reservation in ipairs(profile.reservedAcquisitions or {}) do
		copy.reservedAcquisitions[index] = table.clone(reservation)
	end
	for index, record in ipairs(profile.owned) do
		local clonedRecord = table.clone(record)
		clonedRecord.level = clonedRecord.level or 1
		clonedRecord.xp = clonedRecord.xp or 0
		clonedRecord.bondXp = clonedRecord.bondXp or 0
		clonedRecord.bondLevel = clonedRecord.bondLevel or 1
		clonedRecord.lastInteractionAt = clonedRecord.lastInteractionAt or 0
		clonedRecord.isLocked = clonedRecord.isLocked == true
		clonedRecord.isFavorite = clonedRecord.isFavorite == true
		copy.owned[index] = clonedRecord
	end
	return copy
end


-- Add a pet to the collection using an ID generated by trusted server code.
-- Rarity tier is a neutral 1-6 identifier; this function does not roll rarity or define odds.
function PetCollectionData.addPet(
	profile: any,
	petId: string,
	speciesId: string,
	rarityTier: number,
	now: number
): (boolean, string, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then
		return false, "INVALID_PROFILE:" .. reason, nil
	end
	if not canIncrementRevision(profile) then
		return false, "REVISION_OVERFLOW", nil
	end
	if type(petId) ~= "string" or #petId < 1 or #petId > 128
		or string.match(petId, "^[%w][%w:_%-]*$") == nil
	then
		return false, "INVALID_PET_ID", nil
	end
	if type(speciesId) ~= "string" or not VALID_SPECIES[speciesId] then
		return false, "INVALID_SPECIES", nil
	end
	if not isPositiveInteger(rarityTier) or rarityTier > 6 then
		return false, "INVALID_RARITY_TIER", nil
	end
	if not isNonNegativeInteger(now) then
		return false, "INVALID_TIMESTAMP", nil
	end
	if #profile.owned + #(profile.reservedAcquisitions or {}) >= PetCollectionData.MAX_OWNED_PETS then
		return false, "COLLECTION_FULL", nil
	end
	for _, record in ipairs(profile.owned) do
		if record.petId == petId then
			return false, "DUPLICATE_PET_ID", nil
		end
	end
	-- Prevent reuse while the acquisition receipt is inside its deduplication window.
	for _, receipt in ipairs(profile.acquisitionReceipts or {}) do
		local age = if receipt.completedAt ~= nil then now - receipt.completedAt else 0
		if (receipt.completedAt == nil or age < 0 or age <= PetCollectionData.REWARD_RECEIPT_RETENTION_SECONDS)
			and receipt.petId == petId
		then
			return false, "PET_ID_ALREADY_USED", nil
		end
	end

	local updated = PetCollectionData.clone(profile)
	table.insert(updated.owned, {
		petId = petId,
		speciesId = speciesId,
		rarityTier = rarityTier,
		acquiredAt = now,
		level = 1,
		xp = 0,
		bondXp = 0,
		bondLevel = 1,
		lastInteractionAt = 0,
	})
	updated.revision += 1

	local updatedValid, updatedReason = PetCollectionData.validate(updated, profile.ownerUserId)
	if not updatedValid then
		return false, "INVALID_NEW_PROFILE:" .. updatedReason, nil
	end
	return true, "UPDATED", updated
end

-- Idempotent acquisition: retries with the same acquisition ID never create a second pet.
-- Reserve one collection slot atomically in the pet collection DataStore profile.
-- The reservation is consumed by addPetOnce with the same acquisitionId.
function PetCollectionData.reservePetSlotOnce(
	profile: any,
	acquisitionId: string,
	speciesId: string,
	rarityTier: number,
	now: number,
	transactionId: string?
): (boolean, string, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then return false, "INVALID_PROFILE:" .. reason, nil end
	if type(acquisitionId) ~= "string" or #acquisitionId < 1 or #acquisitionId > 128
		or string.match(acquisitionId, "^[%w][%w:_%-]*$") == nil
	then
		return false, "INVALID_ACQUISITION_ID", nil
	end
	if type(speciesId) ~= "string" or not VALID_SPECIES[speciesId] then
		return false, "INVALID_SPECIES", nil
	end
	if not isPositiveInteger(rarityTier) or rarityTier > 6 then
		return false, "INVALID_RARITY_TIER", nil
	end
	if not isNonNegativeInteger(now) then return false, "INVALID_TIMESTAMP", nil end
	if transactionId ~= nil and (type(transactionId) ~= "string" or #transactionId < 1
		or #transactionId > 128 or string.match(transactionId, "^[%w][%w:_%-]*$") == nil) then
		return false, "INVALID_TRANSACTION_ID", nil
	end

	local retainedReceipts = {}
	for _, receipt in ipairs(profile.acquisitionReceipts or {}) do
		local age = if receipt.completedAt ~= nil then now - receipt.completedAt else 0
		if receipt.completedAt == nil or age < 0 or age <= PetCollectionData.REWARD_RECEIPT_RETENTION_SECONDS then
			table.insert(retainedReceipts, receipt)
			if receipt.acquisitionId == acquisitionId then
				if receipt.speciesId ~= speciesId or receipt.rarityTier ~= rarityTier
					or (transactionId ~= nil and receipt.transactionId ~= transactionId) then
					return false, "ACQUISITION_ID_CONFLICT", nil
				end
				return false, "ALREADY_ACQUIRED", PetCollectionData.clone(profile)
			end
		end
	end
	for _, reservation in ipairs(profile.reservedAcquisitions or {}) do
		if reservation.acquisitionId == acquisitionId then
			if reservation.speciesId ~= speciesId or reservation.rarityTier ~= rarityTier then
				return false, "RESERVATION_CONFLICT", nil
			end
			return false, "ALREADY_RESERVED", PetCollectionData.clone(profile)
		end
	end
	if #profile.owned + #(profile.reservedAcquisitions or {}) >= PetCollectionData.MAX_OWNED_PETS then
		return false, "COLLECTION_FULL", nil
	end
	-- Reserve receipt-ledger capacity as well as a pet slot. Otherwise a charged
	-- hatch could become ungrantable if other rewards fill the bounded ledger.
	if #retainedReceipts + #(profile.reservedAcquisitions or {}) >= PetCollectionData.MAX_ACQUISITION_RECEIPTS then
		return false, "ACQUISITION_LEDGER_FULL", nil
	end

	local updated = PetCollectionData.clone(profile)
	updated.acquisitionReceipts = retainedReceipts
	table.insert(updated.reservedAcquisitions, {
		acquisitionId = acquisitionId,
		speciesId = speciesId,
		rarityTier = rarityTier,
		reservedAt = now,
	})
	updated.revision += 1
	local updatedValid, updatedReason = PetCollectionData.validate(updated, profile.ownerUserId)
	if not updatedValid then return false, "INVALID_RESERVED_PROFILE:" .. updatedReason, nil end
	return true, "RESERVED", updated
end

function PetCollectionData.addPetOnce(
	profile: any,
	petId: string,
	speciesId: string,
	rarityTier: number,
	now: number,
	acquisitionId: string,
	transactionId: string?
): (boolean, string, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then
		return false, "INVALID_PROFILE:" .. reason, nil
	end
	if type(acquisitionId) ~= "string" or #acquisitionId < 1 or #acquisitionId > 128
		or string.match(acquisitionId, "^[%w][%w:_%-]*$") == nil
	then
		return false, "INVALID_ACQUISITION_ID", nil
	end
	if not isNonNegativeInteger(now) then
		return false, "INVALID_TIMESTAMP", nil
	end
	if transactionId ~= nil and (type(transactionId) ~= "string" or #transactionId < 1
		or #transactionId > 128 or string.match(transactionId, "^[%w][%w:_%-]*$") == nil) then
		return false, "INVALID_TRANSACTION_ID", nil
	end

	local reservations = profile.reservedAcquisitions or {}
	local reservationIndex = nil
	for index, reservation in ipairs(reservations) do
		if reservation.acquisitionId == acquisitionId then
			if reservation.speciesId ~= speciesId or reservation.rarityTier ~= rarityTier then
				return false, "RESERVATION_CONFLICT", nil
			end
			reservationIndex = index
			break
		end
	end
	local retainedReceipts = {}
	for _, receipt in ipairs(profile.acquisitionReceipts or {}) do
		local age = if receipt.completedAt ~= nil then now - receipt.completedAt else 0
		if receipt.completedAt == nil or age < 0 or age <= PetCollectionData.REWARD_RECEIPT_RETENTION_SECONDS then
			table.insert(retainedReceipts, receipt)
			if receipt.acquisitionId == acquisitionId then
				if receipt.speciesId ~= speciesId or receipt.rarityTier ~= rarityTier
					or (transactionId ~= nil and receipt.transactionId ~= transactionId) then
					return false, "ACQUISITION_ID_CONFLICT", nil
				end
				return false, "ALREADY_ACQUIRED", PetCollectionData.clone(profile)
			end
		end
	end
	local remainingReservations = #reservations - (if reservationIndex ~= nil then 1 else 0)
	if #retainedReceipts + remainingReservations >= PetCollectionData.MAX_ACQUISITION_RECEIPTS then
		return false, "ACQUISITION_LEDGER_FULL", nil
	end

	local grantBase = profile
	if reservationIndex ~= nil then
		grantBase = PetCollectionData.clone(profile)
		table.remove(grantBase.reservedAcquisitions, reservationIndex)
	end
	local changed, status, updated = PetCollectionData.addPet(grantBase, petId, speciesId, rarityTier, now)
	if not changed or updated == nil then
		return false, status, nil
	end
	table.insert(retainedReceipts, {
		acquisitionId = acquisitionId,
		petId = petId,
		speciesId = speciesId,
		rarityTier = rarityTier,
		processedAt = now,
		transactionId = transactionId,
	})
	updated.acquisitionReceipts = retainedReceipts
	return true, "UPDATED", updated
end

function PetCollectionData.acknowledgeAcquisition(
	profile: any,
	acquisitionId: string,
	transactionId: string,
	now: number
): (boolean, string, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then return false, "INVALID_PROFILE:" .. reason, nil end
	if not canIncrementRevision(profile) then return false, "REVISION_OVERFLOW", nil end
	if type(acquisitionId) ~= "string" or #acquisitionId < 1 or #acquisitionId > 128
		or string.match(acquisitionId, "^[%w][%w:_%-]*$") == nil
		or type(transactionId) ~= "string" or #transactionId < 1 or #transactionId > 128
		or string.match(transactionId, "^[%w][%w:_%-]*$") == nil
	then return false, "INVALID_ACQUISITION_REFERENCE", nil end
	if not isNonNegativeInteger(now) then return false, "INVALID_TIMESTAMP", nil end

	local updated = PetCollectionData.clone(profile)
	for _, receipt in ipairs(updated.acquisitionReceipts or {}) do
		if receipt.acquisitionId == acquisitionId then
			if receipt.transactionId ~= transactionId then
				return false, "ACQUISITION_TRANSACTION_MISMATCH", nil
			end
			if receipt.completedAt ~= nil then
				return false, "ALREADY_ACKNOWLEDGED", updated
			end
			receipt.completedAt = now
			updated.revision += 1
			local updatedValid, updatedReason = PetCollectionData.validate(updated, profile.ownerUserId)
			if not updatedValid then return false, "INVALID_ACKNOWLEDGED_PROFILE:" .. updatedReason, nil end
			return true, "ACKNOWLEDGED", updated
		end
	end
	return false, "ACQUISITION_RECEIPT_NOT_FOUND", nil
end

function PetCollectionData.interact(profile: any, petId: string, interactionType: string, now: number): (boolean, string, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then
		return false, "INVALID_PROFILE:" .. reason, nil
	end
	if not canIncrementRevision(profile) then
		return false, "REVISION_OVERFLOW", nil
	end
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
	local valid, reason = validateMutationProfile(profile)
	if not valid then
		return false, "INVALID_PROFILE:" .. reason, nil
	end
	if not canIncrementRevision(profile) then
		return false, "REVISION_OVERFLOW", nil
	end
	if type(petId) ~= "string" or petId == "" then
		return false, "INVALID_PET_ID", nil
	end
	if not isPositiveInteger(amount) then
		return false, "INVALID_XP_AMOUNT", nil
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


-- Atomically add ordinary XP and derive the persisted level from an injected threshold table.
-- Thresholds are supplied by trusted server game configuration; no curve is defined here.
function PetCollectionData.grantExperienceWithProgress(
	profile: any,
	petId: string,
	amount: number,
	thresholds: any
): (boolean, string, any?, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then
		return false, "INVALID_PROFILE:" .. reason, nil, nil
	end
	if not canIncrementRevision(profile) then
		return false, "REVISION_OVERFLOW", nil, nil
	end
	if type(petId) ~= "string" or petId == "" then
		return false, "INVALID_PET_ID", nil, nil
	end
	if not isPositiveInteger(amount) then
		return false, "INVALID_XP_AMOUNT", nil, nil
	end

	local validThresholds, thresholdReason = PetProgressionData.validateThresholds(thresholds)
	if not validThresholds then
		return false, "INVALID_THRESHOLDS:" .. thresholdReason, nil, nil
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
		return false, "PET_NOT_OWNED", nil, nil
	end

	local previousLevel = selected.level or 1
	local nextXp = selected.xp + amount
	if not isNonNegativeInteger(nextXp) then
		return false, "XP_OVERFLOW", nil, nil
	end

	local progression, progressionReason = PetProgressionData.getProgress(nextXp, thresholds)
	if progression == nil then
		return false, "PROGRESSION_RESOLUTION_FAILED:" .. tostring(progressionReason), nil, nil
	end

	selected.xp = nextXp
	selected.level = progression.level
	updated.revision += 1

	return true, "UPDATED", updated, {
		petId = petId,
		previousLevel = previousLevel,
		level = progression.level,
		levelsGained = math.max(0, progression.level - previousLevel),
		totalXp = progression.totalXp,
		currentLevelXp = progression.currentLevelXp,
		nextLevelXp = progression.nextLevelXp,
		xpRequiredForNext = progression.xpRequiredForNext,
		progress = progression.progress,
		isMaxLevel = progression.isMaxLevel,
	}
end


-- Apply a progression reward once per stable server-generated reward ID.
-- The bounded receipt window guarantees deduplication for seven days; older IDs may be reused after expiry.
function PetCollectionData.grantExperienceWithProgressOnce(
	profile: any,
	petId: string,
	amount: number,
	thresholds: any,
	rewardId: string,
	now: number
): (boolean, string, any?, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then
		return false, "INVALID_PROFILE:" .. reason, nil, nil
	end
	if type(rewardId) ~= "string"
		or #rewardId < 1
		or #rewardId > 128
		or string.match(rewardId, "^[%w][%w:_%-]*$") == nil
	then
		return false, "INVALID_REWARD_ID", nil, nil
	end
	if not isNonNegativeInteger(now) then
		return false, "INVALID_TIMESTAMP", nil, nil
	end

	local retainedReceipts = {}
	for _, receipt in ipairs(profile.rewardReceipts or {}) do
		local age = now - receipt.processedAt
		if age < 0 or age <= PetCollectionData.REWARD_RECEIPT_RETENTION_SECONDS then
			table.insert(retainedReceipts, receipt)
			if receipt.rewardId == rewardId then
				if receipt.petId ~= petId or receipt.amount ~= amount then
					return false, "REWARD_ID_CONFLICT", nil, nil
				end
				return false, "ALREADY_PROCESSED", nil, table.clone(receipt)
			end
		end
	end

	if #retainedReceipts >= PetCollectionData.MAX_REWARD_RECEIPTS then
		return false, "REWARD_LEDGER_FULL", nil, nil
	end

	local changed, status, updated, summary =
		PetCollectionData.grantExperienceWithProgress(profile, petId, amount, thresholds)
	if not changed or updated == nil then
		return false, status, nil, nil
	end

	table.insert(retainedReceipts, {
		rewardId = rewardId,
		petId = petId,
		amount = amount,
		processedAt = now,
	})
	updated.rewardReceipts = retainedReceipts

	return true, "UPDATED", updated, summary
end


-- Update player-controlled collection protection flags without changing pet identity.
function PetCollectionData.setPetFlags(
	profile: any,
	petId: string,
	isLocked: boolean,
	isFavorite: boolean
): (boolean, string, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then return false, "INVALID_PROFILE:" .. reason, nil end
	if not canIncrementRevision(profile) then return false, "REVISION_OVERFLOW", nil end
	if type(petId) ~= "string" or petId == "" then return false, "INVALID_PET_ID", nil end
	if type(isLocked) ~= "boolean" or type(isFavorite) ~= "boolean" then
		return false, "INVALID_PET_FLAGS", nil
	end
	local updated = PetCollectionData.clone(profile)
	for _, record in ipairs(updated.owned) do
		if record.petId == petId then
			record.isLocked = isLocked
			record.isFavorite = isFavorite
			updated.revision += 1
			return true, "UPDATED", updated
		end
	end
	return false, "PET_NOT_OWNED", nil
end

-- Permanently remove an owned pet only when it is neither protected nor equipped.
function PetCollectionData.removePet(profile: any, petId: string): (boolean, string, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then return false, "INVALID_PROFILE:" .. reason, nil end
	if not canIncrementRevision(profile) then return false, "REVISION_OVERFLOW", nil end
	if type(petId) ~= "string" or petId == "" then return false, "INVALID_PET_ID", nil end
	if petId == "starter-bunny" then return false, "STARTER_PET_PROTECTED", nil end
	if #profile.owned <= 1 then return false, "LAST_PET_PROTECTED", nil end

	local selectedIndex = nil
	for index, record in ipairs(profile.owned) do
		if record.petId == petId then
			if record.isLocked == true then return false, "PET_LOCKED", nil end
			selectedIndex = index
			break
		end
	end
	if selectedIndex == nil then return false, "PET_NOT_OWNED", nil end
	for _, equippedPetId in ipairs(profile.equipped) do
		if equippedPetId == petId then return false, "PET_EQUIPPED", nil end
	end

	local updated = PetCollectionData.clone(profile)
	table.remove(updated.owned, selectedIndex)
	updated.revision += 1
	local updatedValid, updatedReason = PetCollectionData.validate(updated, profile.ownerUserId)
	if not updatedValid then return false, "INVALID_REMOVED_PROFILE:" .. updatedReason, nil end
	return true, "REMOVED", updated
end

function PetCollectionData.setEquipped(profile: any, petIds: { string }): (boolean, string, any?)
	local valid, reason = validateMutationProfile(profile)
	if not valid then
		return false, "INVALID_PROFILE:" .. reason, nil
	end
	if not canIncrementRevision(profile) then
		return false, "REVISION_OVERFLOW", nil
	end
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
