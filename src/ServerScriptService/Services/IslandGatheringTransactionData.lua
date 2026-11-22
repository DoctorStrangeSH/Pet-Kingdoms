--!strict
-- Pure, atomic transformation for one island resource gathering transaction.
-- It composes wallet, node cooldown, and quest progress before the caller mutates a profile.
local services = script.Parent
local IslandResourceNodeCatalog = require(services:WaitForChild("IslandResourceNodeCatalog"))
local IslandResourceNodeData = require(services:WaitForChild("IslandResourceNodeData"))
local IslandResources = require(services:WaitForChild("IslandResources"))
local QuestProgressData = require(services:WaitForChild("QuestProgressData"))

local IslandGatheringTransactionData = {}

export type Result = {
	resources: { [string]: number },
	resourceNodes: { any },
	questProgress: any,
	completedQuestIds: { string },
	availableAt: number,
}

function IslandGatheringTransactionData.apply(profile: any, nodeId: string, now: number): (Result?, string, number?)
	if type(profile) ~= "table" then return nil, "INVALID_PROFILE", nil end
	local definition = IslandResourceNodeCatalog.get(nodeId)
	if definition == nil then return nil, "UNKNOWN_NODE", nil end

	local wallet = if profile.resources == nil then IslandResources.create() else table.clone(profile.resources)
	local walletValid = IslandResources.validate(wallet)
	if not walletValid then return nil, "INVALID_RESOURCE_WALLET", nil end

	local questProgress = if profile.questProgress == nil
		then QuestProgressData.create()
		else profile.questProgress
	local questsValid, questCode = QuestProgressData.validate(questProgress)
	if not questsValid then return nil, questCode, nil end

	local nextNodes, availableAt, nodeCode = IslandResourceNodeData.recordGather(
		profile.resourceNodes or {},
		nodeId,
		now
	)
	if nextNodes == nil then return nil, nodeCode, availableAt end

	local granted, grantCode = IslandResources.grant(wallet, definition.resourceId, definition.reward)
	if not granted then return nil, grantCode, nil end

	local nextQuestProgress, completedQuestIds, progressCode = QuestProgressData.recordGather(
		questProgress,
		definition.resourceId
	)
	if nextQuestProgress == nil then return nil, progressCode, nil end

	return {
		resources = wallet,
		resourceNodes = nextNodes,
		questProgress = nextQuestProgress,
		completedQuestIds = completedQuestIds,
		availableAt = availableAt :: number,
	}, "GATHER_READY", availableAt
end

return IslandGatheringTransactionData
