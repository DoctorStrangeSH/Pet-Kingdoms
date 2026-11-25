--!strict
-- Temporary island-focused camera used only while placing or moving buildings.
-- Default Roblox character camera is restored when construction mode ends.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ConstructionCameraMath = require(script.Parent:WaitForChild("ConstructionCameraMath"))

local ConstructionCameraController = {}

local MIN_DISTANCE = 72
local MAX_DISTANCE = 300
local EDGE_MARGIN = 20
local MIN_PITCH = math.rad(32)
local MAX_PITCH = math.rad(72)
local ORBIT_SENSITIVITY = 0.005
local ZOOM_STEP = 1

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local active = false
local grass: BasePart? = nil
local camera: Camera? = nil
local originalCameraType: Enum.CameraType? = nil
local originalCameraSubject: Instance? = nil
local originalCameraCFrame: CFrame? = nil
local originalFieldOfView = 70

local distance = 160
local yaw = math.rad(38)
local pitch = math.rad(52)
local targetOffset = Vector2.zero

local draggingOrbit = false
local draggingPan = false
local touchPositions: { [InputObject]: Vector2 } = {}
local touchOrder: { InputObject } = {}
local connections: { RBXScriptConnection } = {}

local function connect(signal: RBXScriptSignal, callback: (...any) -> ()): RBXScriptConnection
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function disconnectAll()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function clearGestureState()
	draggingOrbit = false
	draggingPan = false
	table.clear(touchPositions)
	table.clear(touchOrder)
end

local function isOverGui(position: Vector2): boolean
	for _, object in ipairs(playerGui:GetGuiObjectsAtPosition(position.X, position.Y)) do
		if object:IsA("GuiObject") and object.Visible then
			return true
		end
	end
	return false
end

local function clampTargetOffset(nextOffset: Vector2): Vector2
	local currentGrass = grass
	if currentGrass == nil then return Vector2.zero end
	return ConstructionCameraMath.clampPan(
		nextOffset,
		Vector2.new(currentGrass.Size.X * 0.5, currentGrass.Size.Z * 0.5),
		EDGE_MARGIN
	)
end

local function applyPan(screenDelta: Vector2)
	local currentCamera = camera
	local currentGrass = grass
	if not active or currentCamera == nil or currentGrass == nil then return end
	local delta = ConstructionCameraMath.getPanDelta(
		screenDelta,
		distance,
		currentCamera.ViewportSize.Y,
		currentCamera.FieldOfView,
		yaw,
		currentGrass.CFrame
	)
	targetOffset = clampTargetOffset(targetOffset + delta)
end

local function applyZoom(wheelDelta: number)
	distance = ConstructionCameraMath.zoomDistance(distance, wheelDelta * ZOOM_STEP, MIN_DISTANCE, MAX_DISTANCE)
end

local function updateCamera()
	local currentCamera = camera
	local currentGrass = grass
	if not active or currentCamera == nil or currentGrass == nil then return end
	if currentGrass.Parent == nil then
		ConstructionCameraController.Stop()
		return
	end
	currentCamera.CameraType = Enum.CameraType.Scriptable
	currentCamera.CFrame = ConstructionCameraMath.getCameraCFrame(
		currentGrass.CFrame,
		currentGrass.Size.Y,
		targetOffset,
		distance,
		yaw,
		pitch
	)
end

local function removeTouch(input: InputObject)
	if touchPositions[input] == nil then return end
	touchPositions[input] = nil
	for index = #touchOrder, 1, -1 do
		if touchOrder[index] == input then
			table.remove(touchOrder, index)
			break
		end
	end
end

local function updateTouch(input: InputObject)
	if touchPositions[input] == nil then return end
	local first = touchOrder[1]
	local second = touchOrder[2]
	if first == nil or second == nil then
		touchPositions[input] = Vector2.new(input.Position.X, input.Position.Y)
		return
	end

	local oldFirst = touchPositions[first]
	local oldSecond = touchPositions[second]
	if oldFirst == nil or oldSecond == nil then return end
	local oldCenter = (oldFirst + oldSecond) * 0.5
	local oldDistance = (oldFirst - oldSecond).Magnitude

	touchPositions[input] = Vector2.new(input.Position.X, input.Position.Y)

	local newFirst = touchPositions[first]
	local newSecond = touchPositions[second]
	if newFirst == nil or newSecond == nil then return end
	local newCenter = (newFirst + newSecond) * 0.5
	local newDistance = (newFirst - newSecond).Magnitude

	applyPan(newCenter - oldCenter)
	if oldDistance > 8 and newDistance > 8 then
		distance = math.clamp(distance * oldDistance / newDistance, MIN_DISTANCE, MAX_DISTANCE)
	end
