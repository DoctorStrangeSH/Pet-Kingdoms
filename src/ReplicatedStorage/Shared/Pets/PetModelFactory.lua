--!strict
-- Original procedural pet rig prototype. Production mesh art and animation clips are separate pipeline steps.
local PetModelFactory = {}

local COLORS = {
	body = Color3.fromRGB(244, 232, 211),
	cream = Color3.fromRGB(255, 246, 226),
	earInner = Color3.fromRGB(242, 145, 159),
	cheek = Color3.fromRGB(250, 177, 169),
	eye = Color3.fromRGB(45, 39, 48),
	nose = Color3.fromRGB(231, 116, 137),
	foot = Color3.fromRGB(235, 218, 194),
}

local function createPart(
	parent: Model,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function connectMotor(
	name: string,
	part0: BasePart,
	part1: BasePart
): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	motor.C1 = CFrame.identity
	motor.Parent = part0
	return motor
end

local function createBunny(scale: number): Model
	local model = Instance.new("Model")
	model.Name = "Pet_Bunny"
	model:SetAttribute("SpeciesId", "bunny")
	model:SetAttribute("RigVersion", 1)
	model:SetAttribute("IsPetRigPrototype", true)
	model:SetAttribute("Scale", scale)

	local root = createPart(model, "HumanoidRootPart", Vector3.new(0.5, 0.5, 0.5) * scale,
		CFrame.new(0, 0.28 * scale, 0), COLORS.body)
	root.Transparency = 1
	root.CanQuery = false
	model.PrimaryPart = root

	local body = createPart(model, "Body", Vector3.new(1.25, 1.05, 1.05) * scale,
		CFrame.new(0, 1.05 * scale, 0.08 * scale), COLORS.body, Enum.PartType.Ball)
	local belly = createPart(model, "Belly", Vector3.new(0.78, 0.72, 0.22) * scale,
		CFrame.new(0, 0.98 * scale, -0.43 * scale), COLORS.cream, Enum.PartType.Ball)
	local head = createPart(model, "Head", Vector3.new(0.98, 0.92, 0.9) * scale,
		CFrame.new(0, 1.92 * scale, -0.27 * scale), COLORS.cream, Enum.PartType.Ball)

	local leftEar = createPart(model, "Ear_Left", Vector3.new(0.3, 1.05, 0.24) * scale,
		CFrame.new(-0.29 * scale, 2.78 * scale, -0.22 * scale) * CFrame.Angles(0, 0, math.rad(-10)),
		COLORS.cream, Enum.PartType.Ball)
	local rightEar = createPart(model, "Ear_Right", Vector3.new(0.3, 1.05, 0.24) * scale,
		CFrame.new(0.29 * scale, 2.78 * scale, -0.22 * scale) * CFrame.Angles(0, 0, math.rad(10)),
		COLORS.cream, Enum.PartType.Ball)
	local leftEarInner = createPart(model, "EarInner_Left", Vector3.new(0.13, 0.72, 0.07) * scale,
		CFrame.new(-0.29 * scale, 2.79 * scale, -0.345 * scale) * CFrame.Angles(0, 0, math.rad(-10)),
		COLORS.earInner, Enum.PartType.Ball)
	local rightEarInner = createPart(model, "EarInner_Right", Vector3.new(0.13, 0.72, 0.07) * scale,
		CFrame.new(0.29 * scale, 2.79 * scale, -0.345 * scale) * CFrame.Angles(0, 0, math.rad(10)),
		COLORS.earInner, Enum.PartType.Ball)

	local leftEye = createPart(model, "Eye_Left", Vector3.new(0.105, 0.14, 0.07) * scale,
		CFrame.new(-0.29 * scale, 2.02 * scale, -0.69 * scale), COLORS.eye, Enum.PartType.Ball)
	local rightEye = createPart(model, "Eye_Right", Vector3.new(0.105, 0.14, 0.07) * scale,
		CFrame.new(0.29 * scale, 2.02 * scale, -0.69 * scale), COLORS.eye, Enum.PartType.Ball)
	local nose = createPart(model, "Nose", Vector3.new(0.14, 0.11, 0.1) * scale,
		CFrame.new(0, 1.82 * scale, -0.755 * scale), COLORS.nose, Enum.PartType.Ball)
	local leftCheek = createPart(model, "Cheek_Left", Vector3.new(0.19, 0.1, 0.06) * scale,
		CFrame.new(-0.39 * scale, 1.82 * scale, -0.65 * scale), COLORS.cheek, Enum.PartType.Ball)
	local rightCheek = createPart(model, "Cheek_Right", Vector3.new(0.19, 0.1, 0.06) * scale,
		CFrame.new(0.39 * scale, 1.82 * scale, -0.65 * scale), COLORS.cheek, Enum.PartType.Ball)

	local leftFrontLeg = createPart(model, "Leg_FrontLeft", Vector3.new(0.32, 0.58, 0.34) * scale,
		CFrame.new(-0.38 * scale, 0.43 * scale, -0.3 * scale), COLORS.body, Enum.PartType.Ball)
	local rightFrontLeg = createPart(model, "Leg_FrontRight", Vector3.new(0.32, 0.58, 0.34) * scale,
		CFrame.new(0.38 * scale, 0.43 * scale, -0.3 * scale), COLORS.body, Enum.PartType.Ball)
	local leftBackLeg = createPart(model, "Leg_BackLeft", Vector3.new(0.4, 0.62, 0.48) * scale,
		CFrame.new(-0.42 * scale, 0.4 * scale, 0.36 * scale), COLORS.foot, Enum.PartType.Ball)
	local rightBackLeg = createPart(model, "Leg_BackRight", Vector3.new(0.4, 0.62, 0.48) * scale,
		CFrame.new(0.42 * scale, 0.4 * scale, 0.36 * scale), COLORS.foot, Enum.PartType.Ball)
	local tail = createPart(model, "Tail", Vector3.new(0.42, 0.42, 0.42) * scale,
		CFrame.new(0, 1.08 * scale, 0.64 * scale), COLORS.cream, Enum.PartType.Ball)

	connectMotor("Root_Body", root, body)
	connectMotor("Body_Belly", body, belly)
	connectMotor("Body_Head", body, head)
	connectMotor("Head_EarLeft", head, leftEar)
	connectMotor("Head_EarRight", head, rightEar)
	connectMotor("EarLeft_Inner", leftEar, leftEarInner)
	connectMotor("EarRight_Inner", rightEar, rightEarInner)
	connectMotor("Head_EyeLeft", head, leftEye)
	connectMotor("Head_EyeRight", head, rightEye)
	connectMotor("Head_Nose", head, nose)
	connectMotor("Head_CheekLeft", head, leftCheek)
	connectMotor("Head_CheekRight", head, rightCheek)
	connectMotor("Body_FrontLeftLeg", body, leftFrontLeg)
	connectMotor("Body_FrontRightLeg", body, rightFrontLeg)
	connectMotor("Body_BackLeftLeg", body, leftBackLeg)
	connectMotor("Body_BackRightLeg", body, rightBackLeg)
	connectMotor("Body_Tail", body, tail)

	local controller = Instance.new("AnimationController")
	controller.Name = "AnimationController"
	controller.Parent = model
	local animator = Instance.new("Animator")
	animator.Parent = controller

	local followAttachment = Instance.new("Attachment")
	followAttachment.Name = "FollowAttachment"
	followAttachment.Position = Vector3.new(0, 0.3 * scale, 0.75 * scale)
	followAttachment.Parent = root

	local groundAttachment = Instance.new("Attachment")
	groundAttachment.Name = "GroundContact"
	groundAttachment.Position = Vector3.new(0, -0.25 * scale, 0)
	groundAttachment.Parent = root

	return model
end

function PetModelFactory.create(speciesId: string, scale: number?): (Model?, string)
	if speciesId ~= "bunny" then
		return nil, "UNKNOWN_SPECIES"
	end

	local resolvedScale = if scale == nil then 1 else scale
	if type(resolvedScale) ~= "number"
		or resolvedScale ~= resolvedScale
		or resolvedScale <= 0
		or resolvedScale > 3
		or resolvedScale == math.huge
	then
		return nil, "INVALID_SCALE"
	end

	return createBunny(resolvedScale), "CREATED"
end

return PetModelFactory
