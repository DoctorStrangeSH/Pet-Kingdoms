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

local claimAOk, profileA, claimAStatus = IslandStore.claimSession(seed)
assert(claimAOk, "first session claim failed: " .. claimAStatus)

local claimBOk, profileB, claimBStatus = IslandStore.claimSession(profileA)
assert(claimBOk, "second session claim failed: " .. claimBStatus)
assert(profileB.sessionGeneration > profileA.sessionGeneration, "new claim must increment generation")

profileA.revision += 1
local staleSaveOk, staleSaveCode = IslandStore.save(profileA)
assert(not staleSaveOk and staleSaveCode == "STALE_SESSION_OR_REVISION", "stale generation must not save")

profileB.revision += 1
local currentSaveOk, currentSaveCode = IslandStore.save(profileB)
assert(currentSaveOk, "current generation should save: " .. currentSaveCode)

print("[PetKingdoms Test] PASS: DataStore fencing rejects stale session generation and accepts current generation")
print("[PetKingdoms Test] IslandStore contract tests completed.")
