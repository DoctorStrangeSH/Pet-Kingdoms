--!strict
-- Studio-only pure data tests for pet collection ownership and equip validation.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local PetCollectionData = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetCollectionData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local profile = PetCollectionData.createDefault(12345)
expect("default collection is created", profile ~= nil)
assert(profile ~= nil)
expect("starter Bunny is owned", #profile.owned == 1 and profile.owned[1].speciesId == "bunny")
expect("starter Bunny is equipped", #profile.equipped == 1 and profile.equipped[1] == "starter-bunny")

local valid, validStatus = PetCollectionData.validate(profile, 12345)
expect("default collection validates", valid and validStatus == "VALID")
local wrongOwner, ownerStatus = PetCollectionData.validate(profile, 54321)
expect("wrong owner rejected", not wrongOwner and ownerStatus == "OWNER_MISMATCH")

local equipped, equipStatus, updated = PetCollectionData.setEquipped(profile, { "starter-bunny" })
expect("owned pet can be equipped", equipped and equipStatus == "UPDATED" and updated ~= nil)
assert(updated ~= nil)
expect("equip mutation increments revision", updated.revision == profile.revision + 1)

local missing, missingStatus = PetCollectionData.setEquipped(profile, { "not-owned" })
expect("unowned pet rejected", not missing and missingStatus == "PET_NOT_OWNED")

local duplicate, duplicateStatus = PetCollectionData.setEquipped(profile, { "starter-bunny", "starter-bunny" })
expect("duplicate equip rejected", not duplicate and duplicateStatus == "DUPLICATE_EQUIPPED_PET")

local tooMany, tooManyStatus = PetCollectionData.setEquipped(profile, { "a", "b", "c", "d" })
expect("more than three rejected", not tooMany and tooManyStatus == "INVALID_EQUIPPED_COUNT")

local sparse, sparseStatus = PetCollectionData.setEquipped(profile, { [1] = "starter-bunny", [3] = "starter-bunny" })
expect("sparse equip list rejected", not sparse and sparseStatus == "INVALID_EQUIPPED_COUNT")

local corrupt = PetCollectionData.clone(profile)
corrupt.owned[1].speciesId = "admin"
local corruptValid = PetCollectionData.validate(corrupt, 12345)
expect("unknown species in saved data rejected", not corruptValid)

local badRevision = PetCollectionData.clone(profile)
badRevision.revision = -1
local revisionValid = PetCollectionData.validate(badRevision, 12345)
expect("negative revision rejected", not revisionValid)

local interacted, interactionStatus, bonded = PetCollectionData.interact(profile, "starter-bunny", "pet", 1000)
expect("owned pet can receive affection", interacted and interactionStatus == "UPDATED" and bonded ~= nil)
assert(bonded ~= nil)
expect("interaction awards Bond XP", bonded.owned[1].bondXp == 10 and bonded.owned[1].bondLevel == 1)
expect("interaction increments collection revision", bonded.revision == profile.revision + 1)

local cooldown, cooldownStatus = PetCollectionData.interact(bonded, "starter-bunny", "play", 1029)
expect("rapid repeated interaction is rejected", not cooldown and cooldownStatus == "INTERACTION_COOLDOWN")

local played, playStatus, playedProfile = PetCollectionData.interact(bonded, "starter-bunny", "play", 1030)
expect("pet can interact again after cooldown", played and playStatus == "UPDATED" and playedProfile ~= nil)
assert(playedProfile ~= nil)
expect("second interaction advances Bond XP", playedProfile.owned[1].bondXp == 20)

local invalidInteraction, invalidInteractionStatus = PetCollectionData.interact(profile, "starter-bunny", "feed", 1000)
expect("unsupported interaction type rejected", not invalidInteraction and invalidInteractionStatus == "INVALID_INTERACTION")

local notOwnedInteraction, notOwnedInteractionStatus = PetCollectionData.interact(profile, "unknown-pet", "pet", 1000)
expect("interaction with unowned pet rejected", not notOwnedInteraction and notOwnedInteractionStatus == "PET_NOT_OWNED")

local persistedValid = PetCollectionData.validate(playedProfile, 12345)
expect("interaction profile remains valid", persistedValid)

print("[PetKingdoms Test] PetCollectionData smoke tests completed.")
