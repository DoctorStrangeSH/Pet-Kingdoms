--!strict
-- Server-only recovery worker for durable quest -> pet XP outbox entries.
-- It never accepts reward IDs, amounts, pet IDs, or progression from clients.
local Players = game:GetService("Players")

local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local PetCollectionService = require(services:WaitForChild("PetCollectionService"))
local PetProgressionCatalog = require(services:WaitForChild("PetProgressionCatalog"))
local QuestRewardRecoveryProtocol = require(services:WaitForChild("QuestRewardRecoveryProtocol"))

local QuestRewardRecoveryService = {}

local READY_TIMEOUT_SECONDS = 120
local READY_POLL_SECONDS = 0.25
local RETRY_DELAY_SECONDS = 15

type RecoveryRun = { player: Player, token: {} }
local activeRuns: { [number]: RecoveryRun } = {}
local warnedStates: { [number]: { [string]: boolean } } = {}
local warnOnce: (Player, string, string) -> ()

local function isCurrentRun(player: Player, token: {}): boolean
	local run = activeRuns[player.UserId]
	return player.Parent == Players and run ~= nil
		and run.player == player and run.token == token
end

local function waitForPlayerData(player: Player, token: {}): boolean
	local startedAt = os.clock()
	local warned = false
	while isCurrentRun(player, token) do
		if IslandSessionService.canWrite(player.UserId, player)
			and IslandSessionService.getProfile(player.UserId) ~= nil
			and PetCollectionService.isReady(player)
		then
			return true
		end
		if not warned and os.clock() - startedAt >= READY_TIMEOUT_SECONDS then
			warned = true
			warnOnce(player, "readiness", "player data is still loading; recovery will keep waiting")
		end
		task.wait(READY_POLL_SECONDS)
	end
	return false
end

warnOnce = function(player: Player, key: string, message: string)
	local byUser = warnedStates[player.UserId]
	if byUser == nil then
		byUser = {}
		warnedStates[player.UserId] = byUser
	end
	if byUser[key] then return end
	byUser[key] = true
	warn("[PetKingdoms] Quest XP recovery deferred", player.UserId, message)
end

local function clearWarning(player: Player, key: string)
	local byUser = warnedStates[player.UserId]
	if byUser ~= nil then byUser[key] = nil end
end

local function isPlayerReady(player: Player, token: {}): boolean
	return isCurrentRun(player, token)
		and IslandSessionService.canWrite(player.UserId, player)
		and PetCollectionService.isReady(player)
end

local function createProtocolHandlers(player: Player)
	return {
		getThresholds = function(version: number)
			return PetProgressionCatalog.getThresholds(version)
		end,
		grantExperience = function(petId: string, rewardId: string, amount: number, thresholds: { number })
			return PetCollectionService.grantExperienceWithProgressOnce(
				player, petId, amount, thresholds, rewardId
			)
		end,
		commitDelivery = function(rewardId: string)
			return IslandSessionService.commitQuestRewardDelivery(player.UserId, player, rewardId)
		end,
		commitSourceAcknowledgement = function(rewardId: string)
			return IslandSessionService.commitQuestRewardAcknowledgement(player.UserId, player, rewardId)
		end,
		acknowledgePetReceipt = function(rewardId: string)
			return PetCollectionService.acknowledgeExperienceReward(player, rewardId)
		end,
		commitPetAcknowledgement = function(rewardId: string)
			return IslandSessionService.commitQuestRewardPetAcknowledgement(player.UserId, player, rewardId)
		end,
	}
end

local function acknowledgeDeliveredReward(player: Player, record: any): (boolean, string)
	return QuestRewardRecoveryProtocol.finalizeDelivered(record, createProtocolHandlers(player))
end

local function deliverPendingReward(player: Player, record: any): (boolean, string)
	return QuestRewardRecoveryProtocol.deliverPending(record, createProtocolHandlers(player))
end

local function processPlayer(player: Player)
	local existing = activeRuns[player.UserId]
	if existing ~= nil and existing.player == player then return end
	local token = {}
	activeRuns[player.UserId] = { player = player, token = token }
	if not waitForPlayerData(player, token) then
		if isCurrentRun(player, token) then activeRuns[player.UserId] = nil end
		return
	end
	clearWarning(player, "readiness")

	while isPlayerReady(player, token) do
		local pending = IslandSessionService.getPendingQuestRewards(player.UserId)
		local awaitingAcknowledgement =
			IslandSessionService.getQuestRewardsAwaitingAcknowledgement(player.UserId)
		local awaitingPetAcknowledgement =
			IslandSessionService.getQuestRewardsAwaitingPetAcknowledgement(player.UserId)
		local workCount = #pending + #awaitingAcknowledgement + #awaitingPetAcknowledgement
		if workCount == 0 then break end

		local deferredCount = 0
		for _, record in ipairs(pending) do
			if not isPlayerReady(player, token) then break end
			local ok, status = deliverPendingReward(player, record)
			local warningKey = record.rewardId
			if ok then
				clearWarning(player, record.rewardId)
				print("[PetKingdoms] Quest XP reward recovered", player.UserId, record.rewardId, status)
			else
				deferredCount += 1
				warnOnce(player, warningKey, record.rewardId .. " — " .. status)
			end
		end

		for _, record in ipairs(awaitingAcknowledgement) do
			if not isPlayerReady(player, token) then break end
			local ok, status = acknowledgeDeliveredReward(player, record)
			local warningKey = record.rewardId
			if ok then
				clearWarning(player, record.rewardId)
				print("[PetKingdoms] Quest XP receipt acknowledged", player.UserId, record.rewardId, status)
			else
				deferredCount += 1
				warnOnce(player, warningKey, record.rewardId .. " — " .. status)
			end
		end

		for _, record in ipairs(awaitingPetAcknowledgement) do
			if not isPlayerReady(player, token) then break end
			local ok, status = acknowledgeDeliveredReward(player, record)
			local warningKey = record.rewardId
			if ok then
				clearWarning(player, record.rewardId)
				print("[PetKingdoms] Quest XP pet receipt finalized", player.UserId, record.rewardId, status)
			else
				deferredCount += 1
				warnOnce(player, warningKey, record.rewardId .. " — " .. status)
			end
		end

		if not isCurrentRun(player, token) then break end
		-- Avoid a hot loop during DataStore outages, configuration gaps, or invalid targets.
		if deferredCount > 0 then task.wait(RETRY_DELAY_SECONDS) else task.wait(READY_POLL_SECONDS) end
	end

	if isCurrentRun(player, token) then
		activeRuns[player.UserId] = nil
	end
end

function QuestRewardRecoveryService.start()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(processPlayer, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local run = activeRuns[player.UserId]
		if run ~= nil and run.player == player then
			activeRuns[player.UserId] = nil
		end
		warnedStates[player.UserId] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(processPlayer, player)
	end
end

return QuestRewardRecoveryService
