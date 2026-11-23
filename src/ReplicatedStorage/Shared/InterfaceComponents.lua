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

return table.freeze(Components)
