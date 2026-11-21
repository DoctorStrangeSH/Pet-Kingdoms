--!strict
-- Studio-only tests for versioned island profile creation and validation.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local services = script.Parent.Parent:WaitForChild("Services")
local Catalog = require(services:WaitForChild("BuildingCatalog"))
local IslandData = require(services:WaitForChild("IslandData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local profile = IslandData.create(1001, 10, 10)
expect("valid profile created", profile ~= nil)
expect("invalid owner rejected", IslandData.create(0, 10, 10) == nil)
expect("invalid bounds rejected", IslandData.create(1001, 0, 10) == nil)

local valid, code = IslandData.validate(profile, 1001, Catalog)
expect("empty profile validates", valid and code == "VALID")
local wrongOwner, ownerCode = IslandData.validate(profile, 2002, Catalog)
expect("owner mismatch rejected", not wrongOwner and ownerCode == "OWNER_MISMATCH")

local builtProfile = IslandData.create(1001, 10, 10)
table.insert(builtProfile.buildings, {
	instanceId = "house-1",
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 0,
})
local builtOk = IslandData.validate(builtProfile, 1001, Catalog)
expect("valid building record accepted", builtOk)

local overlapProfile = IslandData.create(1001, 10, 10)
table.insert(overlapProfile.buildings, {
	instanceId = "house-1",
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 0,
})
table.insert(overlapProfile.buildings, {
	instanceId = "pet-house-1",
	catalogId = "pet_house",
	x = 2,
	z = 2,
	rotation = 0,
})
local overlapOk, overlapCode = IslandData.validate(overlapProfile, 1001, Catalog)
expect("overlapping saved buildings rejected", not overlapOk and overlapCode == "BUILDINGS_OVERLAP")

local duplicateProfile = IslandData.create(1001, 10, 10)
table.insert(duplicateProfile.buildings, {
	instanceId = "duplicate",
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 0,
})
table.insert(duplicateProfile.buildings, {
	instanceId = "duplicate",
	catalogId = "pet_house",
	x = 4,
	z = 4,
	rotation = 0,
})
local duplicateOk = IslandData.validate(duplicateProfile, 1001, Catalog)
expect("duplicate building IDs rejected", not duplicateOk)

local badVersion = IslandData.create(1001, 10, 10)
badVersion.schemaVersion = 999
local versionOk, versionCode = IslandData.validate(badVersion, 1001, Catalog)
expect("unknown schema version rejected", not versionOk and versionCode == "UNSUPPORTED_SCHEMA_VERSION")

local unknownUnlockProfile = IslandData.create(1001, 10, 10)
unknownUnlockProfile.unlockedBuildingIds.unknown_building = true
local unknownUnlockOk, unknownUnlockCode = IslandData.validate(unknownUnlockProfile, 1001, Catalog)
expect("unknown catalog unlock rejected", not unknownUnlockOk and unknownUnlockCode == "INVALID_UNLOCK_RECORD")

print("[PetKingdoms Test] IslandData smoke tests completed.")
