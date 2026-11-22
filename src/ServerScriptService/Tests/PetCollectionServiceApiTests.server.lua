--!strict
-- Studio-only API boundary tests for pet XP persistence.
-- These checks require no Player instance and perform no DataStore writes.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local services = game:GetService("ServerScriptService"):WaitForChild("Services")
local PetCollectionService = require(services:WaitForChild("PetCollectionService"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

expect(
	"legacy non-idempotent XP entry point is not exposed",
	(PetCollectionService :: any).grantExperience == nil
)
expect(
	"non-idempotent progression XP entry point is not exposed",
	(PetCollectionService :: any).grantExperienceWithProgress == nil
)
expect(
	"only stable reward-ID XP write entry point is exposed",
	type(PetCollectionService.grantExperienceWithProgressOnce) == "function"
)

print("[PetKingdoms Test] PetCollectionService API boundary tests completed.")
