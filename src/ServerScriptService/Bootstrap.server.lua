--!strict
-- Server startup and player island profile lifecycle.

local Players = game:GetService("Players")
-- Do not spawn characters into an empty default Workspace while profile/DataStore
-- loading is in progress. IslandSessionService loads the character after the island exists.
Players.CharacterAutoLoads = false

local services = script.Parent:WaitForChild("Services")
local IslandWorldConfig = require(services:WaitForChild("IslandWorldConfig"))
local IslandSessionService = require(services:WaitForChild("IslandSessionService"))
local IslandBuildingService = require(services:WaitForChild("IslandBuildingService"))
local PetCollectionService = require(services:WaitForChild("PetCollectionService"))
local IslandGatheringService = require(services:WaitForChild("IslandGatheringService"))
local PetHatchingRecoveryService = require(services:WaitForChild("PetHatchingRecoveryService"))

local worldConfigured, worldConfigCode = IslandWorldConfig.configure()
if not worldConfigured then
	error("[PetKingdoms] World configuration failed: " .. worldConfigCode)
end

IslandSessionService.start()
IslandBuildingService.start()
PetCollectionService.start()
IslandGatheringService.start()
PetHatchingRecoveryService.start()

print("[PetKingdoms] Server bootstrap loaded.")
