--!strict
-- Studio-only tests for the balance-agnostic evolution catalog contract.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local EvolutionData = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetEvolutionData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local emptyValid, emptyStatus = EvolutionData.validateCatalog({})
expect("empty evolution catalog is valid before game design is approved", emptyValid and emptyStatus == "VALID")

local branchingCatalog = {
	{ evolutionId = "bunny_forest", sourceSpeciesId = "bunny", targetSpeciesId = "forest_bunny" },
	{ evolutionId = "bunny_sky", sourceSpeciesId = "bunny", targetSpeciesId = "sky_bunny" },
	{ evolutionId = "forest_ancient", sourceSpeciesId = "forest_bunny", targetSpeciesId = "ancient_forest_bunny" },
}
local branchingValid = EvolutionData.validateCatalog(branchingCatalog)
expect("branching and chained evolution catalog is valid", branchingValid)

local options = EvolutionData.getOptions(branchingCatalog, "bunny")
expect("source species returns all branch options", options ~= nil and #options == 2)
assert(options ~= nil)
options[1].targetSpeciesId = "tampered"
expect("returned options do not mutate source catalog", branchingCatalog[1].targetSpeciesId == "forest_bunny")

local duplicateIdValid, duplicateIdReason = EvolutionData.validateCatalog({
	{ evolutionId = "same", sourceSpeciesId = "bunny", targetSpeciesId = "forest_bunny" },
	{ evolutionId = "same", sourceSpeciesId = "bunny", targetSpeciesId = "sky_bunny" },
})
expect("duplicate evolution IDs are rejected", not duplicateIdValid and duplicateIdReason == "DUPLICATE_EVOLUTION_ID")

local selfValid, selfReason = EvolutionData.validateCatalog({
	{ evolutionId = "self", sourceSpeciesId = "bunny", targetSpeciesId = "bunny" },
})
expect("self evolution is rejected", not selfValid and selfReason == "SELF_EVOLUTION")

local cycleValid, cycleReason = EvolutionData.validateCatalog({
	{ evolutionId = "a_to_b", sourceSpeciesId = "bunny", targetSpeciesId = "forest_bunny" },
	{ evolutionId = "b_to_a", sourceSpeciesId = "forest_bunny", targetSpeciesId = "bunny" },
})
expect("cyclic evolution chains are rejected", not cycleValid and cycleReason == "EVOLUTION_CYCLE")

local malformedValid = EvolutionData.validateCatalog({
	{ evolutionId = "invalid id", sourceSpeciesId = "bunny", targetSpeciesId = "forest_bunny" },
})
expect("malformed identifiers are rejected", not malformedValid)

local sparseValid, sparseReason = EvolutionData.validateCatalog({
	[1] = { evolutionId = "one", sourceSpeciesId = "bunny", targetSpeciesId = "forest_bunny" },
	[3] = { evolutionId = "three", sourceSpeciesId = "bunny", targetSpeciesId = "sky_bunny" },
})
expect("sparse catalog arrays are rejected", not sparseValid and sparseReason == "INVALID_CATALOG_COUNT")

print("[PetKingdoms Test] PetEvolutionData tests completed.")
