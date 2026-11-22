--!strict
-- Server-only recovery of persisted pet hatch transactions after player data loads.
-- Never accepts recovery instructions or transaction details from clients.
local Players = game:GetService("Players")

local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local PetCollectionService = require(services:WaitForChild("PetCollectionService"))
local PetHatchingRecoveryData = require(services:WaitForChild("PetHatchingRecoveryData"))

local PetHatchingRecoveryService = {}

-- Pet collection load itself can wait up to 120 seconds for the island lease.
-- The recovery poll must not expire first during a delayed but valid login.
local READY_TIMEOUT_SECONDS = PetHatchingRecoveryData.RECOVERY_READY_TIMEOUT_SECONDS
local READY_POLL_SECONDS = 0.25
type RecoveryRun = { player: Player, token: {} }
local activeRuns: { [number]: RecoveryRun } = {}

assert(PetHatchingRecoveryData.hasSufficientReadinessWindow(),
	"[PetKingdoms] Hatch recovery readiness window must exceed collection load wait.")

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

local function recoverTransaction(player: Player, record: any): (boolean, string)
	local action, actionStatus = PetHatchingRecoveryData.getNextAction(record)
	if action == nil then return false, actionStatus end
	if action == "COMPLETE" then return true, actionStatus end

	-- Reserve capacity before charging. A full collection leaves PREPARED/CHARGED
	-- untouched so no player pays for an unstoreable pet.
	local reserved, reserveStatus = PetCollectionService.reservePetSlot(
		player,
		record.speciesId,
		record.rarityTier,
		record.acquisitionId
	)
	if not reserved then return false, "CAPACITY_RESERVATION_FAILED:" .. reserveStatus end

	if action == "CHARGE" then
		local charged, chargeStatus = IslandSessionService.applyHatchOperation(
			player.UserId,
			"CHARGE",
			record.transactionId
		)
		if not charged then return false, "CHARGE_FAILED:" .. chargeStatus end
	end

	-- Reusing the durable acquisition ID is essential: if the collection write
	-- succeeded but its response was lost, this call returns ALREADY_ACQUIRED.
	local granted, grantStatus = PetCollectionService.grantPet(
		player,
		record.speciesId,
		record.rarityTier,
		record.acquisitionId
	)
	if not granted then return false, "PET_GRANT_FAILED:" .. grantStatus end

	local completed, completeStatus = IslandSessionService.applyHatchOperation(
		player.UserId,
		"GRANT",
		record.transactionId
	)
	if not completed then return false, "JOURNAL_COMPLETION_FAILED:" .. completeStatus end

	return true, if grantStatus == "ALREADY_ACQUIRED" then "RECOVERED_EXISTING_PET" else "RECOVERED_NEW_PET"
end

local function recoverPlayer(player: Player)
	local token = {}
	activeRuns[player.UserId] = { player = player, token = token }
	if not waitForPlayerData(player, token) then
		if isCurrentRun(player, token) then
			warn("[PetKingdoms] Hatch recovery skipped: player data did not become ready", player.UserId)
			activeRuns[player.UserId] = nil
		end
		return
	end

	local profile = IslandSessionService.getProfile(player.UserId)
	if profile == nil then
		if isCurrentRun(player, token) then activeRuns[player.UserId] = nil end
		return
	end

	-- Work from a snapshot; each operation may replace the live profile.
	local pending = {}
	for _, record in ipairs(profile.hatchTransactions or {}) do
		if record.state ~= "GRANTED" then
			local copy = table.clone(record)
			copy.costs = table.clone(record.costs)
			table.insert(pending, copy)
		end
	end

	for _, record in ipairs(pending) do
		if not isCurrentRun(player, token)
			or not IslandSessionService.canWrite(player.UserId, player)
			or not PetCollectionService.isReady(player)
		then break end
		local ok, status = recoverTransaction(player, record)
		if ok then
			print("[PetKingdoms] Hatch transaction recovered", player.UserId, record.transactionId, status)
		else
			-- Fail closed. The durable state remains PREPARED or CHARGED and the
			-- same transaction/acquisition IDs are retried on the next join.
			warn("[PetKingdoms] Hatch transaction recovery deferred", player.UserId, record.transactionId, status)
		end
	end

	if isCurrentRun(player, token) then
		activeRuns[player.UserId] = nil
	end
end

function PetHatchingRecoveryService.start()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(recoverPlayer, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local run = activeRuns[player.UserId]
		if run ~= nil and run.player == player then
			activeRuns[player.UserId] = nil
		end
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(recoverPlayer, player)
	end
end

return PetHatchingRecoveryService
