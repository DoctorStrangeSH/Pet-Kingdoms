--!strict
-- Server-owned catalog. Client input must only ever reference these stable IDs.
-- MVP prices below are provisional balancing values; keep them server-owned.

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
		footprintWidth = 3,
		footprintDepth = 3,
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
		footprintWidth = 3,
		footprintDepth = 3,
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
		footprintWidth = 1,
		footprintDepth = 1,
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
		footprintWidth = 1,
		footprintDepth = 1,
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
		footprintWidth = 1,
		footprintDepth = 1,
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
		footprintWidth = 1,
		footprintDepth = 1,
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
