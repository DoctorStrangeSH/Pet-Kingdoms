--!strict
-- Server-owned player island profile lifecycle.
-- Requires Workspace attributes IslandGridWidth and IslandGridDepth to be set
-- from the approved world/plot layout. Fails closed when they are missing.
-- Loads persistent profiles, creates the personal island world, and routes characters to its arrival pad.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local services = script.Parent
local IslandData = require(services:WaitForChild("IslandData"))
local IslandStore = require(services:WaitForChild("IslandStore"))
local IslandLeaseService = require(services:WaitForChild("IslandLeaseService"))
local IslandWorldService = require(services:WaitForChild("IslandWorldService"))
local IslandHatchLedgerData = require(services:WaitForChild("IslandHatchLedgerData"))
local IslandBuildingJournalData = require(services:WaitForChild("IslandBuildingJournalData"))

local IslandSessionService = {}

local AUTOSAVE_INTERVAL = 60

type Session = {
	profile: any,
	player: Player,
	dirty: boolean,
	saving: boolean,
	persistedRevision: number,
	hatchMutationBusy: boolean,
	buildingMutationBusy: boolean,
	saveFinished: BindableEvent,
	closing: boolean,
	playerLeaving: boolean,
	finalizing: boolean,
	leaseToken: string,
	leaseValid: boolean,
	characterAddedConnection: RBXScriptConnection?,
}

local sessions: { [number]: Session } = {}
local loading: { [number]: boolean } = {}
local shuttingDown = false

local function getConfiguredBounds(): (number?, number?)
	local width = Workspace:GetAttribute("IslandGridWidth")
	local depth = Workspace:GetAttribute("IslandGridDepth")
	if type(width) ~= "number" or type(depth) ~= "number"
		or width <= 0 or depth <= 0
		or width ~= math.floor(width) or depth ~= math.floor(depth)
	then
		return nil, nil
	end
	return width, depth
end

function IslandSessionService.getProfile(userId: number): any?
	local session = sessions[userId]
	return if session then session.profile else nil
end

-- Collection writers share the existing island MemoryStore lease and fail closed
-- whenever their island session is closing, superseded, or no longer writable.
function IslandSessionService.canWrite(userId: number, player: Player): boolean
	local session = sessions[userId]
	return session ~= nil and session.player == player
		and not shuttingDown and not session.closing and not session.playerLeaving
		and session.leaseValid
end

function IslandSessionService.markDirty(userId: number): boolean
	local session = sessions[userId]
	if session == nil or shuttingDown or session.closing or not session.leaseValid then
		return false
	end

	session.profile.revision += 1
	session.dirty = true
	return true
end

-- Forward declaration: the hatch operation function must capture this local,
-- not an unresolved global (its implementation appears later in this module).
local saveSession: (number, Session) -> boolean

-- Applies one hatch journal transition to the live island profile and waits
-- until a DataStore save has persisted at least that revision before returning success.
-- The transform is performed without yielding; the per-session guard serializes hatch transitions.
-- Commits a building result and its idempotency receipt in the same island
-- profile revision, then waits for DataStore durability before acknowledging it.
function IslandSessionService.commitBuildingOperation(
	userId: number,
	player: Player,
	requestId: string,
	fingerprint: string,
	action: string,
	result: any
): (boolean, string)
	local session = sessions[userId]
	if session == nil then return false, "SESSION_NOT_READY" end
	if not IslandSessionService.canWrite(userId, player) then
		return false, "SESSION_NOT_WRITABLE"
	end
	if session.buildingMutationBusy then return false, "BUILDING_OPERATION_BUSY" end

	session.buildingMutationBusy = true
	local nextLedger, journalCode = IslandBuildingJournalData.append(
		session.profile.buildingOperations or {},
		requestId,
		fingerprint,
		action,
		result,
		os.time()
	)
	if nextLedger == nil then
		session.buildingMutationBusy = false
		return false, journalCode
	end
	if journalCode == "ALREADY_RECORDED" then
		session.buildingMutationBusy = false
		return true, journalCode
	end

	local previousLedger = session.profile.buildingOperations
	session.profile.buildingOperations = nextLedger
	if not IslandSessionService.markDirty(userId) then
		session.profile.buildingOperations = previousLedger
		session.buildingMutationBusy = false
		return false, "SESSION_NOT_WRITABLE"
	end

	local targetRevision = session.profile.revision
	local deadline = os.clock() + 30
	-- The receipt is durable once its own revision is persisted. A later
	-- unrelated mutation may keep the profile dirty; it must not turn an
	-- already committed purchase into a client-visible failure.
	while session.persistedRevision < targetRevision do
		if not IslandSessionService.canWrite(userId, player) or sessions[userId] ~= session then
			session.buildingMutationBusy = false
			return false, "SESSION_NOT_WRITABLE"
		end
		if os.clock() >= deadline then
			session.buildingMutationBusy = false
			return false, "PERSIST_TIMEOUT"
		end
		local saved = saveSession(userId, session)
		if not saved then task.wait(0.5) end
	end

	session.buildingMutationBusy = false
	return true, "DURABLE"
