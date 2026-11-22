--!strict
-- Server-authoritative building placement/move transaction endpoint.
-- New placements pay server-owned catalog costs; moves remain free.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local BuildingCatalog = require(services:WaitForChild("BuildingCatalog"))
local PlacementValidator = require(services:WaitForChild("PlacementValidator"))
local IslandWorldService = require(services:WaitForChild("IslandWorldService"))
local IslandResourceService = require(services:WaitForChild("IslandResourceService"))
local IslandResources = require(services:WaitForChild("IslandResources"))

local IslandBuildingService = {}
local MAX_REQUEST_ID_LENGTH = 80
local MAX_CACHED_REQUESTS = 64
local REQUEST_BUCKET_CAPACITY = 12
local REQUEST_REFILL_PER_SECOND = 4
local requestBucketsByUserId: { [number]: { tokens: number, updatedAt: number } } = {}
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

local function remember(userId: number, requestId: string, fingerprint: string, result: any)
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
	cache[requestId] = { fingerprint = fingerprint, result = result }
	while #order > MAX_CACHED_REQUESTS do
		local expired = table.remove(order, 1)
		cache[expired] = nil
	end
end

local function makeFingerprint(request: any): (string, string)
	local action = if request.action == "demolish" then "demolish"
		elseif request.movingInstanceId ~= nil then "move" else "place"
	local values = {
		action,
		tostring(request.instanceId or ""),
		tostring(request.catalogId or ""),
		tostring(request.x or ""),
		tostring(request.z or ""),
		tostring(request.rotation or ""),
		tostring(request.movingInstanceId or ""),
	}
	local encoded = {}
	for _, value in ipairs(values) do
		table.insert(encoded, tostring(#value) .. ":" .. value)
	end
	return table.concat(encoded), action
end

local function fail(code: string): any
	return { ok = false, code = code }
end

-- Token bucket protects the server transaction path from remote spam.
-- Cached idempotent retries are returned before charging another token.
local function allowRequest(userId: number): boolean
	local now = os.clock()
	local bucket = requestBucketsByUserId[userId]
	if bucket == nil then
		bucket = {
			tokens = REQUEST_BUCKET_CAPACITY,
			updatedAt = now,
		}
		requestBucketsByUserId[userId] = bucket
	end

	local elapsed = math.max(0, now - bucket.updatedAt)
	bucket.tokens = math.min(
		REQUEST_BUCKET_CAPACITY,
		bucket.tokens + elapsed * REQUEST_REFILL_PER_SECOND
	)
	bucket.updatedAt = now

	if bucket.tokens < 1 then
		return false
	end

	bucket.tokens -= 1
	return true
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
	if not IslandSessionService.canWrite(userId, player) then
		return fail("SESSION_NOT_WRITABLE")
	end
	if IslandSessionService.isProfileMutationBusy(userId) then
		return fail("BUILDING_OPERATION_BUSY")
	end
	local fingerprint, operationAction = makeFingerprint(request)
	local cache = resultsByUserId[userId]
	local cached = cache and cache[request.requestId]
	if cached ~= nil then
		if cached.fingerprint ~= fingerprint then return fail("REQUEST_ID_CONFLICT") end
		return cached.result
	end

	local activeProfile = IslandSessionService.getProfile(userId)
	if activeProfile == nil then return fail("SESSION_NOT_READY") end
	local durableResult, journalStatus = IslandSessionService.findBuildingOperation(
		userId, request.requestId, fingerprint, os.time()
	)
	if journalStatus == "DUPLICATE" and durableResult ~= nil then
		remember(userId, request.requestId, fingerprint, durableResult)
		return durableResult
	elseif journalStatus == "IN_PROGRESS" then
		return fail("BUILDING_OPERATION_IN_PROGRESS")
	elseif journalStatus ~= "NOT_FOUND" then
		return fail(journalStatus)
	end

	if not allowRequest(userId) then
		return fail("RATE_LIMITED")
	end

	if type(request.action) == "string" then
		if request.action ~= "demolish" then
			return fail("UNKNOWN_BUILDING_ACTION")
		end
		if type(request.instanceId) ~= "string" or request.instanceId == "" then
			return fail("INVALID_BUILDING_ID")
		end
		local profileForRemoval = IslandSessionService.getProfile(userId)
		if profileForRemoval == nil then
			return fail("SESSION_NOT_READY")
		end
		local removeIndex = nil
		local removedRecord = nil
		for index, existing in ipairs(profileForRemoval.buildings) do
			if existing.instanceId == request.instanceId then
				removeIndex = index
				removedRecord = table.clone(existing)
				break
			end
		end
		if removeIndex == nil or removedRecord == nil then
			return fail("BUILDING_NOT_FOUND")
		end
		if removedRecord.catalogId == "main_house" then
			return fail("MAIN_HOUSE_PROTECTED")
		end
		local previousLedger = table.clone(profileForRemoval.buildingOperations or {})
		local previousRevision = profileForRemoval.revision
		table.remove(profileForRemoval.buildings, removeIndex)
		local removedFromWorld = IslandWorldService.removeBuilding(userId, removedRecord.instanceId, profileForRemoval)
		if not removedFromWorld then
			table.insert(profileForRemoval.buildings, removeIndex, removedRecord)
			return fail("BUILDING_WORLD_NOT_FOUND")
		end
		local removalResult = {
			ok = true,
			code = "BUILDING_DEMOLISHED",
			instanceId = removedRecord.instanceId,
		}
		local committed, commitCode = IslandSessionService.commitBuildingOperation(
			userId, player, request.requestId, fingerprint, operationAction, removalResult
		)
		if not committed then
			table.insert(profileForRemoval.buildings, removeIndex, removedRecord)
			IslandWorldService.syncBuilding(userId, profileForRemoval, removedRecord)
			if profileForRemoval.revision > previousRevision then
				profileForRemoval.buildingOperations = previousLedger
				if IslandSessionService.canWrite(userId, player) then
					IslandSessionService.markDirty(userId)
				end
			end
			return fail(commitCode)
		end
		remember(userId, request.requestId, fingerprint, removalResult)
		return removalResult
	end

	local profile = IslandSessionService.getProfile(userId)
	if profile == nil then
		return fail("SESSION_NOT_READY")
	end

	local validation = PlacementValidator.validate(userId, request, profile, BuildingCatalog)
	if not validation.ok then
		local result = fail(validation.code)
		remember(userId, request.requestId, fingerprint, result)
		return result
	end

	local isMoving = request.movingInstanceId ~= nil
	if not isMoving and #profile.buildings >= 256 then
		return fail("BUILDING_LIMIT_REACHED")
	end

	local definition = BuildingCatalog[validation.catalogId :: string]
	local previousLedger = table.clone(profile.buildingOperations or {})
	local previousRevision = profile.revision

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

	-- Charge and building record are committed under one profile revision.
	-- No yielding operation occurs between these mutations and markDirty.
	local resourcesBefore = table.clone(profile.resources)
	local charged = false
	if not isMoving and definition.cost ~= nil then
		local paid, paymentCode = IslandResources.spend(profile.resources, definition.cost)
		if not paid then
			local result = fail(paymentCode)
			remember(userId, request.requestId, fingerprint, result)
			return result
		end
		charged = true
	end

	if movingIndex then
		profile.buildings[movingIndex] = record
	else
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
		if charged then profile.resources = resourcesBefore end
		return fail(syncCode)
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
	local committed, commitCode = IslandSessionService.commitBuildingOperation(
		userId, player, request.requestId, fingerprint, operationAction, result
	)
	if not committed then
		if movingIndex and previousRecord then
			profile.buildings[movingIndex] = previousRecord
			IslandWorldService.syncBuilding(userId, profile, previousRecord)
		else
			table.remove(profile.buildings, #profile.buildings)
			IslandWorldService.removeBuilding(userId, record.instanceId)
		end
		if charged then profile.resources = resourcesBefore end
		if profile.revision > previousRevision then
			profile.buildingOperations = previousLedger
			if IslandSessionService.canWrite(userId, player) then
				IslandSessionService.markDirty(userId)
			end
		end
		return fail(commitCode)
	end

	if charged then
		IslandResourceService.publishSnapshot(userId, "SPENT")
	end
	remember(userId, request.requestId, fingerprint, result)
	return result
end

function IslandBuildingService.start()
	getRemote().OnServerInvoke = handleRequest
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		resultsByUserId[player.UserId] = nil
		requestOrderByUserId[player.UserId] = nil
		requestBucketsByUserId[player.UserId] = nil
	end)
end

return IslandBuildingService
