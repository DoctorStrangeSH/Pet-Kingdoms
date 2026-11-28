--!strict
-- Studio-only deterministic tests for MemoryStore island lease transitions.
-- These tests never access MemoryStore or DataStore.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local Lease = require(services:WaitForChild("IslandLeaseData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local now = 1_000
local ttl = 90

local first, firstCode = Lease.acquire(nil, "server-A", now, ttl)
expect("empty lease can be acquired", first ~= nil and firstCode == "ACQUIRED"
	and first.token == "server-A" and first.expiresAt == now + ttl and first.released == false)

local blocked, blockedCode = Lease.acquire(first, "server-B", now + 1, ttl)
expect("active lease blocks a different server", blocked == nil
	and blockedCode == "LEASE_HELD_BY_ANOTHER_SERVER")

local sameOwner, sameOwnerCode = Lease.acquire(first, "server-A", now + 1, ttl)
expect("same token can safely refresh its own lease", sameOwner ~= nil
	and sameOwnerCode == "ACQUIRED" and sameOwner.expiresAt == now + 1 + ttl)

local renewed, renewedCode = Lease.renew(first, "server-A", now + 10, ttl)
expect("lease owner can renew before expiry", renewed ~= nil and renewedCode == "RENEWED"
	and renewed.expiresAt == now + 10 + ttl)

local wrongOwnerRenew, wrongOwnerRenewCode = Lease.renew(first, "server-B", now + 10, ttl)
expect("different server cannot renew another token", wrongOwnerRenew == nil
	and wrongOwnerRenewCode == "LEASE_LOST")

local expiredRenew, expiredRenewCode = Lease.renew(first, "server-A", first.expiresAt, ttl)
expect("expired lease cannot be renewed", expiredRenew == nil and expiredRenewCode == "LEASE_LOST")

local released, releasedCode = Lease.release(first, "server-A", now + 20)
expect("owner can release its lease", released ~= nil and releasedCode == "RELEASED"
	and released.released == true and released.expiresAt == now + 20)

local takeover, takeoverCode = Lease.acquire(released, "server-B", now + 21, ttl)
expect("released lease can be acquired by another server", takeover ~= nil
	and takeoverCode == "ACQUIRED" and takeover.token == "server-B")

local expiredTakeover, expiredTakeoverCode = Lease.acquire(first, "server-B", first.expiresAt, ttl)
expect("another server can acquire an expired lease", expiredTakeover ~= nil
	and expiredTakeoverCode == "ACQUIRED" and expiredTakeover.token == "server-B")

local staleRelease, staleReleaseCode = Lease.release(takeover, "server-A", now + 22)
expect("old token cannot release a newer server lease", staleRelease == nil
	and staleReleaseCode == "LEASE_NOT_OWNED")

local releasedRenew, releasedRenewCode = Lease.renew(released, "server-A", now + 21, ttl)
expect("released lease cannot be renewed", releasedRenew == nil
	and releasedRenewCode == "LEASE_LOST")

local malformedAcquire, malformedAcquireCode = Lease.acquire({
	token = "server-A",
	expiresAt = "not-a-time",
	released = false,
}, "server-B", now, ttl)
expect("malformed expiry cannot permanently lock out a player", malformedAcquire ~= nil
	and malformedAcquireCode == "ACQUIRED")

local malformedRenew, malformedRenewCode = Lease.renew({
	token = "server-A",
	expiresAt = "not-a-time",
	released = false,
}, "server-A", now, ttl)
expect("malformed expiry fails closed during renewal", malformedRenew == nil
	and malformedRenewCode == "LEASE_LOST")

local missingRelease, missingReleaseCode = Lease.release(nil, "server-A", now)
expect("missing lease cannot be released by a token", missingRelease == nil
	and missingReleaseCode == "LEASE_NOT_OWNED")

local invalidAcquire, invalidAcquireCode = Lease.acquire(nil, "", now, ttl)
expect("empty token is rejected", invalidAcquire == nil
	and invalidAcquireCode == "INVALID_LEASE_REQUEST")

print("[PetKingdoms Test] IslandLeaseData tests completed.")
