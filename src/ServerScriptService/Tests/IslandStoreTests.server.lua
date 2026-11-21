--!strict
-- Studio-only contract tests for IslandStore's input validation.
-- These tests deliberately do not touch a live DataStore.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local services = script.Parent.Parent:WaitForChild("Services")
local IslandStore = require(services:WaitForChild("IslandStore"))

local invalidOk, invalidCode = IslandStore.load(0)
assert(not invalidOk and invalidCode == "INVALID_USER_ID", "invalid user ID should be rejected before DataStore access")
print("[PetKingdoms Test] PASS: IslandStore rejects invalid user ID before DataStore access")

local saveOk, saveCode = IslandStore.save({})
assert(not saveOk and saveCode == "INVALID_PROFILE", "invalid profile should be rejected before DataStore access")
print("[PetKingdoms Test] PASS: IslandStore rejects invalid profile before DataStore access")

print("[PetKingdoms Test] IslandStore contract tests completed.")
