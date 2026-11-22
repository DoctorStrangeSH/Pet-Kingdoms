--!strict
-- Pure schema validation for resolved pet stat snapshots.
-- This module intentionally defines no balance values or progression formulas.
local PetStatsData = {}

PetStatsData.MAX_PET_LEVEL = 50
PetStatsData.RARITY_TIER_COUNT = 6
PetStatsData.MAX_SAFE_NUMBER = 9007199254740991

local STAT_KEYS = {
	"health",
	"attack",
	"defense",
	"speed",
	"criticalChance",
}

local VALID_STAT_KEYS: { [string]: boolean } = {}
for _, statKey in ipairs(STAT_KEYS) do
	VALID_STAT_KEYS[statKey] = true
end

local function isFiniteNonNegativeNumber(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value >= 0
		and value <= PetStatsData.MAX_SAFE_NUMBER
end

local function isPositiveInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value >= 1
		and value <= PetStatsData.MAX_SAFE_NUMBER
		and value == math.floor(value)
end

function PetStatsData.getStatKeys(): { string }
	return table.clone(STAT_KEYS)
end

function PetStatsData.validate(snapshot: any): (boolean, string)
	if type(snapshot) ~= "table" then
		return false, "SNAPSHOT_NOT_TABLE"
	end
	if not isPositiveInteger(snapshot.level) or snapshot.level > PetStatsData.MAX_PET_LEVEL then
		return false, "INVALID_LEVEL"
	end
	if not isPositiveInteger(snapshot.rarityTier) or snapshot.rarityTier > PetStatsData.RARITY_TIER_COUNT then
		return false, "INVALID_RARITY_TIER"
	end
	if type(snapshot.stats) ~= "table" then
		return false, "INVALID_STATS"
	end

	local statCount = 0
	for key in pairs(snapshot.stats) do
		if type(key) ~= "string" or not VALID_STAT_KEYS[key] then
			return false, "UNKNOWN_STAT_KEY"
		end
		statCount += 1
	end
	if statCount ~= #STAT_KEYS then
		return false, "INVALID_STAT_COUNT"
	end

	for _, statKey in ipairs(STAT_KEYS) do
		if not isFiniteNonNegativeNumber(snapshot.stats[statKey]) then
			return false, "INVALID_STAT:" .. statKey
		end
	end

	return true, "VALID"
end

function PetStatsData.clone(snapshot: any): any
	local stats = {}
	for _, statKey in ipairs(STAT_KEYS) do
		stats[statKey] = snapshot.stats[statKey]
	end
	return {
		level = snapshot.level,
		rarityTier = snapshot.rarityTier,
		stats = stats,
	}
end

return PetStatsData
