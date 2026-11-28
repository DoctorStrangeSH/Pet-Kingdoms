--!strict
-- Pure lease transition rules used by MemoryStore UpdateAsync transforms.
-- No service calls here: transitions are deterministic and Studio-testable.

local IslandLeaseData = {}

function IslandLeaseData.acquire(current: any, token: string, now: number, ttlSeconds: number): (any?, string)
	if type(token) ~= "string" or token == "" or type(now) ~= "number"
		or type(ttlSeconds) ~= "number" or ttlSeconds <= 0
	then
		return nil, "INVALID_LEASE_REQUEST"
	end

	if type(current) == "table"
		and current.token ~= token
		and current.released ~= true
		and type(current.expiresAt) == "number"
		and current.expiresAt > now
	then
		return nil, "LEASE_HELD_BY_ANOTHER_SERVER"
	end

	return {
		token = token,
		expiresAt = now + ttlSeconds,
		released = false,
	}, "ACQUIRED"
end

function IslandLeaseData.renew(current: any, token: string, now: number, ttlSeconds: number): (any?, string)
	if type(token) ~= "string" or token == "" or type(now) ~= "number"
		or type(ttlSeconds) ~= "number" or ttlSeconds <= 0
	then
		return nil, "INVALID_LEASE_REQUEST"
	end

	if type(current) ~= "table" or current.token ~= token
		or current.released == true
		or type(current.expiresAt) ~= "number"
		or current.expiresAt <= now
	then
		return nil, "LEASE_LOST"
	end

	return {
		token = token,
		expiresAt = now + ttlSeconds,
		released = false,
	}, "RENEWED"
end

function IslandLeaseData.release(current: any, token: string, now: number): (any?, string)
	if type(token) ~= "string" or token == "" or type(now) ~= "number" then
		return nil, "INVALID_LEASE_REQUEST"
	end
	if type(current) ~= "table" or current.token ~= token then
		return nil, "LEASE_NOT_OWNED"
	end

	return {
		token = token,
		expiresAt = now,
		released = true,
	}, "RELEASED"
end

return IslandLeaseData
