--!strict
-- Studio-only checks for the runtime personal-island Workspace bootstrap.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Workspace = game:GetService("Workspace")
local services = script.Parent.Parent:WaitForChild("Services")
local IslandWorldConfig = require(services:WaitForChild("IslandWorldConfig"))

local configured, code = IslandWorldConfig.configure()
assert(configured, "Workspace configuration must succeed: " .. code)

assert(Workspace:GetAttribute("IslandGridWidth") == 24, "default grid width must be 24")
assert(Workspace:GetAttribute("IslandGridDepth") == 24, "default grid depth must be 24")
assert(Workspace:GetAttribute("IslandGridCellSize") == 8, "default grid cell size must be 8")

local spawnFolder = Workspace:FindFirstChild("IslandSpawnPoints")
assert(spawnFolder and spawnFolder:IsA("Folder"), "spawn folder must exist")

local spawnCount = 0
for _, child in ipairs(spawnFolder:GetChildren()) do
	if child:IsA("BasePart") then
		spawnCount += 1
	end
end
assert(spawnCount >= 1, "at least one valid island spawn point must exist")
if spawnFolder:GetAttribute("PetKingdomsGenerated") == true then
	assert(spawnCount == 8, "generated default layout must provide exactly eight spawn points")
end

local beforeCount = #spawnFolder:GetChildren()
local configuredAgain, secondCode = IslandWorldConfig.configure()
assert(configuredAgain, "configuration must be idempotent: " .. secondCode)
assert(#spawnFolder:GetChildren() == beforeCount, "re-running configuration must not duplicate spawn points")

print("[PetKingdoms Test] PASS: island Workspace configuration and spawn slots")
