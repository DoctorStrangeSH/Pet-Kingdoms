--!strict
-- Studio-only contract checks. These tests do not create production assets.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Workspace = game:GetService("Workspace")
local services = script.Parent.Parent:WaitForChild("Services")
local IslandWorldService = require(services:WaitForChild("IslandWorldService"))

local IslandWorldConfig = require(services:WaitForChild("IslandWorldConfig"))
local configured, configCode = IslandWorldConfig.configure()
assert(configured, "island world configuration must be ready: " .. configCode)

local invalidOk, invalidCode = IslandWorldService.spawn({ UserId = 123 } :: any, {})
assert(not invalidOk and invalidCode == "INVALID_PROFILE", "invalid profile must be rejected")

local previousCellSize = Workspace:GetAttribute("IslandGridCellSize")
Workspace:SetAttribute("IslandGridCellSize", 8)

local function profileFor(userId: number)
	return {
		ownerUserId = userId,
		schemaVersion = 1,
		boundsWidth = 24,
		boundsDepth = 24,
		buildings = {},
		resourceNodes = {},
	}
end

local firstUserId = 987654321
local secondUserId = 987654322
local thirdUserId = 987654323
local spawnedUsers = {}

local function cleanup()
	for _, userId in ipairs(spawnedUsers) do
		IslandWorldService.remove(userId)
	end
	Workspace:SetAttribute("IslandGridCellSize", previousCellSize)
end

local ok, failure = pcall(function()
	local firstOk, firstCode = IslandWorldService.spawn({ UserId = firstUserId } :: any, profileFor(firstUserId))
	assert(firstOk and firstCode == "SPAWNED", "first player island must spawn")
	table.insert(spawnedUsers, firstUserId)

	local firstArrival = IslandWorldService.getArrivalCFrame(firstUserId)
	assert(firstArrival ~= nil, "first player must receive an arrival CFrame")

	local duplicateOk, duplicateCode = IslandWorldService.spawn({ UserId = firstUserId } :: any, profileFor(firstUserId))
	assert(duplicateOk and duplicateCode == "ALREADY_SPAWNED", "duplicate spawn must not create a second island")

	local secondOk, secondCode = IslandWorldService.spawn({ UserId = secondUserId } :: any, profileFor(secondUserId))
	assert(secondOk and secondCode == "SPAWNED", "second player island must spawn")
	table.insert(spawnedUsers, secondUserId)

	local secondArrival = IslandWorldService.getArrivalCFrame(secondUserId)
	assert(secondArrival ~= nil, "second player must receive an arrival CFrame")
	assert((firstArrival.Position - secondArrival.Position).Magnitude > 1, "two players must never share an island spawn point")

	local worldFolder = Workspace:FindFirstChild("PlayerIslands")
	assert(worldFolder and worldFolder:FindFirstChild("Island_" .. tostring(firstUserId)), "first world model must exist")
	assert(worldFolder and worldFolder:FindFirstChild("Island_" .. tostring(secondUserId)), "second world model must exist")

	IslandWorldService.remove(firstUserId)
	assert(IslandWorldService.getArrivalCFrame(firstUserId) == nil, "removing an island must clear its arrival CFrame")
	table.remove(spawnedUsers, table.find(spawnedUsers, firstUserId))

	local thirdOk, thirdCode = IslandWorldService.spawn({ UserId = thirdUserId } :: any, profileFor(thirdUserId))
	assert(thirdOk and thirdCode == "SPAWNED", "released spawn slot must be reusable")
	table.insert(spawnedUsers, thirdUserId)
end)

cleanup()
assert(ok, "island world lifecycle integration test failed: " .. tostring(failure))
print("[PetKingdoms Test] PASS: personal island spawn, distinct slots, duplicate guard, cleanup, and slot reuse")
