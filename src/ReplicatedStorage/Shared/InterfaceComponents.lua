--!strict
-- Shared button styling for Pet Kingdoms primary interface windows.

local Theme = require(script.Parent:WaitForChild("InterfaceTheme"))
local GuiService = game:GetService("GuiService")
local Components = {}

-- Returns the camera viewport plus the usable rectangle after Roblox's
-- top-bar/notch insets. UI panels can center and clamp against this rectangle
-- instead of assuming the entire viewport is available.
function Components.GetSafeViewport(camera: Camera?): (Vector2, Vector2, Vector2)
	local activeCamera = camera or workspace.CurrentCamera
	local viewport = if activeCamera then activeCamera.ViewportSize else Vector2.zero
	local topLeftInset, bottomRightInset = GuiService:GetGuiInset()
	local safeOrigin = Vector2.new(
		math.clamp(topLeftInset.X, 0, viewport.X),
		math.clamp(topLeftInset.Y, 0, viewport.Y)
	)
	local safeSize = Vector2.new(
		math.max(0, viewport.X - safeOrigin.X - math.max(0, bottomRightInset.X)),
		math.max(0, viewport.Y - safeOrigin.Y - math.max(0, bottomRightInset.Y))
	)
	return viewport, safeOrigin, safeSize
end

function Components.ClampPanelSize(desired: Vector2, safeSize: Vector2, margin: number?): Vector2
	local inset = math.max(0, margin or 12)
	local available = Vector2.new(
		math.max(0, safeSize.X - inset * 2),
		math.max(0, safeSize.Y - inset * 2)
	)
	return Vector2.new(
		math.min(math.max(0, desired.X), available.X),
		math.min(math.max(0, desired.Y), available.Y)
	)
end

function Components.StyleCloseButton(button: TextButton)
	local colors = Theme.Colors
	button.Size = UDim2.fromOffset(40, 40)
	button.BackgroundColor3 = colors.panelSoft
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Theme.Typography.Display
	button.Text = Theme.Icons.Close
	button.TextColor3 = colors.cream
	button.TextSize = 24
	button.TextScaled = false

	if button:FindFirstChildOfClass("UICorner") == nil then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.Radii.Medium
		corner.Parent = button
	end
	if button:FindFirstChildOfClass("UIStroke") == nil then
		local stroke = Instance.new("UIStroke")
		stroke.Color = colors.gold
		stroke.Thickness = 1
		stroke.Transparency = 0.72
		stroke.Parent = button
	end
end

function Components.SetButtonLoading(button: TextButton, isLoading: boolean, loadingText: string?)
	if isLoading then
		if button:GetAttribute("PKLoading") == true then return end
		button:SetAttribute("PKLoading", true)
		button:SetAttribute("PKOriginalText", button.Text)
		button:SetAttribute("PKOriginalActive", button.Active)
		button:SetAttribute("PKOriginalAutoButtonColor", button.AutoButtonColor)
		button.Active = false
		button.AutoButtonColor = false
		button.Text = loadingText or "ЗАГРУЗКА..."
	else
		if button:GetAttribute("PKLoading") ~= true then return end
		local originalText = button:GetAttribute("PKOriginalText")
		local originalActive = button:GetAttribute("PKOriginalActive")
		local originalAuto = button:GetAttribute("PKOriginalAutoButtonColor")
		if type(originalText) == "string" then button.Text = originalText end
		button.Active = if type(originalActive) == "boolean" then originalActive else true
		button.AutoButtonColor = if type(originalAuto) == "boolean" then originalAuto else true
		button:SetAttribute("PKLoading", false)
		button:SetAttribute("PKOriginalText", nil)
		button:SetAttribute("PKOriginalActive", nil)
		button:SetAttribute("PKOriginalAutoButtonColor", nil)
	end
end

