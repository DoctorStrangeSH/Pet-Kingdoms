--!strict
-- Shared button styling for Pet Kingdoms primary interface windows.

local Theme = require(script.Parent:WaitForChild("InterfaceTheme"))
local Components = {}

function Components.StyleCloseButton(button: TextButton)
	local colors = Theme.Colors
	button.Size = UDim2.fromOffset(40, 40)
	button.BackgroundColor3 = colors.panelSoft
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Theme.Typography.Display
	button.Text = "×"
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
