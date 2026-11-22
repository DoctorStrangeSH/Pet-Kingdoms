--!strict
-- Server-only recovery worker for durable quest -> pet XP outbox entries.
-- It never accepts reward IDs, amounts, pet IDs, or progression from clients.
local Players = game:GetService("Players")

local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local PetCollectionService = require(services:WaitForChild("PetCollectionService"))
local PetProgressionCatalog = require(services:WaitForChild("PetProgressionCatalog"))

local QuestRewardRecoveryService = {}

local READY_TIMEOUT_SECONDS = 120
local READY_POLL_SECONDS = 0.25
local RETRY_DELAY_SECONDS = 15

type RecoveryRun = { player: Player, token: {} }
local activeRuns: { [number]: RecoveryRun } = {}
local warnedStates: { [number]: { [string]: boolean } } = {}

local function isCurrentRun(player: Player, token: {}): boolean
	local run = activeRuns[player.UserId]
	return player.Parent == Players and run ~= nil
		and run.player == player and run.token == token
end

local function waitForPlayerData(player: Player, token: {}): boolean
	local deadline = os.clock() + READY_TIMEOUT_SECONDS
	while os.clock() < deadline do
		if not isCurrentRun(player, token) then return false end
		if IslandSessionService.canWrite(player.UserId, player)
			and IslandSessionService.getProfile(player.UserId) ~= nil
			and PetCollectionService.isReady(player)
		then
			return true
		end
		task.wait(READY_POLL_SECONDS)
	end
	return false
end

local function warnOnce(player: Player, key: string, message: string)
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

local function acknowledgeDeliveredReward(player: Player, record: any): (boolean, string)
	-- First persist the source acknowledgement. Only then may the pet receipt
	-- start its finite retention window; this prevents a prolonged source-store
	-- outage from expiring the only pet-side deduplication receipt.
	local sourceAcknowledged, sourceStatus = IslandSessionService.commitQuestRewardAcknowledgement(
		player.UserId,
		player,
		record.rewardId
	)
	if not sourceAcknowledged then
		return false, "SOURCE_ACK_FAILED:" .. sourceStatus
	end

	local petAcknowledged, petStatus = PetCollectionService.acknowledgeExperienceReward(
		player,
		record.rewardId
	)
	-- A missing receipt is safe to finalize only now: the durable source
	-- acknowledgement proves the XP write was already confirmed.
	if not petAcknowledged and petStatus ~= "RECEIPT_NOT_FOUND" then
		return false, "PET_RECEIPT_ACK_FAILED:" .. petStatus
	end

	local petMarker, markerStatus = IslandSessionService.commitQuestRewardPetAcknowledgement(
		player.UserId,
		player,
		record.rewardId
	)
	if not petMarker then
		return false, "PET_ACK_MARKER_FAILED:" .. markerStatus
	end
	return true, markerStatus
end

local function deliverPendingReward(player: Player, record: any): (boolean, string)
	local thresholds, configStatus = PetProgressionCatalog.getThresholds(record.progressionVersion)
	if thresholds == nil then
		return false, configStatus
	end

	-- The exact pet ID, XP amount, progression version, and reward ID all come
	-- from the durable server-created outbox record. Never recompute these on retry.
	local granted, grantStatus = PetCollectionService.grantExperienceWithProgressOnce(
		player,
		record.petId,
		record.amount,
		thresholds,
		record.rewardId
	)
	if not granted then
		return false, "PET_XP_GRANT_FAILED:" .. grantStatus
	end

	-- Mark delivery only after the pet DataStore has confirmed the idempotent XP write.
	local delivered, deliveryStatus = IslandSessionService.commitQuestRewardDelivery(
		player.UserId,
		player,
		record.rewardId
	)
	if not delivered then
		return false, "SOURCE_DELIVERY_COMMIT_FAILED:" .. deliveryStatus
	end

	return acknowledgeDeliveredReward(player, record)
end

local function processPlayer(player: Player)
	local token = {}
	activeRuns[player.UserId] = { player = player, token = token }
	if not waitForPlayerData(player, token) then
		if isCurrentRun(player, token) then
			warnOnce(player, "readiness", "player data did not become ready within the recovery window")
			activeRuns[player.UserId] = nil
		end
		return
	end

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
