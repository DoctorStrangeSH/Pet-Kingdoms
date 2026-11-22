--!strict
-- Pure island-profile hatch journal operations.
-- Each operation returns a cloned profile; callers must persist it before acknowledging success.
local IslandHatchLedgerData = {}

IslandHatchLedgerData.MAX_TRANSACTIONS = 64
IslandHatchLedgerData.RETENTION_SECONDS = 7 * 24 * 60 * 60
IslandHatchLedgerData.MAX_ID_LENGTH = 128
IslandHatchLedgerData.MAX_EGG_ID_LENGTH = 48
IslandHatchLedgerData.MAX_AMOUNT = 2_000_000_000

local VALID_RESOURCES = {
	wood = true,
	stone = true,
	gold = true,
	gems = true,
}

local function isInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value >= 0
		and value <= IslandHatchLedgerData.MAX_AMOUNT
		and value == math.floor(value)
end

local function isToken(value: any, maxLength: number): boolean
	return type(value) == "string"
		and #value > 0
		and #value <= maxLength
		and string.match(value, "^[%w][%w:_%-]*$") ~= nil
end

local function copyProfile(profile: any): any
	local copy = table.clone(profile)
	copy.buildings = table.clone(profile.buildings or {})
	for index, record in ipairs(profile.buildings or {}) do
		copy.buildings[index] = table.clone(record)
	end
	copy.unlockedBuildingIds = table.clone(profile.unlockedBuildingIds or {})
	copy.resources = table.clone(profile.resources or {})
	copy.hatchTransactions = {}
	for index, record in ipairs(profile.hatchTransactions or {}) do
		local cloned = table.clone(record)
		cloned.costs = table.clone(record.costs)
		copy.hatchTransactions[index] = cloned
	end
	return copy
end

local function validateCosts(costs: any): (boolean, string)
	if type(costs) ~= "table" then return false, "INVALID_COSTS" end
	local count = 0
	for resourceId, amount in pairs(costs) do
		if type(resourceId) ~= "string" or VALID_RESOURCES[resourceId] ~= true then
			return false, "UNKNOWN_RESOURCE"
		end
		if not isInteger(amount) or amount == 0 then return false, "INVALID_COST" end
		count += 1
	end
	if count == 0 then return false, "EMPTY_COSTS" end
	return true, "VALID"
end

function IslandHatchLedgerData.validateRecord(record: any): (boolean, string)
	if type(record) ~= "table" then return false, "INVALID_TRANSACTION" end
	for key in pairs(record) do
		if key ~= "transactionId" and key ~= "eggId" and key ~= "speciesId"
			and key ~= "rarityTier" and key ~= "costs" and key ~= "createdAt"
			and key ~= "state" and key ~= "acquisitionId"
		then
			return false, "UNKNOWN_TRANSACTION_FIELD"
		end
	end
	if not isToken(record.transactionId, IslandHatchLedgerData.MAX_ID_LENGTH) then
		return false, "INVALID_TRANSACTION_ID"
	end
	if not isToken(record.eggId, IslandHatchLedgerData.MAX_EGG_ID_LENGTH) then
		return false, "INVALID_EGG_ID"
	end
	if not isToken(record.speciesId, 48) then return false, "INVALID_SPECIES_ID" end
	if not isInteger(record.rarityTier) or record.rarityTier < 1 or record.rarityTier > 6 then
		return false, "INVALID_RARITY_TIER"
	end
	if not isInteger(record.createdAt) then return false, "INVALID_CREATED_AT" end
	if record.state ~= "PREPARED" and record.state ~= "CHARGED" and record.state ~= "GRANTED" then
		return false, "INVALID_STATE"
	end
	if not isToken(record.acquisitionId, IslandHatchLedgerData.MAX_ID_LENGTH) then
		return false, "INVALID_ACQUISITION_ID"
	end
	local validCosts, costReason = validateCosts(record.costs)
	if not validCosts then return false, costReason end
	return true, "VALID"
end

function IslandHatchLedgerData.validateLedger(ledger: any): (boolean, string)
	if type(ledger) ~= "table" then return false, "INVALID_HATCH_LEDGER" end
	local count = 0
	local highestIndex = 0
	local seen: { [string]: boolean } = {}
	for key, record in pairs(ledger) do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			return false, "INVALID_HATCH_LEDGER_LIST"
		end
		count += 1
		highestIndex = math.max(highestIndex, key)
		local valid, reason = IslandHatchLedgerData.validateRecord(record)
		if not valid then return false, reason end
		if seen[record.transactionId] then return false, "DUPLICATE_TRANSACTION_ID" end
		seen[record.transactionId] = true
	end
	if count > IslandHatchLedgerData.MAX_TRANSACTIONS or highestIndex ~= count then
		return false, "INVALID_HATCH_LEDGER_COUNT"
	end
	return true, "VALID"
