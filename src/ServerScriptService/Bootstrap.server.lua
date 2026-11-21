--!strict
-- Server startup and player island profile lifecycle.

local services = script.Parent:WaitForChild("Services")
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))

IslandSessionService.start()

print("[PetKingdoms] Server bootstrap loaded.")