end

function IslandSessionService.applyHatchOperation(
	userId: number,
	operation: string,
	transactionId: string,
	record: any?
): (boolean, string)
	local session = sessions[userId]
	if session == nil then return false, "SESSION_NOT_READY" end
	if shuttingDown or session.closing or not session.leaseValid then
		return false, "SESSION_NOT_WRITABLE"
	end
	if session.hatchMutationBusy then return false, "HATCH_OPERATION_BUSY" end
	if operation ~= "PREPARE" and operation ~= "CHARGE" and operation ~= "GRANT" then
		return false, "UNKNOWN_HATCH_OPERATION"
	end

	session.hatchMutationBusy = true
	local nextProfile: any = nil
	local status: string
	if operation == "PREPARE" then
		if type(record) ~= "table" or record.transactionId ~= transactionId then
			session.hatchMutationBusy = false
			return false, "TRANSACTION_ID_MISMATCH"
		end
		nextProfile, status = IslandHatchLedgerData.prepare(session.profile, record, os.time())
	elseif operation == "CHARGE" then
		nextProfile, status = IslandHatchLedgerData.charge(session.profile, transactionId)
	else
		nextProfile, status = IslandHatchLedgerData.markGranted(session.profile, transactionId)
	end

	if nextProfile == nil then
		session.hatchMutationBusy = false
		return false, status
	end
	if status == "ALREADY_PREPARED" or status == "ALREADY_CHARGED" or status == "ALREADY_GRANTED" then
		-- An idempotent retry still verifies that the referenced state is durable.
		local targetRecord = nil
		for _, entry in ipairs(nextProfile.hatchTransactions or {}) do
			if entry.transactionId == transactionId then
				targetRecord = entry
				break
			end
		end
		if operation == "PREPARE" and record ~= nil then
			for _, entry in ipairs(nextProfile.hatchTransactions or {}) do
				if entry.transactionId == record.transactionId then
					targetRecord = entry
					break
				end
			end
		end
		if targetRecord == nil then
			session.hatchMutationBusy = false
			return false, "TRANSACTION_NOT_FOUND"
		end
	else
		nextProfile.revision = session.profile.revision + 1
		session.profile = nextProfile
		session.dirty = true
	end

	local targetRevision = session.profile.revision
	local deadline = os.clock() + 30
	while session.persistedRevision < targetRevision or session.dirty do
		if not session.leaseValid or session.closing or sessions[userId] ~= session then
			session.hatchMutationBusy = false
			return false, "SESSION_NOT_WRITABLE"
		end
		if os.clock() >= deadline then
			session.hatchMutationBusy = false
			return false, "PERSIST_TIMEOUT"
		end
		local saved = saveSession(userId, session)
		if not saved then
			task.wait(0.5)
		end
	end

	session.hatchMutationBusy = false
	return true, status
end

local function cloneProfile(profile: any): any
	local copy = table.clone(profile)
	copy.buildings = table.clone(profile.buildings)
	for index, record in ipairs(profile.buildings) do
		copy.buildings[index] = table.clone(record)
	end
	copy.unlockedBuildingIds = table.clone(profile.unlockedBuildingIds)
	copy.resources = table.clone(profile.resources or { wood = 2, stone = 1, gold = 0, gems = 0 })
	copy.buildingOperations = {}
	for index, record in ipairs(profile.buildingOperations or {}) do
		local clonedRecord = table.clone(record)
		clonedRecord.result = table.clone(record.result)
		copy.buildingOperations[index] = clonedRecord
	end
	copy.hatchTransactions = {}
	for index, record in ipairs(profile.hatchTransactions or {}) do
		local clonedRecord = table.clone(record)
		clonedRecord.costs = table.clone(record.costs)
		copy.hatchTransactions[index] = clonedRecord
	end
	return copy
end

