--!strict
-- Studio-only contract tests for durable building operation receipts.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local Journal = require(services:WaitForChild("IslandBuildingJournalData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local now = os.time()
local ledger = {}
local result = {
	ok = true,
	code = "BUILDING_PLACED",
	instanceId = "building-1",
	catalogId = "pet_house",
	x = 2,
	z = 3,
	rotation = 0,
}

local appended, appendCode = Journal.append(
	ledger, "request-1", "place|pet_house|2|3|0", "place", result, now, 1
)
expect("first building receipt is appended", appended ~= nil and appendCode == "RECORDED")
ledger = appended or {}

local upgradeResult = {
	ok = true,
	code = "BUILDING_UPGRADED",
	instanceId = "building-1",
	upgradeLevel = 2,
}
local withUpgrade, upgradeAppendCode = Journal.append(
	ledger, "upgrade-request-1", "upgrade|building-1", "upgrade", upgradeResult, now, 2
)
expect("upgrade receipt is accepted by the durable journal",
	withUpgrade ~= nil and upgradeAppendCode == "RECORDED")
ledger = withUpgrade or {}
local replayUpgrade, replayUpgradeCode = Journal.find(
	ledger, "upgrade-request-1", "upgrade|building-1", now, 2
)
expect("successful upgrade receipt can be replayed after persistence",
	replayUpgrade ~= nil and replayUpgradeCode == "DUPLICATE"
		and replayUpgrade.code == "BUILDING_UPGRADED" and replayUpgrade.upgradeLevel == 2)

local invalidUpgradeLedger = Journal.append(
	ledger, "bad-action-request", "bad-action", "repair", upgradeResult, now, 3
)
expect("unsupported journal action is rejected", invalidUpgradeLedger == nil)

local demolitionResult = {
	ok = true,
	code = "BUILDING_DEMOLISHED",
	instanceId = "building-1",
}
local withDemolition, demolitionAppendCode = Journal.append(
	ledger, "demolish-request-1", "demolish|building-1", "demolish", demolitionResult, now, 3
)
expect("demolition receipt is accepted by the durable journal",
	withDemolition ~= nil and demolitionAppendCode == "RECORDED")
ledger = withDemolition or {}
local replayDemolition, replayDemolitionCode = Journal.find(
	ledger, "demolish-request-1", "demolish|building-1", now, 3
)
expect("retry of committed demolition replays the original result without a second mutation",
	replayDemolition ~= nil and replayDemolitionCode == "DUPLICATE"
		and replayDemolition.code == "BUILDING_DEMOLISHED"
		and replayDemolition.instanceId == "building-1")

local replay, replayCode = Journal.find(ledger, "request-1", "place|pet_house|2|3|0", now, 1)
expect("same request fingerprint replays saved result",
	replay ~= nil and replayCode == "DUPLICATE" and replay.instanceId == "building-1")

local inProgress, inProgressCode = Journal.find(
	ledger, "request-1", "place|pet_house|2|3|0", now, 0
)
expect("receipt is not replayed before its revision is persisted",
	inProgress == nil and inProgressCode == "IN_PROGRESS")

local conflict, conflictCode = Journal.find(ledger, "request-1", "place|stone_path|2|3|0", now, 1)
expect("request ID cannot be reused for another payload",
	conflict == nil and conflictCode == "REQUEST_ID_CONFLICT")

local expired, expiredCode = Journal.find(
	ledger, "request-1", "place|pet_house|2|3|0", now + 7 * 24 * 60 * 60 + 1, 1
)
expect("expired receipt is never replayed as a new successful operation",
	expired == nil and expiredCode == "EXPIRED")

local invalidLedgerOk = Journal.validateLedger({
	{ requestId = "duplicate", fingerprint = "a", action = "place", createdAt = now, revision = 1, result = result },
	{ requestId = "duplicate", fingerprint = "b", action = "move", createdAt = now, revision = 2, result = result },
})
expect("duplicate receipt IDs are rejected in saved profile", not invalidLedgerOk)

local fullLedger = {}
for index = 1, 512 do
	local nextLedger = Journal.append(
		fullLedger,
		"request-" .. tostring(index),
		"fingerprint-" .. tostring(index),
		"place",
		result,
		now,
		index
	)
	assert(nextLedger ~= nil, "ledger fill setup failed at " .. tostring(index))
	fullLedger = nextLedger
end
local overflowLedger, overflowCode = Journal.append(
	fullLedger, "request-overflow", "overflow", "place", result, now, 513
)
expect("full receipt ledger fails closed without evicting retry evidence",
	overflowLedger == nil and overflowCode == "LEDGER_FULL"
		and #fullLedger == 512
		and Journal.find(fullLedger, "request-1", "fingerprint-1", now, 512) ~= nil)

print("[PetKingdoms Test] IslandBuildingJournalData tests completed.")
