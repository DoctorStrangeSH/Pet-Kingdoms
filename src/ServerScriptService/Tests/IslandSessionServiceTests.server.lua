--!strict
-- Studio-only checks for fail-closed island session configuration.
-- This script does not load or write DataStores.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Workspace = game:GetService("Workspace")
local originalWidth = Workspace:GetAttribute("IslandGridWidth")
local originalDepth = Workspace:GetAttribute("IslandGridDepth")

Workspace:SetAttribute("IslandGridWidth", nil)
Workspace:SetAttribute("IslandGridDepth", nil)

local services = script.Parent.Parent:WaitForChild("Services")
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local profile = IslandSessionService.getProfile(-1)
assert(profile == nil, "unknown player must not have an island profile")
assert(not IslandSessionService.markDirty(-1), "unknown player cannot be marked dirty")
print("[PetKingdoms Test] PASS: session service rejects unknown player session")

Workspace:SetAttribute("IslandGridWidth", originalWidth)
Workspace:SetAttribute("IslandGridDepth", originalDepth)

print("[PetKingdoms Test] IslandSessionService contract tests completed.")
