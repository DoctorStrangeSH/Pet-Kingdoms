--!strict
-- Server-authoritative gathering from nodes spawned inside each player's island.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local services = script.Parent
local IslandResourceService = require(services:WaitForChild("IslandResourceService"))
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local IslandResourceNodeCatalog = require(services:WaitForChild("IslandResourceNodeCatalog"))

local IslandGatheringService = {}
local MAX_DISTANCE = 18
local activeNodes: { [Instance]: boolean } = {}

local function getNode(prompt: ProximityPrompt): Model?
	local parent = prompt.Parent
	if parent == nil then return nil end
	return parent:FindFirstAncestorWhichIsA("Model")
end

local function setNodeVisible(node: Model, visible: boolean)
	for _, descendant in ipairs(node:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if visible then 0 else 1
			descendant.CanCollide = false
			descendant.CanTouch = visible
		elseif descendant:IsA("ProximityPrompt") then
			descendant.Enabled = visible
		end
	end
end

local function scheduleRespawn(node: Model, availableAt: number)
	activeNodes[node] = true
	local delaySeconds = math.max(0, availableAt - os.time())
	task.delay(delaySeconds, function()
		if node.Parent == nil or node:GetAttribute("AvailableAt") ~= availableAt then
			activeNodes[node] = nil
			return
		end
		local ownerUserId = node:GetAttribute("OwnerUserId")
		local ownerPlayer = if type(ownerUserId) == "number" then Players:GetPlayerByUserId(ownerUserId) else nil
		if ownerPlayer == nil or not IslandSessionService.canWrite(ownerUserId, ownerPlayer) then
			activeNodes[node] = nil
			return
		end
		if os.time() < availableAt then
			scheduleRespawn(node, availableAt)
			return
		end
		setNodeVisible(node, true)
		activeNodes[node] = nil
	end)
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	if not IslandSessionService.canWrite(player.UserId, player) then return end
	local node = getNode(prompt)
	if node == nil or activeNodes[node] then return end

	local nodeId = node:GetAttribute("ResourceNodeId")
	local definition = if type(nodeId) == "string" then IslandResourceNodeCatalog.get(nodeId) else nil
	local ownerUserId = node:GetAttribute("OwnerUserId")
	if definition == nil or ownerUserId ~= player.UserId
		or node:GetAttribute("ResourceId") ~= definition.resourceId
		or node:GetAttribute("RewardAmount") ~= definition.reward
	then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local promptPart = prompt.Parent
	if root == nil or not root:IsA("BasePart") or promptPart == nil or not promptPart:IsA("BasePart") then
		return
	end
	if (root.Position - promptPart.Position).Magnitude > math.min(MAX_DISTANCE, prompt.MaxActivationDistance + 3) then
		return
	end

	local world = node:FindFirstAncestor("PlayerIslands")
	if world == nil or node.Parent == nil or node.Parent.Name ~= "ResourceNodes" then
		return
	end
	local island = node:FindFirstAncestorWhichIsA("Model")
	if island == nil or island:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end

	local savedAvailableAt = node:GetAttribute("AvailableAt")
	if type(savedAvailableAt) == "number" and savedAvailableAt > os.time() then
		prompt.Enabled = false
		setNodeVisible(node, false)
		scheduleRespawn(node, savedAvailableAt)
		return
	end

	activeNodes[node] = true
	local committed, code, availableAt = IslandSessionService.commitResourceGathering(
		player.UserId,
		player,
		definition.id,
		os.time()
	)
	if not committed then
		activeNodes[node] = nil
		if code == "NODE_COOLDOWN" and availableAt ~= nil then
			node:SetAttribute("AvailableAt", availableAt)
			setNodeVisible(node, false)
			scheduleRespawn(node, availableAt)
		elseif code == "PERSIST_PENDING" and availableAt ~= nil then
			-- The reward and cooldown are already in the same in-memory profile
			-- revision. Keep the node unavailable while autosave retries durability.
			node:SetAttribute("AvailableAt", availableAt)
			setNodeVisible(node, false)
			scheduleRespawn(node, availableAt)
		else
			warn(string.format("[PetKingdoms] Gathering failed for %d: %s", player.UserId, code))
		end
		return
	end

	if availableAt == nil then
		activeNodes[node] = nil
		warn("[PetKingdoms] Gathering commit returned no cooldown timestamp.")
		return
	end
	node:SetAttribute("AvailableAt", availableAt)
	setNodeVisible(node, false)
	IslandResourceService.publishSnapshot(player.UserId, "GATHERED")
	scheduleRespawn(node, availableAt)
end

function IslandGatheringService.start()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

	-- Resource nodes are spawned after the island profile loads. Reconcile
	-- their persisted cooldown timestamps so offline time counts toward regen.
	task.spawn(function()
		while true do
			task.wait(5)
			local worlds = workspace:FindFirstChild("PlayerIslands")
			if worlds == nil then continue end
			for _, island in ipairs(worlds:GetChildren()) do
				local nodes = island:FindFirstChild("ResourceNodes")
				if nodes == nil then continue end
				for _, child in ipairs(nodes:GetChildren()) do
					if not child:IsA("Model") then continue end
					local availableAt = child:GetAttribute("AvailableAt")
					if type(availableAt) ~= "number" or availableAt <= 0 then continue end
					if availableAt > os.time() then
						if not activeNodes[child] then
							setNodeVisible(child, false)
							scheduleRespawn(child, availableAt)
						end
					else
						setNodeVisible(child, true)
						activeNodes[child] = nil
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for node in pairs(activeNodes) do
			if node:GetAttribute("OwnerUserId") == player.UserId then
				activeNodes[node] = nil
			end
		end
	end)
end

return IslandGatheringService
