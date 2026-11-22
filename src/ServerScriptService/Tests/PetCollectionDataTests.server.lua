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

expect("starter pet progression begins at level 1", profile.owned[1].level == 1)
expect("starter pet progression begins with zero XP", profile.owned[1].xp == 0)

local maxPetLevel = PetCollectionData.clone(profile)
maxPetLevel.owned[1].level = PetCollectionData.MAX_PET_LEVEL
local maxPetLevelValid = PetCollectionData.validate(maxPetLevel, 12345)
expect("pet level 50 is accepted", maxPetLevelValid)

local zeroPetLevel = PetCollectionData.clone(profile)
zeroPetLevel.owned[1].level = 0
local zeroPetLevelValid = PetCollectionData.validate(zeroPetLevel, 12345)
expect("pet level zero is rejected", not zeroPetLevelValid)

local overPetLevel = PetCollectionData.clone(profile)
overPetLevel.owned[1].level = PetCollectionData.MAX_PET_LEVEL + 1
local overPetLevelValid = PetCollectionData.validate(overPetLevel, 12345)
expect("pet level above 50 is rejected", not overPetLevelValid)

local fractionalPetLevel = PetCollectionData.clone(profile)
fractionalPetLevel.owned[1].level = 1.5
local fractionalPetLevelValid = PetCollectionData.validate(fractionalPetLevel, 12345)
expect("fractional pet level is rejected", not fractionalPetLevelValid)

local negativePetXp = PetCollectionData.clone(profile)
negativePetXp.owned[1].xp = -1
local negativePetXpValid = PetCollectionData.validate(negativePetXp, 12345)
expect("negative pet XP is rejected", not negativePetXpValid)

local fractionalPetXp = PetCollectionData.clone(profile)
fractionalPetXp.owned[1].xp = 12.5
local fractionalPetXpValid = PetCollectionData.validate(fractionalPetXp, 12345)
expect("fractional pet XP is rejected", not fractionalPetXpValid)

local infinitePetXp = PetCollectionData.clone(profile)
infinitePetXp.owned[1].xp = math.huge
local infinitePetXpValid = PetCollectionData.validate(infinitePetXp, 12345)
expect("infinite pet XP is rejected", not infinitePetXpValid)

local nanPetXp = PetCollectionData.clone(profile)
nanPetXp.owned[1].xp = 0 / 0
local nanPetXpValid = PetCollectionData.validate(nanPetXp, 12345)
expect("NaN pet XP is rejected", not nanPetXpValid)

local legacyProgression = PetCollectionData.clone(profile)
legacyProgression.owned[1].level = nil
legacyProgression.owned[1].xp = nil
local legacyProgressionValid = PetCollectionData.validate(legacyProgression, 12345)
expect("legacy pet without progression fields remains valid", legacyProgressionValid)
local normalizedProgression = PetCollectionData.clone(legacyProgression)
expect("legacy pet progression defaults safely", normalizedProgression.owned[1].level == 1 and normalizedProgression.owned[1].xp == 0)
local wrongOwner, ownerStatus = PetCollectionData.validate(profile, 54321)
expect("wrong owner rejected", not wrongOwner and ownerStatus == "OWNER_MISMATCH")

local xpGranted, xpStatus, xpProfile = PetCollectionData.grantExperience(profile, "starter-bunny", 25)
expect("server reward grants pet XP", xpGranted and xpStatus == "UPDATED" and xpProfile ~= nil)
assert(xpProfile ~= nil)
expect("pet XP reward increments XP", xpProfile.owned[1].xp == 25)
expect("pet XP reward preserves level until curve is approved", xpProfile.owned[1].level == 1)
expect("pet XP reward increments revision", xpProfile.revision == profile.revision + 1)
expect("pet XP reward does not alter Bond", xpProfile.owned[1].bondXp == profile.owned[1].bondXp)

local zeroReward, zeroRewardStatus = PetCollectionData.grantExperience(profile, "starter-bunny", 0)
expect("zero pet XP reward rejected", not zeroReward and zeroRewardStatus == "INVALID_XP_AMOUNT")

