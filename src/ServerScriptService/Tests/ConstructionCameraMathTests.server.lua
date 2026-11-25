--!strict
-- Opt-in pure geometry tests for the construction camera.
local Workspace = game:GetService("Workspace")
if Workspace:GetAttribute("RunConstructionCameraMathTests") ~= true then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Building"):WaitForChild("ConstructionCameraMath")
)

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local function near(a: number, b: number, epsilon: number?): boolean
	return math.abs(a - b) <= (epsilon or 1e-3)
end

local clamped = CameraMath.clampPan(Vector2.new(200, -200), Vector2.new(96, 96), 20)
expect("pan clamps to playable island bounds", near(clamped.X, 76) and near(clamped.Y, -76))

local smallIsland = CameraMath.clampPan(Vector2.new(30, -30), Vector2.new(12, 12), 20)
expect("small island cannot produce inverted pan bounds", smallIsland.Magnitude == 0)

local zoomedIn = CameraMath.zoomDistance(160, 1, 72, 300)
local zoomedOut = CameraMath.zoomDistance(160, -1, 72, 300)
expect("positive wheel delta zooms in", zoomedIn < 160)
expect("negative wheel delta zooms out", zoomedOut > 160)
expect("zoom respects minimum distance", near(CameraMath.zoomDistance(72, 20, 72, 300), 72))
expect("zoom respects maximum distance", near(CameraMath.zoomDistance(300, -20, 72, 300), 300))

local grass = CFrame.new(15, 8, -20) * CFrame.Angles(0, math.rad(90), 0)
local cameraFrame = CameraMath.getCameraCFrame(grass, 4, Vector2.zero, 120, math.rad(38), math.rad(52))
local expectedTarget = grass:PointToWorldSpace(Vector3.new(0, 4, 0))
expect("camera looks at island surface target", (cameraFrame.Position - expectedTarget).Magnitude > 0)
expect("camera keeps requested orbit distance", near((cameraFrame.Position - expectedTarget).Magnitude, 120, 1e-2))
expect("camera look vector points toward island target", cameraFrame.LookVector:Dot((expectedTarget - cameraFrame.Position).Unit) > 0.999)

local zeroPan = CameraMath.getPanDelta(Vector2.zero, 160, 900, 70, 0, CFrame.identity)
expect("zero screen movement produces zero pan", zeroPan.Magnitude == 0)

local pan = CameraMath.getPanDelta(Vector2.new(100, 50), 160, 900, 70, math.rad(38), grass)
expect("pan delta remains finite and nonzero", pan.Magnitude > 0 and pan.X == pan.X and pan.Y == pan.Y)

local expandedClamp = CameraMath.clampPan(Vector2.new(500, 500), Vector2.new(160, 160), 20)
expect("expanded island permits a larger camera travel range", near(expandedClamp.X, 140) and near(expandedClamp.Y, 140))

print("[PetKingdoms Test] ConstructionCameraMath tests completed.")
