--!strict
-- Compact responsive resource HUD. The server is the sole source of balances.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("IslandResourceRequest") :: RemoteFunction
local update = remotes:WaitForChild("IslandResourceUpdate") :: RemoteEvent

local COLORS = {
	panel = Color3.fromRGB(34, 39, 53),
	panelSoft = Color3.fromRGB(49, 56, 73),
	cream = Color3.fromRGB(255, 246, 225),
	muted = Color3.fromRGB(177, 187, 204),
	gold = Color3.fromRGB(255, 207, 123),
	mint = Color3.fromRGB(143, 229, 185),
	line = Color3.fromRGB(104, 119, 148),
}

local RESOURCES = {
	{ id = "wood", icon = "🌲", label = "ДЕРЕВО", color = Color3.fromRGB(169, 207, 151) },
	{ id = "stone", icon = "🪨", label = "КАМЕНЬ", color = Color3.fromRGB(190, 202, 218) },
	{ id = "gold", icon = "🪙", label = "ЗОЛОТО", color = COLORS.gold },
	{ id = "gems", icon = "💎", label = "КРИСТАЛЛЫ", color = Color3.fromRGB(139, 218, 235) },
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
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 17)
local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.line
stroke.Transparency = 0.28
stroke.Thickness = 1.2
stroke.Parent = root
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 7)
padding.PaddingRight = UDim.new(0, 7)
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = root
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 6)
layout.Parent = root

local amountLabels: { [string]: TextLabel } = {}
for _, resource in ipairs(RESOURCES) do
	local chip = Instance.new("Frame")
	chip.Name = resource.id .. "Chip"
	chip.Size = UDim2.new(0.25, -5, 1, 0)
	chip.BackgroundColor3 = COLORS.panelSoft
	chip.Parent = root
	Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 12)

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 5, 0, 0)
	icon.Size = UDim2.new(0, 27, 1, 0)
	icon.Font = Enum.Font.Gotham
	icon.Text = resource.icon
	icon.TextSize = 19
	icon.Parent = chip

	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.BackgroundTransparency = 1
	amount.Position = UDim2.new(0, 32, 0, 2)
	amount.Size = UDim2.new(1, -36, 0.58, 0)
	amount.Font = Enum.Font.GothamBold
	amount.Text = "—"
	amount.TextSize = 17
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.TextColor3 = resource.color
	amount.Parent = chip
	amountLabels[resource.id] = amount

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 33, 0.57, -1)
	label.Size = UDim2.new(1, -35, 0.36, 0)
	label.Font = Enum.Font.GothamMedium
	label.Text = resource.label
	label.TextSize = 7
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = COLORS.muted
	label.Parent = chip
end

local toast = Instance.new("TextLabel")
toast.Name = "GatherToast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 178)
toast.Size = UDim2.fromOffset(250, 38)
toast.BackgroundColor3 = COLORS.panel
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.Text = ""
toast.TextColor3 = COLORS.mint
toast.TextSize = 15
toast.Font = Enum.Font.GothamBold
toast.Visible = false
toast.Parent = screen
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 13)
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
bondLabel.Text = "🏡 Тихий остров"
bondLabel.TextColor3 = COLORS.gold
bondLabel.TextSize = 12
bondLabel.Font = Enum.Font.GothamBold
bondLabel.Visible = false
bondLabel.Parent = screen
Instance.new("UICorner", bondLabel).CornerRadius = UDim.new(0, 10)
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
		then string.format("🏡 %s  •  %d очков  •  дальше: %d", stageName, points, nextPoints)
		else string.format("🏡 %s  •  %d очков  •  максимум", stageName, points)
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

local gatherHint = Instance.new("TextLabel")
gatherHint.Name = "GatheringHint"
gatherHint.AnchorPoint = Vector2.new(0.5, 0)
gatherHint.Position = UDim2.new(0.5, 0, 0, 106)
gatherHint.Size = UDim2.new(0.94, 0, 0, 32)
gatherHint.BackgroundColor3 = COLORS.panel
gatherHint.BackgroundTransparency = 0.08
gatherHint.BorderSizePixel = 0
gatherHint.Text = "НАЙДИ ДЕРЕВО  •  E / НАЖМИ «СРУБИТЬ»"
gatherHint.TextColor3 = COLORS.mint
gatherHint.TextSize = 11
gatherHint.Font = Enum.Font.GothamBold
gatherHint.TextWrapped = true
gatherHint.Visible = false
gatherHint.Parent = screen
Instance.new("UICorner", gatherHint).CornerRadius = UDim.new(0, 10)
local gatherHintStroke = Instance.new("UIStroke")
gatherHintStroke.Color = COLORS.mint
gatherHintStroke.Transparency = 0.45
gatherHintStroke.Parent = gatherHint

