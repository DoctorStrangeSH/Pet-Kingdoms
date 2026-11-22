--!strict
-- Data-driven pet stat calculation pipeline.
-- Balance formulas are injected by the caller; this module defines none.
local PetStatsCalculator = {}

local PetStatsData = require(script.Parent:WaitForChild("PetStatsData"))
local PetSpeciesStatsData = require(script.Parent:WaitForChild("PetSpeciesStatsData"))

function PetStatsCalculator.calculate(
	speciesId: any,
	speciesDefinition: any,
	level: any,
	rarityTier: any,
	resolveStats: any
): (any?, string?)
	local validDefinition, definitionReason =
		PetSpeciesStatsData.validateDefinition(speciesId, speciesDefinition)
	if not validDefinition then
		return nil, "INVALID_SPECIES_DEFINITION:" .. definitionReason
	end

	if type(level) ~= "number"
		or level ~= level
		or level == math.huge
		or level == -math.huge
		or level < 1
		or level > PetStatsData.MAX_PET_LEVEL
		or level ~= math.floor(level)
	then
		return nil, "INVALID_LEVEL"
	end

	if type(rarityTier) ~= "number"
		or rarityTier ~= rarityTier
		or rarityTier == math.huge
		or rarityTier == -math.huge
		or rarityTier < 1
		or rarityTier > PetStatsData.RARITY_TIER_COUNT
		or rarityTier ~= math.floor(rarityTier)
	then
		return nil, "INVALID_RARITY_TIER"
	end

	if type(resolveStats) ~= "function" then
		return nil, "MISSING_BALANCE_RESOLVER"
	end

	local baseStats, cloneReason = PetStatsData.cloneStats(speciesDefinition.baseStats)
	if baseStats == nil then
		return nil, "INVALID_BASE_STATS:" .. tostring(cloneReason)
	end

	local ok, resolvedStats = pcall(resolveStats, baseStats, level, rarityTier)
	if not ok then
		return nil, "BALANCE_RESOLUTION_FAILED"
	end

	local validStats, statsReason = PetStatsData.validateStats(resolvedStats)
	if not validStats then
		return nil, "INVALID_RESOLVED_STATS:" .. statsReason
	end

	local copiedStats, copiedReason = PetStatsData.cloneStats(resolvedStats)
	if copiedStats == nil then
		return nil, "INVALID_RESOLVED_STATS:" .. tostring(copiedReason)
	end

	local snapshot = {
		level = level,
		rarityTier = rarityTier,
		stats = copiedStats,
	}
	local validSnapshot, snapshotReason = PetStatsData.validate(snapshot)
	if not validSnapshot then
		return nil, "INVALID_RESULT:" .. snapshotReason
	end

	return snapshot
end

return PetStatsCalculator
