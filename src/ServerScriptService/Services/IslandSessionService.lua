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
local IslandResourceNodeCatalog = require(services:WaitForChild("IslandResourceNodeCatalog"))
local IslandResourceNodeData = require(services:WaitForChild("IslandResourceNodeData"))
local IslandResources = require(services:WaitForChild("IslandResources"))
local IslandExpansion = require(services:WaitForChild("IslandExpansion"))
local QuestProgressData = require(services:WaitForChild("QuestProgressData"))
local QuestRewardOutboxData = require(services:WaitForChild("QuestRewardOutboxData"))

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
	gatheringMutationBusy: boolean,
	saveFinished: BindableEvent,
	closing: boolean,
	playerLeaving: boolean,
	finalizing: boolean,
	leaseToken: string,
	leaseValid: boolean,
	characterAddedConnection: RBXScriptConnection?,
	humanoidDiedConnection: RBXScriptConnection?,
	respawnPending: boolean,
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
function IslandSessionService.isProfileMutationBusy(userId: number): boolean
	local session = sessions[userId]
	return session ~= nil and (
		session.buildingMutationBusy
		or session.gatheringMutationBusy
		or session.hatchMutationBusy
	)
end

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
-- Atomically grants one canonical resource node reward and advances its
-- cooldown in the same island profile revision. The reward is acknowledged
-- only after that revision is confirmed in DataStore.
function IslandSessionService.commitResourceGathering(
	userId: number,
	player: Player,
	nodeId: string,
	now: number
): (boolean, string, number?)
	local session = sessions[userId]
	if session == nil then return false, "SESSION_NOT_READY", nil end
	if not IslandSessionService.canWrite(userId, player) then
		return false, "SESSION_NOT_WRITABLE", nil
	end
	if session.gatheringMutationBusy or session.buildingMutationBusy or session.hatchMutationBusy then
		return false, "GATHERING_BUSY", nil
	end

	local definition = IslandResourceNodeCatalog.get(nodeId)
	if definition == nil then return false, "UNKNOWN_NODE", nil end
	session.gatheringMutationBusy = true

	local nextStates, availableAt, stateCode = IslandResourceNodeData.recordGather(
		session.profile.resourceNodes or {},
		nodeId,
		now
	)
	if nextStates == nil then
		session.gatheringMutationBusy = false
		return false, stateCode, availableAt
	end

	local previousResources = table.clone(session.profile.resources)
	local granted, grantCode = IslandResources.grant(
		session.profile.resources,
		definition.resourceId,
		definition.reward
	)
	if not granted then
		session.gatheringMutationBusy = false
		return false, grantCode, nil
	end

	local previousQuestProgress = session.profile.questProgress or QuestProgressData.create()
	local nextQuestProgress, completedQuestIds, questCode = QuestProgressData.recordGather(
		previousQuestProgress,
		definition.resourceId
	)
	if nextQuestProgress == nil then
		session.profile.resources = previousResources
		session.gatheringMutationBusy = false
		return false, questCode, nil
	end

	local previousStates = session.profile.resourceNodes
	session.profile.resourceNodes = nextStates
	session.profile.questProgress = nextQuestProgress
	if not IslandSessionService.markDirty(userId) then
		session.profile.resources = previousResources
		session.profile.resourceNodes = previousStates
		session.profile.questProgress = previousQuestProgress
		session.gatheringMutationBusy = false
		return false, "SESSION_NOT_WRITABLE", nil
	end

	local targetRevision = session.profile.revision
	local deadline = os.clock() + 30
	while session.persistedRevision < targetRevision do
		if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
			session.gatheringMutationBusy = false
			return false, "SESSION_NOT_WRITABLE", availableAt
		end
		if os.clock() >= deadline then
			session.gatheringMutationBusy = false
			return false, "PERSIST_PENDING", availableAt
		end
		local saved = saveSession(userId, session)
		if not saved then task.wait(0.5) end
	end

	session.gatheringMutationBusy = false
	return true, "GATHERED", availableAt
