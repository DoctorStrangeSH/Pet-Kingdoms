# Build and Test Workflow

## Toolchain

- Roblox Studio
- Rojo 7.x
- VS Code or another Luau-capable editor
- Git

## Build

From the repository root:

```bash
rojo build default.project.json -o build/PetKingdoms.rbxlx
```

The output directory may need to be created first.

## Live sync

```bash
rojo serve default.project.json
```

Connect to the running Rojo server with the Rojo Studio plugin.

## Current source checks

The first pure utility module is:
- `src/ReplicatedStorage/Shared/Building/GridMath.lua`

Before integrating it into placement gameplay, verify these cases:
- Grid snapping at exact cell centers and halfway boundaries.
- Invalid grid size returns nil.
- Footprints rotate correctly at 0, 90, 180, and 270 degrees.
- Unsupported rotation angles are rejected.
- A footprint exactly on the island boundary is accepted.
- A footprint extending one cell beyond the island is rejected.
- Adjacent footprints do not overlap.
- Footprints sharing any positive-area region do overlap.

## Verification honesty

A successful Rojo build proves the project tree can be serialized; it does not prove the game works in Roblox Studio. Physics, UI, DataStores, replication, mobile controls, and visual quality require Studio playtests. Do not mark those tasks DONE until tested there.
