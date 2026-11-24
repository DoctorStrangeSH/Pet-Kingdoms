--!strict
-- Studio-only tests for versioned island profile creation and validation.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local services = script.Parent.Parent:WaitForChild("Services")
local Catalog = require(services:WaitForChild("BuildingCatalog"))
local IslandData = require(services:WaitForChild("IslandData"))
local IslandExpansion = require(services:WaitForChild("IslandExpansion"))
local QuestProgressData = require(services:WaitForChild("QuestProgressData"))

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
expect("new island profile starts at expansion level zero", profile.expansionLevel == 0)
expect("legacy profile without expansion level remains valid", (function()
	local legacy = table.clone(profile)
	legacy.expansionLevel = nil
	local legacyOk = IslandData.validate(legacy, 1001, Catalog)
	return legacyOk
end)())
local invalidExpansionProfile = table.clone(profile)
invalidExpansionProfile.expansionLevel = 99
local invalidExpansionOk, invalidExpansionCode = IslandData.validate(invalidExpansionProfile, 1001, Catalog)
expect("invalid saved expansion level rejected", not invalidExpansionOk and invalidExpansionCode == "INVALID_EXPANSION_LEVEL")

local expansionSource = IslandData.create(1001, 24, 24)
table.insert(expansionSource.buildings, { instanceId = "keep-position", catalogId = "main_house", x = 8, z = 6, rotation = 0 })
local expandedProfile, expansionCode = IslandExpansion.expandProfile(expansionSource)
expect("profile expands by one level", expandedProfile ~= nil and expansionCode == "EXPANDED"
	and expandedProfile.expansionLevel == 1 and expandedProfile.boundsWidth == 32 and expandedProfile.boundsDepth == 32)
expect("existing building grid coordinates shift by half expansion", expandedProfile ~= nil
	and expandedProfile.buildings[1].x == 12 and expandedProfile.buildings[1].z == 10)
local originalWorldX = (8 + 1 - 24 / 2)
local expandedWorldX = (expandedProfile.buildings[1].x + 1 - expandedProfile.boundsWidth / 2)
local originalWorldZ = (6 + 1 - 24 / 2)
local expandedWorldZ = (expandedProfile.buildings[1].z + 1 - expandedProfile.boundsDepth / 2)
expect("existing building world position remains unchanged", originalWorldX == expandedWorldX and originalWorldZ == expandedWorldZ)
local expandedTwice, twiceCode = IslandExpansion.expandProfile(expandedProfile)
expect("second expansion reaches 40 by 40", expandedTwice ~= nil and twiceCode == "EXPANDED"
	and expandedTwice.boundsWidth == 40 and expandedTwice.boundsDepth == 40 and expandedTwice.expansionLevel == 2)
local thirdExpansion, thirdCode = IslandExpansion.expandProfile(expandedTwice)
expect("expansion beyond maximum rejected", thirdExpansion == nil and thirdCode == "MAX_EXPANSION_REACHED")
expect("source profile is not mutated by expansion", expansionSource.expansionLevel == 0
	and expansionSource.boundsWidth == 24 and expansionSource.buildings[1].x == 8)

