--!strict
-- Studio-only validation for the server-owned construction economy catalog.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local catalog = require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("BuildingCatalog"))
local resources = require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("IslandResources"))
local function check(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

check("starter main house is free", catalog.main_house.cost == nil)
check("pet house has server-defined wood and stone cost", catalog.pet_house.cost.wood == 5 and catalog.pet_house.cost.stone == 2)
check("stone path has both material costs", catalog.stone_path.cost.wood == 1 and catalog.stone_path.cost.stone == 1)
check("lantern has both material costs", catalog.garden_lantern.cost.wood == 2 and catalog.garden_lantern.cost.stone == 1)
check("flower bed uses wood", catalog.flower_bed.cost.wood == 1)
check("wooden fence uses wood", catalog.wooden_fence.cost.wood == 1)

for buildingId, definition in pairs(catalog) do
	check(buildingId .. " catalog key matches stable ID", definition.id == buildingId)
	if definition.cost then
		local valid, code = resources.validate(definition.cost)
		check(buildingId .. " cost uses valid resource IDs and positive integer balances", valid and code == "VALID")
		for _, amount in pairs(definition.cost) do
			check(buildingId .. " cost amount is positive", amount > 0)
		end
	end
end

print("[PetKingdoms Test] BuildingCatalog economy tests completed.")