function Components.SetButtonFeedback(button: TextButton, state: string, message: string?, duration: number?)
	local colors = Theme.Colors
	local token = (button:GetAttribute("PKFeedbackToken") or 0) + 1
	button:SetAttribute("PKFeedbackToken", token)

	if button:GetAttribute("PKFeedbackActive") ~= true then
		button:SetAttribute("PKFeedbackOriginalText", button.Text)
		button:SetAttribute("PKFeedbackOriginalBackground", button.BackgroundColor3)
		button:SetAttribute("PKFeedbackOriginalTextColor", button.TextColor3)
		button:SetAttribute("PKFeedbackOriginalActive", button.Active)
		button:SetAttribute("PKFeedbackOriginalAuto", button.AutoButtonColor)
	end

	local background = colors.panelSoft
	local foreground = colors.cream
	if state == "success" then
		background, foreground = colors.mint, colors.panel
	elseif state == "error" then
		background, foreground = colors.danger, colors.cream
	elseif state == "warning" then
		background, foreground = colors.gold, colors.panel
	else
		return
	end

	button:SetAttribute("PKFeedbackActive", true)
	button.BackgroundColor3 = background
	button.TextColor3 = foreground
	button.Text = message or (if state == "success" then "ГОТОВО" elseif state == "warning" then "ПРОВЕРЬ" else "ПОВТОРИТЬ")
	button.Active = true
	button.AutoButtonColor = true

	task.delay(math.max(0.5, duration or 1.8), function()
		if not button.Parent or button:GetAttribute("PKFeedbackToken") ~= token then return end
		local originalText = button:GetAttribute("PKFeedbackOriginalText")
		local originalBackground = button:GetAttribute("PKFeedbackOriginalBackground")
		local originalTextColor = button:GetAttribute("PKFeedbackOriginalTextColor")
		local originalActive = button:GetAttribute("PKFeedbackOriginalActive")
		local originalAuto = button:GetAttribute("PKFeedbackOriginalAuto")
		if type(originalText) == "string" then button.Text = originalText end
		if typeof(originalBackground) == "Color3" then button.BackgroundColor3 = originalBackground end
		if typeof(originalTextColor) == "Color3" then button.TextColor3 = originalTextColor end
		button.Active = if type(originalActive) == "boolean" then originalActive else true
		button.AutoButtonColor = if type(originalAuto) == "boolean" then originalAuto else true
		button:SetAttribute("PKFeedbackActive", false)
		button:SetAttribute("PKFeedbackOriginalText", nil)
		button:SetAttribute("PKFeedbackOriginalBackground", nil)
		button:SetAttribute("PKFeedbackOriginalTextColor", nil)
		button:SetAttribute("PKFeedbackOriginalActive", nil)
		button:SetAttribute("PKFeedbackOriginalAuto", nil)
	end)
end

function Components.StyleText(label: TextLabel, role: string?)
	local typography = Theme.Typography
	local sizes = typography.Sizes
	local roleName = role or "Body"
	local font = typography.Body
	local size = sizes.Body
	if roleName == "Display" then
		font, size = typography.Display, sizes.Display
	elseif roleName == "Heading" then
		font, size = typography.Display, sizes.Heading
	elseif roleName == "Caption" then
		font, size = typography.Body, sizes.Caption
	elseif roleName == "Micro" then
		font, size = typography.Emphasis, sizes.Micro
	elseif roleName == "Numeric" then
		font, size = typography.Emphasis, sizes.Numeric
	elseif roleName == "Emphasis" then
		font, size = typography.Emphasis, sizes.Body
	end
	label.Font = font
	label.TextSize = size
	label.TextScaled = false
end

