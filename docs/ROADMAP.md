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
- [ ] Complete the first original pet model and animation pipeline.
  - [x] Create and commit original Bunny OBJ/MTL mesh source (15,332 vertices, 30,194 triangles, 13 named mesh objects, 9 material groups).
  - [x] Reject and remove the unsuitable third-party Bunny candidate from the runtime catalog.
  - [x] Import the rigged FBX in Studio and collect structural report: 13 MeshParts, 7 Bones (expected 10), 13 Motor6D, 1 AnimationController, 0 Animator, all MeshParts Plastic; owner rejected current appearance and deferred visual polish.
  - [ ] Resolve Roblox import mismatch (7 vs 10 bones), investigate Motor6D conversion and verify actual skin deformation.
  - [ ] Rework materials/textures and visual quality later, as explicitly deferred by owner; do not use this Bunny as approved production art.
  - [ ] Verify imported animation playback in Studio, then publish approved assets and set model/animation IDs.
  - [x] Add reproducible Blender Python rig/export script with 10-bone first-pass rig and Idle/Walk/Hop/Happy actions; Blender 4.2.0 CI build generated and structurally validated `.blend` + `.fbx` outputs.
  - [x] Add GitHub Actions validation for Bunny OBJ/MTL integrity and Blender script Python syntax (source-only run passed).
  - [x] Extend CI to install pinned Blender 4.2.0, execute rig/FBX export, re-import FBX, and verify 10 bones, 13 meshes, and keyed motion for each of the four required unique clips; publish a 30-day artifact (run passed).
  - [x] Run Blender 4.2.0 rig build in CI and generate `.blend` + `.fbx` outputs (both validated and uploaded as a workflow artifact).
  - [ ] Visually review skin weights, silhouette, and all four actions in Blender/Roblox Studio; fix deformations before production approval.
  - [ ] Approve silhouette, materials, scale, and gameplay-camera appearance in Green Valley.
  - [x] Commit Bunny procedural Part-based rig factory v1 and its Studio smoke test (test blockout only; live collection service does not use it).
  - [x] Add first expressive face-detail pass to Bunny (eye catchlights, mouth, forehead tuft, six whiskers) and extend the factory smoke test; still prototype geometry, Studio review pending.
  - [x] Add procedural Bunny state-pose controller for idle, walk, run, happy, curious, sniff, alert, and combat; Studio animation smoke test committed (execution pending).
  - [x] Add autonomous idle personality moments (sniff, curious look, happy hop) with randomized pauses; movement interrupts idle actions. Client smoke coverage committed (Studio execution pending).
  - [x] Add a client-side companion follow controller with three formation slots, ground raycast, smooth facing/follow, and idle/walk/run state selection (Studio test committed; execution pending).
  - [x] Add a server-authoritative pet collection DataStore profile with starter Bunny, ownership validation, max-three equip validation, and revision-checked equip writes (Studio DataStore verification pending).
  - [x] Add pure collection data tests for ownership, invalid species, duplicate/sparse equip lists, and the three-pet limit (Studio execution pending).
  - [x] Add first responsive Russian pet collection UI with search, pet preview, equipped count, and server-backed equip/unequip (Studio/device verification pending).
  - [x] Spawn server-authoritative equipped pet Models under `Workspace/PlayerPets/<UserId>` from validated collection data; refresh on equip and recreate on character respawn (Studio verification pending).
  - [x] Add client runtime binding replicated owned pet models to the three-slot follow controller with cleanup on removal/character lifecycle (Studio verification pending).
  - [x] Add initial server asset loader and collection preview plumbing (asset ID intentionally unset until project-owned mesh is imported/published; loader currently returns `ASSET_NOT_CONFIGURED`).
  - [x] Add original Bunny OBJ/MTL mesh source and reject the unsuitable Creator Store candidate.
  - [ ] Import project-owned Bunny OBJ/MTL in Studio, publish it, set its asset ID, then run mesh smoke test and visually approve scale, orientation, materials, and follow behavior.
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
- [x] Add persistent resource wallet to island profiles (provisional starter: 2 Wood, 1 Stone; Gold/Gems start at 0).
- [x] Add backward-compatible migration for existing schema-v1 profiles without a wallet during session claim.
- [x] Add server-only atomic resource grant/spend API with rollback when a session is not writable.
- [x] Add pure Studio contract tests for resource validation, grants, and atomic spending (execution pending).
- [x] Spawn two Wood and two Stone gathering nodes on each personal island using server-owned reward values.
- [x] Add server-authoritative ProximityPrompt gathering with ownership/distance checks, duplicate-trigger protection, wallet grant, and 60-second node respawn (Studio verification pending).
- [x] Add client resource HUD for Wood/Stone/Gold/Gems with server snapshot bootstrap, authoritative update event, and gathering reward toast (Studio/device verification pending).
- [ ] Add gathering feedback animation and final polished art treatment.
- [ ] Verify HUD safe areas, readability, and touch gathering on phone/tablet in Roblox Studio.
- [ ] Verify multiplayer ownership, prompt interactions, respawn, and persistence in Roblox Studio.
- [ ] Approve and tune the full economy balance sheet; current construction prices are provisional and must be playtested.
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
- [x] Add server-authoritative placement/move/demolition transaction endpoint with idempotency and world/profile rollback (Studio integration verification pending).
  - [x] Add per-player token-bucket rate limiting to the building RemoteFunction (12-request burst, refill 4/sec; Studio spam test pending).
