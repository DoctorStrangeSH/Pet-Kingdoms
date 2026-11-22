--!strict
-- Studio-only tests for the hatch recovery decision table.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local RecoveryData = require(script.Parent.Parent.Services:WaitForChild("PetHatchingRecoveryData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local chargeAction, chargeStatus = RecoveryData.getNextAction({ state = "PREPARED" })
expect("prepared transaction resumes at charge", chargeAction == "CHARGE" and chargeStatus == "RECOVER_PREPARED")

local grantAction, grantStatus = RecoveryData.getNextAction({ state = "CHARGED" })
expect("charged transaction resumes at pet grant", grantAction == "GRANT" and grantStatus == "RECOVER_CHARGED")

local completeAction, completeStatus = RecoveryData.getNextAction({ state = "GRANTED" })
expect("granted transaction is already complete", completeAction == "COMPLETE" and completeStatus == "ALREADY_GRANTED")

local invalidAction, invalidStatus = RecoveryData.getNextAction({ state = "REFUNDED" })
expect("unknown transaction state fails closed", invalidAction == nil and invalidStatus == "INVALID_STATE")

local nilAction, nilStatus = RecoveryData.getNextAction(nil)
expect("missing transaction fails closed", nilAction == nil and nilStatus == "INVALID_TRANSACTION")

expect("hatch recovery readiness window exceeds collection lease wait",
	RecoveryData.hasSufficientReadinessWindow()
		and RecoveryData.RECOVERY_READY_TIMEOUT_SECONDS > RecoveryData.COLLECTION_READY_TIMEOUT_SECONDS)

print("[PetKingdoms Test] PetHatchingRecoveryData tests completed.")
