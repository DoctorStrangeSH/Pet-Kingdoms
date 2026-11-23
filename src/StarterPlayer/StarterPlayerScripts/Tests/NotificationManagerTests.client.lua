--!strict
-- Studio client smoke tests. Run in a dedicated test place with the test attribute enabled.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("RunPetKingdomsStudioTests") ~= true then
	return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local NotificationManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NotificationManager"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local screen = playerGui:WaitForChild("PetKingdomsNotifications")
local holder = screen:WaitForChild("ToastStack")

local function countToasts(): number
	local count = 0
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("Frame") and string.sub(child.Name, 1, 5) == "Toast" then
			count += 1
		end
	end
	return count
end

for index = 1, 5 do
	NotificationManager.Notify("Проверка очереди уведомлений " .. tostring(index), "info", 1.5)
end
expect("toast stack respects the four-item desktop cap", countToasts() <= 4)

task.wait(2)
expect("expired and evicted toasts are removed", countToasts() == 0)

for index = 1, 4 do
	NotificationManager.Notify("Повторная проверка " .. tostring(index), "success", 1.5)
end
expect("new notifications can fill the stack after expiry", countToasts() == 4)

task.wait(2)
expect("second notification batch cleans up", countToasts() == 0)

-- A burst larger than the queue cap must evict old cards without allowing
-- expired timers from evicted cards to decrement slots owned by newer cards.
for index = 1, 25 do
	NotificationManager.Notify("Пакетное уведомление " .. tostring(index), if index % 2 == 0 then "warning" else "info", 1.5)
end
expect("rapid notification burst stays within desktop cap", countToasts() <= 4)
local newestToastRetained = false
for _, child in ipairs(holder:GetChildren()) do
	local message = child:FindFirstChild("Message")
	if message and message:IsA("TextLabel") and message.Text == "Пакетное уведомление 25" then
		newestToastRetained = true
		break
	end
end
expect("rapid notification burst retains newest items", newestToastRetained)
task.wait(2)
expect("evicted notification timers do not leak active toasts", countToasts() == 0)

print("[PetKingdoms Test] NotificationManager smoke tests completed.")
