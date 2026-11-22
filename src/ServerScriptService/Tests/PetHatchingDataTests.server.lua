--!strict
-- Studio-only pure tests for the pet hatching transaction state contract.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local PetHatchingData = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetHatchingData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local costs = { gold = 100, gems = 2 }
local record, createStatus = PetHatchingData.create(
	"hatch_tx_001",
	"starter_egg",
	"bunny",
	1,
	costs,
	1_800_000_000
)
expect("valid hatch transaction is prepared", record ~= nil and createStatus == "CREATED")
assert(record ~= nil)
expect("acquisition ID is stable and derived from transaction ID", record.acquisitionId == "hatch:hatch_tx_001")
expect("costs are copied on transaction creation", record.costs ~= costs and record.costs.gold == 100)
costs.gold = 1
expect("source cost mutation cannot alter transaction", record.costs.gold == 100)

local charged, chargedStatus = PetHatchingData.advance(record, "CHARGED")
expect("prepared transaction can advance to charged", charged ~= nil and chargedStatus == "UPDATED")
assert(charged ~= nil)
local granted, grantedStatus = PetHatchingData.advance(charged, "GRANTED")
expect("charged transaction can advance to granted", granted ~= nil and grantedStatus == "UPDATED")
assert(granted ~= nil)
expect("granted transaction validates", PetHatchingData.validate(granted))

local repeated, repeatedStatus = PetHatchingData.advance(charged, "CHARGED")
expect("repeating current state is idempotent", repeated ~= nil and repeatedStatus == "ALREADY_ADVANCED")

local skippedCharge = PetHatchingData.advance(record, "GRANTED")
expect("prepared transaction cannot skip charge", skippedCharge == nil)
local backwards = PetHatchingData.advance(granted, "CHARGED")
expect("granted transaction cannot move backwards", backwards == nil)

local cloned = PetHatchingData.clone(granted)
assert(cloned ~= nil)
cloned.costs.gold = 999
expect("transaction clone is isolated", granted.costs.gold == 100)

local unknownResource = PetHatchingData.create("hatch_tx_002", "starter_egg", "bunny", 1, { tokens = 1 }, 1)
expect("unknown currency is rejected", unknownResource == nil)

local emptyCosts = PetHatchingData.create("hatch_tx_003", "starter_egg", "bunny", 1, {}, 1)
expect("empty costs are rejected", emptyCosts == nil)

local invalidRarity = PetHatchingData.create("hatch_tx_004", "starter_egg", "bunny", 7, { gold = 1 }, 1)
expect("rarity outside approved tier range is rejected", invalidRarity == nil)

local invalidToken = PetHatchingData.create("hatch tx 005", "starter_egg", "bunny", 1, { gold = 1 }, 1)
expect("malformed transaction ID is rejected", invalidToken == nil)

local overflow = PetHatchingData.create(
	"hatch_tx_006",
	"starter_egg",
	"bunny",
	1,
	{ gold = PetHatchingData.MAX_COST_PER_RESOURCE, gems = 1 },
	1
)
expect("combined cost overflow is rejected", overflow == nil)

local unknownState = table.clone(granted)
unknownState.state = "REFUNDED"
expect("unsupported transaction state is rejected", not PetHatchingData.validate(unknownState))

print("[PetKingdoms Test] PetHatchingData tests completed.")
