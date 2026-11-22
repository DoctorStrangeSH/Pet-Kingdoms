--!strict
-- Studio-only serialization/reload contract for the gathering -> quest transaction.
-- This validates the persisted profile shape; it does not call live DataStores.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local HttpService = game:GetService("HttpService")
local services = script.Parent.Parent:WaitForChild("Services")
local BuildingCatalog = require(services:WaitForChild("BuildingCatalog"))
local IslandData = require(services:WaitForChild("IslandData"))
local TransactionData = require(services:WaitForChild("IslandGatheringTransactionData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local now = 1_800_000_000
local profile = IslandData.create(1001, 24, 24)
assert(profile ~= nil, "test profile creation failed")

local function commitGather(nodeId: string, timestamp: number): (boolean, string)
	local result, code, availableAt = TransactionData.apply(profile, nodeId, timestamp)
	if result == nil then return false, code end
	profile.resources = result.resources
	profile.resourceNodes = result.resourceNodes
	profile.questProgress = result.questProgress
	profile.revision += 1
	return true, tostring(availableAt)
end

local firstOk = commitGather("WoodNode_A", now)
expect("first wood gather commits a profile revision",
	firstOk and profile.revision == 1 and profile.resources.wood == 5
		and profile.questProgress.gather_wood.count == 1)

local encoded = HttpService:JSONEncode(profile)
local restored = HttpService:JSONDecode(encoded)
local restoredValid, restoredCode = IslandData.validate(restored, 1001, BuildingCatalog)
expect("gathered profile survives DataStore-shaped JSON round trip",
	restoredValid and restoredCode == "VALID")
expect("resources, cooldown, quest progress, and revision survive reload",
	restored.resources.wood == 5
		and #restored.resourceNodes == 1
		and restored.resourceNodes[1].nodeId == "WoodNode_A"
		and restored.resourceNodes[1].availableAt == now + 60
		and restored.questProgress.gather_wood.count == 1
		and restored.revision == 1)

local blocked, blockedCode = TransactionData.apply(restored, "WoodNode_A", now + 30)
expect("reloaded node cooldown prevents duplicate resource and quest progress",
	blocked == nil and blockedCode == "NODE_COOLDOWN"
		and restored.resources.wood == 5
		and restored.questProgress.gather_wood.count == 1)

profile = restored
local secondOk = commitGather("WoodNode_B", now + 30)
expect("second distinct wood node advances reloaded quest exactly once",
	secondOk and profile.revision == 2 and profile.resources.wood == 8
		and profile.questProgress.gather_wood.count == 2)

local reloadedAgain = HttpService:JSONDecode(HttpService:JSONEncode(profile))
local secondValid = IslandData.validate(reloadedAgain, 1001, BuildingCatalog)
expect("second gathered revision remains valid after another reload",
	secondValid and reloadedAgain.revision == 2
		and reloadedAgain.resources.wood == 8
		and reloadedAgain.questProgress.gather_wood.count == 2)

print("[PetKingdoms Test] IslandGatheringPersistenceContract tests completed.")
