--!strict
-- Server-authoritative quest snapshots and tracked-objective preference.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local QuestProgressData = require(services:WaitForChild("QuestProgressData"))

local QuestService = {}
local REQUEST_INTERVAL = 0.5
local lastRequestAt: { [number]: number } = {}

local function getRemote(name: string): RemoteFunction
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	local existing = folder:FindFirstChild(name)
	if existing == nil then
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
		existing = remote
	end
	assert(existing:IsA("RemoteFunction"), name .. " has an invalid class")
	return existing
end

local function allowRequest(player: Player): boolean
	local now = os.clock()
	local previous = lastRequestAt[player.UserId]
	if previous ~= nil and now - previous < REQUEST_INTERVAL then return false end
	lastRequestAt[player.UserId] = now
	return true
end

function QuestService.start()
	local snapshotRemote = getRemote("GetQuestProgress")
	local trackingRemote = getRemote("SetTrackedQuest")

	snapshotRemote.OnServerInvoke = function(player: Player)
		if not allowRequest(player) then return { ok = false, code = "RATE_LIMITED" } end
		if not IslandSessionService.canWrite(player.UserId, player) then
			return { ok = false, code = "SESSION_NOT_WRITABLE" }
		end
		local profile = IslandSessionService.getProfile(player.UserId)
		if type(profile) ~= "table" then return { ok = false, code = "SESSION_NOT_READY" } end
		return {
			ok = true,
			quests = QuestProgressData.snapshot(profile.questProgress),
			trackedQuestId = profile.trackedQuestId,
			revision = profile.revision,
		}
	end

	trackingRemote.OnServerInvoke = function(player: Player, questId: any)
		if not allowRequest(player) then return { ok = false, code = "RATE_LIMITED" } end
		if questId ~= nil and type(questId) ~= "string" then
			return { ok = false, code = "INVALID_QUEST_ID" }
		end
		local ok, code, revision = IslandSessionService.commitTrackedQuest(
			player.UserId,
			player,
			questId
		)
		return { ok = ok, code = code, revision = revision }
	end

	Players.PlayerRemoving:Connect(function(player)
		lastRequestAt[player.UserId] = nil
	end)
end

return QuestService
