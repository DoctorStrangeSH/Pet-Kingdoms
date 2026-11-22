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

local nilInteract, nilInteractStatus = PetCollectionData.interact(nil, "starter-bunny", "pet", 1000)
expect("interaction rejects nil profile safely", not nilInteract and nilInteractStatus == "INVALID_PROFILE:PROFILE_NOT_TABLE")

local malformedInteract, malformedInteractStatus = PetCollectionData.interact({ revision = 0 }, "starter-bunny", "pet", 1000)
expect("interaction rejects malformed profile safely", not malformedInteract and string.sub(malformedInteractStatus, 1, 15) == "INVALID_PROFILE")

local nilEquip, nilEquipStatus = PetCollectionData.setEquipped(nil, { "starter-bunny" })
expect("equip rejects nil profile safely", not nilEquip and nilEquipStatus == "INVALID_PROFILE:PROFILE_NOT_TABLE")

local malformedEquip, malformedEquipStatus = PetCollectionData.setEquipped({ revision = 0 }, { "starter-bunny" })
expect("equip rejects malformed profile safely", not malformedEquip and string.sub(malformedEquipStatus, 1, 15) == "INVALID_PROFILE")

local nilReward, nilRewardStatus = PetCollectionData.grantExperience(nil, "starter-bunny", 1)
expect("XP reward rejects nil profile safely", not nilReward and nilRewardStatus == "INVALID_PROFILE:PROFILE_NOT_TABLE")

local unsafePetXp = PetCollectionData.clone(profile)
unsafePetXp.owned[1].xp = PetCollectionData.MAX_SAFE_INTEGER + 1
local unsafePetXpValid = PetCollectionData.validate(unsafePetXp, 12345)
expect("unsafe integer pet XP is rejected", not unsafePetXpValid)

local maxSafePetXp = PetCollectionData.clone(profile)
maxSafePetXp.owned[1].xp = PetCollectionData.MAX_SAFE_INTEGER
local maxSafePetXpValid = PetCollectionData.validate(maxSafePetXp, 12345)
expect("maximum safe integer pet XP is accepted", maxSafePetXpValid)

local overflowingPetXp = PetCollectionData.clone(profile)
overflowingPetXp.owned[1].xp = PetCollectionData.MAX_SAFE_INTEGER - 10
local overflowReward, overflowRewardStatus = PetCollectionData.grantExperience(overflowingPetXp, "starter-bunny", 20)
expect("pet XP reward cannot exceed safe integer precision", not overflowReward and overflowRewardStatus == "XP_OVERFLOW")

local unsafeReward, unsafeRewardStatus = PetCollectionData.grantExperience(profile, "starter-bunny", PetCollectionData.MAX_SAFE_INTEGER + 1)
expect("unsafe integer XP reward is rejected", not unsafeReward and unsafeRewardStatus == "INVALID_XP_AMOUNT")

local maxRevision = PetCollectionData.clone(profile)
maxRevision.revision = PetCollectionData.MAX_SAFE_INTEGER
local maxRevisionValid = PetCollectionData.validate(maxRevision, 12345)
expect("maximum safe revision is accepted", maxRevisionValid)
local revisionInteract, revisionInteractStatus = PetCollectionData.interact(maxRevision, "starter-bunny", "pet", 1000)
expect("interaction cannot overflow collection revision", not revisionInteract and revisionInteractStatus == "REVISION_OVERFLOW")
local revisionEquip, revisionEquipStatus = PetCollectionData.setEquipped(maxRevision, { "starter-bunny" })
expect("equip cannot overflow collection revision", not revisionEquip and revisionEquipStatus == "REVISION_OVERFLOW")
local revisionReward, revisionRewardStatus = PetCollectionData.grantExperience(maxRevision, "starter-bunny", 1)
expect("XP reward cannot overflow collection revision", not revisionReward and revisionRewardStatus == "REVISION_OVERFLOW")

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


-- Synthetic thresholds verify atomic XP + level persistence only; not production balance.
local progressionThresholds = {}
for level = 1, PetCollectionData.MAX_PET_LEVEL do
	progressionThresholds[level] = (level - 1) * 100
end

local progressionReward, progressionStatus, progressionProfile, progressionSummary =
	PetCollectionData.grantExperienceWithProgress(profile, "starter-bunny", 250, progressionThresholds)
