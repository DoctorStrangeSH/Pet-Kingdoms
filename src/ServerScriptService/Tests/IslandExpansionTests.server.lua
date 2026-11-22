--!strict
-- Studio-only pure contract tests for island expansion geometry.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local IslandExpansion = require(services:WaitForChild("IslandExpansion"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local starter = IslandExpansion.getBounds(24, 24, 0)
expect("starter expansion level preserves current island bounds",
	starter ~= nil and starter.width == 24 and starter.depth == 24)

local first = IslandExpansion.getBounds(24, 24, 1)
expect("first expansion adds eight cells on both axes",
	first ~= nil and first.width == 32 and first.depth == 32)

local second = IslandExpansion.getBounds(24, 24, 2)
expect("second expansion adds sixteen cells on both axes",
	second ~= nil and second.width == 40 and second.depth == 40)

local nextFirst = IslandExpansion.getNextBounds(24, 24, 0)
expect("next bounds resolve from starter level",
	nextFirst ~= nil and nextFirst.width == 32 and nextFirst.depth == 32)

expect("maximum level has no next expansion",
	IslandExpansion.getNextBounds(24, 24, IslandExpansion.MAX_LEVEL) == nil)
expect("negative levels are rejected", IslandExpansion.getBounds(24, 24, -1) == nil)
expect("fractional levels are rejected", IslandExpansion.getBounds(24, 24, 0.5) == nil)
expect("levels above maximum are rejected", IslandExpansion.getBounds(24, 24, 3) == nil)
expect("invalid base dimensions are rejected", IslandExpansion.getBounds(0, 24, 1) == nil)
expect("non-finite dimensions are rejected", IslandExpansion.getBounds(math.huge, 24, 1) == nil)

print("[PetKingdoms Test] IslandExpansion geometry contract tests completed.")