end

-- Commits a server-resolved pet XP quest reward, its permanent claim receipt,
-- and its outbox record in one durable island profile revision.
-- rewardPlan must come from a server-owned catalog; this method is never a RemoteFunction.
function IslandSessionService.commitQuestRewardClaim(
	userId: number,
	player: Player,
	questId: string,
	rewardPlan: any
): (boolean, string, any?)
	local session = sessions[userId]
	if session == nil then return false, "SESSION_NOT_READY", nil end
	if not IslandSessionService.canWrite(userId, player) then
		return false, "SESSION_NOT_WRITABLE", nil
	end
	if session.gatheringMutationBusy or session.buildingMutationBusy or session.hatchMutationBusy then
		return false, "PROFILE_MUTATION_BUSY", nil
	end
	local definition = QuestProgressData.DEFINITIONS[questId]
	if definition == nil then return false, "UNKNOWN_QUEST", nil end
	if type(rewardPlan) ~= "table" then return false, "INVALID_REWARD_PLAN", nil end

	local progress = (session.profile.questProgress or QuestProgressData.create())[questId]
	if progress == nil or progress.count < definition.target then
		return false, "QUEST_NOT_COMPLETED", nil
	end

	local claims = session.profile.questRewardClaims or QuestRewardOutboxData.createClaims()
	local existingReceipt = claims[questId]
	if existingReceipt ~= nil then
		if type(existingReceipt) ~= "table" or type(existingReceipt.rewardId) ~= "string" then
			return false, "INVALID_CLAIM_RECEIPT", nil
		end
		local expectedRevision = existingReceipt.revision
		if type(expectedRevision) == "number" then
			local deadline = os.clock() + 30
			while session.persistedRevision < expectedRevision do
				if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
					return false, "SESSION_NOT_WRITABLE", existingReceipt
				end
				if os.clock() >= deadline then return false, "PERSIST_PENDING", existingReceipt end
				local saved = saveSession(userId, session)
				if not saved then task.wait(0.5) end
			end
		end
		return true, "ALREADY_CLAIMED", table.clone(existingReceipt)
	end

	local rewardId = rewardPlan.rewardId
	local petId = rewardPlan.petId
	local amount = rewardPlan.amount
	local progressionVersion = rewardPlan.progressionVersion
	if type(rewardId) ~= "string" or #rewardId == 0 or #rewardId > QuestRewardOutboxData.MAX_REWARD_ID_LENGTH
		or type(petId) ~= "string" or #petId == 0 or #petId > QuestRewardOutboxData.MAX_PET_ID_LENGTH
		or type(amount) ~= "number" or amount < 1 or amount > QuestRewardOutboxData.MAX_REWARD_AMOUNT
		or amount ~= math.floor(amount)
		or type(progressionVersion) ~= "number" or progressionVersion < 1
		or progressionVersion ~= math.floor(progressionVersion) then
		return false, "INVALID_REWARD_PLAN", nil
	end

	session.gatheringMutationBusy = true
	local now = os.time()
	local targetRevision = session.profile.revision + 1
	local nextClaims, claimCode = QuestRewardOutboxData.recordClaim(
		claims, questId, rewardId, now, targetRevision
	)
	if nextClaims == nil then
		session.gatheringMutationBusy = false
		return false, claimCode, nil
	end
	local nextOutbox, outboxCode = QuestRewardOutboxData.append(
		session.profile.questRewardOutbox or QuestRewardOutboxData.createOutbox(),
		{
			rewardId = rewardId,
			questId = questId,
			petId = petId,
			amount = amount,
			progressionVersion = progressionVersion,
			createdAt = now,
		}
	)
	if nextOutbox == nil then
		session.gatheringMutationBusy = false
		return false, outboxCode, nil
	end

	local previousClaims = session.profile.questRewardClaims
	local previousOutbox = session.profile.questRewardOutbox
	session.profile.questRewardClaims = nextClaims
	session.profile.questRewardOutbox = nextOutbox
	if not IslandSessionService.markDirty(userId) then
		session.profile.questRewardClaims = previousClaims
		session.profile.questRewardOutbox = previousOutbox
		session.gatheringMutationBusy = false
		return false, "SESSION_NOT_WRITABLE", nil
	end

	local deadline = os.clock() + 30
	while session.persistedRevision < targetRevision do
		if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
			session.gatheringMutationBusy = false
			return false, "SESSION_NOT_WRITABLE", nil
		end
		if os.clock() >= deadline then
			session.gatheringMutationBusy = false
			return false, "PERSIST_PENDING", nil
		end
		local saved = saveSession(userId, session)
		if not saved then task.wait(0.5) end
	end
	session.gatheringMutationBusy = false
	return true, "CLAIM_DURABLE", table.clone(nextClaims[questId])
