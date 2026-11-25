--!strict
-- Opt-in pure layout math tests. Safe to run in Studio without creating UI.
local Workspace = game:GetService("Workspace")
if Workspace:GetAttribute("RunInterfaceComponentsTests") ~= true then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceComponents"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local function near(a: number, b: number, epsilon: number?): boolean
	return math.abs(a - b) <= (epsilon or 1e-3)
end

expect(
	"overview keeps natural scale when it fits",
	near(Components.GetSafeFitScale(Vector2.new(420, 286), Vector2.new(500, 400), 12), 1)
)
expect(
	"short landscape scales card to safe height",
	near(Components.GetSafeFitScale(Vector2.new(420, 286), Vector2.new(800, 220), 12), 196 / 286)
)
expect(
	"narrow portrait scales card to safe width",
	near(Components.GetSafeFitScale(Vector2.new(420, 286), Vector2.new(260, 600), 12), 236 / 420)
)
expect(
	"zero safe viewport returns zero scale instead of overflowing",
	near(Components.GetSafeFitScale(Vector2.new(420, 286), Vector2.zero, 12), 0)
)
expect(
	"invalid content dimensions safely return natural scale",
	near(Components.GetSafeFitScale(Vector2.new(0, 286), Vector2.new(200, 200), 12), 1)
)

local clamped = Components.ClampPanelSize(Vector2.new(420, 286), Vector2.new(260, 220), 12)
expect("panel dimensions stay inside safe rectangle", near(clamped.X, 236) and near(clamped.Y, 196))

print("[PetKingdoms Test] InterfaceComponents tests completed.")
