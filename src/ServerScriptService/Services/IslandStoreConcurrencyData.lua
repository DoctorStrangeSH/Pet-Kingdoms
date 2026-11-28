--!strict
-- Pure DataStore generation/revision fencing rules.
-- Kept separate from DataStoreService so concurrency decisions are deterministic
-- and can be regression-tested in Studio without touching production data.

local IslandStoreConcurrencyData = {}

local MAX_SESSION_GENERATION = 2_000_000_000

local function isInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value == math.floor(value)
end

function IslandStoreConcurrencyData.nextSessionGeneration(
	currentGeneration: any,
	expectedGeneration: any
): (number?, string)
	local current = if currentGeneration == nil then 0 else currentGeneration
	if not isInteger(current) or current < 0
		or not isInteger(expectedGeneration) or expectedGeneration < 0
	then
		return nil, "INVALID_GENERATION"
	end
	if current ~= expectedGeneration then
		return nil, "GENERATION_CHANGED"
	end
	if current >= MAX_SESSION_GENERATION then
		return nil, "GENERATION_EXHAUSTED"
	end
	return current + 1, "CLAIMED"
end

function IslandStoreConcurrencyData.classifySave(
	currentGeneration: any,
	currentRevision: any,
	snapshotGeneration: any,
	snapshotRevision: any
): string
	if not isInteger(currentGeneration) or currentGeneration < 1
		or not isInteger(snapshotGeneration) or snapshotGeneration < 1
		or not isInteger(currentRevision) or currentRevision < 0
		or not isInteger(snapshotRevision) or snapshotRevision < 0
	then
		return "INVALID_METADATA"
	end
	if currentGeneration ~= snapshotGeneration then
		return "STALE_SESSION"
	end
	if currentRevision >= snapshotRevision then
		return "ALREADY_DURABLE"
	end
	return "WRITE"
end

return IslandStoreConcurrencyData
