--!strict
-- Compact responsive resource HUD. The server is the sole source of balances.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local RequestRunner = require(Shared:WaitForChild("RequestRunner"))
local InterfaceTheme = require(Shared:WaitForChild("InterfaceTheme"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("IslandResourceRequest") :: RemoteFunction
local update = remotes:WaitForChild("IslandResourceUpdate") :: RemoteEvent

local COLORS = InterfaceTheme.Colors

local RESOURCES = {
	{ id = "wood", icon = InterfaceTheme.Icons.Wood, label = "ДЕРЕВО", color = Color3.fromRGB(169, 207, 151) },
	{ id = "stone", icon = InterfaceTheme.Icons.Stone, label = "КАМЕНЬ", color = Color3.fromRGB(190, 202, 218) },
	{ id = "gold", icon = InterfaceTheme.Icons.Gold, label = "ЗОЛОТО", color = COLORS.gold },
	{ id = "gems", icon = InterfaceTheme.Icons.Gems, label = "КРИСТАЛЛЫ", color = Color3.fromRGB(139, 218, 235) },
}

local screen = Instance.new("ScreenGui")
screen.Name = "IslandResourceHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.DisplayOrder = 12
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "ResourceBar"
root.AnchorPoint = Vector2.new(0.5, 0)
root.Position = UDim2.new(0.5, 0, 0, 10)
root.Size = UDim2.fromOffset(420, 54)
root.BackgroundColor3 = COLORS.panel
root.BackgroundTransparency = 0.04
root.Parent = screen
Instance.new("UICorner", root).CornerRadius = InterfaceTheme.Radii.Large
local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.panelLight
stroke.Transparency = 0.28
stroke.Thickness = 1.2
stroke.Parent = root
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 7)
padding.PaddingRight = UDim.new(0, 7)
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = root
local layout = Instance.new("UIGridLayout")
layout.FillDirectionMaxCells = 2
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.CellPadding = UDim2.fromOffset(6, 4)
layout.Parent = root

local amountLabels: { [string]: TextLabel } = {}
for _, resource in ipairs(RESOURCES) do
	local chip = Instance.new("Frame")
	chip.Name = resource.id .. "Chip"
	chip.LayoutOrder = #amountLabels + 1
	chip.Size = UDim2.new(0.25, -5, 1, 0)
	chip.BackgroundColor3 = COLORS.panelSoft
	chip.Parent = root
	Instance.new("UICorner", chip).CornerRadius = InterfaceTheme.Radii.Medium

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 5, 0, 0)
	icon.Size = UDim2.new(0, 27, 1, 0)
	icon.Font = InterfaceTheme.Typography.Body
	icon.Text = resource.icon
	icon.TextSize = InterfaceTheme.Typography.Sizes.Numeric
	icon.Parent = chip

	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.BackgroundTransparency = 1
	amount.Position = UDim2.new(0, 32, 0, 2)
	amount.Size = UDim2.new(1, -36, 0.58, 0)
	amount.TextTruncate = Enum.TextTruncate.AtEnd
	amount.Font = InterfaceTheme.Typography.Display
	amount.Text = "…"
	amount.TextSize = InterfaceTheme.Typography.Sizes.Numeric
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.TextColor3 = resource.color
	amount.Parent = chip
	amountLabels[resource.id] = amount

	local label = Instance.new("TextLabel")
	label.Name = "ResourceName"
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 33, 0.57, -1)
	label.Size = UDim2.new(1, -35, 0.36, 0)
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Font = InterfaceTheme.Typography.Emphasis
	label.Text = resource.label
	label.TextSize = InterfaceTheme.Typography.Sizes.Micro
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = COLORS.muted
	label.Parent = chip
end

