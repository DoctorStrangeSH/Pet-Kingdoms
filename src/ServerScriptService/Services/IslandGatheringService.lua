--!strict
-- Server-authoritative gathering from nodes spawned inside each player's island.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local services = script.Parent
local IslandResourceService = require(services:WaitForChild("IslandResourceService"))

local IslandGatheringService = {}
local RESPAWN_SECONDS = 60
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
			if not visible then descendant.CanTouch = false end
		elseif descendant:IsA("ProximityPrompt") then
			descendant.Enabled = visible
		end
	end
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local node = getNode(prompt)
	if node == nil or activeNodes[node] then return end

	local resourceId = node:GetAttribute("ResourceId")
	local reward = node:GetAttribute("RewardAmount")
	local ownerUserId = node:GetAttribute("OwnerUserId")
	if (resourceId ~= "wood" and resourceId ~= "stone")
		or type(reward) ~= "number" or reward <= 0 or reward ~= math.floor(reward)
		or type(ownerUserId) ~= "number" or ownerUserId ~= player.UserId
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

	activeNodes[node] = true
	local granted, code = IslandResourceService.grant(player.UserId, resourceId, reward)
	if not granted then
		activeNodes[node] = nil
		warn(string.format("[PetKingdoms] Gathering failed for %d: %s", player.UserId, code))
		return
	end

	setNodeVisible(node, false)
	task.delay(RESPAWN_SECONDS, function()
		if node.Parent ~= nil then
			setNodeVisible(node, true)
			activeNodes[node] = nil
		else
			activeNodes[node] = nil
		end
	end)
end

function IslandGatheringService.start()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
	Players.PlayerRemoving:Connect(function(player)
		for node in pairs(activeNodes) do
			if node:GetAttribute("OwnerUserId") == player.UserId then
				activeNodes[node] = nil
			end
		end
	end)
end

return IslandGatheringService
