--!strict
-- Studio-only pure tests for the server resource wallet.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local IslandResources = require(services:WaitForChild("IslandResources"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local wallet = IslandResources.create()
expect("starter wallet matches provisional project baseline", wallet.wood == 2 and wallet.stone == 1 and wallet.gold == 0 and wallet.gems == 0)
local valid, validCode = IslandResources.validate(wallet)
expect("starter wallet validates", valid and validCode == "VALID")

local granted, grantCode, newWood = IslandResources.grant(wallet, "wood", 3)
expect("server grant adds resources", granted and grantCode == "GRANTED" and newWood == 5)

local spent, spendCode = IslandResources.spend(wallet, { wood = 2, stone = 1 })
expect("multi-resource spend succeeds atomically", spent and spendCode == "SPENT" and wallet.wood == 3 and wallet.stone == 0)

local grantManyBefore = table.clone(wallet)
local grantManyOk, grantManyCode, grantManyBalances =
	IslandResources.grantMany(wallet, { wood = 2, stone = 3, gold = 1 })
expect("multi-resource grant succeeds atomically",
	grantManyOk and grantManyCode == "GRANTED" and grantManyBalances ~= nil
		and wallet.wood == grantManyBefore.wood + 2
		and wallet.stone == grantManyBefore.stone + 3
		and wallet.gold == grantManyBefore.gold + 1)

local beforeInvalidGrant = table.clone(wallet)
local invalidMultiGrant, invalidMultiGrantCode = IslandResources.grantMany(
	wallet, { wood = 1, dragon_scale = 1 }
)
expect("invalid multi-resource grant changes no balances",
	not invalidMultiGrant and invalidMultiGrantCode == "UNKNOWN_RESOURCE"
		and wallet.wood == beforeInvalidGrant.wood
		and wallet.stone == beforeInvalidGrant.stone
		and wallet.gold == beforeInvalidGrant.gold
		and wallet.gems == beforeInvalidGrant.gems)

local emptyMultiGrant, emptyMultiGrantCode = IslandResources.grantMany(wallet, {})
expect("empty multi-resource grant is rejected",
	not emptyMultiGrant and emptyMultiGrantCode == "EMPTY_REWARDS")

local cappedMultiGrantWallet = {
	wood = 2_000_000_000, stone = 0, gold = 0, gems = 0,
}
local cappedMultiGrant, cappedMultiGrantCode = IslandResources.grantMany(
	cappedMultiGrantWallet, { wood = 1, stone = 1 }
)
expect("multi-resource grant cap failure is atomic",
	not cappedMultiGrant and cappedMultiGrantCode == "RESOURCE_CAP_REACHED"
		and cappedMultiGrantWallet.stone == 0)

local beforeWood = wallet.wood
local insufficient, insufficientCode = IslandResources.spend(wallet, { wood = 2, stone = 1 })
expect("insufficient multi-resource spend changes nothing", not insufficient and insufficientCode == "INSUFFICIENT_RESOURCES" and wallet.wood == beforeWood and wallet.stone == 0)

local beforeEmptySpend = table.clone(wallet)
local emptySpend, emptySpendCode = IslandResources.spend(wallet, {})
expect("empty spend transaction is rejected", not emptySpend and emptySpendCode == "EMPTY_COSTS"
	and wallet.wood == beforeEmptySpend.wood and wallet.stone == beforeEmptySpend.stone
	and wallet.gold == beforeEmptySpend.gold and wallet.gems == beforeEmptySpend.gems)

local unknown, unknownCode = IslandResources.grant(wallet, "dragon_scale", 1)
expect("unknown resource rejected", not unknown and unknownCode == "UNKNOWN_RESOURCE")

local fractional, fractionalCode = IslandResources.grant(wallet, "wood", 1.5)
expect("fractional grant rejected", not fractional and fractionalCode == "INVALID_AMOUNT")

local malformed = { wood = -1, stone = 0 }
local malformedOk = IslandResources.validate(malformed)
expect("negative balance rejected", not malformedOk)

local overCap = { wood = 2_000_000_000, stone = 0, gold = 0, gems = 0 }
local overflow, overflowCode = IslandResources.grant(overCap, "wood", 1)
expect("balance overflow rejected", not overflow and overflowCode == "RESOURCE_CAP_REACHED")

print("[PetKingdoms Test] IslandResources smoke tests completed.")
