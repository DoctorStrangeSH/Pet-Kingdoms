--!strict
-- Studio-only smoke tests for pure grid helpers.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local GridMath = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared")
	:WaitForChild("Building")
	:WaitForChild("GridMath"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

expect("snap to cell center", GridMath.snapWorldToGrid(2.4, 4) == 0)
expect("snap across half-cell", GridMath.snapWorldToGrid(2.1, 4) == 4)
expect("invalid grid size rejected", GridMath.snapWorldToGrid(1, 0) == nil)
expect("non-finite world coordinate rejected", GridMath.snapWorldToGrid(math.huge, 4) == nil)

local width90, depth90 = GridMath.getRotatedFootprint(2, 3, 90)
expect("quarter turn swaps footprint", width90 == 3 and depth90 == 2)
local width45 = GridMath.getRotatedFootprint(2, 3, 45)
expect("unsupported rotation rejected", width45 == nil)

local inside = { x = 7, z = 7, width = 3, depth = 3 }
local outside = { x = 8, z = 7, width = 3, depth = 3 }
expect("exact island boundary accepted", GridMath.isWithinBounds(inside, 10, 10))
expect("outside island boundary rejected", not GridMath.isWithinBounds(outside, 10, 10))

local left = { x = 0, z = 0, width = 3, depth = 3 }
local adjacent = { x = 3, z = 0, width = 3, depth = 3 }
local overlap = { x = 2, z = 2, width = 3, depth = 3 }
expect("edge-adjacent footprints do not overlap", not GridMath.footprintsOverlap(left, adjacent))
expect("positive-area intersection overlaps", GridMath.footprintsOverlap(left, overlap))

print("[PetKingdoms Test] GridMath smoke tests completed.")
