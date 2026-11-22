--!strict
-- Declarative pet stat modifier contracts only.
-- This module validates and clones modifier records; it does not apply or stack them.
local PetStatModifiersData = {}

local PetStatsData = require(script.Parent:WaitForChild("PetStatsData"))

local ALLOWED_SOURCE_TYPES: { [string]: boolean } = {
	equipment = true,
	skill = true,
	ability = true,
}

local ALLOWED_OPERATIONS: { [string]: boolean } = {
	flat = true,
	percent = true,
}

local MAX_MODIFIERS = 128
PetStatModifiersData.MAX_MODIFIERS = MAX_MODIFIERS

local function isStableId(value: any): boolean
	return type(value) == "string"
		and #value > 0
		and #value <= 64
		and string.match(value, "^[a-z][a-z0-9_%-]*$") ~= nil
end

local function isFiniteNumber(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value <= PetStatsData.MAX_SAFE_NUMBER
		and value >= -PetStatsData.MAX_SAFE_NUMBER
end

function PetStatModifiersData.validateModifier(modifier: any): (boolean, string)
	if type(modifier) ~= "table" then
		return false, "INVALID_MODIFIER"
	end

	for key in pairs(modifier) do
		if key ~= "id" and key ~= "sourceType" and key ~= "sourceId"
			and key ~= "stat" and key ~= "operation" and key ~= "value"
		then
			return false, "UNKNOWN_MODIFIER_FIELD"
		end
	end

	if not isStableId(modifier.id) then
		return false, "INVALID_MODIFIER_ID"
	end
	if type(modifier.sourceType) ~= "string" or not ALLOWED_SOURCE_TYPES[modifier.sourceType] then
		return false, "INVALID_SOURCE_TYPE"
	end
	if not isStableId(modifier.sourceId) then
		return false, "INVALID_SOURCE_ID"
	end

	local validStat = false
	for _, statKey in ipairs(PetStatsData.getStatKeys()) do
		if modifier.stat == statKey then
			validStat = true
			break
		end
	end
	if not validStat then
		return false, "INVALID_STAT"
	end

	if type(modifier.operation) ~= "string" or not ALLOWED_OPERATIONS[modifier.operation] then
		return false, "INVALID_OPERATION"
	end
	if not isFiniteNumber(modifier.value) then
		return false, "INVALID_VALUE"
	end

	return true, "VALID"
end

function PetStatModifiersData.validateList(modifiers: any): (boolean, string)
	if type(modifiers) ~= "table" then
		return false, "INVALID_MODIFIER_LIST"
	end

	local count = 0
	local seenIds: { [string]: boolean } = {}
	for key, modifier in pairs(modifiers) do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			return false, "INVALID_MODIFIER_LIST_KEY"
		end
		count += 1
		if count > MAX_MODIFIERS then
			return false, "TOO_MANY_MODIFIERS"
		end

		local valid, reason = PetStatModifiersData.validateModifier(modifier)
		if not valid then
			return false, "INVALID_MODIFIER_AT:" .. tostring(key) .. ":" .. reason
		end
		if seenIds[modifier.id] then
			return false, "DUPLICATE_MODIFIER_ID"
		end
		seenIds[modifier.id] = true
	end

	for index = 1, count do
		if modifiers[index] == nil then
			return false, "SPARSE_MODIFIER_LIST"
		end
	end

	return true, "VALID"
end

function PetStatModifiersData.cloneModifier(modifier: any): (any?, string?)
	local valid, reason = PetStatModifiersData.validateModifier(modifier)
	if not valid then
		return nil, reason
	end

	return {
		id = modifier.id,
		sourceType = modifier.sourceType,
		sourceId = modifier.sourceId,
		stat = modifier.stat,
		operation = modifier.operation,
		value = modifier.value,
	}
end

function PetStatModifiersData.cloneList(modifiers: any): (any?, string?)
	local valid, reason = PetStatModifiersData.validateList(modifiers)
	if not valid then
		return nil, reason
	end

	local copy = {}
	for index, modifier in ipairs(modifiers) do
		local cloned, cloneReason = PetStatModifiersData.cloneModifier(modifier)
		if cloned == nil then
			return nil, "INVALID_MODIFIER_AT:" .. tostring(index) .. ":" .. tostring(cloneReason)
		end
		copy[index] = cloned
	end

	return copy
end

return PetStatModifiersData
