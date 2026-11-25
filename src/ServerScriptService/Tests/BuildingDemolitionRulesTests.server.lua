--!strict
-- Studio-only tests for server-side building demolition authorization.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local Rules = require(services:WaitForChild("BuildingDemolitionRules"))
local Catalog = require(services:WaitForChild("BuildingCatalog"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local mainHouse = { instanceId = "main-house-001", catalogId = "main_house" }
local allowedMain, mainCode = Rules.validate(mainHouse, Catalog)
expect("main house is always protected", not allowedMain and mainCode == "MAIN_HOUSE_PROTECTED")

local petHouse = { instanceId = "pet-house-001", catalogId = "pet_house" }
local allowedPet, petCode = Rules.validate(petHouse, Catalog)
expect("ordinary pet house can be demolished", allowedPet and petCode == "DEMOLITION_ALLOWED")

local pathRecord = { instanceId = "stone-path-001", catalogId = "stone_path" }
local allowedPath, pathCode = Rules.validate(pathRecord, Catalog)
expect("ordinary path can be demolished", allowedPath and pathCode == "DEMOLITION_ALLOWED")

local missingId, missingIdCode = Rules.validate({ catalogId = "pet_house" }, Catalog)
expect("record without instance ID is rejected", not missingId and missingIdCode == "INVALID_BUILDING_RECORD")

local emptyId, emptyIdCode = Rules.validate({ instanceId = "", catalogId = "pet_house" }, Catalog)
expect("empty instance ID is rejected", not emptyId and emptyIdCode == "INVALID_BUILDING_RECORD")

local unknown, unknownCode = Rules.validate({ instanceId = "unknown-001", catalogId = "admin_spawn" }, Catalog)
expect("unknown catalog entry cannot be demolished", not unknown and unknownCode == "UNKNOWN_BUILDING")

local malformed, malformedCode = Rules.validate("pet_house", Catalog)
expect("malformed record is rejected", not malformed and malformedCode == "INVALID_BUILDING_RECORD")

print("[PetKingdoms Test] BuildingDemolitionRules tests completed.")
