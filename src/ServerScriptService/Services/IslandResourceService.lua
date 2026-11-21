--!strict
-- Server-only resource wallet facade. Gameplay services call this module;
-- clients never submit balances, rewards, or prices directly.
local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local IslandResources = require(services:WaitForChild("IslandResources"))

local IslandResourceService = {}

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
	return true, code, balance
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
	return true, code, balances
end

return IslandResourceService
