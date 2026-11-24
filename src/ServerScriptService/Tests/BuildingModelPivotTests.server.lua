--!strict
-- Studio-only tests for imported model pivot normalization.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local BuildingModelPivot = require(script.Parent.Parent:WaitForChild("BuildingModelPivot"))

local function expect(label: string, condition: boolean)
	if not condition then
		error("[PetKingdoms Test] FAILED: " .. label)
	end
	print("[PetKingdoms Test] PASS: " .. label)
end

local fitInside = BuildingModelPivot.checkFootprintFit(
	{ width = 9.5, height = 4, depth = 9.8 },
	2,
	2,
	5
)
expect("visual bounds inside grid footprint are accepted", fitInside ~= nil and fitInside.fits)
expect("visual bounds do not report negative overhang",
	fitInside ~= nil and fitInside.overhangX == 0 and fitInside.overhangZ == 0)

local fitWithinTolerance = BuildingModelPivot.checkFootprintFit(
	{ width = 10.2, height = 4, depth = 10.1 },
	2,
	2,
	5,
	0.25
)
expect("tiny visual overhang inside tolerance is accepted",
	fitWithinTolerance ~= nil and fitWithinTolerance.fits)

local fitOutside = BuildingModelPivot.checkFootprintFit(
	{ width = 10.6, height = 4, depth = 11.1 },
	2,
	2,
	5,
	0.25
)
expect("visual bounds beyond tolerance are reported",
	fitOutside ~= nil and not fitOutside.fits
		and math.abs(fitOutside.overhangX - 0.6) < 0.001
		and math.abs(fitOutside.overhangZ - 1.1) < 0.001)

local invalidFit = BuildingModelPivot.checkFootprintFit(
	{ width = 10, height = 4, depth = 10 },
	2,
	2,
	0
)
expect("invalid cell size rejects footprint diagnostics", invalidFit == nil)

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
