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
	turnSmoothing: number?,
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
	turnSmoothing: number,
	movementSpeed: number,
	walkSpeed: number,
	runSpeed: number,
	catchUpDistance: number,
	teleportDistance: number,
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
	environmentState: string?,
	environmentUntil: number,
	nextEnvironmentScan: number,
	investigatePosition: Vector3?,
	investigateUntil: number,
	lastInvestigatedNode: Instance?,
	lastInvestigatedAt: number,
	interactionConnection: RBXScriptConnection?,
	pathDetourPosition: Vector3?,
	pathDetourUntil: number,
	nextObstacleScan: number,
	lastPathTarget: Vector3?,
	jumpElapsed: number,
	jumpDuration: number,
	jumpHeight: number,
	wasOwnerAirborne: boolean,
	groundNormal: Vector3,
	nextGroundNormalScan: number,
	nextJumpAt: number,
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
	local groundOffset = model:GetAttribute("GroundOffset")
	local resolvedOffset = if type(groundOffset) == "number"
		then math.clamp(groundOffset, 0.08, 1.2)
		else 0.28 * resolvedScale
	local origin = desired + Vector3.new(0, 8, 0)
	local result = Workspace:Raycast(origin, Vector3.new(0, -32, 0), params)
	if result then
		return Vector3.new(desired.X, result.Position.Y + resolvedOffset, desired.Z)
	end
	return desired
end

local MAX_COMPANION_SLOPE_DEGREES = 50
local function resolveGroundNormal(desired: Vector3, params: RaycastParams): Vector3
	local result = Workspace:Raycast(
		desired + Vector3.new(0, 8, 0),
		Vector3.new(0, -32, 0),
		params
	)
	if result == nil then
		return Vector3.yAxis
	end

	local normal = result.Normal.Unit
	if normal:Dot(Vector3.yAxis) < math.cos(math.rad(MAX_COMPANION_SLOPE_DEGREES)) then
		return Vector3.yAxis
	end
	return normal
end

