--!strict
-- Server-side personal island blockout renderer.
-- The terrain is procedural prototype geometry. Production building models
-- are supplied separately in ServerStorage/BuildingModels/<catalogId>.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local BuildingCatalog = require(script.Parent:WaitForChild("BuildingCatalog"))
local IslandExpansion = require(script.Parent:WaitForChild("IslandExpansion"))
local KingdomBond = require(script.Parent:WaitForChild("KingdomBond"))
local IslandResourceNodeCatalog = require(script.Parent:WaitForChild("IslandResourceNodeCatalog"))
local IslandResourceNodeData = require(script.Parent:WaitForChild("IslandResourceNodeData"))
local GridMath = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Building"):WaitForChild("GridMath"))
local BuildingModelPivot = require(script.Parent:WaitForChild("BuildingModelPivot"))

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
	for index, offset in ipairs({Vector3.new(-2.3, 1.7, 0.8), Vector3.new(2.1, 1.9, -0.7), Vector3.new(-0.8, 3.8, -1.65), Vector3.new(1, 3.7, 1.45)}) do
		local leaf = makePart(tree, "LeafCluster_" .. index, Vector3.new(2.1, 2.2, 2) * scale,
			base * CFrame.new(offset * scale + Vector3.new(0, trunkHeight, 0)),
			if index % 2 == 0 then Color3.fromRGB(91, 159, 81) else Color3.fromRGB(67, 130, 72),
			Enum.Material.Grass, Enum.PartType.Ball)
		leaf.CanCollide = false
		leaf.CanQuery = false
	end
end

