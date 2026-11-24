--!strict
-- Studio-only contract tests for IslandStore's input validation.
-- The input-contract checks avoid DataStore access; the fencing scenario below
-- writes synthetic test records and requires a dedicated test universe.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
if not RunService:IsStudio() then
	return
end

local services = script.Parent.Parent:WaitForChild("Services")
local IslandStore = require(services:WaitForChild("IslandStore"))
local IslandData = require(services:WaitForChild("IslandData"))
local BuildingJournal = require(services:WaitForChild("IslandBuildingJournalData"))
local IslandExpansion = require(services:WaitForChild("IslandExpansion"))

local invalidOk, invalidCode = IslandStore.load(0)
assert(not invalidOk and invalidCode == "INVALID_USER_ID", "invalid user ID should be rejected before DataStore access")
print("[PetKingdoms Test] PASS: IslandStore rejects invalid user ID before DataStore access")

local saveOk, saveCode = IslandStore.save({})
assert(not saveOk and saveCode == "INVALID_PROFILE", "invalid profile should be rejected before DataStore access")
print("[PetKingdoms Test] PASS: IslandStore rejects invalid profile before DataStore access")

-- Never write synthetic records during ordinary Studio play. Opt in only
-- after opening a dedicated test universe with Studio API access enabled.
if Workspace:GetAttribute("RunIslandStoreIntegrationTests") ~= true then
	print("[PetKingdoms Test] SKIP: set Workspace.RunIslandStoreIntegrationTests = true in a dedicated test universe to run DataStore integration checks.")
	return
end

