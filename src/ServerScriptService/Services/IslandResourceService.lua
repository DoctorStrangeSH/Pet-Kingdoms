--!strict
-- Server-only resource wallet facade. Gameplay services call this module;
-- clients never submit balances, rewards, or prices directly.
local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local IslandResources = require(services:WaitForChild("IslandResources"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes == nil then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end
local resourceUpdate = remotes:FindFirstChild("IslandResourceUpdate") :: RemoteEvent?
if resourceUpdate == nil then
	resourceUpdate = Instance.new("RemoteEvent")
	resourceUpdate.Name = "IslandResourceUpdate"
	resourceUpdate.Parent = remotes
end
local resourceRequest = remotes:FindFirstChild("IslandResourceRequest") :: RemoteFunction?
if resourceRequest == nil then
	resourceRequest = Instance.new("RemoteFunction")
	resourceRequest.Name = "IslandResourceRequest"
	resourceRequest.Parent = remotes
end

local function snapshot(profile: any): { [string]: number }
	return {
		wood = IslandResources.get(profile.resources, "wood"),
		stone = IslandResources.get(profile.resources, "stone"),
		gold = IslandResources.get(profile.resources, "gold"),
		gems = IslandResources.get(profile.resources, "gems"),
	}
end

resourceRequest.OnServerInvoke = function(player: Player, action: any)
	if action ~= "Get" then return false, "UNKNOWN_ACTION" end
	if not IslandSessionService.canWrite(player.UserId, player) then
		return false, "SESSION_NOT_WRITABLE"
	end
	local profile = IslandSessionService.getProfile(player.UserId)
	if profile == nil then return false, "SESSION_NOT_READY" end
	return true, snapshot(profile), profile.revision
end

local IslandResourceService = {}

-- Publish a snapshot after another server-side service commits a larger
-- profile transaction that already includes the wallet mutation. This does not
-- mutate balances or increment the profile revision.
function IslandResourceService.publishSnapshot(
	userId: number,
	code: string
): boolean
	local profile = IslandSessionService.getProfile(userId)
	if profile == nil then return false end
	local player = Players:GetPlayerByUserId(userId)
	if player == nil or not IslandSessionService.canWrite(userId, player) then return false end
	resourceUpdate:FireClient(player, snapshot(profile), nil, nil, code)
	return true
end

function IslandResourceService.getBalance(userId: number, resourceId: string): number?
	local profile = IslandSessionService.getProfile(userId)
	if profile == nil then return nil end
	return IslandResources.get(profile.resources, resourceId)
end

function IslandResourceService.grant(userId: number, resourceId: string, amount: number): (boolean, string, number?)
	local profile = IslandSessionService.getProfile(userId)
	if profile == nil then return false, "SESSION_NOT_READY", nil end
	local before = table.clone(profile.resources)
	local granted, code, balance = IslandResources.grant(profile.resources, resourceId, amount)
	if not granted then return false, code, nil end
	if not IslandSessionService.markDirty(userId) then
		profile.resources = before
		return false, "SESSION_NOT_WRITABLE", nil
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		resourceUpdate:FireClient(player, snapshot(profile), resourceId, amount, code)
	end
	return true, code, balance
end

function IslandResourceService.grantMany(userId: number, rewards: any): (boolean, string, { [string]: number }?)
	local profile = IslandSessionService.getProfile(userId)
	if profile == nil then return false, "SESSION_NOT_READY", nil end
	local before = table.clone(profile.resources)
	local granted, code = IslandResources.grantMany(profile.resources, rewards)
	if not granted then return false, code, nil end
	if not IslandSessionService.markDirty(userId) then
		profile.resources = before
		return false, "SESSION_NOT_WRITABLE", nil
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		resourceUpdate:FireClient(player, snapshot(profile), nil, nil, code)
	end
	return true, code, snapshot(profile)
end

function IslandResourceService.spend(userId: number, costs: any): (boolean, string, { [string]: number }?)
	local profile = IslandSessionService.getProfile(userId)
	if profile == nil then return false, "SESSION_NOT_READY", nil end
	local before = table.clone(profile.resources)
	local spent, code, balances = IslandResources.spend(profile.resources, costs)
	if not spent then return false, code, nil end
	if not IslandSessionService.markDirty(userId) then
		profile.resources = before
		return false, "SESSION_NOT_WRITABLE", nil
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		resourceUpdate:FireClient(player, snapshot(profile), nil, nil, code)
	end
	return true, code, balances
end

return IslandResourceService
