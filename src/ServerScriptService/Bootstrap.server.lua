--!strict
-- Server startup and player island profile lifecycle.

local services = script.Parent:WaitForChild("Services")
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local IslandBuildingService = require(services:WaitForChild("IslandBuildingService"))

IslandSessionService.start()
IslandBuildingService.start()

print("[PetKingdoms] Server bootstrap loaded.")
