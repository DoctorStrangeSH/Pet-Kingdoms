--!strict
-- Bounded, persisted idempotency receipts for island building operations.
-- Receipts are retained for seven days. When the ledger is full, new
-- mutations fail closed instead of evicting a still-valid retry receipt.

local IslandBuildingJournalData = {}

local MAX_RECEIPTS = 128
local RETENTION_SECONDS = 7 * 24 * 60 * 60
local MAX_REQUEST_ID_LENGTH = 80
local MAX_FINGERPRINT_LENGTH = 256

local function isInteger(value: any): boolean
	return type(value) == "number" and value == value
		and value ~= math.huge and value ~= -math.huge
		and value == math.floor(value)
end

local function cloneResult(result: any): any
	if type(result) ~= "table" then return nil end
	return table.clone(result)
end

function IslandBuildingJournalData.validateLedger(ledger: any): (boolean, string)
	if type(ledger) ~= "table" then return false, "LEDGER_NOT_TABLE" end
	local count = 0
	local highest = 0
	local seen: { [string]: boolean } = {}
	for key, entry in pairs(ledger) do
		if not isInteger(key) or key < 1 or type(entry) ~= "table" then
			return false, "INVALID_ENTRY"
		end
		count += 1
		highest = math.max(highest, key)
		if type(entry.requestId) ~= "string" or #entry.requestId < 1
			or #entry.requestId > MAX_REQUEST_ID_LENGTH
			or seen[entry.requestId] == true
			or type(entry.fingerprint) ~= "string" or #entry.fingerprint < 1
			or #entry.fingerprint > MAX_FINGERPRINT_LENGTH
			or (entry.action ~= "place" and entry.action ~= "move" and entry.action ~= "demolish")
			or not isInteger(entry.createdAt) or entry.createdAt < 0
			or type(entry.result) ~= "table"
			or entry.result.ok ~= true
		then
			return false, "INVALID_ENTRY"
		end
		seen[entry.requestId] = true
	end
	if count ~= highest then return false, "SPARSE_LEDGER" end
	if count > MAX_RECEIPTS then return false, "LEDGER_TOO_LARGE" end
	return true, "VALID"
end

function IslandBuildingJournalData.find(
	ledger: any,
	requestId: string,
	fingerprint: string,
	now: number
): (any?, string)
	local valid = IslandBuildingJournalData.validateLedger(ledger)
	if not valid then return nil, "INVALID_LEDGER" end
	for _, entry in ipairs(ledger) do
		if entry.requestId == requestId then
			if now - entry.createdAt > RETENTION_SECONDS then
				return nil, "EXPIRED"
			end
			if entry.fingerprint ~= fingerprint then
				return nil, "REQUEST_ID_CONFLICT"
			end
			return cloneResult(entry.result), "DUPLICATE"
		end
	end
	return nil, "NOT_FOUND"
end

function IslandBuildingJournalData.append(
	ledger: any,
	requestId: string,
	fingerprint: string,
	action: string,
	result: any,
	now: number
): ({ any }?, string)
	local valid = IslandBuildingJournalData.validateLedger(ledger)
	if not valid then return nil, "INVALID_LEDGER" end
	if type(requestId) ~= "string" or #requestId < 1 or #requestId > MAX_REQUEST_ID_LENGTH
		or type(fingerprint) ~= "string" or #fingerprint < 1 or #fingerprint > MAX_FINGERPRINT_LENGTH
		or (action ~= "place" and action ~= "move" and action ~= "demolish")
		or type(result) ~= "table" or result.ok ~= true
		or not isInteger(now) or now < 0
	then
		return nil, "INVALID_RECEIPT"
	end

	local nextLedger = {}
	for _, entry in ipairs(ledger) do
		if now - entry.createdAt <= RETENTION_SECONDS then
			if entry.requestId == requestId then
				if entry.fingerprint ~= fingerprint then return nil, "REQUEST_ID_CONFLICT" end
				return table.clone(ledger), "ALREADY_RECORDED"
			end
			table.insert(nextLedger, table.clone(entry))
		end
	end
	if #nextLedger >= MAX_RECEIPTS then return nil, "LEDGER_FULL" end

	table.insert(nextLedger, {
		requestId = requestId,
		fingerprint = fingerprint,
		action = action,
		createdAt = now,
		result = cloneResult(result),
	})
	return nextLedger, "RECORDED"
end

return IslandBuildingJournalData
