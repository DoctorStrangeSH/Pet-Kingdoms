--!strict
-- Studio-only pure schema tests for pet stat snapshots.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local PetStatsData = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetStatsData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local validSnapshot = {
	level = 1,
	rarityTier = 1,
	stats = {
		health = 0,
		attack = 0,
		defense = 0,
		speed = 0,
		criticalChance = 0,
	},
}

local valid, validStatus = PetStatsData.validate(validSnapshot)
expect("complete zero-valued stat schema is valid", valid and validStatus == "VALID")
expect("all five approved stat keys are exposed", #PetStatsData.getStatKeys() == 5)

local maxLevel = PetStatsData.clone(validSnapshot)
maxLevel.level = PetStatsData.MAX_PET_LEVEL
expect("maximum pet level 50 is valid", PetStatsData.validate(maxLevel))

local overLevel = PetStatsData.clone(validSnapshot)
overLevel.level = PetStatsData.MAX_PET_LEVEL + 1
expect("pet level above 50 is rejected", not PetStatsData.validate(overLevel))

local fractionalLevel = PetStatsData.clone(validSnapshot)
fractionalLevel.level = 1.5
expect("fractional pet level is rejected", not PetStatsData.validate(fractionalLevel))

local allRaritiesValid = true
for tier = 1, PetStatsData.RARITY_TIER_COUNT do
	local candidate = PetStatsData.clone(validSnapshot)
	candidate.rarityTier = tier
	local candidateValid = PetStatsData.validate(candidate)
	allRaritiesValid = allRaritiesValid and candidateValid
end
expect("all six rarity tier identifiers are accepted", allRaritiesValid)

local invalidRarity = PetStatsData.clone(validSnapshot)
invalidRarity.rarityTier = 7
expect("rarity tier above six is rejected", not PetStatsData.validate(invalidRarity))

local fractionalRarity = PetStatsData.clone(validSnapshot)
fractionalRarity.rarityTier = 1.5
expect("fractional rarity tier is rejected", not PetStatsData.validate(fractionalRarity))

for _, statKey in ipairs(PetStatsData.getStatKeys()) do
	local missingStat = PetStatsData.clone(validSnapshot)
	missingStat.stats[statKey] = nil
	local missingValid, missingStatus = PetStatsData.validate(missingStat)
	expect("missing " .. statKey .. " is rejected", not missingValid and missingStatus == "INVALID_STAT:" .. statKey)

	local negativeStat = PetStatsData.clone(validSnapshot)
	negativeStat.stats[statKey] = -1
	expect("negative " .. statKey .. " is rejected", not PetStatsData.validate(negativeStat))

	local nanStat = PetStatsData.clone(validSnapshot)
	nanStat.stats[statKey] = 0 / 0
	expect("NaN " .. statKey .. " is rejected", not PetStatsData.validate(nanStat))

	local infiniteStat = PetStatsData.clone(validSnapshot)
	infiniteStat.stats[statKey] = math.huge
	expect("infinite " .. statKey .. " is rejected", not PetStatsData.validate(infiniteStat))
end

local invalidSnapshot = PetStatsData.validate(nil)
expect("nil snapshot is rejected", not invalidSnapshot)

local invalidStats = PetStatsData.clone(validSnapshot)
invalidStats.stats = nil
expect("missing stats table is rejected", not PetStatsData.validate(invalidStats))

local extraStat = PetStatsData.clone(validSnapshot)
extraStat.stats.mana = 10
local extraStatValid, extraStatStatus = PetStatsData.validate(extraStat)
expect("unknown stat key is rejected", not extraStatValid and extraStatStatus == "UNKNOWN_STAT_KEY")

local numericStatKey = PetStatsData.clone(validSnapshot)
numericStatKey.stats[1] = 10
local numericStatValid, numericStatStatus = PetStatsData.validate(numericStatKey)
expect("non-string stat key is rejected", not numericStatValid and numericStatStatus == "UNKNOWN_STAT_KEY")

local missingStatCount = PetStatsData.clone(validSnapshot)
missingStatCount.stats.criticalChance = nil
local missingStatCountValid, missingStatCountStatus = PetStatsData.validate(missingStatCount)
expect("incomplete stat count is rejected", not missingStatCountValid and missingStatCountStatus == "INVALID_STAT_COUNT")

local clone = PetStatsData.clone(validSnapshot)
clone.stats.health = 999
expect("cloned stat snapshot does not mutate source", validSnapshot.stats.health == 0)

print("[PetKingdoms Test] PetStatsData smoke tests completed.")
