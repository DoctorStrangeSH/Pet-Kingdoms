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

local wrongBoundsProfile = {
	ownerUserId = 123,
	schemaVersion = 1,
	boundsWidth = 40,
	boundsDepth = 40,
	expansionLevel = 1,
	buildings = {},
}
local wrongBoundsOk, wrongBoundsCode = IslandWorldService.spawn({ UserId = 123 } :: any, wrongBoundsProfile)
assert(not wrongBoundsOk and wrongBoundsCode == "INVALID_EXPANSION_BOUNDS",
	"world renderer must reject bounds that do not match the persisted expansion level")

local function profileFor(userId: number)
	local gatheredAt = os.time()
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
				rotation = 90,
				upgradeLevel = 2,
			},
		},
		resourceNodes = {
			{
				nodeId = "WoodNode_A",
				resourceId = "wood",
				lastGatheredAt = gatheredAt,
				availableAt = gatheredAt + 45,
			},
		},
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
	local resourceNodes = firstWorld and firstWorld:FindFirstChild("ResourceNodes")
	local savedWoodNode = resourceNodes and resourceNodes:FindFirstChild("WoodNode_A")
	assert(savedWoodNode and savedWoodNode:GetAttribute("AvailableAt") > os.time(),
		"saved resource node cooldown must be restored when the island spawns")
	local savedWoodPrompt = savedWoodNode and savedWoodNode:FindFirstChild("GatherPrompt", true)
	assert(savedWoodPrompt and savedWoodPrompt:IsA("ProximityPrompt") and not savedWoodPrompt.Enabled,
		"resource prompt must remain disabled while its persisted cooldown is active")
	local hiddenWoodPart = savedWoodNode and savedWoodNode:FindFirstChildWhichIsA("BasePart")
	assert(hiddenWoodPart and hiddenWoodPart.Transparency == 1,
		"resource node must remain hidden during its persisted cooldown")
	local savedWoodMarker = savedWoodNode and savedWoodNode:FindFirstChild("GatheringMarker", true)
	assert(savedWoodMarker and savedWoodMarker:IsA("BillboardGui") and not savedWoodMarker.Enabled,
		"gathering marker must also be hidden during a restored cooldown")

	assert(mainHouse and mainHouse:GetAttribute("MaxUpgradeLevel") == 3,
		"spawned main house must expose its server-owned upgrade level cap")
	assert(mainHouse and mainHouse:GetAttribute("NextUpgradeWoodCost") == 12
		and mainHouse:GetAttribute("NextUpgradeStoneCost") == 6,
		"spawned main house must expose the server-owned cost for its next upgrade")
	local mainHousePrompt = mainHouse and mainHouse:FindFirstChild("MainHousePrompt", true)
	assert(mainHousePrompt and mainHousePrompt:IsA("ProximityPrompt"), "main house must expose its kingdom interaction")
	assert(mainHousePrompt.ActionText == "Управлять королевством", "main house prompt must have localized action text")

	local petHouse = firstWorld and firstWorld:FindFirstChild("pet_house_test-pet-house-" .. tostring(firstUserId))
	assert(petHouse and petHouse:IsA("Model"), "saved pet house must be rendered")
	assert(petHouse and petHouse:GetAttribute("UpgradeLevel") == 2,
		"spawned pet house must restore its saved level-2 upgrade attribute")
	assert(petHouse and petHouse:GetAttribute("GridX") == 10 and petHouse:GetAttribute("GridZ") == 10,
		"spawned pet house must restore its saved grid coordinates")
	assert(petHouse and petHouse:GetAttribute("GridRotation") == 90,
		"spawned pet house must restore its saved 90-degree rotation")
	assert(petHouse and petHouse:GetAttribute("MaxUpgradeLevel") == 3,
		"spawned pet house must expose its server-owned upgrade level cap")
	assert(petHouse and petHouse:GetAttribute("NextUpgradeWoodCost") == 20
		and petHouse:GetAttribute("NextUpgradeStoneCost") == 12,
		"level-2 pet house must expose level-3 costs from the server catalog")
	local petHousePrompt = petHouse and petHouse:FindFirstChild("PetHousePrompt", true)
	assert(petHousePrompt and petHousePrompt:IsA("ProximityPrompt"), "pet house must expose its collection interaction")
	assert(petHousePrompt.ActionText == "Открыть коллекцию", "pet house prompt must have localized action text")
	assert(worldFolder and worldFolder:FindFirstChild("Island_" .. tostring(secondUserId)), "second world model must exist")

	local originalHousePivot = mainHouse:GetPivot()
	local originalWorld = firstWorld
	local expandedProfile = profileFor(firstUserId)
	expandedProfile.boundsWidth = 32
	expandedProfile.boundsDepth = 32
	expandedProfile.expansionLevel = 1
	for _, building in ipairs(expandedProfile.buildings) do
		building.x += 4
		building.z += 4
	end
	local expandedOk, expandedCode = IslandWorldService.refresh(firstUserId, { UserId = firstUserId } :: any, expandedProfile)
	assert(expandedOk and expandedCode == "WORLD_REFRESHED", "expanded island must refresh in the active session")
	local expandedWorld = worldFolder and worldFolder:FindFirstChild("Island_" .. tostring(firstUserId))
	assert(originalWorld.Parent == nil, "successful refresh must replace the previous world model")
	assert(expandedWorld and expandedWorld:GetAttribute("GridWidth") == 32 and expandedWorld:GetAttribute("GridDepth") == 32,
		"expanded world must expose persisted 32x32 bounds")
	assert(expandedWorld and expandedWorld.Name == "Island_" .. tostring(firstUserId),
		"refreshed island must preserve its stable player-island model name")
	local expansionEffect = expandedWorld and expandedWorld:FindFirstChild("ExpansionCompletionEffect")
	assert(expansionEffect and expansionEffect:IsA("Folder"),
		"successful size increase must create a transient expansion completion effect")
	assert(expansionEffect and expansionEffect:FindFirstChildWhichIsA("ParticleEmitter", true) ~= nil,
		"expansion completion effect must include particles")
	local expandedGrass = expandedWorld and expandedWorld:FindFirstChild("Island_GrassTop")
	assert(expandedGrass and expandedGrass:IsA("BasePart")
		and expandedGrass.Size.X == 256 and expandedGrass.Size.Z == 256,
		"expanded terrain must render at the persisted grid dimensions")
	local expandedHouse = expandedWorld and expandedWorld:FindFirstChild("main_house_test-main-house-" .. tostring(firstUserId))
	assert(expandedHouse and expandedHouse:IsA("Model"), "expanded world must retain the saved main house")
	local expandedPetHouse = expandedWorld and expandedWorld:FindFirstChild("pet_house_test-pet-house-" .. tostring(firstUserId))
	assert(expandedPetHouse and expandedPetHouse:GetAttribute("UpgradeLevel") == 2,
		"world refresh after expansion must preserve the saved pet-house upgrade level")
	assert(expandedPetHouse and expandedPetHouse:GetAttribute("GridRotation") == 90,
		"world refresh after expansion must preserve the saved pet-house rotation")
	assert(expandedPetHouse and expandedPetHouse:GetAttribute("GridX") == 14
		and expandedPetHouse:GetAttribute("GridZ") == 14,
		"world refresh after expansion must preserve the shifted saved pet-house coordinates")
	local expandedNodes = expandedWorld and expandedWorld:FindFirstChild("ResourceNodes")
	local expandedWoodNode = expandedNodes and expandedNodes:FindFirstChild("WoodNode_A")
	assert(expandedWoodNode and expandedWoodNode:GetAttribute("AvailableAt") > os.time(),
		"world refresh must preserve the resource node cooldown")
	local expandedWoodPrompt = expandedWoodNode and expandedWoodNode:FindFirstChild("GatherPrompt", true)
	assert(expandedWoodPrompt and expandedWoodPrompt:IsA("ProximityPrompt") and not expandedWoodPrompt.Enabled,
		"world refresh must not re-enable a node that is still on cooldown")
	assert((expandedHouse:GetPivot().Position - originalHousePivot.Position).Magnitude < 0.01,
		"expansion coordinate shift must preserve existing building world position")

	local maxExpandedProfile = profileFor(firstUserId)
	maxExpandedProfile.boundsWidth = 40
	maxExpandedProfile.boundsDepth = 40
	maxExpandedProfile.expansionLevel = 2
	for _, building in ipairs(maxExpandedProfile.buildings) do
		building.x += 8
		building.z += 8
	end
	local previousExpandedWorld = expandedWorld
	local maxExpandedOk, maxExpandedCode = IslandWorldService.refresh(firstUserId, { UserId = firstUserId } :: any, maxExpandedProfile)
	assert(maxExpandedOk and maxExpandedCode == "WORLD_REFRESHED", "maximum expansion must refresh in the active session")
	local maxExpandedWorld = worldFolder and worldFolder:FindFirstChild("Island_" .. tostring(firstUserId))
	assert(previousExpandedWorld and previousExpandedWorld.Parent == nil, "maximum refresh must replace the previous world model")
	assert(maxExpandedWorld and maxExpandedWorld:GetAttribute("GridWidth") == 40 and maxExpandedWorld:GetAttribute("GridDepth") == 40,
		"maximum expanded world must expose 40x40 bounds")
	assert(maxExpandedWorld and maxExpandedWorld.Name == "Island_" .. tostring(firstUserId),
		"repeated refreshes must not append suffixes to the island model name")
	local maxExpandedGrass = maxExpandedWorld and maxExpandedWorld:FindFirstChild("Island_GrassTop")
	assert(maxExpandedGrass and maxExpandedGrass:IsA("BasePart")
		and maxExpandedGrass.Size.X == 320 and maxExpandedGrass.Size.Z == 320,
		"maximum expanded terrain must render at 320x320 studs")
	local maxExpandedHouse = maxExpandedWorld and maxExpandedWorld:FindFirstChild("main_house_test-main-house-" .. tostring(firstUserId))
	assert(maxExpandedHouse and maxExpandedHouse:IsA("Model"), "maximum expanded world must retain the main house")
	assert((maxExpandedHouse:GetPivot().Position - originalHousePivot.Position).Magnitude < 0.01,
		"two expansion levels must preserve the original main-house world position")
	local maxExpandedPetHouse = maxExpandedWorld and maxExpandedWorld:FindFirstChild("pet_house_test-pet-house-" .. tostring(firstUserId))
	assert(maxExpandedPetHouse and maxExpandedPetHouse:GetAttribute("GridRotation") == 90,
		"maximum expansion must preserve the saved pet-house rotation")
	assert(maxExpandedPetHouse and maxExpandedPetHouse:GetAttribute("GridX") == 18
		and maxExpandedPetHouse:GetAttribute("GridZ") == 18,
		"maximum expansion must preserve the shifted pet-house grid coordinates")

	-- A live move updates the rendered model's grid metadata and orientation,
	-- while the profile record remains the caller-owned transaction source.
	local movedPetRecord = table.clone(maxExpandedProfile.buildings[2])
	movedPetRecord.x += 1
	movedPetRecord.rotation = 180
	local beforeMovePivot = maxExpandedPetHouse:GetPivot()
	local syncOk, syncCode = IslandWorldService.syncBuilding(firstUserId, maxExpandedProfile, movedPetRecord)
	assert(syncOk and syncCode == "BUILDING_SYNCED", "moving a saved building must sync its world model")
	local movedPetHouse = maxExpandedWorld and maxExpandedWorld:FindFirstChild("pet_house_test-pet-house-" .. tostring(firstUserId))
	assert(movedPetHouse and movedPetHouse:GetAttribute("GridX") == movedPetRecord.x
		and movedPetHouse:GetAttribute("GridZ") == movedPetRecord.z,
		"live move must update the rendered model grid coordinates")
	assert(movedPetHouse and movedPetHouse:GetAttribute("GridRotation") == 180,
		"live move must update the rendered model rotation")
	assert(movedPetHouse and (movedPetHouse:GetPivot().Position - beforeMovePivot.Position).Magnitude > 0.1,
		"live move must reposition the rendered model")

	IslandWorldService.remove(firstUserId)
	assert(IslandWorldService.getArrivalCFrame(firstUserId) == nil, "removing an island must clear its arrival CFrame")

	local thirdOk, thirdCode = IslandWorldService.spawn({ UserId = thirdUserId } :: any, profileFor(thirdUserId))
	assert(thirdOk and thirdCode == "SPAWNED", "released spawn slot must be reusable")
	table.insert(spawnedUsers, thirdUserId)
end)

cleanup()
assert(ok, "island world lifecycle integration test failed: " .. tostring(failure))
print("[PetKingdoms Test] PASS: personal island spawn, distinct slots, duplicate guard, cleanup, and slot reuse")
