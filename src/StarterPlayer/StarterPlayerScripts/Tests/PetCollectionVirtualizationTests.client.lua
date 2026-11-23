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

for _, total in ipairs({ 100, 250, 500, 1000 }) do
	local contentHeight = VirtualList.GetContentHeight(total, cardStep, cardGap)
	expect("content height is correct for " .. tostring(total), contentHeight == total * cardStep - cardGap)

	local top = VirtualList.GetWindow(total, 0, viewportHeight, cardStep, overscan)
	expect("top window starts at first item for " .. tostring(total), top.firstIndex == 1)
	expect("top window stays within render budget for " .. tostring(total), top.count <= maxExpectedCards)

	local middleY = math.floor(contentHeight / 2)
	local middle = VirtualList.GetWindow(total, middleY, viewportHeight, cardStep, overscan)
	expect("middle window stays in bounds for " .. tostring(total), middle.firstIndex >= 1 and middle.lastIndex <= total)
	expect("middle window stays within render budget for " .. tostring(total), middle.count <= maxExpectedCards)

	local adjacent = VirtualList.GetWindow(total, cardStep, viewportHeight, cardStep, overscan)
	local overlapStart = math.max(top.firstIndex, adjacent.firstIndex)
	local overlapEnd = math.min(top.lastIndex, adjacent.lastIndex)
	local overlapCount = math.max(0, overlapEnd - overlapStart + 1)
	expect("adjacent scroll windows retain overlapping cards for " .. tostring(total), overlapCount > 0)

	local bottomY = math.max(0, contentHeight - viewportHeight)
	local bottom = VirtualList.GetWindow(total, bottomY, viewportHeight, cardStep, overscan)
	expect("bottom window reaches final item for " .. tostring(total), bottom.lastIndex == total)
	expect("bottom window stays within render budget for " .. tostring(total), bottom.count <= maxExpectedCards)

	-- Sweep the full scroll range at deterministic intervals. Every item that
	-- intersects the viewport must be inside the returned virtual window.
	local scrollY = 0
	local scrollLimit = math.max(0, contentHeight - viewportHeight)
	while scrollY <= scrollLimit do
		local window = VirtualList.GetWindow(total, scrollY, viewportHeight, cardStep, overscan)
		local firstVisible = math.floor(scrollY / cardStep) + 1
		local lastVisible = math.min(total, math.ceil((scrollY + viewportHeight) / cardStep))
		expect(
			"scroll sweep covers visible items (" .. tostring(total) .. ", y=" .. tostring(scrollY) .. ")",
			window.firstIndex <= firstVisible and window.lastIndex >= lastVisible
		)
		expect(
			"scroll sweep respects render budget (" .. tostring(total) .. ", y=" .. tostring(scrollY) .. ")",
			window.count <= maxExpectedCards
		)
		scrollY += math.max(1, math.floor(viewportHeight / 3))
	end
end

local empty = VirtualList.GetWindow(0, 0, viewportHeight, cardStep, overscan)
expect("empty list has an empty window", empty.count == 0 and empty.firstIndex == 0 and empty.lastIndex == 0)
expect("empty list has zero content height", VirtualList.GetContentHeight(0, cardStep, cardGap) == 0)

expect("filter/sort keeps a valid scroll position", VirtualList.ClampCanvasY(180, 1200, 420) == 180)
expect("shorter filtered results clamp scroll to their end", VirtualList.ClampCanvasY(900, 600, 420) == 180)
expect("empty filtered results reset scroll to zero", VirtualList.ClampCanvasY(900, 0, 420) == 0)
expect("negative saved scroll is clamped", VirtualList.ClampCanvasY(-40, 1200, 420) == 0)
expect("content shorter than viewport clamps scroll to zero", VirtualList.ClampCanvasY(250, 200, 420) == 0)
expect("zero viewport height remains safe", VirtualList.GetWindow(100, 0, 0, cardStep, overscan).count > 0)

local negativeScroll = VirtualList.GetWindow(100, -500, viewportHeight, cardStep, overscan)
expect("negative canvas position is clamped", negativeScroll.firstIndex == 1)

local largeOverscan = VirtualList.GetWindow(1000, 12000, viewportHeight, cardStep, 20)
expect("large overscan remains within collection bounds", largeOverscan.firstIndex >= 1 and largeOverscan.lastIndex <= 1000)

print("[PetKingdoms Test] PetCollection virtualization tests completed.")
