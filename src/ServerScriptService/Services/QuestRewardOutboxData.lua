--!strict
-- Durable quest reward claim receipts and cross-DataStore XP outbox contracts.
-- This module is pure data logic: it never grants rewards or calls DataStoreService.
local QuestProgressData = require(script.Parent:WaitForChild("QuestProgressData"))

local QuestRewardOutboxData = {}

QuestRewardOutboxData.MAX_OUTBOX_ENTRIES = 256
QuestRewardOutboxData.MAX_REWARD_ID_LENGTH = 128
QuestRewardOutboxData.MAX_PET_ID_LENGTH = 64
QuestRewardOutboxData.MAX_REWARD_AMOUNT = 2_000_000_000

local function isInteger(value: any): boolean
	return type(value) == "number" and value == value
		and value ~= math.huge and value ~= -math.huge
		and value >= 0 and value == math.floor(value)
end

local function isNonEmptyString(value: any, maxLength: number): boolean
	return type(value) == "string" and #value > 0 and #value <= maxLength
end

local function isValidTimestamp(value: any): boolean
	return type(value) == "number" and value == value
		and value ~= math.huge and value ~= -math.huge and value > 0
end

function QuestRewardOutboxData.createClaims(): { [string]: any }
	return {}
end

function QuestRewardOutboxData.createOutbox(): { any }
	return {}
end

function QuestRewardOutboxData.validateClaims(claims: any): (boolean, string)
	if type(claims) ~= "table" then return false, "INVALID_CLAIMS" end
	local seenRewardIds: { [string]: boolean } = {}
	for questId, receipt in pairs(claims) do
		if type(questId) ~= "string" or QuestProgressData.DEFINITIONS[questId] == nil
			or type(receipt) ~= "table"
			or not isNonEmptyString(receipt.rewardId, QuestRewardOutboxData.MAX_REWARD_ID_LENGTH)
			or not isValidTimestamp(receipt.claimedAt)
			or (receipt.revision ~= nil and (not isInteger(receipt.revision) or receipt.revision < 1)) then
			return false, "INVALID_CLAIM_RECEIPT"
		end
		if seenRewardIds[receipt.rewardId] then return false, "DUPLICATE_CLAIM_REWARD_ID" end
		seenRewardIds[receipt.rewardId] = true
		for key in pairs(receipt) do
			if key ~= "rewardId" and key ~= "claimedAt" and key ~= "revision" then
				return false, "INVALID_CLAIM_RECEIPT"
			end
		end
	end
	return true, "VALID"
end

-- Quest claims are permanent. There is deliberately no pruning or expiry path.
function QuestRewardOutboxData.recordClaim(
	claims: any,
	questId: string,
	rewardId: string,
	claimedAt: number,
	claimRevision: number?
): (any?, string)
	local valid, reason = QuestRewardOutboxData.validateClaims(claims)
	if not valid then return nil, reason end
	if type(questId) ~= "string" or QuestProgressData.DEFINITIONS[questId] == nil then
		return nil, "UNKNOWN_QUEST"
	end
	if not isNonEmptyString(rewardId, QuestRewardOutboxData.MAX_REWARD_ID_LENGTH)
		or not isValidTimestamp(claimedAt)
		or (claimRevision ~= nil and (not isInteger(claimRevision) or claimRevision < 1)) then
		return nil, "INVALID_CLAIM_RECEIPT"
	end

	local existing = claims[questId]
	if existing ~= nil then
		if existing.rewardId == rewardId then return nil, "ALREADY_CLAIMED" end
		return nil, "CLAIM_RECEIPT_CONFLICT"
	end
	for _, receipt in pairs(claims) do
		if receipt.rewardId == rewardId then return nil, "CLAIM_REWARD_ID_REUSED" end
	end

	local nextClaims = table.clone(claims)
	nextClaims[questId] = { rewardId = rewardId, claimedAt = claimedAt, revision = claimRevision }
	return nextClaims, "CLAIM_RECORDED"
end

