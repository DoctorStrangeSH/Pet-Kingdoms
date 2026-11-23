--!strict
-- Studio client smoke tests. Run in a dedicated test place with the test attribute enabled.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("RunPetKingdomsStudioTests") ~= true then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestRunner = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RequestRunner"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local successResult = RequestRunner.Invoke(function()
	return { ok = true, value = 42 }
end, 2)
expect("successful request returns value", successResult.ok and type(successResult.value) == "table")
expect("successful request has no error code", successResult.errorCode == nil)

local errorResult = RequestRunner.Invoke(function()
	error("intentional RequestRunner test error")
end, 2)
expect("callback error is captured", not errorResult.ok)
expect("callback error has stable error code", errorResult.errorCode == "REMOTE_ERROR")

local lateCallbackFinished = false
local timeoutResult = RequestRunner.Invoke(function()
	task.wait(2.5)
	lateCallbackFinished = true
	return "late result"
end, 2)
expect("slow request returns timeout", not timeoutResult.ok and timeoutResult.errorCode == "TIMEOUT")
expect("timeout does not expose a partial value", timeoutResult.value == nil)

task.wait(0.7)
expect("late callback can finish without changing timeout result", lateCallbackFinished)
expect("timeout result remains a timeout", not timeoutResult.ok and timeoutResult.errorCode == "TIMEOUT")

print("[PetKingdoms Test] RequestRunner smoke tests completed.")
