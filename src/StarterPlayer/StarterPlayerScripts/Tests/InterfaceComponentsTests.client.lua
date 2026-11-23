--!strict
-- Studio client smoke tests. Run in a dedicated test place with the test attribute enabled.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("RunPetKingdomsStudioTests") ~= true then
	return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InterfaceComponents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InterfaceComponents"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local testGui = Instance.new("ScreenGui")
testGui.Name = "InterfaceComponentsTests"
testGui.ResetOnSpawn = false
testGui.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "FeedbackTestButton"
button.Text = "ORIGINAL"
button.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
button.TextColor3 = Color3.fromRGB(240, 240, 240)
button.Parent = testGui

local originalBackground = button.BackgroundColor3
local originalTextColor = button.TextColor3

InterfaceComponents.SetButtonFeedback(button, "success", "ГОТОВО", 0.5)
expect("valid feedback applies state", button.Text == "ГОТОВО" and button:GetAttribute("PKFeedbackActive") == true)

local activeToken = button:GetAttribute("PKFeedbackToken")
InterfaceComponents.SetButtonFeedback(button, "unsupported", "НЕ ДОЛЖНО ПОЯВИТЬСЯ", 0.5)
expect("invalid feedback leaves active timer token intact", button:GetAttribute("PKFeedbackToken") == activeToken)
expect("invalid feedback does not overwrite active message", button.Text == "ГОТОВО")

task.wait(0.7)
expect("valid feedback restores original text", button.Text == "ORIGINAL")
expect("valid feedback restores original colors", button.BackgroundColor3 == originalBackground and button.TextColor3 == originalTextColor)
expect("feedback timer clears active state", button:GetAttribute("PKFeedbackActive") == false)

testGui:Destroy()
print("[PetKingdoms Test] InterfaceComponents smoke tests completed.")
