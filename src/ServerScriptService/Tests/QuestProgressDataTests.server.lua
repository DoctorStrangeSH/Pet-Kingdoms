--!strict
-- Studio-only pure contract tests for introductory quest progress.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local QuestProgressData = require(services:WaitForChild("QuestProgressData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local state = QuestProgressData.create()
local valid, code = QuestProgressData.validate(state)
expect("new quest progress validates", valid and code == "VALID")

local legacySnapshot = QuestProgressData.snapshot(nil)
expect("legacy profile without quest progress receives default quest snapshot",
	#legacySnapshot == 2 and legacySnapshot[1].count == 0 and legacySnapshot[2].count == 0)
local invalidSnapshot = QuestProgressData.snapshot({ unknown_quest = { count = 1 } })
expect("malformed quest progress never leaks into client snapshot", #invalidSnapshot == 0)

local orderedSnapshot = QuestProgressData.snapshot(state)
local repeatedSnapshot = QuestProgressData.snapshot(state)
expect("quest journal order is stable and starts with wood then stone",
	orderedSnapshot[1].id == "gather_wood"
		and orderedSnapshot[2].id == "gather_stone"
		and repeatedSnapshot[1].id == orderedSnapshot[1].id
		and repeatedSnapshot[2].id == orderedSnapshot[2].id)

local afterWood, completedWood, woodCode = QuestProgressData.recordGather(state, "wood")
expect("wood gather increments only wood quest", afterWood ~= nil and woodCode == "RECORDED"
	and afterWood.gather_wood.count == 1 and afterWood.gather_stone.count == 0)

expect("gather progression uses immutable snapshots",
	state.gather_wood.count == 0 and state.gather_stone.count == 0)
local afterUnknown, completedUnknown, unknownCode = QuestProgressData.recordGather(state, "crystal")
expect("unknown resource does not advance any quest",
	afterUnknown ~= nil and unknownCode == "RECORDED"
		and #completedUnknown == 0
		and afterUnknown.gather_wood.count == 0
		and afterUnknown.gather_stone.count == 0)
local nanState = { gather_wood = { count = 0 / 0 }, gather_stone = { count = 0 } }
local nanValid = QuestProgressData.validate(nanState)
expect("NaN quest progress is rejected", not nanValid)
local infiniteState = { gather_wood = { count = math.huge }, gather_stone = { count = 0 } }
local infiniteValid = QuestProgressData.validate(infiniteState)
expect("infinite quest progress is rejected", not infiniteValid)
expect("incomplete wood quest does not report completion", completedWood ~= nil and #completedWood == 0)

local afterThree = afterWood
for _ = 1, 2 do
	local nextState = QuestProgressData.recordGather(afterThree, "wood")
	afterThree = nextState
end
local snapshot = QuestProgressData.snapshot(afterThree)
local woodSnapshot = nil
for _, quest in ipairs(snapshot) do
	if quest.id == "gather_wood" then woodSnapshot = quest end
end
expect("wood quest completes at target", woodSnapshot ~= nil and woodSnapshot.count == 3 and woodSnapshot.completed)

local claimedSnapshot = nil
for _, quest in ipairs(QuestProgressData.snapshot(afterThree, {
	gather_wood = { rewardId = "quest:gather_wood:reward:v1", claimedAt = 100 },
})) do
	if quest.id == "gather_wood" then claimedSnapshot = quest end
end
expect("completed quest exposes its durable reward claim separately",
	claimedSnapshot ~= nil and claimedSnapshot.completed == true
		and claimedSnapshot.rewardClaimed == true and claimedSnapshot.rewardAvailable == false)
local unclaimedSnapshot = nil
for _, quest in ipairs(QuestProgressData.snapshot(afterThree, {})) do
	if quest.id == "gather_wood" then unclaimedSnapshot = quest end
end
expect("completed quest without a receipt remains unclaimed",
	unclaimedSnapshot ~= nil and unclaimedSnapshot.completed == true
		and unclaimedSnapshot.rewardClaimed == false)
local malformedClaimSnapshot = nil
for _, quest in ipairs(QuestProgressData.snapshot(afterThree, {
	gather_wood = { rewardId = "", claimedAt = 100 },
})) do
	if quest.id == "gather_wood" then malformedClaimSnapshot = quest end
end
expect("malformed claim receipt is never exposed as claimed",
	malformedClaimSnapshot ~= nil and malformedClaimSnapshot.rewardClaimed == false)
local prematureClaimSnapshot = nil
for _, quest in ipairs(QuestProgressData.snapshot(state, {
	gather_wood = { rewardId = "quest:gather_wood:premature:v1", claimedAt = 100 },
})) do
	if quest.id == "gather_wood" then prematureClaimSnapshot = quest end
end
expect("claim receipt cannot mark an incomplete quest as claimed",
	prematureClaimSnapshot ~= nil and prematureClaimSnapshot.completed == false
		and prematureClaimSnapshot.rewardClaimed == false)
expect("completed quest does not exceed target", afterThree.gather_wood.count == 3)

local afterStone, completedStone = QuestProgressData.recordGather(state, "stone")
expect("stone gather increments only stone quest", afterStone ~= nil
	and afterStone.gather_stone.count == 1 and afterStone.gather_wood.count == 0)
local afterTwoStone = QuestProgressData.recordGather(afterStone, "stone")
local stoneSnapshot = nil
for _, quest in ipairs(QuestProgressData.snapshot(afterTwoStone)) do
	if quest.id == "gather_stone" then stoneSnapshot = quest end
end
expect("stone quest completes at target", stoneSnapshot ~= nil and stoneSnapshot.count == 2 and stoneSnapshot.completed)

local repeated = QuestProgressData.recordGather(afterThree, "wood")
expect("completed quest progress is capped on later gathers", repeated ~= nil and repeated.gather_wood.count == 3)

local invalid = { gather_wood = { count = 4 }, gather_stone = { count = 0 } }
local invalidOk, invalidCode = QuestProgressData.validate(invalid)
expect("progress above target is rejected", not invalidOk and invalidCode == "INVALID_QUEST_ENTRY")
local missing = { gather_wood = { count = 0 } }
local missingOk, missingCode = QuestProgressData.validate(missing)
expect("missing quest record is rejected", not missingOk and missingCode == "MISSING_QUEST_ENTRY")
local unknown = { gather_wood = { count = 0 }, gather_stone = { count = 0 }, fake = { count = 1 } }
local unknownOk = QuestProgressData.validate(unknown)
expect("unknown quest IDs are rejected", not unknownOk)

print("[PetKingdoms Test] QuestProgressData tests completed.")
