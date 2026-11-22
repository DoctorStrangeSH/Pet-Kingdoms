--!strict
-- Ordered, policy-injected modifier pipeline.
-- This module never decides flat/percent arithmetic or stacking semantics.
local PetStatModifierPipeline = {}

local PetStatsData = require(script.Parent:WaitForChild("PetStatsData"))
local PetStatModifiersData = require(script.Parent:WaitForChild("PetStatModifiersData"))

function PetStatModifierPipeline.apply(
	baseStats: any,
	modifiers: any,
	applyModifier: any
): (any?, string?)
	local validStats, statsReason = PetStatsData.validateStats(baseStats)
	if not validStats then
		return nil, "INVALID_BASE_STATS:" .. statsReason
	end

	local validModifiers, modifiersReason = PetStatModifiersData.validateList(modifiers)
	if not validModifiers then
		return nil, "INVALID_MODIFIERS:" .. modifiersReason
	end

	local currentStats, cloneReason = PetStatsData.cloneStats(baseStats)
	if currentStats == nil then
		return nil, "INVALID_BASE_STATS:" .. tostring(cloneReason)
	end

	if #modifiers == 0 then
		return currentStats
	end

	if type(applyModifier) ~= "function" then
		return nil, "MISSING_MODIFIER_POLICY"
	end

	for index, modifier in ipairs(modifiers) do
		local modifierCopy, modifierCloneReason = PetStatModifiersData.cloneModifier(modifier)
		if modifierCopy == nil then
			return nil, "INVALID_MODIFIER_AT:" .. tostring(index) .. ":" .. tostring(modifierCloneReason)
		end

		local ok, nextStats = pcall(applyModifier, currentStats, modifierCopy, index)
		if not ok then
			return nil, "MODIFIER_POLICY_FAILED_AT:" .. tostring(index)
		end

		local validNextStats, nextStatsReason = PetStatsData.validateStats(nextStats)
		if not validNextStats then
			return nil, "INVALID_MODIFIER_RESULT_AT:" .. tostring(index) .. ":" .. nextStatsReason
		end

		local nextStatsCopy, nextCloneReason = PetStatsData.cloneStats(nextStats)
		if nextStatsCopy == nil then
			return nil, "INVALID_MODIFIER_RESULT_AT:" .. tostring(index) .. ":" .. tostring(nextCloneReason)
		end
		currentStats = nextStatsCopy
	end

	return currentStats
end

return PetStatModifierPipeline
