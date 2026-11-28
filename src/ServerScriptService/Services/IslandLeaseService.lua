--!strict
-- Cross-server single-writer lease for one player's island profile.
-- Uses MemoryStoreHashMap atomic UpdateAsync transforms. Fail closed on errors.
local MemoryStoreService = game:GetService("MemoryStoreService")
local LEASES = MemoryStoreService:GetHashMap("PetKingdoms_IslandLeases_v1")
local IslandLeaseData = require(script.Parent:WaitForChild("IslandLeaseData"))

local LeaseService = {}
local LEASE_TTL_SECONDS = 90
local RENEWAL_WINDOW_SECONDS = 30

local function keyFor(userId: number): string
	return "player_" .. tostring(userId)
end

local function validUserId(userId: number): boolean
	return type(userId) == "number"
		and userId > 0
		and userId == math.floor(userId)
		and userId == userId
		and userId < math.huge
end

function LeaseService.newToken(): string
	return game:GetService("HttpService"):GenerateGUID(false)
end

function LeaseService.acquire(userId: number, token: string): (boolean, string)
	if not validUserId(userId) or type(token) ~= "string" or token == "" then
		return false, "INVALID_LEASE_REQUEST"
	end

	local now = os.time()
	local ok, record = pcall(function()
		return LEASES:UpdateAsync(keyFor(userId), function(current)
			local nextRecord = IslandLeaseData.acquire(current, token, now, LEASE_TTL_SECONDS)
			return nextRecord
		end, LEASE_TTL_SECONDS)
	end)

	if not ok then
		warn("[PetKingdoms] MemoryStore lease acquire failed:", record)
		return false, "LEASE_STORE_UNAVAILABLE"
	end

	if type(record) == "table" and record.token == token and record.released ~= true then
		return true, "ACQUIRED"
	end
	return false, "LEASE_HELD_BY_ANOTHER_SERVER"
end

function LeaseService.renew(userId: number, token: string): (boolean, string)
	if not validUserId(userId) or type(token) ~= "string" or token == "" then
		return false, "INVALID_LEASE_REQUEST"
	end

	local now = os.time()
	local ok, record = pcall(function()
		return LEASES:UpdateAsync(keyFor(userId), function(current)
			local nextRecord = IslandLeaseData.renew(current, token, now, LEASE_TTL_SECONDS)
			return nextRecord
		end, LEASE_TTL_SECONDS)
	end)

	if not ok then
		warn("[PetKingdoms] MemoryStore lease renewal failed:", record)
		return false, "LEASE_STORE_UNAVAILABLE"
	end

	if type(record) == "table" and record.token == token
		and record.released ~= true and type(record.expiresAt) == "number"
		and record.expiresAt > now
	then
		return true, "RENEWED"
	end
	return false, "LEASE_LOST"
end

function LeaseService.release(userId: number, token: string): (boolean, string)
	if not validUserId(userId) or type(token) ~= "string" or token == "" then
		return false, "INVALID_LEASE_REQUEST"
	end

	local now = os.time()
	local ok, record = pcall(function()
		return LEASES:UpdateAsync(keyFor(userId), function(current)
			local nextRecord = IslandLeaseData.release(current, token, now)
			return nextRecord
		end, 1)
	end)

	if not ok then
		warn("[PetKingdoms] MemoryStore lease release failed:", record)
		return false, "LEASE_STORE_UNAVAILABLE"
	end

	if type(record) == "table" and record.token == token and record.released == true then
		return true, "RELEASED"
	end
	return false, "LEASE_NOT_OWNED"
end

LeaseService.LEASE_TTL_SECONDS = LEASE_TTL_SECONDS
LeaseService.RENEWAL_WINDOW_SECONDS = RENEWAL_WINDOW_SECONDS

return LeaseService
