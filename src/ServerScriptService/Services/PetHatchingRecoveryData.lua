--!strict
-- Pure recovery decision table for persisted hatch transactions.
local PetHatchingRecoveryData = {}

function PetHatchingRecoveryData.getNextAction(record: any): (string?, string)
	if type(record) ~= "table" then return nil, "INVALID_TRANSACTION" end
	if record.state == "PREPARED" then return "CHARGE", "RECOVER_PREPARED" end
	if record.state == "CHARGED" then return "GRANT", "RECOVER_CHARGED" end
	if record.state == "GRANTED" then return "COMPLETE", "ALREADY_GRANTED" end
	return nil, "INVALID_STATE"
end

return PetHatchingRecoveryData
