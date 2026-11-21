# Pet Kingdoms — Roadmap

> Rule: deliver the approved MVP in order. No scope expansion before 1.0. A task is DONE only when the implementation is in this repository and its relevant verification has passed.

## Stage 0 — Repository foundation

- [x] Create project README and central specification.
- [x] Create a single source-of-truth roadmap.
- [x] Confirm the intended Roblox development workflow: hybrid Rojo + VS Code + Roblox Studio.
- [x] Add the initial Rojo project mapping and source folder structure.
- [x] Add server and client bootstrap entrypoints.
- [x] Document the local build/live-sync workflow.
- [ ] Run a real Rojo build and record the result.
- [ ] Add CI checks appropriate to the chosen workflow.

## Stage 1 — Pet Art Pipeline

- [x] Document the visual style guide and technical asset standards in ART_BIBLE.md.
- [ ] Review and formally approve the art bible against the full original specification.
- [ ] Create the first original pet model and animation pipeline.
  - [x] Commit Bunny procedural rig factory v1 and its Studio smoke test (execution pending).
  - [x] Add procedural Bunny state-pose controller for idle, walk, run, happy, curious, alert, and combat; Studio animation smoke test committed (execution pending).
  - [x] Add a client-side companion follow controller with three formation slots, ground raycast, smooth facing/follow, and idle/walk/run state selection (Studio test committed; execution pending).
  - [x] Add a server-authoritative pet collection DataStore profile with starter Bunny, ownership validation, max-three equip validation, and revision-checked equip writes (Studio DataStore verification pending).
  - [x] Add pure collection data tests for ownership, invalid species, duplicate/sparse equip lists, and the three-pet limit (Studio execution pending).
  - [ ] Add client inventory/equip UI and connect equipped IDs to replicated pet world spawns and the follow controller.
- [ ] Validate scale, silhouette, materials, rig, animation, and mobile performance.
- [ ] Produce a reusable template for all 20 MVP pets.

## Stage 2 — Green Valley

- [ ] Build the Meadow.
- [ ] Build Deep Forest.
- [ ] Build Crystal Creek.
- [ ] Build Ancient Grove.
- [ ] Build Wildflower Hills.
- [ ] Add gathering nodes, wild-pet encounters, and taming opportunities.
- [ ] Validate navigation, readability, performance, and exploration flow.

## Stage 3 — Starter Island, building, and Kingdom Bond

- [x] Document the MVP building-system design and server-authority requirements.

- [ ] Implement persistent personal home islands.
- [ ] Verify procedural personal island world rendering and character arrival in Roblox Studio (renderer, spawn routing, and session integration are committed; required Workspace setup and visual checks remain).
- [x] Add versioned island profile schema and validation helpers (Studio tests committed; execution pending).
- [ ] Implement shared Sun Grove and Moon Grove connections.
- [ ] Implement bridge repair and guest permissions.
- [ ] Implement island expansion and validated building placement.
- [x] Add first client construction controller for main_house (grid preview, rotate, confirm/cancel; Studio verification pending).
- [x] Add runtime fallback blockout Models for main_house and pet_house so placement can be exercised without imported production assets (Studio verification pending).
- [x] Add a minimal client catalogue for main_house and pet_house, wired to server-authoritative placement (Studio/device verification pending).
- [x] Add server-authoritative demolition for non-main-house buildings, with client selection and explicit second-press confirmation (Studio verification pending).
- [x] Add client move mode for selected buildings using existing server-authoritative move transaction and stable instance IDs (Studio/device verification pending).
- [x] Add client-side occupied-footprint preview feedback for placement/move; server remains authoritative (Studio verification pending).
- [x] Add initial decor catalogue entries for stone_path and garden_lantern with saved placement, move, and demolition support (Studio verification pending).
- [x] Expand the starter decor catalogue with flower_bed and wooden_fence blockout models, selection cards, and the shared placement/move/demolition flow (Studio verification pending).
- [ ] Complete server-side placement validation (catalog and validator are committed; Studio smoke tests remain unrun).
- [x] Add Studio smoke-test coverage for placement validation and grid math (scripts committed; execution pending).
- [x] Add server-authoritative placement/move transaction endpoint with idempotency and world/profile rollback (Studio integration verification pending).
- [ ] Add server transaction handling for resource charging (economy values remain unapproved).
- [ ] Complete persistent personal home islands (profile lifecycle and MemoryStore lease code are committed; world spawning and Studio verification remain).
- [x] Add cross-server MemoryStore coordination lease with acquire, renewal, release, and fail-closed handling (Studio verification pending; DataStore fencing is implemented separately).
- [x] Add DataStore-side fencing/session generation checked atomically inside every profile UpdateAsync write, using compare-and-swap claims to reject delayed loaders (Studio integration test committed; execution pending).
- [x] Add MemoryStore lease integration smoke coverage for ownership, stale tokens, release, and reacquisition (execution pending).
- [x] Harden profile validation against unknown building unlock IDs.
- [x] Reject non-numeric lease owner IDs before MemoryStore calls.
- [x] Validate persisted building arrays as contiguous and bounded (256 records maximum); reject dictionary/sparse entries.
- [x] Serialize per-player saves and wait for in-flight autosaves before releasing a leaving player's session (code committed; Studio verification pending).
- [x] Deep-copy island profile snapshots before yielding DataStore writes.
- [x] Correctly detect UpdateAsync rejected writes (the transform returns the current value; Studio verification pending).
- [x] Add server PlayerAdded/PlayerRemoving/autosave/BindToClose profile lifecycle code (Studio/live DataStore verification pending).
- [ ] Implement Kingdom Bond progression and visual island changes.
- [ ] Make farming and production meaningfully contribute to progression.

