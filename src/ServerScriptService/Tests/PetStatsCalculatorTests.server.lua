--!strict
-- Studio-only tests for the data-driven pet stat calculation pipeline.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Pets = game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets")
local PetStatsCalculator = require(Pets:WaitForChild("PetStatsCalculator"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local definition = {
	baseStats = {
		health = 100,
		attack = 20,
		defense = 15,
		speed = 10,
		criticalChance = 5,
	},
}

local function identityResolver(baseStats, _level, _rarityTier)
	return baseStats
end

local result, resultReason = PetStatsCalculator.calculate(
	"sample-species",
	definition,
	1,
	1,
	identityResolver
)
expect("valid input resolves a stat snapshot", result ~= nil and resultReason == nil)
expect("identity policy preserves the supplied base values", result ~= nil and result.stats.health == 100)
expect("requested level and rarity are retained", result ~= nil and result.level == 1 and result.rarityTier == 1)

local maxLevel, maxLevelReason = PetStatsCalculator.calculate(
	"sample-species",
	definition,
	50,
	6,
	identityResolver
)
expect("maximum level and rarity are accepted", maxLevel ~= nil and maxLevelReason == nil)

local badLevel, badLevelReason = PetStatsCalculator.calculate(
	"sample-species",
	definition,
	51,
	1,
	identityResolver
)
expect("level above 50 is rejected", badLevel == nil and badLevelReason == "INVALID_LEVEL")

local badRarity, badRarityReason = PetStatsCalculator.calculate(
	"sample-species",
	definition,
	1,
	7,
	identityResolver
)
expect("rarity tier above six is rejected", badRarity == nil and badRarityReason == "INVALID_RARITY_TIER")

local noResolver, noResolverReason = PetStatsCalculator.calculate(
	"sample-species",
	definition,
	1,
	1,
	nil
)
expect("missing balance resolver is rejected", noResolver == nil and noResolverReason == "MISSING_BALANCE_RESOLVER")

local errorResolver = function()
	error("test resolver failure")
end
local failed, failedReason = PetStatsCalculator.calculate(
	"sample-species",
	definition,
	1,
	1,
	errorResolver
)
expect("resolver errors fail safely", failed == nil and failedReason == "BALANCE_RESOLUTION_FAILED")

local invalidResolver = function(baseStats)
	baseStats.health = -1
	return baseStats
end
local invalid, invalidReason = PetStatsCalculator.calculate(
	"sample-species",
	definition,
	1,
	1,
	invalidResolver
)
expect("invalid calculated stats are rejected", invalid == nil and invalidReason == "INVALID_RESOLVED_STATS:INVALID_STAT:health")
expect("resolver cannot mutate source species definition", definition.baseStats.health == 100)

local extraStatResolver = function(baseStats)
	baseStats.mana = 100
	return baseStats
end
local extraStat, extraStatReason = PetStatsCalculator.calculate(
	"sample-species",
	definition,
	1,
	1,
	extraStatResolver
)
expect("unknown calculated stat is rejected", extraStat == nil and extraStatReason == "INVALID_RESOLVED_STATS:UNKNOWN_STAT_KEY")

local clonedResult, clonedReason = PetStatsCalculator.calculate(
	"sample-species",
	definition,
	2,
	2,
	identityResolver
)
assert(clonedResult ~= nil, tostring(clonedReason))
clonedResult.stats.health = 999
expect("result snapshot does not mutate species base definition", definition.baseStats.health == 100)


local modifierList = {
	{
		id = "test_health_charm",
		sourceType = "equipment",
		sourceId = "health_charm",
		stat = "health",
		operation = "flat",
		value = 10,
	},
}
local function testModifierPolicy(currentStats, modifier)
	local nextStats = table.clone(currentStats)
	if modifier.stat == "health" then
		nextStats.health += modifier.value
	end
	return nextStats
end

local integrated, integratedReason = PetStatsCalculator.calculateWithModifiers(
	"sample-species",
	definition,
	3,
	2,
	identityResolver,
	modifierList,
	testModifierPolicy
)
expect("calculator integrates the modifier pipeline", integrated ~= nil and integratedReason == nil)
expect("integrated result retains level and rarity", integrated ~= nil and integrated.level == 3 and integrated.rarityTier == 2)
expect("integrated result contains modified stats", integrated ~= nil and integrated.stats.health == 110)
expect("modifier integration leaves species definition unchanged", definition.baseStats.health == 100)

local integratedNoPolicy, integratedNoPolicyReason = PetStatsCalculator.calculateWithModifiers(
	"sample-species",
	definition,
	1,
	1,
	identityResolver,
	modifierList,
	nil
)
expect("non-empty modifiers require an application policy", integratedNoPolicy == nil and integratedNoPolicyReason == "MISSING_MODIFIER_POLICY")

local integratedEmpty, integratedEmptyReason = PetStatsCalculator.calculateWithModifiers(
	"sample-species",
	definition,
	1,
	1,
	identityResolver,
	{},
	nil
)
expect("empty modifiers do not require an application policy", integratedEmpty ~= nil and integratedEmptyReason == nil)

print("[PetKingdoms Test] PetStatsCalculator smoke tests completed.")