expect("progression reward updates XP and level", progressionReward and progressionStatus == "UPDATED" and progressionProfile ~= nil and progressionSummary ~= nil)
assert(progressionProfile ~= nil and progressionSummary ~= nil)
expect("progression reward persists total XP", progressionProfile.owned[1].xp == 250)
expect("progression reward persists derived level", progressionProfile.owned[1].level == 3)
expect("progression summary reports multiple level gains", progressionSummary.previousLevel == 1 and progressionSummary.level == 3 and progressionSummary.levelsGained == 2)
expect("progression reward increments revision once", progressionProfile.revision == profile.revision + 1)
expect("progression reward leaves Bond unchanged", progressionProfile.owned[1].bondXp == profile.owned[1].bondXp)

local maxProgressionReward, _, maxProgressionProfile, maxProgressionSummary =
	PetCollectionData.grantExperienceWithProgress(profile, "starter-bunny", 4900, progressionThresholds)
expect("large reward caps level at 50", maxProgressionProfile ~= nil and maxProgressionProfile.owned[1].level == 50)
expect("level 50 summary has no next level", maxProgressionSummary ~= nil and maxProgressionSummary.isMaxLevel and maxProgressionSummary.nextLevelXp == nil)

local badThresholdReward, badThresholdStatus = PetCollectionData.grantExperienceWithProgress(profile, "starter-bunny", 10, {})
expect("progression reward rejects invalid thresholds", not badThresholdReward and string.find(badThresholdStatus, "INVALID_THRESHOLDS:", 1, true) == 1)

local progressionUnowned, progressionUnownedStatus =
	PetCollectionData.grantExperienceWithProgress(profile, "missing-pet", 10, progressionThresholds)
expect("progression reward rejects unowned pet", not progressionUnowned and progressionUnownedStatus == "PET_NOT_OWNED")

local progressionOverflow = PetCollectionData.clone(profile)
progressionOverflow.owned[1].xp = PetCollectionData.MAX_SAFE_INTEGER - 1
local progressionOverflowReward, progressionOverflowStatus =
	PetCollectionData.grantExperienceWithProgress(progressionOverflow, "starter-bunny", 10, progressionThresholds)
expect("progression reward rejects XP overflow", not progressionOverflowReward and progressionOverflowStatus == "XP_OVERFLOW")


-- Idempotency tests use a fixed timestamp and stable server-generated reward IDs.
local rewardNow = 1_800_000_000
local once, onceStatus, onceProfile, onceSummary =
	PetCollectionData.grantExperienceWithProgressOnce(
		profile, "starter-bunny", 250, progressionThresholds, "quest:chapter_01:reward_001", rewardNow
	)
