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

local original = {
	boundsWidth = 24,
	boundsDepth = 24,
	expansionLevel = 0,
	buildings = {
		{ instanceId = "house-1", catalogId = "main_house", x = 2, z = 3, rotation = 0 },
		{ instanceId = "pet-1", catalogId = "pet_house", x = 12, z = 8, rotation = 90 },
	},
}
local originalFirstX = original.buildings[1].x
local originalSecondZ = original.buildings[2].z
local firstProfile, firstStatus = IslandExpansion.expandProfile(original)
expect("first profile expansion succeeds", firstProfile ~= nil and firstStatus == "EXPANDED")
expect("first expansion updates dimensions and level",
	firstProfile ~= nil and firstProfile.boundsWidth == 32 and firstProfile.boundsDepth == 32 and firstProfile.expansionLevel == 1)
expect("first expansion shifts each building by four cells",
	firstProfile ~= nil and firstProfile.buildings[1].x == 6 and firstProfile.buildings[1].z == 7
		and firstProfile.buildings[2].x == 16 and firstProfile.buildings[2].z == 12)
expect("first expansion leaves source profile immutable",
	original.boundsWidth == 24 and original.boundsDepth == 24 and original.expansionLevel == 0
		and original.buildings[1].x == originalFirstX and original.buildings[2].z == originalSecondZ)

local secondProfile, secondStatus = IslandExpansion.expandProfile(firstProfile)
expect("second profile expansion succeeds", secondProfile ~= nil and secondStatus == "EXPANDED")
expect("second expansion reaches forty by forty",
	secondProfile ~= nil and secondProfile.boundsWidth == 40 and secondProfile.boundsDepth == 40 and secondProfile.expansionLevel == 2)
expect("two expansions preserve cumulative grid shift",
	secondProfile ~= nil and secondProfile.buildings[1].x == 10 and secondProfile.buildings[1].z == 11
		and secondProfile.buildings[2].x == 20 and secondProfile.buildings[2].z == 16)
local maxProfile, maxStatus = IslandExpansion.expandProfile(secondProfile)
expect("third expansion is rejected at maximum level",
	maxProfile == nil and maxStatus == "MAX_EXPANSION_REACHED")

local fractionalProfile = {
	boundsWidth = 24, boundsDepth = 24, expansionLevel = 0,
	buildings = {{ instanceId = "bad-fraction", catalogId = "main_house", x = 1.5, z = 2, rotation = 0 }},
}
local fractionalResult, fractionalCode = IslandExpansion.expandProfile(fractionalProfile)
expect("fractional saved building coordinates are rejected",
	fractionalResult == nil and fractionalCode == "INVALID_BUILDING_RECORD")

local negativeProfile = {
	boundsWidth = 24, boundsDepth = 24, expansionLevel = 0,
	buildings = {{ instanceId = "bad-negative", catalogId = "main_house", x = -1, z = 2, rotation = 0 }},
}
local negativeResult, negativeCode = IslandExpansion.expandProfile(negativeProfile)
expect("negative saved building coordinates are rejected",
	negativeResult == nil and negativeCode == "INVALID_BUILDING_RECORD")

print("[PetKingdoms Test] IslandExpansion geometry contract tests completed.")