-- Read-only gathering feedback. Nodes expose their server-owned cooldown
-- deadline as a replicated attribute; no client request can change rewards.
local gatheringAvailability = Instance.new("TextLabel")
gatheringAvailability.Name = "ResourceAvailability"
gatheringAvailability.AnchorPoint = Vector2.new(0.5, 0)
gatheringAvailability.Position = UDim2.new(0.5, 0, 0, 142)
gatheringAvailability.Size = UDim2.new(0.94, 0, 0, 28)
gatheringAvailability.BackgroundColor3 = COLORS.panel
gatheringAvailability.BackgroundTransparency = 0.12
gatheringAvailability.BorderSizePixel = 0
gatheringAvailability.Text = ""
gatheringAvailability.TextColor3 = COLORS.muted
gatheringAvailability.Font = Enum.Font.GothamMedium
gatheringAvailability.TextSize = 12
gatheringAvailability.Visible = false
gatheringAvailability.Parent = screen
Instance.new("UICorner", gatheringAvailability).CornerRadius = UDim.new(0, 10)

local function updateGatheringAvailability()
	local worlds = Workspace:FindFirstChild("PlayerIslands")
	local ownWorld = worlds and worlds:FindFirstChild("Island_" .. tostring(player.UserId))
	local nodes = ownWorld and ownWorld:FindFirstChild("ResourceNodes")
	if nodes == nil then
		gatheringAvailability.Visible = false
		return
	end

	local availableWood, availableStone = 0, 0
	local totalWood, totalStone = 0, 0
	local nextReady: number? = nil
	local now = Workspace:GetServerTimeNow()
	for _, node in ipairs(nodes:GetChildren()) do
		if not node:IsA("Model") or node:GetAttribute("OwnerUserId") ~= player.UserId then continue end
		local resourceId = node:GetAttribute("ResourceId")
		local availableAt = node:GetAttribute("AvailableAt")
		if resourceId ~= "wood" and resourceId ~= "stone" then continue end
		local ready = type(availableAt) == "number" and availableAt <= now
		if resourceId == "wood" then
			totalWood += 1
			if ready then availableWood += 1 end
		else
			totalStone += 1
			if ready then availableStone += 1 end
		end
		if type(availableAt) == "number" and availableAt > now then
			nextReady = if nextReady then math.min(nextReady, availableAt) else availableAt
		end
	end
	if totalWood + totalStone == 0 then
		gatheringAvailability.Visible = false
		return
	end
	local upcoming = ""
	if nextReady then
		local remaining = math.max(1, math.ceil(nextReady - now))
		upcoming = string.format("  •  ещё через %02d:%02d", math.floor(remaining / 60), remaining % 60)
	end
	gatheringAvailability.Text = string.format(
		"🌲 %d/%d  •  🪨 %d/%d%s", availableWood, totalWood, availableStone, totalStone, upcoming
	)
	gatheringAvailability.Visible = true
end

task.spawn(function()
	while screen.Parent ~= nil do
		updateGatheringAvailability()
		task.wait(1)
	end
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
	if type(snapshot.wood) == "number" then
		gatherHint.Visible = snapshot.wood == 0
	end
end

local function resize()
	local camera = Workspace.CurrentCamera
	if camera == nil then return end
	local width = camera.ViewportSize.X
	local compact = width < 560
	root.Size = UDim2.new(compact and 0.96 or 0, compact and 0 or 420, 0, compact and 48 or 54)
	if compact then
		root.Size = UDim2.new(0.96, 0, 0, 48)
	end
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("Frame") then
			child.Size = UDim2.new(0.25, -4, 1, 0)
		end
	end
	for _, label in pairs(amountLabels) do
		label.TextSize = compact and 14 or 17
	end
	gatherHint.TextSize = compact and 9 or 11
	gatheringAvailability.TextSize = compact and 10 or 12
end

if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
		resize()
	end
end)
resize()

update.OnClientEvent:Connect(function(snapshot, resourceId, amount, code)
	applySnapshot(snapshot)
	showToast(resourceId, amount, code)
end)

task.spawn(function()
	for attempt = 1, 6 do
		local ok, success, snapshot = pcall(function()
			return request:InvokeServer("Get")
		end)
		if ok and success == true then
			applySnapshot(snapshot)
			return
		end
		task.wait(math.min(1.5, 0.25 * attempt))
	end
	warn("[PetKingdoms] Resource HUD could not load initial wallet snapshot.")
end)