-- A short local detour is cheaper than recomputing a full navigation path every
-- frame. It lets a companion move around nearby walls/buildings while keeping
-- the server authoritative for all gameplay interactions and rewards.
local function findObstacleDetour(
	model: Model,
	currentPosition: Vector3,
	desiredPosition: Vector3,
	params: RaycastParams
): Vector3?
	local displacement = horizontal(desiredPosition - currentPosition)
	if displacement.Magnitude < 2.5 then
		return nil
	end

	local direction = displacement.Unit
	local origin = currentPosition + Vector3.new(0, 1, 0)
	local destination = desiredPosition + Vector3.new(0, 1, 0)
	local obstacle = Workspace:Raycast(origin, destination - origin, params)
	if obstacle == nil then
		return nil
	end

	local side = Vector3.new(-direction.Z, 0, direction.X)
	local extents = model:GetExtentsSize()
	local petRadius = math.max(extents.X, extents.Z) * 0.5
	local obstacleHalfWidth = 0
	if obstacle.Instance:IsA("BasePart") then
		local obstaclePart = obstacle.Instance :: BasePart
		obstacleHalfWidth = math.abs(side:Dot(obstaclePart.CFrame.RightVector)) * obstaclePart.Size.X * 0.5
			+ math.abs(side:Dot(obstaclePart.CFrame.LookVector)) * obstaclePart.Size.Z * 0.5
	end
	local approachDistance = math.max(0.25, obstacle.Distance - 1.5)
	local remainingDistance = math.max(0.5, displacement.Magnitude - approachDistance)
	local lateralRetention = math.clamp(
		(displacement.Magnitude - obstacle.Distance) / remainingDistance,
		0.15,
		1
	)
	-- The waypoint-to-target segment converges back toward the formation slot.
	-- Increase its side offset so it still clears the wall at the exact crossing.
	local clearance = math.clamp((obstacleHalfWidth + petRadius + 1.5) / lateralRetention, 3.5, 14)
	local bestCandidate: Vector3? = nil
	local bestRouteLength = math.huge

	for _, sideSign in ipairs({ -1, 1 }) do
		-- Stop short of the obstacle, move laterally around its edge, then
		-- let the next update resume the direct route to the formation slot.
		local candidate = currentPosition + direction * approachDistance + side * (clearance * sideSign)
		candidate = Vector3.new(candidate.X, desiredPosition.Y, candidate.Z)
		local groundResult = Workspace:Raycast(
			candidate + Vector3.new(0, 8, 0),
			Vector3.new(0, -32, 0),
			params
		)
		if groundResult ~= nil then
			local groundOffset = model:GetAttribute("GroundOffset")
			local resolvedOffset = if type(groundOffset) == "number"
				then math.clamp(groundOffset, 0.08, 1.2)
				else 0.28
			candidate = Vector3.new(candidate.X, groundResult.Position.Y + resolvedOffset, candidate.Z)

			local candidateProbe = candidate + Vector3.new(0, 1, 0)
			local firstBlocked = Workspace:Raycast(origin, candidateProbe - origin, params) ~= nil
			local secondBlocked = Workspace:Raycast(candidateProbe, destination - candidateProbe, params) ~= nil
			if not firstBlocked and not secondBlocked then
				local routeLength = horizontal(candidate - currentPosition).Magnitude
					+ horizontal(desiredPosition - candidate).Magnitude
				if routeLength < bestRouteLength then
					bestRouteLength = routeLength
					bestCandidate = candidate
				end
			end
		end
	end

	-- If neither side has a grounded, clear route, keep the direct target and
	-- retry later rather than steering the pet into a wall or off the island.
	return bestCandidate
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

	local initialFacing = horizontal(targetRoot.CFrame.LookVector)
	if initialFacing.Magnitude <= 0.001 then
		initialFacing = Vector3.new(0, 0, -1)
	else
		initialFacing = initialFacing.Unit
	end

	local self = setmetatable({
		model = model,
		targetRoot = targetRoot,
		groundRaycastParams = groundRaycastParams,
		slotIndex = slotIndex,
		followDistance = math.clamp(settings.followDistance or 4.5, 3, 8),
		sideSpacing = math.clamp(settings.sideSpacing or 2.4, 1.5, 4),
		smoothing = math.clamp(settings.smoothing or 8, 2, 16),
		turnSmoothing = math.clamp(settings.turnSmoothing or 9, 4, 18),
		movementSpeed = 0,
		walkSpeed = math.clamp(settings.walkSpeed or 1.5, 0.5, 4),
		runSpeed = math.clamp(settings.runSpeed or 18, 5, 24),
		catchUpDistance = 8,
		teleportDistance = 55,
		animation = animation,
		connection = nil,
		destroyed = false,
		lastFacing = initialFacing,
		idleElapsed = 0,
		nextIdleActionAt = math.random(35, 65) / 10,
		idleActionRemaining = 0,
		idleActionState = "idle",
		interactionState = nil,
		interactionUntil = 0,
		environmentState = nil,
		environmentUntil = 0,
		nextEnvironmentScan = 0,
		investigatePosition = nil,
		investigateUntil = 0,
		lastInvestigatedNode = nil,
		lastInvestigatedAt = 0,
		interactionConnection = nil,
		pathDetourPosition = nil,
		pathDetourUntil = 0,
		nextObstacleScan = 0,
		lastPathTarget = nil,
		jumpElapsed = -1,
		jumpDuration = 0.68,
		jumpHeight = 2.2,
		wasOwnerAirborne = false,
		groundNormal = Vector3.yAxis,
		nextGroundNormalScan = 0,
		nextJumpAt = 0,
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
	local offset = getSlotOffset(self.slotIndex, self.sideSpacing, self.followDistance)
	local desired = self.targetRoot.CFrame:PointToWorldSpace(offset)
	desired = resolveGroundPosition(self.model, desired, self.groundRaycastParams)
	local current = self.model:GetPivot()
	local currentPosition = current.Position
	local lagDistance = horizontal(desired - currentPosition).Magnitude

	-- Mirror the owner's take-off with one short, cosmetic companion hop.
	-- Freefall while descending does not trigger a new jump; the airborne
	-- edge and cooldown prevent repeated hops during one player jump.
	local ownerHumanoid = self.targetRoot.Parent:FindFirstChildOfClass("Humanoid")
	local ownerState = if ownerHumanoid and ownerHumanoid:IsA("Humanoid")
		then ownerHumanoid:GetState()
		else nil
	local ownerAirborne = ownerState == Enum.HumanoidStateType.Jumping
		or ownerState == Enum.HumanoidStateType.Freefall
	local ownerJumpStarted = ownerState == Enum.HumanoidStateType.Jumping
		or (ownerState == Enum.HumanoidStateType.Freefall and self.targetRoot.AssemblyLinearVelocity.Y >= 7)
	if ownerJumpStarted and not self.wasOwnerAirborne and os.clock() >= self.nextJumpAt
		and lagDistance <= 18
	then
		self.jumpElapsed = 0
		self.nextJumpAt = os.clock() + 1.1
	end
	self.wasOwnerAirborne = ownerAirborne

	local jumpOffset = 0
	local jumpActive = false
	if self.jumpElapsed >= 0 then
		self.jumpElapsed += math.min(dt, 0.1)
		local jumpProgress = math.clamp(self.jumpElapsed / self.jumpDuration, 0, 1)
		jumpOffset = math.sin(math.pi * jumpProgress) * self.jumpHeight
		jumpActive = jumpProgress < 1
		if not jumpActive then
			self.jumpElapsed = -1
		end
	end

	-- If the player outruns a companion for a while, it should visibly hurry
	-- instead of sliding with an idle animation. Very large gaps can happen
	-- after streaming or a character reset; recover near the owner safely.
	local state = if speed >= self.runSpeed or lagDistance >= self.catchUpDistance
		then "run"
		else if speed >= self.walkSpeed or lagDistance >= 1.1 then "walk" else "idle"

	if lagDistance >= self.teleportDistance then
		local recoveryPosition = desired - horizontal(self.targetRoot.CFrame.LookVector) * 2
		self.model:PivotTo(CFrame.lookAt(recoveryPosition, recoveryPosition + horizontal(self.targetRoot.CFrame.LookVector)))
		current = self.model:GetPivot()
		currentPosition = current.Position
		lagDistance = horizontal(desired - currentPosition).Magnitude
	end

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
	-- Nearby resource nodes can catch a resting Bunny's attention. This is
	-- cosmetic only: gathering rewards and prompt validation stay server-owned.
	if os.clock() >= self.nextEnvironmentScan then
		self.nextEnvironmentScan = os.clock() + 1
		local ownerUserId = self.model:GetAttribute("OwnerUserId")
		local islands = Workspace:FindFirstChild("PlayerIslands")
		local ownerIsland = nil
		if type(ownerUserId) == "number" and islands then
			for _, island in ipairs(islands:GetChildren()) do
				if island:GetAttribute("OwnerUserId") == ownerUserId then
					ownerIsland = island
					break
				end
			end
		end
		local nodes = ownerIsland and ownerIsland:FindFirstChild("ResourceNodes")
		local nearestDistance = 9
		local nearestNode = nil
		if nodes then
			for _, node in ipairs(nodes:GetChildren()) do
				local availableAt = node:GetAttribute("AvailableAt")
				if node:IsA("Model") and type(availableAt) == "number"
					and availableAt <= os.time()
				then
					local visible = false
					for _, part in ipairs(node:GetDescendants()) do
						if part:IsA("BasePart") and part.Transparency < 1 then
							visible = true
							break
						end
					end
					if visible then
						local distance = (node:GetPivot().Position - currentPosition).Magnitude
						if distance < nearestDistance then
							nearestDistance = distance
							nearestNode = node
						end
					end
				end
			end
		end
		if nearestNode and speed < self.walkSpeed and self.interactionState == nil
			and self.slotIndex == 1
			and (nearestNode ~= self.lastInvestigatedNode or os.clock() - self.lastInvestigatedAt >= 12)
		then
			local nodePosition = nearestNode:GetPivot().Position
			local away = horizontal(currentPosition - nodePosition)
			if away.Magnitude < 0.1 then away = -horizontal(self.targetRoot.CFrame.LookVector) end
			local approachPosition = nodePosition + away.Unit * 2.8
			self.investigatePosition = resolveGroundPosition(self.model, approachPosition, self.groundRaycastParams)
			self.investigateUntil = os.clock() + 4
			self.lastInvestigatedNode = nearestNode
			self.lastInvestigatedAt = os.clock()
			self.environmentState = if nearestNode:GetAttribute("ResourceId") == "wood" then "curious" else "sniff"
			self.environmentUntil = self.investigateUntil
		end
	end

	-- The lead Bunny briefly leaves formation to inspect a nearby resource,
	-- then naturally resumes its normal follow slot. Other companions keep formation.
	if self.investigatePosition ~= nil then
		if os.clock() < self.investigateUntil and speed < self.walkSpeed then
			desired = self.investigatePosition
			lagDistance = horizontal(desired - currentPosition).Magnitude
			state = if lagDistance > 1.2 then "walk" else (self.environmentState or "idle")
		else
			self.investigatePosition = nil
		end
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
	if speed < self.walkSpeed and self.interactionState == nil
		and self.environmentState ~= nil and os.clock() < self.environmentUntil
		and (self.investigatePosition == nil or lagDistance <= 1.2) then
		state = self.environmentState
	elseif self.environmentState ~= nil and os.clock() >= self.environmentUntil then
		self.environmentState = nil
	end
	-- Avoid walking directly through nearby buildings or walls. Re-evaluate
	-- periodically and keep a short-lived side waypoint until it is reached.
	local now = os.clock()
	local pathTarget = desired
	if self.pathDetourPosition ~= nil then
		local targetChanged = self.lastPathTarget ~= nil
			and horizontal(pathTarget - self.lastPathTarget).Magnitude >= 4
		local detourReached = horizontal(self.pathDetourPosition - currentPosition).Magnitude <= 1.25
		if targetChanged or detourReached or now >= self.pathDetourUntil then
			self.pathDetourPosition = nil
		end
	end
	self.lastPathTarget = pathTarget

	if self.pathDetourPosition == nil and now >= self.nextObstacleScan then
		self.nextObstacleScan = now + 0.35
		self.pathDetourPosition = findObstacleDetour(
			self.model,
			currentPosition,
			pathTarget,
			self.groundRaycastParams
		)
		if self.pathDetourPosition ~= nil then
			self.pathDetourUntil = now + 2
		end
	end
	if self.pathDetourPosition ~= nil then
		desired = self.pathDetourPosition
		lagDistance = horizontal(desired - currentPosition).Magnitude
		if lagDistance > self.catchUpDistance then
			state = "run"
		elseif lagDistance > 1.1 then
			state = "walk"
		end
	end

	-- Sample the surface normal at a modest rate and smoothly align the pet
	-- with ramps/bridges without adding a raycast to every rendered frame.
	if now >= self.nextGroundNormalScan then
		self.nextGroundNormalScan = now + 0.15
		self.groundNormal = resolveGroundNormal(desired, self.groundRaycastParams)
	end

	if jumpActive then
		desired += Vector3.new(0, jumpOffset, 0)
		state = "jump"
	end

	local facing = if speed > 0.75 then targetVelocity.Unit else horizontal(self.targetRoot.CFrame.LookVector)
	if facing.Magnitude > 0.001 then
		local turnAlpha = 1 - math.exp(-self.turnSmoothing * math.min(dt, 0.1))
		local blendedFacing = self.lastFacing:Lerp(facing.Unit, turnAlpha)
		self.lastFacing = if blendedFacing.Magnitude > 0.001 then blendedFacing.Unit else facing.Unit
	end

	local alpha = 1 - math.exp(-self.smoothing * math.min(dt, 0.1))
	local targetCFrame = CFrame.lookAt(desired, desired + self.lastFacing, self.groundNormal)
	local nextCFrame = current:Lerp(targetCFrame, alpha)
	self.movementSpeed = (nextCFrame.Position - currentPosition).Magnitude / dt

	-- Locomotion is selected from the companion's actual displacement, not
	-- the owner's velocity alone. This prevents idle leg cycles and sliding
	-- when the pet has already reached its formation slot.
	if jumpActive then
		state = "jump"
	elseif self.movementSpeed >= 7.5
		or (lagDistance >= self.catchUpDistance and self.movementSpeed >= 2.5)
	then
		state = "run"
	elseif self.movementSpeed >= 0.35 then
		state = "walk"
	elseif state == "walk" or state == "run" then
		state = "idle"
	end

	if self.animation then
		self.animation:setMovementSpeed(self.movementSpeed)
		self.animation:setState(state)
	end

	self.model:PivotTo(nextCFrame)
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