local fractionalReward, fractionalRewardStatus = PetCollectionData.grantExperience(profile, "starter-bunny", 2.5)
expect("fractional pet XP reward rejected", not fractionalReward and fractionalRewardStatus == "INVALID_XP_AMOUNT")

local infiniteReward, infiniteRewardStatus = PetCollectionData.grantExperience(profile, "starter-bunny", math.huge)
expect("infinite pet XP reward rejected", not infiniteReward and infiniteRewardStatus == "INVALID_XP_AMOUNT")

local nanReward, nanRewardStatus = PetCollectionData.grantExperience(profile, "starter-bunny", 0 / 0)
expect("NaN pet XP reward rejected", not nanReward and nanRewardStatus == "INVALID_XP_AMOUNT")

local unownedReward, unownedRewardStatus = PetCollectionData.grantExperience(profile, "not-owned", 10)
expect("XP reward for unowned pet rejected", not unownedReward and unownedRewardStatus == "PET_NOT_OWNED")

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

local infiniteRevision = PetCollectionData.clone(profile)
infiniteRevision.revision = math.huge
local infiniteRevisionValid = PetCollectionData.validate(infiniteRevision, 12345)
expect("infinite revision rejected", not infiniteRevisionValid)

local nanRevision = PetCollectionData.clone(profile)
nanRevision.revision = 0 / 0
local nanRevisionValid = PetCollectionData.validate(nanRevision, 12345)
expect("NaN revision rejected", not nanRevisionValid)

local infiniteAcquiredAt = PetCollectionData.clone(profile)
infiniteAcquiredAt.owned[1].acquiredAt = math.huge
local infiniteAcquiredAtValid = PetCollectionData.validate(infiniteAcquiredAt, 12345)
expect("infinite acquisition timestamp rejected", not infiniteAcquiredAtValid)

local fractionalAcquiredAt = PetCollectionData.clone(profile)
fractionalAcquiredAt.owned[1].acquiredAt = 12.5
local fractionalAcquiredAtValid = PetCollectionData.validate(fractionalAcquiredAt, 12345)
expect("fractional acquisition timestamp rejected", not fractionalAcquiredAtValid)

local infiniteInteractionAt = PetCollectionData.clone(profile)
infiniteInteractionAt.owned[1].lastInteractionAt = math.huge
local infiniteInteractionAtValid = PetCollectionData.validate(infiniteInteractionAt, 12345)
expect("infinite interaction timestamp rejected", not infiniteInteractionAtValid)

local nanInteractionAt = PetCollectionData.clone(profile)
nanInteractionAt.owned[1].lastInteractionAt = 0 / 0
local nanInteractionAtValid = PetCollectionData.validate(nanInteractionAt, 12345)
expect("NaN interaction timestamp rejected", not nanInteractionAtValid)

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

local levelled = PetCollectionData.clone(profile)
levelled.owned[1].bondXp = 50
levelled.owned[1].bondLevel = 2
local levelledValid = PetCollectionData.validate(levelled, 12345)
expect("Bond level and XP persist in valid collection", levelledValid)

local legacy = PetCollectionData.clone(profile)
legacy.owned[1].bondXp = nil
legacy.owned[1].bondLevel = nil
legacy.owned[1].lastInteractionAt = nil
local legacyValid = PetCollectionData.validate(legacy, 12345)
expect("legacy collection without Bond fields remains valid", legacyValid)
local normalizedLegacy = PetCollectionData.clone(legacy)
expect("legacy Bond fields normalize safely", normalizedLegacy.owned[1].bondXp == 0 and normalizedLegacy.owned[1].bondLevel == 1)

local capped = PetCollectionData.clone(profile)
capped.owned[1].bondXp = PetCollectionData.MAX_BOND_XP
capped.owned[1].bondLevel = PetCollectionData.MAX_BOND_LEVEL
local cappedValid = PetCollectionData.validate(capped, 12345)
expect("maximum Bond level remains valid", cappedValid)

