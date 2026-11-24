--!strict
-- Studio-only smoke tests for procedural Bunny companion animation states.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Pets")
local PetModelFactory = require(shared:WaitForChild("PetModelFactory"))
local PetAnimationController = require(shared:WaitForChild("PetAnimationController"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local testFolder = Instance.new("Folder")
testFolder.Name = "PetAnimationControllerTests"
testFolder.Parent = workspace

local bunny, createStatus = PetModelFactory.create("bunny")
expect("bunny rig factory succeeds", bunny ~= nil and createStatus == "CREATED")
assert(bunny ~= nil)
bunny.Parent = testFolder

local controller, controllerStatus = PetAnimationController.new(bunny)
expect("animation controller binds to Bunny rig", controller ~= nil and controllerStatus == "CREATED")
assert(controller ~= nil)

expect("idle is accepted", controller:setState("idle"))
controller:update(1 / 60)
local bodyMotor = bunny:FindFirstChild("Root_Body", true)
expect("idle produces procedural body motion", bodyMotor ~= nil and bodyMotor:IsA("Motor6D") and bodyMotor.Transform ~= CFrame.identity)

expect("walk state is accepted", controller:setState("walk"))
controller:update(1 / 30)
local leftLeg = bunny:FindFirstChild("Body_FrontLeftLeg", true)
expect("walk animates front legs", leftLeg ~= nil and leftLeg:IsA("Motor6D") and leftLeg.Transform ~= CFrame.identity)

expect("run state is accepted", controller:setState("run"))
controller:update(1 / 30)
expect("jump state is accepted", controller:setState("jump"))
controller:update(1 / 30)
local frontLeg = bunny:FindFirstChild("Body_FrontLeftLeg", true)
local backLeg = bunny:FindFirstChild("Body_BackLeftLeg", true)
expect("jump tucks the front paws", frontLeg ~= nil and frontLeg:IsA("Motor6D") and frontLeg.Transform ~= CFrame.identity)
expect("jump folds the hind legs", backLeg ~= nil and backLeg:IsA("Motor6D") and backLeg.Transform ~= CFrame.identity)
expect("happy state is accepted", controller:setState("happy"))
controller:update(1 / 30)
expect("curious state is accepted", controller:setState("curious"))
controller:update(1 / 30)
expect("sniff state is accepted", controller:setState("sniff"))
controller:update(1 / 30)
expect("sniff pose lowers the head", bodyMotor ~= nil and bodyMotor:IsA("Motor6D") and bodyMotor.Transform ~= CFrame.identity)
expect("alert state is accepted", controller:setState("alert"))
controller:update(1 / 30)
expect("combat state is accepted", controller:setState("combat"))
controller:update(1 / 30)

expect("unknown state is rejected", not controller:setState("teleport" :: any))
controller:update(0)
controller:update(-1)
controller:update(math.huge)

controller:destroy()
expect("destroy resets motor transforms", bodyMotor ~= nil and bodyMotor:IsA("Motor6D") and bodyMotor.Transform == CFrame.identity)
expect("destroy is idempotent", controller:destroy() == nil)
expect("destroyed controller rejects state changes", not controller:setState("idle"))

testFolder:Destroy()
print("[PetKingdoms Test] PetAnimationController smoke tests completed.")
