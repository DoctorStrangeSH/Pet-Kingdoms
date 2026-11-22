--!strict
-- Canonical server-owned resource nodes for every personal island.

local IslandResourceNodeCatalog = {}

IslandResourceNodeCatalog.RESPAWN_SECONDS = 60

local definitions = {
	{ id = "WoodNode_A", resourceId = "wood", reward = 3, sideX = -1, sideZ = -1 },
	{ id = "WoodNode_B", resourceId = "wood", reward = 3, sideX = 1, sideZ = -1 },
	{ id = "StoneNode_A", resourceId = "stone", reward = 2, sideX = -1, sideZ = 1 },
	{ id = "StoneNode_B", resourceId = "stone", reward = 2, sideX = 1, sideZ = 1 },
}

local byId = {}
for _, definition in ipairs(definitions) do
	byId[definition.id] = table.freeze(definition)
end

function IslandResourceNodeCatalog.get(nodeId: string): any?
	return byId[nodeId]
end

function IslandResourceNodeCatalog.getAll(): { any }
	return definitions
end

return table.freeze(IslandResourceNodeCatalog)
