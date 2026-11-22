--!strict
-- Pure server-side resource wallet operations.
-- This module never trusts client-supplied prices or amounts.
local IslandResources = {}

IslandResources.RESOURCE_IDS = {
	wood = true,
	stone = true,
	gold = true,
	gems = true,
}

IslandResources.STARTER_BALANCES = {
	wood = 2,
	stone = 1,
	gold = 0,
	gems = 0,
}

local MAX_BALANCE = 2_000_000_000

local function isNonNegativeInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value >= 0
		and value == math.floor(value)
		and value <= MAX_BALANCE
end

function IslandResources.create(): { [string]: number }
	return table.clone(IslandResources.STARTER_BALANCES)
end

function IslandResources.validate(wallet: any): (boolean, string)
	if type(wallet) ~= "table" then
		return false, "INVALID_RESOURCE_WALLET"
	end
	for resourceId, amount in pairs(wallet) do
		if type(resourceId) ~= "string"
			or IslandResources.RESOURCE_IDS[resourceId] ~= true
			or not isNonNegativeInteger(amount)
		then
			return false, "INVALID_RESOURCE_BALANCE"
		end
	end
	return true, "VALID"
end

function IslandResources.get(wallet: any, resourceId: string): number
	if IslandResources.RESOURCE_IDS[resourceId] ~= true or type(wallet) ~= "table" then
		return 0
	end
	local amount = wallet[resourceId]
	return if isNonNegativeInteger(amount) then amount else 0
end

function IslandResources.grant(wallet: any, resourceId: string, amount: number): (boolean, string, number?)
	local valid = IslandResources.validate(wallet)
	if not valid then return false, "INVALID_RESOURCE_WALLET", nil end
	if IslandResources.RESOURCE_IDS[resourceId] ~= true then
		return false, "UNKNOWN_RESOURCE", nil
	end
	if not isNonNegativeInteger(amount) or amount == 0 then
		return false, "INVALID_AMOUNT", nil
	end
	local current = IslandResources.get(wallet, resourceId)
	if current > MAX_BALANCE - amount then
		return false, "RESOURCE_CAP_REACHED", nil
	end
	wallet[resourceId] = current + amount
	return true, "GRANTED", wallet[resourceId]
end

function IslandResources.grantMany(wallet: any, rewards: any): (boolean, string, { [string]: number }?)
	local valid = IslandResources.validate(wallet)
	if not valid then return false, "INVALID_RESOURCE_WALLET", nil end
	if type(rewards) ~= "table" then return false, "INVALID_REWARDS", nil end
	if next(rewards) == nil then return false, "EMPTY_REWARDS", nil end

	local normalizedRewards: { [string]: number } = {}
	for resourceId, amount in pairs(rewards) do
		if type(resourceId) ~= "string" or IslandResources.RESOURCE_IDS[resourceId] ~= true then
			return false, "UNKNOWN_RESOURCE", nil
		end
		if not isNonNegativeInteger(amount) or amount == 0 then
			return false, "INVALID_AMOUNT", nil
		end
		local current = IslandResources.get(wallet, resourceId)
		if current > MAX_BALANCE - amount then
			return false, "RESOURCE_CAP_REACHED", nil
		end
		normalizedRewards[resourceId] = amount
	end

	-- Validate every reward and cap before mutating any balance.
	for resourceId, amount in pairs(normalizedRewards) do
		wallet[resourceId] = IslandResources.get(wallet, resourceId) + amount
	end
	return true, "GRANTED", table.clone(wallet)
end

function IslandResources.spend(wallet: any, costs: any): (boolean, string, { [string]: number }?)
	local valid = IslandResources.validate(wallet)
	if not valid then return false, "INVALID_RESOURCE_WALLET", nil end
	if type(costs) ~= "table" then return false, "INVALID_COSTS", nil end
	if next(costs) == nil then return false, "EMPTY_COSTS", nil end

	local normalizedCosts: { [string]: number } = {}
	for resourceId, amount in pairs(costs) do
		if type(resourceId) ~= "string" or IslandResources.RESOURCE_IDS[resourceId] ~= true then
			return false, "UNKNOWN_RESOURCE", nil
		end
		if not isNonNegativeInteger(amount) or amount == 0 then
			return false, "INVALID_AMOUNT", nil
		end
		normalizedCosts[resourceId] = amount
	end

	-- Validate every balance before mutating any balance: spending is atomic.
	for resourceId, amount in pairs(normalizedCosts) do
		if IslandResources.get(wallet, resourceId) < amount then
			return false, "INSUFFICIENT_RESOURCES", nil
		end
	end

	for resourceId, amount in pairs(normalizedCosts) do
		wallet[resourceId] -= amount
	end
	return true, "SPENT", table.clone(wallet)
end

return IslandResources
