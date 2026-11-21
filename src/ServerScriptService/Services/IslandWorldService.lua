--!strict
-- Server-side personal island blockout renderer.
-- The terrain is procedural prototype geometry. Production building models
-- are supplied separately in ServerStorage/BuildingModels/<catalogId>.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local BuildingCatalog = require(script.Parent:WaitForChild("BuildingCatalog"))
local GridMath = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Building"):WaitForChild("GridMath"))

local IslandWorldService = {}

local SPAWN_FOLDER_NAME = "IslandSpawnPoints"
local WORLD_FOLDER_NAME = "PlayerIslands"
local BUILDING_FOLDER_NAME = "BuildingModels"
local ROCK_COLOR = Color3.fromRGB(105, 105, 111)
local GRASS_COLOR = Color3.fromRGB(103, 166, 91)
local DIRT_COLOR = Color3.fromRGB(119, 83, 58)

local occupiedSpawns: { [Instance]: number } = {}
local worldsByUserId: { [number]: Model } = {}
local arrivalCFrames: { [number]: CFrame } = {}

local function getNumberAttribute(name: string): number?
	local value = Workspace:GetAttribute(name)
	if type(value) ~= "number" or value <= 0 or value ~= value or value == math.huge then
		return nil
	end
	return value
end

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	if shape then part.Shape = shape end
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeTree(parent: Instance, base: CFrame, scale: number, index: number)
	local tree = Instance.new("Model")
	tree.Name = "BlockoutTree_" .. tostring(index)
	tree.Parent = parent
	local trunkHeight = 5 * scale
	makePart(tree, "Trunk", Vector3.new(1.2, trunkHeight, 1.2), base * CFrame.new(0, trunkHeight / 2, 0),
		Color3.fromRGB(112, 76, 48), Enum.Material.Wood)
	makePart(tree, "Canopy_Lower", Vector3.new(5.2, 4.2, 5.2) * scale,
		base * CFrame.new(0, trunkHeight + 1.8 * scale, 0), Color3.fromRGB(76, 139, 72), Enum.Material.Grass, Enum.PartType.Ball)
	makePart(tree, "Canopy_Upper", Vector3.new(3.8, 3.8, 3.8) * scale,
		base * CFrame.new(0, trunkHeight + 4 * scale, 0), Color3.fromRGB(102, 166, 86), Enum.Material.Grass, Enum.PartType.Ball)
end

local function createTerrain(world: Model, spawnCFrame: CFrame, width: number, depth: number, cellSize: number)
	local sizeX = width * cellSize
	local sizeZ = depth * cellSize
	local maxDimension = math.max(sizeX, sizeZ)
	local top = spawnCFrame

	makePart(world, "Island_GrassTop", Vector3.new(sizeX, 4, sizeZ),
		top * CFrame.new(0, -2, 0), GRASS_COLOR, Enum.Material.Grass)

	makePart(world, "Island_DirtLayer", Vector3.new(sizeX + 2, 5, sizeZ + 2),
		top * CFrame.new(0, -6.5, 0), DIRT_COLOR, Enum.Material.Ground)

	makePart(world, "Island_StoneCore", Vector3.new(sizeX * 0.88, 8, sizeZ * 0.88),
		top * CFrame.new(0, -12.5, 0), ROCK_COLOR, Enum.Material.Slate)

	for index = 1, 8 do
		local angle = (math.pi * 2 * index) / 8
		local radiusX = sizeX * 0.42
		local radiusZ = sizeZ * 0.42
		local x = math.cos(angle) * radiusX
		local z = math.sin(angle) * radiusZ
		local rockSize = Vector3.new(maxDimension * 0.12, 5 + (index % 3) * 2, maxDimension * 0.14)
		makePart(world, "Island_CliffRock_" .. tostring(index), rockSize,
			top * CFrame.new(x, -9 - (index % 2) * 2, z) * CFrame.Angles(0, angle, math.rad((index % 3 - 1) * 9)),
			ROCK_COLOR:Lerp(DIRT_COLOR, 0.18), Enum.Material.Rock, Enum.PartType.Ball)
	end

	-- Deterministic perimeter greenery; kept away from the central building area.
	local treePositions = {
		{ -0.38, -0.34, 1.0 }, { 0.35, -0.37, 0.85 }, { -0.42, 0.28, 0.8 },
		{ 0.4, 0.32, 1.05 }, { -0.1, 0.42, 0.72 }, { 0.12, -0.43, 0.75 },
	}
	for index, item in ipairs(treePositions) do
		local x = item[1] * sizeX
		local z = item[2] * sizeZ
		local treeBase = top * CFrame.new(x, 0, z)
		makeTree(world, treeBase, item[3], index)
	end

	-- A simple stone arrival pad is a temporary gameplay landmark.
	makePart(world, "Arrival_Pad", Vector3.new(cellSize * 2.4, 0.35, cellSize * 2.4),
		top * CFrame.new(0, 0.18, sizeZ * 0.34), Color3.fromRGB(181, 177, 160), Enum.Material.Slate)
