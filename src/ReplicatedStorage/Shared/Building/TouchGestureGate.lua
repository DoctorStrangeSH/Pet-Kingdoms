--!strict
-- Small, deterministic gate for one-finger placement vs multi-touch camera gestures.
-- It never sinks input; it only tells the building controller whether a touch
-- sequence is still eligible to commit a placement target.

local TouchGestureGate = {}

local activeTouches: { [InputObject]: boolean } = {}
local activeCount = 0
local blocked = false
local candidate: InputObject? = nil

function TouchGestureGate.Begin(input: InputObject, eligible: boolean): boolean
	if not activeTouches[input] then
		activeTouches[input] = true
		activeCount += 1
	end

	if activeCount > 1 then
		blocked = true
		candidate = nil
		return false
	end

	if blocked or not eligible then
		return false
	end

	candidate = input
	return true
end

function TouchGestureGate.GetCandidate(): InputObject?
	return candidate
end

function TouchGestureGate.IsBlocked(): boolean
	return blocked
end

function TouchGestureGate.End(input: InputObject, cancelled: boolean): boolean
	local isCandidate = input == candidate
	if activeTouches[input] then
		activeTouches[input] = nil
		activeCount = math.max(0, activeCount - 1)
	end

	local mayCommit = isCandidate and not blocked and not cancelled and activeCount == 0
	if isCandidate then
		candidate = nil
	end
	if activeCount == 0 then
		blocked = false
		candidate = nil
	end
	return mayCommit
end

function TouchGestureGate.Reset()
	table.clear(activeTouches)
	activeCount = 0
	blocked = false
	candidate = nil
end

return table.freeze(TouchGestureGate)
