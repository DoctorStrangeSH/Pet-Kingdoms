--!strict
-- Dedicated Studio/DataStore integration test for durable pet collection state.
-- This test is opt-in and must only run in a non-production test universe.
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then return end
if Workspace:GetAttribute("RunPetCollectionStoreIntegrationTests") ~= true then
	print("[PetKingdoms Test] Pet collection DataStore integration skipped; explicit test gate is disabled.")
	return
end

local sharedPets = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Pets")
local PetCollectionData = require(sharedPets:WaitForChild("PetCollectionData"))
local PetCollectionSessionData = require(sharedPets:WaitForChild("PetCollectionSessionData"))

local STORE_NAME = "PetKingdoms_PetCollections_v1"
local MAX_ATTEMPTS = 4
local syntheticUserId = 1_000_000_000 + math.random(1, 900_000_000)
local key = "player_" .. tostring(syntheticUserId)
local store = DataStoreService:GetDataStore(STORE_NAME)
local ownsSyntheticKey = false

local function updateStore(transform: (any) -> any): (boolean, any)
	local lastError = nil
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(function()
			return store:UpdateAsync(key, transform)
		end)
		if ok then return true, result end
		lastError = result
		if attempt < MAX_ATTEMPTS then task.wait(0.5 * (2 ^ (attempt - 1))) end
	end
	return false, lastError
end

