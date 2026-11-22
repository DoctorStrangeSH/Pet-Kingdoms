--!strict
-- Species stat definition contract. No species list or balance values are authored here.
local PetSpeciesStatsData = {}

local PetStatsData = require(script.Parent:WaitForChild("PetStatsData"))

local function isValidSpeciesId(speciesId: any): boolean
	return type(speciesId) == "string"
		and #speciesId > 0
		and #speciesId <= 48
		and string.match(speciesId, "^[a-z][a-z0-9_%-]*$") ~= nil
end

function PetSpeciesStatsData.validateDefinition(speciesId: any, definition: any): (boolean, string)
	if not isValidSpeciesId(speciesId) then
		return false, "INVALID_SPECIES_ID"
	end
	if type(definition) ~= "table" then
		return false, "INVALID_DEFINITION"
	end

	for key in pairs(definition) do
		if key ~= "baseStats" then
			return false, "UNKNOWN_DEFINITION_FIELD"
		end
	end

	local validStats, reason = PetStatsData.validateStats(definition.baseStats)
	if not validStats then
		return false, "INVALID_BASE_STATS:" .. reason
	end

	return true, "VALID"
end

function PetSpeciesStatsData.cloneDefinition(speciesId: any, definition: any): (any?, string?)
	local valid, reason = PetSpeciesStatsData.validateDefinition(speciesId, definition)
	if not valid then
		return nil, reason
	end

	local baseStats, statsReason = PetStatsData.cloneStats(definition.baseStats)
	if baseStats == nil then
		return nil, "INVALID_BASE_STATS:" .. tostring(statsReason)
	end

	return {
		speciesId = speciesId,
		baseStats = baseStats,
	}
end

function PetSpeciesStatsData.validateCatalog(catalog: any): (boolean, string)
	if type(catalog) ~= "table" then
		return false, "INVALID_CATALOG"
	end

	local count = 0
	for speciesId, definition in pairs(catalog) do
		count += 1
		if not isValidSpeciesId(speciesId) then
			return false, "INVALID_SPECIES_ID"
		end
		local valid, reason = PetSpeciesStatsData.validateDefinition(speciesId, definition)
		if not valid then
			return false, "INVALID_SPECIES:" .. speciesId .. ":" .. reason
		end
	end

	if count == 0 then
		return false, "EMPTY_CATALOG"
	end

	return true, "VALID"
end

function PetSpeciesStatsData.cloneCatalog(catalog: any): (any?, string?)
	local valid, reason = PetSpeciesStatsData.validateCatalog(catalog)
	if not valid then
		return nil, reason
	end

	local copy = {}
	for speciesId, definition in pairs(catalog) do
		local clonedDefinition, cloneReason = PetSpeciesStatsData.cloneDefinition(speciesId, definition)
		if clonedDefinition == nil then
			return nil, "INVALID_SPECIES:" .. speciesId .. ":" .. tostring(cloneReason)
		end
		copy[speciesId] = clonedDefinition
	end

	return copy
end

return PetSpeciesStatsData