- [x] Add server transaction handling for new placement resource charging from server-owned provisional catalog prices; move remains free; rollback refund is atomic across resource types (Studio transaction/failure-injection verification pending).
- [x] Show provisional resource costs in the client construction catalogue and localize insufficient-resource/placement errors.
- [x] Add Studio catalog economy contract tests for resource IDs and positive integer prices (execution pending).
- [ ] Add durable transaction journal for crash-safe charge/placement recovery.
- [ ] Decide and implement demolition refund policy after economy balance approval.
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
- [x] Fix failed PlayerRemoving save lifecycle: mark the session as leaving, retry the final save on autosave, then release the MemoryStore lease and destroy the island world/spawn reservation only after save and lease release succeed (forced-failure Studio integration test pending).
- [x] Add first layout-derived Kingdom Bond track (10 provisional points per distinct non-Main-House building type; duplicates do not farm points; moves do not change score; demolition recalculates from the saved layout).
- [x] Add four provisional Kingdom Bond stages and server-owned island visuals (grass tint, flowers, crystal accent, banner) refreshed on spawn/place/move/demolition; visuals follow the stage ID, not raw building count.
- [x] Show current Kingdom Bond stage, points, and next threshold in the resource HUD.
- [x] Add KingdomBond pure contract tests (Studio execution pending).
- [x] Document provisional rules in docs/game-systems/KINGDOM_BOND.md.
- [ ] Playtest Bond thresholds and visuals in Studio; replace blockout decorations with approved original art.
- [ ] Make farming and production meaningfully contribute to progression.

## Stage 4 — Pet Collection

- [ ] Deliver the 20-pet MVP collection.
  - [x] Add validated `PetCollectionData.addPet` and trusted server-only `PetCollectionService.grantPet` foundation with server-generated pet IDs, neutral rarity tier 1–6, level 1 defaults, capacity checks, and atomic DataStore persistence. No egg tables, drop rates, species additions, or client endpoint are defined.
- [ ] Implement pet inventory and collection UI.
- [ ] Implement up to 3 active companions and team management.
  - [x] Add unique per-player spawn tokens so delayed CharacterAdded/equip spawn tasks cannot re-create stale or duplicate companion models after a newer spawn request; verify respawn/equip races in Studio.
- [ ] Implement companion states and mobile-safe movement.
  - [x] Reuse one per-companion RaycastParams instance for ground projection instead of allocating a new filter object every RenderStepped update; mobile/terrain verification pending.
