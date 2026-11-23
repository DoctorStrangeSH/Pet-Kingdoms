--!strict
-- Clear, player-facing startup feedback while the server loads the profile and island.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Keep the first island view at a useful third-person distance even if the
-- Studio camera was previously zoomed far out during editing.
player.CameraMinZoomDistance = 8
player.CameraMaxZoomDistance = 28

local function bindCamera(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		local camera = workspace.CurrentCamera
		if camera then
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
		end
	end
end

player.CharacterAdded:Connect(function(character)
	task.spawn(bindCamera, character)
end)
if player.Character then
	task.spawn(bindCamera, player.Character)
end

local COLORS = {
	background = Color3.fromRGB(22, 25, 39),
	panel = Color3.fromRGB(39, 44, 65),
	gold = Color3.fromRGB(255, 211, 126),
	text = Color3.fromRGB(255, 248, 232),
	muted = Color3.fromRGB(190, 197, 213),
}

local screen = Instance.new("ScreenGui")
screen.Name = "PetKingdomsLoading"
screen.IgnoreGuiInset = true
screen.ResetOnSpawn = false
screen.DisplayOrder = 100
screen.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = COLORS.background
backdrop.Parent = screen

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 36, 55)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 37, 65)),
})
gradient.Rotation = 35
gradient.Parent = backdrop

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(1, -40, 0, 224)
panel.BackgroundColor3 = COLORS.panel
panel.Parent = backdrop
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 24)
local panelConstraint = Instance.new("UISizeConstraint")
panelConstraint.MinSize = Vector2.new(280, 224)
panelConstraint.MaxSize = Vector2.new(440, 224)
panelConstraint.Parent = panel
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = COLORS.gold
panelStroke.Transparency = 0.72
panelStroke.Thickness = 1.3
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 20, 0, 25)
title.Size = UDim2.new(1, -40, 0, 42)
title.Font = Enum.Font.GothamBold
title.Text = "PET KINGDOMS"
title.TextColor3 = COLORS.gold
title.TextSize = 27
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 20, 0, 78)
subtitle.Size = UDim2.new(1, -40, 0, 28)
subtitle.Font = Enum.Font.GothamMedium
subtitle.Text = "Готовим твоё королевство"
subtitle.TextColor3 = COLORS.text
subtitle.TextSize = 17
subtitle.Parent = panel

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 24, 0, 118)
status.Size = UDim2.new(1, -48, 0, 42)
status.Font = Enum.Font.Gotham
status.Text = "Подключаемся к королевству..."
status.TextColor3 = COLORS.muted
status.TextSize = 13
status.TextWrapped = true
status.Parent = panel

local track = Instance.new("Frame")
track.Position = UDim2.new(0, 24, 1, -34)
track.Size = UDim2.new(1, -48, 0, 7)
track.BackgroundColor3 = Color3.fromRGB(65, 71, 94)
track.BorderSizePixel = 0
track.Parent = panel
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0.08, 1)
fill.BackgroundColor3 = COLORS.gold
fill.BorderSizePixel = 0
fill.Parent = track
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

-- The loading card must remain fully visible even on very short landscape
-- displays (for example 320×180 phones). Keep normal typography on taller screens.
local function resizeLoadingCard()
	local camera = Workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local tiny = viewport.Y < 210
	local compact = viewport.Y < 280
	local cardHeight = if tiny then 148 else (if compact then 176 else 224)
	local horizontalMargin = if viewport.X < 360 then 20 else 40

	panel.Size = UDim2.new(1, -horizontalMargin, 0, cardHeight)
	panelConstraint.MinSize = Vector2.new(240, cardHeight)
	panelConstraint.MaxSize = Vector2.new(440, cardHeight)

	title.Position = UDim2.new(0, 16, 0, if tiny then 10 else (if compact then 14 else 25))
	title.Size = UDim2.new(1, -32, 0, if tiny then 30 else (if compact then 34 else 42))
	title.TextSize = if tiny then 20 else (if compact then 22 else 27)

	subtitle.Position = UDim2.new(0, 16, 0, if tiny then 43 else (if compact then 52 else 78))
	subtitle.Size = UDim2.new(1, -32, 0, if tiny then 22 else (if compact then 24 else 28))
	subtitle.TextSize = if tiny then 13 else (if compact then 14 else 17)

	status.Position = UDim2.new(0, 18, 0, if tiny then 70 else (if compact then 82 else 118))
	status.Size = UDim2.new(1, -36, 0, if tiny then 34 else (if compact then 38 else 42))
	status.TextSize = if tiny then 10 else (if compact then 11 else 13)

	track.Position = UDim2.new(0, 18, 1, if tiny then -19 else (if compact then -23 else -34))
	track.Size = UDim2.new(1, -36, 0, if tiny then 5 else 7)
end

local activeTween: Tween? = nil
local function applyState()
	local state = player:GetAttribute("PetKingdomsLoadStatus")
	local message = player:GetAttribute("PetKingdomsLoadMessage")
	if type(message) == "string" and message ~= "" then
		status.Text = message
	end
	if state == "Ready" then
		if activeTween then activeTween:Cancel() end
		local fade = TweenService:Create(backdrop, TweenInfo.new(0.45), { BackgroundTransparency = 1 })
		for _, item in ipairs(screen:GetDescendants()) do
			if item:IsA("GuiObject") then
				TweenService:Create(item, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
				end
			if item:IsA("TextLabel") then
				TweenService:Create(item, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
			end
		end
		fade:Play()
		fade.Completed:Once(function() screen:Destroy() end)
	elseif state == "Failed" then
		subtitle.Text = "Не удалось войти"
		subtitle.TextColor3 = Color3.fromRGB(255, 145, 145)
		status.TextColor3 = Color3.fromRGB(255, 190, 190)
		track.Visible = false
	elseif state == "Loading" or state == nil then
		if activeTween == nil or activeTween.PlaybackState ~= Enum.PlaybackState.Playing then
			activeTween = TweenService:Create(fill, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Size = UDim2.fromScale(0.92, 1),
				})
			activeTween:Play()
		end
	end
end

local viewportConnection: RBXScriptConnection? = nil
local function bindViewportCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeLoadingCard)
	end
	resizeLoadingCard()
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportCamera)
bindViewportCamera()
player:GetAttributeChangedSignal("PetKingdomsLoadStatus"):Connect(applyState)
player:GetAttributeChangedSignal("PetKingdomsLoadMessage"):Connect(applyState)
applyState()
