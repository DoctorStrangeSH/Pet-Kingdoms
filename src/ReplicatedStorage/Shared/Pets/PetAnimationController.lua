--!strict
-- Lightweight procedural companion animation controller.
-- Call update(dt) from a client RenderStepped loop; no physics or animation asset IDs required.
local PetAnimationController = {}
PetAnimationController.__index = PetAnimationController

export type PetState = "idle" | "walk" | "run" | "happy" | "curious" | "alert" | "combat"

export type Controller = {
	model: Model,
	state: PetState,
	phase: number,
	motors: { [string]: Motor6D },
	destroyed: boolean,
	setState: (self: Controller, state: PetState) -> boolean,
	update: (self: Controller, dt: number) -> (),
	destroy: (self: Controller) -> (),
}

local VALID_STATES: { [string]: boolean } = {
	idle = true,
	walk = true,
	run = true,
	happy = true,
	curious = true,
	alert = true,
	combat = true,
}

local function findMotor(model: Model, name: string): Motor6D?
	local found = model:FindFirstChild(name, true)
	if found and found:IsA("Motor6D") then
		return found
	end
	return nil
end

local function put(motors: { [string]: Motor6D }, name: string, transform: CFrame)
	local motor = motors[name]
	if motor then
		motor.Transform = transform
	end
end

function PetAnimationController.new(model: Model): (Controller?, string)
	if model:GetAttribute("SpeciesId") ~= "bunny" or model:GetAttribute("RigVersion") ~= 1 then
		return nil, "UNSUPPORTED_RIG"
	end

	local names = {
		"Root_Body",
		"Body_Head",
		"Head_EarLeft",
		"Head_EarRight",
		"Body_FrontLeftLeg",
		"Body_FrontRightLeg",
		"Body_BackLeftLeg",
		"Body_BackRightLeg",
		"Body_Tail",
	}
	local motors: { [string]: Motor6D } = {}
	for _, name in ipairs(names) do
		local motor = findMotor(model, name)
		if motor == nil then
			return nil, "MISSING_MOTOR_" .. name
		end
		motors[name] = motor
	end

	local self = setmetatable({
		model = model,
		state = "idle" :: PetState,
		phase = 0,
		motors = motors,
		destroyed = false,
	}, PetAnimationController)

	return (self :: any) :: Controller, "CREATED"
end

function PetAnimationController.setState(self: Controller, state: PetState): boolean
	if self.destroyed or not VALID_STATES[state] then
		return false
	end
	self.state = state
	return true
end