end

-- The caller may acknowledge the pet-side receipt only after this method
-- confirms the delivered timestamp is durable in the island profile.
function IslandSessionService.commitQuestRewardDelivery(
	userId: number,
	player: Player,
	rewardId: string
): (boolean, string, number?)
	local session = sessions[userId]
	if session == nil then return false, "SESSION_NOT_READY", nil end
	if not IslandSessionService.canWrite(userId, player) then
		return false, "SESSION_NOT_WRITABLE", nil
	end
	if session.gatheringMutationBusy or session.buildingMutationBusy or session.hatchMutationBusy then
		return false, "PROFILE_MUTATION_BUSY", nil
	end
	session.gatheringMutationBusy = true
	local nextOutbox, status = QuestRewardOutboxData.markDelivered(
		session.profile.questRewardOutbox or QuestRewardOutboxData.createOutbox(),
		rewardId,
		os.time()
	)
	if nextOutbox == nil then
		if status == "ALREADY_DELIVERED" then
			local targetRevision = session.profile.revision
			local deadline = os.clock() + 30
			while session.persistedRevision < targetRevision do
				if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
					session.gatheringMutationBusy = false
					return false, "SESSION_NOT_WRITABLE", targetRevision
				end
				if os.clock() >= deadline then
					session.gatheringMutationBusy = false
					return false, "PERSIST_PENDING", targetRevision
				end
				local saved = saveSession(userId, session)
				if not saved then task.wait(0.5) end
			end
		end
		session.gatheringMutationBusy = false
		return status == "ALREADY_DELIVERED", status, session.profile.revision
	end

	local previousOutbox = session.profile.questRewardOutbox
	session.profile.questRewardOutbox = nextOutbox
	if not IslandSessionService.markDirty(userId) then
		session.profile.questRewardOutbox = previousOutbox
		session.gatheringMutationBusy = false
		return false, "SESSION_NOT_WRITABLE", nil
	end
	local targetRevision = session.profile.revision
	local deadline = os.clock() + 30
	while session.persistedRevision < targetRevision do
		if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
			session.gatheringMutationBusy = false
			return false, "SESSION_NOT_WRITABLE", targetRevision
		end
		if os.clock() >= deadline then
			session.gatheringMutationBusy = false
			return false, "PERSIST_PENDING", targetRevision
		end
		local saved = saveSession(userId, session)
		if not saved then task.wait(0.5) end
	end
	session.gatheringMutationBusy = false
	return true, "DELIVERY_DURABLE", targetRevision
end

