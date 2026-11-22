--!strict
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local Ledger = require(services:WaitForChild("IslandHatchLedgerData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local baseProfile = {
	schemaVersion = 1,
	ownerUserId = 123,
	boundsWidth = 10,
	boundsDepth = 10,
	buildings = {},
	unlockedBuildingIds = {},
	resources = { wood = 5, stone = 2, gold = 100, gems = 3 },
	revision = 0,
}
local record = {
	transactionId = "hatch_001",
	eggId = "starter_egg",
	speciesId = "bunny",
	rarityTier = 1,
	costs = { gold = 25, gems = 1 },
	createdAt = 1_800_000_000,
	state = "PREPARED",
	acquisitionId = "hatch:hatch_001",
}

local prepared, prepareStatus = Ledger.prepare(baseProfile, record, record.createdAt)
expect("valid transaction is added to profile journal", prepared ~= nil and prepareStatus == "PREPARED")
assert(prepared ~= nil)
expect("preparing does not debit wallet", prepared.resources.gold == 100 and prepared.resources.gems == 3)
expect("prepare snapshots transaction costs", prepared.hatchTransactions[1].costs.gold == 25)

local preparedAgain, repeatPrepareStatus = Ledger.prepare(prepared, record, record.createdAt + 1)
expect("same prepare request is idempotent", preparedAgain ~= nil and repeatPrepareStatus == "ALREADY_PREPARED")

local conflictingRecord = table.clone(record)
conflictingRecord.costs = { gold = 26, gems = 1 }
local conflict, conflictStatus = Ledger.prepare(prepared, conflictingRecord, record.createdAt + 1)
expect("reused transaction ID with different costs is rejected", conflict == nil and conflictStatus == "TRANSACTION_ID_CONFLICT")

local charged, chargeStatus = Ledger.charge(prepared, record.transactionId)
expect("charge debits all resources and marks charged", charged ~= nil and chargeStatus == "CHARGED")
assert(charged ~= nil)
expect("charge updates wallet atomically", charged.resources.gold == 75 and charged.resources.gems == 2)
local chargedAgain, chargeAgainStatus = Ledger.charge(charged, record.transactionId)
expect("repeated charge cannot debit twice", chargedAgain ~= nil and chargeAgainStatus == "ALREADY_CHARGED")
assert(chargedAgain ~= nil)
expect("repeated charge preserves balances", chargedAgain.resources.gold == 75 and chargedAgain.resources.gems == 2)

local granted, grantStatus = Ledger.markGranted(charged, record.transactionId)
expect("charged transaction can be marked granted", granted ~= nil and grantStatus == "GRANTED")
assert(granted ~= nil)
local grantedAgain, grantedAgainStatus = Ledger.markGranted(granted, record.transactionId)
expect("grant acknowledgement is idempotent", grantedAgain ~= nil and grantedAgainStatus == "ALREADY_GRANTED")

local insufficientProfile = table.clone(baseProfile)
insufficientProfile.resources = { wood = 0, stone = 0, gold = 1, gems = 0 }
local insufficientPrepared = Ledger.prepare(insufficientProfile, record, record.createdAt)
assert(insufficientPrepared ~= nil)
local insufficientCharge, insufficientChargeStatus = Ledger.charge(insufficientPrepared, record.transactionId)
expect("insufficient funds leave profile unchanged", insufficientCharge == nil and insufficientChargeStatus == "INSUFFICIENT_RESOURCES")
expect("failed charge does not mutate original wallet", insufficientPrepared.resources.gold == 1)

local malformedLedger = { record, record }
expect("duplicate transaction IDs invalidate journal", not Ledger.validateLedger(malformedLedger))

local badState = table.clone(record)
badState.state = "REFUNDED"
expect("unsupported transaction state rejected", not Ledger.validateRecord(badState))

print("[PetKingdoms Test] IslandHatchLedgerData tests completed.")
