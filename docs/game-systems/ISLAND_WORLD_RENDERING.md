# Personal Island World Rendering

> Status: procedural blockout renderer is committed and connected to player profile sessions. It is not production art and has not been verified in Roblox Studio.

## Required Workspace configuration

- `IslandGridWidth`: logical grid width, also used by the profile schema.
- `IslandGridDepth`: logical grid depth, also used by the profile schema.
- `IslandGridCellSize`: world studs per logical grid cell; must be a positive number.
- `IslandSpawnPoints`: Folder containing anchored BaseParts. Each BasePart CFrame is the center/top reference for one island slot. The number of spawn points limits simultaneous personal islands per server.

No dimensions, world positions, or cell size are hard-coded as game design defaults. The world renderer fails closed if required configuration or a free spawn point is missing.

## Generated blockout

- Rectangular grass top and dirt/stone island layers.
- Rock clusters below the island edge.
- Small perimeter trees and a stone arrival pad.
- Each world is parented under `Workspace/PlayerIslands/Island_<UserId>`.
- Spawn points are reserved per server and released when the world is removed.

All generated geometry is temporary blockout built from Parts. It is not the final hand-crafted art direction and must be replaced or upgraded with original meshes and curated assets before release.

## Building model integration

Place production or approved prototype Models in `ServerStorage/BuildingModels`, with each model named exactly after its server catalog ID (for example `main_house`, `pet_house`). The renderer clones only Models matching persisted building records. If a template is missing, the saved record is preserved and a warning is logged; the rest of the island still loads.

Model pivots must be authored at the ground-level origin of the building footprint. Grid coordinates are converted to world coordinates using the configured cell size and profile bounds, then the saved 90-degree rotation is applied.

## Lifecycle

- After profile load and DataStore session claim, the session service requests a world spawn.
- If world creation fails, the player is not admitted into a session and the MemoryStore lease is released.
- On lease loss or successful player removal, the world is destroyed and its spawn slot released.
- The renderer exposes a safe arrival CFrame above the arrival pad. The session service moves the current character there and repeats the move on respawn.
- The default Roblox camera remains in use; no custom camera controller is implemented.
- Building placement/mutation is not implemented.

## Verification

`IslandWorldServiceTests.server.lua` checks invalid-profile rejection and fail-closed behavior when cell-size configuration is absent. Run it in Roblox Studio. Also verify two simultaneous players receive different spawn points, characters arrive above the pad after initial spawn and respawn, profile buildings clone at expected pivots, missing templates preserve profile data, and player removal releases slots.
