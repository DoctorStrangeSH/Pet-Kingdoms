--!strict
-- Shared client toast notifications. Contextual panel status text remains in its owning screen;
-- this module is for brief global feedback such as completion, success and errors.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceTheme"))
local colors = Theme.Colors

local NotificationManager = {}
local MAX_VISIBLE = 4
local activeCount = 0
local maxVisibleCount = MAX_VISIBLE
local sequence = 0
local viewportConnection: RBXScriptConnection? = nil

local existing = playerGui:FindFirstChild("PetKingdomsNotifications")
if existing then existing:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name = "PetKingdomsNotifications"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.DisplayOrder = 1000
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local holder = Instance.new("Frame")
holder.Name = "ToastStack"
holder.BackgroundTransparency = 1
holder.AnchorPoint = Vector2.new(0.5, 0)
holder.Position = UDim2.new(0.5, 0, 0, 14)
holder.Size = UDim2.new(1, 0, 0, 250)
holder.Parent = screen

local layout = Instance.new("UIListLayout")
layout.Name = "StackLayout"
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = holder

local variants = {
	success = { background = colors.panelSoft, accent = colors.mint, icon = "✓" },
	info = { background = colors.panelSoft, accent = colors.gold, icon = "i" },
	warning = { background = colors.panelSoft, accent = colors.gold, icon = "!" },
	error = { background = colors.panelSoft, accent = colors.rose, icon = "×" },
	reward = { background = colors.panelSoft, accent = colors.gold, icon = "★" },
}

local function resize()
	local camera = workspace.CurrentCamera
	if camera == nil then return end
	local viewport = camera.ViewportSize
	local compact = viewport.X < 520
	-- Leave the Resource HUD visible: it occupies the top band on desktop
	-- and a taller two-row band on narrow portrait screens.
	local topOffset = if compact and viewport.Y >= 360 then 110 else 72
	maxVisibleCount = if viewport.Y < 220 then 1 elseif viewport.Y < 360 then 2 else MAX_VISIBLE
	holder.Position = UDim2.new(0.5, 0, 0, topOffset)
	holder.Size = UDim2.new(1, 0, 0, math.max(58, math.min(250, viewport.Y - topOffset - 8)))
	while activeCount > maxVisibleCount do
		local oldest = holder:FindFirstChildWhichIsA("Frame")
		if oldest == nil then
			activeCount = 0
			break
		end
		if oldest:GetAttribute("PKToastCounted") == true then
			oldest:SetAttribute("PKToastCounted", false)
			activeCount = math.max(0, activeCount - 1)
		end
		oldest:Destroy()
	end
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("Frame") then
			local constraint = child:FindFirstChildOfClass("UISizeConstraint")
			local icon = child:FindFirstChild("Icon")
			local label = child:FindFirstChild("Message")
			if constraint then
				constraint.MinSize = Vector2.new(math.min(180, math.max(150, viewport.X - 28)), 54)
				constraint.MaxSize = Vector2.new(math.max(150, math.min(440, viewport.X - 24)), 58)
			end
			child.Size = UDim2.new(0.94, 0, 0, 58)
			if icon and icon:IsA("TextLabel") then
				icon.Size = UDim2.fromOffset(compact and 28 or 30, 58)
				icon.TextSize = compact and 18 or 20
			end
			if label and label:IsA("TextLabel") then
				label.Position = UDim2.fromOffset(compact and 42 or 48, 4)
				label.Size = UDim2.new(1, compact and -50 or -60, 1, -8)
				label.TextSize = compact and 12 or Theme.Typography.Sizes.Body
			end
		end
	end
end

local function bindCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

function NotificationManager.Notify(message: string, variant: string?, duration: number?)
	if type(message) ~= "string" or message == "" then return end
	if activeCount >= maxVisibleCount then
		local oldest = holder:FindFirstChildWhichIsA("Frame")
		if oldest then
			-- A toast may be evicted before its lifetime timer fires. Release its
			-- slot exactly once so the old timer cannot decrement a newer toast.
			if oldest:GetAttribute("PKToastCounted") == true then
				oldest:SetAttribute("PKToastCounted", false)
				activeCount = math.max(0, activeCount - 1)
			end
			oldest:Destroy()
		end
	end

	sequence += 1
	local toastId = sequence
	local style = variants[variant or "info"] or variants.info
	local toast = Instance.new("Frame")
	toast.Name = "Toast_" .. tostring(toastId)
	toast.LayoutOrder = toastId
	toast.Size = UDim2.new(0.9, 0, 0, 54)
	toast.BackgroundColor3 = style.background
	toast.BackgroundTransparency = 1
	toast.BorderSizePixel = 0
	toast.ClipsDescendants = true
	toast.Parent = holder

	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(180, 54)
	constraint.MaxSize = Vector2.new(440, 54)
	constraint.Parent = toast

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.Radii.Medium
	corner.Parent = toast

	local stroke = Instance.new("UIStroke")
	stroke.Color = style.accent
	stroke.Thickness = 1.2
	stroke.Transparency = 1
	stroke.Parent = toast

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromOffset(12, 0)
	icon.Size = UDim2.fromOffset(30, 54)
	icon.Font = Theme.Typography.Display
	icon.Text = style.icon
	icon.TextSize = 20
	icon.TextColor3 = style.accent
	icon.Parent = toast

	local label = Instance.new("TextLabel")
	label.Name = "Message"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(48, 5)
	label.Size = UDim2.new(1, -60, 1, -10)
	label.Font = Theme.Typography.Body
	label.Text = message
	label.TextSize = Theme.Typography.Sizes.Body
	label.TextTruncate = Enum.TextTruncate.None
	label.TextColor3 = colors.cream
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = toast

	activeCount += 1
	toast:SetAttribute("PKToastCounted", true)
	local function releaseSlot()
		if toast:GetAttribute("PKToastCounted") ~= true then return end
		toast:SetAttribute("PKToastCounted", false)
		activeCount = math.max(0, activeCount - 1)
	end

	toast.Position = UDim2.fromOffset(0, -8)
	TweenService:Create(toast, TweenInfo.new(Theme.Motion.Standard, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.04,
		Position = UDim2.fromOffset(0, 0),
	}):Play()
	TweenService:Create(stroke, TweenInfo.new(Theme.Motion.Standard), { Transparency = 0.3 }):Play()

	task.delay(math.clamp(duration or 3, 1.5, 8), function()
		if toast.Parent == nil then
			releaseSlot()
			return
		end
		local fade = TweenService:Create(toast, TweenInfo.new(Theme.Motion.Fast), {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, -8),
		})
		TweenService:Create(stroke, TweenInfo.new(Theme.Motion.Fast), { Transparency = 1 }):Play()
		fade:Play()
		fade.Completed:Wait()
		if toast.Parent then toast:Destroy() end
		releaseSlot()
	end)
end

return table.freeze(NotificationManager)
