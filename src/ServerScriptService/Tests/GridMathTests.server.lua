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
local BuildingFootprints = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared")
	:WaitForChild("Building")
	:WaitForChild("BuildingFootprints"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

expect("snap to cell center", GridMath.snapWorldToGrid(1.4, 4) == 0)
for catalogId, footprint in pairs(BuildingFootprints) do
	expect(catalogId .. " shared footprint has positive integer dimensions",
		type(footprint.width) == "number" and footprint.width > 0 and footprint.width == math.floor(footprint.width)
			and type(footprint.depth) == "number" and footprint.depth > 0 and footprint.depth == math.floor(footprint.depth))
end
expect("snap across half-cell", GridMath.snapWorldToGrid(2.1, 4) == 4)
expect("invalid grid size rejected", GridMath.snapWorldToGrid(1, 0) == nil)
expect("non-finite world coordinate rejected", GridMath.snapWorldToGrid(math.huge, 4) == nil)

local width90, depth90 = GridMath.getRotatedFootprint(2, 3, 90)
expect("quarter turn swaps footprint", width90 == 3 and depth90 == 2)
local width270, depth270 = GridMath.getRotatedFootprint(2, 3, 270)
expect("three-quarter turn swaps footprint", width270 == 3 and depth270 == 2)
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
local rotatedExistingWidth, rotatedExistingDepth = GridMath.getRotatedFootprint(2, 3, 90)
local rotatedExisting = { x = 2, z = 2, width = rotatedExistingWidth, depth = rotatedExistingDepth }
local touchingRotated = { x = 5, z = 2, width = 2, depth = 3 }
local crossingRotated = { x = 4, z = 2, width = 2, depth = 3 }
expect("rotated footprint edge adjacency does not overlap", not GridMath.footprintsOverlap(rotatedExisting, touchingRotated))
expect("rotated footprint intersection overlaps", GridMath.footprintsOverlap(rotatedExisting, crossingRotated))

print("[PetKingdoms Test] GridMath smoke tests completed.")