-- Persist the source-side acknowledgement after the pet XP delivery revision is
-- durable. This must precede pet receipt acknowledgement so its retention clock
-- cannot expire while the source-side commit is still unavailable.
function IslandSessionService.commitQuestRewardAcknowledgement(
	userId: number,
	player: Player,
	rewardId: string
): (boolean, string, number?)
	local session = sessions[userId]
	if session == nil then return false, "SESSION_NOT_READY", nil end
	if not IslandSessionService.canWrite(userId, player) then
		return false, "SESSION_NOT_WRITABLE", nil
	end
	if session.gatheringMutationBusy or session.buildingMutationBusy or session.hatchMutationBusy then
		return false, "PROFILE_MUTATION_BUSY", nil
	end
	session.gatheringMutationBusy = true
	local nextOutbox, status = QuestRewardOutboxData.markAcknowledged(
		session.profile.questRewardOutbox or QuestRewardOutboxData.createOutbox(),
		rewardId,
		os.time()
	)
	if nextOutbox == nil then
		if status == "ALREADY_ACKNOWLEDGED" then
			local targetRevision = session.profile.revision
			local deadline = os.clock() + 30
			while session.persistedRevision < targetRevision do
				if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
					session.gatheringMutationBusy = false
					return false, "SESSION_NOT_WRITABLE", targetRevision
				end
				if os.clock() >= deadline then
					session.gatheringMutationBusy = false
					return false, "PERSIST_PENDING", targetRevision
				end
				local saved = saveSession(userId, session)
				if not saved then task.wait(0.5) end
			end
		end
		session.gatheringMutationBusy = false
		return status == "ALREADY_ACKNOWLEDGED", status, session.profile.revision
	end
	local previousOutbox = session.profile.questRewardOutbox
	session.profile.questRewardOutbox = nextOutbox
	if not IslandSessionService.markDirty(userId) then
		session.profile.questRewardOutbox = previousOutbox
		session.gatheringMutationBusy = false
		return false, "SESSION_NOT_WRITABLE", nil
	end
	local targetRevision = session.profile.revision
	local deadline = os.clock() + 30
	while session.persistedRevision < targetRevision do
		if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
			session.gatheringMutationBusy = false
			return false, "SESSION_NOT_WRITABLE", targetRevision
		end
		if os.clock() >= deadline then
			session.gatheringMutationBusy = false
			return false, "PERSIST_PENDING", targetRevision
		end
		local saved = saveSession(userId, session)
		if not saved then task.wait(0.5) end
	end
	session.gatheringMutationBusy = false
	return true, "ACKNOWLEDGEMENT_DURABLE", targetRevision
end

-- After source acknowledgement is durable, finalize the pet-side receipt retention
-- state. The outbox is compactable only after this final marker is durable too.
function IslandSessionService.commitQuestRewardPetAcknowledgement(
	userId: number,
	player: Player,
	rewardId: string
): (boolean, string, number?)
	local session = sessions[userId]
	if session == nil then return false, "SESSION_NOT_READY", nil end
	if not IslandSessionService.canWrite(userId, player) then
		return false, "SESSION_NOT_WRITABLE", nil
	end
	if session.gatheringMutationBusy or session.buildingMutationBusy or session.hatchMutationBusy then
		return false, "PROFILE_MUTATION_BUSY", nil
	end
	session.gatheringMutationBusy = true
	local nextOutbox, status = QuestRewardOutboxData.markPetAcknowledged(
		session.profile.questRewardOutbox or QuestRewardOutboxData.createOutbox(),
		rewardId,
		os.time()
	)
	if nextOutbox == nil then
		if status == "ALREADY_PET_ACKNOWLEDGED" then
			local targetRevision = session.profile.revision
			local deadline = os.clock() + 30
			while session.persistedRevision < targetRevision do
				if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
					session.gatheringMutationBusy = false
					return false, "SESSION_NOT_WRITABLE", targetRevision
				end
				if os.clock() >= deadline then
					session.gatheringMutationBusy = false
					return false, "PERSIST_PENDING", targetRevision
				end
				local saved = saveSession(userId, session)
				if not saved then task.wait(0.5) end
			end
		end
		session.gatheringMutationBusy = false
		return status == "ALREADY_PET_ACKNOWLEDGED", status, session.profile.revision
	end
	local previousOutbox = session.profile.questRewardOutbox
	session.profile.questRewardOutbox = nextOutbox
	if not IslandSessionService.markDirty(userId) then
		session.profile.questRewardOutbox = previousOutbox
		session.gatheringMutationBusy = false
		return false, "SESSION_NOT_WRITABLE", nil
	end
	local targetRevision = session.profile.revision
	local deadline = os.clock() + 30
	while session.persistedRevision < targetRevision do
		if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
			session.gatheringMutationBusy = false
			return false, "SESSION_NOT_WRITABLE", targetRevision
		end
		if os.clock() >= deadline then
			session.gatheringMutationBusy = false
			return false, "PERSIST_PENDING", targetRevision
		end
		local saved = saveSession(userId, session)
		if not saved then task.wait(0.5) end
	end
	session.gatheringMutationBusy = false
	return true, "PET_ACKNOWLEDGEMENT_DURABLE", targetRevision