saveSession = function(userId: number, session: Session): boolean
	-- Serialize saves for one player. A leave/shutdown caller waits for an
	-- in-flight autosave instead of discarding the session while it is writing.
	while session.saving do
		session.saveFinished.Event:Wait()
	end

	if not session.leaseValid then
		warn(string.format("[PetKingdoms] Refusing save without a valid island lease for %d", userId))
		return false
	end
	if not session.dirty then
		return true
	end

	session.saving = true
	local snapshot = cloneProfile(session.profile)
	local ok, code = IslandStore.save(snapshot)
	session.saving = false
	session.saveFinished:Fire()

	if ok then
		session.persistedRevision = math.max(session.persistedRevision, snapshot.revision)
		-- Keep dirty if any mutation happened while the DataStore call yielded.
		if session.profile.revision == snapshot.revision then
			session.dirty = false
		else
			session.dirty = true
		end
		print(string.format("[PetKingdoms] Island saved for %d (%s)", userId, code))
		return true
	end

	warn(string.format("[PetKingdoms] Island save failed for %d: %s", userId, code))
	return false
end

local function moveCharacterToIsland(userId: number, character: Model)
	local arrival = IslandWorldService.getArrivalCFrame(userId)
	if arrival == nil then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root == nil or not root:IsA("BasePart") then
		warn(string.format("[PetKingdoms] Character root missing for island arrival: %d", userId))
		return
	end
	if character.Parent == nil then
		return
	end
	-- The island may have been removed while WaitForChild yielded (lease loss/leave).
	local currentArrival = IslandWorldService.getArrivalCFrame(userId)
	if currentArrival == nil then
		return
	end
	character:PivotTo(currentArrival)
end

local function loadPlayer(player: Player)
	local userId = player.UserId
	if loading[userId] or sessions[userId] ~= nil then
		return
	end
	loading[userId] = true

	local leaseToken = IslandLeaseService.newToken()
	local leaseAcquired, leaseStatus = IslandLeaseService.acquire(userId, leaseToken)
	if not leaseAcquired then
		loading[userId] = nil
		warn(string.format("[PetKingdoms] Could not acquire island lease for %s: %s", player.Name, leaseStatus))
		player:Kick("Ваш остров уже загружается на другом сервере. Пожалуйста, попробуйте позже.")
		return
	end

	local function releaseLoadingLease()
		local released, releaseCode = IslandLeaseService.release(userId, leaseToken)
		if not released then
			warn(string.format("[PetKingdoms] Could not release loading lease for %d: %s", userId, releaseCode))
		end
	end

	local ok, profile, status = IslandStore.load(userId)
	if not ok then
		loading[userId] = nil
		releaseLoadingLease()
		warn(string.format("[PetKingdoms] Refusing island session for %s: %s", player.Name, status))
		player:Kick("Не удалось загрузить остров. Пожалуйста, попробуйте войти позже.")
		return
	end

	if status == "NOT_FOUND" then
		local width, depth = getConfiguredBounds()
		if width == nil or depth == nil then
			loading[userId] = nil
			releaseLoadingLease()
			warn("[PetKingdoms] IslandGridWidth/IslandGridDepth Workspace attributes are missing; refusing to create an island profile.")
			player:Kick("Мир временно недоступен. Пожалуйста, попробуйте позже.")
			return
		end

		profile = IslandData.create(userId, width, depth)
		if profile == nil then
			loading[userId] = nil
			releaseLoadingLease()
			player:Kick("Не удалось создать остров. Пожалуйста, попробуйте позже.")
			return
		end

	end

	-- Claim a monotonically increasing generation in the same DataStore key.
	-- Every later save must present this exact generation inside UpdateAsync.
	local claimed, claimedProfile, claimCode = IslandStore.claimSession(profile)
	if not claimed then
		loading[userId] = nil
		releaseLoadingLease()
		warn(string.format("[PetKingdoms] Could not claim DataStore session for %s: %s", player.Name, claimCode))
		player:Kick("Не удалось открыть остров. Пожалуйста, попробуйте позже.")
		return
	end
	profile = claimedProfile

	if player.Parent ~= Players then
		loading[userId] = nil
		releaseLoadingLease()
		return
	end

	local worldSpawned, worldStatus = IslandWorldService.spawn(player, profile)
	if not worldSpawned then
		loading[userId] = nil
		releaseLoadingLease()
		warn(string.format("[PetKingdoms] Could not spawn island for %s: %s", player.Name, worldStatus))
		player:Kick("Не удалось подготовить ваш остров. Пожалуйста, попробуйте позже.")
		return
	end

	local characterAddedConnection = player.CharacterAdded:Connect(function(character)
		task.spawn(moveCharacterToIsland, userId, character)
	end)

	sessions[userId] = {
		profile = profile,
		player = player,
		dirty = false,
		saving = false,
		persistedRevision = profile.revision,
		hatchMutationBusy = false,
		buildingMutationBusy = false,
		saveFinished = Instance.new("BindableEvent"),
		closing = false,
		playerLeaving = false,
		finalizing = false,
		leaseToken = leaseToken,
		leaseValid = true,
		characterAddedConnection = characterAddedConnection,
	}
	loading[userId] = nil

	if player.Character then
		task.spawn(moveCharacterToIsland, userId, player.Character)
	end
	task.spawn(function()
		while sessions[userId] ~= nil and not shuttingDown do
			task.wait(IslandLeaseService.RENEWAL_WINDOW_SECONDS)
			local activeSession = sessions[userId]
			if activeSession == nil or activeSession.leaseToken ~= leaseToken then
				break
			end
			local renewed, renewCode = IslandLeaseService.renew(userId, leaseToken)
			if not renewed then
				activeSession.leaseValid = false
				activeSession.closing = true
				if activeSession.characterAddedConnection then
					activeSession.characterAddedConnection:Disconnect()
					activeSession.characterAddedConnection = nil
				end
				IslandWorldService.remove(userId)
				warn(string.format("[PetKingdoms] Island lease lost for %d: %s", userId, renewCode))
				local currentPlayer = Players:GetPlayerByUserId(userId)
				if currentPlayer then
					currentPlayer:Kick("Потеряно подключение к острову. Пожалуйста, войдите снова.")
				end
				break
			end
		end
	end)
	print(string.format("[PetKingdoms] Island profile ready for %s", player.Name))
