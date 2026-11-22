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
		buildings = {
			{
				instanceId = "test-main-house-" .. tostring(userId),
				catalogId = "main_house",
				x = 14,
				z = 10,
				rotation = 0,
			},
			{
				instanceId = "test-pet-house-" .. tostring(userId),
				catalogId = "pet_house",
				x = 10,
				z = 10,
				rotation = 0,
			},
		},
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
	local firstWorld = worldFolder and worldFolder:FindFirstChild("Island_" .. tostring(firstUserId))
	local mainHouse = firstWorld and firstWorld:FindFirstChild("main_house_test-main-house-" .. tostring(firstUserId))
	assert(mainHouse and mainHouse:IsA("Model"), "saved main house must be rendered")
	local mainHousePrompt = mainHouse and mainHouse:FindFirstChild("MainHousePrompt", true)
	assert(mainHousePrompt and mainHousePrompt:IsA("ProximityPrompt"), "main house must expose its kingdom interaction")
	assert(mainHousePrompt.ActionText == "Управлять королевством", "main house prompt must have localized action text")

	local petHouse = firstWorld and firstWorld:FindFirstChild("pet_house_test-pet-house-" .. tostring(firstUserId))
	assert(petHouse and petHouse:IsA("Model"), "saved pet house must be rendered")
	local petHousePrompt = petHouse and petHouse:FindFirstChild("PetHousePrompt", true)
	assert(petHousePrompt and petHousePrompt:IsA("ProximityPrompt"), "pet house must expose its collection interaction")
	assert(petHousePrompt.ActionText == "Открыть коллекцию", "pet house prompt must have localized action text")
	assert(worldFolder and worldFolder:FindFirstChild("Island_" .. tostring(secondUserId)), "second world model must exist")

	local originalHousePivot = mainHouse:GetPivot()
	IslandWorldService.remove(firstUserId)
	assert(IslandWorldService.getArrivalCFrame(firstUserId) == nil, "removing an island must clear its arrival CFrame")

	local expandedProfile = profileFor(firstUserId)
	expandedProfile.boundsWidth = 32
	expandedProfile.boundsDepth = 32
	expandedProfile.expansionLevel = 1
	for _, building in ipairs(expandedProfile.buildings) do
		building.x += 4
		building.z += 4
	end
	local expandedOk, expandedCode = IslandWorldService.spawn({ UserId = firstUserId } :: any, expandedProfile)
	assert(expandedOk and expandedCode == "SPAWNED", "expanded island profile must render")
	table.insert(spawnedUsers, firstUserId)
	local expandedWorld = worldFolder and worldFolder:FindFirstChild("Island_" .. tostring(firstUserId))
	assert(expandedWorld and expandedWorld:GetAttribute("GridWidth") == 32 and expandedWorld:GetAttribute("GridDepth") == 32,
		"expanded world must expose persisted 32x32 bounds")
	local expandedGrass = expandedWorld and expandedWorld:FindFirstChild("Island_GrassTop")
	assert(expandedGrass and expandedGrass:IsA("BasePart")
		and expandedGrass.Size.X == 256 and expandedGrass.Size.Z == 256,
		"expanded terrain must render at the persisted grid dimensions")
	local expandedHouse = expandedWorld and expandedWorld:FindFirstChild("main_house_test-main-house-" .. tostring(firstUserId))
	assert(expandedHouse and expandedHouse:IsA("Model"), "expanded world must retain the saved main house")
	assert((expandedHouse:GetPivot().Position - originalHousePivot.Position).Magnitude < 0.01,
		"expansion coordinate shift must preserve existing building world position")

	IslandWorldService.remove(firstUserId)
	assert(IslandWorldService.getArrivalCFrame(firstUserId) == nil, "removing an island must clear its arrival CFrame")

	local thirdOk, thirdCode = IslandWorldService.spawn({ UserId = thirdUserId } :: any, profileFor(thirdUserId))
	assert(thirdOk and thirdCode == "SPAWNED", "released spawn slot must be reusable")
	table.insert(spawnedUsers, thirdUserId)
end)

cleanup()
assert(ok, "island world lifecycle integration test failed: " .. tostring(failure))
print("[PetKingdoms Test] PASS: personal island spawn, distinct slots, duplicate guard, cleanup, and slot reuse")