end

function IslandSessionService.getPendingQuestRewards(userId: number): { any }
	local session = sessions[userId]
	if session == nil then return {} end
	return QuestRewardOutboxData.listPending(
		session.profile.questRewardOutbox or QuestRewardOutboxData.createOutbox()
	)
end

function IslandSessionService.getQuestRewardsAwaitingAcknowledgement(userId: number): { any }
	local session = sessions[userId]
	if session == nil then return {} end
	return QuestRewardOutboxData.listAwaitingAcknowledgement(
		session.profile.questRewardOutbox or QuestRewardOutboxData.createOutbox()
	)
end

function IslandSessionService.getQuestRewardsAwaitingPetAcknowledgement(userId: number): { any }
	local session = sessions[userId]
	if session == nil then return {} end
	return QuestRewardOutboxData.listAwaitingPetAcknowledgement(
		session.profile.questRewardOutbox or QuestRewardOutboxData.createOutbox()
	)
end

-- Persists the player's tracked quest preference using the island profile revision.
-- The selected ID is checked against the server catalog and incomplete progress.
function IslandSessionService.commitTrackedQuest(
	userId: number,
	player: Player,
	questId: string?
): (boolean, string, number?)
	local session = sessions[userId]
	if session == nil then return false, "SESSION_NOT_READY", nil end
	if not IslandSessionService.canWrite(userId, player) then
		return false, "SESSION_NOT_WRITABLE", nil
	end
	if session.buildingMutationBusy or session.gatheringMutationBusy or session.hatchMutationBusy then
		return false, "PROFILE_MUTATION_BUSY", nil
	end
	if questId ~= nil then
		local definition = QuestProgressData.DEFINITIONS[questId]
		if definition == nil then return false, "UNKNOWN_QUEST", nil end
		local progress = (session.profile.questProgress or QuestProgressData.create())[questId]
		if progress == nil or progress.count >= definition.target then
			return false, "QUEST_NOT_ACTIVE", nil
		end
	end
	if session.profile.trackedQuestId == questId then
		return true, "UNCHANGED", session.profile.revision
	end

	session.gatheringMutationBusy = true
	local previous = session.profile.trackedQuestId
	session.profile.trackedQuestId = questId
	if not IslandSessionService.markDirty(userId) then
		session.profile.trackedQuestId = previous
		session.gatheringMutationBusy = false
		return false, "SESSION_NOT_WRITABLE", nil
	end
	local targetRevision = session.profile.revision
	local deadline = os.clock() + 30
	while session.persistedRevision < targetRevision do
		if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
			session.gatheringMutationBusy = false
			return false, "SESSION_NOT_WRITABLE", targetRevision
		end
		if os.clock() >= deadline then
			session.gatheringMutationBusy = false
			return false, "PERSIST_PENDING", targetRevision
		end
		local saved = saveSession(userId, session)
		if not saved then task.wait(0.5) end
	end
	session.gatheringMutationBusy = false
	return true, "TRACKING_SAVED", targetRevision
end

