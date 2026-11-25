--!strict
-- Studio-only tests for preserving building progression during a move.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local Factory = require(services:WaitForChild("BuildingRecordFactory"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local existing = {
	instanceId = "pet-house-001",
	catalogId = "pet_house",
	x = 3,
	z = 4,
	rotation = 90,
	upgradeLevel = 2,
}
local validation = {
	ok = true,
	x = 8,
	z = 6,
	rotation = 180,
}

local moved = Factory.moved(existing, validation)
expect("move keeps stable building instance ID", moved.instanceId == existing.instanceId)
expect("move keeps stable catalog ID", moved.catalogId == existing.catalogId)
expect("move updates grid coordinates", moved.x == 8 and moved.z == 6)
expect("move updates rotation", moved.rotation == 180)
expect("move preserves level-2 upgrade progression", moved.upgradeLevel == 2)
expect("move does not mutate the previous saved record",
	existing.x == 3 and existing.z == 4 and existing.rotation == 90 and existing.upgradeLevel == 2)

local legacyRecord = {
	instanceId = "legacy-fence-001",
	catalogId = "wooden_fence",
	x = 1,
	z = 1,
	rotation = 0,
}
local movedLegacy = Factory.moved(legacyRecord, validation)
expect("legacy level-1 record remains without a synthetic upgrade level", movedLegacy.upgradeLevel == nil)

print("[PetKingdoms Test] BuildingRecordFactory tests completed.")
