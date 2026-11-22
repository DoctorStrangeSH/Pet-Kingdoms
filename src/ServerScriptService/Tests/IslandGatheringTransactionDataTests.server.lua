--!strict
-- Studio-only pure integration tests for resource wallet + cooldown + quest progress.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local TransactionData = require(services:WaitForChild("IslandGatheringTransactionData"))
local IslandResources = require(services:WaitForChild("IslandResources"))
local QuestProgressData = require(services:WaitForChild("QuestProgressData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local now = 1_800_000_000
local profile = {
	resources = IslandResources.create(),
	resourceNodes = {},
	questProgress = QuestProgressData.create(),
}

local first, firstCode, firstAvailableAt = TransactionData.apply(profile, "WoodNode_A", now)
expect("wood gathering composes wallet, node cooldown, and quest progress",
	first ~= nil and firstCode == "GATHER_READY" and firstAvailableAt == now + 60
		and first.resources.wood == 5
		and #first.resourceNodes == 1
		and first.resourceNodes[1].nodeId == "WoodNode_A"
		and first.questProgress.gather_wood.count == 1
		and first.questProgress.gather_stone.count == 0)
expect("gather transaction does not mutate the source profile",
	profile.resources.wood == 2 and #profile.resourceNodes == 0
		and profile.questProgress.gather_wood.count == 0)

local blocked, blockedCode, blockedAt = TransactionData.apply({
	resources = first.resources,
	resourceNodes = first.resourceNodes,
	questProgress = first.questProgress,
}, "WoodNode_A", now + 30)
expect("cooldown rejection changes none of the composed state",
	blocked == nil and blockedCode == "NODE_COOLDOWN" and blockedAt == now + 60)

local second, secondCode = TransactionData.apply({
	resources = first.resources,
	resourceNodes = first.resourceNodes,
	questProgress = first.questProgress,
}, "WoodNode_B", now + 30)
expect("different wood node advances the same quest exactly once",
	second ~= nil and secondCode == "GATHER_READY"
		and second.resources.wood == 8
		and second.questProgress.gather_wood.count == 2)

local third, thirdCode = TransactionData.apply({
	resources = second.resources,
	resourceNodes = second.resourceNodes,
	questProgress = second.questProgress,
}, "WoodNode_A", now + 60)
expect("third committed wood gather completes introductory wood quest",
	third ~= nil and thirdCode == "GATHER_READY"
		and third.questProgress.gather_wood.count == 3
		and #third.completedQuestIds == 1
		and third.completedQuestIds[1] == "gather_wood")

local stone, stoneCode = TransactionData.apply({
	resources = third.resources,
	resourceNodes = third.resourceNodes,
	questProgress = third.questProgress,
}, "StoneNode_A", now + 60)
expect("stone gathering advances only the stone quest",
	stone ~= nil and stoneCode == "GATHER_READY"
		and stone.resources.stone == 3
		and stone.questProgress.gather_stone.count == 1
		and stone.questProgress.gather_wood.count == 3)

local capProfile = {
	resources = { wood = 2_000_000_000, stone = 1, gold = 0, gems = 0 },
	resourceNodes = {},
	questProgress = QuestProgressData.create(),
}
local capResult, capCode = TransactionData.apply(capProfile, "WoodNode_A", now)
expect("wallet cap rejects gathering before cooldown or quest mutation",
	capResult == nil and capCode == "RESOURCE_CAP_REACHED"
		and #capProfile.resourceNodes == 0
		and capProfile.questProgress.gather_wood.count == 0)

local invalidQuestProfile = {
	resources = IslandResources.create(),
	resourceNodes = {},
	questProgress = { gather_wood = { count = 999 }, gather_stone = { count = 0 } },
}
local invalidQuestResult = TransactionData.apply(invalidQuestProfile, "WoodNode_A", now)
expect("invalid quest state rejects the whole gather transaction",
	invalidQuestResult == nil
		and invalidQuestProfile.resources.wood == 2
		and #invalidQuestProfile.resourceNodes == 0)

local unknownResult, unknownCode = TransactionData.apply(profile, "GoldNode_A", now)
expect("unknown resource node rejects the whole transaction",
	unknownResult == nil and unknownCode == "UNKNOWN_NODE"
		and profile.resources.wood == 2
		and profile.questProgress.gather_wood.count == 0)

print("[PetKingdoms Test] IslandGatheringTransactionData tests completed.")
