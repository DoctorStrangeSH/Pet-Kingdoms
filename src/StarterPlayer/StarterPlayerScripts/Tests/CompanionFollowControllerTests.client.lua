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

-- Imported meshes often use a center pivot and must be lifted by half their height.
local externalPet = Instance.new("Model")
externalPet.Name = "ExternalMeshPivotTest"
externalPet:SetAttribute("SpeciesId", "bunny")
externalPet:SetAttribute("IsExternalMeshPet", true)
local externalMesh = Instance.new("Part")
externalMesh.Name = "MeshBounds"
externalMesh.Anchored = true
externalMesh.CanCollide = false
externalMesh.Size = Vector3.new(2, 4, 2)
externalMesh.Position = Vector3.new(12, 10, 0)
externalMesh.Parent = externalPet
externalPet.PrimaryPart = externalMesh
externalPet.Parent = folder
local externalController, externalStatus = CompanionFollowController.new(externalPet, target, { slotIndex = 3 })
expect("external mesh with center pivot can follow", externalController ~= nil and externalStatus == "CREATED")
assert(externalController ~= nil)
expect("ground lift follows actual imported mesh bounds", math.abs(externalController.groundLift - 2) < 0.05)
externalController:destroy()
externalPet:Destroy()

-- Verify a single exponential smoothing step: the old controller applied
-- interpolation twice, resulting in alpha squared and sluggish movement.
local smoothTarget = Instance.new("Part")
smoothTarget.Name = "SmoothingTarget"
smoothTarget.Anchored = true
smoothTarget.CanCollide = false
smoothTarget.CanQuery = false
smoothTarget.CFrame = CFrame.new(1200, 80, 1200)
smoothTarget.Parent = folder
local smoothPet = Instance.new("Model")
smoothPet.Name = "SmoothingPet"
smoothPet:SetAttribute("SpeciesId", "bunny")
smoothPet:SetAttribute("IsExternalMeshPet", true)
local smoothPart = Instance.new("Part")
smoothPart.Anchored = true
smoothPart.CanCollide = false
smoothPart.CanQuery = false
smoothPart.Size = Vector3.new(2, 2, 2)
smoothPart.CFrame = CFrame.new(1208, 80, 1200)
smoothPart.Parent = smoothPet
smoothPet.PrimaryPart = smoothPart
smoothPet.Parent = folder
local smoothController, smoothStatus = CompanionFollowController.new(
	smoothPet, smoothTarget, { slotIndex = 1, smoothing = 8 }
)
expect("smoothing test controller created", smoothController ~= nil and smoothStatus == "CREATED")
assert(smoothController ~= nil)
local before = smoothPet:GetPivot().Position
local formationTarget = smoothTarget.CFrame:PointToWorldSpace(Vector3.new(-2.4, 0, 4.5))
smoothController:update(1 / 60)
local after = smoothPet:GetPivot().Position
local expectedAlpha = 1 - math.exp(-8 / 60)
local actualAlpha = (after.X - before.X) / (formationTarget.X - before.X)
expect("follow translation uses one smoothing step, not alpha squared",
	math.abs(actualAlpha - expectedAlpha) < 0.015)
smoothController:destroy()
smoothPet:Destroy()
smoothTarget:Destroy()

-- A visible pet must not slide off its island across a terrain gap just
-- because the direct horizontal raycast happens to be unobstructed.
local edgeFloor = Instance.new("Part")
edgeFloor.Name = "CliffEdgeGround"
edgeFloor.Anchored = true
edgeFloor.Size = Vector3.new(12, 1, 12)
edgeFloor.CFrame = CFrame.new(2000, 3, 2000)
edgeFloor.Parent = folder
local edgeTarget = Instance.new("Part")
edgeTarget.Name = "CliffEdgeOwner"
edgeTarget.Anchored = true
edgeTarget.CanCollide = false
edgeTarget.CanQuery = false
edgeTarget.Position = Vector3.new(2018.4, 5, 2000)
edgeTarget.Parent = folder
local edgePet = Instance.new("Model")
edgePet.Name = "CliffEdgePet"
edgePet:SetAttribute("SpeciesId", "bunny")
edgePet:SetAttribute("IsExternalMeshPet", true)
local edgeRoot = Instance.new("Part")
edgeRoot.Anchored = true
edgeRoot.CanCollide = false
edgeRoot.CanQuery = false
edgeRoot.Size = Vector3.new(2, 2, 2)
edgeRoot.Position = Vector3.new(2000, 5, 2000)
edgeRoot.Parent = edgePet
edgePet.PrimaryPart = edgeRoot
edgePet.Parent = folder
local edgeController = CompanionFollowController.new(edgePet, edgeTarget, { slotIndex = 1 })
expect("cliff-edge companion controller created", edgeController ~= nil)
assert(edgeController ~= nil)
local beforeEdge = edgePet:GetPivot().Position
edgeController:update(1 / 60)
expect("companion does not take a direct shortcut into missing ground",
	(edgePet:GetPivot().Position - beforeEdge).Magnitude < 0.05)
edgeController:destroy()
edgePet:Destroy()
edgeTarget:Destroy()
edgeFloor:Destroy()

-- Direct raycasts + terrain samples are expensive when 3 companions follow
-- a stationary owner. Reuse a recent result until the owner or pet moves.
controllers[2]:update(1 / 60)
local firstProbeCount = controllers[2].directCheckCount
controllers[2]:update(1 / 60)
expect("stationary companion reuses recent direct-route check",
	controllers[2].directCheckCount == firstProbeCount)
local oldTarget = target.CFrame
target.CFrame = oldTarget * CFrame.new(1.5, 0, 0)
controllers[2]:update(1 / 60)
expect("owner movement invalidates the navigation cache",
	controllers[2].directCheckCount == firstProbeCount + 1)
target.CFrame = oldTarget

expect("clear follow lane does not allocate a path", controllers[1].path == nil and #controllers[1].pathWaypoints == 0)

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
-- Reproduce an owner teleport while navigation is waiting on an obstacle route:
-- recovery must use the owner's formation target, not a nearby waypoint.
controllers[1].pathPending = true
controllers[1].pathWaypoints = {}
local previousGeneration = controllers[1].pathGeneration
target.CFrame = target.CFrame + Vector3.new(70, 0, 0)
controllers[1]:update(1 / 60)
expect("teleport recovery cancels pending navigation", not controllers[1].pathPending
	and controllers[1].pathGeneration > previousGeneration
	and #controllers[1].pathWaypoints == 0)
local catchUpTarget = target.CFrame:PointToWorldSpace(Vector3.new(-2.4, 0, 4.5))
expect("lagging companion switches to run", controllers[1].animation.state == "run")
expect("extremely distant companion recovers near its owner",
	(pets[1]:GetPivot().Position - catchUpTarget).Magnitude < 5)

for _, controller in ipairs(controllers) do
	controller:destroy()
	expect("controller disconnects and destroys safely", controller.destroyed and controller.connection == nil and controller.pathBlockedConnection == nil)
end

target:Destroy()
folder:Destroy()
print("[PetKingdoms Test] CompanionFollowController smoke tests completed.")
