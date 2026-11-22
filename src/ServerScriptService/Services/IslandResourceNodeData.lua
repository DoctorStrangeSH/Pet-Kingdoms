--!strict
-- Serializable resource-node cooldown state. No Roblox Instances or DataStore calls.

local Catalog = require(script.Parent:WaitForChild("IslandResourceNodeCatalog"))

local IslandResourceNodeData = {}

local function isInteger(value: any): boolean
	return type(value) == "number" and value == value
		and value ~= math.huge and value ~= -math.huge
		and value == math.floor(value)
end

function IslandResourceNodeData.validate(states: any): (boolean, string)
	if type(states) ~= "table" then return false, "NOT_TABLE" end
	local count = 0
	local highest = 0
	local seen: { [string]: boolean } = {}
	for key, state in pairs(states) do
		if not isInteger(key) or key < 1 or type(state) ~= "table" then
			return false, "INVALID_ENTRY"
		end
		count += 1
		highest = math.max(highest, key)
		local definition = type(state.nodeId) == "string" and Catalog.get(state.nodeId) or nil
		if definition == nil or seen[state.nodeId] == true
			or state.resourceId ~= definition.resourceId
			or not isInteger(state.availableAt) or state.availableAt < 0
			or not isInteger(state.lastGatheredAt) or state.lastGatheredAt < 0
			or state.availableAt < state.lastGatheredAt
			or state.availableAt - state.lastGatheredAt > Catalog.RESPAWN_SECONDS
		then
			return false, "INVALID_ENTRY"
		end
		seen[state.nodeId] = true
	end
	if count ~= highest then return false, "SPARSE_LIST" end
	if count > #Catalog.getAll() then return false, "TOO_MANY_NODES" end
	return true, "VALID"
end

function IslandResourceNodeData.getState(states: any, nodeId: string): any?
	for _, state in ipairs(states or {}) do
		if state.nodeId == nodeId then return state end
	end
	return nil
end

function IslandResourceNodeData.recordGather(
	states: any,
	nodeId: string,
	now: number
): ({ any }?, number?, string)
	local valid = IslandResourceNodeData.validate(states)
	if not valid then return nil, nil, "INVALID_NODE_STATES" end
	local definition = Catalog.get(nodeId)
	if definition == nil then return nil, nil, "UNKNOWN_NODE" end
	if not isInteger(now) or now < 0 then return nil, nil, "INVALID_TIME" end

	local nextStates = {}
	local found = false
	local availableAt = now + Catalog.RESPAWN_SECONDS
	for _, state in ipairs(states) do
		if state.nodeId == nodeId then
			found = true
			if state.availableAt > now then return nil, state.availableAt, "NODE_COOLDOWN" end
			table.insert(nextStates, {
				nodeId = nodeId,
				resourceId = definition.resourceId,
				lastGatheredAt = now,
				availableAt = availableAt,
			})
		else
			table.insert(nextStates, table.clone(state))
		end
	end
	if not found then
		table.insert(nextStates, {
			nodeId = nodeId,
			resourceId = definition.resourceId,
			lastGatheredAt = now,
			availableAt = availableAt,
		})
	end
	return nextStates, availableAt, "RECORDED"
end

return IslandResourceNodeData
