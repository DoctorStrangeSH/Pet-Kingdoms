--!strict
-- Studio-only tests for imported model pivot normalization.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local BuildingModelPivot = require(script.Parent.Parent:WaitForChild("BuildingModelPivot"))
local Workspace = game:GetService("Workspace")

local function expect(label: string, condition: boolean)
	if not condition then
		error("[PetKingdoms Test] FAILED: " .. label)
	end
	print("[PetKingdoms Test] PASS: " .. label)
end

local model = Instance.new("Model")
model.Name = "BuildingPivotTestFixture"
local first = Instance.new("Part")
first.Name = "Wall"
first.Anchored = true
first.Size = Vector3.new(8, 5, 6)
first.CFrame = CFrame.new(12, 8, 24)
first.Parent = model
local second = Instance.new("Part")
second.Name = "Roof"
second.Anchored = true
second.Size = Vector3.new(10, 2, 8)
second.CFrame = CFrame.new(12, 11.5, 24)
second.Parent = model
-- Keep the fixture unparented, matching a freshly cloned ServerStorage template.

local authoredPivot = CFrame.new(17, 13, 29) * CFrame.Angles(0, math.rad(37), 0)
model:PivotTo(authoredPivot)
local boundsCFrame, boundsSize = model:GetBoundingBox()
local expectedGroundCenter = boundsCFrame.Position - boundsCFrame.UpVector * (boundsSize.Y / 2)
local expectedRotation = model:GetPivot().Rotation

local bounds = BuildingModelPivot.normalizeToGroundCenter(model)
expect("valid model returns visual bounds", bounds ~= nil)
expect("normalized pivot is at visual ground center",
	(model:GetPivot().Position - expectedGroundCenter).Magnitude < 0.001)
expect("normalization preserves authored model orientation",
	model:GetPivot().LookVector:Dot(expectedRotation.LookVector) > 0.999)
expect("visual width/depth/height are reported",
	bounds ~= nil
		and math.abs(bounds.width - boundsSize.X) < 0.001
		and math.abs(bounds.depth - boundsSize.Z) < 0.001
		and math.abs(bounds.height - boundsSize.Y) < 0.001)

local normalizedPivot = model:GetPivot()
local secondBounds = BuildingModelPivot.normalizeToGroundCenter(model)
expect("normalization is idempotent",
	secondBounds ~= nil and (model:GetPivot().Position - normalizedPivot.Position).Magnitude < 0.001)

model:Destroy()
print("[PetKingdoms Test] BuildingModelPivot smoke tests completed.")
