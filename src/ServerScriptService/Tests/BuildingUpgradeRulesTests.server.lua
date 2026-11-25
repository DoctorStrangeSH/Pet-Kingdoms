--!strict
-- Studio-only tests for upgrade eligibility, pricing, and atomic wallet spending.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local Rules = require(services:WaitForChild("BuildingUpgradeRules"))
local Catalog = require(services:WaitForChild("BuildingCatalog"))
local Resources = require(services:WaitForChild("IslandResources"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local petHouse = { instanceId = "pet-house-test", catalogId = "pet_house" }
local enough = { wood = 10, stone = 5, gold = 0, gems = 0 }
local plan, code = Rules.plan(Catalog.pet_house, petHouse, enough)
expect("level-1 pet house can plan level-2 upgrade", plan ~= nil and code == "UPGRADE_AVAILABLE")
expect("level-2 plan has correct target level", plan ~= nil and plan.targetLevel == 2)
expect("level-2 plan uses server catalog cost", plan ~= nil
	and plan.cost.wood == 10 and plan.cost.stone == 5)

local lowWood = { wood = 9, stone = 100, gold = 0, gems = 0 }
local noWoodPlan, noWoodCode = Rules.plan(Catalog.pet_house, petHouse, lowWood)
expect("insufficient wood blocks upgrade", noWoodPlan == nil and noWoodCode == "NOT_ENOUGH_WOOD")

local lowStone = { wood = 100, stone = 4, gold = 0, gems = 0 }
local noStonePlan, noStoneCode = Rules.plan(Catalog.pet_house, petHouse, lowStone)
expect("insufficient stone blocks upgrade", noStonePlan == nil and noStoneCode == "NOT_ENOUGH_STONE")

local levelTwo = { instanceId = "pet-house-test", catalogId = "pet_house", upgradeLevel = 2 }
local levelThreePlan, levelThreeCode = Rules.plan(Catalog.pet_house, levelTwo, { wood = 20, stone = 12 })
expect("level-2 pet house can plan level-3 upgrade",
	levelThreePlan ~= nil and levelThreeCode == "UPGRADE_AVAILABLE" and levelThreePlan.targetLevel == 3)

local maxed = { instanceId = "pet-house-test", catalogId = "pet_house", upgradeLevel = 3 }
local maxPlan, maxCode = Rules.plan(Catalog.pet_house, maxed, enough)
expect("maximum level rejects another upgrade", maxPlan == nil and maxCode == "MAX_UPGRADE_LEVEL")

local unsupportedPlan, unsupportedCode = Rules.plan(Catalog.wooden_fence, petHouse, enough)
expect("building without configured upgrade rejects upgrade", unsupportedPlan == nil and unsupportedCode == "UPGRADE_NOT_AVAILABLE")

local missingWalletPlan, missingWalletCode = Rules.plan(Catalog.pet_house, petHouse, nil)
expect("missing wallet reports resources not ready", missingWalletPlan == nil and missingWalletCode == "RESOURCES_NOT_READY")

local invalidDefinition = {
	maxUpgradeLevel = 2,
	upgradeCosts = { [2] = { wood = -1 } },
}
local invalidPlan, invalidCode = Rules.plan(invalidDefinition, petHouse, enough)
expect("invalid negative catalog cost fails closed", invalidPlan == nil and invalidCode == "INVALID_UPGRADE_COST")

local wallet = { wood = 10, stone = 4, gold = 0, gems = 0 }
local before = table.clone(wallet)
local spent, spendCode = Resources.spend(wallet, { wood = 10, stone = 5 })
expect("multi-resource upgrade spend fails when one balance is short",
	not spent and spendCode == "INSUFFICIENT_RESOURCES")
expect("failed multi-resource spend leaves every balance unchanged",
	wallet.wood == before.wood and wallet.stone == before.stone)

local exactWallet = { wood = 10, stone = 5, gold = 0, gems = 0 }
local exactSpent, exactCode = Resources.spend(exactWallet, plan and plan.cost or {})
expect("exact upgrade cost is charged successfully", exactSpent and exactCode == "SPENT")
expect("successful upgrade charge deducts both resources",
	exactWallet.wood == 0 and exactWallet.stone == 0)

print("[PetKingdoms Test] BuildingUpgradeRules tests completed.")
