# Build and Test Workflow

## Toolchain

- Roblox Studio
- [Rokit](https://github.com/rojo-rbx/rokit)
- Rojo version pinned in `rokit.toml`
- VS Code or another Luau-capable editor
- Git

Install the pinned tools from the repository root:

```bash
rokit install
```

Do not use a different Rojo version for this repository unless the pin is deliberately updated and verified.

## Build

From the repository root:

```bash
mkdir -p build
rojo build default.project.json --output build/PetKingdoms.rbxlx
```

Open `build/PetKingdoms.rbxlx` in Roblox Studio.

## Live sync

From the repository root:

```bash
rojo serve default.project.json
```

Connect to the running Rojo server with the matching Rojo 7 Studio plugin. Keep the CLI and Studio plugin on the same major version.

## Automated build

GitHub Actions runs the full Rojo build on changes to `src/**`, `default.project.json`, `rokit.toml`, and the build workflow itself.

A successful run uploads the generated `PetKingdoms.rbxlx` as the `pet-kingdoms-studio-build` artifact for 14 days:

1. Open the repository's Actions tab.
2. Select **Roblox project build**.
3. Open the latest successful run.
4. Download **pet-kingdoms-studio-build** from Artifacts.
5. Extract the ZIP and open `PetKingdoms.rbxlx` in Studio.

The CI build validates that Rojo can serialize the complete repository project tree. It does not execute Roblox scripts or prove runtime behavior.

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

## Opt-in client smoke tests

The client companion-controller smoke test is included in the Studio project, but it must not create test pets during an ordinary play session.

To run it deliberately in a dedicated Studio test place:

1. In Edit mode, open **View → Command Bar**.
2. Run:

   ```lua
   workspace:SetAttribute("RunPetKingdomsStudioTests", true)
   ```

3. Press **Play**. The client smoke test creates three temporary Bunny blockouts under `Workspace/CompanionFollowControllerTests`, runs its assertions, and removes the folder when it completes.
4. Stop the session. In Edit mode, disable the gate:

   ```lua
   workspace:SetAttribute("RunPetKingdomsStudioTests", false)
   ```

Do not enable the gate in a normal development session; it is for isolated test runs only.

## Roblox Studio test checklist

The repository contains Studio-only test scripts under `src/ServerScriptService/Tests` and client test scripts under `src/StarterPlayer/StarterPlayerScripts/Tests`. Run these in a dedicated Studio test place, not against production player data.

For DataStore and MemoryStore scenarios, enable API access only in the dedicated test universe and use test accounts/profiles. Exercise at least:
- First join, save, leave, and rejoin.
- Save failure and retry during leave/shutdown.
- Two-server lease contention and stale-writer rejection.
- Gathering/building/hatching overlap and retry behavior.
- Pet collection load delays, disconnect/rejoin, and acquisition recovery.
- Mobile touch, safe areas, and companion movement.

## Verification honesty

A successful Rojo build proves the project tree can be serialized; it does not prove the game works in Roblox Studio. Physics, UI, DataStores, replication, mobile controls, and visual quality require Studio playtests. Do not mark those tasks DONE until tested there.


## Join and character startup flow

- Server bootstrap disables automatic character spawning. The player is not dropped at the empty default Workspace origin while DataStore/session loading is in progress.
- IslandSessionService acquires the lease, loads/claims the profile, generates the personal island, installs the session, and only then calls `Player:LoadCharacterAsync()`.
- Server publishes `PetKingdomsLoadStatus` and `PetKingdomsLoadMessage` attributes during each phase. `IslandLoading.client.lua` shows a localized loading screen and dismisses it only after the character has been moved to the island arrival point.
- On failure, the player sees a clear failure state before the server kicks them with a localized message.
- This flow must be playtested in Studio with API access enabled in a dedicated test universe; CI only verifies the project builds.


## Character respawn verification

- Because automatic character loading is disabled, manually verify the server-controlled respawn loop in a dedicated Studio test place.
- Kill the player character and confirm exactly one replacement appears after the five-second delay on the current island arrival point.
- Repeat deaths quickly; ensure only one respawn request is pending.
- Leave during the delay; ensure no delayed LoadCharacterAsync occurs after the session closes.
- Simulate a lease loss during the delay; ensure the stale session cannot respawn.
- Confirm the loading overlay clears only after the replacement character reaches the island.