local mismatchedBond = PetCollectionData.clone(profile)
mismatchedBond.owned[1].bondXp = 0
mismatchedBond.owned[1].bondLevel = 10
local mismatchedValid, mismatchReason = PetCollectionData.validate(mismatchedBond, 12345)
expect("inconsistent Bond XP and level rejected", not mismatchedValid and mismatchReason == "BOND_LEVEL_XP_MISMATCH")

local fractionalXp = PetCollectionData.clone(profile)
fractionalXp.owned[1].bondXp = 10.5
local fractionalXpValid = PetCollectionData.validate(fractionalXp, 12345)
expect("fractional Bond XP rejected", not fractionalXpValid)

local overCapXp = PetCollectionData.clone(profile)
overCapXp.owned[1].bondXp = PetCollectionData.MAX_BOND_XP + 10
overCapXp.owned[1].bondLevel = PetCollectionData.MAX_BOND_LEVEL
local overCapValid = PetCollectionData.validate(overCapXp, 12345)
expect("Bond XP above maximum rejected", not overCapValid)

local fractionalTimestamp = PetCollectionData.clone(profile)
fractionalTimestamp.owned[1].lastInteractionAt = 1000.5
local fractionalTimestampValid = PetCollectionData.validate(fractionalTimestamp, 12345)
expect("fractional interaction timestamp rejected", not fractionalTimestampValid)

local maxed = PetCollectionData.clone(profile)
maxed.owned[1].bondXp = PetCollectionData.MAX_BOND_XP
maxed.owned[1].bondLevel = PetCollectionData.MAX_BOND_LEVEL
maxed.owned[1].lastInteractionAt = 1000
local maxedInteraction, maxedStatus, maxedResult = PetCollectionData.interact(maxed, "starter-bunny", "pet", 1030)
expect("max-level pet can still interact without XP overflow", maxedInteraction and maxedStatus == "UPDATED" and maxedResult ~= nil)
assert(maxedResult ~= nil)
expect("max-level Bond XP remains capped", maxedResult.owned[1].bondXp == PetCollectionData.MAX_BOND_XP and maxedResult.owned[1].bondLevel == PetCollectionData.MAX_BOND_LEVEL)

local fractionalNow, fractionalNowStatus = PetCollectionData.interact(profile, "starter-bunny", "pet", 1000.5)
expect("fractional interaction timestamp rejected", not fractionalNow and fractionalNowStatus == "INVALID_TIMESTAMP")

local negativeNow, negativeNowStatus = PetCollectionData.interact(profile, "starter-bunny", "pet", -1)
expect("negative interaction timestamp rejected", not negativeNow and negativeNowStatus == "INVALID_TIMESTAMP")

local infiniteNow, infiniteNowStatus = PetCollectionData.interact(profile, "starter-bunny", "pet", math.huge)
expect("infinite interaction timestamp rejected", not infiniteNow and infiniteNowStatus == "INVALID_TIMESTAMP")

local nanNow, nanNowStatus = PetCollectionData.interact(profile, "starter-bunny", "pet", 0 / 0)
expect("NaN interaction timestamp rejected", not nanNow and nanNowStatus == "INVALID_TIMESTAMP")

local infiniteBondXp = PetCollectionData.clone(profile)
infiniteBondXp.owned[1].bondXp = math.huge
local infiniteBondXpValid = PetCollectionData.validate(infiniteBondXp, 12345)
expect("infinite Bond XP rejected", not infiniteBondXpValid)

local nanBondXp = PetCollectionData.clone(profile)
nanBondXp.owned[1].bondXp = 0 / 0
local nanBondXpValid = PetCollectionData.validate(nanBondXp, 12345)
expect("NaN Bond XP rejected", not nanBondXpValid)

local infiniteBondLevel = PetCollectionData.clone(profile)
infiniteBondLevel.owned[1].bondLevel = math.huge
local infiniteBondLevelValid = PetCollectionData.validate(infiniteBondLevel, 12345)
expect("infinite Bond level rejected", not infiniteBondLevelValid)

print("[PetKingdoms Test] PetCollectionData smoke tests completed.")
