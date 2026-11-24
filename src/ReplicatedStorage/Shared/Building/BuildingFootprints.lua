--!strict
-- Canonical grid footprints shared by client preview and server validation.
-- Keep only base (unrotated) dimensions here; GridMath applies rotation.
export type FootprintSize = {
	width: number,
	depth: number,
}

local Footprints: { [string]: FootprintSize } = {
	main_house = { width = 3, depth = 3 },
	pet_house = { width = 3, depth = 3 },
	stone_path = { width = 1, depth = 1 },
	garden_lantern = { width = 1, depth = 1 },
	flower_bed = { width = 1, depth = 1 },
	wooden_fence = { width = 1, depth = 1 },
}

return Footprints
