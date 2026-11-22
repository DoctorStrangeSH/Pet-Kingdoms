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
expect("new profile receives provisional starter wallet", profile.resources.wood == 2 and profile.resources.stone == 1)
local invalidWalletProfile = IslandData.create(1001, 10, 10)
invalidWalletProfile.resources = { wood = -1, stone = 1 }
local invalidWalletOk, invalidWalletCode = IslandData.validate(invalidWalletProfile, 1001, Catalog)
expect("negative resource balance rejected", not invalidWalletOk and invalidWalletCode == "INVALID_RESOURCE_BALANCE")
local unknownWalletProfile = IslandData.create(1001, 10, 10)
unknownWalletProfile.resources = { wood = 1, stone = 1, dragon_scale = 1 }
local unknownWalletOk, unknownWalletCode = IslandData.validate(unknownWalletProfile, 1001, Catalog)
expect("unknown resource ID rejected", not unknownWalletOk and unknownWalletCode == "INVALID_RESOURCE_BALANCE")
local overCapWalletProfile = IslandData.create(1001, 10, 10)
overCapWalletProfile.resources = { wood = 2_000_000_001, stone = 1, gold = 0, gems = 0 }
local overCapWalletOk, overCapWalletCode = IslandData.validate(overCapWalletProfile, 1001, Catalog)
expect("saved wallet above the live resource cap is rejected",
	not overCapWalletOk and overCapWalletCode == "INVALID_RESOURCE_BALANCE")

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

local sparseProfile = IslandData.create(1001, 10, 10)
sparseProfile.buildings[2] = {
	instanceId = "sparse-house",
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 0,
}
local sparseOk, sparseCode = IslandData.validate(sparseProfile, 1001, Catalog)
expect("sparse building list rejected", not sparseOk and sparseCode == "INVALID_BUILDING_LIST")

local keyedProfile = IslandData.create(1001, 10, 10)
keyedProfile.buildings.extra = {
	instanceId = "keyed-house",
	catalogId = "main_house",
	x = 0,
	z = 0,
	rotation = 0,
}
local keyedOk, keyedCode = IslandData.validate(keyedProfile, 1001, Catalog)
expect("dictionary building entry rejected", not keyedOk and keyedCode == "INVALID_BUILDING_LIST")

local oversizedProfile = IslandData.create(1001, 1000, 1000)
for index = 1, IslandData.MAX_BUILDINGS_PER_ISLAND + 1 do
	table.insert(oversizedProfile.buildings, {
		instanceId = "building-" .. tostring(index),
		catalogId = "main_house",
		x = (index - 1) * 4,
		z = 0,
		rotation = 0,
	})
end
local oversizedOk, oversizedCode = IslandData.validate(oversizedProfile, 1001, Catalog)
expect("oversized building list rejected", not oversizedOk and oversizedCode == "TOO_MANY_BUILDINGS")

print("[PetKingdoms Test] IslandData smoke tests completed.")