function PetAnimationController.update(self: Controller, dt: number)
	if self.destroyed or self.model.Parent == nil then
		return
	end
	if type(dt) ~= "number" or dt <= 0 or dt ~= dt or dt == math.huge then
		return
	end

	self.phase += math.min(dt, 0.1)
	local t = self.phase
	local speed = 3
	if self.state == "run" then
		speed = 13
	elseif self.state == "walk" then
		speed = 8
	end
	local wave = math.sin(t * speed)
	local secondary = math.sin(t * speed * 2 + 0.7)

	for _, motor in pairs(self.motors) do
		motor.Transform = CFrame.identity
	end

	if self.state == "idle" then
		put(self.motors, "Root_Body", CFrame.new(0, math.sin(t * 2.4) * 0.035, 0)
			* CFrame.Angles(math.sin(t * 1.2) * 0.025, 0, math.sin(t * 1.5) * 0.025))
		put(self.motors, "Body_Head", CFrame.Angles(math.sin(t * 1.8) * 0.045, math.sin(t * 0.9) * 0.04, 0))
		put(self.motors, "Head_EarLeft", CFrame.Angles(0, 0, math.rad(-5) + math.sin(t * 2.1) * 0.08))
		put(self.motors, "Head_EarRight", CFrame.Angles(0, 0, math.rad(5) - math.sin(t * 2.1 + 0.4) * 0.08))
		put(self.motors, "Body_Tail", CFrame.Angles(0, math.sin(t * 2.7) * 0.12, 0))
	elseif self.state == "walk" or self.state == "run" then
		local stride = if self.state == "run" then 0.62 else 0.36
		local bounce = math.abs(wave) * (if self.state == "run" then 0.11 else 0.055)
		put(self.motors, "Root_Body", CFrame.new(0, bounce, 0) * CFrame.Angles(secondary * 0.06, 0, 0))
		put(self.motors, "Body_FrontLeftLeg", CFrame.Angles(wave * stride, 0, 0))
		put(self.motors, "Body_FrontRightLeg", CFrame.Angles(-wave * stride, 0, 0))
		put(self.motors, "Body_BackLeftLeg", CFrame.Angles(-wave * stride * 0.8, 0, 0))
		put(self.motors, "Body_BackRightLeg", CFrame.Angles(wave * stride * 0.8, 0, 0))
		put(self.motors, "Body_Head", CFrame.Angles(-0.035 + math.abs(wave) * 0.035, 0, 0))
		put(self.motors, "Head_EarLeft", CFrame.Angles(wave * 0.16, 0, math.rad(-5) + secondary * 0.08))
		put(self.motors, "Head_EarRight", CFrame.Angles(-wave * 0.16, 0, math.rad(5) - secondary * 0.08))
		put(self.motors, "Body_Tail", CFrame.Angles(0, wave * 0.18, secondary * 0.12))
	elseif self.state == "happy" then
		local hop = math.max(0, math.sin(t * 7))
		put(self.motors, "Root_Body", CFrame.new(0, hop * 0.2, 0) * CFrame.Angles(-hop * 0.12, 0, 0))
		put(self.motors, "Body_Head", CFrame.Angles(-hop * 0.12, 0, math.sin(t * 5) * 0.08))
		put(self.motors, "Head_EarLeft", CFrame.Angles(-hop * 0.25, 0, -0.12))
		put(self.motors, "Head_EarRight", CFrame.Angles(-hop * 0.25, 0, 0.12))
		put(self.motors, "Body_Tail", CFrame.Angles(0, math.sin(t * 12) * 0.3, 0))
	elseif self.state == "curious" then
		put(self.motors, "Body_Head", CFrame.Angles(-0.08, 0, math.sin(t * 1.7) * 0.2 - 0.18))
		put(self.motors, "Head_EarLeft", CFrame.Angles(0, 0, 0.32 + math.sin(t * 2) * 0.04))
		put(self.motors, "Head_EarRight", CFrame.Angles(0, 0, -0.08))
		put(self.motors, "Body_Tail", CFrame.Angles(0, math.sin(t * 1.5) * 0.08, 0))
	elseif self.state == "alert" then
		put(self.motors, "Body_Head", CFrame.Angles(-0.12, 0, 0))
		put(self.motors, "Head_EarLeft", CFrame.Angles(-0.08, 0, -0.28))
		put(self.motors, "Head_EarRight", CFrame.Angles(-0.08, 0, 0.28))
		put(self.motors, "Root_Body", CFrame.new(0, 0.025, 0))
	elseif self.state == "combat" then
		put(self.motors, "Root_Body", CFrame.Angles(0.12 + math.sin(t * 8) * 0.04, 0, 0))
		put(self.motors, "Body_Head", CFrame.Angles(-0.18, 0, 0))
		put(self.motors, "Body_FrontLeftLeg", CFrame.Angles(-0.28, 0, -0.08))
		put(self.motors, "Body_FrontRightLeg", CFrame.Angles(-0.28, 0, 0.08))
		put(self.motors, "Body_Tail", CFrame.Angles(0, math.sin(t * 9) * 0.2, 0))
	end
end

function PetAnimationController.destroy(self: Controller)
	if self.destroyed then
		return
	end
	self.destroyed = true
	for _, motor in pairs(self.motors) do
		if motor.Parent then
			motor.Transform = CFrame.identity
		end
	end
	table.clear(self.motors)
end

return PetAnimationController
