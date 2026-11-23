--!strict
-- Pure virtualization budget tests. Run in a dedicated Studio test place.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("RunPetKingdomsStudioTests") ~= true then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualList = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VirtualList"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local cardStep = 77
local cardGap = 9
local viewportHeight = 420
local overscan = 2
local maxExpectedCards = math.ceil(viewportHeight / cardStep) + overscan * 2

for _, total in ipairs({ 100, 250, 500 }) do
	local contentHeight = VirtualList.GetContentHeight(total, cardStep, cardGap)
	expect("content height is correct for " .. tostring(total), contentHeight == total * cardStep - cardGap)

	local top = VirtualList.GetWindow(total, 0, viewportHeight, cardStep, overscan)
	expect("top window starts at first item for " .. tostring(total), top.firstIndex == 1)
	expect("top window stays within render budget for " .. tostring(total), top.count <= maxExpectedCards)

	local middleY = math.floor(contentHeight / 2)
	local middle = VirtualList.GetWindow(total, middleY, viewportHeight, cardStep, overscan)
	expect("middle window stays in bounds for " .. tostring(total), middle.firstIndex >= 1 and middle.lastIndex <= total)
	expect("middle window stays within render budget for " .. tostring(total), middle.count <= maxExpectedCards)

	local bottomY = math.max(0, contentHeight - viewportHeight)
	local bottom = VirtualList.GetWindow(total, bottomY, viewportHeight, cardStep, overscan)
	expect("bottom window reaches final item for " .. tostring(total), bottom.lastIndex == total)
	expect("bottom window stays within render budget for " .. tostring(total), bottom.count <= maxExpectedCards)
end

local empty = VirtualList.GetWindow(0, 0, viewportHeight, cardStep, overscan)
expect("empty list has an empty window", empty.count == 0 and empty.firstIndex == 0 and empty.lastIndex == 0)
expect("empty list has zero content height", VirtualList.GetContentHeight(0, cardStep, cardGap) == 0)

local negativeScroll = VirtualList.GetWindow(100, -500, viewportHeight, cardStep, overscan)
expect("negative canvas position is clamped", negativeScroll.firstIndex == 1)

print("[PetKingdoms Test] PetCollection virtualization tests completed.")
