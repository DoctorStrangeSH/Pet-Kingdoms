--!strict
-- Studio client smoke tests. Run from StarterPlayerScripts in a dedicated test place.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("RunPetKingdomsStudioTests") ~= true then
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

local floor = Instance.new("Part")
floor.Name = "CompanionFollowTestFloor"
floor.Anchored = true
floor.Size = Vector3.new(200, 1, 200)
floor.Position = Vector3.new(0, -0.5, 0)
floor.Parent = workspace

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

-- A nearby, available wood node should trigger a brief cosmetic curiosity reaction.
local islands = Instance.new("Folder")
islands.Name = "PlayerIslands"
islands.Parent = workspace
local island = Instance.new("Model")
island.Name = "TestIsland"
island:SetAttribute("OwnerUserId", 123456)
island.Parent = islands
local nodes = Instance.new("Folder")
nodes.Name = "ResourceNodes"
nodes.Parent = island
local woodNode = Instance.new("Model")
woodNode.Name = "TestWoodNode"
woodNode:SetAttribute("AvailableAt", os.time())
woodNode:SetAttribute("ResourceId", "wood")
woodNode.Parent = nodes
local woodPart = Instance.new("Part")
woodPart.Anchored = true
woodPart.CanCollide = false
woodPart.Position = pets[1]:GetPivot().Position + Vector3.new(5, 0, 0)
woodPart.Parent = woodNode
pets[1]:SetAttribute("OwnerUserId", 123456)
controllers[1].interactionState = nil
controllers[1].nextEnvironmentScan = 0
controllers[1]:update(1 / 60)
expect("lead Bunny starts walking toward a nearby resource", controllers[1].investigatePosition ~= nil and controllers[1].animation.state == "walk")
local investigationTarget = controllers[1].investigatePosition
assert(investigationTarget ~= nil)
pets[1]:PivotTo(CFrame.new(investigationTarget))
controllers[1]:update(1 / 60)
expect("Bunny inspects the resource after approaching it", controllers[1].animation.state == "curious")
controllers[1].investigateUntil = os.clock() - 1
controllers[1]:update(1 / 60)
expect("Bunny returns to its normal follow formation after inspection", controllers[1].investigatePosition == nil)
islands:Destroy()

local invalidController, invalidStatus = CompanionFollowController.new(pets[1], target, { slotIndex = 4 })
expect("fourth active slot is rejected", invalidController == nil and invalidStatus == "INVALID_SLOT_INDEX")

-- Catch-up must switch to run when the pet falls behind, then recover from
-- extreme streaming/character-reset gaps without remaining stranded far away.
target.AssemblyLinearVelocity = Vector3.zero
target.CFrame = target.CFrame + Vector3.new(70, 0, 0)
controllers[1]:update(1 / 60)
local catchUpTarget = target.CFrame:PointToWorldSpace(Vector3.new(-2.4, 0, 4.5))
expect("lagging companion switches to run", controllers[1].animation.state == "run")
expect("extremely distant companion recovers near its owner",
	(pets[1]:GetPivot().Position - catchUpTarget).Magnitude < 5)

-- A broad wall blocks the straight line to the first formation slot. The
-- controller should choose a grounded side waypoint instead of pushing through it.
target.CFrame = CFrame.new(0, 5, 0)
pets[1]:PivotTo(CFrame.new(0, 0.28, 0))
controllers[1].pathDetourPosition = nil
controllers[1].pathDetourUntil = 0
controllers[1].nextObstacleScan = 0
controllers[1].lastPathTarget = nil
local obstacleDestination = target.CFrame:PointToWorldSpace(Vector3.new(-2.4, 0, 4.5))
local obstacleDirection = (obstacleDestination - pets[1]:GetPivot().Position).Unit
local obstacleMidpoint = (obstacleDestination + pets[1]:GetPivot().Position) * 0.5
local wall = Instance.new("Part")
wall.Name = "CompanionFollowTestWall"
wall.Anchored = true
wall.Size = Vector3.new(8, 4, 1)
local wallCenter = Vector3.new(obstacleMidpoint.X, 1.5, obstacleMidpoint.Z)
wall.CFrame = CFrame.lookAt(wallCenter, wallCenter + obstacleDirection)
wall.Parent = workspace
controllers[1]:update(1 / 60)
local detour = controllers[1].pathDetourPosition
expect("companion detects a wall between itself and its formation slot", detour ~= nil)
if detour ~= nil then
	local side = Vector3.new(-obstacleDirection.Z, 0, obstacleDirection.X)
	local lateralClearance = math.abs((detour - obstacleMidpoint):Dot(side))
	expect("detour clears the wall instead of staying on the blocked centerline", lateralClearance > 4)
	expect("detour remains grounded on the island floor", math.abs(detour.Y - 0.28) < 0.05)
end
wall:Destroy()

for _, controller in ipairs(controllers) do
	controller:destroy()
	expect("controller disconnects and destroys safely", controller.destroyed and controller.connection == nil)
end

target:Destroy()
floor:Destroy()
folder:Destroy()
print("[PetKingdoms Test] CompanionFollowController smoke tests completed.")