expect("first reward ID is applied", once and onceStatus == "UPDATED" and onceProfile ~= nil and onceSummary ~= nil)
assert(onceProfile ~= nil)
expect("first reward receipt is persisted", #onceProfile.rewardReceipts == 1 and onceProfile.rewardReceipts[1].rewardId == "quest:chapter_01:reward_001")

local duplicate, duplicateStatus, duplicateProfile, duplicateReceipt =
	PetCollectionData.grantExperienceWithProgressOnce(
		onceProfile, "starter-bunny", 250, progressionThresholds, "quest:chapter_01:reward_001", rewardNow + 1
	)
expect("same reward ID and payload is not applied twice", not duplicate and duplicateStatus == "ALREADY_PROCESSED" and duplicateProfile == nil)
expect("duplicate reward returns its receipt", duplicateReceipt ~= nil and duplicateReceipt.rewardId == "quest:chapter_01:reward_001")
expect("duplicate reward does not increment XP or revision", onceProfile.owned[1].xp == 250 and onceProfile.revision == profile.revision + 1)

local conflict, conflictStatus =
	PetCollectionData.grantExperienceWithProgressOnce(
		onceProfile, "starter-bunny", 300, progressionThresholds, "quest:chapter_01:reward_001", rewardNow + 1
	)
expect("reused reward ID with different amount is rejected", not conflict and conflictStatus == "REWARD_ID_CONFLICT")

local invalidRewardId, invalidRewardIdStatus =
	PetCollectionData.grantExperienceWithProgressOnce(
		profile, "starter-bunny", 10, progressionThresholds, "invalid reward id", rewardNow
	)
expect("malformed reward ID is rejected", not invalidRewardId and invalidRewardIdStatus == "INVALID_REWARD_ID")

local expiredReceiptProfile = PetCollectionData.clone(onceProfile)
local afterRetention = rewardNow + PetCollectionData.REWARD_RECEIPT_RETENTION_SECONDS + 1
local reusedAfterExpiry, reusedAfterExpiryStatus, reusedAfterExpiryProfile =
	PetCollectionData.grantExperienceWithProgressOnce(
		expiredReceiptProfile, "starter-bunny", 250, progressionThresholds, "quest:chapter_01:reward_001", afterRetention
	)
expect("expired reward receipt is pruned according to retention policy", reusedAfterExpiry and reusedAfterExpiryStatus == "UPDATED" and reusedAfterExpiryProfile ~= nil)
expect("expired receipt is replaced by a fresh receipt", reusedAfterExpiryProfile ~= nil and #reusedAfterExpiryProfile.rewardReceipts == 1)

local ledgerFullProfile = PetCollectionData.clone(profile)
ledgerFullProfile.rewardReceipts = {}
for index = 1, PetCollectionData.MAX_REWARD_RECEIPTS do
	ledgerFullProfile.rewardReceipts[index] = {
		rewardId = "daily:reward_" .. tostring(index),
		petId = "starter-bunny",
		amount = 1,
		processedAt = rewardNow,
	}
end
local ledgerFull, ledgerFullStatus =
	PetCollectionData.grantExperienceWithProgressOnce(
		ledgerFullProfile, "starter-bunny", 10, progressionThresholds, "daily:new_reward", rewardNow
	)
expect("full unexpired reward ledger rejects new rewards safely", not ledgerFull and ledgerFullStatus == "REWARD_LEDGER_FULL")

local malformedLedgerProfile = PetCollectionData.clone(profile)
malformedLedgerProfile.rewardReceipts = {
	{ rewardId = "duplicate:id", petId = "starter-bunny", amount = 1, processedAt = rewardNow },
	{ rewardId = "duplicate:id", petId = "starter-bunny", amount = 1, processedAt = rewardNow },
}
expect("duplicate reward receipts invalidate profile", not PetCollectionData.validate(malformedLedgerProfile, 12345))

local invalidReceiptTimeProfile = PetCollectionData.clone(profile)
invalidReceiptTimeProfile.rewardReceipts = {
	{ rewardId = "bad:time", petId = "starter-bunny", amount = 1, processedAt = math.huge },
}
expect("non-finite receipt timestamp invalidates profile", not PetCollectionData.validate(invalidReceiptTimeProfile, 12345))


-- Pet acquisition contract tests: the current catalog intentionally contains only Bunny.
local acquired, acquiredStatus, acquiredProfile =
	PetCollectionData.addPet(profile, "pet_test_001", "bunny", 2, 1_800_000_000)
expect("valid pet acquisition adds an owned pet", acquired and acquiredStatus == "UPDATED" and acquiredProfile ~= nil)
assert(acquiredProfile ~= nil)
expect("new pet starts at level one with zero XP", acquiredProfile.owned[2].level == 1 and acquiredProfile.owned[2].xp == 0)
expect("new pet stores neutral rarity tier", acquiredProfile.owned[2].rarityTier == 2)
expect("new pet acquisition increments revision once", acquiredProfile.revision == profile.revision + 1)
expect("new pet is not auto-equipped", #acquiredProfile.equipped == #profile.equipped)

local duplicatePet, duplicatePetStatus =
	PetCollectionData.addPet(acquiredProfile, "pet_test_001", "bunny", 2, 1_800_000_001)
expect("duplicate pet ID is rejected", not duplicatePet and duplicatePetStatus == "DUPLICATE_PET_ID")

local invalidSpecies, invalidSpeciesStatus =
	PetCollectionData.addPet(profile, "pet_test_002", "unknown_species", 2, 1_800_000_000)
expect("species outside the approved catalog is rejected", not invalidSpecies and invalidSpeciesStatus == "INVALID_SPECIES")

local invalidRarity, invalidRarityStatus =
	PetCollectionData.addPet(profile, "pet_test_003", "bunny", 7, 1_800_000_000)
expect("rarity tier outside 1-6 is rejected", not invalidRarity and invalidRarityStatus == "INVALID_RARITY_TIER")

local fullCollection = PetCollectionData.clone(profile)
for index = 2, PetCollectionData.MAX_OWNED_PETS do
	table.insert(fullCollection.owned, {
		petId = "pet_fill_" .. tostring(index),
		speciesId = "bunny",
		rarityTier = 1,
		acquiredAt = 1,
		level = 1,
		xp = 0,
		bondXp = 0,
		bondLevel = 1,
		lastInteractionAt = 0,
	})
end
local fullReward, fullRewardStatus =
	PetCollectionData.addPet(fullCollection, "pet_over_capacity", "bunny", 1, 1_800_000_000)
expect("collection capacity is enforced", not fullReward and fullRewardStatus == "COLLECTION_FULL")

local invalidAcquiredAt, invalidAcquiredAtStatus =
	PetCollectionData.addPet(profile, "pet_test_004", "bunny", 1, math.huge)
expect("invalid acquisition timestamp is rejected", not invalidAcquiredAt and invalidAcquiredAtStatus == "INVALID_TIMESTAMP")


-- Idempotent acquisition: repeated calls with the same stable ID cannot add another pet.
local acquiredOnce, acquiredOnceStatus, acquiredOnceProfile =
	PetCollectionData.addPetOnce(profile, "pet_acq_001", "bunny", 2, 1_800_000_000, "egg:opening_001")
expect("first acquisition ID adds a pet", acquiredOnce and acquiredOnceStatus == "UPDATED" and acquiredOnceProfile ~= nil)
assert(acquiredOnceProfile ~= nil)
expect("first acquisition stores its receipt", #acquiredOnceProfile.acquisitionReceipts == 1)

local duplicateReceiptPetIdProfile = PetCollectionData.clone(acquiredOnceProfile)
local duplicateReceipt = table.clone(duplicateReceiptPetIdProfile.acquisitionReceipts[1])
duplicateReceipt.acquisitionId = "egg:opening_duplicate_pet"
table.insert(duplicateReceiptPetIdProfile.acquisitionReceipts, duplicateReceipt)
local duplicateReceiptPetIdValid, duplicateReceiptPetIdReason =
	PetCollectionData.validate(duplicateReceiptPetIdProfile, profile.ownerUserId)
expect("two acquisition receipts cannot claim the same pet ID", not duplicateReceiptPetIdValid and duplicateReceiptPetIdReason == "INVALID_ACQUISITION_RECEIPT")

local mismatchedReceiptPetProfile = PetCollectionData.clone(acquiredOnceProfile)
mismatchedReceiptPetProfile.owned[2].rarityTier = 3
local mismatchedReceiptPetValid, mismatchedReceiptPetReason =
	PetCollectionData.validate(mismatchedReceiptPetProfile, profile.ownerUserId)
expect("owned pet metadata must match its acquisition receipt", not mismatchedReceiptPetValid and mismatchedReceiptPetReason == "ACQUISITION_RECEIPT_PET_MISMATCH")

local acquiredDuplicate, acquiredDuplicateStatus, duplicateAcquisitionProfile =
	PetCollectionData.addPetOnce(acquiredOnceProfile, "pet_acq_new_retry", "bunny", 2, 1_800_000_001, "egg:opening_001")
expect("repeated acquisition ID does not add a second pet", not acquiredDuplicate and acquiredDuplicateStatus == "ALREADY_ACQUIRED")
expect("repeated acquisition preserves the original pet", duplicateAcquisitionProfile ~= nil and #duplicateAcquisitionProfile.owned == #acquiredOnceProfile.owned)
expect("repeated acquisition does not increment revision", duplicateAcquisitionProfile ~= nil and duplicateAcquisitionProfile.revision == acquiredOnceProfile.revision)

local acquisitionConflict, acquisitionConflictStatus =
	PetCollectionData.addPetOnce(acquiredOnceProfile, "pet_acq_conflict", "bunny", 3, 1_800_000_001, "egg:opening_001")
expect("acquisition ID cannot be reused with another rarity", not acquisitionConflict and acquisitionConflictStatus == "ACQUISITION_ID_CONFLICT")

local invalidAcquisitionId, invalidAcquisitionIdStatus =
	PetCollectionData.addPetOnce(profile, "pet_acq_bad", "bunny", 1, 1_800_000_000, "invalid acquisition id")
expect("malformed acquisition ID is rejected", not invalidAcquisitionId and invalidAcquisitionIdStatus == "INVALID_ACQUISITION_ID")

local fullAcquisitionLedger = PetCollectionData.clone(profile)
fullAcquisitionLedger.acquisitionReceipts = {}
for index = 1, PetCollectionData.MAX_ACQUISITION_RECEIPTS do
	fullAcquisitionLedger.acquisitionReceipts[index] = {
		acquisitionId = "egg:opening_" .. tostring(index),
		petId = "pet_existing_" .. tostring(index),
		speciesId = "bunny",
		rarityTier = 1,
		processedAt = 1_800_000_000,
	}
end
local ledgerFullAcquisition, ledgerFullAcquisitionStatus =
	PetCollectionData.addPetOnce(fullAcquisitionLedger, "pet_acq_full", "bunny", 1, 1_800_000_000, "egg:opening_new")
expect("full acquisition ledger rejects new acquisitions safely", not ledgerFullAcquisition and ledgerFullAcquisitionStatus == "ACQUISITION_LEDGER_FULL")

local expiredAcquisitionProfile = PetCollectionData.clone(acquiredOnceProfile)
local acquisitionAfterRetention = 1_800_000_000 + PetCollectionData.ACQUISITION_RECEIPT_RETENTION_SECONDS + 1
local reacquired, reacquiredStatus, reacquiredProfile =
	PetCollectionData.addPetOnce(expiredAcquisitionProfile, "pet_acq_after_expiry", "bunny", 2, acquisitionAfterRetention, "egg:opening_001")
expect("unacknowledged acquisition receipt never expires", not reacquired and reacquiredStatus == "ALREADY_ACQUIRED" and reacquiredProfile ~= nil)

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

local capacityProfile = PetCollectionData.clone(profile)
for index = 2, PetCollectionData.MAX_OWNED_PETS - 1 do
	table.insert(capacityProfile.owned, {
		petId = "capacity-pet-" .. tostring(index),
		speciesId = "bunny",
		acquiredAt = 1,
		rarityTier = 1,
		level = 1,
		xp = 0,
		bondXp = 0,
		bondLevel = 1,
		lastInteractionAt = 0,
	})
end
local capacityValid = PetCollectionData.validate(capacityProfile, 12345)
expect("collection with one free slot validates", capacityValid)

local reserved, reserveStatus, reservedProfile = PetCollectionData.reservePetSlotOnce(
	capacityProfile, "hatch:capacity-001", "bunny", 1, 100
)
expect("free collection slot can be reserved", reserved and reserveStatus == "RESERVED" and reservedProfile ~= nil)
assert(reservedProfile ~= nil)
expect("reservation does not add an owned pet", #reservedProfile.owned == PetCollectionData.MAX_OWNED_PETS - 1)
expect("reservation consumes the final available capacity", #reservedProfile.reservedAcquisitions == 1)

local secondReserved, secondReserveStatus = PetCollectionData.reservePetSlotOnce(
	reservedProfile, "hatch:capacity-002", "bunny", 1, 101
)
expect("another reservation is rejected when capacity is reserved", not secondReserved and secondReserveStatus == "COLLECTION_FULL")

local ordinaryAdded, ordinaryAddStatus = PetCollectionData.addPet(
	reservedProfile, "ordinary-reward-pet", "bunny", 1, 102
)
expect("ordinary rewards cannot consume reserved capacity", not ordinaryAdded and ordinaryAddStatus == "COLLECTION_FULL")

local reservedAgain, reservedAgainStatus = PetCollectionData.reservePetSlotOnce(
	reservedProfile, "hatch:capacity-001", "bunny", 1, 103
)
expect("same reservation request is idempotent", not reservedAgain and reservedAgainStatus == "ALREADY_RESERVED")

local granted, grantStatus, grantedProfile = PetCollectionData.addPetOnce(
	reservedProfile, "reserved-pet", "bunny", 1, 104, "hatch:capacity-001"
)
expect("reserved slot can be consumed by matching acquisition", granted and grantStatus == "UPDATED" and grantedProfile ~= nil)
assert(grantedProfile ~= nil)
expect("grant replaces reservation with owned pet", #grantedProfile.owned == PetCollectionData.MAX_OWNED_PETS and #grantedProfile.reservedAcquisitions == 0)

local grantedAgain, grantedAgainStatus = PetCollectionData.addPetOnce(
	grantedProfile, "another-pet-id", "bunny", 1, 105, "hatch:capacity-001"
)
expect("consumed reservation acquisition is idempotent", not grantedAgain and grantedAgainStatus == "ALREADY_ACQUIRED")

local conflictReservation, conflictReservationStatus = PetCollectionData.reservePetSlotOnce(
	reservedProfile, "hatch:capacity-001", "bunny", 2, 106
)
expect("reservation cannot be reused for different rarity", not conflictReservation and conflictReservationStatus == "RESERVATION_CONFLICT")

local inventoryProfile = PetCollectionData.clone(profile)
local petAdded, petAddedStatus, withSecondPet = PetCollectionData.addPet(
	inventoryProfile, "inventory-test-pet", "bunny", 2, 200
)
expect("inventory test pet can be added", petAdded and petAddedStatus == "UPDATED" and withSecondPet ~= nil)
assert(withSecondPet ~= nil)

local protected, protectedStatus, protectedProfile = PetCollectionData.setPetFlags(
	withSecondPet, "inventory-test-pet", true, true
)
expect("pet can be locked and favorited", protected and protectedStatus == "UPDATED" and protectedProfile ~= nil)
assert(protectedProfile ~= nil)
expect("lock and favorite flags persist", protectedProfile.owned[2].isLocked and protectedProfile.owned[2].isFavorite)

local lockedRemoval, lockedRemovalStatus = PetCollectionData.removePet(protectedProfile, "inventory-test-pet")
expect("locked pet cannot be removed", not lockedRemoval and lockedRemovalStatus == "PET_LOCKED")

local starterRemoval, starterRemovalStatus = PetCollectionData.removePet(withSecondPet, "starter-bunny")
expect("starter pet cannot be permanently removed", not starterRemoval and starterRemovalStatus == "STARTER_PET_PROTECTED")

local unlocked, unlockedStatus, unlockedProfile = PetCollectionData.setPetFlags(
	protectedProfile, "inventory-test-pet", false, true
)
expect("pet can be unlocked while remaining favorite", unlocked and unlockedStatus == "UPDATED" and unlockedProfile ~= nil)
assert(unlockedProfile ~= nil)

local equippedCandidate, equippedCandidateStatus, equippedProfile = PetCollectionData.setEquipped(
	unlockedProfile, { "starter-bunny", "inventory-test-pet" }
)
expect("pet can be equipped for deletion protection test", equippedCandidate and equippedCandidateStatus == "UPDATED" and equippedProfile ~= nil)
assert(equippedProfile ~= nil)

local equippedRemoval, equippedRemovalStatus = PetCollectionData.removePet(equippedProfile, "inventory-test-pet")
expect("equipped pet cannot be removed", not equippedRemoval and equippedRemovalStatus == "PET_EQUIPPED")

local unequipped, unequippedStatus, unequippedProfile = PetCollectionData.setEquipped(
	equippedProfile, { "starter-bunny" }
)
expect("pet can be unequipped before deletion", unequipped and unequippedStatus == "UPDATED" and unequippedProfile ~= nil)
assert(unequippedProfile ~= nil)

local removed, removedStatus, removedProfile = PetCollectionData.removePet(unequippedProfile, "inventory-test-pet")
expect("unlocked unequipped pet can be removed", removed and removedStatus == "REMOVED" and removedProfile ~= nil)
assert(removedProfile ~= nil)
expect("deletion frees one collection slot", #removedProfile.owned == 1)
expect("deletion does not disturb equipped starter", #removedProfile.equipped == 1 and removedProfile.equipped[1] == "starter-bunny")

local lastRemoval, lastRemovalStatus = PetCollectionData.removePet(profile, "starter-bunny")
expect("last owned pet cannot be removed", not lastRemoval and lastRemovalStatus == "STARTER_PET_PROTECTED")

local invalidFlags, invalidFlagsStatus = PetCollectionData.setPetFlags(
	withSecondPet, "inventory-test-pet", 1 :: any, false
)
expect("non-boolean protection flags are rejected", not invalidFlags and invalidFlagsStatus == "INVALID_PET_FLAGS")

local identityProfile = PetCollectionData.createDefault(54321)
assert(identityProfile ~= nil)
local identityAdded, identityAddStatus, identityOwned = PetCollectionData.addPetOnce(
	identityProfile, "retired-pet-id", "bunny", 2, 300, "identity-acquisition-001", "hatch:identity-001"
)
expect("identity test pet is acquired with a receipt", identityAdded and identityAddStatus == "UPDATED" and identityOwned ~= nil)
assert(identityOwned ~= nil)
local identityRemoved, identityRemoveStatus, identityAfterRemoval = PetCollectionData.removePet(
	identityOwned, "retired-pet-id"
)
expect("identity test pet can be removed", identityRemoved and identityRemoveStatus == "REMOVED" and identityAfterRemoval ~= nil)
assert(identityAfterRemoval ~= nil)
local identityReused, identityReuseStatus = PetCollectionData.addPet(
	identityAfterRemoval, "retired-pet-id", "bunny", 2, 301
)
expect("removed pet identity cannot be reused", not identityReused and identityReuseStatus == "PET_ID_ALREADY_USED")

local identityAcknowledged, identityAcknowledgeStatus, identityAcknowledgedProfile =
	PetCollectionData.acknowledgeAcquisition(identityAfterRemoval, "identity-acquisition-001", "hatch:identity-001", 400)
expect("completed hatch receipt can be acknowledged", identityAcknowledged and identityAcknowledgeStatus == "ACKNOWLEDGED" and identityAcknowledgedProfile ~= nil)
assert(identityAcknowledgedProfile ~= nil)
local expiredIdentityReuse, expiredIdentityStatus = PetCollectionData.addPet(
	identityAcknowledgedProfile,
	"retired-pet-id",
	"bunny",
	2,
	300 + PetCollectionData.ACQUISITION_RECEIPT_RETENTION_SECONDS + 1
)
expect("completed pet identity can be reused after journal retention", expiredIdentityReuse and expiredIdentityStatus == "UPDATED")

local receiptCapacityProfile = PetCollectionData.clone(profile)
receiptCapacityProfile.acquisitionReceipts = {}
for index = 1, PetCollectionData.MAX_ACQUISITION_RECEIPTS - 1 do
	table.insert(receiptCapacityProfile.acquisitionReceipts, {
		acquisitionId = "ledger-seed-" .. tostring(index),
		petId = "ledger-pet-" .. tostring(index),
		speciesId = "bunny",
		rarityTier = 1,
		processedAt = 1000,
	})
end
local receiptCapacityValid = PetCollectionData.validate(receiptCapacityProfile, profile.ownerUserId)
expect("nearly full acquisition receipt ledger validates", receiptCapacityValid)

local ledgerReserved, ledgerReserveStatus, ledgerReservedProfile = PetCollectionData.reservePetSlotOnce(
	receiptCapacityProfile, "hatch-ledger-001", "bunny", 1, 1000
)
expect("last receipt slot can be reserved for a hatch", ledgerReserved and ledgerReserveStatus == "RESERVED" and ledgerReservedProfile ~= nil)
assert(ledgerReservedProfile ~= nil)

local secondLedgerReserved, secondLedgerStatus = PetCollectionData.reservePetSlotOnce(
	ledgerReservedProfile, "hatch-ledger-002", "bunny", 1, 1000
)
expect("pending hatch reserves receipt ledger capacity", not secondLedgerReserved and secondLedgerStatus == "ACQUISITION_LEDGER_FULL")

local ledgerGrant, ledgerGrantStatus, ledgerGrantedProfile = PetCollectionData.addPetOnce(
	ledgerReservedProfile, "ledger-new-pet", "bunny", 1, 1001, "hatch-ledger-001"
)
expect("reserved receipt slot can be consumed by its hatch", ledgerGrant and ledgerGrantStatus == "UPDATED" and ledgerGrantedProfile ~= nil)
assert(ledgerGrantedProfile ~= nil)
expect("hatch grant fills but does not exceed receipt ledger", #ledgerGrantedProfile.acquisitionReceipts == PetCollectionData.MAX_ACQUISITION_RECEIPTS)

local expiredLedgerProfile = PetCollectionData.clone(receiptCapacityProfile)
expiredLedgerProfile.acquisitionReceipts = {}
for index = 1, PetCollectionData.MAX_ACQUISITION_RECEIPTS do
	table.insert(expiredLedgerProfile.acquisitionReceipts, {
		acquisitionId = "expired-ledger-" .. tostring(index),
		petId = "expired-ledger-pet-" .. tostring(index),
		speciesId = "bunny",
		rarityTier = 1,
		processedAt = 1,
		transactionId = "hatch:expired-" .. tostring(index),
		completedAt = 1,
	})
end
local expiredLedgerReserved, expiredLedgerStatus = PetCollectionData.reservePetSlotOnce(
	expiredLedgerProfile,
	"hatch-after-expiry",
	"bunny",
	1,
	1 + PetCollectionData.ACQUISITION_RECEIPT_RETENTION_SECONDS + 1
)
expect("acknowledged receipts are pruned after retention", expiredLedgerReserved and expiredLedgerStatus == "RESERVED")

local pendingHatchProfile = PetCollectionData.createDefault(98765)
assert(pendingHatchProfile ~= nil)
local pendingHatchAdded, pendingHatchStatus, pendingHatchOwned = PetCollectionData.addPetOnce(
	pendingHatchProfile, "pending-hatch-pet", "bunny", 2, 100, "hatch:pending-001", "hatch:tx-pending-001"
)
expect("hatch grant stores its source transaction", pendingHatchAdded and pendingHatchStatus == "UPDATED" and pendingHatchOwned ~= nil)
assert(pendingHatchOwned ~= nil)
local pendingHatchRetry, pendingHatchRetryStatus = PetCollectionData.addPetOnce(
	pendingHatchOwned, "duplicate-hatch-pet", "bunny", 2,
	100 + PetCollectionData.ACQUISITION_RECEIPT_RETENTION_SECONDS + 100,
	"hatch:pending-001", "hatch:tx-pending-001"
)
expect("unacknowledged hatch receipt survives beyond seven days",
	not pendingHatchRetry and pendingHatchRetryStatus == "ALREADY_ACQUIRED")
local acknowledgedHatch, acknowledgedHatchStatus, acknowledgedHatchProfile =
	PetCollectionData.acknowledgeAcquisition(pendingHatchOwned, "hatch:pending-001", "hatch:tx-pending-001", 200)
expect("durable journal completion acknowledges hatch receipt",
	acknowledgedHatch and acknowledgedHatchStatus == "ACKNOWLEDGED" and acknowledgedHatchProfile ~= nil)
assert(acknowledgedHatchProfile ~= nil)
local mismatchedAck, mismatchedAckStatus = PetCollectionData.acknowledgeAcquisition(
	acknowledgedHatchProfile, "hatch:pending-001", "hatch:wrong-transaction", 201
)
expect("receipt cannot be acknowledged by a different transaction",
	not mismatchedAck and mismatchedAckStatus == "ACQUISITION_TRANSACTION_MISMATCH")
local repeatedAck, repeatedAckStatus = PetCollectionData.acknowledgeAcquisition(
	acknowledgedHatchProfile, "hatch:pending-001", "hatch:tx-pending-001", 202
)
expect("receipt acknowledgement is idempotent", not repeatedAck and repeatedAckStatus == "ALREADY_ACKNOWLEDGED")
local expiredAcknowledgedHatch, expiredAcknowledgedStatus =
	PetCollectionData.reservePetSlotOnce(
		acknowledgedHatchProfile, "hatch:after-completion", "bunny", 1,
		200 + PetCollectionData.ACQUISITION_RECEIPT_RETENTION_SECONDS + 1, "hatch:tx-after-completion"
	)
expect("acknowledged receipt can be compacted after completion retention",
	expiredAcknowledgedHatch and expiredAcknowledgedStatus == "RESERVED")

local sessionProfile = PetCollectionData.createDefault(12345)
assert(sessionProfile ~= nil)
sessionProfile.collectionSessionGeneration = 3
sessionProfile.collectionSessionToken = "server-session-token"
local sessionValid, sessionReason = PetCollectionData.validate(sessionProfile, 12345)
expect("fenced collection profile validates", sessionValid and sessionReason == "VALID")

local sessionClone = PetCollectionData.clone(sessionProfile)
expect("collection cloning preserves writer generation and token",
	sessionClone.collectionSessionGeneration == 3
	and sessionClone.collectionSessionToken == "server-session-token")
local sessionMutated, _, sessionUpdated = PetCollectionData.setPetFlags(
	sessionProfile, "starter-bunny", true, false
)
expect("pet mutation preserves collection fencing",
	sessionMutated and sessionUpdated ~= nil
	and sessionUpdated.collectionSessionGeneration == 3
	and sessionUpdated.collectionSessionToken == "server-session-token")

local incompleteSession = PetCollectionData.clone(sessionProfile)
incompleteSession.collectionSessionToken = nil
local incompleteValid, incompleteReason = PetCollectionData.validate(incompleteSession, 12345)
expect("partial collection session metadata is rejected",
	not incompleteValid and incompleteReason == "INCOMPLETE_COLLECTION_SESSION")

print("[PetKingdoms Test] PetCollectionData smoke tests completed.")
