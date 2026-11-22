--!strict
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Session = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	:WaitForChild("Pets"):WaitForChild("PetCollectionSessionData"))

local function expect(name: string, value: boolean)
	assert(value, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local function defaultProfile()
	return { revision = 0, owned = {}, equipped = {} }
end
local first, firstStatus = Session.claim(nil, nil, "server-a", defaultProfile)
expect("first writer claims a fresh profile", first ~= nil and firstStatus == "CLAIMED")
assert(first ~= nil)
expect("initial claim has generation one", first.collectionSessionGeneration == 1)
expect("claim does not mutate default profile fields", first.revision == 0)

local again, againStatus = Session.claim(first, first, "server-a", defaultProfile)
expect("ambiguous retry with the same token is idempotent", again == first and againStatus == "ALREADY_CLAIMED")

local second, secondStatus = Session.claim(first, first, "server-b", defaultProfile)
expect("second writer advances the generation", second ~= nil and secondStatus == "CLAIMED")
assert(second ~= nil)
expect("old writer is fenced after another claim", not Session.owns(second, 1, "server-a"))
expect("new writer owns latest generation", Session.owns(second, 2, "server-b"))

local stale, staleStatus = Session.claim(second, first, "server-c", defaultProfile)
expect("delayed claim cannot supersede newer session", stale == nil and staleStatus == "STALE_OBSERVATION")

local modified = table.clone(first)
modified.revision = 1
local changed, changedStatus = Session.claim(modified, first, "server-d", defaultProfile)
expect("concurrent revision change invalidates the observation", changed == nil and changedStatus == "STALE_OBSERVATION")

local badToken = Session.claim(first, first, "", defaultProfile)
expect("empty session token rejected", badToken == nil)

print("[PetKingdoms Test] PetCollectionSessionData tests completed.")
