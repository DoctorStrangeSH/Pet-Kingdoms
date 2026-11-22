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

local afterWood, completedWood, woodCode = QuestProgressData.recordGather(state, "wood")
expect("wood gather increments only wood quest", afterWood ~= nil and woodCode == "RECORDED"
	and afterWood.gather_wood.count == 1 and afterWood.gather_stone.count == 0)
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
