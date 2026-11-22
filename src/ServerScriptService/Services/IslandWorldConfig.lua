--!strict
-- Runtime-owned Workspace configuration for the personal island prototype.
-- Values are provisional blockout defaults and can later move to a world-layout asset.
local Workspace = game:GetService("Workspace")

local IslandWorldConfig = {}

IslandWorldConfig.DEFAULTS = table.freeze({
	gridWidth = 24,
	gridDepth = 24,
	cellSize = 8,
	islandCapacity = 8,
	islandSpacing = 256,
})

local SPAWN_FOLDER_NAME = "IslandSpawnPoints"
local GENERATED_FOLDER_ATTRIBUTE = "PetKingdomsGenerated"
local ATTRIBUTE_NAMES = {
	width = "IslandGridWidth",
	depth = "IslandGridDepth",
	cellSize = "IslandGridCellSize",
}

local function isPositiveInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value < math.huge
		and value > 0
		and value == math.floor(value)
end

local function ensureAttribute(name: string, defaultValue: number, mustBeInteger: boolean): (boolean, string)
	local value = Workspace:GetAttribute(name)
	if value == nil then
		Workspace:SetAttribute(name, defaultValue)
		value = defaultValue
	end

	local valid = if mustBeInteger then isPositiveInteger(value)
		else type(value) == "number" and value == value and value < math.huge and value > 0
	if not valid then
		return false, "INVALID_WORKSPACE_ATTRIBUTE:" .. name
	end
	return true, "OK"
end

local function createSpawnPoint(parent: Folder, index: number, spacing: number)
	local column = (index - 1) % 4
	local row = math.floor((index - 1) / 4)
	local x = (column - 1.5) * spacing
	local z = (row - 0.5) * spacing

	local point = Instance.new("Part")
	point.Name = string.format("IslandSlot_%02d", index)
	point.Size = Vector3.new(4, 1, 4)
	point.CFrame = CFrame.new(x, 0, z)
	point.Anchored = true
	point.Transparency = 1
	point.CanCollide = false
	point.CanTouch = false
	point.CanQuery = false
	point.CastShadow = false
	point:SetAttribute("IslandSlotIndex", index)
	point.Parent = parent
end

local function ensureSpawnFolder(): (boolean, string)
	local existing = Workspace:FindFirstChild(SPAWN_FOLDER_NAME)
	local folder: Folder
	if existing == nil then
		folder = Instance.new("Folder")
		folder.Name = SPAWN_FOLDER_NAME
		folder:SetAttribute(GENERATED_FOLDER_ATTRIBUTE, true)
		folder.Parent = Workspace
	elseif existing:IsA("Folder") then
		folder = existing
	else
		return false, "SPAWN_POINTS_NAME_OCCUPIED_BY_NON_FOLDER"
	end

	local hasAnyPart = false
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then
			hasAnyPart = true
			break
		end
	end

	local generated = folder:GetAttribute(GENERATED_FOLDER_ATTRIBUTE) == true
	if not generated and not hasAnyPart then
		-- An empty folder is safe to initialize; folders with manually placed
		-- points are treated as owner-authored and never rearranged.
		folder:SetAttribute(GENERATED_FOLDER_ATTRIBUTE, true)
		generated = true
	end

	if generated then
		for index = 1, IslandWorldConfig.DEFAULTS.islandCapacity do
			local name = string.format("IslandSlot_%02d", index)
			local current = folder:FindFirstChild(name)
			if current == nil then
				createSpawnPoint(folder, index, IslandWorldConfig.DEFAULTS.islandSpacing)
			elseif not current:IsA("BasePart") then
				return false, "INVALID_GENERATED_SPAWN_POINT:" .. name
			end
		end
	end

	local validCount = 0
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then
			validCount += 1
		end
	end
	if validCount == 0 then
		return false, "NO_VALID_ISLAND_SPAWN_POINTS"
	end
	return true, "OK"
end

function IslandWorldConfig.configure(): (boolean, string)
	local checks = {
		{ ATTRIBUTE_NAMES.width, IslandWorldConfig.DEFAULTS.gridWidth, true },
		{ ATTRIBUTE_NAMES.depth, IslandWorldConfig.DEFAULTS.gridDepth, true },
		{ ATTRIBUTE_NAMES.cellSize, IslandWorldConfig.DEFAULTS.cellSize, false },
	}
	for _, check in ipairs(checks) do
		local ok, code = ensureAttribute(check[1], check[2], check[3])
		if not ok then
			return false, code
		end
	end

	local pointsOk, pointsCode = ensureSpawnFolder()
	if not pointsOk then
		return false, pointsCode
	end
	return true, "CONFIGURED"
end

return IslandWorldConfig
