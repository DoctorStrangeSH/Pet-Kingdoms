--!strict
-- Studio-only pure contract tests for durable quest claims and XP outbox records.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local QuestRewardOutboxData = require(services:WaitForChild("QuestRewardOutboxData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local claims = QuestRewardOutboxData.createClaims()
local validClaims, validClaimsCode = QuestRewardOutboxData.validateClaims(claims)
expect("empty permanent claim ledger validates", validClaims and validClaimsCode == "VALID")

local claimed, claimCode = QuestRewardOutboxData.recordClaim(
	claims, "gather_wood", "quest:gather_wood:reward:v1", 100
)
expect("first quest claim is recorded", claimed ~= nil and claimCode == "CLAIM_RECORDED")
expect("claim recording does not mutate source ledger", claims.gather_wood == nil)
local duplicateClaim, duplicateClaimCode = QuestRewardOutboxData.recordClaim(
	claimed, "gather_wood", "quest:gather_wood:reward:v1", 101
)
expect("duplicate claim is permanently rejected", duplicateClaim == nil and duplicateClaimCode == "ALREADY_CLAIMED")
local conflictingClaim, conflictingClaimCode = QuestRewardOutboxData.recordClaim(
	claimed, "gather_wood", "quest:gather_wood:reward:v2", 102
)
expect("second reward identity cannot replace a claim receipt",
	conflictingClaim == nil and conflictingClaimCode == "CLAIM_RECEIPT_CONFLICT")
local invalidClaim = { fake_quest = { rewardId = "bad", claimedAt = 100 } }
local invalidClaimOk = QuestRewardOutboxData.validateClaims(invalidClaim)
expect("unknown quest claim IDs are rejected", not invalidClaimOk)
local duplicateRewardClaims = {
	gather_wood = { rewardId = "shared-reward", claimedAt = 100 },
	gather_stone = { rewardId = "shared-reward", claimedAt = 100 },
}
local duplicateRewardClaimsOk, duplicateRewardClaimsCode =
	QuestRewardOutboxData.validateClaims(duplicateRewardClaims)
expect("claim ledger rejects reward IDs reused across quests",
	not duplicateRewardClaimsOk and duplicateRewardClaimsCode == "DUPLICATE_CLAIM_REWARD_ID")
local reusedClaim, reusedClaimCode = QuestRewardOutboxData.recordClaim(
	claimed, "gather_stone", "quest:gather_wood:reward:v1", 103
)
expect("one reward ID cannot be claimed for two quests",
	reusedClaim == nil and reusedClaimCode == "CLAIM_REWARD_ID_REUSED")

local outbox = QuestRewardOutboxData.createOutbox()
local record = {
	rewardId = "quest:gather_wood:reward:v1",
	questId = "gather_wood",
	petId = "starter-bunny",
	amount = 250,
	progressionVersion = 1,
	createdAt = 100,
}
local queued, queueCode = QuestRewardOutboxData.append(outbox, record)
expect("valid XP reward enters outbox", queued ~= nil and queueCode == "QUEUED")
expect("append does not mutate source outbox", #outbox == 0)
local duplicateQueue, duplicateQueueCode = QuestRewardOutboxData.append(queued, record)
expect("same reward ID and payload are idempotent",
	duplicateQueue == nil and duplicateQueueCode == "ALREADY_QUEUED")
local conflictingRecord = table.clone(record)
conflictingRecord.amount = 500
local conflict, conflictCode = QuestRewardOutboxData.append(queued, conflictingRecord)
expect("same reward ID cannot change its payload", conflict == nil and conflictCode == "REWARD_ID_CONFLICT")
expect("pending reward is discoverable after reload",
	#QuestRewardOutboxData.listPending(queued) == 1
		and QuestRewardOutboxData.listPending(queued)[1].rewardId == record.rewardId)

local delivered, deliveredCode = QuestRewardOutboxData.markDelivered(queued, record.rewardId, 110)
expect("outbox delivery is recorded", delivered ~= nil and deliveredCode == "DELIVERED")
expect("delivered reward is no longer pending", delivered ~= nil
	and #QuestRewardOutboxData.listPending(delivered) == 0)
local duplicateDelivery, duplicateDeliveryCode =
	QuestRewardOutboxData.markDelivered(delivered, record.rewardId, 111)
expect("delivery acknowledgement is idempotent",
	duplicateDelivery == nil and duplicateDeliveryCode == "ALREADY_DELIVERED")
local unknownDelivery, unknownDeliveryCode =
	QuestRewardOutboxData.markDelivered(delivered, "missing-reward", 111)
expect("unknown delivery cannot mutate outbox",
	unknownDelivery == nil and unknownDeliveryCode == "REWARD_NOT_FOUND")

local malformed = { table.clone(record), table.clone(record) }
local malformedOk, malformedCode = QuestRewardOutboxData.validateOutbox(malformed)
expect("duplicate reward IDs invalidate the outbox",
	not malformedOk and malformedCode == "DUPLICATE_REWARD_ID")
local invalidTimestamp = table.clone(record)
invalidTimestamp.deliveredAt = 99
local timestampLedgerOk = QuestRewardOutboxData.validateOutbox({ invalidTimestamp })
expect("delivery before enqueue time is rejected", not timestampLedgerOk)

local fullOutbox = QuestRewardOutboxData.createOutbox()
for index = 1, QuestRewardOutboxData.MAX_OUTBOX_ENTRIES do
	local fullRecord = table.clone(record)
	fullRecord.rewardId = "capacity-reward-" .. tostring(index)
	local nextOutbox, status = QuestRewardOutboxData.append(fullOutbox, fullRecord)
	assert(nextOutbox ~= nil and status == "QUEUED", "outbox capacity setup failed")
	fullOutbox = nextOutbox
end
local overflowRecord = table.clone(record)
overflowRecord.rewardId = "capacity-overflow"
local overflow, overflowCode = QuestRewardOutboxData.append(fullOutbox, overflowRecord)
expect("full outbox rejects new entries without evicting pending rewards",
	overflow == nil and overflowCode == "OUTBOX_FULL" and #fullOutbox == QuestRewardOutboxData.MAX_OUTBOX_ENTRIES)

print("[PetKingdoms Test] QuestRewardOutboxData tests completed.")