local function runIntegrationScenario()
	local readOk, existing = pcall(function()
		return store:GetAsync(key)
	end)
	assert(readOk, "could not inspect synthetic collection key")
	assert(existing == nil, "random synthetic collection key unexpectedly already exists")
	ownsSyntheticKey = true

	local firstToken = HttpService:GenerateGUID(false)
	local claimStatus = "NOT_CLAIMED"
	local claimOk, profile = updateStore(function(current)
		local claimed, status = PetCollectionSessionData.claim(
			current,
			nil,
			firstToken,
			function()
				return PetCollectionData.createDefault(syntheticUserId)
			end
		)
		claimStatus = status
		return claimed
	end)
	assert(claimOk and type(profile) == "table" and claimStatus == "CLAIMED",
		"first collection session claim failed: " .. claimStatus)
	local valid, reason = PetCollectionData.validate(profile, syntheticUserId)
	assert(valid, "new collection profile is invalid: " .. reason)

	local function persistMutation(currentProfile: any, nextProfile: any): any
		local saveStatus = "NOT_SAVED"
		local saveOk, saved = updateStore(function(current)
			if not PetCollectionSessionData.owns(
				current,
				currentProfile.collectionSessionGeneration,
				currentProfile.collectionSessionToken
			) then
				saveStatus = "STALE_SESSION"
				return nil
			end
			if current.revision ~= currentProfile.revision
				or nextProfile.revision ~= current.revision + 1 then
				saveStatus = "STALE_OR_INVALID_REVISION"
				return nil
			end
			saveStatus = "SAVED"
			return nextProfile
		end)
		assert(saveOk, "collection mutation DataStore request failed: " .. tostring(saved))
		assert(saveStatus == "SAVED" and type(saved) == "table",
			"collection mutation was not committed: " .. saveStatus)
		local savedValid, savedReason = PetCollectionData.validate(saved, syntheticUserId)
		assert(savedValid, "saved collection snapshot is invalid: " .. savedReason)
		return saved
	end

	local now = os.time()
	local reserved, reserveStatus, reservedProfile = PetCollectionData.reservePetSlotOnce(
		profile,
		"hatch:store-round-trip",
		"bunny",
		4,
		now,
		"hatch:store-transaction"
	)
	assert(reserved and reserveStatus == "RESERVED" and reservedProfile ~= nil,
		"pet slot reservation failed: " .. reserveStatus)
	profile = persistMutation(profile, reservedProfile)

	local acquired, acquireStatus, acquiredProfile = PetCollectionData.addPetOnce(
		profile,
		"store-round-trip-bunny",
		"bunny",
		4,
		now,
		"hatch:store-round-trip",
		"hatch:store-transaction"
	)
	assert(acquired and acquireStatus == "UPDATED" and acquiredProfile ~= nil,
		"reserved pet acquisition failed: " .. acquireStatus)
	profile = persistMutation(profile, acquiredProfile)

	local interacted, interactionStatus, interactedProfile = PetCollectionData.interact(
		profile,
		"store-round-trip-bunny",
		"pet",
		now + PetCollectionData.BOND_INTERACTION_COOLDOWN_SECONDS
	)
	assert(interacted and interactionStatus == "UPDATED" and interactedProfile ~= nil,
		"pet bond interaction failed: " .. interactionStatus)
	profile = persistMutation(profile, interactedProfile)

	local experienced, experienceStatus, experiencedProfile = PetCollectionData.grantExperience(
		profile,
		"store-round-trip-bunny",
		35
	)
	assert(experienced and experienceStatus == "UPDATED" and experiencedProfile ~= nil,
		"pet XP mutation failed: " .. experienceStatus)
	profile = persistMutation(profile, experiencedProfile)

	local protected, protectionStatus, protectedProfile = PetCollectionData.setPetFlags(
		profile,
		"store-round-trip-bunny",
		true,
		true
	)
	assert(protected and protectionStatus == "UPDATED" and protectedProfile ~= nil,
		"pet lock/favorite mutation failed: " .. protectionStatus)
	profile = persistMutation(profile, protectedProfile)

	local equipped, equipStatus, equippedProfile = PetCollectionData.setEquipped(
		profile,
		{ "starter-bunny", "store-round-trip-bunny" }
	)
	assert(equipped and equipStatus == "UPDATED" and equippedProfile ~= nil,
		"pet equip mutation failed: " .. equipStatus)
	profile = persistMutation(profile, equippedProfile)

	local loadedOk, loaded = pcall(function()
		return store:GetAsync(key)
	end)
	assert(loadedOk and type(loaded) == "table", "collection profile could not be reloaded from DataStore")
	local loadedValid, loadedReason = PetCollectionData.validate(loaded, syntheticUserId)
	assert(loadedValid, "reloaded collection profile is invalid: " .. loadedReason)

	local hatchedPet = nil
	for _, pet in ipairs(loaded.owned) do
		if pet.petId == "store-round-trip-bunny" then
			hatchedPet = pet
			break
		end
	end
	assert(hatchedPet ~= nil, "hatched pet identity did not survive DataStore reload")
	assert(hatchedPet.speciesId == "bunny" and hatchedPet.rarityTier == 4,
		"hatched pet species/rarity did not survive reload")
	assert(hatchedPet.level == 1 and hatchedPet.xp == 35,
		"pet progression did not survive reload")
	assert(hatchedPet.bondXp == PetCollectionData.BOND_XP_PER_INTERACTION
		and hatchedPet.bondLevel == 1
		and hatchedPet.lastInteractionAt == now + PetCollectionData.BOND_INTERACTION_COOLDOWN_SECONDS,
		"pet bond state did not survive reload")
	assert(hatchedPet.isLocked == true and hatchedPet.isFavorite == true,
		"pet lock/favorite state did not survive reload")
	assert(#loaded.owned == 2, "starter and acquired pets should both remain in the collection")
	assert(#loaded.equipped == 2
		and loaded.equipped[1] == "starter-bunny"
		and loaded.equipped[2] == "store-round-trip-bunny",
		"equipped pet team did not survive reload")
	assert(#(loaded.acquisitionReceipts or {}) == 1
		and loaded.acquisitionReceipts[1].acquisitionId == "hatch:store-round-trip"
		and loaded.acquisitionReceipts[1].transactionId == "hatch:store-transaction",
		"durable acquisition receipt did not survive reload")
	print("[PetKingdoms Test] PASS: owned pets, equipped team, XP, bond, flags and hatch receipt survive DataStore reload")

	local secondToken = HttpService:GenerateGUID(false)
	local secondClaimStatus = "NOT_CLAIMED"
	local secondClaimOk, secondSession = updateStore(function(current)
		local claimed, status = PetCollectionSessionData.claim(
			current,
			loaded,
			secondToken,
			function()
				return PetCollectionData.createDefault(syntheticUserId)
			end
		)
		secondClaimStatus = status
		return claimed
	end)
	assert(secondClaimOk and type(secondSession) == "table" and secondClaimStatus == "CLAIMED",
		"second collection session claim failed: " .. secondClaimStatus)
	assert(secondSession.collectionSessionGeneration == loaded.collectionSessionGeneration + 1,
		"new collection session did not advance the writer generation")

	local staleWriterStatus = "NOT_CHECKED"
	local staleWriterOk, staleWriterResult = updateStore(function(current)
		if not PetCollectionSessionData.owns(
			current,
			loaded.collectionSessionGeneration,
			loaded.collectionSessionToken
		) then
			staleWriterStatus = "REJECTED"
			return nil
		end
		staleWriterStatus = "UNEXPECTEDLY_ACCEPTED"
		return loaded
	end)
	assert(staleWriterOk and staleWriterResult == nil and staleWriterStatus == "REJECTED",
		"previous collection session was able to overwrite the latest writer")
	local finalReadOk, finalProfile = pcall(function()
		return store:GetAsync(key)
	end)
	assert(finalReadOk and type(finalProfile) == "table"
		and PetCollectionSessionData.owns(
			finalProfile,
			secondSession.collectionSessionGeneration,
			secondToken
		),
		"stale writer rejection must leave the newest collection session intact")
	print("[PetKingdoms Test] PASS: stale collection writer cannot overwrite a newer session")
end

local scenarioOk, scenarioError = xpcall(runIntegrationScenario, debug.traceback)
local cleanupOk = true
local cleanupError = nil
if ownsSyntheticKey then
	cleanupOk, cleanupError = pcall(function()
		store:RemoveAsync(key)
	end)
end
if not cleanupOk then
	warn("[PetKingdoms Test] Failed to remove synthetic pet collection profile:", cleanupError)
end
assert(cleanupOk, "synthetic pet collection profile cleanup failed")
assert(scenarioOk, "PetCollectionStore integration scenario failed: " .. tostring(scenarioError))
print("[PetKingdoms Test] Pet collection DataStore integration completed.")
