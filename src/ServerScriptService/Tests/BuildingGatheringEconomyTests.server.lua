--!strict
-- Studio-only cross-system contract tests for the starter gathering/building loop.
-- These tests use cloned wallets and never mutate a live player profile.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local BuildingCatalog = require(services:WaitForChild("BuildingCatalog"))
local NodeCatalog = require(services:WaitForChild("IslandResourceNodeCatalog"))
local IslandResources = require(services:WaitForChild("IslandResources"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local starterWallet = IslandResources.create()
local petHouseCost = BuildingCatalog.pet_house.cost
assert(petHouseCost ~= nil, "pet house must define a server-side cost")

local canBuildPetHouseImmediately = IslandResources.spend(table.clone(starterWallet), petHouseCost)
expect("starter wallet requires gathering before building a pet house", not canBuildPetHouseImmediately)

local woodNode = NodeCatalog.get("WoodNode_A")
local stoneNode = NodeCatalog.get("StoneNode_A")
assert(woodNode ~= nil and stoneNode ~= nil, "starter island must expose canonical wood and stone nodes")

local gatheredWallet = table.clone(starterWallet)
local woodGranted, woodCode = IslandResources.grant(gatheredWallet, woodNode.resourceId, woodNode.reward)
expect("one wood node adds enough wood for the pet house", woodGranted and woodCode == "GRANTED"
	and gatheredWallet.wood == 5)

local stoneGranted, stoneCode = IslandResources.grant(gatheredWallet, stoneNode.resourceId, stoneNode.reward)
expect("one stone node adds enough stone for the pet house", stoneGranted and stoneCode == "GRANTED"
	and gatheredWallet.stone == 3)

local petHouseWallet = table.clone(gatheredWallet)
local petHouseBuilt, petHouseCode = IslandResources.spend(petHouseWallet, petHouseCost)
expect("starter player can afford the pet house after one wood and one stone gather",
	petHouseBuilt and petHouseCode == "SPENT"
		and petHouseWallet.wood == 0 and petHouseWallet.stone == 1)

local checkedCatalogEntries = 0
for buildingId, definition in pairs(BuildingCatalog) do
	checkedCatalogEntries += 1
	if definition.cost ~= nil then
		local wallet = table.clone(gatheredWallet)
		local affordable, code = IslandResources.spend(wallet, definition.cost)
		expect(buildingId .. " is affordable after the starter gathering loop",
			affordable and code == "SPENT")
	else
		expect(buildingId .. " is a free starter building", buildingId == "main_house")
	end
end
expect("starter building catalog contains six entries", checkedCatalogEntries == 6)

local failedWallet = table.clone(starterWallet)
local beforeFailedSpend = table.clone(failedWallet)
local failed, failedCode = IslandResources.spend(failedWallet, petHouseCost)
expect("failed pet house purchase does not partially deduct resources",
	not failed and failedCode == "INSUFFICIENT_RESOURCES"
		and failedWallet.wood == beforeFailedSpend.wood
		and failedWallet.stone == beforeFailedSpend.stone)

print("[PetKingdoms Test] Building/gathering economy integration tests completed.")
