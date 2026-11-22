--!strict
-- Client-side companion follow controller.
-- One controller per equipped pet; slotIndex 1..3 provides deterministic formation spacing.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PetAnimationController = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetAnimationController")
)

local CompanionFollowController = {}
CompanionFollowController.__index = CompanionFollowController

export type FollowOptions = {
	slotIndex: number?,
	followDistance: number?,
	sideSpacing: number?,
	smoothing: number?,
	walkSpeed: number?,
	runSpeed: number?,
}

export type FollowController = {
	model: Model,
	targetRoot: BasePart,
	slotIndex: number,
	followDistance: number,
	sideSpacing: number,
	smoothing: number,
	walkSpeed: number,
	runSpeed: number,
	animation: any,
	connection: RBXScriptConnection?,
	destroyed: boolean,
	lastFacing: Vector3,
	idleElapsed: number,
	nextIdleActionAt: number,
	idleActionRemaining: number,
	idleActionState: string,
	interactionState: string?,
	interactionUntil: number,
	interactionConnection: RBXScriptConnection?,
	groundRaycastParams: RaycastParams,
	update: (self: FollowController, dt: number) -> (),
	destroy: (self: FollowController) -> (),
}

local MAX_ACTIVE_SLOTS = 3

local function horizontal(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function getSlotOffset(slotIndex: number, sideSpacing: number, followDistance: number): Vector3
	if slotIndex == 1 then
		return Vector3.new(-sideSpacing, 0, followDistance)
	elseif slotIndex == 2 then
		return Vector3.new(sideSpacing, 0, followDistance)
	end
	return Vector3.new(0, 0, followDistance + sideSpacing * 0.8)
end

local function resolveGroundPosition(model: Model, desired: Vector3, params: RaycastParams): Vector3
	local scale = model:GetAttribute("Scale")
	local resolvedScale = if type(scale) == "number" then scale else 1
	local origin = desired + Vector3.new(0, 8, 0)
	local result = Workspace:Raycast(origin, Vector3.new(0, -32, 0), params)
	if result then
		return Vector3.new(desired.X, result.Position.Y + 0.28 * resolvedScale, desired.Z)
	end
	return desired
end

function CompanionFollowController.new(
	model: Model,
	targetRoot: BasePart,
	options: FollowOptions?
): (FollowController?, string)
	if not model:IsA("Model") or model.PrimaryPart == nil then
		return nil, "INVALID_PET_MODEL"
	end
	if not targetRoot:IsA("BasePart") or not targetRoot:IsDescendantOf(Workspace) then
		return nil, "INVALID_TARGET_ROOT"
	end
	if model:GetAttribute("SpeciesId") ~= "bunny" then
		return nil, "UNSUPPORTED_PET_SPECIES"
	end

	local settings = options or {}
	local slotIndex = settings.slotIndex or 1
	if type(slotIndex) ~= "number" or slotIndex % 1 ~= 0 or slotIndex < 1 or slotIndex > MAX_ACTIVE_SLOTS then
		return nil, "INVALID_SLOT_INDEX"
	end

	local animation = nil
	if model:GetAttribute("IsExternalMeshPet") ~= true then
		local animationStatus: string
		animation, animationStatus = PetAnimationController.new(model)
		if animation == nil then
			return nil, animationStatus
		end
	end

	local groundRaycastParams = RaycastParams.new()
	groundRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	groundRaycastParams.FilterDescendantsInstances = { model, targetRoot.Parent }
	groundRaycastParams.IgnoreWater = false

	local self = setmetatable({
		model = model,
		targetRoot = targetRoot,
		groundRaycastParams = groundRaycastParams,
		slotIndex = slotIndex,
		followDistance = math.clamp(settings.followDistance or 4.5, 3, 8),
		sideSpacing = math.clamp(settings.sideSpacing or 2.4, 1.5, 4),
		smoothing = math.clamp(settings.smoothing or 8, 2, 16),
		walkSpeed = math.clamp(settings.walkSpeed or 1.5, 0.5, 4),
		runSpeed = math.clamp(settings.runSpeed or 18, 5, 24),
		animation = animation,
		connection = nil,
		destroyed = false,
		lastFacing = horizontal(targetRoot.CFrame.LookVector).Unit,
		idleElapsed = 0,
		nextIdleActionAt = math.random(35, 65) / 10,
		idleActionRemaining = 0,
		idleActionState = "idle",
		interactionState = nil,
		interactionUntil = 0,
		interactionConnection = nil,
	}, CompanionFollowController)

	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	if character and model:IsDescendantOf(character) then
		if animation then
			animation:destroy()
		end
		return nil, "PET_CANNOT_BE_PARENTED_TO_CHARACTER"
	end

	self.interactionConnection = model:GetAttributeChangedSignal("InteractionSequence"):Connect(function()
		local emotion = model:GetAttribute("InteractionEmotion")
		if emotion == "happy" or emotion == "curious" then
			self.interactionState = emotion
			self.interactionUntil = os.clock() + 1.8
		end
	end)

	self.connection = RunService.RenderStepped:Connect(function(dt)
		self:update(dt)
	end)
	return (self :: any) :: FollowController, "CREATED"
end

function CompanionFollowController.update(self: FollowController, dt: number)
	if self.destroyed or self.model.Parent == nil or self.targetRoot.Parent == nil then
		self:destroy()
		return
	end
	if type(dt) ~= "number" or dt <= 0 or dt ~= dt then
		return
	end

	local targetVelocity = horizontal(self.targetRoot.AssemblyLinearVelocity)
	local speed = targetVelocity.Magnitude
	local state = if speed >= self.runSpeed then "run" else if speed >= self.walkSpeed then "walk" else "idle"

	if state == "idle" then
		self.idleElapsed += dt
		if self.idleActionRemaining > 0 then
			self.idleActionRemaining = math.max(0, self.idleActionRemaining - dt)
			state = self.idleActionState
			if self.idleActionRemaining <= 0 then
				self.idleActionState = "idle"
				self.nextIdleActionAt = self.idleElapsed + math.random(40, 75) / 10
			end
		elseif self.idleElapsed >= self.nextIdleActionAt then
			local actions = { "sniff", "curious", "happy" }
			self.idleActionState = actions[math.random(1, #actions)]
			self.idleActionRemaining = math.random(12, 24) / 10
			state = self.idleActionState
		end
	else
		self.idleElapsed = 0
		self.idleActionRemaining = 0
		self.idleActionState = "idle"
		self.nextIdleActionAt = math.random(35, 65) / 10
	end
	-- Player-triggered affection/play reactions take priority over autonomous idle actions.
	-- Movement states still win so an interaction never freezes a moving companion.
	if speed < self.walkSpeed and self.interactionState ~= nil then
		if os.clock() < self.interactionUntil then
			state = self.interactionState
		else
			self.interactionState = nil
		end
	end
	if self.animation then
		self.animation:setState(state)
	end

	local offset = getSlotOffset(self.slotIndex, self.sideSpacing, self.followDistance)
	local desired = self.targetRoot.CFrame:PointToWorldSpace(offset)
	desired = resolveGroundPosition(self.model, desired, self.groundRaycastParams)

	local facing = if speed > 0.75 then targetVelocity.Unit else horizontal(self.targetRoot.CFrame.LookVector)
	if facing.Magnitude > 0.001 then
		self.lastFacing = facing.Unit
	end

	local current = self.model:GetPivot()
	local currentPosition = current.Position
	local alpha = 1 - math.exp(-self.smoothing * math.min(dt, 0.1))
	local nextPosition = currentPosition:Lerp(desired, alpha)
	local targetCFrame = CFrame.lookAt(nextPosition, nextPosition + self.lastFacing)
	self.model:PivotTo(current:Lerp(targetCFrame, alpha))
	if self.animation then
		self.animation:update(dt)
	end
end

function CompanionFollowController.destroy(self: FollowController)
	if self.destroyed then
		return
	end
	self.destroyed = true
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	if self.interactionConnection then
		self.interactionConnection:Disconnect()
		self.interactionConnection = nil
	end
	if self.animation then
		self.animation:destroy()
	end
end

return CompanionFollowController
