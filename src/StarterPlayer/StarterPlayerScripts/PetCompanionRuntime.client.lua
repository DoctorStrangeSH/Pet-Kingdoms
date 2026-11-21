--!strict
-- Binds replicated, server-spawned equipped pet models to local follow controllers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local CompanionFollowController = require(script.Parent:WaitForChild("CompanionFollowController"))

local playerFolder: Folder? = nil
local folderConnection: RBXScriptConnection? = nil
local childAddedConnection: RBXScriptConnection? = nil
local childRemovedConnection: RBXScriptConnection? = nil
local characterConnection: RBXScriptConnection? = nil
local controllers: { [Model]: any } = {}
local bindingGeneration = 0

local function destroyControllers()
	for model, controller in pairs(controllers) do
		controller:destroy()
		controllers[model] = nil
	end
end

local function bindPet(model: Instance, generation: number)
	if generation ~= bindingGeneration or not model:IsA("Model") or controllers[model] then
		return
	end

	local character = player.Character
	local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
	if targetRoot == nil or not targetRoot:IsA("BasePart") then
		return
	end
	if model:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end

	local slotIndex = model:GetAttribute("FormationSlot")
	if type(slotIndex) ~= "number" then
		return
	end

	local controller, status = CompanionFollowController.new(model, targetRoot, {
		slotIndex = slotIndex,
	})
	if controller then
		controllers[model] = controller
	else
		warn("[PetKingdoms] Could not bind pet follow controller:", model.Name, status)
	end
end

local function bindAllPets(generation: number)
	if playerFolder == nil then
		return
	end
	for _, child in ipairs(playerFolder:GetChildren()) do
		bindPet(child, generation)
	end
end

local function attachToCurrentFolder()
	bindingGeneration += 1
	local generation = bindingGeneration
	destroyControllers()

	if childAddedConnection then childAddedConnection:Disconnect() end
	if childRemovedConnection then childRemovedConnection:Disconnect() end
	if folderConnection then folderConnection:Disconnect() end
	playerFolder = nil

	local root = Workspace:FindFirstChild("PlayerPets")
	if root == nil then
		folderConnection = Workspace.ChildAdded:Connect(function(child)
			if child.Name == "PlayerPets" then
				attachToCurrentFolder()
			end
		end)
		return
	end

	local existing = root:FindFirstChild(tostring(player.UserId))
	if existing and existing:IsA("Folder") then
		playerFolder = existing
	else
		folderConnection = root.ChildAdded:Connect(function(child)
			if child.Name == tostring(player.UserId) and child:IsA("Folder") then
				attachToCurrentFolder()
			end
		end)
		return
	end

	childAddedConnection = playerFolder.ChildAdded:Connect(function(child)
		task.defer(bindPet, child, generation)
	end)
	childRemovedConnection = playerFolder.ChildRemoved:Connect(function(child)
		if child:IsA("Model") then
			local controller = controllers[child]
			if controller then
				controller:destroy()
				controllers[child] = nil
			end
		end
	end)

	bindAllPets(generation)
end

local function onCharacterAdded(character: Model)
	bindingGeneration += 1
	destroyControllers()
	local generation = bindingGeneration
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root == nil or not root:IsA("BasePart") then
		warn("[PetKingdoms] Character root not available; pet follow will retry on next spawn.")
		return
	end
	task.defer(bindAllPets, generation)
end

characterConnection = player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(function()
	bindingGeneration += 1
	destroyControllers()
end)

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
attachToCurrentFolder()

print("[PetKingdoms] Pet companion runtime loaded.")
