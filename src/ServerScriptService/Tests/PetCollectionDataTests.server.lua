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
local acquisitionAfterRetention = 1_800_000_000 + PetCollectionData.REWARD_RECEIPT_RETENTION_SECONDS + 1
local reacquired, reacquiredStatus, reacquiredProfile =
	PetCollectionData.addPetOnce(expiredAcquisitionProfile, "pet_acq_after_expiry", "bunny", 2, acquisitionAfterRetention, "egg:opening_001")
expect("expired acquisition receipt follows retention policy", reacquired and reacquiredStatus == "UPDATED" and reacquiredProfile ~= nil)

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
