--!strict
-- Studio client smoke tests. Run in a dedicated test place with the test attribute enabled.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("RunPetKingdomsStudioTests") ~= true then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModalManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModalManager"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local closeOrder = {}
local firstOpen = false
local secondOpen = false
local firstClose = function(reason: string)
	firstOpen = false
	table.insert(closeOrder, "first:" .. reason)
end
local secondClose = function(reason: string)
	secondOpen = false
	table.insert(closeOrder, "second:" .. reason)
end

ModalManager.Register("ModalManagerTestFirst", firstClose)
ModalManager.Register("ModalManagerTestSecond", secondClose)

firstOpen = true
ModalManager.Open("ModalManagerTestFirst")
expect("registered first modal receives focus", ModalManager.IsActive("ModalManagerTestFirst"))

secondOpen = true
ModalManager.Open("ModalManagerTestSecond")
expect("opening second modal transfers focus", ModalManager.IsActive("ModalManagerTestSecond"))
expect("switch closes first modal", not firstOpen)
expect("switch preserves newly opened modal", secondOpen)

-- CloseAll must repair stale visibility even when a window is not the active one.
firstOpen = true
ModalManager.CloseAll()
expect("CloseAll clears active focus", ModalManager.GetActive() == nil)
expect("CloseAll closes every registered modal", not firstOpen and not secondOpen)

-- Escape routing is based on one focused top-level window.
ModalManager.Open("ModalManagerTestFirst")
expect("only focused modal reports active", ModalManager.IsActive("ModalManagerTestFirst")
	and not ModalManager.IsActive("ModalManagerTestSecond"))
ModalManager.Close("ModalManagerTestFirst")
expect("closing focused modal clears focus", ModalManager.GetActive() == nil)

-- Unregistering a visible controller must run its close handler before
-- removing the registration, otherwise its GUI shade can remain on screen.
firstOpen = true
ModalManager.Open("ModalManagerTestFirst")
ModalManager.Unregister("ModalManagerTestFirst")
expect("unregister closes visible modal", not firstOpen)
expect("unregister clears modal focus", ModalManager.GetActive() == nil)

ModalManager.Unregister("ModalManagerTestSecond")
expect("unregistered modal cannot retain focus", ModalManager.GetActive() == nil)

print("[PetKingdoms Test] ModalManager smoke tests completed.")
