--!strict
-- Studio integration smoke test. Run only in a dedicated test universe with
-- MemoryStore API access enabled. Uses a unique synthetic user key.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local HttpService = game:GetService("HttpService")
local services = script.Parent.Parent:WaitForChild("Services")
local LeaseService = require(services:WaitForChild("IslandLeaseService"))

local invalidTypeAcquire, invalidTypeAcquireCode = LeaseService.acquire("not-a-user-id", "token")
assert(not invalidTypeAcquire and invalidTypeAcquireCode == "INVALID_LEASE_REQUEST")
local invalidAcquire, invalidAcquireCode = LeaseService.acquire(0, "")
assert(not invalidAcquire and invalidAcquireCode == "INVALID_LEASE_REQUEST")
local invalidRenew, invalidRenewCode = LeaseService.renew(0, "")
assert(not invalidRenew and invalidRenewCode == "INVALID_LEASE_REQUEST")
local invalidRelease, invalidReleaseCode = LeaseService.release(0, "")
assert(not invalidRelease and invalidReleaseCode == "INVALID_LEASE_REQUEST")

-- UserId is only used to derive an isolated MemoryStore key in this test.
local syntheticUserId = 2_000_000_000 + math.random(1, 900_000_000)
local tokenA = HttpService:GenerateGUID(false)
local tokenB = HttpService:GenerateGUID(false)

local acquiredA, acquireAStatus = LeaseService.acquire(syntheticUserId, tokenA)
assert(acquiredA, "first lease acquire failed: " .. acquireAStatus)

local acquiredB, acquireBStatus = LeaseService.acquire(syntheticUserId, tokenB)
assert(not acquiredB and acquireBStatus == "LEASE_HELD_BY_ANOTHER_SERVER", "second server must not steal a live lease")

local renewedWrong, renewWrongStatus = LeaseService.renew(syntheticUserId, tokenB)
assert(not renewedWrong and renewWrongStatus == "LEASE_LOST", "non-owner must not renew the lease")

local releasedWrong, releaseWrongStatus = LeaseService.release(syntheticUserId, tokenB)
assert(not releasedWrong and releaseWrongStatus == "LEASE_NOT_OWNED", "non-owner must not release the lease")

local renewedA, renewAStatus = LeaseService.renew(syntheticUserId, tokenA)
assert(renewedA, "owner renewal failed: " .. renewAStatus)

local releasedA, releaseAStatus = LeaseService.release(syntheticUserId, tokenA)
assert(releasedA, "owner release failed: " .. releaseAStatus)

local acquiredBAfterRelease, acquireBAfterReleaseStatus = LeaseService.acquire(syntheticUserId, tokenB)
assert(acquiredBAfterRelease, "new server could not acquire released lease: " .. acquireBAfterReleaseStatus)

local releasedB, releaseBStatus = LeaseService.release(syntheticUserId, tokenB)
assert(releasedB, "test cleanup failed: " .. releaseBStatus)

print("[PetKingdoms Test] PASS: lease exclusivity, owner renewal, stale-token protection, release, and reacquire")
