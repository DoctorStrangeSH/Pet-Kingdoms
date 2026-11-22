--!strict
-- Pure transaction contract for a future server-authoritative egg hatch saga.
-- This module does not charge currency, persist data, roll species, or grant pets.
local PetHatchingData = {}

PetHatchingData.MAX_TRANSACTION_ID_LENGTH = 128
PetHatchingData.MAX_EGG_ID_LENGTH = 48
PetHatchingData.MAX_COST_PER_RESOURCE = 2_000_000_000
PetHatchingData.MAX_TOTAL_COST = 4_000_000_000
PetHatchingData.VALID_STATES = {
	PREPARED = true,
	CHARGED = true,
	GRANTED = true,
}

local VALID_RESOURCES = {
	wood = true,
	stone = true,
	gold = true,
	gems = true,
}

local function isSafeInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value >= 0
		and value <= PetHatchingData.MAX_COST_PER_RESOURCE
		and value == math.floor(value)
end

local function isValidToken(value: any, maxLength: number): boolean
	return type(value) == "string"
		and #value >= 1
		and #value <= maxLength
		and string.match(value, "^[%w][%w:_%-]*$") ~= nil
end

local function cloneCosts(costs: any): ({ [string]: number }?, string?)
	if type(costs) ~= "table" then
		return nil, "INVALID_COSTS"
	end
	local copy: { [string]: number } = {}
	local count = 0
	local total = 0
	for resourceId, amount in pairs(costs) do
		if type(resourceId) ~= "string" or VALID_RESOURCES[resourceId] ~= true then
			return nil, "UNKNOWN_RESOURCE"
		end
		if not isSafeInteger(amount) or amount == 0 then
			return nil, "INVALID_COST"
		end
		if total > PetHatchingData.MAX_TOTAL_COST - amount then
			return nil, "TOTAL_COST_TOO_LARGE"
		end
		copy[resourceId] = amount
		total += amount
		count += 1
	end
	if count == 0 then
		return nil, "EMPTY_COSTS"
	end
	return copy, nil
end

function PetHatchingData.validate(record: any): (boolean, string)
	if type(record) ~= "table" then
		return false, "INVALID_TRANSACTION"
	end
	for key in pairs(record) do
		if key ~= "transactionId" and key ~= "eggId" and key ~= "speciesId"
			and key ~= "rarityTier" and key ~= "costs" and key ~= "createdAt"
			and key ~= "state" and key ~= "acquisitionId"
		then
			return false, "UNKNOWN_TRANSACTION_FIELD"
		end
	end
	if not isValidToken(record.transactionId, PetHatchingData.MAX_TRANSACTION_ID_LENGTH) then
		return false, "INVALID_TRANSACTION_ID"
	end
	if not isValidToken(record.eggId, PetHatchingData.MAX_EGG_ID_LENGTH) then
		return false, "INVALID_EGG_ID"
	end
	if not isValidToken(record.speciesId, 48) then
		return false, "INVALID_SPECIES_ID"
	end
	if not isSafeInteger(record.rarityTier) or record.rarityTier < 1 or record.rarityTier > 6 then
		return false, "INVALID_RARITY_TIER"
	end
	if not isSafeInteger(record.createdAt) then
		return false, "INVALID_CREATED_AT"
	end
	if PetHatchingData.VALID_STATES[record.state] ~= true then
		return false, "INVALID_STATE"
	end
	if not isValidToken(record.acquisitionId, PetHatchingData.MAX_TRANSACTION_ID_LENGTH) then
		return false, "INVALID_ACQUISITION_ID"
	end
	local costs, costReason = cloneCosts(record.costs)
	if costs == nil then
		return false, costReason or "INVALID_COSTS"
	end
	return true, "VALID"
end

function PetHatchingData.create(
	transactionId: any,
	eggId: any,
	speciesId: any,
	rarityTier: any,
	costs: any,
	createdAt: any
): (any?, string)
	local record = {
		transactionId = transactionId,
		eggId = eggId,
		speciesId = speciesId,
		rarityTier = rarityTier,
		costs = costs,
		createdAt = createdAt,
		state = "PREPARED",
		acquisitionId = "hatch:" .. tostring(transactionId),
	}
	local valid, reason = PetHatchingData.validate(record)
	if not valid then
		return nil, reason
	end
	local copiedCosts = cloneCosts(costs)
	return {
		transactionId = transactionId,
		eggId = eggId,
		speciesId = speciesId,
		rarityTier = rarityTier,
		costs = copiedCosts,
		createdAt = createdAt,
		state = "PREPARED",
		acquisitionId = record.acquisitionId,
	}, "CREATED"
end

function PetHatchingData.advance(record: any, nextState: any): (any?, string)
	local valid, reason = PetHatchingData.validate(record)
	if not valid then
		return nil, reason
	end
	if nextState ~= "CHARGED" and nextState ~= "GRANTED" then
		return nil, "INVALID_NEXT_STATE"
	end
	if record.state == nextState then
		local copy = table.clone(record)
		copy.costs = table.clone(record.costs)
		return copy, "ALREADY_ADVANCED"
	end
	if (record.state == "PREPARED" and nextState ~= "CHARGED")
		or (record.state == "CHARGED" and nextState ~= "GRANTED")
	then
		return nil, "INVALID_STATE_TRANSITION"
	end
	local copy = table.clone(record)
	copy.costs = table.clone(record.costs)
	copy.state = nextState
	return copy, "UPDATED"
end

function PetHatchingData.clone(record: any): (any?, string?)
	local valid, reason = PetHatchingData.validate(record)
	if not valid then
		return nil, reason
	end
	local copy = table.clone(record)
	copy.costs = table.clone(record.costs)
	return copy, nil
end

return PetHatchingData