local toast = Instance.new("TextLabel")
toast.Name = "GatherToast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 106)
toast.Size = UDim2.fromOffset(250, 38)
toast.BackgroundColor3 = COLORS.panel
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.Text = ""
toast.TextColor3 = COLORS.mint
toast.TextSize = InterfaceTheme.Typography.Sizes.Body
toast.Font = InterfaceTheme.Typography.Display
toast.Visible = false
toast.Parent = screen
Instance.new("UICorner", toast).CornerRadius = InterfaceTheme.Radii.Medium
local toastStroke = Instance.new("UIStroke")
toastStroke.Color = COLORS.mint
toastStroke.Transparency = 1
toastStroke.Parent = toast

local bondLabel = Instance.new("TextLabel")
bondLabel.Name = "KingdomBondStatus"
bondLabel.AnchorPoint = Vector2.new(0.5, 0)
bondLabel.Position = UDim2.new(0.5, 0, 0, 70)
bondLabel.Size = UDim2.fromOffset(300, 28)
bondLabel.BackgroundColor3 = COLORS.panel
bondLabel.BackgroundTransparency = 0.12
bondLabel.Text = InterfaceTheme.Icons.Build .. " Тихий остров"
bondLabel.TextTruncate = Enum.TextTruncate.AtEnd
bondLabel.TextColor3 = COLORS.gold
bondLabel.TextSize = InterfaceTheme.Typography.Sizes.Caption
bondLabel.Font = InterfaceTheme.Typography.Display
bondLabel.Visible = false
bondLabel.Parent = screen
Instance.new("UICorner", bondLabel).CornerRadius = InterfaceTheme.Radii.Small
local bondStroke = Instance.new("UIStroke")
bondStroke.Color = COLORS.gold
bondStroke.Transparency = 0.55
bondStroke.Parent = bondLabel

local function applyKingdomBond(world: Instance)
	local stageName = world:GetAttribute("KingdomBondStageName")
	local points = world:GetAttribute("KingdomBondPoints")
	local nextPoints = world:GetAttribute("KingdomBondNextStagePoints")
	if type(stageName) ~= "string" or type(points) ~= "number" then
		bondLabel.Visible = false
		return
	end
	bondLabel.Text = if type(nextPoints) == "number"
		then string.format("%s %s  •  %d очков  •  дальше: %d", InterfaceTheme.Icons.Build, stageName, points, nextPoints)
		else string.format("%s %s  •  %d очков  •  максимум", InterfaceTheme.Icons.Build, stageName, points)
	bondLabel.Visible = true
end

local function bindKingdomBond(world: Instance)
	if not world:IsA("Model") or world:GetAttribute("OwnerUserId") ~= player.UserId then return end
	applyKingdomBond(world)
	for _, attribute in ipairs({ "KingdomBondStageName", "KingdomBondPoints", "KingdomBondNextStagePoints" }) do
		world:GetAttributeChangedSignal(attribute):Connect(function()
			applyKingdomBond(world)
		end)
	end
end

task.spawn(function()
	local folder = Workspace:WaitForChild("PlayerIslands", 30)
	if folder == nil then return end
	for _, world in ipairs(folder:GetChildren()) do bindKingdomBond(world) end
	folder.ChildAdded:Connect(bindKingdomBond)
end)

