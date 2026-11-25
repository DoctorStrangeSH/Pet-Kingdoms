--!strict
-- Pure validation for server-owned building upgrade plans.
local BuildingUpgradeRules = {}

function BuildingUpgradeRules.plan(definition: any, building: any, wallet: any): (any?, string)
	if type(definition) ~= "table" or type(building) ~= "table"
		or type(definition.maxUpgradeLevel) ~= "number"
	then
		return nil, "UPGRADE_NOT_AVAILABLE"
	end

	local currentLevel = if type(building.upgradeLevel) == "number"
		and building.upgradeLevel == building.upgradeLevel
		and building.upgradeLevel ~= math.huge
		and building.upgradeLevel ~= -math.huge
		then math.max(1, math.floor(building.upgradeLevel))
		else 1
	local targetLevel = currentLevel + 1
	if targetLevel > definition.maxUpgradeLevel then return nil, "MAX_UPGRADE_LEVEL" end

	local cost = definition.upgradeCosts and definition.upgradeCosts[targetLevel]
	if type(cost) ~= "table" or next(cost) == nil then return nil, "UPGRADE_NOT_AVAILABLE" end
	if type(wallet) ~= "table" then return nil, "RESOURCES_NOT_READY" end

	for resourceId, amount in pairs(cost) do
		if type(resourceId) ~= "string" or type(amount) ~= "number"
			or amount <= 0 or amount ~= math.floor(amount)
			or amount == math.huge or amount == -math.huge
		then
			return nil, "INVALID_UPGRADE_COST"
		end
		if type(wallet[resourceId]) ~= "number" or wallet[resourceId] < amount then
			return nil, "NOT_ENOUGH_" .. string.upper(resourceId)
		end
	end

	return {
		currentLevel = currentLevel,
		targetLevel = targetLevel,
		cost = table.clone(cost),
	}, "UPGRADE_AVAILABLE"
end

return BuildingUpgradeRules