local function validateOutboxRecord(record: any): (boolean, string)
	if type(record) ~= "table"
		or not isNonEmptyString(record.rewardId, QuestRewardOutboxData.MAX_REWARD_ID_LENGTH)
		or type(record.questId) ~= "string"
		or QuestProgressData.DEFINITIONS[record.questId] == nil
		or not isNonEmptyString(record.petId, QuestRewardOutboxData.MAX_PET_ID_LENGTH)
		or not isInteger(record.amount) or record.amount < 1
		or record.amount > QuestRewardOutboxData.MAX_REWARD_AMOUNT
		or not isInteger(record.progressionVersion) or record.progressionVersion < 1
		or not isValidTimestamp(record.createdAt) then
		return false, "INVALID_OUTBOX_RECORD"
	end
	if record.deliveredAt ~= nil and (not isValidTimestamp(record.deliveredAt)
		or record.deliveredAt < record.createdAt) then
		return false, "INVALID_DELIVERY_TIMESTAMP"
	end
	for key in pairs(record) do
		if key ~= "rewardId" and key ~= "questId" and key ~= "petId"
			and key ~= "amount" and key ~= "progressionVersion"
			and key ~= "createdAt" and key ~= "deliveredAt" then
			return false, "INVALID_OUTBOX_RECORD"
		end
	end
	return true, "VALID"
end

function QuestRewardOutboxData.validateOutbox(outbox: any): (boolean, string)
	if type(outbox) ~= "table" then return false, "INVALID_OUTBOX" end
	local count = 0
	local highestIndex = 0
	local seen: { [string]: boolean } = {}
	for key in pairs(outbox) do
		if not isInteger(key) or key < 1 then return false, "INVALID_OUTBOX_LIST" end
		count += 1
		highestIndex = math.max(highestIndex, key)
	end
	if count > QuestRewardOutboxData.MAX_OUTBOX_ENTRIES then return false, "OUTBOX_FULL" end
	if highestIndex ~= count then return false, "INVALID_OUTBOX_LIST" end
	for _, record in ipairs(outbox) do
		local valid, reason = validateOutboxRecord(record)
		if not valid then return false, reason end
		if seen[record.rewardId] then return false, "DUPLICATE_REWARD_ID" end
		seen[record.rewardId] = true
	end
	return true, "VALID"
end

local function sameReward(left: any, right: any): boolean
	return left.rewardId == right.rewardId
		and left.questId == right.questId
		and left.petId == right.petId
		and left.amount == right.amount
		and left.progressionVersion == right.progressionVersion
		and left.createdAt == right.createdAt
end

-- Pending records are never evicted. A full ledger fails closed rather than
-- dropping an undelivered reward or weakening the cross-store recovery guarantee.
function QuestRewardOutboxData.append(outbox: any, record: any): (any?, string)
	local valid, reason = QuestRewardOutboxData.validateOutbox(outbox)
	if not valid then return nil, reason end
	local recordValid, recordReason = validateOutboxRecord(record)
	if not recordValid then return nil, recordReason end
	for _, existing in ipairs(outbox) do
		if existing.rewardId == record.rewardId then
			if sameReward(existing, record) then return nil, "ALREADY_QUEUED" end
			return nil, "REWARD_ID_CONFLICT"
		end
	end
	if #outbox >= QuestRewardOutboxData.MAX_OUTBOX_ENTRIES then return nil, "OUTBOX_FULL" end
	local nextOutbox = table.clone(outbox)
	table.insert(nextOutbox, table.clone(record))
	return nextOutbox, "QUEUED"
end

function QuestRewardOutboxData.markDelivered(
	outbox: any,
	rewardId: string,
	deliveredAt: number
): (any?, string)
	local valid, reason = QuestRewardOutboxData.validateOutbox(outbox)
	if not valid then return nil, reason end
	if not isNonEmptyString(rewardId, QuestRewardOutboxData.MAX_REWARD_ID_LENGTH)
		or not isValidTimestamp(deliveredAt) then
		return nil, "INVALID_DELIVERY"
	end
	local nextOutbox = table.clone(outbox)
	for index, record in ipairs(outbox) do
		if record.rewardId == rewardId then
			if record.deliveredAt ~= nil then return nil, "ALREADY_DELIVERED" end
			if deliveredAt < record.createdAt then return nil, "INVALID_DELIVERY_TIMESTAMP" end
			local updated = table.clone(record)
			updated.deliveredAt = deliveredAt
			nextOutbox[index] = updated
			return nextOutbox, "DELIVERED"
		end
	end
	return nil, "REWARD_NOT_FOUND"
end

function QuestRewardOutboxData.listPending(outbox: any): { any }
	local valid = QuestRewardOutboxData.validateOutbox(outbox)
	if not valid then return {} end
	local pending = {}
	for _, record in ipairs(outbox) do
		if record.deliveredAt == nil then table.insert(pending, table.clone(record)) end
	end
	return pending
end

return QuestRewardOutboxData