-- Applies one level of island expansion as a durable profile mutation.
-- expectedLevel makes retries safe: a repeated request cannot advance twice.
function IslandSessionService.commitIslandExpansion(
	userId: number,
	player: Player,
	expectedLevel: number
): (boolean, string, number?)
	local session = sessions[userId]
	if session == nil then return false, "SESSION_NOT_READY", nil end
	if not IslandSessionService.canWrite(userId, player) then
		return false, "SESSION_NOT_WRITABLE", nil
	end
	if session.buildingMutationBusy or session.gatheringMutationBusy or session.hatchMutationBusy then
		return false, "PROFILE_MUTATION_BUSY", nil
	end
	if type(expectedLevel) ~= "number" or expectedLevel < 0 or expectedLevel ~= math.floor(expectedLevel) then
		return false, "INVALID_EXPECTED_LEVEL", nil
	end

	local baseWidth, baseDepth = getConfiguredBounds()
	if baseWidth == nil or baseDepth == nil then
		return false, "MISSING_ISLAND_GRID_BOUNDS", nil
	end

	local currentLevel = if session.profile.expansionLevel == nil then 0 else session.profile.expansionLevel
	session.buildingMutationBusy = true

	local targetRevision: number
	local resultCode: string
	if currentLevel == expectedLevel then
		local nextProfile, prepareCode = IslandExpansion.prepareNextProfile(session.profile, baseWidth, baseDepth)
		if nextProfile == nil then
			session.buildingMutationBusy = false
			return false, prepareCode, nil
		end
		nextProfile.revision = session.profile.revision + 1
		session.profile = nextProfile
		session.dirty = true
		targetRevision = nextProfile.revision
		resultCode = "EXPANDED"
	elseif currentLevel == expectedLevel + 1 then
		if not IslandExpansion.matchesProfileBounds(session.profile, baseWidth, baseDepth) then
			session.buildingMutationBusy = false
			return false, "INVALID_EXPANSION_BOUNDS", nil
		end
		targetRevision = session.profile.revision
		resultCode = "ALREADY_APPLIED"
	else
		session.buildingMutationBusy = false
		return false, "EXPANSION_LEVEL_CONFLICT", nil
	end

	local deadline = os.clock() + 30
	while session.persistedRevision < targetRevision do
		if sessions[userId] ~= session or not IslandSessionService.canWrite(userId, player) then
			session.buildingMutationBusy = false
			return false, "SESSION_NOT_WRITABLE", targetRevision
		end
		if os.clock() >= deadline then
			session.buildingMutationBusy = false
			return false, "PERSIST_PENDING", targetRevision
		end
		local saved = saveSession(userId, session)
		if not saved then task.wait(0.5) end
	end

	if resultCode == "ALREADY_APPLIED" then
		session.buildingMutationBusy = false
		return true, resultCode, targetRevision
	end

	local refreshed, refreshCode = IslandWorldService.refresh(userId, player, session.profile)
	session.buildingMutationBusy = false
	if not refreshed then
		-- The profile revision is already durable. Keep it authoritative; a
		-- subsequent island reload will render the persisted expanded bounds.
		warn(string.format("[PetKingdoms] Expansion persisted but live world refresh failed for %d: %s", userId, refreshCode))
		return true, "PERSISTED_WORLD_REFRESH_PENDING", targetRevision
	end
	return true, resultCode, targetRevision
end

function IslandSessionService.findBuildingOperation(
	userId: number,
	requestId: string,
	fingerprint: string,
	now: number
): (any?, string)
	local session = sessions[userId]
	if session == nil then return nil, "SESSION_NOT_READY" end
	return IslandBuildingJournalData.find(
		session.profile.buildingOperations or {},
		requestId,
		fingerprint,
		now,
		session.persistedRevision
	)
