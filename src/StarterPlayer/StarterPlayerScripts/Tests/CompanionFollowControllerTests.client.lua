--!strict
-- Studio client smoke tests. Run from StarterPlayerScripts in a dedicated test place.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedPets = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets")
local PetModelFactory = require(sharedPets:WaitForChild("PetModelFactory"))
local CompanionFollowController = require(script.Parent.Parent:WaitForChild("CompanionFollowController"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local folder = Instance.new("Folder")
folder.Name = "CompanionFollowControllerTests"
folder.Parent = workspace

local target = Instance.new("Part")
target.Name = "TestTargetRoot"
target.Anchored = true
target.CanCollide = false
target.Size = Vector3.new(2, 2, 1)
target.CFrame = CFrame.new(0, 5, 0)
target.Parent = folder

local pets = {}
local controllers = {}
for slot = 1, 3 do
	local pet, status = PetModelFactory.create("bunny")
	expect("factory creates pet for slot " .. tostring(slot), pet ~= nil and status == "CREATED")
	assert(pet ~= nil)
	pet.Parent = folder
	table.insert(pets, pet)

	local controller, followStatus = CompanionFollowController.new(pet, target, { slotIndex = slot })
	expect("follow controller accepts slot " .. tostring(slot), controller ~= nil and followStatus == "CREATED")
	assert(controller ~= nil)
	table.insert(controllers, controller)
	controller:update(1 / 60)
	expect("pet remains in test world for slot " .. tostring(slot), pet.Parent == folder)
end

local firstPosition = pets[1]:GetPivot().Position
local secondPosition = pets[2]:GetPivot().Position
expect("formation slots produce distinct pet positions", (firstPosition - secondPosition).Magnitude > 0.5)

local observedIdlePersonality = false
for _ = 1, 900 do
	controllers[1]:update(1 / 60)
	local state = controllers[1].animation.state
	if state == "sniff" or state == "curious" or state == "happy" then
		observedIdlePersonality = true
		break
	end
end
expect("stationary Bunny performs an autonomous personality action", observedIdlePersonality)

-- A direct player interaction must override an autonomous idle animation already in progress.
controllers[1].idleActionState = "sniff"
controllers[1].idleActionRemaining = 1
pets[1]:SetAttribute("InteractionEmotion", "happy")
pets[1]:SetAttribute("InteractionSequence", 1)
task.wait()
controllers[1]:update(1 / 60)
expect("player interaction overrides autonomous idle action", controllers[1].animation.state == "happy")

-- Movement remains the higher-priority state while an interaction reaction is active.
target.AssemblyLinearVelocity = Vector3.new(0, 0, -10)
controllers[1]:update(1 / 60)
expect("movement animation overrides interaction reaction", controllers[1].animation.state == "walk")
target.AssemblyLinearVelocity = Vector3.zero

local invalidController, invalidStatus = CompanionFollowController.new(pets[1], target, { slotIndex = 4 })
expect("fourth active slot is rejected", invalidController == nil and invalidStatus == "INVALID_SLOT_INDEX")

for _, controller in ipairs(controllers) do
	controller:destroy()
	expect("controller disconnects and destroys safely", controller.destroyed and controller.connection == nil)
end

target:Destroy()
folder:Destroy()
print("[PetKingdoms Test] CompanionFollowController smoke tests completed.")