local toastSequence = 0
local function showToast(resourceId: string?, amount: number?, code: string?)
	if code ~= "GATHERED" or resourceId == nil or amount == nil then return end
	local item = nil
	for _, resource in ipairs(RESOURCES) do
		if resource.id == resourceId then item = resource break end
	end
	if item == nil then return end
	toastSequence += 1
	local sequence = toastSequence
	toast.Text = string.format("+%d %s", amount, item.label:lower())
	toast.TextColor3 = item.color
	toastStroke.Color = item.color
	toast.Visible = true
	TweenService:Create(toast, TweenInfo.new(0.16), {
		BackgroundTransparency = 0.04,
		TextTransparency = 0,
	}):Play()
	TweenService:Create(toastStroke, TweenInfo.new(0.16), { Transparency = 0.35 }):Play()
	task.delay(1.65, function()
		if sequence ~= toastSequence then return end
		local fade = TweenService:Create(toast, TweenInfo.new(0.22), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		TweenService:Create(toastStroke, TweenInfo.new(0.22), { Transparency = 1 }):Play()
		fade:Play()
		fade.Completed:Wait()
		if sequence == toastSequence then toast.Visible = false end
	end)
end

local function applySnapshot(snapshot: any)
	if type(snapshot) ~= "table" then return end
	for _, resource in ipairs(RESOURCES) do
		local value = snapshot[resource.id]
		if type(value) == "number" and value >= 0 and value == math.floor(value) then
			amountLabels[resource.id].Text = tostring(value)
		end
	end
end

local function resize()
	local camera = Workspace.CurrentCamera
	if camera == nil then return end
	local viewport = camera.ViewportSize
	local compact = viewport.X < 560
	local tiny = viewport.X < 360
	root.Size = UDim2.new(compact and 0.96 or 0, compact and 0 or 420, 0, compact and 92 or 54)
	layout.FillDirectionMaxCells = if compact then 2 else 4
	layout.CellSize = if compact then UDim2.new(0.5, -10, 0, 36) else UDim2.new(0.25, -6, 1, 0)
	layout.CellPadding = UDim2.fromOffset(compact and 4 or 6, compact and 4 or 0)
	padding.PaddingLeft = UDim.new(0, compact and 6 or 7)
	padding.PaddingRight = UDim.new(0, compact and 6 or 7)
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("Frame") then
			local icon = child:FindFirstChildWhichIsA("TextLabel")
			local amount = child:FindFirstChild("Amount")
			local label = child:FindFirstChild("ResourceName")
			if icon and icon ~= amount and icon ~= label then
				icon.Size = UDim2.fromOffset(tiny and 22 or 27, 36)
				icon.TextSize = tiny and 16 or InterfaceTheme.Typography.Sizes.Numeric
			end
			if amount and amount:IsA("TextLabel") then
				amount.Position = UDim2.new(0, tiny and 27 or 32, 0, 1)
				amount.Size = UDim2.new(1, tiny and -30 or -36, 0.62, 0)
				amount.TextSize = tiny and 12 or (compact and InterfaceTheme.Typography.Sizes.Body or InterfaceTheme.Typography.Sizes.Numeric)
			end
			if label and label:IsA("TextLabel") then
				label.Position = UDim2.new(0, tiny and 28 or 33, 0.58, 0)
				label.Size = UDim2.new(1, tiny and -30 or -35, 0, 12)
				label.TextSize = tiny and 8 or InterfaceTheme.Typography.Sizes.Micro
			end
		end
	end
	toast.Position = UDim2.new(0.5, 0, 0, compact and 108 or 106)
	toast.Size = UDim2.fromOffset(math.max(190, math.min(250, viewport.X - 32)), 36)
	bondLabel.Position = UDim2.new(0.5, 0, 0, compact and 148 or 70)
	bondLabel.Size = UDim2.fromOffset(math.max(200, math.min(300, viewport.X - 32)), 28)
	bondLabel.TextSize = tiny and 9 or InterfaceTheme.Typography.Sizes.Caption
end

local viewportConnection: RBXScriptConnection? = nil
local function bindViewportCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	end
	resize()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportCamera)
bindViewportCamera()

update.OnClientEvent:Connect(function(snapshot, resourceId, amount, code)
	applySnapshot(snapshot)
	showToast(resourceId, amount, code)
end)

task.spawn(function()
	local attempt = 0
	while player.Parent ~= nil do
		attempt += 1
		local result = RequestRunner.Invoke(function()
			return request:InvokeServer("Get")
		end, 12)
		if result.ok then
			local success, snapshot = result.value
			if success == true then
				applySnapshot(snapshot)
				return
			end
		end
		-- Island profile/session startup can outlast the first HUD render.
		-- Keep retrying with a capped delay instead of leaving permanent dashes.
		task.wait(math.min(2.5, 0.35 + attempt * 0.15))
	end
end)
