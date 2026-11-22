--!strict
-- Studio-only pure tests for the layout-derived Kingdom Bond progression.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local KingdomBond = require(services:WaitForChild("KingdomBond"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local empty = KingdomBond.calculate({ buildings = {} })
expect("empty island starts at quiet stage", empty.points == 0 and empty.stageId == "quiet")
expect("empty island has no development building count", empty.buildingCount == 0)
expect("empty island has no total building count", empty.totalBuildingCount == 0)

local one = KingdomBond.calculate({ buildings = {
	{ catalogId = "main_house" },
	{ catalogId = "pet_house" },
} })
expect("main house does not grant development points", one.points == 10 and one.buildingCount == 1)
expect("total building count includes the Main House", one.totalBuildingCount == 2)
expect("first improvement unlocks cozy stage", one.stageId == "cozy" and one.stageName == "Уютное королевство")
expect("next threshold is exposed", one.nextStagePoints == 30)

local three = KingdomBond.calculate({ buildings = {
	{ catalogId = "main_house" },
	{ catalogId = "pet_house" },
	{ catalogId = "stone_path" },
	{ catalogId = "flower_bed" },
} })
expect("three improvements unlock blooming stage", three.points == 30 and three.stageId == "blooming")

local six = KingdomBond.calculate({ buildings = {
	{ catalogId = "pet_house" }, { catalogId = "stone_path" }, { catalogId = "flower_bed" },
	{ catalogId = "wooden_fence" }, { catalogId = "garden_lantern" }, { catalogId = "pet_house" },
} })
expect("five distinct improvements unlock thriving stage", six.points == 50 and six.stageId == "thriving")
expect("duplicate building type does not farm Bond", six.uniqueBuildingTypes == 5 and six.buildingCount == 6)
expect("total count includes every placed building", six.totalBuildingCount == 6)
expect("maximum stage has no next threshold", six.nextStagePoints == nil)

expect("invalid profile is rejected", KingdomBond.calculate(nil) == nil)
print("[PetKingdoms Test] KingdomBond smoke tests completed.")
