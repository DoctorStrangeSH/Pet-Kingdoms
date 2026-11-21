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

local IslandSessionService = {}

local AUTOSAVE_INTERVAL = 60

type Session = {
	profile: any,
	dirty: boolean,
	saving: boolean,
	saveFinished: BindableEvent,
	closing: boolean,
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

function IslandSessionService.markDirty(userId: number): boolean
	local session = sessions[userId]
	if session == nil or shuttingDown or session.closing or not session.leaseValid then
		return false
	end

	session.profile.revision += 1
	session.dirty = true
	return true
end

local function cloneProfile(profile: any): any
	local copy = table.clone(profile)
	copy.buildings = table.clone(profile.buildings)
	for index, record in ipairs(profile.buildings) do
		copy.buildings[index] = table.clone(record)
	end
	copy.unlockedBuildingIds = table.clone(profile.unlockedBuildingIds)
	return copy
end

local function saveSession(userId: number, session: Session): boolean
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
		-- Keep dirty if any mutation happened while the DataStore call yielded.
		if session.profile.revision == snapshot.revision then
			session.dirty = false
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
		dirty = false,
		saving = false,
		saveFinished = Instance.new("BindableEvent"),
		closing = false,
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

local function removePlayer(player: Player)
	local userId = player.UserId
	local session = sessions[userId]
	if session then
		session.closing = true
		local saved = saveSession(userId, session)
		if not saved then
			warn(string.format("[PetKingdoms] Final save failed; retaining session until server shutdown for %d", userId))
			return
		end
		local released, releaseCode = IslandLeaseService.release(userId, session.leaseToken)
		if not released then
			warn(string.format("[PetKingdoms] Island lease release failed for %d: %s", userId, releaseCode))
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
				if session.dirty then
					task.spawn(saveSession, userId, session)
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
				if not saved then
					warn(string.format("[PetKingdoms] Shutdown could not flush island profile for %d", userId))
				end
				local released, releaseCode = IslandLeaseService.release(userId, session.leaseToken)
				if not released then
					warn(string.format("[PetKingdoms] Shutdown lease release failed for %d: %s", userId, releaseCode))
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
