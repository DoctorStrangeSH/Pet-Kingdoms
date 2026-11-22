--!strict
-- Studio-only tests for the XP threshold contract and level progress resolver.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Pets = game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets")
local PetProgressionData = require(Pets:WaitForChild("PetProgressionData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

-- Synthetic thresholds are used only to test the resolver contract, not game balance.
local thresholds = {}
for level = 1, PetProgressionData.MAX_LEVEL do
	thresholds[level] = (level - 1) * 100
end

local valid, validReason = PetProgressionData.validateThresholds(thresholds)
expect("complete increasing threshold table is accepted", valid and validReason == "VALID")

local levelOne, levelOneReason = PetProgressionData.getProgress(0, thresholds)
expect("zero XP resolves to level one", levelOne ~= nil and levelOneReason == nil and levelOne.level == 1)
expect("level one progress starts at zero", levelOne ~= nil and levelOne.progress == 0)

local belowLevelUp = PetProgressionData.getProgress(99, thresholds)
expect("XP below threshold remains at current level", belowLevelUp ~= nil and belowLevelUp.level == 1 and belowLevelUp.currentLevelXp == 99)

local exactLevelUp = PetProgressionData.getProgress(100, thresholds)
expect("exact threshold advances to next level", exactLevelUp ~= nil and exactLevelUp.level == 2 and exactLevelUp.currentLevelXp == 0)

local midway = PetProgressionData.getProgress(150, thresholds)
expect("progress fraction is calculated within level", midway ~= nil and midway.level == 2 and midway.progress == 0.5 and midway.xpRequiredForNext == 100)

local maxLevelXp = thresholds[PetProgressionData.MAX_LEVEL]
local maxLevel = PetProgressionData.getProgress(maxLevelXp, thresholds)
expect("maximum threshold resolves to level 50", maxLevel ~= nil and maxLevel.level == 50 and maxLevel.isMaxLevel)
expect("maximum level has no next threshold", maxLevel ~= nil and maxLevel.nextLevelXp == nil and maxLevel.progress == 1)

local beyondMaximum = PetProgressionData.getProgress(maxLevelXp + 5000, thresholds)
expect("XP beyond level 50 remains capped at maximum level",
	beyondMaximum ~= nil and beyondMaximum.level == PetProgressionData.MAX_LEVEL
		and beyondMaximum.isMaxLevel and beyondMaximum.progress == 1)
expect("XP beyond level 50 remains visible as lifetime XP",
	beyondMaximum ~= nil and beyondMaximum.totalXp == maxLevelXp + 5000
		and beyondMaximum.currentLevelXp == 5000)

local incomplete = table.clone(thresholds)
incomplete[50] = nil
expect("incomplete threshold table is rejected", not PetProgressionData.validateThresholds(incomplete))

local duplicateThreshold = table.clone(thresholds)
duplicateThreshold[10] = duplicateThreshold[9]
expect("duplicate threshold is rejected", not PetProgressionData.validateThresholds(duplicateThreshold))

local descendingThreshold = table.clone(thresholds)
descendingThreshold[10] = descendingThreshold[9] - 1
expect("descending threshold is rejected", not PetProgressionData.validateThresholds(descendingThreshold))

local wrongFirstThreshold = table.clone(thresholds)
wrongFirstThreshold[1] = 1
expect("level one threshold must be zero", not PetProgressionData.validateThresholds(wrongFirstThreshold))

local invalidIndex = table.clone(thresholds)
invalidIndex.extra = 100
expect("non-numeric threshold index is rejected", not PetProgressionData.validateThresholds(invalidIndex))

local fractionalThreshold = table.clone(thresholds)
fractionalThreshold[2] = 1.5
expect("fractional threshold is rejected", not PetProgressionData.validateThresholds(fractionalThreshold))

local nanThreshold = table.clone(thresholds)
nanThreshold[2] = 0 / 0
expect("NaN threshold is rejected", not PetProgressionData.validateThresholds(nanThreshold))

local invalidXp = PetProgressionData.getProgress(-1, thresholds)
expect("negative XP is rejected", invalidXp == nil)

local fractionalXp = PetProgressionData.getProgress(1.5, thresholds)
expect("fractional XP is rejected", fractionalXp == nil)

local infiniteXp = PetProgressionData.getProgress(math.huge, thresholds)
expect("infinite XP is rejected", infiniteXp == nil)

local nanXp = PetProgressionData.getProgress(0 / 0, thresholds)
expect("NaN XP is rejected", nanXp == nil)

print("[PetKingdoms Test] PetProgressionData smoke tests completed.")