-- Synthetic user keys are intentionally unique; these records are test data.
local syntheticUserId = 1_000_000_000 + math.random(1, 900_000_000)
local function runIntegrationScenario()
	local seed = IslandData.create(syntheticUserId, 10, 10)
	assert(seed ~= nil, "synthetic profile should be created")
	-- Remove newer fields to emulate a legacy schema-v1 profile.
	seed.buildingOperations = nil
	seed.resourceNodes = nil
	seed.questProgress = nil
	seed.trackedQuestId = nil
	
	local claimAOk, profileA, claimAStatus = IslandStore.claimSession(seed)
	assert(claimAOk, "first session claim failed: " .. claimAStatus)
	assert(type(profileA.buildingOperations) == "table" and #profileA.buildingOperations == 0,
		"legacy profile claim should migrate an empty building operation ledger")
	assert(type(profileA.resourceNodes) == "table" and #profileA.resourceNodes == 0,
		"legacy profile claim should migrate an empty resource node state list")
	assert(type(profileA.questProgress) == "table"
		and profileA.questProgress.gather_wood.count == 0
		and profileA.questProgress.gather_stone.count == 0,
		"legacy profile claim should migrate default introductory quest progress")
	assert(profileA.trackedQuestId == "gather_wood",
		"legacy profile claim should migrate the default tracked quest")
	
	-- Build a representative island snapshot before saving: a placed house,
	-- non-default wallet, expanded plot and a resource node on cooldown.
	local persistenceBuildings = {
		{ instanceId = "store-test-main-house", catalogId = "main_house", x = 1, z = 1, rotation = 90 },
		{ instanceId = "store-test-pet-house", catalogId = "pet_house", x = 5, z = 1, rotation = 0, upgradeLevel = 2 },
		{ instanceId = "store-test-stone-path", catalogId = "stone_path", x = 9, z = 1, rotation = 0 },
		{ instanceId = "store-test-lantern", catalogId = "garden_lantern", x = 10, z = 1, rotation = 0 },
		{ instanceId = "store-test-flower-bed", catalogId = "flower_bed", x = 11, z = 1, rotation = 0 },
		{ instanceId = "store-test-fence", catalogId = "wooden_fence", x = 12, z = 1, rotation = 0 },
	}
	for _, building in ipairs(persistenceBuildings) do
		table.insert(profileA.buildings, building)
	end
	profileA.resources = { wood = 17, stone = 9, gold = 4, gems = 2 }
	profileA.questProgress = {
		gather_wood = { count = 2 },
		gather_stone = { count = 1 },
	}
	profileA.trackedQuestId = "gather_stone"
	local expandedProfile, expansionCode = IslandExpansion.expandProfile(profileA)
	assert(expandedProfile ~= nil and expansionCode == "EXPANDED", "synthetic island should expand before persistence")
	profileA = expandedProfile
	
	local gatheredAt = os.time()
	profileA.resourceNodes = {
		{ nodeId = "WoodNode_A", resourceId = "wood", lastGatheredAt = gatheredAt, availableAt = gatheredAt + 60 },
	}
	
	local receiptRevision = profileA.revision + 1
	local receiptLedger, receiptCode = BuildingJournal.append(
		profileA.buildingOperations,
		"store-test-request",
		"place|test|1|1|0",
		"place",
		{ ok = true, code = "BUILDING_PLACED", instanceId = "store-test-building" },
		os.time(),
		receiptRevision
	)
	assert(receiptLedger ~= nil and receiptCode == "RECORDED", "synthetic building receipt should be created")
	profileA.buildingOperations = receiptLedger
	profileA.revision = receiptRevision
	local receiptSaveOk, receiptSaveCode = IslandStore.save(profileA)
	assert(receiptSaveOk, "building receipt should persist: " .. receiptSaveCode)
	
	local receiptLoadOk, receiptLoaded = IslandStore.load(syntheticUserId)
	assert(receiptLoadOk and receiptLoaded ~= nil
		and #receiptLoaded.buildingOperations == 1
		and receiptLoaded.buildingOperations[1].requestId == "store-test-request"
		and #receiptLoaded.resourceNodes == 1
		and receiptLoaded.resourceNodes[1].nodeId == "WoodNode_A"
		and #receiptLoaded.buildings == 6
		and receiptLoaded.buildings[1].instanceId == "store-test-main-house"
		and receiptLoaded.buildings[1].catalogId == "main_house"
		and receiptLoaded.buildings[1].x == 5
		and receiptLoaded.buildings[1].z == 5
		and receiptLoaded.buildings[1].rotation == 90
		and receiptLoaded.buildings[2].instanceId == "store-test-pet-house"
		and receiptLoaded.buildings[2].catalogId == "pet_house"
		and receiptLoaded.buildings[2].x == 9
		and receiptLoaded.buildings[2].z == 5
		and receiptLoaded.buildings[2].upgradeLevel == 2
		and receiptLoaded.buildings[3].catalogId == "stone_path"
		and receiptLoaded.buildings[3].x == 13
		and receiptLoaded.buildings[4].catalogId == "garden_lantern"
		and receiptLoaded.buildings[4].x == 14
		and receiptLoaded.buildings[5].catalogId == "flower_bed"
		and receiptLoaded.buildings[5].x == 15
		and receiptLoaded.buildings[6].catalogId == "wooden_fence"
		and receiptLoaded.buildings[6].x == 16
		and receiptLoaded.resources.wood == 17
		and receiptLoaded.resources.stone == 9
		and receiptLoaded.resources.gold == 4
		and receiptLoaded.resources.gems == 2
		and receiptLoaded.expansionLevel == 1
		and receiptLoaded.boundsWidth == 18
		and receiptLoaded.boundsDepth == 18
		and receiptLoaded.questProgress.gather_wood.count == 2
		and receiptLoaded.questProgress.gather_stone.count == 1
		and receiptLoaded.trackedQuestId == "gather_stone",
		"all six catalog buildings, exact grid positions, wallet, expansion and cooldown should survive DataStore save/load")
	print("[PetKingdoms Test] PASS: all six building types, wallet, expansion bounds, cooldown and quest state survive save/load")
	
	-- A delayed loader holding the original generation-zero snapshot must not
	-- supersede the first session after its claim has committed.
	local staleClaimOk, _, staleClaimStatus = IslandStore.claimSession(seed)
	assert(not staleClaimOk and staleClaimStatus == "SESSION_CLAIM_REJECTED", "stale loader must not claim over a newer generation")
	
	local claimBOk, profileB, claimBStatus = IslandStore.claimSession(profileA)
	assert(claimBOk, "second sequential session claim failed: " .. claimBStatus)
	assert(profileB.sessionGeneration > profileA.sessionGeneration, "new claim must increment generation")
	assert(profileB.questProgress.gather_wood.count == 2
		and profileB.questProgress.gather_stone.count == 1
		and profileB.trackedQuestId == "gather_stone",
		"quest progress and tracked objective must remain available to the next claimed session")
	
	profileA.revision += 1
	local staleSaveOk, staleSaveCode = IslandStore.save(profileA)
	assert(not staleSaveOk and staleSaveCode == "STALE_SESSION_OR_REVISION", "stale generation must not save")
	
	profileB.revision += 1
	local currentSaveOk, currentSaveCode = IslandStore.save(profileB)
	assert(currentSaveOk, "current generation should save: " .. currentSaveCode)
	
	-- A retry may arrive after the same revision was already persisted. It must
	-- be acknowledged without replacing the newer stored profile.
	local alreadyPersistedSnapshot = table.clone(profileB)
	alreadyPersistedSnapshot.revision -= 1
	local alreadyPersistedOk, alreadyPersistedCode = IslandStore.save(alreadyPersistedSnapshot)
	assert(alreadyPersistedOk,
		"same-generation older snapshot should be acknowledged as already durable: " .. alreadyPersistedCode)
	
	print("[PetKingdoms Test] PASS: DataStore fencing rejects stale session generation and accepts current generation")
	
end

local scenarioOk, scenarioError = xpcall(runIntegrationScenario, debug.traceback)
local cleanupOk, cleanupError = pcall(function()
	DataStoreService:GetDataStore("PetKingdoms_Islands_v1"):RemoveAsync("player_" .. tostring(syntheticUserId))
end)
if not cleanupOk then
	warn("[PetKingdoms Test] Failed to remove synthetic island profile:", cleanupError)
end
assert(cleanupOk, "synthetic island profile cleanup failed")
assert(scenarioOk, "IslandStore integration scenario failed: " .. tostring(scenarioError))
print("[PetKingdoms Test] IslandStore contract tests completed.")
