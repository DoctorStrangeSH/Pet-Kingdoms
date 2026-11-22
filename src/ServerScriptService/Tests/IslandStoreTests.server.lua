--!strict
-- Studio-only contract tests for IslandStore's input validation.
-- The input-contract checks avoid DataStore access; the fencing scenario below
-- writes synthetic test records and requires a dedicated test universe.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local services = script.Parent.Parent:WaitForChild("Services")
local IslandStore = require(services:WaitForChild("IslandStore"))
local IslandData = require(services:WaitForChild("IslandData"))
local BuildingJournal = require(services:WaitForChild("IslandBuildingJournalData"))

local invalidOk, invalidCode = IslandStore.load(0)
assert(not invalidOk and invalidCode == "INVALID_USER_ID", "invalid user ID should be rejected before DataStore access")
print("[PetKingdoms Test] PASS: IslandStore rejects invalid user ID before DataStore access")

local saveOk, saveCode = IslandStore.save({})
assert(not saveOk and saveCode == "INVALID_PROFILE", "invalid profile should be rejected before DataStore access")
print("[PetKingdoms Test] PASS: IslandStore rejects invalid profile before DataStore access")

-- Integration scenario: run only in a dedicated test universe with API access.
-- Synthetic user keys are intentionally unique; these records are test data.
local syntheticUserId = 1_000_000_000 + math.random(1, 900_000_000)
local seed = IslandData.create(syntheticUserId, 10, 10)
assert(seed ~= nil, "synthetic profile should be created")
-- Remove newer fields to emulate a legacy schema-v1 profile.
seed.buildingOperations = nil
seed.resourceNodes = nil

local claimAOk, profileA, claimAStatus = IslandStore.claimSession(seed)
assert(claimAOk, "first session claim failed: " .. claimAStatus)
assert(type(profileA.buildingOperations) == "table" and #profileA.buildingOperations == 0,
	"legacy profile claim should migrate an empty building operation ledger")
assert(type(profileA.resourceNodes) == "table" and #profileA.resourceNodes == 0,
	"legacy profile claim should migrate an empty resource node state list")

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
	and receiptLoaded.resourceNodes[1].nodeId == "WoodNode_A",
	"building receipt and resource node cooldown should survive DataStore save/load")

-- A delayed loader holding the original generation-zero snapshot must not
-- supersede the first session after its claim has committed.
local staleClaimOk, _, staleClaimStatus = IslandStore.claimSession(seed)
assert(not staleClaimOk and staleClaimStatus == "SESSION_CLAIM_REJECTED", "stale loader must not claim over a newer generation")

local claimBOk, profileB, claimBStatus = IslandStore.claimSession(profileA)
assert(claimBOk, "second sequential session claim failed: " .. claimBStatus)
assert(profileB.sessionGeneration > profileA.sessionGeneration, "new claim must increment generation")

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
print("[PetKingdoms Test] IslandStore contract tests completed.")
