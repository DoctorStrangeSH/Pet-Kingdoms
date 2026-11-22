--!strict
-- Pure orchestration for the durable cross-DataStore quest XP handshake.
-- All handlers are trusted server callbacks; this module owns ordering only.
local QuestRewardRecoveryProtocol = {}

export type Handlers = {
	getThresholds: (number) -> ({ number }?, string),
	grantExperience: (string, string, number, { number }) -> (boolean, string),
	commitDelivery: (string) -> (boolean, string),
	commitSourceAcknowledgement: (string) -> (boolean, string),
	acknowledgePetReceipt: (string) -> (boolean, string),
	commitPetAcknowledgement: (string) -> (boolean, string),
}

local function finalizeDelivered(record: any, handlers: Handlers): (boolean, string)
	local sourceOk, sourceStatus = handlers.commitSourceAcknowledgement(record.rewardId)
	if not sourceOk then return false, "SOURCE_ACK_FAILED:" .. sourceStatus end

	local petOk, petStatus = handlers.acknowledgePetReceipt(record.rewardId)
	-- The source marker is durable before the pet receipt retention clock starts.
	-- A missing receipt is safe only after that marker proves the XP write succeeded.
	if not petOk and petStatus ~= "RECEIPT_NOT_FOUND" then
		return false, "PET_RECEIPT_ACK_FAILED:" .. petStatus
	end

	local finalOk, finalStatus = handlers.commitPetAcknowledgement(record.rewardId)
	if not finalOk then return false, "PET_ACK_MARKER_FAILED:" .. finalStatus end
	return true, finalStatus
end

function QuestRewardRecoveryProtocol.deliverPending(record: any, handlers: Handlers): (boolean, string)
	local thresholds, configStatus = handlers.getThresholds(record.progressionVersion)
	if thresholds == nil then return false, configStatus end

	local grantOk, grantStatus = handlers.grantExperience(
		record.petId,
		record.rewardId,
		record.amount,
		thresholds
	)
	if not grantOk then return false, "PET_XP_GRANT_FAILED:" .. grantStatus end

	local deliveryOk, deliveryStatus = handlers.commitDelivery(record.rewardId)
	if not deliveryOk then return false, "SOURCE_DELIVERY_COMMIT_FAILED:" .. deliveryStatus end

	return finalizeDelivered(record, handlers)
end

function QuestRewardRecoveryProtocol.finalizeDelivered(record: any, handlers: Handlers): (boolean, string)
	return finalizeDelivered(record, handlers)
end

return QuestRewardRecoveryProtocol
