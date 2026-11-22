--!strict
-- Studio-only pure contract tests for species base-stat definitions.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Pets = Shared:WaitForChild("Pets")
local PetSpeciesStatsData = require(Pets:WaitForChild("PetSpeciesStatsData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local validDefinition = {
	baseStats = {
		health = 0,
		attack = 0,
		defense = 0,
		speed = 0,
		criticalChance = 0,
	},
}

local valid, status = PetSpeciesStatsData.validateDefinition("sample-species", validDefinition)
expect("complete species base-stat definition is valid", valid and status == "VALID")

local invalidId, invalidIdStatus = PetSpeciesStatsData.validateDefinition("Sample Species", validDefinition)
expect("species ID must use stable lowercase identifier format", not invalidId and invalidIdStatus == "INVALID_SPECIES_ID")

local invalidDefinition, invalidDefinitionStatus = PetSpeciesStatsData.validateDefinition("sample-species", nil)
expect("nil species definition is rejected", not invalidDefinition and invalidDefinitionStatus == "INVALID_DEFINITION")

local extraField = {
	baseStats = table.clone(validDefinition.baseStats),
	level = 1,
}
local extraValid, extraStatus = PetSpeciesStatsData.validateDefinition("sample-species", extraField)
expect("unapproved species definition field is rejected", not extraValid and extraStatus == "UNKNOWN_DEFINITION_FIELD")

local invalidStats = {
	baseStats = table.clone(validDefinition.baseStats),
}
invalidStats.baseStats.health = -1
local invalidStatsValid, invalidStatsStatus = PetSpeciesStatsData.validateDefinition("sample-species", invalidStats)
expect("invalid base stat value is rejected", not invalidStatsValid and string.sub(invalidStatsStatus, 1, 18) == "INVALID_BASE_STATS")

local validCatalog = {
	["sample-species"] = validDefinition,
	["sample-species-2"] = validDefinition,
}
expect("catalog with multiple valid species definitions is accepted", PetSpeciesStatsData.validateCatalog(validCatalog))

local emptyCatalog, emptyCatalogStatus = PetSpeciesStatsData.validateCatalog({})
expect("empty species catalog is rejected", not emptyCatalog and emptyCatalogStatus == "EMPTY_CATALOG")

local invalidCatalog, invalidCatalogStatus = PetSpeciesStatsData.validateCatalog({
	["bad species"] = validDefinition,
})
expect("invalid species catalog key is rejected", not invalidCatalog and invalidCatalogStatus == "INVALID_SPECIES_ID")

local malformedCatalog, malformedCatalogStatus = PetSpeciesStatsData.validateCatalog({
	["sample-species"] = { baseStats = { health = 10 } },
})
expect("catalog with incomplete base stats is rejected", not malformedCatalog and string.sub(malformedCatalogStatus, 1, 15) == "INVALID_SPECIES")

local cloned, cloneStatus = PetSpeciesStatsData.cloneDefinition("sample-species", validDefinition)
assert(cloned ~= nil, tostring(cloneStatus))
cloned.baseStats.health = 999
expect("cloned species definition does not mutate source", validDefinition.baseStats.health == 0)

local nilClone, nilCloneStatus = PetSpeciesStatsData.cloneDefinition("sample-species", nil)
expect("invalid species definition clone fails safely", nilClone == nil and nilCloneStatus == "INVALID_DEFINITION")

local clonedCatalog, clonedCatalogStatus = PetSpeciesStatsData.cloneCatalog(validCatalog)
assert(clonedCatalog ~= nil, tostring(clonedCatalogStatus))
clonedCatalog["sample-species"].baseStats.attack = 999
expect("cloned catalog does not mutate source", validCatalog["sample-species"].baseStats.attack == 0)

print("[PetKingdoms Test] PetSpeciesStatsData smoke tests completed.")
