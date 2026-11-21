--!strict
-- Studio-only contract checks. These tests do not create production assets.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Workspace = game:GetService("Workspace")
local services = script.Parent.Parent:WaitForChild("Services")
local IslandWorldService = require(services:WaitForChild("IslandWorldService"))

local previousCellSize = Workspace:GetAttribute("IslandGridCellSize")
Workspace:SetAttribute("IslandGridCellSize", nil)

local invalidOk, invalidCode = IslandWorldService.spawn({ UserId = 123 } :: any, {})
assert(not invalidOk and invalidCode == "INVALID_PROFILE", "invalid profile must be rejected")

local validProfile = {
	ownerUserId = 123,
	schemaVersion = 1,
	boundsWidth = 10,
	boundsDepth = 10,
	buildings = {},
}
local missingConfigOk, missingConfigCode = IslandWorldService.spawn({ UserId = 123 } :: any, validProfile)
assert(not missingConfigOk and missingConfigCode == "MISSING_ISLAND_GRID_CELL_SIZE", "missing grid cell size must fail closed")

Workspace:SetAttribute("IslandGridCellSize", previousCellSize)
print("[PetKingdoms Test] PASS: IslandWorldService rejects invalid profiles and missing world configuration")
