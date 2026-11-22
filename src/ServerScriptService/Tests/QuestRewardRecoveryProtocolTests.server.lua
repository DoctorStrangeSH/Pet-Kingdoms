--!strict
-- Studio-only fault-injection tests for every cross-DataStore recovery boundary.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local Protocol = require(services:WaitForChild("QuestRewardRecoveryProtocol"))

local STAGES = { "grant", "delivery", "sourceAck", "petAck", "finalMarker" }
local record = {
	rewardId = "quest:fault_injection:reward:v1",
	questId = "gather_wood",
	petId = "starter-bunny",
	amount = 250,
	progressionVersion = 1,
	createdAt = 100,
}

local function runScenario(failureStage: string)
	local state = {
		xpApplications = 0,
		grantCommitted = false,
		deliveryCommitted = false,
		sourceAcknowledged = false,
		petReceiptAcknowledged = false,
		finalMarkerCommitted = false,
		injected = false,
	}
	local function afterCommit(stage: string): (boolean, string)
		if failureStage == stage and not state.injected then
			state.injected = true
			return false, "SIMULATED_RESPONSE_LOST_AFTER_COMMIT"
		end
		return true, "DURABLE"
	end
	local handlers = {
		getThresholds = function(version: number)
			if version ~= 1 then return nil, "UNKNOWN_VERSION" end
			return { 100, 250, 500 }, "CONFIGURED"
		end,
		grantExperience = function(petId: string, rewardId: string, amount: number, thresholds: { number })
			if petId ~= record.petId or rewardId ~= record.rewardId or amount ~= record.amount then
				return false, "PAYLOAD_MISMATCH"
			end
			if not state.grantCommitted then
				state.grantCommitted = true
				state.xpApplications += 1
			end
			return afterCommit("grant")
		end,
		commitDelivery = function(rewardId: string)
			if rewardId ~= record.rewardId then return false, "REWARD_ID_MISMATCH" end
			state.deliveryCommitted = true
			return afterCommit("delivery")
		end,
		commitSourceAcknowledgement = function(rewardId: string)
			if not state.deliveryCommitted then return false, "NOT_DELIVERED" end
			state.sourceAcknowledged = true
			return afterCommit("sourceAck")
		end,
		acknowledgePetReceipt = function(rewardId: string)
			if not state.sourceAcknowledged then return false, "SOURCE_NOT_ACKNOWLEDGED" end
			state.petReceiptAcknowledged = true
			return afterCommit("petAck")
		end,
		commitPetAcknowledgement = function(rewardId: string)
			if not state.petReceiptAcknowledged then return false, "PET_RECEIPT_NOT_ACKNOWLEDGED" end
			state.finalMarkerCommitted = true
			return afterCommit("finalMarker")
		end,
	}

	local firstOk = Protocol.deliverPending(record, handlers)
	assert(not firstOk, failureStage .. ": first attempt must simulate an interrupted response")
	local retryOk, retryStatus = Protocol.deliverPending(record, handlers)
	assert(retryOk, failureStage .. ": retry failed: " .. retryStatus)
	assert(state.xpApplications == 1, failureStage .. ": XP was applied more than once")
	assert(state.grantCommitted and state.deliveryCommitted and state.sourceAcknowledged
		and state.petReceiptAcknowledged and state.finalMarkerCommitted,
		failureStage .. ": transaction did not reach final durable state")
	return true
end

for _, stage in ipairs(STAGES) do
	runScenario(stage)
	print("[PetKingdoms Test] PASS: recovery retry after " .. stage .. " commit")
end

-- A delivered record must resume at the acknowledgement phase without granting XP again.
local resumeState = { source = false, pet = false, final = false, grantCalls = 0 }
local resumeHandlers = {
	getThresholds = function() return { 100 }, "CONFIGURED" end,
	grantExperience = function() resumeState.grantCalls += 1; return false, "MUST_NOT_RUN" end,
	commitDelivery = function() return false, "MUST_NOT_RUN" end,
	commitSourceAcknowledgement = function() resumeState.source = true; return true, "DURABLE" end,
	acknowledgePetReceipt = function() resumeState.pet = true; return true, "ACKNOWLEDGED" end,
	commitPetAcknowledgement = function() resumeState.final = true; return true, "DURABLE" end,
}
local resumed, resumeStatus = Protocol.finalizeDelivered(record, resumeHandlers)
assert(resumed, "delivered-record recovery failed: " .. resumeStatus)
assert(resumeState.grantCalls == 0 and resumeState.source and resumeState.pet and resumeState.final,
	"delivered-record recovery repeated XP grant or missed a finalization phase")

-- A missing receipt is acceptable only after the durable source acknowledgement.
local missingReceiptAccepted = Protocol.finalizeDelivered(record, {
	commitSourceAcknowledgement = function() return true, "ALREADY_ACKNOWLEDGED" end,
	acknowledgePetReceipt = function() return false, "RECEIPT_NOT_FOUND" end,
	commitPetAcknowledgement = function() return true, "DURABLE" end,
})
assert(missingReceiptAccepted, "missing pet receipt after durable source acknowledgement must finalize")

local missingReceiptRejected = Protocol.finalizeDelivered(record, {
	commitSourceAcknowledgement = function() return false, "DATASTORE_UNAVAILABLE" end,
	acknowledgePetReceipt = function() error("pet receipt must not be touched before source acknowledgement") end,
	commitPetAcknowledgement = function() return true, "DURABLE" end,
})
assert(not missingReceiptRejected, "source acknowledgement failure must stop finalization")

print("[PetKingdoms Test] QuestRewardRecoveryProtocol fault-injection tests completed.")