end

local function gridToWorld(spawnCFrame: CFrame, record: any, profile: any, cellSize: number): CFrame
	local definition = BuildingCatalog[record.catalogId]
	if definition == nil then
		error("Building catalog entry disappeared for " .. tostring(record.catalogId))
	end
	local footprintWidth, footprintDepth = GridMath.getRotatedFootprint(
		definition.footprintWidth,
		definition.footprintDepth,
		record.rotation
	)
	if footprintWidth == nil or footprintDepth == nil then
		error("Invalid building rotation for " .. tostring(record.instanceId))
	end
	local localX = (record.x + footprintWidth / 2 - profile.boundsWidth / 2) * cellSize
	local localZ = (record.z + footprintDepth / 2 - profile.boundsDepth / 2) * cellSize
	return spawnCFrame * CFrame.new(localX, 0, localZ)
end

local function createFallbackBuilding(catalogId: string, cellSize: number): Model?
	local definition = BuildingCatalog[catalogId]
	if definition == nil then
		return nil
	end
	local footprintWidth, footprintDepth = definition.footprintWidth, definition.footprintDepth
	local width = footprintWidth * cellSize * 0.82
	local depth = footprintDepth * cellSize * 0.82
	local unit = cellSize
	local model = Instance.new("Model")
	model.Name = "Fallback_" .. catalogId
	local root = Instance.new("Part")
	root.Name = "Pivot"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root

	if catalogId == "pet_house" then
		makePart(model, "Body", Vector3.new(width * 0.82, unit * 0.48, depth * 0.72),
			CFrame.new(0, unit * 0.24, 0), Color3.fromRGB(238, 190, 132), Enum.Material.Wood)
		makePart(model, "Roof", Vector3.new(width, unit * 0.16, depth * 0.9),
			CFrame.new(0, unit * 0.58, 0), Color3.fromRGB(105, 164, 205), Enum.Material.SmoothPlastic)
		makePart(model, "Door", Vector3.new(width * 0.22, unit * 0.3, 0.12),
			CFrame.new(0, unit * 0.15, -depth * 0.365), Color3.fromRGB(91, 61, 47), Enum.Material.Wood)
		makePart(model, "Sign", Vector3.new(width * 0.38, unit * 0.13, 0.12),
			CFrame.new(0, unit * 0.82, -depth * 0.37), Color3.fromRGB(255, 218, 137), Enum.Material.SmoothPlastic)
	elseif catalogId == "stone_path" then
		local slab = makePart(model, "StoneSlab", Vector3.new(width * 0.92, unit * 0.1, depth * 0.92),
			CFrame.new(0, unit * 0.05, 0), Color3.fromRGB(157, 157, 150), Enum.Material.Slate)
		slab.TopSurface = Enum.SurfaceType.Smooth
		makePart(model, "StoneAccent", Vector3.new(width * 0.24, unit * 0.035, depth * 0.16),
			CFrame.new(-width * 0.18, unit * 0.12, -depth * 0.12), Color3.fromRGB(190, 184, 166), Enum.Material.Rock)
	elseif catalogId == "garden_lantern" then
		makePart(model, "Foot", Vector3.new(width * 0.5, unit * 0.08, depth * 0.5),
			CFrame.new(0, unit * 0.04, 0), Color3.fromRGB(102, 78, 57), Enum.Material.Wood)
		makePart(model, "Post", Vector3.new(width * 0.12, unit * 0.62, depth * 0.12),
			CFrame.new(0, unit * 0.36, 0), Color3.fromRGB(111, 77, 48), Enum.Material.Wood)
		local glow = makePart(model, "LanternGlow", Vector3.new(width * 0.42, unit * 0.28, depth * 0.42),
			CFrame.new(0, unit * 0.78, 0), Color3.fromRGB(255, 211, 125), Enum.Material.Neon)
		glow.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 205, 126)
		light.Brightness = 0.7
		light.Range = cellSize * 2.5
		light.Shadows = false
		light.Parent = glow
		makePart(model, "Cap", Vector3.new(width * 0.56, unit * 0.08, depth * 0.56),
			CFrame.new(0, unit * 0.96, 0), Color3.fromRGB(83, 63, 49), Enum.Material.Wood)
	elseif catalogId == "flower_bed" then
		makePart(model, "PlanterBase", Vector3.new(width * 0.88, unit * 0.12, depth * 0.88),
			CFrame.new(0, unit * 0.06, 0), Color3.fromRGB(132, 91, 61), Enum.Material.WoodPlanks)
		makePart(model, "Soil", Vector3.new(width * 0.72, unit * 0.08, depth * 0.72),
			CFrame.new(0, unit * 0.15, 0), Color3.fromRGB(76, 58, 43), Enum.Material.Ground)
		local flowerColors = {
			Color3.fromRGB(255, 112, 145),
			Color3.fromRGB(255, 218, 104),
			Color3.fromRGB(166, 139, 255),
		}
		for index = 1, 3 do
			local x = (index - 2) * width * 0.22
			local z = if index == 2 then depth * 0.18 else -depth * 0.12
			makePart(model, "Stem_" .. tostring(index), Vector3.new(0.07, unit * 0.24, 0.07),
				CFrame.new(x, unit * 0.29, z), Color3.fromRGB(72, 139, 73), Enum.Material.Grass)
			local bloom = makePart(model, "Bloom_" .. tostring(index), Vector3.new(unit * 0.17, unit * 0.17, unit * 0.17),
				CFrame.new(x, unit * 0.43, z), flowerColors[index], Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			bloom.CanCollide = false
		end
	elseif catalogId == "wooden_fence" then
		local postColor = Color3.fromRGB(128, 88, 55)
		for index, x in ipairs({ -width * 0.4, width * 0.4 }) do
			makePart(model, "Post_" .. tostring(index), Vector3.new(width * 0.12, unit * 0.62, depth * 0.12),
				CFrame.new(x, unit * 0.31, 0), postColor, Enum.Material.Wood)
		end
		makePart(model, "Rail_Lower", Vector3.new(width * 0.86, unit * 0.12, depth * 0.1),
			CFrame.new(0, unit * 0.24, 0), Color3.fromRGB(157, 112, 69), Enum.Material.Wood)
		makePart(model, "Rail_Upper", Vector3.new(width * 0.86, unit * 0.12, depth * 0.1),
			CFrame.new(0, unit * 0.52, 0), Color3.fromRGB(157, 112, 69), Enum.Material.Wood)
	else
		makePart(model, "Foundation", Vector3.new(width, unit * 0.16, depth),
			CFrame.new(0, unit * 0.08, 0), Color3.fromRGB(119, 91, 72), Enum.Material.WoodPlanks)
		makePart(model, "Walls", Vector3.new(width * 0.9, unit * 0.68, depth * 0.84),
			CFrame.new(0, unit * 0.5, 0), Color3.fromRGB(246, 218, 169), Enum.Material.SmoothPlastic)
		makePart(model, "Roof", Vector3.new(width * 1.08, unit * 0.2, depth * 1.02),
			CFrame.new(0, unit * 0.94, 0), Color3.fromRGB(126, 83, 139), Enum.Material.Slate)
		makePart(model, "Door", Vector3.new(width * 0.2, unit * 0.42, 0.14),
			CFrame.new(0, unit * 0.3, -depth * 0.425), Color3.fromRGB(126, 83, 57), Enum.Material.Wood)
		makePart(model, "Window_Left", Vector3.new(width * 0.16, unit * 0.17, 0.12),
			CFrame.new(-width * 0.28, unit * 0.58, -depth * 0.425), Color3.fromRGB(122, 214, 224), Enum.Material.Glass)
		makePart(model, "Window_Right", Vector3.new(width * 0.16, unit * 0.17, 0.12),
			CFrame.new(width * 0.28, unit * 0.58, -depth * 0.425), Color3.fromRGB(122, 214, 224), Enum.Material.Glass)
	end
	model:SetAttribute("IsFallbackBlockout", true)
	return model
end

local function getBuildingTemplate(catalogId: string, cellSize: number): Model?
	local templates = ServerStorage:FindFirstChild(BUILDING_FOLDER_NAME)
	local template = templates and templates:FindFirstChild(catalogId)
	if template and template:IsA("Model") then
		return template:Clone()
	end
	return createFallbackBuilding(catalogId, cellSize)
end

local function spawnBuildings(world: Model, spawnCFrame: CFrame, profile: any, cellSize: number)
	for _, record in ipairs(profile.buildings) do
		local clone = getBuildingTemplate(record.catalogId, cellSize)
		if clone == nil then
			warn(string.format("[PetKingdoms] No template or fallback for building '%s'; record remains saved and is skipped visually.", record.catalogId))
			continue
		end

		clone.Name = record.catalogId .. "_" .. record.instanceId
		clone:SetAttribute("BuildingInstanceId", record.instanceId)
		clone:SetAttribute("BuildingCatalogId", record.catalogId)
		clone:SetAttribute("GridX", record.x)
		clone:SetAttribute("GridZ", record.z)
		clone:SetAttribute("GridRotation", record.rotation)
		clone.Parent = world
		local pivot = gridToWorld(spawnCFrame, record, profile, cellSize)
		clone:PivotTo(pivot * CFrame.Angles(0, math.rad(record.rotation), 0))
	end
end

function IslandWorldService.spawn(player: Player, profile: any): (boolean, string)
	if worldsByUserId[player.UserId] then
		return true, "ALREADY_SPAWNED"
	end
	if type(profile) ~= "table" or profile.ownerUserId ~= player.UserId then
		return false, "INVALID_PROFILE"
	end

	local cellSize = getNumberAttribute("IslandGridCellSize")
	if cellSize == nil then
		return false, "MISSING_ISLAND_GRID_CELL_SIZE"
	end

	local spawnFolder = Workspace:FindFirstChild(SPAWN_FOLDER_NAME)
	if spawnFolder == nil or not spawnFolder:IsA("Folder") then
		return false, "MISSING_ISLAND_SPAWN_POINTS"
	end

	local spawnPoint: BasePart? = nil
	for _, candidate in ipairs(spawnFolder:GetChildren()) do
		if candidate:IsA("BasePart") and occupiedSpawns[candidate] == nil then
			spawnPoint = candidate
			break
		end
	end
	if spawnPoint == nil then
		return false, "NO_FREE_ISLAND_SPAWN_POINT"
	end

	local worldFolder = Workspace:FindFirstChild(WORLD_FOLDER_NAME)
	if worldFolder == nil then
		worldFolder = Instance.new("Folder")
		worldFolder.Name = WORLD_FOLDER_NAME
		worldFolder.Parent = Workspace
	end

	local world = Instance.new("Model")
	world.Name = "Island_" .. tostring(player.UserId)
	world:SetAttribute("OwnerUserId", player.UserId)
	world:SetAttribute("SchemaVersion", profile.schemaVersion)
	world:SetAttribute("GridWidth", profile.boundsWidth)
	world:SetAttribute("GridDepth", profile.boundsDepth)
	world:SetAttribute("GridCellSize", cellSize)
	world.Parent = worldFolder

	local ok, err = pcall(function()
		createTerrain(world, spawnPoint.CFrame, profile.boundsWidth, profile.boundsDepth, cellSize)
		spawnBuildings(world, spawnPoint.CFrame, profile, cellSize)
	end)
	if not ok then
		world:Destroy()
		warn("[PetKingdoms] Island world generation failed:", err)
		return false, "WORLD_GENERATION_FAILED"
	end

	occupiedSpawns[spawnPoint] = player.UserId
	worldsByUserId[player.UserId] = world
	arrivalCFrames[player.UserId] = spawnPoint.CFrame * CFrame.new(0, 4, (profile.boundsDepth * cellSize) * 0.34)
	return true, "SPAWNED"
end

function IslandWorldService.removeBuilding(userId: number, instanceId: string): boolean
	local world = worldsByUserId[userId]
	if world == nil then return false end
	for _, child in ipairs(world:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("BuildingInstanceId") == instanceId then
			child:Destroy()
			return true
		end
	end
	return false
end

function IslandWorldService.syncBuilding(userId: number, profile: any, record: any): (boolean, string)
	local world = worldsByUserId[userId]
	if world == nil then
		return false, "ISLAND_NOT_LOADED"
	end
	local cellSize = getNumberAttribute("IslandGridCellSize")
	if cellSize == nil then
		return false, "MISSING_ISLAND_GRID_CELL_SIZE"
	end
	local clone = getBuildingTemplate(record.catalogId, cellSize)
	if clone == nil then
		return false, "BUILDING_TEMPLATE_NOT_FOUND"
	end
	local spawnCFrame = nil
	for spawnPoint, ownerUserId in pairs(occupiedSpawns) do
		if ownerUserId == userId then
			spawnCFrame = spawnPoint.CFrame
			break
		end
	end
	if spawnCFrame == nil then
		return false, "ISLAND_SPAWN_REFERENCE_MISSING"
	end

	clone.Name = record.catalogId .. "_" .. record.instanceId
	clone:SetAttribute("BuildingInstanceId", record.instanceId)
	clone:SetAttribute("BuildingCatalogId", record.catalogId)
	clone:SetAttribute("GridX", record.x)
	clone:SetAttribute("GridZ", record.z)
	clone:SetAttribute("GridRotation", record.rotation)
	local ok, err = pcall(function()
		local pivot = gridToWorld(spawnCFrame, record, profile, cellSize)
		clone:PivotTo(pivot * CFrame.Angles(0, math.rad(record.rotation), 0))
	end)
	if not ok then
		clone:Destroy()
		warn("[PetKingdoms] Could not position building:", err)
		return false, "BUILDING_POSITION_FAILED"
	end

	for _, child in ipairs(world:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("BuildingInstanceId") == record.instanceId then
			child:Destroy()
		end
	end
	clone.Parent = world
	return true, "BUILDING_SYNCED"
end

function IslandWorldService.getArrivalCFrame(userId: number): CFrame?
	return arrivalCFrames[userId]
end

function IslandWorldService.remove(userId: number)
	local world = worldsByUserId[userId]
	if world then
		world:Destroy()
		worldsByUserId[userId] = nil
	end
	arrivalCFrames[userId] = nil
	for spawnPoint, ownerUserId in pairs(occupiedSpawns) do
		if ownerUserId == userId then
			occupiedSpawns[spawnPoint] = nil
		end
	end
end

return IslandWorldService
