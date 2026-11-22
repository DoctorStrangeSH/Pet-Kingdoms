--!strict
-- Pure pet XP threshold validation and progress calculation.
-- The game-design XP curve is supplied by the caller; no thresholds are invented here.
local PetProgressionData = {}

local MAX_LEVEL = 50
local MAX_SAFE_INTEGER = 9007199254740991

PetProgressionData.MAX_LEVEL = MAX_LEVEL
PetProgressionData.MAX_SAFE_INTEGER = MAX_SAFE_INTEGER

local function isNonNegativeSafeInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value >= 0
		and value <= MAX_SAFE_INTEGER
		and value == math.floor(value)
end

function PetProgressionData.validateThresholds(thresholds: any): (boolean, string)
	if type(thresholds) ~= "table" then
		return false, "INVALID_THRESHOLDS"
	end

	local count = 0
	local highestIndex = 0
	for key, value in pairs(thresholds) do
		if type(key) ~= "number" or key < 1 or key > MAX_LEVEL or key ~= math.floor(key) then
			return false, "INVALID_THRESHOLD_INDEX"
		end
		count += 1
		highestIndex = math.max(highestIndex, key)
		if not isNonNegativeSafeInteger(value) then
			return false, "INVALID_THRESHOLD_VALUE"
		end
	end

	if count ~= MAX_LEVEL or highestIndex ~= MAX_LEVEL then
		return false, "INCOMPLETE_THRESHOLDS"
	end
	if thresholds[1] ~= 0 then
		return false, "LEVEL_ONE_THRESHOLD_MUST_BE_ZERO"
	end
	for level = 2, MAX_LEVEL do
		if thresholds[level] <= thresholds[level - 1] then
			return false, "THRESHOLDS_NOT_STRICTLY_INCREASING"
		end
	end

	return true, "VALID"
end

function PetProgressionData.getProgress(totalXp: any, thresholds: any): (any?, string?)
	if not isNonNegativeSafeInteger(totalXp) then
		return nil, "INVALID_TOTAL_XP"
	end

	local valid, reason = PetProgressionData.validateThresholds(thresholds)
	if not valid then
		return nil, reason
	end

	local low = 1
	local high = MAX_LEVEL
	local currentLevel = 1
	while low <= high do
		local middle = math.floor((low + high) / 2)
		if thresholds[middle] <= totalXp then
			currentLevel = middle
			low = middle + 1
		else
			high = middle - 1
		end
	end

	local currentLevelXp = totalXp - thresholds[currentLevel]
	local nextLevelXp = thresholds[currentLevel + 1]
	local xpRequiredForNext = if nextLevelXp ~= nil then nextLevelXp - thresholds[currentLevel] else nil
	local progress = if xpRequiredForNext ~= nil
		then currentLevelXp / xpRequiredForNext
		else 1

	return {
		level = currentLevel,
		totalXp = totalXp,
		currentLevelXp = currentLevelXp,
		nextLevelXp = nextLevelXp,
		xpRequiredForNext = xpRequiredForNext,
		progress = progress,
		isMaxLevel = currentLevel == MAX_LEVEL,
	}, nil
end

return PetProgressionData
