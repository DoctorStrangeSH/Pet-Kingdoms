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
	local seenPositions = {}
	for index = 1, 8 do
		local point = spawnFolder:FindFirstChild(string.format("IslandSlot_%02d", index))
		assert(point and point:IsA("BasePart"), "every generated slot must be a BasePart")
		assert(point.Anchored, "generated spawn points must be anchored")
		assert(point.Transparency == 1, "generated spawn points must be invisible")
		assert(not point.CanCollide and not point.CanTouch and not point.CanQuery, "generated spawn points must not affect gameplay physics or queries")
		local key = tostring(point.Position.X) .. ":" .. tostring(point.Position.Z)
		assert(not seenPositions[key], "generated spawn point positions must be unique")
		seenPositions[key] = true
	end
end

local beforeCount = #spawnFolder:GetChildren()
local configuredAgain, secondCode = IslandWorldConfig.configure()
assert(configuredAgain, "configuration must be idempotent: " .. secondCode)
assert(#spawnFolder:GetChildren() == beforeCount, "re-running configuration must not duplicate spawn points")

print("[PetKingdoms Test] PASS: island Workspace configuration and spawn slots")
