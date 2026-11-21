--!strict
-- Studio-only validation tests; invalid inputs must fail before MemoryStore access.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local services = script.Parent.Parent:WaitForChild("Services")
local LeaseService = require(services:WaitForChild("IslandLeaseService"))

local acquired, acquireCode = LeaseService.acquire(0, "")
assert(not acquired and acquireCode == "INVALID_LEASE_REQUEST", "invalid acquire request should be rejected")
local renewed, renewCode = LeaseService.renew(0, "")
assert(not renewed and renewCode == "INVALID_LEASE_REQUEST", "invalid renew request should be rejected")
local released, releaseCode = LeaseService.release(0, "")
assert(not released and releaseCode == "INVALID_LEASE_REQUEST", "invalid release request should be rejected")

print("[PetKingdoms Test] PASS: IslandLeaseService rejects invalid requests before MemoryStore access")