end

local function findTransaction(ledger: any, transactionId: string): (number?, any?)
	for index, record in ipairs(ledger) do
		if record.transactionId == transactionId then return index, record end
	end
	return nil, nil
end

function IslandHatchLedgerData.prepare(profile: any, record: any, now: number): (any?, string)
	if type(profile) ~= "table" or type(profile.resources) ~= "table" then
		return nil, "INVALID_PROFILE"
	end
	local validRecord, recordReason = IslandHatchLedgerData.validateRecord(record)
	if not validRecord then return nil, recordReason end
	if record.state ~= "PREPARED" then return nil, "NEW_TRANSACTION_MUST_BE_PREPARED" end
	if not isInteger(now) then return nil, "INVALID_TIMESTAMP" end

	local ledger = profile.hatchTransactions or {}
	local validLedger, ledgerReason = IslandHatchLedgerData.validateLedger(ledger)
	if not validLedger then return nil, ledgerReason end
	local _, existing = findTransaction(ledger, record.transactionId)
	if existing then
		if existing.eggId ~= record.eggId or existing.speciesId ~= record.speciesId
			or existing.rarityTier ~= record.rarityTier or existing.acquisitionId ~= record.acquisitionId
		then
			return nil, "TRANSACTION_ID_CONFLICT"
		end
		for resourceId, amount in pairs(existing.costs) do
			if record.costs[resourceId] ~= amount then return nil, "TRANSACTION_ID_CONFLICT" end
		end
		for resourceId, amount in pairs(record.costs) do
			if existing.costs[resourceId] ~= amount then return nil, "TRANSACTION_ID_CONFLICT" end
		end
		return copyProfile(profile), "ALREADY_PREPARED"
	end

	local retained = {}
	for _, entry in ipairs(ledger) do
		local age = now - entry.createdAt
		if age < 0 or age <= IslandHatchLedgerData.RETENTION_SECONDS or entry.state ~= "GRANTED" then
			table.insert(retained, entry)
		end
	end
	if #retained >= IslandHatchLedgerData.MAX_TRANSACTIONS then
		return nil, "HATCH_LEDGER_FULL"
	end

	local nextProfile = copyProfile(profile)
	local nextRecord = table.clone(record)
	nextRecord.costs = table.clone(record.costs)
	table.insert(retained, nextRecord)
	nextProfile.hatchTransactions = retained
	return nextProfile, "PREPARED"
end

function IslandHatchLedgerData.charge(profile: any, transactionId: string): (any?, string)
	if type(profile) ~= "table" or type(profile.resources) ~= "table" then
		return nil, "INVALID_PROFILE"
	end
	local ledger = profile.hatchTransactions or {}
	local validLedger, ledgerReason = IslandHatchLedgerData.validateLedger(ledger)
	if not validLedger then return nil, ledgerReason end
	local index, record = findTransaction(ledger, transactionId)
	if index == nil or record == nil then return nil, "TRANSACTION_NOT_FOUND" end
	if record.state == "CHARGED" or record.state == "GRANTED" then
		return copyProfile(profile), "ALREADY_CHARGED"
	end
	if record.state ~= "PREPARED" then return nil, "INVALID_STATE_TRANSITION" end

	local nextResources = table.clone(profile.resources)
	for resourceId, amount in pairs(record.costs) do
		local balance = nextResources[resourceId]
		if not isInteger(balance) then return nil, "INVALID_RESOURCE_BALANCE" end
		if balance < amount then return nil, "INSUFFICIENT_RESOURCES" end
	end
	for resourceId, amount in pairs(record.costs) do
		nextResources[resourceId] -= amount
	end

	local nextProfile = copyProfile(profile)
	nextProfile.resources = nextResources
	nextProfile.hatchTransactions[index].state = "CHARGED"
	return nextProfile, "CHARGED"
end

function IslandHatchLedgerData.markGranted(profile: any, transactionId: string): (any?, string)
	if type(profile) ~= "table" then return nil, "INVALID_PROFILE" end
	local ledger = profile.hatchTransactions or {}
	local validLedger, ledgerReason = IslandHatchLedgerData.validateLedger(ledger)
	if not validLedger then return nil, ledgerReason end
	local index, record = findTransaction(ledger, transactionId)
	if index == nil or record == nil then return nil, "TRANSACTION_NOT_FOUND" end
	if record.state == "GRANTED" then return copyProfile(profile), "ALREADY_GRANTED" end
	if record.state ~= "CHARGED" then return nil, "INVALID_STATE_TRANSITION" end
	local nextProfile = copyProfile(profile)
	nextProfile.hatchTransactions[index].state = "GRANTED"
	return nextProfile, "GRANTED"
end

return IslandHatchLedgerData
