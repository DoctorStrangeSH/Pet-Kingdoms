--!strict
-- Studio-only resource cooldown visibility regression tests.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Visibility = require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("ResourceNodeVisibility"))

local node = Instance.new("Model")
node.Name = "ResourceVisibilityFixture"
local visual = Instance.new("Part")
visual.Name = "TranslucentVisual"
visual.Transparency = 0.35
visual.CanCollide = true
visual.Parent = node
local anchor = Instance.new("Part")
anchor.Name = "GatherAnchor"
anchor.Transparency = 1
anchor.CanCollide = false
anchor.Parent = node
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "GatherPrompt"
prompt.Parent = anchor
local marker = Instance.new("BillboardGui")
marker.Name = "ResourceMarker"
marker.Parent = node

Visibility.setVisible(node, false)
assert(visual.Transparency == 1 and anchor.Transparency == 1,
	"cooldown must hide the model without revealing the anchor")
assert(not prompt.Enabled and not marker.Enabled,
	"cooldown must disable gathering prompt and resource marker")
Visibility.setVisible(node, true)
assert(math.abs(visual.Transparency - 0.35) < 0.001,
	"respawn must restore custom model source transparency")
assert(anchor.Transparency == 1 and not anchor.CanCollide,
	"respawn must never reveal or collide with the invisible anchor")
assert(not visual.CanCollide and prompt.Enabled and marker.Enabled,
	"respawn must restore interactive cues while keeping resource visual noncolliding")
Visibility.setVisible(node, false)
Visibility.setVisible(node, true)
assert(math.abs(visual.Transparency - 0.35) < 0.001,
	"multiple cooldown cycles must not overwrite the original alpha")
node:Destroy()
print("[PetKingdoms Test] PASS: resource cooldown visibility hide/restore cycles")
