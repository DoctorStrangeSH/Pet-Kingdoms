--!strict
-- Read-only quest snapshot endpoint. Quest progress is updated by trusted
-- server gameplay transactions; clients cannot submit progress or rewards.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local services = script.Parent
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local QuestProgressData = require(services:WaitForChild("QuestProgressData"))

local QuestService = {}
local REMOTE_NAME = "GetQuestProgress"
local REQUEST_INTERVAL = 0.5
local lastRequestAt: { [number]: number } = {}

local function getRemote(): RemoteFunction
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	local existing = folder:FindFirstChild(REMOTE_NAME)
	if existing == nil then
		local remote = Instance.new("RemoteFunction")
		remote.Name = REMOTE_NAME
		remote.Parent = folder
		existing = remote
	end
	assert(existing:IsA("RemoteFunction"), "Quest progress remote has an invalid class")
	return existing
end

function QuestService.start()
	local remote = getRemote()
	remote.OnServerInvoke = function(player: Player)
		local now = os.clock()
		local previous = lastRequestAt[player.UserId]
		if previous ~= nil and now - previous < REQUEST_INTERVAL then
			return { ok = false, code = "RATE_LIMITED" }
		end
		lastRequestAt[player.UserId] = now
		if not IslandSessionService.canWrite(player.UserId, player) then
			return { ok = false, code = "SESSION_NOT_WRITABLE" }
		end
		local profile = IslandSessionService.getProfile(player.UserId)
		if type(profile) ~= "table" then return { ok = false, code = "SESSION_NOT_READY" } end
		local quests = QuestProgressData.snapshot(profile.questProgress)
		return { ok = true, quests = quests, revision = profile.revision }
	end
	Players.PlayerRemoving:Connect(function(player)
		lastRequestAt[player.UserId] = nil
	end)
end

return QuestService
