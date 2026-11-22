--!strict
-- Read-only expansion preview endpoint. Purchasing remains disabled until
-- economy costs and unlock conditions are approved.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local IslandExpansion = require(services:WaitForChild("IslandExpansion"))

local IslandExpansionService = {}
local REMOTE_NAME = "GetIslandExpansionPreview"
local REQUEST_INTERVAL = 0.5
local lastRequestAt: { [number]: number } = {}

local function getRemote(): RemoteFunction
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	local existing = folder:FindFirstChild(REMOTE_NAME)
	if existing == nil then
		local remote = Instance.new("RemoteFunction")
		remote.Name = REMOTE_NAME
		remote.Parent = folder
		existing = remote
	end
	assert(existing:IsA("RemoteFunction"), "Expansion preview remote has an invalid class")
	return existing
end

local function handleRequest(player: Player): any
	local now = os.clock()
	local previous = lastRequestAt[player.UserId] or 0
	if now - previous < REQUEST_INTERVAL then
		return { ok = false, code = "RATE_LIMITED" }
	end
	lastRequestAt[player.UserId] = now

	if not IslandSessionService.canWrite(player.UserId, player) then
		return { ok = false, code = "SESSION_NOT_WRITABLE" }
	end
	local profile = IslandSessionService.getProfile(player.UserId)
	if type(profile) ~= "table" then
		return { ok = false, code = "SESSION_NOT_READY" }
	end

	local baseWidth = Workspace:GetAttribute("IslandGridWidth")
	local baseDepth = Workspace:GetAttribute("IslandGridDepth")
	if type(baseWidth) ~= "number" or type(baseDepth) ~= "number" then
		return { ok = false, code = "MISSING_ISLAND_GRID_BOUNDS" }
	end

	local currentLevel = if profile.expansionLevel == nil then 0 else profile.expansionLevel
	if not IslandExpansion.matchesProfileBounds(profile, baseWidth, baseDepth) then
		return { ok = false, code = "INVALID_EXPANSION_BOUNDS" }
	end
	local nextBounds = IslandExpansion.getNextBounds(baseWidth, baseDepth, currentLevel)
	return {
		ok = true,
		currentLevel = currentLevel,
		currentWidth = profile.boundsWidth,
		currentDepth = profile.boundsDepth,
		nextLevel = if nextBounds then currentLevel + 1 else nil,
		nextWidth = if nextBounds then nextBounds.width else nil,
		nextDepth = if nextBounds then nextBounds.depth else nil,
		maxLevel = IslandExpansion.MAX_LEVEL,
		canExpand = nextBounds ~= nil,
		purchaseAvailable = false,
		purchaseStatus = "ECONOMY_NOT_APPROVED",
	}
end

function IslandExpansionService.start()
	local remote = getRemote()
	remote.OnServerInvoke = handleRequest
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastRequestAt[player.UserId] = nil
	end)
end

return IslandExpansionService
