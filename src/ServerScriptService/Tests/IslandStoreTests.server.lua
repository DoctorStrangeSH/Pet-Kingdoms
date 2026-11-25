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
local IslandResources = require(services:WaitForChild("IslandResources"))

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
	
	-- Build a representative island, then run a full persisted lifecycle:
	-- place -> pay/upgrade -> move -> demolish -> save -> load.
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
	profileA.resources = { wood = 60, stone = 40, gold = 4, gems = 2 }
	profileA.questProgress = {
		gather_wood = { count = 2 },
		gather_stone = { count = 1 },
	}
	profileA.trackedQuestId = "gather_stone"
	local expandedProfile, expansionCode = IslandExpansion.expandProfile(profileA)
	assert(expandedProfile ~= nil and expansionCode == "EXPANDED", "synthetic island should expand before persistence")
	profileA = expandedProfile

	-- The pet house was built, upgraded twice, and moved before the final save.
	-- Apply both upgrade prices plus the original construction price atomically.
	local paid, paymentCode = IslandResources.spend(profileA.resources, {
		wood = 35,
		stone = 19,
	})
	assert(paid and paymentCode == "SPENT", "synthetic lifecycle should pay the configured building and upgrade costs")
	local petHouseRecord = profileA.buildings[2]
	petHouseRecord.x = 9
	petHouseRecord.z = 8
	petHouseRecord.rotation = 180
	petHouseRecord.upgradeLevel = 3

	-- Demolish one ordinary building: it must be absent after reconnect.
	local demolishedRecord = table.remove(profileA.buildings, 4)
	assert(demolishedRecord ~= nil and demolishedRecord.instanceId == "store-test-lantern",
		"synthetic lifecycle should remove the selected garden lantern")

	local gatheredAt = os.time()
	profileA.resourceNodes = {
		{ nodeId = "WoodNode_A", resourceId = "wood", lastGatheredAt = gatheredAt, availableAt = gatheredAt + 60 },
	}

	local function appendLifecycleReceipt(requestId: string, fingerprint: string, action: string, result: any)
		local nextRevision = profileA.revision + 1
		local nextLedger, appendCode = BuildingJournal.append(
			profileA.buildingOperations,
			requestId,
			fingerprint,
			action,
			result,
			os.time(),
			nextRevision
		)
		assert(nextLedger ~= nil and appendCode == "RECORDED",
			"synthetic " .. action .. " receipt should be recorded: " .. appendCode)
		profileA.buildingOperations = nextLedger
		profileA.revision = nextRevision
	end

	appendLifecycleReceipt("store-test-place", "place|pet_house|5|1|0", "place", {
		ok = true, code = "BUILDING_PLACED", instanceId = "store-test-pet-house",
	})
	appendLifecycleReceipt("store-test-upgrade", "upgrade|store-test-pet-house", "upgrade", {
		ok = true, code = "BUILDING_UPGRADED", instanceId = "store-test-pet-house", upgradeLevel = 3,
	})
	appendLifecycleReceipt("store-test-move", "move|store-test-pet-house|9|8|180", "move", {
		ok = true, code = "BUILDING_PLACED", instanceId = "store-test-pet-house",
		x = 9, z = 8, rotation = 180,
	})
	appendLifecycleReceipt("store-test-demolish", "demolish|store-test-lantern", "demolish", {
		ok = true, code = "BUILDING_DEMOLISHED", instanceId = "store-test-lantern",
	})

	local receiptSaveOk, receiptSaveCode = IslandStore.save(profileA)
	assert(receiptSaveOk, "full building lifecycle should persist: " .. receiptSaveCode)

	local receiptLoadOk, receiptLoaded = IslandStore.load(syntheticUserId)
	assert(receiptLoadOk and receiptLoaded ~= nil
		and #receiptLoaded.buildingOperations == 4
		and receiptLoaded.buildingOperations[1].requestId == "store-test-place"
		and receiptLoaded.buildingOperations[2].requestId == "store-test-upgrade"
		and receiptLoaded.buildingOperations[3].requestId == "store-test-move"
		and receiptLoaded.buildingOperations[4].requestId == "store-test-demolish"
		and #receiptLoaded.resourceNodes == 1
		and receiptLoaded.resourceNodes[1].nodeId == "WoodNode_A"
		and #receiptLoaded.buildings == 5
		and receiptLoaded.buildings[1].instanceId == "store-test-main-house"
		and receiptLoaded.buildings[1].catalogId == "main_house"
		and receiptLoaded.buildings[1].x == 5
		and receiptLoaded.buildings[1].z == 5
		and receiptLoaded.buildings[1].rotation == 90
		and receiptLoaded.buildings[2].instanceId == "store-test-pet-house"
		and receiptLoaded.buildings[2].catalogId == "pet_house"
		and receiptLoaded.buildings[2].x == 9
		and receiptLoaded.buildings[2].z == 12
		and receiptLoaded.buildings[2].rotation == 180
		and receiptLoaded.buildings[2].upgradeLevel == 3
		and receiptLoaded.buildings[3].catalogId == "stone_path"
		and receiptLoaded.buildings[3].x == 13
		and receiptLoaded.buildings[4].catalogId == "flower_bed"
		and receiptLoaded.buildings[4].x == 15
		and receiptLoaded.buildings[5].catalogId == "wooden_fence"
		and receiptLoaded.buildings[5].x == 16
		and receiptLoaded.resources.wood == 25
		and receiptLoaded.resources.stone == 21
		and receiptLoaded.resources.gold == 4
		and receiptLoaded.resources.gems == 2
		and receiptLoaded.expansionLevel == 1
		and receiptLoaded.boundsWidth == 18
		and receiptLoaded.boundsDepth == 18
		and receiptLoaded.questProgress.gather_wood.count == 2
		and receiptLoaded.questProgress.gather_stone.count == 1
		and receiptLoaded.trackedQuestId == "gather_stone",
		"place/upgrade/move/demolish results, wallet, expanded bounds, cooldown and quest state should survive DataStore save/load")
	for _, savedBuilding in ipairs(receiptLoaded.buildings) do
		assert(savedBuilding.instanceId ~= "store-test-lantern",
			"demolished building must not return after reconnect")
	end
	print("[PetKingdoms Test] PASS: full place/upgrade/move/demolish lifecycle, wallet, bounds and cooldown survive save/load")

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