-- Lightweight perimeter dressing. Decorative parts never take ownership of grid cells.
local function createEdgeMeadow(world: Model, top: CFrame, sizeX: number, sizeZ: number, cellSize: number)
	local decor = Instance.new("Folder")
	decor.Name = "IslandEdgeMeadow"
	decor.Parent = world
	local patches = {
		{ -0.41, -0.14, 1 }, { 0.41, 0.12, 2 },
		{ -0.33, 0.39, 3 }, { 0.30, -0.40, 4 },
		{ -0.40, 0.05, 5 }, { 0.40, -0.15, 6 },
		{ -0.18, -0.42, 7 }, { 0.17, 0.42, 8 },
	}
	local blossomColors = {
		Color3.fromRGB(255, 191, 215),
		Color3.fromRGB(255, 229, 153),
		Color3.fromRGB(195, 177, 255),
		Color3.fromRGB(238, 245, 225),
	}
	-- Server-wide art density can be configured in Studio via Workspace attribute.
	-- 0 = essential world only, 1/default = lightweight, 2 = full prototype meadow.
	local rawDetailLevel = Workspace:GetAttribute("IslandDecorationLevel")
	local detailLevel = if type(rawDetailLevel) == "number" then math.clamp(math.floor(rawDetailLevel), 0, 2) else 1
	if detailLevel == 0 then return end
	for index, patch in ipairs(patches) do
		local center = top * CFrame.new(patch[1] * sizeX, 0, patch[2] * sizeZ)
		local bushes = if detailLevel == 2
			then { Vector3.new(-0.24, 0, 0), Vector3.new(0.22, 0, 0.13) }
			else { Vector3.new(0, 0, 0) }
		for leafIndex, offset in ipairs(bushes) do
			local bush = makePart(decor, "Bush_" .. index .. "_" .. leafIndex,
				Vector3.new(cellSize * 0.38, cellSize * 0.29, cellSize * 0.36),
				center * CFrame.new(offset * cellSize + Vector3.new(0, cellSize * 0.145, 0)),
				if leafIndex == 1 then Color3.fromRGB(80, 152, 77) else Color3.fromRGB(113, 174, 88),
				Enum.Material.Grass, Enum.PartType.Ball)
			bush.CanCollide = false
			bush.CanTouch = false
			bush.CanQuery = false
			bush.CastShadow = false
		end
		local blossoms = if detailLevel == 2
			then { Vector3.new(-0.26, 0, -0.05), Vector3.new(0.22, 0, 0.14) }
			else { Vector3.new(0.12, 0, -0.10) }
		for blossomIndex, offset in ipairs(blossoms) do
			local flower = makePart(decor, "Blossom_" .. index .. "_" .. blossomIndex,
				Vector3.new(cellSize * 0.13, cellSize * 0.13, cellSize * 0.13),
				center * CFrame.new(offset * cellSize + Vector3.new(0, cellSize * 0.30, 0)),
				blossomColors[((index + blossomIndex - 2) % #blossomColors) + 1],
				Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			flower.CanCollide = false
			flower.CanTouch = false
			flower.CanQuery = false
			flower.CastShadow = false
		end
	end
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

	-- Layered rock faces are entirely beneath the playable grass surface.
	-- Stable variations add depth without changing the island grid or collisions.
	local edgeRockTints = {
		Color3.fromRGB(112, 112, 116), Color3.fromRGB(125, 119, 116),
		Color3.fromRGB(99, 107, 111), Color3.fromRGB(119, 110, 109),
	}
	for index = 1, 8 do
		local angle = (math.pi * 2 * index) / 8
		local radiusX = sizeX * 0.42
		local radiusZ = sizeZ * 0.42
		local x = math.cos(angle) * radiusX
		local z = math.sin(angle) * radiusZ
		local scale = 0.88 + (index % 4) * 0.08
		local rockSize = Vector3.new(maxDimension * 0.12 * scale, 5 + (index % 3) * 2, maxDimension * 0.14 * scale)
		local rock = makePart(world, "Island_CliffRock_" .. tostring(index), rockSize,
			top * CFrame.new(x, -9 - (index % 2) * 2, z) * CFrame.Angles(0, angle, math.rad((index % 3 - 1) * 9)),
			edgeRockTints[((index - 1) % #edgeRockTints) + 1], Enum.Material.Rock, Enum.PartType.Ball)
		rock.CanQuery = false
		local stratum = makePart(world, "Island_CliffStratum_" .. tostring(index),
			Vector3.new(rockSize.X * 0.91, 1.15 + (index % 2) * 0.3, rockSize.Z * 0.84),
			top * CFrame.new(x * 0.94, -11.7 - (index % 2) * 1.4, z * 0.94) * CFrame.Angles(0, angle, math.rad((index % 3 - 1) * 7)),
			Color3.fromRGB(135 + (index % 3) * 6, 116 + (index % 3) * 4, 103 + (index % 3) * 3),
			Enum.Material.Slate, Enum.PartType.Ball)
		stratum.CanCollide = false
		stratum.CanTouch = false
		stratum.CanQuery = false
		stratum.CastShadow = false
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

	-- Perimeter flowers remain purely decorative and can be built over.
	createEdgeMeadow(world, top, sizeX, sizeZ, cellSize)

	-- A simple stone arrival pad is a temporary gameplay landmark.
	makePart(world, "Arrival_Pad", Vector3.new(cellSize * 2.4, 0.35, cellSize * 2.4),
		top * CFrame.new(0, 0.18, sizeZ * 0.34), Color3.fromRGB(181, 177, 160), Enum.Material.Slate)
end

local function refreshKingdomBondVisuals(world: Model, profile: any)
	local bond = KingdomBond.calculate(profile)
	if bond == nil then return end
	world:SetAttribute("KingdomBondPoints", bond.points)
	world:SetAttribute("KingdomBondStage", bond.stageId)
	world:SetAttribute("KingdomBondStageName", bond.stageName)
	world:SetAttribute("KingdomBondBuildingCount", bond.buildingCount)
	world:SetAttribute("KingdomBondTotalBuildingCount", bond.totalBuildingCount)
	world:SetAttribute("KingdomBondNextStagePoints", bond.nextStagePoints)

	local grass = world:FindFirstChild("Island_GrassTop")
	if grass and grass:IsA("BasePart") then
		local stageColors = {
			quiet = Color3.fromRGB(103, 166, 91),
			cozy = Color3.fromRGB(111, 177, 94),
			blooming = Color3.fromRGB(123, 187, 102),
			thriving = Color3.fromRGB(135, 194, 111),
		}
		grass.Color = stageColors[bond.stageId] or stageColors.quiet
	end

	local previous = world:FindFirstChild("KingdomBondDecor")
	if previous then previous:Destroy() end
	if bond.stageId == "quiet" then return end

	local decor = Instance.new("Folder")
	decor.Name = "KingdomBondDecor"
	decor.Parent = world
	local center = grass and grass:IsA("BasePart") and grass.CFrame or world:GetPivot()
	local size = grass and grass:IsA("BasePart") and grass.Size or Vector3.new(40, 4, 40)
	local function accent(name: string, position: Vector3, dimensions: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType?)
		local part = makePart(decor, name, dimensions, CFrame.new(position), color, material, shape)
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		return part
	end

	local edgeX = size.X * 0.34
	local edgeZ = size.Z * 0.34
	local groundY = center.Position.Y + size.Y * 0.5 + 0.12
	if bond.stageId == "cozy" or bond.stageId == "blooming" or bond.stageId == "thriving" then
		for index, offset in ipairs({ Vector3.new(-edgeX, 0, -edgeZ), Vector3.new(edgeX, 0, edgeZ), Vector3.new(-edgeX, 0, edgeZ) }) do
			accent("Kingdom_Flower_" .. index, center.Position + offset + Vector3.new(0, groundY - center.Position.Y, 0),
				Vector3.new(0.65, 0.9, 0.65), Color3.fromRGB(255, 190, 215), Enum.Material.Neon, Enum.PartType.Ball)
		end
	end
	if bond.stageId == "blooming" or bond.stageId == "thriving" then
		accent("Kingdom_Crystal", center.Position + Vector3.new(edgeX * 0.35, groundY - center.Position.Y + 1.1, -edgeZ * 0.2),
			Vector3.new(1.1, 2.2, 1.1), Color3.fromRGB(115, 220, 231), Enum.Material.Neon, Enum.PartType.Ball)
	end
	if bond.stageId == "thriving" then
		local banner = accent("Kingdom_Banner", center.Position + Vector3.new(-edgeX * 0.2, groundY - center.Position.Y + 2.1, edgeZ * 0.45),
			Vector3.new(0.35, 4.2, 0.35), Color3.fromRGB(255, 207, 123), Enum.Material.Metal)
		accent("Kingdom_BannerCloth", banner.Position + Vector3.new(0.9, 0.7, 0),
			Vector3.new(1.7, 1.15, 0.12), Color3.fromRGB(132, 104, 194), Enum.Material.SmoothPlastic)
	end
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
	local localX, localZ = GridMath.getFootprintCenterOffset(
		{ x = record.x, z = record.z, width = footprintWidth, depth = footprintDepth },
		profile.boundsWidth,
		profile.boundsDepth,
		cellSize
	)
	if localX == nil or localZ == nil then
		error("Invalid grid footprint for " .. tostring(record.instanceId))
	end
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
			CFrame.new(0, unit * 0.58, 0), Color3.fromRGB(105, 164, 205), Enum.Material.Slate)
		makePart(model, "Door", Vector3.new(width * 0.22, unit * 0.3, 0.12),
			CFrame.new(0, unit * 0.15, -depth * 0.365), Color3.fromRGB(91, 61, 47), Enum.Material.Wood)
		makePart(model, "Sign", Vector3.new(width * 0.38, unit * 0.13, 0.12),
			CFrame.new(0, unit * 0.82, -depth * 0.37), Color3.fromRGB(255, 218, 137), Enum.Material.SmoothPlastic)
		for index, x in ipairs({ -width * 0.30, width * 0.30 }) do
			makePart(model, "CornerBeam_" .. index, Vector3.new(width * 0.065, unit * 0.50, depth * 0.075),
				CFrame.new(x, unit * 0.25, -depth * 0.36), Color3.fromRGB(142, 97, 62), Enum.Material.Wood)
			local shutter = makePart(model, "PetWindow_" .. index, Vector3.new(width * 0.105, unit * 0.14, 0.10),
				CFrame.new(x * 0.66, unit * 0.31, -depth * 0.37), Color3.fromRGB(255, 218, 149), Enum.Material.Glass)
			shutter.CanCollide = false
		end
		makePart(model, "RoofRidge", Vector3.new(width * 0.92, unit * 0.075, depth * 0.12),
			CFrame.new(0, unit * 0.69, 0), Color3.fromRGB(73, 119, 165), Enum.Material.Slate)
		local badge = makePart(model, "PawBadge", Vector3.new(width * 0.13, unit * 0.09, 0.14),
			CFrame.new(0, unit * 0.825, -depth * 0.38), Color3.fromRGB(149, 91, 167), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		badge.CanCollide = false
	elseif catalogId == "stone_path" then
		-- A repeatable stepping-stone pattern with irregular spacing, not a giant tile.
		local stones = {
			{ -0.25, -0.24, 0.39, 0.34, 0.10, 156 },
			{ 0.23, -0.20, 0.40, 0.31, -0.08, 180 },
			{ -0.22, 0.23, 0.36, 0.34, -0.06, 170 },
			{ 0.23, 0.22, 0.41, 0.37, 0.07, 150 },
		}
		for index, stone in ipairs(stones) do
			local tint = stone[6]
			local slab = makePart(model, "PavingStone_" .. index,
				Vector3.new(width * stone[3], unit * 0.085, depth * stone[4]),
				CFrame.new(width * stone[1], unit * 0.045, depth * stone[2]) * CFrame.Angles(0, stone[5], 0),
				Color3.fromRGB(tint, tint - 3, tint - 9), Enum.Material.Slate)
			slab.TopSurface = Enum.SurfaceType.Smooth
		end
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
			makePart(model, "Post_" .. tostring(index), Vector3.new(width * 0.12, unit * 0.70, depth * 0.12),
				CFrame.new(x, unit * 0.35, 0), postColor, Enum.Material.Wood)
			local cap = makePart(model, "PostCap_" .. index, Vector3.new(width * 0.17, unit * 0.075, depth * 0.17),
				CFrame.new(x, unit * 0.73, 0), Color3.fromRGB(192, 147, 91), Enum.Material.WoodPlanks)
			cap.CanCollide = false
		end
		for index, height in ipairs({ 0.25, 0.53 }) do
			makePart(model, "Rail_" .. index, Vector3.new(width * 0.86, unit * 0.095, depth * 0.10),
				CFrame.new(0, unit * height, 0), Color3.fromRGB(157, 112, 69), Enum.Material.Wood)
		end
		local medallion = makePart(model, "CenterMedallion", Vector3.new(width * 0.16, unit * 0.16, depth * 0.13),
			CFrame.new(0, unit * 0.53, -depth * 0.035), Color3.fromRGB(221, 174, 102), Enum.Material.Wood)
		medallion.CanCollide = false
	else
		makePart(model, "Foundation", Vector3.new(width, unit * 0.16, depth),
			CFrame.new(0, unit * 0.08, 0), Color3.fromRGB(119, 91, 72), Enum.Material.WoodPlanks)
		makePart(model, "Walls", Vector3.new(width * 0.9, unit * 0.68, depth * 0.84),
			CFrame.new(0, unit * 0.5, 0), Color3.fromRGB(246, 218, 169), Enum.Material.SmoothPlastic)
		makePart(model, "Roof", Vector3.new(width * 1.08, unit * 0.2, depth * 1.02),
			CFrame.new(0, unit * 0.94, 0), Color3.fromRGB(126, 83, 139), Enum.Material.Slate)
		makePart(model, "RoofRidge", Vector3.new(width * 0.97, unit * 0.09, depth * 0.14),
			CFrame.new(0, unit * 1.08, 0), Color3.fromRGB(93, 60, 114), Enum.Material.Slate)
		makePart(model, "Door", Vector3.new(width * 0.2, unit * 0.42, 0.14),
			CFrame.new(0, unit * 0.3, -depth * 0.425), Color3.fromRGB(126, 83, 57), Enum.Material.Wood)
		local knob = makePart(model, "DoorKnob", Vector3.new(unit * 0.055, unit * 0.055, unit * 0.055),
			CFrame.new(width * 0.055, unit * 0.28, -depth * 0.433 - 0.08),
			Color3.fromRGB(246, 202, 115), Enum.Material.Metal, Enum.PartType.Ball)
		knob.CanCollide = false
		for index, x in ipairs({ -width * 0.28, width * 0.28 }) do
			makePart(model, "Window_" .. index, Vector3.new(width * 0.16, unit * 0.17, 0.12),
				CFrame.new(x, unit * 0.58, -depth * 0.425), Color3.fromRGB(122, 214, 224), Enum.Material.Glass)
			makePart(model, "WindowSill_" .. index, Vector3.new(width * 0.2, unit * 0.045, 0.2),
				CFrame.new(x, unit * 0.47, -depth * 0.45), Color3.fromRGB(155, 104, 76), Enum.Material.Wood)
		end
		for index, x in ipairs({ -width * 0.40, width * 0.40 }) do
			makePart(model, "TimberTrim_" .. index, Vector3.new(width * 0.055, unit * 0.73, depth * 0.07),
				CFrame.new(x, unit * 0.48, -depth * 0.42), Color3.fromRGB(139, 91, 68), Enum.Material.Wood)
		end
	end
	model:SetAttribute("IsFallbackBlockout", true)
	return model
end

local function getBuildingTemplate(catalogId: string, cellSize: number): Model?
	local templates = ServerStorage:FindFirstChild(BUILDING_FOLDER_NAME)
	local template = templates and templates:FindFirstChild(catalogId)
	if template and template:IsA("Model") then
		local clone = template:Clone()
		local bounds = BuildingModelPivot.normalizeToGroundCenter(clone)
		if bounds == nil then
			warn(string.format("[PetKingdoms] Building template '%s' has invalid visual bounds; using procedural fallback.", catalogId))
			clone:Destroy()
			return createFallbackBuilding(catalogId, cellSize)
		end
		clone:SetAttribute("VisualBoundsWidth", bounds.width)
		clone:SetAttribute("VisualBoundsHeight", bounds.height)
		clone:SetAttribute("VisualBoundsDepth", bounds.depth)

		local physics = BuildingModelPivot.prepareForWorld(clone)
		clone:SetAttribute("PhysicsPartCount", physics.partCount)
		clone:SetAttribute("PhysicsAnchoredCount", physics.anchoredCount)
		clone:SetAttribute("PhysicsTouchDisabledCount", physics.touchDisabledCount)

		local definition = BuildingCatalog[catalogId]
		local fit = if definition then BuildingModelPivot.checkFootprintFit(
			bounds,
			definition.footprintWidth,
			definition.footprintDepth,
			cellSize
		) else nil
		if fit == nil then
			warn(string.format("[PetKingdoms] Could not validate visual footprint for '%s'.", catalogId))
			clone:SetAttribute("VisualFootprintFits", false)
		else
			clone:SetAttribute("VisualFootprintFits", fit.fits)
			clone:SetAttribute("VisualOverhangX", fit.overhangX)
			clone:SetAttribute("VisualOverhangZ", fit.overhangZ)
			if not fit.fits then
				warn(string.format(
					"[PetKingdoms] Building template '%s' exceeds its grid footprint by X=%.2f, Z=%.2f studs (allowed tolerance %.2f). Review the source asset.",
					catalogId,
					fit.overhangX,
					fit.overhangZ,
					cellSize * 0.05
				))
			end
		end
		return clone
	end
	return createFallbackBuilding(catalogId, cellSize)
end

local function spawnResourceNodes(world: Model, spawnCFrame: CFrame, profile: any, cellSize: number)
	local folder = Instance.new("Folder")
	folder.Name = "ResourceNodes"
	folder.Parent = world

	local halfWidth = math.max(3, math.floor(profile.boundsWidth / 2) - 2)
	local halfDepth = math.max(3, math.floor(profile.boundsDepth / 2) - 2)
	local now = os.time()

	for _, definition in ipairs(IslandResourceNodeCatalog.getAll()) do
		local node = Instance.new("Model")
		node.Name = definition.id
		node:SetAttribute("ResourceNodeId", definition.id)
		node:SetAttribute("ResourceId", definition.resourceId)
		node:SetAttribute("RewardAmount", definition.reward)
		node:SetAttribute("OwnerUserId", profile.ownerUserId)
		node.Parent = folder

		local offsetX = definition.sideX * halfWidth
		local offsetZ = definition.sideZ * halfDepth
		local base = spawnCFrame * CFrame.new(offsetX * cellSize, 0, offsetZ * cellSize)
		if definition.resourceId == "wood" then
			local trunk = makePart(node, "Trunk", Vector3.new(cellSize * 0.22, cellSize * 1.1, cellSize * 0.22),
				base * CFrame.new(0, cellSize * 0.55, 0), Color3.fromRGB(116, 77, 48), Enum.Material.Wood)
			trunk.CanQuery = true
			makePart(node, "Canopy", Vector3.new(cellSize * 0.95, cellSize * 0.85, cellSize * 0.95),
				base * CFrame.new(0, cellSize * 1.3, 0), Color3.fromRGB(76, 145, 78), Enum.Material.Grass, Enum.PartType.Ball)
			for index, offset in ipairs({ Vector3.new(-0.27, 1.18, -0.23), Vector3.new(0.28, 1.31, 0.16), Vector3.new(0, 1.62, 0) }) do
				local leaf = makePart(node, "LeafCluster_" .. index, Vector3.new(cellSize * 0.5, cellSize * 0.42, cellSize * 0.5),
					base * CFrame.new(offset * cellSize),
					if index == 2 then Color3.fromRGB(103, 175, 89) else Color3.fromRGB(66, 131, 71),
					Enum.Material.Grass, Enum.PartType.Ball)
				leaf.CanCollide = false
				leaf.CanQuery = false
			end
		else
			makePart(node, "Ore", Vector3.new(cellSize * 0.72, cellSize * 0.62, cellSize * 0.72),
				base * CFrame.new(0, cellSize * 0.31, 0) * CFrame.Angles(0, math.rad(18), math.rad(8)),
				Color3.fromRGB(123, 133, 145), Enum.Material.Slate, Enum.PartType.Ball)
			makePart(node, "OreHighlight", Vector3.new(cellSize * 0.2, cellSize * 0.13, cellSize * 0.16),
				base * CFrame.new(-cellSize * 0.13, cellSize * 0.55, -cellSize * 0.12),
				Color3.fromRGB(178, 194, 207), Enum.Material.Rock, Enum.PartType.Ball)
			for index, offset in ipairs({ Vector3.new(-0.32, 0.16, 0.23), Vector3.new(0.28, 0.19, -0.23) }) do
				local fragment = makePart(node, "OreFragment_" .. index, Vector3.new(cellSize * 0.29, cellSize * 0.31, cellSize * 0.33),
					base * CFrame.new(offset * cellSize) * CFrame.Angles(0, math.rad(index * 31), math.rad(9)),
					Color3.fromRGB(137 + index * 9, 147 + index * 8, 159 + index * 7), Enum.Material.Slate, Enum.PartType.Ball)
				fragment.CanCollide = false
				fragment.CanQuery = false
			end
			for index, offset in ipairs({ Vector3.new(-0.16, 0.60, -0.15), Vector3.new(0.18, 0.48, 0.12) }) do
				local glint = makePart(node, "OreGlint_" .. index, Vector3.new(cellSize * 0.09, cellSize * 0.15, cellSize * 0.09),
					base * CFrame.new(offset * cellSize), Color3.fromRGB(152, 207, 214), Enum.Material.Glass)
				glint.CanCollide = false
				glint.CanQuery = false
			end
		end

		local promptPart = node:FindFirstChildWhichIsA("BasePart")
		local prompt: ProximityPrompt? = nil
		if promptPart then
			prompt = Instance.new("ProximityPrompt")
			prompt.Name = "GatherPrompt"
			prompt.ActionText = if definition.resourceId == "wood" then "Собрать дерево" else "Добыть камень"
			prompt.ObjectText = if definition.resourceId == "wood" then "Дерево" else "Каменная жила"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			prompt.HoldDuration = 0.8
			prompt.MaxActivationDistance = cellSize * 1.6
			prompt.RequiresLineOfSight = false
			prompt.Parent = promptPart

			-- A readable world marker makes gathering nodes discoverable before
			-- the player is close enough for the ProximityPrompt to appear.
			local marker = Instance.new("BillboardGui")
			marker.Name = "GatheringMarker"
			marker.Size = UDim2.fromOffset(132, 30)
			marker.StudsOffset = Vector3.new(0, cellSize * 1.8, 0)
			marker.MaxDistance = 64
			marker.AlwaysOnTop = true
			marker.LightInfluence = 0
			marker.Parent = promptPart
			local markerText = Instance.new("TextLabel")
			markerText.Size = UDim2.fromScale(1, 1)
			markerText.BackgroundColor3 = Color3.fromRGB(31, 35, 48)
			markerText.BackgroundTransparency = 0.08
			markerText.BorderSizePixel = 0
			markerText.Font = Enum.Font.GothamBold
			markerText.Text = if definition.resourceId == "wood" then "♣  ДЕРЕВО  +3" else "◆  КАМЕНЬ  +2"
			markerText.TextColor3 = if definition.resourceId == "wood" then Color3.fromRGB(190, 230, 166) else Color3.fromRGB(205, 218, 235)
			markerText.TextSize = 12
			markerText.Parent = marker
			local markerCorner = Instance.new("UICorner")
			markerCorner.CornerRadius = UDim.new(0, 9)
			markerCorner.Parent = markerText
			local markerStroke = Instance.new("UIStroke")
			markerStroke.Color = if definition.resourceId == "wood" then Color3.fromRGB(117, 170, 104) else Color3.fromRGB(145, 165, 188)
			markerStroke.Transparency = 0.3
			markerStroke.Thickness = 1
			markerStroke.Parent = markerText
		end

		local savedState = IslandResourceNodeData.getState(profile.resourceNodes or {}, definition.id)
		local availableAt = if savedState then savedState.availableAt else 0
		node:SetAttribute("AvailableAt", availableAt)
		if availableAt > now then
			for _, descendant in ipairs(node:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Transparency = 1
					descendant.CanTouch = false
				elseif descendant:IsA("BillboardGui") then
					-- The gathering marker is part of the node's visible state too.
					-- Hide it on initial island load just as the live respawn service does.
					descendant.Enabled = false
				end
			end
			if prompt then prompt.Enabled = false end
		end
	end
end

local function attachBuildingInteraction(model: Model, catalogId: string)
	local promptName, actionText, objectText
	if catalogId == "pet_house" then
		promptName = "PetHousePrompt"
		actionText = "Открыть коллекцию"
		objectText = "Домик питомцев"
	elseif catalogId == "main_house" then
		promptName = "MainHousePrompt"
		actionText = "Управлять королевством"
		objectText = "Главный дом"
	else
		return
	end
	if model:FindFirstChild(promptName, true) ~= nil then return end

	local promptPart = model:FindFirstChild("Door", true)
	if promptPart == nil or not promptPart:IsA("BasePart") then
		promptPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	end
	if promptPart == nil or not promptPart:IsA("BasePart") then
		warn("[PetKingdoms] Building has no BasePart for its interaction prompt:", model:GetFullName())
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = promptName
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart
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
		local footprintDefinition = BuildingCatalog[record.catalogId]
		clone:SetAttribute("FootprintWidth", footprintDefinition.footprintWidth)
		clone:SetAttribute("FootprintDepth", footprintDefinition.footprintDepth)
		clone:SetAttribute("UpgradeLevel", if type(record.upgradeLevel) == "number" then math.max(1, math.floor(record.upgradeLevel)) else 1)
		clone.Parent = world
		local pivot = gridToWorld(spawnCFrame, record, profile, cellSize)
		clone:PivotTo(pivot * CFrame.Angles(0, math.rad(record.rotation), 0))
		attachBuildingInteraction(clone, record.catalogId)
	end
end

function IslandWorldService.spawn(player: Player, profile: any): (boolean, string)
	if worldsByUserId[player.UserId] then
		return true, "ALREADY_SPAWNED"
	end
	if type(profile) ~= "table" or profile.ownerUserId ~= player.UserId then
		return false, "INVALID_PROFILE"
	end

	local baseWidth = getNumberAttribute("IslandGridWidth")
	local baseDepth = getNumberAttribute("IslandGridDepth")
	if baseWidth == nil or baseDepth == nil then
		return false, "MISSING_ISLAND_GRID_BOUNDS"
	end
	if not IslandExpansion.matchesProfileBounds(profile, baseWidth, baseDepth) then
		return false, "INVALID_EXPANSION_BOUNDS"
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
		if candidate:IsA("BasePart") and candidate.Anchored and occupiedSpawns[candidate] == nil then
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
		spawnResourceNodes(world, spawnPoint.CFrame, profile, cellSize)
		refreshKingdomBondVisuals(world, profile)
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

local function playExpansionCompletionEffect(world: Model, previousSize: Vector3, newSize: Vector3)
	local grass = world:FindFirstChild("Island_GrassTop")
	if not grass or not grass:IsA("BasePart") then return end

	local effectFolder = Instance.new("Folder")
	effectFolder.Name = "ExpansionCompletionEffect"
	effectFolder.Parent = world
	Debris:AddItem(effectFolder, 3.5)

	local topY = grass.Size.Y * 0.5 + 0.22
	local addedX = math.max(0, (newSize.X - previousSize.X) * 0.5)
	local addedZ = math.max(0, (newSize.Z - previousSize.Z) * 0.5)
	if addedX <= 0 and addedZ <= 0 then
		effectFolder:Destroy()
		return
	end

	local function pulse(name: string, size: Vector3, offset: CFrame)
		local ribbon = Instance.new("Part")
		ribbon.Name = name
		ribbon.Anchored = true
		ribbon.CanCollide = false
		ribbon.CanTouch = false
		ribbon.CanQuery = false
		ribbon.CastShadow = false
		ribbon.Material = Enum.Material.Neon
		ribbon.Color = Color3.fromRGB(133, 255, 190)
		ribbon.Transparency = 0.72
		ribbon.Size = size
		ribbon.CFrame = grass.CFrame * offset
		ribbon.Parent = effectFolder

		local glow = Instance.new("PointLight")
		glow.Color = ribbon.Color
		glow.Brightness = 1.4
		glow.Range = 10
		glow.Parent = ribbon

		local grow = TweenService:Create(ribbon, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.22,
		})
		local fade = TweenService:Create(ribbon, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.32), {
			Transparency = 1,
		})
		grow:Play()
		fade:Play()
		TweenService:Create(glow, TweenInfo.new(1.15), { Brightness = 0 }):Play()
	end

	if addedZ > 0 then
		pulse("Expansion_North", Vector3.new(newSize.X, 0.16, math.max(1, addedZ)), CFrame.new(0, topY, -(previousSize.Z * 0.5 + addedZ * 0.5)))
		pulse("Expansion_South", Vector3.new(newSize.X, 0.16, math.max(1, addedZ)), CFrame.new(0, topY, previousSize.Z * 0.5 + addedZ * 0.5))
	end
	if addedX > 0 then
		pulse("Expansion_West", Vector3.new(math.max(1, addedX), 0.16, previousSize.Z), CFrame.new(-(previousSize.X * 0.5 + addedX * 0.5), topY, 0))
		pulse("Expansion_East", Vector3.new(math.max(1, addedX), 0.16, previousSize.Z), CFrame.new(previousSize.X * 0.5 + addedX * 0.5, topY, 0))
	end

	local particleHost = effectFolder:FindFirstChildWhichIsA("BasePart")
	if particleHost == nil then return end
	local attachment = Instance.new("Attachment")
	attachment.Name = "ExpansionParticles"
	attachment.Position = Vector3.zero
	attachment.Parent = particleHost
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ExpansionSparkles"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(184, 255, 210), Color3.fromRGB(255, 220, 145))
	emitter.LightEmission = 0.8
	emitter.Lifetime = NumberRange.new(0.55, 1.1)
	emitter.Speed = NumberRange.new(5, 10)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = attachment
	emitter:Emit(42)
end

-- Rebuilds the current island from a newly persisted profile while keeping
-- the owner's assigned spawn point and arrival anchor stable.
function IslandWorldService.refresh(userId: number, player: Player, profile: any): (boolean, string)
	local currentWorld = worldsByUserId[userId]
	if currentWorld == nil then return false, "ISLAND_NOT_LOADED" end
	if type(profile) ~= "table" or profile.ownerUserId ~= userId then
		return false, "INVALID_PROFILE"
	end

	local baseWidth = getNumberAttribute("IslandGridWidth")
	local baseDepth = getNumberAttribute("IslandGridDepth")
	local cellSize = getNumberAttribute("IslandGridCellSize")
	if baseWidth == nil or baseDepth == nil then return false, "MISSING_ISLAND_GRID_BOUNDS" end
	if cellSize == nil then return false, "MISSING_ISLAND_GRID_CELL_SIZE" end
	if not IslandExpansion.matchesProfileBounds(profile, baseWidth, baseDepth) then
		return false, "INVALID_EXPANSION_BOUNDS"
	end

	local spawnPoint: BasePart? = nil
	for candidate, ownerUserId in pairs(occupiedSpawns) do
		if ownerUserId == userId and candidate:IsA("BasePart") and candidate.Parent ~= nil then
			spawnPoint = candidate
			break
		end
	end
	if spawnPoint == nil then return false, "ISLAND_SPAWN_POINT_MISSING" end

	local worldFolder = currentWorld.Parent
	if worldFolder == nil then return false, "ISLAND_WORLD_PARENT_MISSING" end
	local previousGrass = currentWorld:FindFirstChild("Island_GrassTop")
	local previousSize = if previousGrass and previousGrass:IsA("BasePart") then previousGrass.Size else Vector3.zero
	local replacement = Instance.new("Model")
	replacement.Name = "Island_" .. tostring(userId)
	replacement:SetAttribute("OwnerUserId", userId)
	replacement:SetAttribute("SchemaVersion", profile.schemaVersion)
	replacement:SetAttribute("GridWidth", profile.boundsWidth)
	replacement:SetAttribute("GridDepth", profile.boundsDepth)
	replacement:SetAttribute("GridCellSize", cellSize)

	local ok, err = pcall(function()
		createTerrain(replacement, spawnPoint.CFrame, profile.boundsWidth, profile.boundsDepth, cellSize)
		spawnBuildings(replacement, spawnPoint.CFrame, profile, cellSize)
		spawnResourceNodes(replacement, spawnPoint.CFrame, profile, cellSize)
		refreshKingdomBondVisuals(replacement, profile)
	end)
	if not ok then
		replacement:Destroy()
		warn("[PetKingdoms] Island refresh generation failed:", err)
		return false, "WORLD_GENERATION_FAILED"
	end

	-- Parent the fully-built replacement before swapping references. The old
	-- world remains intact if generation fails at any point above.
	replacement.Parent = worldFolder
	worldsByUserId[userId] = replacement
	currentWorld:Destroy()
	local newGrass = replacement:FindFirstChild("Island_GrassTop")
	if newGrass and newGrass:IsA("BasePart") then
		playExpansionCompletionEffect(replacement, previousSize, newGrass.Size)
	end
	arrivalCFrames[userId] = spawnPoint.CFrame * CFrame.new(0, 4, (profile.boundsDepth * cellSize) * 0.34)
	return true, "WORLD_REFRESHED"
end

function IslandWorldService.removeBuilding(userId: number, instanceId: string, profile: any?): boolean
	local world = worldsByUserId[userId]
	if world == nil then return false end
	for _, child in ipairs(world:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("BuildingInstanceId") == instanceId then
			child:Destroy()
			if profile ~= nil then refreshKingdomBondVisuals(world, profile) end
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
	local footprintDefinition = BuildingCatalog[record.catalogId]
	clone:SetAttribute("FootprintWidth", footprintDefinition.footprintWidth)
	clone:SetAttribute("FootprintDepth", footprintDefinition.footprintDepth)
	clone:SetAttribute("UpgradeLevel", if type(record.upgradeLevel) == "number" then math.max(1, math.floor(record.upgradeLevel)) else 1)
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
	attachBuildingInteraction(clone, record.catalogId)
	refreshKingdomBondVisuals(world, profile)
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