## Stage 4 — Pet Collection

- [ ] Deliver the 20-pet MVP collection.
- [ ] Implement pet inventory and collection UI.
- [ ] Implement up to 3 active companions and team management.
- [ ] Implement companion states and mobile-safe movement.
- [ ] Implement pet levels, XP, stats, skills, equipment, and Bond.
- [ ] Verify all six rarity tiers can reach level 50.

## Stage 5 — Core Gameplay

- [ ] Implement the approved combat loop.
- [ ] Implement quests and rewards.
- [ ] Implement exploration interactions and pet abilities.
- [ ] Implement Gold, Gems, biome resources, shops, and balanced upgrade costs.
- [ ] Verify free progression is complete and optional purchases are non-pay-to-win.

## Stage 6 — 1.0 Release Gate

- [ ] End-to-end playthrough from new player to MVP completion.
- [ ] Save/load, reconnect, duplicate reward, and failure-recovery tests.
- [ ] Server-authority and exploit-resistance review.
- [ ] Roblox Studio visual/physics checks.
- [ ] PC and mobile usability/performance checks.
- [ ] Fix all release-blocking bugs; freeze scope for 1.0.

## Current status

The repository now contains the documentation baseline, Rojo mapping, grid math, server/client bootstraps, a server-owned starter building catalog, a pure placement validator, versioned island profile creation/validation helpers, a revision-aware DataStore adapter with bounded retries, and Studio-only smoke-test scripts for placement, grid math, island profiles, store input contracts, and the first Bunny rig factory. These scripts are committed but have not been executed in Roblox Studio. DataStore adapter code is committed but has not been tested against a live Roblox DataStore. The server profile lifecycle is now wired into Bootstrap, but it has not been executed in Roblox Studio or tested against live DataStores. A procedural personal-island blockout renderer is now committed and called after profile session claim. It requires configured Workspace grid attributes and `IslandSpawnPoints`; building Models are optional templates under ServerStorage. This is prototype geometry, not production art, and has not been verified in Studio. Character routing to the island arrival pad is now implemented for initial spawn and respawn. A server RemoteFunction now validates place/move requests, creates server-generated building IDs, synchronizes approved Models, updates the active profile, and deduplicates recent request IDs; Studio integration verification is pending. A first client construction controller is now committed for `main_house`: it renders a local translucent grid-footprint preview, supports rotate/confirm/cancel on desktop and touch, and calls the authoritative server RemoteFunction. The server publishes island grid metadata for this preview. Studio/device verification is pending. A minimal two-entry client catalogue now selects `main_house` or `pet_house` and sends the selected stable ID to the server. Resource charging, full catalogue art/filtering, custom building art, custom camera, upgrade UX, and production assets are not implemented. The starter catalogue now includes four 1×1 decor blockouts: stone path, garden lantern, flower bed, and wooden fence section. All use the same validated placement, move, save, and demolition flow. The next MVP stage, Pet Art Pipeline, has started with a procedural Bunny rig factory (17 Motor6D joints, AnimationController/Animator, follow/ground attachments) and a Studio smoke test; both implementation and test are committed, but Studio execution and visual approval are pending. They are blockouts, not production art; Studio verification is pending. Client move mode now selects a building on the local island, previews a new grid position, checks bounds and replicated building footprints for immediate overlap feedback, and submits the existing instance ID to the server transaction; Studio/device verification is pending. A first demolition flow now selects buildings on the local island, requires a second confirmation press, protects the main house server-side, and rolls profile/world state back if the session cannot be marked writable; Studio verification is pending. Runtime fallback blockout Models now allow `main_house` and `pet_house` placement without imported templates; they are explicitly temporary and not production art. Cross-server MemoryStore coordination lease code is wired into profile lifecycle. Integration smoke coverage exercises ownership, stale-token rejection, release, and reacquisition, but it has not been executed in Studio or under multi-server load. DataStore-side fencing is now implemented: a monotonic sessionGeneration is claimed atomically in the profile key, and every save checks it inside the same UpdateAsync transform. A Studio integration test covers stale-loader claim rejection, stale-generation save rejection, and current-generation acceptance; it is committed but has not yet been executed against a dedicated test universe. MemoryStore remains the coordination lease. Per-player saves are serialized and final-save failures retain the session in memory until shutdown. UpdateAsync rejection detection was corrected: rejected transforms return the existing value, so the adapter now tracks whether the snapshot was accepted. These fixes are committed but untested in Studio. Profile validation now rejects unlock records that do not map to a current server catalog item, malformed/sparse building arrays, and more than 256 building records; lease input validation also rejects non-numeric user IDs before comparing or constructing keys. New Studio tests are committed but remain unexecuted.
