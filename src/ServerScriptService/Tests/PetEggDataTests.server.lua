--!strict
-- Studio-only pure tests for the pet egg configuration and weighted selector.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local PetEggData = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetEggData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local catalog = {
	bunny = true,
	fox = true,
	owl = true,
}
local definition = {
	entries = {
		{ speciesId = "bunny", weight = 10 },
		{ speciesId = "fox", weight = 30 },
		{ speciesId = "owl", weight = 60 },
	},
}

local valid, status = PetEggData.validateDefinition("starter_egg", definition, catalog)
expect("valid weighted egg definition is accepted", valid and status == "VALID")

local cloned, cloneReason = PetEggData.cloneDefinition("starter_egg", definition, catalog)
expect("valid egg definition can be cloned", cloned ~= nil and cloneReason == nil)
assert(cloned ~= nil)
cloned.entries[1].weight = 999
expect("egg clone is isolated from source definition", definition.entries[1].weight == 10)

local first, firstReason = PetEggData.roll("starter_egg", definition, catalog, 0)
expect("zero random value selects first weighted entry", first == "bunny" and firstReason == nil)
local middle, middleReason = PetEggData.roll("starter_egg", definition, catalog, 0.1)
expect("weighted boundary advances to next entry", middle == "fox" and middleReason == nil)
local last, lastReason = PetEggData.roll("starter_egg", definition, catalog, 0.999999)
expect("upper random range selects final entry", last == "owl" and lastReason == nil)

local unknownSpecies = {
	entries = { { speciesId = "dragon", weight = 1 } },
}
local unknownValid, unknownReason = PetEggData.validateDefinition("starter_egg", unknownSpecies, catalog)
expect("species outside supplied catalog is rejected", not unknownValid and unknownReason == "UNKNOWN_SPECIES")

local duplicateSpecies = {
	entries = {
		{ speciesId = "bunny", weight = 1 },
		{ speciesId = "bunny", weight = 2 },
	},
}
local duplicateValid, duplicateReason = PetEggData.validateDefinition("starter_egg", duplicateSpecies, catalog)
expect("duplicate species entries are rejected", not duplicateValid and duplicateReason == "DUPLICATE_SPECIES")

local invalidWeight = {
	entries = { { speciesId = "bunny", weight = 0 } },
}
local weightValid, weightReason = PetEggData.validateDefinition("starter_egg", invalidWeight, catalog)
expect("zero weight is rejected", not weightValid and weightReason == "INVALID_WEIGHT")

local sparseEntries = {
	entries = {
		[1] = { speciesId = "bunny", weight = 1 },
		[3] = { speciesId = "fox", weight = 1 },
	},
}
local sparseValid, sparseReason = PetEggData.validateDefinition("starter_egg", sparseEntries, catalog)
expect("sparse entry arrays are rejected", not sparseValid and sparseReason == "INVALID_ENTRY_COUNT")

local unknownField = {
	entries = { { speciesId = "bunny", weight = 1, chance = 100 } },
}
local fieldValid, fieldReason = PetEggData.validateDefinition("starter_egg", unknownField, catalog)
expect("unapproved entry fields are rejected", not fieldValid and fieldReason == "UNKNOWN_ENTRY_FIELD")

local invalidRandom, invalidRandomReason = PetEggData.roll("starter_egg", definition, catalog, 1)
expect("random value outside zero-to-one range is rejected", invalidRandom == nil and invalidRandomReason == "INVALID_RANDOM_VALUE")

local hugeWeights = {
	entries = {
		{ speciesId = "bunny", weight = PetEggData.MAX_TOTAL_WEIGHT },
		{ speciesId = "fox", weight = 1 },
	},
}
local hugeValid, hugeReason = PetEggData.validateDefinition("starter_egg", hugeWeights, catalog)
expect("total weight overflow is rejected", not hugeValid and hugeReason == "TOTAL_WEIGHT_TOO_LARGE")

local empty = { entries = {} }
local emptyValid, emptyReason = PetEggData.validateDefinition("starter_egg", empty, catalog)
expect("empty egg table is rejected", not emptyValid and emptyReason == "EMPTY_ENTRIES")

print("[PetKingdoms Test] PetEggData tests completed.")