- [ ] Implement actual pet levels (maximum 50), gameplay XP, core stats, skill tree, abilities, equipment, and Bond. Bond is a separate relationship progression; the current Bond prototype is not the pet-level system.
  - [x] Add a pure PetStatsData schema for the five approved stats, level 1–50, and six neutral rarity-tier identifiers. Validation only; no base values, rarity names, scaling formulas, modifiers, or combat behavior are defined.
  - [x] Add reusable exact stat-map validation/cloning and a `PetSpeciesStatsData` contract for species base-stat definitions and catalogs; no species list or balance values are authored.
  - [x] Add `PetStatsCalculator` as a validated, data-driven pipeline that delegates actual stat formulas to an injected balance resolver; no progression or rarity formula is hardcoded.
  - [x] Require resolved stat snapshots to contain exactly `level`, `rarityTier`, and `stats`; reject unknown top-level fields and add regression coverage.
  - [x] Add a declarative `PetStatModifiersData` contract for equipment, skill, and ability modifiers, including strict validation, duplicate-ID rejection, bounded lists, and defensive cloning. Application/stacking rules remain open.
  - [x] Add an ordered `PetStatModifierPipeline` that validates and clones inputs, delegates each modifier's actual arithmetic to an injected policy, validates every intermediate result, and isolates returned values. No stacking or percentage formula is hardcoded.
  - [x] Add `PetStatsCalculator.calculateWithModifiers` to compose species/level/rarity resolution with the validated modifier pipeline, while requiring explicit modifier policy for non-empty modifier lists. Balance arithmetic remains injected.
  - [x] Add `PetProgressionData` to validate a complete monotonic 50-level cumulative-XP threshold table and resolve level/progress with binary search. Threshold values remain external and unapproved; this is not yet connected to persisted XP awards.
  - [x] Add `PetCollectionData.grantExperienceWithProgress` and trusted `PetCollectionService.grantExperienceWithProgress` to atomically persist XP plus its derived level using caller-supplied approved thresholds; return a level-up summary and support multi-level gains. No production threshold curve or gameplay caller is configured.
  - [x] Add a bounded persisted reward-receipt ledger and trusted `grantExperienceWithProgressOnce` API: duplicate reward IDs are idempotent, mismatched payload reuse is rejected, and receipts are retained for seven days (max 128; new rewards fail closed when full). No client remote or gameplay reward caller is added.
  - [x] Add a separate bounded acquisition-receipt ledger and `PetCollectionData.addPetOnce` / trusted `PetCollectionService.grantPet` path. Reusing an acquisition ID returns the existing collection without a second pet; conflicting rarity/species is rejected. Seven-day retention, 128 entries, fail-closed when full.
  - [x] Add `PetEggData` as a reusable strict egg-definition contract with unique species entries, bounded integer weights, defensive cloning, and deterministic weighted selection from a server-supplied random value. No production egg, drop weights, species roster, prices, or hatch endpoint is configured.
  - [x] Add a pure `PetHatchingData` transaction contract with immutable cost snapshots and monotonic PREPARED → CHARGED → GRANTED transitions. This is a state/validation foundation only; no currency is charged, no pet is granted, and no hatch endpoint is exposed until durable cross-store recovery is implemented.
  - [x] Add an island-profile hatch journal with validated transaction records, immutable costs, idempotent prepare/charge/grant transitions, and atomic in-memory wallet debit + CHARGED state mutation. New island profiles initialize an empty journal; legacy profiles remain compatible. Durable transaction acknowledgements and cross-DataStore recovery remain NOT DONE.
  - [x] Enforce an exact five-key stat map and reject unknown/non-string stat keys and incomplete stat maps; added regression tests.
  - [x] Make `PetStatsData.clone` validate its input first and return a structured failure for nil/malformed snapshots instead of indexing invalid data; added regression tests.
  - [x] Add a trusted server-only `PetCollectionService.grantExperience(player, petId, amount)` API backed by DataStore UpdateAsync and a pure validated `PetCollectionData.grantExperience` mutation. It rejects invalid amounts and unowned pets. It is not exposed to clients; no XP reward amounts, level thresholds, or gameplay source callers are defined yet.
  - [x] Bound pet XP, timestamps, acquisition times, and collection revisions to Luau's maximum safe integer; reject XP rewards and collection mutations that would exceed exact integer precision.
  - [x] Validate the complete collection profile at the start of every pure mutation (Interact, Equip, XP reward), returning a structured error for nil or malformed input instead of indexing invalid data; Studio tests added.
  - [x] Prevent out-of-order DataStore mutation responses from rolling the in-memory pet profile back to an older revision; Studio concurrency verification pending.
  - [x] Return the latest in-memory revision in Equip/Interact responses so a delayed request cannot send an older snapshot back to the client; Studio concurrency verification pending.
  - [x] Add backward-compatible per-pet progression fields (`level`, `xp`), default new pets to level 1 / 0 XP, and validate level 1–50 plus finite non-negative integer XP. This is a data-model foundation only; XP thresholds and awarding are intentionally not implemented until approved.
  - [x] Implement first per-pet companionship Bond loop: Pet and Play each grant 10 provisional Bond XP; shared per-pet 30-second cooldown; Bond level 1–10 at 50 XP per level; 450 XP cap; validation enforces XP/level consistency. Studio/DataStore verification remains pending.
  - [x] Collection UI now reflows when the active camera viewport changes (window resize, device rotation, or CurrentCamera replacement); Studio/device verification pending.