end

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
	if session.buildingMutationBusy or session.gatheringMutationBusy or session.hatchMutationBusy then
		return false, "BUILDING_OPERATION_BUSY"
	end

	session.buildingMutationBusy = true
	local nextLedger, journalCode = IslandBuildingJournalData.append(
		session.profile.buildingOperations or {},
		requestId,
		fingerprint,
		action,
		result,
		os.time(),
		session.profile.revision + 1
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
	if session.hatchMutationBusy or session.buildingMutationBusy or session.gatheringMutationBusy then
		return false, "HATCH_OPERATION_BUSY"
	end
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
	copy.resourceNodes = {}
	for index, state in ipairs(profile.resourceNodes or {}) do
		copy.resourceNodes[index] = table.clone(state)
	end
	copy.questProgress = {}
	for questId, state in pairs(profile.questProgress or QuestProgressData.create()) do
		copy.questProgress[questId] = table.clone(state)
	end
	copy.questRewardClaims = {}
	for questId, receipt in pairs(profile.questRewardClaims or {}) do
		copy.questRewardClaims[questId] = table.clone(receipt)
	end
	copy.questRewardOutbox = {}
	for index, record in ipairs(profile.questRewardOutbox or {}) do
		copy.questRewardOutbox[index] = table.clone(record)
	end
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

local function setPlayerLoadState(player: Player, status: string, message: string)
	player:SetAttribute("PetKingdomsLoadStatus", status)
	player:SetAttribute("PetKingdomsLoadMessage", message)
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
	local player = Players:GetPlayerByUserId(userId)
	if player and player.Character == character then
		setPlayerLoadState(player, "Ready", "Остров готов. Приятной игры!")
	end
end

local function bindCharacterLifecycle(session: Session, character: Model)
	if session.humanoidDiedConnection then
		session.humanoidDiedConnection:Disconnect()
		session.humanoidDiedConnection = nil
	end

	task.spawn(moveCharacterToIsland, session.player.UserId, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid == nil or not humanoid:IsA("Humanoid")
		or sessions[session.player.UserId] ~= session or session.player.Character ~= character
	then
		return
	end

	session.humanoidDiedConnection = humanoid.Died:Connect(function()
		if session.respawnPending or sessions[session.player.UserId] ~= session
			or not IslandSessionService.canWrite(session.player.UserId, session.player)
		then
			return
		end
		session.respawnPending = true
		setPlayerLoadState(session.player, "Loading", "Питомцы ждут тебя. Возвращаемся на остров...")
		task.delay(5, function()
			local player = session.player
			if sessions[player.UserId] ~= session or player.Parent ~= Players
				or not IslandSessionService.canWrite(player.UserId, player)
				or player.Character ~= character
			then
				session.respawnPending = false
				return
			end

			local loaded = false
			local lastError: any = nil
			for attempt = 1, 3 do
				if sessions[player.UserId] ~= session or not IslandSessionService.canWrite(player.UserId, player) then
					break
				end
				local ok, result = pcall(function()
					player:LoadCharacterAsync()
				end)
				if ok then
					loaded = true
					break
				end
				lastError = result
				warn(string.format("[PetKingdoms] Respawn attempt %d failed for %d: %s", attempt, player.UserId, tostring(result)))
				if attempt < 3 then task.wait(attempt * 2) end
			end

			session.respawnPending = false
			if not loaded and sessions[player.UserId] == session and player.Parent == Players then
				setPlayerLoadState(player, "Failed", "Не удалось вернуть персонажа. Переподключись к игре.")
				warn(string.format("[PetKingdoms] Character respawn exhausted retries for %d: %s", player.UserId, tostring(lastError)))
				player:Kick("Не удалось возродить персонажа. Пожалуйста, войдите снова.")
			end
		end)
	end)
end

local function loadPlayer(player: Player)
	local userId = player.UserId
	if loading[userId] or sessions[userId] ~= nil then
		return
	end
	loading[userId] = true
	setPlayerLoadState(player, "Loading", "Подключаемся к королевству...")

	local leaseToken = IslandLeaseService.newToken()
	local leaseAcquired, leaseStatus = IslandLeaseService.acquire(userId, leaseToken)
	if not leaseAcquired then
		setPlayerLoadState(player, "Failed", "Не удалось открыть сессию острова.")
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

	setPlayerLoadState(player, "Loading", "Загружаем сохранение...")
	local ok, profile, status = IslandStore.load(userId)
	if not ok then
		setPlayerLoadState(player, "Failed", "Не удалось загрузить сохранение.")
		loading[userId] = nil
		releaseLoadingLease()
		warn(string.format("[PetKingdoms] Refusing island session for %s: %s", player.Name, status))
		player:Kick("Не удалось загрузить остров. Пожалуйста, попробуйте войти позже.")
		return
	end

	if status == "NOT_FOUND" then
		setPlayerLoadState(player, "Loading", "Создаём твоё королевство...")
		local width, depth = getConfiguredBounds()
		if width == nil or depth == nil then
			setPlayerLoadState(player, "Failed", "Не настроены размеры стартового острова.")
			loading[userId] = nil
			releaseLoadingLease()
			warn("[PetKingdoms] IslandGridWidth/IslandGridDepth Workspace attributes are missing; refusing to create an island profile.")
			player:Kick("Мир временно недоступен. Пожалуйста, попробуйте позже.")
			return
		end

		profile = IslandData.create(userId, width, depth)
		if profile == nil then
			setPlayerLoadState(player, "Failed", "Не удалось создать профиль острова.")
			loading[userId] = nil
			releaseLoadingLease()
			player:Kick("Не удалось создать остров. Пожалуйста, попробуйте позже.")
			return
		end

	end

	-- Claim a monotonically increasing generation in the same DataStore key.
	-- Every later save must present this exact generation inside UpdateAsync.
	setPlayerLoadState(player, "Loading", "Подготавливаем сохранение...")
	local claimed, claimedProfile, claimCode = IslandStore.claimSession(profile)
	if not claimed then
		setPlayerLoadState(player, "Failed", "Не удалось открыть сохранение.")
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

	setPlayerLoadState(player, "Loading", "Строим твой остров...")
	local worldSpawned, worldStatus = IslandWorldService.spawn(player, profile)
	if not worldSpawned then
		setPlayerLoadState(player, "Failed", "Не удалось создать остров.")
		loading[userId] = nil
		releaseLoadingLease()
		warn(string.format("[PetKingdoms] Could not spawn island for %s: %s", player.Name, worldStatus))
		player:Kick("Не удалось подготовить ваш остров. Пожалуйста, попробуйте позже.")
		return
	end

	local characterAddedConnection = player.CharacterAdded:Connect(function(character)
		local activeSession = sessions[userId]
		if activeSession then
			bindCharacterLifecycle(activeSession, character)
		end
	end)

	sessions[userId] = {
		profile = profile,
		player = player,
		dirty = false,
		saving = false,
		persistedRevision = profile.revision,
		hatchMutationBusy = false,
		buildingMutationBusy = false,
		gatheringMutationBusy = false,
		saveFinished = Instance.new("BindableEvent"),
		closing = false,
		playerLeaving = false,
		finalizing = false,
		leaseToken = leaseToken,
		leaseValid = true,
		characterAddedConnection = characterAddedConnection,
		humanoidDiedConnection = nil,
		respawnPending = false,
	}
	loading[userId] = nil

	-- CharacterAutoLoads is disabled by the server bootstrap. Create the
	-- character only after the profile, lease, and island world are ready.
	setPlayerLoadState(player, "Loading", "Готовим персонажа...")
	local characterLoaded, characterError = pcall(function()
		player:LoadCharacterAsync()
	end)
	if not characterLoaded then
		warn(string.format("[PetKingdoms] Character load failed for %d: %s", userId, tostring(characterError)))
		setPlayerLoadState(player, "Failed", "Не удалось создать персонажа.")
		player:Kick("Не удалось подготовить персонажа. Пожалуйста, войдите снова.")
		return
	end
	if player.Parent == Players and sessions[userId] ~= nil and player.Character then
		moveCharacterToIsland(userId, player.Character)
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
				if activeSession.humanoidDiedConnection then
					activeSession.humanoidDiedConnection:Disconnect()
					activeSession.humanoidDiedConnection = nil
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
	if session.humanoidDiedConnection then
		session.humanoidDiedConnection:Disconnect()
		session.humanoidDiedConnection = nil
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
