--!strict
-- Server startup and player island profile lifecycle.

local services = script.Parent:WaitForChild("Services")
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local IslandBuildingService = require(services:WaitForChild("IslandBuildingService"))
local PetCollectionService = require(services:WaitForChild("PetCollectionService"))
local IslandGatheringService = require(services:WaitForChild("IslandGatheringService"))

IslandSessionService.start()
IslandBuildingService.start()
PetCollectionService.start()
IslandGatheringService.start()

print("[PetKingdoms] Server bootstrap loaded.")
