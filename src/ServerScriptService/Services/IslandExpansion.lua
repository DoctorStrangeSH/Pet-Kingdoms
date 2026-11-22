--!strict
-- Pure island expansion geometry contract.
-- Purchase prices and unlock conditions intentionally remain undefined until
-- the MVP economy/progression balance is approved.
local IslandExpansion = {}

IslandExpansion.MAX_LEVEL = 2
IslandExpansion.CELLS_PER_LEVEL = 8

export type Bounds = {
	width: number,
	depth: number,
}

local function isPositiveInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value > 0
		and value < math.huge
		and value == math.floor(value)
end

local function isNonNegativeInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value >= 0
		and value < math.huge
		and value == math.floor(value)
end

function IslandExpansion.isValidLevel(level: any): boolean
	return type(level) == "number"
		and level == level
		and level >= 0
		and level <= IslandExpansion.MAX_LEVEL
		and level == math.floor(level)
end

function IslandExpansion.getBounds(baseWidth: number, baseDepth: number, level: number): Bounds?
	if not isPositiveInteger(baseWidth)
		or not isPositiveInteger(baseDepth)
		or not IslandExpansion.isValidLevel(level)
	then
		return nil
	end

	local addedCells = level * IslandExpansion.CELLS_PER_LEVEL
	return {
		width = baseWidth + addedCells,
		depth = baseDepth + addedCells,
	}
end

function IslandExpansion.getNextBounds(baseWidth: number, baseDepth: number, currentLevel: number): Bounds?
	if not IslandExpansion.isValidLevel(currentLevel) or currentLevel >= IslandExpansion.MAX_LEVEL then
		return nil
	end
	return IslandExpansion.getBounds(baseWidth, baseDepth, currentLevel + 1)
end

function IslandExpansion.matchesProfileBounds(profile: any, baseWidth: number, baseDepth: number): boolean
	if type(profile) ~= "table" or not isPositiveInteger(profile.boundsWidth)
		or not isPositiveInteger(profile.boundsDepth)
	then
		return false
	end
	local level = if profile.expansionLevel == nil then 0 else profile.expansionLevel
	local expected = IslandExpansion.getBounds(baseWidth, baseDepth, level)
	return expected ~= nil
		and profile.boundsWidth == expected.width
		and profile.boundsDepth == expected.depth
end

-- Returns a cloned profile for the next expansion level.
-- Moving each saved grid coordinate by half the added dimensions preserves
-- every building's world-space position while the renderer keeps the grid centered.
function IslandExpansion.expandProfile(profile: any): (any?, string)
	if type(profile) ~= "table"
		or not isPositiveInteger(profile.boundsWidth)
		or not isPositiveInteger(profile.boundsDepth)
		or type(profile.buildings) ~= "table"
	then
		return nil, "INVALID_PROFILE"
	end

	local currentLevel = if profile.expansionLevel == nil then 0 else profile.expansionLevel
	if not IslandExpansion.isValidLevel(currentLevel) then
		return nil, "INVALID_EXPANSION_LEVEL"
	end
	if currentLevel >= IslandExpansion.MAX_LEVEL then
		return nil, "MAX_EXPANSION_REACHED"
	end

	local nextLevel = currentLevel + 1
	local nextBounds = IslandExpansion.getNextBounds(profile.boundsWidth, profile.boundsDepth, currentLevel)
	if nextBounds == nil then
		return nil, "INVALID_EXPANSION_BOUNDS"
	end

	local shift = IslandExpansion.CELLS_PER_LEVEL / 2
	local nextProfile = table.clone(profile)
	nextProfile.buildings = {}
	for index, record in ipairs(profile.buildings) do
		if type(record) ~= "table"
			or not isNonNegativeInteger(record.x)
			or not isNonNegativeInteger(record.z)
		then
			return nil, "INVALID_BUILDING_RECORD"
		end
		local nextRecord = table.clone(record)
		nextRecord.x += shift
		nextRecord.z += shift
		nextProfile.buildings[index] = nextRecord
	end

	nextProfile.boundsWidth = nextBounds.width
	nextProfile.boundsDepth = nextBounds.depth
	nextProfile.expansionLevel = nextLevel
	return nextProfile, "EXPANDED"
end

return IslandExpansion
