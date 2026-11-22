--!strict
-- Pure, server-owned introductory quest progress. Rewards are intentionally
-- omitted until the economy balance sheet is approved.
local QuestProgressData = {}

QuestProgressData.DEFINITIONS = {
	gather_wood = {
		id = "gather_wood",
		name = "Запасы древесины",
		description = "Добудь дерево на своём острове.",
		resourceId = "wood",
		target = 3,
	},
	gather_stone = {
		id = "gather_stone",
		name = "Крепкий фундамент",
		description = "Добудь камень на своём острове.",
		resourceId = "stone",
		target = 2,
	},
}

-- Stable presentation and progression order; never depend on hash-table iteration.
local QUEST_ORDER = { "gather_wood", "gather_stone" }

local function isCount(value: any): boolean
	return type(value) == "number" and value == value
		and value ~= math.huge and value ~= -math.huge
		and value >= 0 and value == math.floor(value)
end

function QuestProgressData.create(): any
	return {
		gather_wood = { count = 0 },
		gather_stone = { count = 0 },
	}
end

function QuestProgressData.validate(state: any): (boolean, string)
	if type(state) ~= "table" then return false, "INVALID_QUEST_PROGRESS" end
	for questId, progress in pairs(state) do
		local definition = QuestProgressData.DEFINITIONS[questId]
		if definition == nil or type(progress) ~= "table"
			or not isCount(progress.count) or progress.count > definition.target then
			return false, "INVALID_QUEST_ENTRY"
		end
		for key in pairs(progress) do
			if key ~= "count" then return false, "INVALID_QUEST_ENTRY" end
		end
	end
	for questId in pairs(QuestProgressData.DEFINITIONS) do
		if state[questId] == nil then return false, "MISSING_QUEST_ENTRY" end
	end
	return true, "VALID"
end

function QuestProgressData.recordGather(state: any, resourceId: string): (any?, { string }?, string)
	local valid, reason = QuestProgressData.validate(state)
	if not valid then return nil, nil, reason end
	local nextState = table.clone(state)
	local completed = {}
	for _, questId in ipairs(QUEST_ORDER) do
		local definition = QuestProgressData.DEFINITIONS[questId]
		if definition.resourceId == resourceId then
			local previous = state[questId]
			if previous.count < definition.target then
				local nextEntry = table.clone(previous)
				nextEntry.count = math.min(definition.target, previous.count + 1)
				nextState[questId] = nextEntry
				if nextEntry.count == definition.target then
					table.insert(completed, questId)
				end
			end
		end
	end
	return nextState, completed, "RECORDED"
end

function QuestProgressData.snapshot(state: any, claims: any?): { any }
	-- Legacy island profiles may predate questProgress. Present the current
	-- introductory quest set at zero progress without mutating the saved profile.
	local source = if state == nil then QuestProgressData.create() else state
	local valid = QuestProgressData.validate(source)
	if not valid then return {} end
	local result = {}
	for _, questId in ipairs(QUEST_ORDER) do
		local definition = QuestProgressData.DEFINITIONS[questId]
		local entry = source[questId]
		local receipt = if type(claims) == "table" then claims[questId] else nil
		local rewardClaimed = entry.count >= definition.target
			and type(receipt) == "table"
			and type(receipt.rewardId) == "string"
			and receipt.rewardId ~= ""
			and type(receipt.claimedAt) == "number"
			and receipt.claimedAt == receipt.claimedAt
			and receipt.claimedAt > 0
		table.insert(result, {
			id = definition.id,
			name = definition.name,
			description = definition.description,
			count = entry.count,
			target = definition.target,
			completed = entry.count >= definition.target,
			rewardAvailable = false,
			rewardClaimed = rewardClaimed,
		})
	end
	return result
end

return QuestProgressData
