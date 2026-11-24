--!strict
-- Studio-only smoke tests for the first procedural pet rig prototype.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local PetModelFactory = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared")
	:WaitForChild("Pets")
	:WaitForChild("PetModelFactory"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local bunny, status = PetModelFactory.create("bunny")
expect("bunny factory returns a model", bunny ~= nil and status == "CREATED")
assert(bunny ~= nil)

expect("stable species attribute", bunny:GetAttribute("SpeciesId") == "bunny")
expect("rig version attribute", bunny:GetAttribute("RigVersion") == 1)
expect("prototype is explicitly marked", bunny:GetAttribute("IsPetRigPrototype") == true)
expect("ground contact offset is available to the follow controller", bunny:GetAttribute("GroundOffset") == 0.28)
expect("root is primary part", bunny.PrimaryPart ~= nil and bunny.PrimaryPart.Name == "HumanoidRootPart")
expect("root is anchored for safe PivotTo-driven companion movement", bunny.PrimaryPart ~= nil and bunny.PrimaryPart.Anchored)
expect("animation controller exists", bunny:FindFirstChildOfClass("AnimationController") ~= nil)

local controller = bunny:FindFirstChildOfClass("AnimationController")
expect("animator exists", controller ~= nil and controller:FindFirstChildOfClass("Animator") ~= nil)
expect("follow attachment exists", bunny.PrimaryPart ~= nil and bunny.PrimaryPart:FindFirstChild("FollowAttachment") ~= nil)
expect("ground attachment exists", bunny.PrimaryPart ~= nil and bunny.PrimaryPart:FindFirstChild("GroundContact") ~= nil)
expect("eye highlights exist", bunny:FindFirstChild("EyeGlint_Left", true) ~= nil and bunny:FindFirstChild("EyeGlint_Right", true) ~= nil)
expect("mouth details exist", bunny:FindFirstChild("Mouth_Left", true) ~= nil and bunny:FindFirstChild("Mouth_Right", true) ~= nil)
expect("three whiskers on each cheek", bunny:FindFirstChild("Whisker_-1_1", true) ~= nil and bunny:FindFirstChild("Whisker_-1_2", true) ~= nil and bunny:FindFirstChild("Whisker_-1_3", true) ~= nil and bunny:FindFirstChild("Whisker_1_1", true) ~= nil and bunny:FindFirstChild("Whisker_1_2", true) ~= nil and bunny:FindFirstChild("Whisker_1_3", true) ~= nil)
expect("forehead tuft exists", bunny:FindFirstChild("Forehead_Tuft", true) ~= nil)

local motorCount = 0
local allPartsSafe = true
for _, descendant in ipairs(bunny:GetDescendants()) do
	if descendant:IsA("Motor6D") then
		motorCount += 1
	elseif descendant:IsA("BasePart") then
		if (descendant ~= bunny.PrimaryPart and descendant.Anchored) or descendant.CanCollide or descendant.CanTouch or not descendant.Massless then
			allPartsSafe = false
		end
	end
end

expect("bunny has a complete 17-joint prototype rig", motorCount == 17)
expect("all visual parts are non-colliding and massless", allPartsSafe)

local scaledBunny, scaledStatus = PetModelFactory.create("bunny", 1.5)
expect("valid scale accepted", scaledBunny ~= nil and scaledStatus == "CREATED")
if scaledBunny then
	expect("scale is recorded", scaledBunny:GetAttribute("Scale") == 1.5)
	expect("ground contact offset scales with the rig", math.abs((scaledBunny:GetAttribute("GroundOffset") or 0) - 0.42) < 0.001)
	scaledBunny:Destroy()
end

local unknown, unknownStatus = PetModelFactory.create("unknown_pet")
expect("unknown species rejected", unknown == nil and unknownStatus == "UNKNOWN_SPECIES")

local invalid, invalidStatus = PetModelFactory.create("bunny", 0)
expect("zero scale rejected", invalid == nil and invalidStatus == "INVALID_SCALE")

bunny:Destroy()
print("[PetKingdoms Test] PetModelFactory smoke tests completed.")
