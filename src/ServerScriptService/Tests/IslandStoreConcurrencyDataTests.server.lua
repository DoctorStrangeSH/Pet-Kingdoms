--!strict
-- Studio-only deterministic tests for DataStore session-generation and revision fencing.
-- These tests do not access or modify production DataStores.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local Fencing = require(services:WaitForChild("IslandStoreConcurrencyData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local firstGeneration, firstClaimCode = Fencing.nextSessionGeneration(nil, 0)
expect("first session claims generation one from an empty profile",
	firstGeneration == 1 and firstClaimCode == "CLAIMED")

local secondGeneration, secondClaimCode = Fencing.nextSessionGeneration(1, 1)
expect("next session atomically advances the observed generation",
	secondGeneration == 2 and secondClaimCode == "CLAIMED")

local delayedGeneration, delayedClaimCode = Fencing.nextSessionGeneration(2, 1)
expect("delayed loader cannot claim after another server advanced the generation",
	delayedGeneration == nil and delayedClaimCode == "GENERATION_CHANGED")

local concurrentWinner, concurrentWinnerCode = Fencing.nextSessionGeneration(7, 7)
local concurrentLoser, concurrentLoserCode = Fencing.nextSessionGeneration(8, 7)
expect("only the first concurrent claimant using the same observed generation can win",
	concurrentWinner == 8 and concurrentWinnerCode == "CLAIMED"
		and concurrentLoser == nil and concurrentLoserCode == "GENERATION_CHANGED")

local exhausted, exhaustedCode = Fencing.nextSessionGeneration(2_000_000_000, 2_000_000_000)
expect("generation counter fails closed at its supported maximum",
	exhausted == nil and exhaustedCode == "GENERATION_EXHAUSTED")

local invalidGeneration, invalidGenerationCode = Fencing.nextSessionGeneration(1.5, 1.5)
expect("fractional session generations are rejected",
	invalidGeneration == nil and invalidGenerationCode == "INVALID_GENERATION")

local staleSave = Fencing.classifySave(5, 40, 4, 41)
expect("old server cannot overwrite a profile claimed by a newer generation",
	staleSave == "STALE_SESSION")

local retrySave = Fencing.classifySave(5, 41, 5, 41)
expect("retry of an already committed revision is acknowledged without rewriting",
	retrySave == "ALREADY_DURABLE")

local supersededSave = Fencing.classifySave(5, 44, 5, 42)
expect("older retry is acknowledged when a newer revision from the same generation is durable",
	supersededSave == "ALREADY_DURABLE")

local currentSave = Fencing.classifySave(5, 41, 5, 42)
expect("newer snapshot from the current generation is allowed to write",
	currentSave == "WRITE")

local revisionRaceOld = Fencing.classifySave(5, 50, 5, 49)
local revisionRaceNew = Fencing.classifySave(5, 50, 5, 51)
expect("out-of-order saves never replace a newer persisted revision",
	revisionRaceOld == "ALREADY_DURABLE" and revisionRaceNew == "WRITE")

local malformedGeneration = Fencing.classifySave(0, 1, 0, 2)
local malformedRevision = Fencing.classifySave(5, 1.25, 5, 2)
expect("malformed generation and revision metadata fail closed",
	malformedGeneration == "INVALID_METADATA" and malformedRevision == "INVALID_METADATA")

print("[PetKingdoms Test] IslandStoreConcurrencyData tests completed.")
