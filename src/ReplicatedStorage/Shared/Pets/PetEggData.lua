--!strict
-- Data contract and deterministic weighted selection for future pet eggs.
-- No egg definitions, drop rates, currency costs, or production species catalog are authored here.
local PetEggData = {}

PetEggData.MAX_EGG_ID_LENGTH = 48
PetEggData.MAX_ENTRIES = 32
PetEggData.MAX_TOTAL_WEIGHT = 1_000_000_000

local function isValidId(value: any): boolean
	return type(value) == "string"
		and #value >= 1
		and #value <= PetEggData.MAX_EGG_ID_LENGTH
		and string.match(value, "^[a-z][a-z0-9_%-]*$") ~= nil
end

local function isPositiveSafeInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value > 0
		and value <= PetEggData.MAX_TOTAL_WEIGHT
		and value == math.floor(value)
end

function PetEggData.validateDefinition(eggId: any, definition: any, speciesCatalog: any): (boolean, string)
	if not isValidId(eggId) then
		return false, "INVALID_EGG_ID"
	end
	if type(definition) ~= "table" then
		return false, "INVALID_DEFINITION"
	end
	if type(speciesCatalog) ~= "table" then
		return false, "INVALID_SPECIES_CATALOG"
	end

	for key in pairs(definition) do
		if key ~= "entries" then
			return false, "UNKNOWN_DEFINITION_FIELD"
		end
	end
	if type(definition.entries) ~= "table" then
		return false, "INVALID_ENTRIES"
	end

	local count = 0
	local highestIndex = 0
	local totalWeight = 0
	local seenSpecies: { [string]: boolean } = {}
	for key, entry in pairs(definition.entries) do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			return false, "INVALID_ENTRY_LIST"
		end
		count += 1
		highestIndex = math.max(highestIndex, key)
		if type(entry) ~= "table" then
			return false, "INVALID_ENTRY"
		end
		for entryKey in pairs(entry) do
			if entryKey ~= "speciesId" and entryKey ~= "weight" then
				return false, "UNKNOWN_ENTRY_FIELD"
			end
		end
		if not isValidId(entry.speciesId) or speciesCatalog[entry.speciesId] ~= true then
			return false, "UNKNOWN_SPECIES"
		end
		if seenSpecies[entry.speciesId] then
			return false, "DUPLICATE_SPECIES"
		end
		if not isPositiveSafeInteger(entry.weight) then
			return false, "INVALID_WEIGHT"
		end
		if totalWeight > PetEggData.MAX_TOTAL_WEIGHT - entry.weight then
			return false, "TOTAL_WEIGHT_TOO_LARGE"
		end
		totalWeight += entry.weight
		seenSpecies[entry.speciesId] = true
	end

	if count == 0 then
		return false, "EMPTY_ENTRIES"
	end
	if count > PetEggData.MAX_ENTRIES or highestIndex ~= count then
		return false, "INVALID_ENTRY_COUNT"
	end

	return true, "VALID"
end

function PetEggData.cloneDefinition(eggId: any, definition: any, speciesCatalog: any): (any?, string?)
	local valid, reason = PetEggData.validateDefinition(eggId, definition, speciesCatalog)
	if not valid then
		return nil, reason
	end

	local entries = {}
	for index, entry in ipairs(definition.entries) do
		entries[index] = {
			speciesId = entry.speciesId,
			weight = entry.weight,
		}
	end
	return { eggId = eggId, entries = entries }
end

-- randomValue must come from a server-owned Random instance and be in [0, 1).
-- Returning a species only keeps the selection independent from presentation and economy.
function PetEggData.roll(eggId: any, definition: any, speciesCatalog: any, randomValue: number): (string?, string?)
	local valid, reason = PetEggData.validateDefinition(eggId, definition, speciesCatalog)
	if not valid then
		return nil, reason
	end
	if type(randomValue) ~= "number" or randomValue ~= randomValue or randomValue < 0 or randomValue >= 1 then
		return nil, "INVALID_RANDOM_VALUE"
	end

	local totalWeight = 0
	for _, entry in ipairs(definition.entries) do
		totalWeight += entry.weight
	end
	local target = randomValue * totalWeight
	local cumulativeWeight = 0
	for _, entry in ipairs(definition.entries) do
		cumulativeWeight += entry.weight
		if target < cumulativeWeight then
			return entry.speciesId, nil
		end
	end

	return nil, "ROLL_FAILED"
end

return PetEggData