function Components.StyleCard(card: GuiObject, variant: string?)
	local colors = Theme.Colors
	local strokeColor = colors.panelLight
	local transparency = 0.72
	local radius = Theme.Radii.Large
	if variant == "highlight" then
		strokeColor, transparency = colors.gold, 0.42
	elseif variant == "compact" then
		strokeColor, transparency, radius = colors.track, 0.58, Theme.Radii.Medium
	end

	local corner = card:FindFirstChildOfClass("UICorner")
	if corner == nil then
		corner = Instance.new("UICorner")
		corner.Parent = card
	end
	corner.CornerRadius = radius

	local stroke = card:FindFirstChildOfClass("UIStroke")
	if stroke == nil then
		stroke = Instance.new("UIStroke")
		stroke.Parent = card
	end
	stroke.Color = strokeColor
	stroke.Thickness = 1
	stroke.Transparency = transparency
end

function Components.StyleEmptyState(label: TextLabel, icon: string?)
	local colors = Theme.Colors
	label.BackgroundColor3 = colors.panelSoft
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Font = Theme.Typography.Body
	label.TextColor3 = colors.muted
	label.TextSize = Theme.Typography.Sizes.Body
	label.TextWrapped = true
	label.TextScaled = false
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.RichText = false
	if icon and icon ~= "" and not label:GetAttribute("PKEmptyIconApplied") then
		label.Text = icon .. "\n" .. label.Text
		label:SetAttribute("PKEmptyIconApplied", true)
	end

	local corner = label:FindFirstChildOfClass("UICorner")
	if corner == nil then
		corner = Instance.new("UICorner")
		corner.Parent = label
	end
	corner.CornerRadius = Theme.Radii.Medium

	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke == nil then
		stroke = Instance.new("UIStroke")
		stroke.Parent = label
	end
	stroke.Color = colors.panelLight
	stroke.Thickness = 1
	stroke.Transparency = 0.72
end

function Components.StyleFloatingButton(button: TextButton, variant: string?)
	local colors = Theme.Colors
	local accent = colors.gold
	if variant == "mint" then
		accent = colors.mint
	elseif variant == "rose" then
		accent = colors.rose
	end

	button.BackgroundColor3 = colors.panel
	button.TextColor3 = colors.cream
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Theme.Typography.Display
	button.TextScaled = false
	button.TextStrokeTransparency = 1
	button.ClipsDescendants = false

	local corner = button:FindFirstChildOfClass("UICorner")
	if corner == nil then
		corner = Instance.new("UICorner")
		corner.Parent = button
	end
	corner.CornerRadius = UDim.new(1, 0)

	local stroke = button:FindFirstChildOfClass("UIStroke")
	if stroke == nil then
		stroke = Instance.new("UIStroke")
		stroke.Parent = button
	end
	stroke.Color = accent
	stroke.Thickness = 1.5
	stroke.Transparency = 0.18
end

function Components.StyleActionButton(button: TextButton, variant: string?)
	local colors = Theme.Colors
	local background = colors.panelLight
	local foreground = colors.cream
	local strokeColor = colors.track

	if variant == "primary" then
		background, foreground, strokeColor = colors.mint, colors.panel, colors.mint
	elseif variant == "danger" then
		background, foreground, strokeColor = colors.danger, colors.panel, colors.rose
	elseif variant == "gold" then
		background, foreground, strokeColor = colors.gold, colors.panel, colors.gold
	elseif variant == "secondary" then
		background, foreground, strokeColor = colors.panelSoft, colors.cream, colors.panelLight
	end

	button.BackgroundColor3 = background
	button.TextColor3 = foreground
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Theme.Typography.Emphasis
	button.TextSize = math.clamp(button.TextSize, 12, 16)
	button.TextScaled = false

	local corner = button:FindFirstChildOfClass("UICorner")
	if corner == nil then
		corner = Instance.new("UICorner")
		corner.Parent = button
	end
	corner.CornerRadius = Theme.Radii.Medium

	local stroke = button:FindFirstChildOfClass("UIStroke")
	if stroke == nil then
		stroke = Instance.new("UIStroke")
		stroke.Parent = button
	end
	stroke.Color = strokeColor
	stroke.Thickness = 1
	stroke.Transparency = 0.62
end

return table.freeze(Components)
