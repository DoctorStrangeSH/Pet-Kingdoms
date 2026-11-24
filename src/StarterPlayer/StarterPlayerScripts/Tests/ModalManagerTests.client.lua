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

local activeChanges: { string } = {}
local activeChangedConnection = ModalManager.ActiveChanged:Connect(function(name: string?)
	table.insert(activeChanges, name or "none")
end)
local firstOpen = false
local secondOpen = false
local firstClose = function(_reason: string)
	firstOpen = false
end
local secondClose = function(_reason: string)
	secondOpen = false
end

ModalManager.Register("ModalManagerTestFirst", firstClose)
ModalManager.Register("ModalManagerTestSecond", secondClose)

firstOpen = true
ModalManager.Open("ModalManagerTestFirst")
expect("registered first modal receives focus", ModalManager.IsActive("ModalManagerTestFirst"))
expect("active modal change is published", activeChanges[#activeChanges] == "ModalManagerTestFirst")

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

ModalManager.Open("ModalManagerTestFirst")
expect("only focused modal reports active", ModalManager.IsActive("ModalManagerTestFirst")
	and not ModalManager.IsActive("ModalManagerTestSecond"))
ModalManager.Close("ModalManagerTestFirst")
expect("closing focused modal clears focus", ModalManager.GetActive() == nil)
expect("closing modal publishes empty focus", activeChanges[#activeChanges] == "none")

-- Unregistering a visible controller must run cleanup before dropping its callback.
firstOpen = true
ModalManager.Open("ModalManagerTestFirst")
ModalManager.Unregister("ModalManagerTestFirst")
expect("unregister closes visible modal", not firstOpen)
expect("unregister clears modal focus", ModalManager.GetActive() == nil)
expect("unregister publishes empty focus", activeChanges[#activeChanges] == "none")

-- Re-registering a live controller must clean the old controller before replacement.
ModalManager.Register("ModalManagerTestFirst", firstClose)
firstOpen = true
ModalManager.Open("ModalManagerTestFirst")
ModalManager.Register("ModalManagerTestFirst", function(_reason: string)
	firstOpen = false
end)
expect("re-register closes previous controller", not firstOpen)
expect("re-register clears previous focus", ModalManager.GetActive() == nil)
expect("re-register publishes empty focus", activeChanges[#activeChanges] == "none")
ModalManager.Open("ModalManagerTestFirst")
expect("replacement registration can open", ModalManager.IsActive("ModalManagerTestFirst"))

-- Cleanup callbacks must be able to unregister themselves without recursion.
local recursiveCleanupCount = 0
ModalManager.Register("ModalManagerTestRecursive", function(_reason: string)
	recursiveCleanupCount += 1
	ModalManager.Unregister("ModalManagerTestRecursive")
end)
ModalManager.Open("ModalManagerTestRecursive")
ModalManager.Unregister("ModalManagerTestRecursive")
expect("cleanup callback can unregister itself safely", recursiveCleanupCount == 1)
expect("self-unregistered modal loses focus", ModalManager.GetActive() == nil)

-- Unregister must also clean a stale visible panel when focus bookkeeping was lost.
ModalManager.Close("ModalManagerTestFirst")
firstOpen = true
ModalManager.Unregister("ModalManagerTestFirst")
expect("inactive unregister still runs cleanup", not firstOpen)
expect("inactive unregister leaves no focus", ModalManager.GetActive() == nil)

activeChangedConnection:Disconnect()
ModalManager.Unregister("ModalManagerTestSecond")
expect("unregistered modal cannot retain focus", ModalManager.GetActive() == nil)

print("[PetKingdoms Test] ModalManager smoke tests completed.")
