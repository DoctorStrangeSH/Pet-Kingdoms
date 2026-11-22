--!strict
-- Studio-only tests for the ordered, policy-injected modifier pipeline.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Pets = game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets")
local PetStatModifierPipeline = require(Pets:WaitForChild("PetStatModifierPipeline"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local baseStats = {
	health = 100,
	attack = 20,
	defense = 15,
	speed = 10,
	criticalChance = 5,
}

local emptyResult, emptyReason = PetStatModifierPipeline.apply(baseStats, {})
expect("empty modifier list returns an independent base stat copy", emptyResult ~= nil and emptyReason == nil)
if emptyResult then
	emptyResult.health = 999
end
expect("empty result does not mutate base stats", baseStats.health == 100)

local modifiers = {
	{
		id = "equipment_health",
		sourceType = "equipment",
		sourceId = "health_charm",
		stat = "health",
		operation = "flat",
		value = 10,
	},
	{
		id = "skill_attack",
		sourceType = "skill",
		sourceId = "power_skill",
		stat = "attack",
		operation = "percent",
		value = 5,
	},
}

local seenIndices = {}
local function testPolicy(currentStats, modifier, index)
	table.insert(seenIndices, index)
	local nextStats = table.clone(currentStats)
	if modifier.id == "equipment_health" then
		nextStats.health += modifier.value
	elseif modifier.id == "skill_attack" then
		nextStats.attack += modifier.value
	end
	return nextStats
end

local result, resultReason = PetStatModifierPipeline.apply(baseStats, modifiers, testPolicy)
expect("valid modifiers produce a stat map", result ~= nil and resultReason == nil)
expect("policy receives modifiers in supplied order", seenIndices[1] == 1 and seenIndices[2] == 2)
expect("pipeline accepts policy-provided resolved values", result ~= nil and result.health == 110 and result.attack == 25)
expect("pipeline leaves base stats unchanged", baseStats.health == 100 and baseStats.attack == 20)

local noPolicy, noPolicyReason = PetStatModifierPipeline.apply(baseStats, modifiers, nil)
expect("non-empty modifier list requires a policy", noPolicy == nil and noPolicyReason == "MISSING_MODIFIER_POLICY")

local invalidModifiers, invalidModifiersReason = PetStatModifierPipeline.apply(baseStats, { modifiers[1], modifiers[1] }, testPolicy)
expect("duplicate modifier IDs fail before application", invalidModifiers == nil and invalidModifiersReason == "INVALID_MODIFIERS:DUPLICATE_MODIFIER_ID")

local invalidBase, invalidBaseReason = PetStatModifierPipeline.apply({ health = -1 }, {}, testPolicy)
expect("invalid base stats fail before application", invalidBase == nil and string.find(invalidBaseReason or "", "INVALID_BASE_STATS", 1, true) == 1)

local errorResult, errorReason = PetStatModifierPipeline.apply(baseStats, modifiers, function()
	error("policy failure")
end)
expect("policy errors fail safely", errorResult == nil and errorReason == "MODIFIER_POLICY_FAILED_AT:1")

local invalidResult, invalidResultReason = PetStatModifierPipeline.apply(baseStats, modifiers, function(currentStats)
	local nextStats = table.clone(currentStats)
	nextStats.health = -1
	return nextStats
end)
expect("invalid policy output is rejected", invalidResult == nil and string.find(invalidResultReason or "", "INVALID_MODIFIER_RESULT_AT:1", 1, true) == 1)

local unknownResult, unknownResultReason = PetStatModifierPipeline.apply(baseStats, modifiers, function(currentStats)
	local nextStats = table.clone(currentStats)
	nextStats.mana = 100
	return nextStats
end)
expect("unknown policy output stat is rejected", unknownResult == nil and string.find(unknownResultReason or "", "UNKNOWN_STAT_KEY", 1, true) ~= nil)

local retainedReference
local isolatedResult = PetStatModifierPipeline.apply(baseStats, { modifiers[1] }, function(currentStats)
	retainedReference = currentStats
	return currentStats
end)
expect("policy receives a detached stat copy", retainedReference ~= nil and retainedReference ~= baseStats)
expect("successful result is detached from policy references", isolatedResult ~= nil and isolatedResult ~= retainedReference)

print("[PetKingdoms Test] PetStatModifierPipeline smoke tests completed.")
