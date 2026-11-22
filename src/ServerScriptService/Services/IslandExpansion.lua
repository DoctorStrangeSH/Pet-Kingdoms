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

return IslandExpansion