- [x] Implement Pet/Play actions and per-pet Bond progress in collection UI; server replicates happy/curious emotion cues to the companion animation controller. PC/touch Studio verification remains pending.
  - [x] Give player-triggered happy/curious reactions priority over autonomous idle personality animations while keeping walk/run states dominant; client Studio verification pending.
  - [x] Add PetCollectionData tests for ownership, XP, cooldown, revision, invalid actions, legacy records, XP/level mismatch, fractional values, NaN/Infinity, and max-XP behavior. Execute the tests in Roblox Studio before marking verification complete.
- [x] Apply a shared server-side one-second mutation rate limit to pet Equip and Interact requests; clear limiter state on PlayerRemoving (Studio spam/race verification pending).
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

The repository now contains the documentation baseline, Rojo mapping, grid math, server/client bootstraps, a server-owned starter building catalog, a pure placement validator, versioned island profile creation/validation helpers, a revision-aware DataStore adapter with bounded retries, and Studio-only smoke-test scripts for placement, grid math, island profiles, store input contracts, and the first Bunny rig factory. These scripts are committed but have not been executed in Roblox Studio. DataStore adapter code is committed but has not been tested against a live Roblox DataStore. The server profile lifecycle is wired into Bootstrap. A failed final PlayerRemoving save now remains in the autosave retry path and finalizes the leaving session only after the save and lease release succeed; this failure/retry scenario still needs a forced-failure Studio integration test against live DataStores. A procedural personal-island blockout renderer is now committed and called after profile session claim. It requires configured Workspace grid attributes and `IslandSpawnPoints`; building Models are optional templates under ServerStorage. This is prototype geometry, not production art, and has not been verified in Studio. Character routing to the island arrival pad is now implemented for initial spawn and respawn. A server RemoteFunction now validates place/move requests, creates server-generated building IDs, synchronizes approved Models, updates the active profile, and deduplicates recent request IDs; Studio integration verification is pending. A first client construction controller is now committed for `main_house`: it renders a local translucent grid-footprint preview, supports rotate/confirm/cancel on desktop and touch, and calls the authoritative server RemoteFunction. The server publishes island grid metadata for this preview. Studio/device verification is pending. A minimal two-entry client catalogue now selects `main_house` or `pet_house` and sends the selected stable ID to the server. Resource charging, full catalogue art/filtering, custom building art, custom camera, upgrade UX, and production assets are not implemented. The starter catalogue now includes four 1×1 decor blockouts: stone path, garden lantern, flower bed, and wooden fence section. All use the same validated placement, move, save, and demolition flow. The next MVP stage, Pet Art Pipeline, has started with a procedural Bunny rig factory (17 Motor6D joints, AnimationController/Animator, follow/ground attachments) and a Studio smoke test; both implementation and test are committed, but Studio execution and visual approval are pending. They are blockouts, not production art; Studio verification is pending. Client move mode now selects a building on the local island, previews a new grid position, checks bounds and replicated building footprints for immediate overlap feedback, and submits the existing instance ID to the server transaction; Studio/device verification is pending. A first demolition flow now selects buildings on the local island, requires a second confirmation press, protects the main house server-side, and rolls profile/world state back if the session cannot be marked writable; Studio verification is pending. Runtime fallback blockout Models now allow `main_house` and `pet_house` placement without imported templates; they are explicitly temporary and not production art. Cross-server MemoryStore coordination lease code is wired into profile lifecycle. Integration smoke coverage exercises ownership, stale-token rejection, release, and reacquisition, but it has not been executed in Studio or under multi-server load. DataStore-side fencing is now implemented: a monotonic sessionGeneration is claimed atomically in the profile key, and every save checks it inside the same UpdateAsync transform. A Studio integration test covers stale-loader claim rejection, stale-generation save rejection, and current-generation acceptance; it is committed but has not yet been executed against a dedicated test universe. MemoryStore remains the coordination lease. Per-player saves are serialized and final-save failures retain the session in memory until shutdown. UpdateAsync rejection detection was corrected: rejected transforms return the existing value, so the adapter now tracks whether the snapshot was accepted. These fixes are committed but untested in Studio. Profile validation now rejects unlock records that do not map to a current server catalog item, malformed/sparse building arrays, and more than 256 building records; lease input validation also rejects non-numeric user IDs before comparing or constructing keys. New Studio tests are committed but remain unexecuted.
