--!strict
-- Studio client smoke tests. Run in a dedicated test place with the test attribute enabled.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("RunPetKingdomsStudioTests") ~= true then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TouchGestureGate = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Building"):WaitForChild("TouchGestureGate")
)

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local first = {} :: any
local second = {} :: any
local third = {} :: any
local fourth = {} :: any

-- A single eligible finger may own a placement tap/drag until release.
expect("first eligible touch becomes placement candidate", TouchGestureGate.Begin(first, true))
expect("single touch is not camera-blocked", not TouchGestureGate.IsBlocked())
expect("candidate identity is retained", TouchGestureGate.GetCandidate() == first)
expect("single touch release may commit", TouchGestureGate.End(first, false))
expect("gate is ready after single touch release", not TouchGestureGate.IsBlocked())

-- A second finger cancels the entire sequence; neither release may commit.
expect("first touch starts a new sequence", TouchGestureGate.Begin(first, true))
expect("second finger cancels placement candidate", not TouchGestureGate.Begin(second, true))
expect("multi-touch sequence is blocked from placement", TouchGestureGate.IsBlocked())
expect("candidate is cleared after second finger", TouchGestureGate.GetCandidate() == nil)
expect("first finger release cannot commit", not TouchGestureGate.End(first, false))
expect("gesture remains blocked while second finger is down", TouchGestureGate.IsBlocked())
expect("third finger joins blocked camera gesture", not TouchGestureGate.Begin(third, true))
expect("second finger release cannot commit", not TouchGestureGate.End(second, false))
expect("gesture remains blocked while third finger is down", TouchGestureGate.IsBlocked())
expect("third finger release cannot commit", not TouchGestureGate.End(third, false))
expect("gate unlocks only after every finger is released", not TouchGestureGate.IsBlocked())

-- A cancelled single touch must not lock a placement target.
expect("touch after multi-touch can start normally", TouchGestureGate.Begin(fourth, true))
expect("cancelled touch cannot commit", not TouchGestureGate.End(fourth, true))
expect("cancelled touch leaves gate clear", not TouchGestureGate.IsBlocked())

-- Touches that began over GUI or were otherwise processed never become candidates.
expect("ineligible touch is tracked without becoming candidate", not TouchGestureGate.Begin(first, false))
expect("ineligible touch has no candidate", TouchGestureGate.GetCandidate() == nil)
expect("ineligible touch cannot commit", not TouchGestureGate.End(first, false))

-- Duplicate Begin for the same InputObject must not inflate the active count.
expect("duplicate begin keeps the same candidate", TouchGestureGate.Begin(first, true))
expect("duplicate begin is idempotent", TouchGestureGate.Begin(first, true))
expect("a distinct second input still blocks the gesture", not TouchGestureGate.Begin(second, true))
expect("release of duplicate candidate cannot commit multi-touch", not TouchGestureGate.End(first, false))
expect("second input release clears multi-touch block", not TouchGestureGate.End(second, false))
expect("duplicate sequence leaves no blocked state", not TouchGestureGate.IsBlocked())

-- Focus loss reset clears every tracked input, including an interrupted sequence.
expect("touch before focus reset starts", TouchGestureGate.Begin(first, true))
expect("second touch blocks before focus reset", not TouchGestureGate.Begin(second, true))
TouchGestureGate.Reset()
expect("reset clears blocked state", not TouchGestureGate.IsBlocked())
expect("reset clears candidate", TouchGestureGate.GetCandidate() == nil)
expect("stale release after reset cannot commit", not TouchGestureGate.End(first, false))
expect("fresh touch works after reset", TouchGestureGate.Begin(third, true))
expect("fresh touch commits after reset", TouchGestureGate.End(third, false))

TouchGestureGate.Reset()
print("[PetKingdoms Test] TouchGestureGate smoke tests completed.")
