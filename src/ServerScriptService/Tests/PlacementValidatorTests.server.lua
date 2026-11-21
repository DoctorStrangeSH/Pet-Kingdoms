--!strict
-- Studio-only smoke tests for the pure placement validator.
-- These tests do not mutate player data, create Instances, or charge currency.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local services = script.Parent.Parent:WaitForChild("Services")
local Catalog = require(services:WaitForChild("BuildingCatalog"))
local PlacementValidator = require(services:WaitForChild("PlacementValidator"))

local function makeIsland(): any
	return {
		ownerUserId = 1001,
		boundsWidth = 10,
		boundsDepth = 10,
		buildings = {},
	}
end

local function check(name: string, request: any, island: any, playerUserId: number, expectedCode: string, catalogOverride: any?)
	local result = PlacementValidator.validate(playerUserId, request, island, catalogOverride or Catalog)
	assert(result.code == expectedCode, string.format(
		"%s: expected %s, got %s",
		name,
		expectedCode,
		result.code
	))
	print("[PetKingdoms Test] PASS:", name)
end

local island = makeIsland()
check("valid placement", {
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 0,
}, island, 1001, "VALID")

check("exact boundary fit", {
	catalogId = "main_house",
	x = 7,
	z = 7,
	rotation = 0,
}, island, 1001, "VALID")

check("out of bounds", {
	catalogId = "main_house",
	x = 8,
	z = 7,
	rotation = 0,
}, island, 1001, "OUT_OF_BOUNDS")

check("negative coordinate", {
	catalogId = "main_house",
	x = -1,
	z = 0,
	rotation = 0,
}, island, 1001, "OUT_OF_BOUNDS")

check("fractional coordinate", {
	catalogId = "main_house",
	x = 1.5,
	z = 0,
	rotation = 0,
}, island, 1001, "INVALID_REQUEST")

check("unsupported rotation", {
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 45,
}, island, 1001, "ROTATION_NOT_ALLOWED")

check("wrong island owner", {
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 0,
}, island, 2002, "INVALID_OR_UNOWNED_ISLAND")

check("unknown building", {
	catalogId = "client_supplied_fake_building",
	x = 0,
	z = 0,
	rotation = 0,
}, island, 1001, "UNKNOWN_BUILDING")

local occupiedIsland = makeIsland()
table.insert(occupiedIsland.buildings, {
	instanceId = "building-1",
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 0,
})

check("overlap rejected", {
	catalogId = "pet_house",
	x = 2,
	z = 2,
	rotation = 0,
}, occupiedIsland, 1001, "FOOTPRINT_OVERLAP")

check("edge adjacency accepted", {
	catalogId = "pet_house",
	x = 3,
	z = 0,
	rotation = 0,
}, occupiedIsland, 1001, "VALID")

check("moving building ignores its old footprint", {
	catalogId = "main_house",
	x = 5,
	z = 5,
	rotation = 90,
	movingInstanceId = "building-1",
}, occupiedIsland, 1001, "VALID")

check("spoofed move target rejected", {
	catalogId = "main_house",
	x = 5,
	z = 5,
	rotation = 0,
	movingInstanceId = "not-owned",
}, occupiedIsland, 1001, "MOVE_TARGET_NOT_FOUND")


local lockedCatalog = {
	locked_house = {
		id = "locked_house",
		footprintWidth = 2,
		footprintDepth = 3,
		allowedRotations = {
			[0] = true,
			[90] = true,
			[180] = true,
			[270] = true,
		},
		defaultUnlocked = false,
	},
}
check("locked building rejected", {
	catalogId = "locked_house",
	x = 0,
	z = 0,
	rotation = 0,
}, makeIsland(), 1001, "BUILDING_LOCKED", lockedCatalog)

local unlockedIsland = makeIsland()
unlockedIsland.unlockedBuildingIds = { locked_house = true }
local unlockedResult = PlacementValidator.validate(1001, {
	catalogId = "locked_house",
	x = 0,
	z = 0,
	rotation = 90,
}, unlockedIsland, lockedCatalog)
assert(unlockedResult.code == "VALID", "unlocked rectangular building should allow 90-degree rotation")
assert(unlockedResult.footprintWidth == 3 and unlockedResult.footprintDepth == 2, "rotated footprint should swap dimensions")
print("[PetKingdoms Test] PASS: unlocked rectangular building rotation")

local malformedMoveIsland = makeIsland()
table.insert(malformedMoveIsland.buildings, {
	instanceId = "broken-building",
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 45,
})
check("malformed moved building rejected", {
	catalogId = "main_house",
	x = 5,
	z = 5,
	rotation = 0,
	movingInstanceId = "broken-building",
}, malformedMoveIsland, 1001, "ISLAND_STATE_INVALID")

local duplicateIsland = makeIsland()
table.insert(duplicateIsland.buildings, {
	instanceId = "duplicate",
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 0,
})
table.insert(duplicateIsland.buildings, {
	instanceId = "duplicate",
	catalogId = "pet_house",
	x = 4,
	z = 4,
	rotation = 0,
})
check("duplicate instance IDs rejected", {
	catalogId = "main_house",
	x = 7,
	z = 7,
	rotation = 0,
}, duplicateIsland, 1001, "ISLAND_STATE_INVALID")

local nan = 0 / 0
check("NaN coordinate rejected", {
	catalogId = "main_house",
	x = nan,
	z = 0,
	rotation = 0,
}, makeIsland(), 1001, "INVALID_REQUEST")

print("[PetKingdoms Test] Placement validator smoke tests completed.")
