--!strict
-- Studio-only contract checks. These tests do not create production assets.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
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

-- Isolate a temporary approved-style art template for the runtime contract.
-- Gameplay prompts and rewards must remain server-owned regardless of art.
local existingTemplates = ServerStorage:FindFirstChild("ResourceNodeModels")
local temporaryTemplates: Folder? = nil
local temporaryWood: Model? = nil
if existingTemplates == nil then
	temporaryTemplates = Instance.new("Folder")
	temporaryTemplates.Name = "ResourceNodeModels"
	temporaryTemplates.Parent = ServerStorage
	existingTemplates = temporaryTemplates
end
if existingTemplates:FindFirstChild("wood") == nil then
	temporaryWood = Instance.new("Model")
	temporaryWood.Name = "wood"
	local treeMesh = Instance.new("Part")
	treeMesh.Name = "TestMesh"
	treeMesh.Anchored = true
	treeMesh.Size = Vector3.new(3, 5, 3)
	treeMesh.Transparency = 0.35
	treeMesh.Parent = temporaryWood
	temporaryWood.PrimaryPart = treeMesh
	local unsafeScript = Instance.new("Script")
	unsafeScript.Name = "UntrustedScript"
	unsafeScript.Parent = temporaryWood
	temporaryWood.Parent = existingTemplates
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
	if temporaryWood then temporaryWood:Destroy() end
	if temporaryTemplates then temporaryTemplates:Destroy() end
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
	local resources = firstWorld and firstWorld:FindFirstChild("ResourceNodes")
	local wood = resources and resources:FindFirstChild("WoodNode_A")
	assert(wood and wood:IsA("Model"), "wood resource must spawn")
	local gatherPrompt = wood:FindFirstChild("GatherPrompt", true)
	local gatherAnchor = wood:FindFirstChild("GatherAnchor")
	assert(gatherPrompt and gatherPrompt:IsA("ProximityPrompt")
		and gatherAnchor and gatherAnchor:IsA("BasePart")
		and gatherPrompt.Parent == gatherAnchor,
		"resource prompt must be attached to the trusted invisible anchor")
	assert(gatherAnchor.Transparency == 1 and not gatherAnchor.CanCollide,
		"invisible resource anchor must not obstruct movement")
	if temporaryWood then
		local model = wood:FindFirstChild("Visual")
		assert(model and model:IsA("Model")
			and model:GetAttribute("IsCustomResourceVisual") == true,
			"approved resource template must replace fallback geometry")
		assert(model:FindFirstChild("UntrustedScript", true) == nil,
			"resource template must not retain executable Script descendants")
		local visiblePart = model:FindFirstChild("TestMesh", true)
		assert(visiblePart and visiblePart:IsA("BasePart")
			and math.abs(visiblePart.Transparency - 0.35) < 0.01,
			"custom resource detail transparency must be retained")
	end
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

	IslandWorldService.remove(firstUserId)
	assert(IslandWorldService.getArrivalCFrame(firstUserId) == nil, "removing an island must clear its arrival CFrame")

	local thirdOk, thirdCode = IslandWorldService.spawn({ UserId = thirdUserId } :: any, profileFor(thirdUserId))
	assert(thirdOk and thirdCode == "SPAWNED", "released spawn slot must be reusable")
	table.insert(spawnedUsers, thirdUserId)
end)

cleanup()
assert(ok, "island world lifecycle integration test failed: " .. tostring(failure))
print("[PetKingdoms Test] PASS: personal island spawn, distinct slots, duplicate guard, cleanup, and slot reuse")
