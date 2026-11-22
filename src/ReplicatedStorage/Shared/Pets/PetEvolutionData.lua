--!strict
-- Pure, balance-agnostic evolution catalog validation and lookup.
-- This module deliberately defines no species, costs, levels, items, or evolution outcomes.
local PetEvolutionData = {}

PetEvolutionData.MAX_DEFINITIONS = 256

local function isIdentifier(value: any): boolean
	return type(value) == "string"
		and #value >= 1
		and #value <= 96
		and string.match(value, "^[%w][%w:_%-]*$") ~= nil
end

function PetEvolutionData.validateCatalog(catalog: any): (boolean, string)
	if type(catalog) ~= "table" then return false, "INVALID_CATALOG" end

	local count = 0
	local highestIndex = 0
	local byId: { [string]: any } = {}
	local graph: { [string]: { string } } = {}

	for key, definition in pairs(catalog) do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			return false, "INVALID_CATALOG_LIST"
		end
		count += 1
		highestIndex = math.max(highestIndex, key)
		if type(definition) ~= "table"
			or not isIdentifier(definition.evolutionId)
			or not isIdentifier(definition.sourceSpeciesId)
			or not isIdentifier(definition.targetSpeciesId)
		then
			return false, "INVALID_DEFINITION"
		end
		if byId[definition.evolutionId] ~= nil then
			return false, "DUPLICATE_EVOLUTION_ID"
		end
		if definition.sourceSpeciesId == definition.targetSpeciesId then
			return false, "SELF_EVOLUTION"
		end
		byId[definition.evolutionId] = definition
		graph[definition.sourceSpeciesId] = graph[definition.sourceSpeciesId] or {}
		table.insert(graph[definition.sourceSpeciesId], definition.targetSpeciesId)
	end

	if count > PetEvolutionData.MAX_DEFINITIONS or highestIndex ~= count then
		return false, "INVALID_CATALOG_COUNT"
	end

	-- Evolution chains may branch and converge, but must not contain cycles.
	local visiting: { [string]: boolean } = {}
	local visited: { [string]: boolean } = {}
	local function visit(speciesId: string): boolean
		if visiting[speciesId] then return false end
		if visited[speciesId] then return true end
		visiting[speciesId] = true
		for _, targetSpeciesId in ipairs(graph[speciesId] or {}) do
			if not visit(targetSpeciesId) then return false end
		end
		visiting[speciesId] = nil
		visited[speciesId] = true
		return true
	end

	for sourceSpeciesId in pairs(graph) do
		if not visit(sourceSpeciesId) then return false, "EVOLUTION_CYCLE" end
	end
	return true, "VALID"
end

function PetEvolutionData.getDefinition(catalog: any, evolutionId: string): (any?, string?)
	if not isIdentifier(evolutionId) then return nil, "INVALID_EVOLUTION_ID" end
	local valid, reason = PetEvolutionData.validateCatalog(catalog)
	if not valid then return nil, reason end
	for _, definition in ipairs(catalog) do
		if definition.evolutionId == evolutionId then
			return table.clone(definition), nil
		end
	end
	return nil, "EVOLUTION_NOT_FOUND"
end

-- Prepare a non-persistent transformation while preserving the pet's stable identity
-- and every unrelated field (level, XP, bond, rarity, equipment metadata, protection flags).
-- Persistence and eligibility remain the responsibility of a server transaction service.
function PetEvolutionData.prepareTransition(definition: any, petRecord: any): (any?, string?)
	if type(definition) ~= "table"
		or not isIdentifier(definition.evolutionId)
		or not isIdentifier(definition.sourceSpeciesId)
		or not isIdentifier(definition.targetSpeciesId)
	then
		return nil, "INVALID_DEFINITION"
	end
	if definition.sourceSpeciesId == definition.targetSpeciesId then
		return nil, "SELF_EVOLUTION"
	end
	if type(petRecord) ~= "table"
		or type(petRecord.petId) ~= "string"
		or petRecord.petId == ""
		or type(petRecord.speciesId) ~= "string"
	then
		return nil, "INVALID_PET_RECORD"
	end
	if petRecord.speciesId ~= definition.sourceSpeciesId then
		return nil, "SOURCE_SPECIES_MISMATCH"
	end

	local evolvedRecord = table.clone(petRecord)
	evolvedRecord.speciesId = definition.targetSpeciesId
	return {
		evolutionId = definition.evolutionId,
		petId = petRecord.petId,
		sourceSpeciesId = definition.sourceSpeciesId,
		targetSpeciesId = definition.targetSpeciesId,
		petRecord = evolvedRecord,
	}, nil
end

function PetEvolutionData.getOptions(catalog: any, sourceSpeciesId: string): ({ any }?, string?)
	if not isIdentifier(sourceSpeciesId) then return nil, "INVALID_SPECIES_ID" end
	local valid, reason = PetEvolutionData.validateCatalog(catalog)
	if not valid then return nil, reason end
	local options = {}
	for _, definition in ipairs(catalog) do
		if definition.sourceSpeciesId == sourceSpeciesId then
			table.insert(options, table.clone(definition))
		end
	end
	return options, nil
end

return PetEvolutionData