end

local function finalizeLeavingSession(userId: number, session: Session)
	if session.finalizing or not session.playerLeaving then
		return
	end
	session.finalizing = true

	local released, releaseCode = IslandLeaseService.release(userId, session.leaseToken)
	if not released then
		session.finalizing = false
		warn(string.format("[PetKingdoms] Island lease release failed for %d: %s; will retry", userId, releaseCode))
		return
	end

	-- Do not tear down a newer session if this callback was delayed.
	if sessions[userId] ~= session then
		return
	end
	sessions[userId] = nil
	if session.characterAddedConnection then
		session.characterAddedConnection:Disconnect()
		session.characterAddedConnection = nil
	end
	IslandWorldService.remove(userId)
	session.saveFinished:Destroy()
end

local function removePlayer(player: Player)
	local userId = player.UserId
	local session = sessions[userId]
	if session then
		session.closing = true
		session.playerLeaving = true
		local saved = saveSession(userId, session)
		if not saved then
			-- Keep the profile, world and lease alive. The autosave loop retries
			-- the final write and then calls finalizeLeavingSession on success.
			warn(string.format("[PetKingdoms] Final save failed; retaining island session for retry: %d", userId))
			return
		end
		finalizeLeavingSession(userId, session)
	end
	loading[userId] = nil
end

function IslandSessionService.start()
	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(removePlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadPlayer, player)
	end

	task.spawn(function()
		while not shuttingDown do
			task.wait(AUTOSAVE_INTERVAL)
			for userId, session in pairs(sessions) do
				if session.dirty or session.playerLeaving then
					task.spawn(function()
						local saved = saveSession(userId, session)
						if saved and session.playerLeaving then
							finalizeLeavingSession(userId, session)
						end
					end)
				end
			end
		end
	end)

	game:BindToClose(function()
		shuttingDown = true
		local pending = 0
		for userId, session in pairs(sessions) do
			pending += 1
			task.spawn(function()
				local saved = saveSession(userId, session)
				if saved then
					-- Release only after the final snapshot is confirmed persisted.
					-- On failure, let the lease expire naturally so a new server
					-- cannot immediately load stale data while this server shuts down.
					local released, releaseCode = IslandLeaseService.release(userId, session.leaseToken)
					if not released then
						warn(string.format("[PetKingdoms] Shutdown lease release failed for %d: %s", userId, releaseCode))
					end
				else
					warn(string.format("[PetKingdoms] Shutdown could not flush island profile for %d; retaining lease until expiry", userId))
				end
				pending -= 1
			end)
		end

		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return IslandSessionService