end

local function restoreCamera()
	local currentCamera = Workspace.CurrentCamera or camera
	if currentCamera == nil then return end

	local subject = originalCameraSubject
	if subject == nil or subject.Parent == nil then
		local character = player.Character
		subject = if character then character:FindFirstChildOfClass("Humanoid") else nil
	end
	currentCamera.CameraSubject = subject
	currentCamera.FieldOfView = originalFieldOfView
	if originalCameraCFrame then currentCamera.CFrame = originalCameraCFrame end
	currentCamera.CameraType = if originalCameraType == Enum.CameraType.Scriptable
		then Enum.CameraType.Custom
		else (originalCameraType or Enum.CameraType.Custom)
end

function ConstructionCameraController.Start(island: Model?): boolean
	if island == nil or island.Parent == nil then return false end
	local islandGrass = island:FindFirstChild("Island_GrassTop")
	if islandGrass == nil or not islandGrass:IsA("BasePart") then return false end
	local currentCamera = Workspace.CurrentCamera
	if currentCamera == nil then return false end

	if active then ConstructionCameraController.Stop() end

	camera = currentCamera
	grass = islandGrass
	originalCameraType = currentCamera.CameraType
	originalCameraSubject = currentCamera.CameraSubject
	originalCameraCFrame = currentCamera.CFrame
	originalFieldOfView = currentCamera.FieldOfView

	targetOffset = Vector2.zero
	distance = math.clamp(math.max(islandGrass.Size.X, islandGrass.Size.Z) * 0.85, 120, 260)
	local islandForward = islandGrass.CFrame.LookVector
	yaw = math.atan2(-islandForward.X, -islandForward.Z) + math.rad(38)
	pitch = math.rad(52)
	clearGestureState()
	active = true
	currentCamera.CameraType = Enum.CameraType.Scriptable

	connect(RunService.RenderStepped, updateCamera)
	connect(UserInputService.WindowFocusReleased, clearGestureState)
	connect(islandGrass.Destroying, function()
		ConstructionCameraController.Stop()
	end)
	connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
		if not active then return end
		camera = Workspace.CurrentCamera
		if camera then camera.CameraType = Enum.CameraType.Scriptable end
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if not active then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			local position = Vector2.new(input.Position.X, input.Position.Y)
			if processed or isOverGui(position) then return end
			touchPositions[input] = position
			table.insert(touchOrder, input)
			return
		end
		if processed or isOverGui(UserInputService:GetMouseLocation()) then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			draggingOrbit = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			draggingPan = true
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if not active then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			updateTouch(input)
		elseif input.UserInputType == Enum.UserInputType.MouseMovement then
			if draggingOrbit then
				yaw -= input.Delta.X * ORBIT_SENSITIVITY
				pitch = math.clamp(pitch + input.Delta.Y * ORBIT_SENSITIVITY, MIN_PITCH, MAX_PITCH)
			elseif draggingPan then
				applyPan(Vector2.new(input.Delta.X, input.Delta.Y))
			end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			if not isOverGui(UserInputService:GetMouseLocation()) then
				applyZoom(input.Position.Z)
			end
		end
	end)

	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			removeTouch(input)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			draggingOrbit = false
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			draggingPan = false
		end
	end)

	updateCamera()
	return true
end

function ConstructionCameraController.Stop()
	if not active then return end
	active = false
	clearGestureState()
	disconnectAll()
	restoreCamera()
	grass = nil
	camera = nil
	originalCameraType = nil
	originalCameraSubject = nil
	originalCameraCFrame = nil
end

function ConstructionCameraController.IsActive(): boolean
	return active
end

return table.freeze(ConstructionCameraController)
