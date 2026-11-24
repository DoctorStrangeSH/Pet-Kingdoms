--!strict
-- Server-owned catalog. Client input must only ever reference these stable IDs.
-- MVP prices below are provisional balancing values; keep them server-owned.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildingFootprints = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Building"):WaitForChild("BuildingFootprints"))

export type BuildingDefinition = {
	id: string,
	footprintWidth: number,
	footprintDepth: number,
	allowedRotations: { [number]: boolean },
	defaultUnlocked: boolean,
	cost: { [string]: number }?,
	maxUpgradeLevel: number?,
	upgradeCosts: { [number]: { [string]: number } }?,
}

local Catalog: { [string]: BuildingDefinition } = {
	main_house = {
		id = "main_house",
		maxUpgradeLevel = 3,
		upgradeCosts = {
			[2] = { wood = 12, stone = 6 },
			[3] = { wood = 24, stone = 14 },
		},
		footprintWidth = BuildingFootprints.main_house.width,
		footprintDepth = BuildingFootprints.main_house.depth,
		allowedRotations = {
			[0] = true,
			[90] = true,
			[180] = true,
			[270] = true,
		},
		defaultUnlocked = true,
	},
	pet_house = {
		id = "pet_house",
		maxUpgradeLevel = 3,
		upgradeCosts = {
			[2] = { wood = 10, stone = 5 },
			[3] = { wood = 20, stone = 12 },
		},
		footprintWidth = BuildingFootprints.pet_house.width,
		footprintDepth = BuildingFootprints.pet_house.depth,
		allowedRotations = {
			[0] = true,
			[90] = true,
			[180] = true,
			[270] = true,
		},
		defaultUnlocked = true,
		cost = { wood = 5, stone = 2 },
	},
	stone_path = {
		id = "stone_path",
		maxUpgradeLevel = 2,
		upgradeCosts = { [2] = { stone = 3 } },
		footprintWidth = BuildingFootprints.stone_path.width,
		footprintDepth = BuildingFootprints.stone_path.depth,
		allowedRotations = {
			[0] = true,
			[90] = true,
			[180] = true,
			[270] = true,
		},
		defaultUnlocked = true,
		cost = { wood = 1, stone = 1 },
	},
	garden_lantern = {
		id = "garden_lantern",
		maxUpgradeLevel = 2,
		upgradeCosts = { [2] = { wood = 4, stone = 2 } },
		footprintWidth = BuildingFootprints.garden_lantern.width,
		footprintDepth = BuildingFootprints.garden_lantern.depth,
		allowedRotations = {
			[0] = true,
			[90] = true,
			[180] = true,
			[270] = true,
		},
		defaultUnlocked = true,
		cost = { wood = 2, stone = 1 },
	},
	flower_bed = {
		id = "flower_bed",
		maxUpgradeLevel = 2,
		upgradeCosts = { [2] = { wood = 3 } },
		footprintWidth = BuildingFootprints.flower_bed.width,
		footprintDepth = BuildingFootprints.flower_bed.depth,
		allowedRotations = {
			[0] = true,
			[90] = true,
			[180] = true,
			[270] = true,
		},
		defaultUnlocked = true,
		cost = { wood = 1 },
	},
	wooden_fence = {
		id = "wooden_fence",
		maxUpgradeLevel = 2,
		upgradeCosts = { [2] = { wood = 3 } },
		footprintWidth = BuildingFootprints.wooden_fence.width,
		footprintDepth = BuildingFootprints.wooden_fence.depth,
		allowedRotations = {
			[0] = true,
			[90] = true,
			[180] = true,
			[270] = true,
		},
		defaultUnlocked = true,
		cost = { wood = 1 },
	},
}

return Catalog
