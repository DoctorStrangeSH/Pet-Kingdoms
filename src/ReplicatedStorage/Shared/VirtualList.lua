--!strict
-- Pure helpers for fixed-height virtualized scrolling lists.

local VirtualList = {}

export type Window = {
	firstIndex: number,
	lastIndex: number,
	count: number,
}

function VirtualList.GetWindow(
	totalItems: number,
	canvasY: number,
	viewportHeight: number,
	itemStep: number,
	overscan: number
): Window
	assert(totalItems >= 0, "totalItems must be non-negative")
	assert(itemStep > 0, "itemStep must be positive")
	assert(overscan >= 0, "overscan must be non-negative")

	if totalItems == 0 then
		return { firstIndex = 0, lastIndex = 0, count = 0 }
	end

	local safeCanvasY = math.max(0, canvasY)
	local safeViewportHeight = math.max(1, viewportHeight)
	local firstVisible = math.floor(safeCanvasY / itemStep) + 1
	local firstIndex = math.max(1, firstVisible - overscan)
	local visibleCount = math.ceil(safeViewportHeight / itemStep) + overscan * 2
	local lastIndex = math.min(totalItems, firstIndex + visibleCount - 1)
	firstIndex = math.min(firstIndex, totalItems)

	return {
		firstIndex = firstIndex,
		lastIndex = lastIndex,
		count = math.max(0, lastIndex - firstIndex + 1),
	}
end

function VirtualList.ClampCanvasY(savedY: number, contentHeight: number, viewportHeight: number): number
	local maxY = math.max(0, contentHeight - math.max(0, viewportHeight))
	return math.clamp(savedY, 0, maxY)
end

function VirtualList.GetContentHeight(totalItems: number, itemStep: number, trailingGap: number): number
	assert(totalItems >= 0, "totalItems must be non-negative")
	assert(itemStep > 0, "itemStep must be positive")
	assert(trailingGap >= 0, "trailingGap must be non-negative")
	if totalItems == 0 then return 0 end
	return totalItems * itemStep - trailingGap
end

return table.freeze(VirtualList)