expect("new island profile starts with an empty building operation journal",
	type(profile.buildingOperations) == "table" and #profile.buildingOperations == 0)
expect("new island profile starts with no resource cooldowns",
	type(profile.resourceNodes) == "table" and #profile.resourceNodes == 0)

expect("new island profile starts with introductory quest progress",
	type(profile.questProgress) == "table" and profile.questProgress.gather_wood.count == 0
		and profile.questProgress.gather_stone.count == 0)
expect("new island profile tracks the first introductory quest",
	profile.trackedQuestId == "gather_wood")
local invalidTrackedQuestProfile = table.clone(profile)
invalidTrackedQuestProfile.trackedQuestId = "unknown_quest"
local invalidTrackedQuestOk, invalidTrackedQuestCode =
	IslandData.validate(invalidTrackedQuestProfile, 1001, Catalog)
expect("unknown tracked quest ID is rejected",
	not invalidTrackedQuestOk and invalidTrackedQuestCode == "INVALID_TRACKED_QUEST")
local legacyTrackedQuestProfile = table.clone(profile)
legacyTrackedQuestProfile.trackedQuestId = nil
local legacyTrackedQuestOk = IslandData.validate(legacyTrackedQuestProfile, 1001, Catalog)
expect("legacy profile without tracked quest remains valid", legacyTrackedQuestOk)
local legacyQuestProfile = table.clone(profile)
legacyQuestProfile.questProgress = nil
local legacyQuestValid = IslandData.validate(legacyQuestProfile, 1001, Catalog)
expect("legacy profile without quest progress remains valid", legacyQuestValid)
local invalidQuestProfile = table.clone(profile)
invalidQuestProfile.questProgress = { gather_wood = { count = 99 }, gather_stone = { count = 0 } }
local invalidQuestValid, invalidQuestCode = IslandData.validate(invalidQuestProfile, 1001, Catalog)
expect("invalid saved quest progress is rejected", not invalidQuestValid
	and string.find(invalidQuestCode, "INVALID_QUEST_PROGRESS:", 1, true) == 1)

local malformedResourceNodesProfile = IslandData.create(1001, 10, 10)
malformedResourceNodesProfile.resourceNodes = {
	{ nodeId = "WoodNode_A", resourceId = "stone", lastGatheredAt = 10, availableAt = 70 },
}
local malformedResourceNodesOk, malformedResourceNodesCode =
	IslandData.validate(malformedResourceNodesProfile, 1001, Catalog)
expect("resource node state cannot award a different resource",
	not malformedResourceNodesOk and malformedResourceNodesCode == "INVALID_RESOURCE_NODES:INVALID_ENTRY")

local duplicateResourceNodesProfile = IslandData.create(1001, 10, 10)
duplicateResourceNodesProfile.resourceNodes = {
	{ nodeId = "WoodNode_A", resourceId = "wood", lastGatheredAt = 10, availableAt = 70 },
	{ nodeId = "WoodNode_A", resourceId = "wood", lastGatheredAt = 10, availableAt = 70 },
}
local duplicateResourceNodesOk, duplicateResourceNodesCode =
	IslandData.validate(duplicateResourceNodesProfile, 1001, Catalog)
expect("duplicate resource node states are rejected",
	not duplicateResourceNodesOk and duplicateResourceNodesCode == "INVALID_RESOURCE_NODES:INVALID_ENTRY")


local malformedBuildingJournalProfile = IslandData.create(1001, 10, 10)
malformedBuildingJournalProfile.buildingOperations = {
	{ requestId = "bad", fingerprint = "place", action = "place", createdAt = 1, revision = 1, result = { ok = false } },
}
local malformedJournalOk, malformedJournalCode =
	IslandData.validate(malformedBuildingJournalProfile, 1001, Catalog)
expect("malformed building operation receipt rejected",
	not malformedJournalOk and string.find(malformedJournalCode, "INVALID_BUILDING_LEDGER:", 1, true) == 1)

local futureReceiptProfile = IslandData.create(1001, 10, 10)
futureReceiptProfile.buildingOperations = {
	{
		requestId = "future-receipt",
		fingerprint = "place|pet_house|1|1|0",
		action = "place",
		createdAt = os.time(),
		revision = 1,
		result = { ok = true, code = "BUILDING_PLACED", instanceId = "future-building" },
	},
}
local futureReceiptOk, futureReceiptCode = IslandData.validate(futureReceiptProfile, 1001, Catalog)
expect("building receipt ahead of saved profile revision is rejected",
	not futureReceiptOk and futureReceiptCode == "INVALID_BUILDING_LEDGER:REVISION_AHEAD")

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

local upgradedProfile = IslandData.create(1001, 10, 10)
table.insert(upgradedProfile.buildings, {
	instanceId = "upgraded-pet-house",
	catalogId = "pet_house",
	x = 0,
	z = 0,
	rotation = 0,
	upgradeLevel = 2,
})
local upgradedOk = IslandData.validate(upgradedProfile, 1001, Catalog)
expect("valid saved building upgrade level accepted", upgradedOk)
local invalidUpgradeProfile = IslandData.create(1001, 10, 10)
table.insert(invalidUpgradeProfile.buildings, {
	instanceId = "invalid-upgrade",
	catalogId = "pet_house",
	x = 0,
	z = 0,
	rotation = 0,
	upgradeLevel = 4,
})
local invalidUpgradeOk, invalidUpgradeCode = IslandData.validate(invalidUpgradeProfile, 1001, Catalog)
expect("saved building upgrade above catalogue maximum rejected",
	not invalidUpgradeOk and invalidUpgradeCode == "INVALID_BUILDING_UPGRADE_LEVEL")
local fractionalUpgradeProfile = IslandData.create(1001, 10, 10)
table.insert(fractionalUpgradeProfile.buildings, {
	instanceId = "fractional-upgrade",
	catalogId = "pet_house",
	x = 0,
	z = 0,
	rotation = 0,
	upgradeLevel = 1.5,
})
local fractionalUpgradeOk, fractionalUpgradeCode = IslandData.validate(fractionalUpgradeProfile, 1001, Catalog)
expect("fractional saved building upgrade level rejected",
	not fractionalUpgradeOk and fractionalUpgradeCode == "INVALID_BUILDING_UPGRADE_LEVEL")

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
