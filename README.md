# Pet Kingdoms

A colorful, child-friendly Roblox adventure about collecting, bonding with, and adventuring alongside expressive pets while building and growing a personal kingdom.

## Product direction

- Original, polished stylized-fantasy visuals; prefer custom-created assets over random Toolbox models.
- Clear, welcoming UX that children can understand, with PC and mobile support.
- A persistent, expandable home island connected to shared exploration spaces.
- Pet collection, companionship, progression, exploration, and meaningful kingdom building.
- Ethical monetization: optional purchases must not create pay-to-win progression.

## Project documentation

- [Project specification](docs/PROJECT_SPEC.md) — approved vision, MVP scope, and open decisions.
- [Roadmap](docs/ROADMAP.md) — implementation status and verification gates.
- [AI handoff](docs/AI_HANDOFF.md) — current technical state and next actions.
- [Art bible](docs/ART_BIBLE.md) — visual direction and asset acceptance rules.
- [Build and test](docs/BUILD_AND_TEST.md) — local Rojo workflow and verification guidance.
- [Asset tracker](docs/ASSET_TRACKER.md) — asset pipeline and approval status.

## Development setup

The project uses a hybrid **Rojo + VS Code + Roblox Studio** workflow.

1. Install Roblox Studio and Rojo 7.x.
2. Clone this repository and open its root folder in VS Code.
3. Build the place model:

   ```bash
   rojo build default.project.json -o build/PetKingdoms.rbxlx
   ```

   Create the `build` directory first if it does not exist.
4. For live sync, run:

   ```bash
   rojo serve default.project.json
   ```

5. Connect to the running Rojo server from the Rojo plugin in Roblox Studio.

See [docs/BUILD_AND_TEST.md](docs/BUILD_AND_TEST.md) for the workflow and testing requirements.

## Repository layout

- `src/ReplicatedStorage/Shared` — shared Luau modules for pets and building.
- `src/ServerScriptService` — server bootstrap, authoritative gameplay services, and Studio test scripts.
- `src/StarterPlayer/StarterPlayerScripts` — client UI and companion controllers.
- `assets/pets` — source meshes, rig/export scripts, and pet pipeline documentation.
- `tools/roblox` — Roblox Studio inspection and helper scripts.
- `.github/workflows` — automated pet asset source and Blender pipeline validation.

## Current implementation snapshot

The repository contains an initial playable-systems scaffold, including:

- Server-authoritative pet collection, equip, and companionship Bond interactions.
- A test-only procedural Bunny blockout, animation controller, and follow behavior (not used as the live collection visual).
- Persistent personal-island profile and resource systems.
- Server-authoritative building placement, movement, and demolition prototypes.
- Kingdom Bond island progression and a starter resource HUD.

**Important:** this is not a production-ready game release. Many systems are prototypes awaiting Roblox Studio verification. The Bunny is not approved production art, the Green Valley biome and complete 20-pet collection are not finished, and live DataStore, multiplayer, mobile, and visual acceptance checks remain outstanding. The authoritative status is always [docs/ROADMAP.md](docs/ROADMAP.md).

## Quality rule

A feature is DONE only when its source and relevant tests are committed and the required verification has passed. A committed Studio smoke test is not the same as an executed test. Automated asset-pipeline success does not prove Roblox runtime, physics, UI, persistence, or mobile correctness.
