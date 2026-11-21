--!strict
-- Server-authoritative building placement/move transaction endpoint.
-- Resource costs are intentionally absent until economy values are approved.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local BuildingCatalog = require(services:WaitForChild("BuildingCatalog"))
local PlacementValidator = require(services:WaitForChild("PlacementValidator"))
local IslandWorldService = require(services:WaitForChild("IslandWorldService"))

local IslandBuildingService = {}
local MAX_REQUEST_ID_LENGTH = 80
local MAX_CACHED_REQUESTS = 64
local resultsByUserId: { [number]: { [string]: any } } = {}
local requestOrderByUserId: { [number]: { string } } = {}

local function getRemote(): RemoteFunction
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	local remote = folder:FindFirstChild("PlaceBuilding")
	if remote == nil then
		remote = Instance.new("RemoteFunction")
		remote.Name = "PlaceBuilding"
		remote.Parent = folder
	end
	assert(remote:IsA("RemoteFunction"), "ReplicatedStorage/Remotes/PlaceBuilding must be a RemoteFunction")
	return remote
end

local function remember(userId: number, requestId: string, result: any)
	local cache = resultsByUserId[userId]
	if cache == nil then
		cache = {}
		resultsByUserId[userId] = cache
		requestOrderByUserId[userId] = {}
	end
	local order = requestOrderByUserId[userId]
	if cache[requestId] == nil then
		table.insert(order, requestId)
	end
	cache[requestId] = result
	while #order > MAX_CACHED_REQUESTS do
		local expired = table.remove(order, 1)
		cache[expired] = nil
	end
end

local function fail(code: string): any
	return { ok = false, code = code }
end

local function handleRequest(player: Player, request: any): any
	if type(request) ~= "table"
		or type(request.requestId) ~= "string"
		or #request.requestId < 1
		or #request.requestId > MAX_REQUEST_ID_LENGTH
	then
		return fail("INVALID_REQUEST_ID")
	end

	local userId = player.UserId
	local cache = resultsByUserId[userId]
	if cache and cache[request.requestId] then
		return cache[request.requestId]
	end

	local profile = IslandSessionService.getProfile(userId)
	if profile == nil then
		return fail("SESSION_NOT_READY")
	end

	local validation = PlacementValidator.validate(userId, request, profile, BuildingCatalog)
	if not validation.ok then
		local result = fail(validation.code)
		remember(userId, request.requestId, result)
		return result
	end

	local record
	local previousRecord: any = nil
	local movingIndex: number? = nil
	if request.movingInstanceId ~= nil then
		for index, existing in ipairs(profile.buildings) do
			if existing.instanceId == request.movingInstanceId then
				movingIndex = index
				previousRecord = table.clone(existing)
				record = {
					instanceId = existing.instanceId,
					catalogId = validation.catalogId,
					x = validation.x,
					z = validation.z,
					rotation = validation.rotation,
				}
				break
			end
		end
		if movingIndex == nil then
			return fail("MOVE_TARGET_NOT_FOUND")
		end
	else
		record = {
			instanceId = HttpService:GenerateGUID(false),
			catalogId = validation.catalogId,
			x = validation.x,
			z = validation.z,
			rotation = validation.rotation,
		}
	end

	if movingIndex then
		profile.buildings[movingIndex] = record
	else
		if #profile.buildings >= 256 then
			return fail("BUILDING_LIMIT_REACHED")
		end
		table.insert(profile.buildings, record)
	end

	local synced, syncCode = IslandWorldService.syncBuilding(userId, profile, record)
	if not synced then
		if movingIndex then
			-- Restore the previous saved record; no dirty revision was issued.
			for index, existing in ipairs(profile.buildings) do
				if existing.instanceId == record.instanceId then
					profile.buildings[index] = previousRecord
					break
				end
			end
		else
			table.remove(profile.buildings, #profile.buildings)
		end
		return fail(syncCode)
	end

	if not IslandSessionService.markDirty(userId) then
		if movingIndex and previousRecord then
			profile.buildings[movingIndex] = previousRecord
			IslandWorldService.syncBuilding(userId, profile, previousRecord)
		else
			table.remove(profile.buildings, #profile.buildings)
			IslandWorldService.removeBuilding(userId, record.instanceId)
		end
		return fail("SESSION_NOT_WRITABLE")
	end

	local result = {
		ok = true,
		code = "BUILDING_PLACED",
		instanceId = record.instanceId,
		catalogId = record.catalogId,
		x = record.x,
		z = record.z,
		rotation = record.rotation,
	}
	remember(userId, request.requestId, result)
	return result
end

function IslandBuildingService.start()
	getRemote().OnServerInvoke = handleRequest
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		resultsByUserId[player.UserId] = nil
		requestOrderByUserId[player.UserId] = nil
	end)
end

return IslandBuildingService
