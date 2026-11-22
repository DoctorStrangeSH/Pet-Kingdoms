# Pet Kingdoms — Roadmap

> Rule: deliver the approved MVP in order. No scope expansion before 1.0. A task is DONE only when the implementation is in this repository and its relevant verification has passed.

## Stage 0 — Repository foundation

- [x] Create project README and central specification.
- [x] Create a single source-of-truth roadmap.
- [x] Confirm the intended Roblox development workflow: hybrid Rojo + VS Code + Roblox Studio.
- [x] Add the initial Rojo project mapping and source folder structure.
- [x] Add server and client bootstrap entrypoints.
- [x] Document the local build/live-sync workflow.
- [x] Pin Rojo 7.7.1 in `rokit.toml` for reproducible local and CI builds.
- [x] Add GitHub Actions CI for the full Rojo project build and upload a Studio-ready `.rbxlx` artifact (14-day retention).
- [x] Run and verify a real CI Rojo build: workflow run `45021287072` succeeded on 2026-11-22; artifact `pet-kingdoms-studio-build` was uploaded.
- [ ] Open the generated place in Roblox Studio and verify the runtime hierarchy, Workspace island bounds, scripts, and playtest behavior.
- [x] Add controlled server-side character respawn after death (five-second return delay, session/lease guards, bounded retries; Studio verification pending).
- [x] Prevent automatic character spawn before island/session initialization; load the character only after the profile is claimed and the personal island exists. Add player-facing localized startup status and loading overlay, plus a bounded third-person camera rebind (Studio verification pending).
- [x] Add an idempotent server startup configuration for provisional 24×24 islands, 8-stud grid cells, and eight generated spawn slots; preserve valid owner-authored Workspace configuration.
- [x] Add Studio-only configuration contract coverage for defaults, spawn-slot count, and repeated initialization.
- [x] Extend Studio integration coverage for two-player island allocation, distinct arrival points, duplicate spawn protection, cleanup, and slot reuse (execution pending).
- [x] Reject unanchored parts as personal-island spawn points.
- [ ] Execute the configuration and two-player island spawn tests in Roblox Studio.

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
- [x] Verify the first Roblox Studio Play launch after publishing a dedicated private test Experience and enabling Studio API access; owner confirmed the loading screen completed and the game entered successfully (2026-11-22).
- [ ] Verify procedural personal island rendering quality, exact spawn placement, resource prompts, and repeated leave/rejoin behavior in Roblox Studio.
- [x] Add versioned island profile schema and validation helpers (Studio tests committed; execution pending).
- [x] Add persistent resource wallet to island profiles (provisional starter: 2 Wood, 1 Stone; Gold/Gems start at 0).
- [x] Add backward-compatible migration for existing schema-v1 profiles without a wallet during session claim.
- [x] Add server-only atomic resource grant/spend API with rollback when a session is not writable.
- [x] Centralize atomic multi-resource grants; reject empty reward/spend transactions and validate every reward/cap before changing any wallet balance.
- [x] Align saved island wallet validation with the live wallet's resource IDs and 2,000,000,000 balance cap; add an over-cap profile regression test.
- [x] Add pure Studio contract tests for resource validation, grants, and atomic spending (execution pending).
- [x] Spawn two Wood and two Stone gathering nodes on each personal island using server-owned reward values.
- [x] Add server-authoritative ProximityPrompt gathering with ownership/distance checks, duplicate-trigger protection, wallet grant, and 60-second node respawn (Studio verification pending).
- [x] Persist each canonical Wood/Stone node's last-gathered and available-at timestamps in the island profile; grant its wallet reward and set the 60-second cooldown in one profile revision, waiting for DataStore durability before acknowledging the reward.
- [x] Restore depleted node visuals/prompts from saved timestamps on island load; offline time counts toward regeneration and expired nodes return without an extra reward.
- [x] Migrate legacy schema-v1 profiles to an empty resource-node state list; validate node IDs, resource mapping, unique records, timestamp order, and the server-owned cooldown duration.
- [x] Serialize gathering against building and hatch profile mutations; reject overlapping construction requests before they mutate the wallet/building list, preventing rollback from overwriting another committed reward.
- [x] Add Studio contract tests for independent node cooldowns, duplicate collection prevention, cooldown expiry, invalid node/resource state, profile validation, legacy migration, and DataStore save/load persistence (execution pending).
- [x] Require the exact current writable Player session for gathering prompts and client wallet snapshot requests.
- [x] Add client resource HUD for Wood/Stone/Gold/Gems with server snapshot bootstrap, authoritative update event, and gathering reward toast (Studio/device verification pending).
- [x] Align the gathering success toast with the server's authoritative `GATHERED` event (client/server code mismatch fixed; Studio confirmation pending).
- [ ] Add world-space gathering feedback animation and final polished art treatment.
- [ ] Verify HUD safe areas, readability, and touch gathering on phone/tablet in Roblox Studio.
- [ ] Verify multiplayer ownership, prompt interactions, respawn, and persistence in Roblox Studio.
- [ ] Approve and tune the full economy balance sheet; current construction prices are provisional and must be playtested.
- [ ] Implement shared Sun Grove and Moon Grove connections.
- [ ] Implement bridge repair and guest permissions.
- [x] Remove the unused duplicated client-side building-price table; the server-owned BuildingCatalog remains the sole source of construction costs (no gameplay behavior changed).
- [ ] Implement island expansion and validated building placement.
  - [x] Add a pure expansion geometry contract: level 0 preserves the current plot, each of two provisional levels adds 8 grid cells per axis, and invalid/max levels are rejected. No purchase costs or unlock conditions are invented before economy approval.
  - [x] Add Studio-only geometry contract tests for starter/expanded dimensions, maximum level, and invalid inputs (execution pending).
  - [x] Persist `expansionLevel` as an optional schema-v1 profile field; normalize legacy saves to level 0 during load and session claim.
  - [x] Add a pure next-level profile transformation that shifts saved grid coordinates by half the added dimensions, preserving existing buildings in world space; cover two levels and max-level rejection in Studio tests (execution pending).
- [x] Extend IslandExpansion Studio contract tests to verify both successive profile transformations, exact cumulative coordinate offsets, source-profile immutability, and rejection beyond the maximum level (Studio execution pending).
- [x] Harden expansion profile transformation against negative/fractional saved grid coordinates and add regression cases (Studio execution pending).
- [x] Extend malformed-coordinate regression coverage to NaN and infinity (Studio execution pending).
  - [x] Add Studio world-renderer integration coverage for a level-1 expanded profile: 32x32 terrain and unchanged saved-building world position (execution pending).
- [x] Extend renderer integration coverage to maximum level 2: 40x40 terrain and unchanged main-house world position after cumulative coordinate offset (execution pending).
- [x] Validate that persisted island bounds exactly match the configured base bounds and expansion level before rendering; reject mismatched or unsupported profile geometry.
- [x] Add a pure canonical next-level preparation boundary that validates current and resulting profile bounds without mutating the source profile.
- [x] Add a server-session expansion commit that serializes against existing profile mutations, checks the expected level, prepares the next profile, and waits for its revision to persist; purchase/resource charging and world respawn remain separate NOT DONE work.
- [x] Rebuild the active island world from the newly persisted expansion profile while retaining its assigned spawn slot; add Studio integration coverage for live refresh at levels 1 and 2 (execution pending).
- [x] Add read-only server RemoteFunction `GetIslandExpansionPreview` exposing the active profile's current/next bounds, max level, and explicit economy-not-approved state; rate-limit preview requests. Purchase remains disabled.
- [x] Add responsive client expansion preview panel wired to GetIslandExpansionPreview; show current/next level and dimensions, explain disabled purchase, and support manual refresh. No purchase action is exposed.
- [x] Add client-only holographic preview strips around the active island using server-provided next dimensions; preview is non-colliding, non-queryable, and removed when the panel closes. This is a visual guide, not terrain or a purchase.
- [x] Add a short server-replicated expansion completion effect after successful world replacement: perimeter light pulses and a transient particle burst; add Studio assertions (execution pending).
- [ ] Persist expansion level, implement server-authoritative unlock/purchase and idempotency, then render expanded terrain without moving existing saved building coordinates.
- [x] Add first client construction controller for main_house (grid preview, rotate, confirm/cancel; Studio verification pending).
- [x] Add runtime fallback blockout Models for main_house and pet_house so placement can be exercised without imported production assets (Studio verification pending).
- [x] Add a minimal client catalogue for main_house and pet_house, wired to server-authoritative placement (Studio/device verification pending).
- [x] Add server-authoritative demolition for non-main-house buildings, with client selection and explicit second-press confirmation (Studio verification pending).
- [x] Add client move mode for selected buildings using existing server-authoritative move transaction and stable instance IDs (Studio/device verification pending).
- [x] Add client-side occupied-footprint preview feedback for placement/move; server remains authoritative (Studio verification pending).
- [x] Add a proximity interaction to the Pet House that opens the existing pet collection UI only on the owner's island; all collection mutations remain server-authoritative (Studio/device verification pending).
- [x] Add a Main House interaction that opens an island overview with live Kingdom Bond progress, building count, and a route into the existing construction flow (Studio/device verification pending).
- [x] Add initial decor catalogue entries for stone_path and garden_lantern with saved placement, move, and demolition support (Studio verification pending).
- [x] Expand the starter decor catalogue with flower_bed and wooden_fence blockout models, selection cards, and the shared placement/move/demolition flow (Studio verification pending).
- [x] Preserve the same client request ID for placement/move retries while the server reports BUILDING_OPERATION_IN_PROGRESS, BUILDING_OPERATION_BUSY, PERSIST_TIMEOUT, or SESSION_NOT_WRITABLE; clear it only after a definitive response (Studio fault-injection verification pending).
- [ ] Complete server-side placement validation (catalog and validator are committed; Studio smoke tests remain unrun).
- [x] Add Studio smoke-test coverage for placement validation and grid math (scripts committed; execution pending).
- [x] Add server-authoritative placement/move/demolition transaction endpoint with recent request deduplication and world/profile rollback (Studio integration verification pending).
- [x] Require the exact current Player instance and writable island lease before building mutations.
- [x] Persist building operation receipts in the same island profile revision as placement/move/demolition results; fingerprint request payloads, replay only after the receipt revision is durable, and retain 512 recent receipts for seven days (Studio DataStore restart/failure-injection verification pending).
  - [x] Add per-player token-bucket rate limiting to the building RemoteFunction (12-request burst, refill 4/sec; Studio spam test pending).
- [x] Add server transaction handling for new placement resource charging from server-owned provisional catalog prices; move remains free; wallet cost and building record now share one profile revision and restore the original wallet on rollback (Studio transaction/failure-injection verification pending).
- [x] Show provisional resource costs in the client construction catalogue and localize insufficient-resource/placement errors.
- [x] Add Studio catalog economy contract tests for resource IDs and positive integer prices (execution pending).
- [x] Add durable building-operation receipt journal for crash-safe placement/move/demolition idempotency; wallet/building/profile receipt are saved together before success is acknowledged (Studio DataStore restart/failure-injection verification pending).
- [ ] Decide and implement demolition refund policy after economy balance approval.
- [ ] Complete persistent personal home islands (profile lifecycle and MemoryStore lease code are committed; world spawning and Studio verification remain).
- [x] Add cross-server MemoryStore coordination lease with acquire, renewal, release, and fail-closed handling (Studio verification pending; DataStore fencing is implemented separately).
- [x] Add DataStore-side fencing/session generation checked atomically inside every profile UpdateAsync write, using compare-and-swap claims to reject delayed loaders (Studio integration test committed; execution pending).
- [x] Treat a same-generation DataStore revision that is already equal/newer than the retry snapshot as durable success; this makes lost UpdateAsync acknowledgements idempotent without overwriting newer data (Studio integration test committed; execution pending).
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
- [x] Separate the Bond-eligible improvement count from the total placed-building count (including Main House); calculate overview progress from stable stage IDs rather than localized labels.
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
- [x] Implement client companion follow controllers for up to three equipped Bunny pets, with distinct formation slots and procedural idle/walk/run/interaction animations (Studio verification pending).
- [x] Add catch-up running when a companion lags behind and bounded recovery when streaming/character resets leave it extremely far from the owner (Studio verification pending).
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
  - [x] Add `IslandSessionService.applyHatchOperation` with per-session hatch serialization, revision tracking, and a durable-save wait loop. PREPARE/CHARGE/GRANT transformations are not acknowledged until the corresponding profile revision has been saved successfully; timeout/failure leaves the mutation pending for retry/autosave. Recovery orchestration and cross-store reconciliation remain NOT DONE.
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
  - [x] Audit the island-wallet and pet-collection DataStore boundary; document a durable claim + outbox + idempotent pet-XP delivery protocol and its recovery invariants.
  - [x] Make pet XP idempotency receipts permanent while unacknowledged; add a trusted source-acknowledgement operation, then start the bounded retention window.
- [ ] Integrate the acknowledgement operation with the durable island XP outbox and verify cross-store recovery.
  - [ ] Approve resource/Gold/Gems and pet-XP reward values, plus the pet recipient rule.
  - [ ] Implement permanent quest claim receipts, atomic island resource grants, and durable pet-XP outbox delivery.
  - [ ] Add failure-injection tests for lost acknowledgements, duplicate claims, DataStore outages, and server shutdown during outbox delivery.
  - [ ] Add the claim UI only after the server claim protocol and economy values are approved.
  - [x] Add persistent server-authoritative introductory gathering quest progress for Wood/Stone, with a read-only snapshot endpoint and profile migration; reward claiming/UI remain NOT DONE.
- [ ] Implement exploration interactions and pet abilities.
- [ ] Implement Gold, Gems, biome resources, shops, and balanced upgrade costs.
  - [x] Lock current gathering-node count, canonical IDs, rewards, and 60-second cooldown in Studio contract tests; gold/gem, quest, and shop income remain NOT DONE.
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


### Pet hatch recovery on player join

- [x] Add a server-only recovery decision table for PREPARED → CHARGE, CHARGED → GRANT, and GRANTED → COMPLETE.
- [x] Add `PetHatchingRecoveryService`, started after island and pet collection services. It waits for both player datasets, snapshots unresolved island journal entries, resumes PREPARED/CHARGED transactions using the original species, rarity, transaction ID, and acquisition ID, and marks GRANTED only after the pet collection write succeeds.
- [x] Repeated collection grants use the existing idempotent acquisition receipt; a lost response can be retried without creating a second pet.
- [x] Fail-closed behavior: if either datastore is unavailable, the player leaves, the collection is full, or a transaction cannot complete, the journal remains unresolved and will be retried on a later join.
- [ ] Add Studio integration/fault-injection tests for interruption after PREPARED, after CHARGED, after pet collection commit, and before GRANTED acknowledgement.
- [ ] Add a capacity reservation/overflow policy before enabling paid hatching. A CHARGED transaction must remain pending rather than discard the pet if collection capacity is unavailable.
- [ ] Add player-facing hatch endpoint only after approved egg catalog/economy configuration and integration verification.


### Pet collection capacity reservations

- [x] Add persisted `reservedAcquisitions` to the pet collection profile. Validation enforces unique acquisition IDs, approved species/rarity, valid timestamps, and `owned + reserved <= MAX_OWNED_PETS`.
- [x] Add idempotent `reservePetSlotOnce` and server API `PetCollectionService.reservePetSlot`. A slot is reserved with the same acquisition ID before an island hatch transaction is charged.
- [x] Update ordinary `addPet` so non-hatch rewards cannot consume capacity already reserved for a pending hatch.
- [x] Update `grantPet` to reserve and consume capacity in one collection DataStore UpdateAsync mutation when no prior reservation exists; existing reservations are consumed by the matching acquisition.
- [x] Update join recovery to reserve collection capacity before resuming PREPARED charge or CHARGED grant. A full collection therefore blocks charging and leaves the transaction pending.
- [x] Add data tests for reservation idempotency, capacity exhaustion, protection against ordinary rewards, reservation consumption, and acquisition retry.
- [ ] Run Studio tests and DataStore fault-injection tests; validate simultaneous reserve attempts under concurrent UpdateAsync callbacks.
- [ ] Define reservation expiry/cancellation policy for abandoned transactions. Do not automatically expire a reservation while its island journal is PREPARED or CHARGED.
- [ ] Add user-facing overflow/inbox/collection management policy before shipping hatch purchases.


### Pet inventory management foundation

- [x] Add persisted `isLocked` and `isFavorite` flags to pet records; legacy records normalize to false.
- [x] Add server-validated `Protect` action with expected-revision checks and DataStore UpdateAsync persistence.
- [x] Add safe permanent removal with protections for the starter Bunny, the last remaining pet, locked pets, and currently equipped pets.
- [x] Add server-validated `Delete` action with expected-revision checks; successful deletion immediately frees one collection slot.
- [x] Add pure data tests for flag validation/persistence, lock protection, equipped protection, starter protection, last-pet protection, and successful removal.
- [x] Add player-facing collection management UX: filter all/team/favorites, sort by newest/name/Bond, toggle favorite/lock, and require explicit confirmation before permanent deletion. Server remains authoritative and revision-checked (Studio/device verification pending).
- [ ] Run Studio tests and DataStore integration tests before release.


### Pet evolution architecture foundation

- [x] Add a balance-agnostic evolution catalog contract with stable evolution IDs and source/target species identifiers.
- [x] Validate identifier shape, duplicate evolution IDs, self-evolution, dense catalog arrays, and a bounded definition count.
- [x] Validate the evolution graph as a directed acyclic graph while allowing branches and converging paths.
- [x] Add a read-only option lookup by source species; returned definitions are cloned.
- [x] Add Studio-only pure tests for empty catalogs, branching/chained paths, lookup isolation, duplicate IDs, self edges, cycles, malformed IDs, and sparse arrays.
- [ ] Approve actual species/forms, evolution branches, levels, item/currency costs, and eligibility requirements in game design before adding production catalog entries.
- [ ] Add persisted evolution history and idempotent server-side evolution transactions only after requirements and target species are approved.
- [ ] Add Studio/DataStore integration and interruption tests before enabling evolution.


### Pet evolution transition preparation

- [x] Add stable-ID lookup for a validated evolution definition.
- [x] Add a pure transition-preparation function that checks the pet's current species against the definition source.
- [x] Preserve the same petId and all unrelated pet fields while preparing only the speciesId change (level, XP, bond, rarity, lock, favorite, and other metadata remain intact).
- [x] Add tests for definition lookup, successful transition preparation, stable identity, progression/metadata preservation, original-record immutability, wrong-source rejection, malformed records, and unknown evolution IDs.
- [ ] Do not add a production evolution service or persistence transaction until the species registry and at least one real target form are approved; the current collection schema only accepts `bunny`.
- [ ] Once target species are approved, extend the species registry and add bounded evolution history/receipts plus an idempotent UpdateAsync transaction with expected-revision checks.


### Pet identity ledger hardening

- [x] Prevent a newly added pet from reusing a petId already present in the retained acquisition receipt ledger, even if the original pet was deleted.
- [x] Add a regression test that acquires, removes, and attempts to recreate a pet with the same ID.
- [x] Review acquisition receipt retention and capacity policy: unresolved receipts are permanent; acknowledged receipts are compacted seven days after durable completion; the ledger remains bounded and fails closed at capacity.
- [ ] Add cross-system audit correlation for hatch transaction IDs, acquisition IDs, and stable pet IDs when evolution transactions are implemented.


### Pet acquisition ledger capacity audit

- [x] Found and fixed a cross-ledger failure: hatch slot reservation previously reserved collection capacity but did not reserve a bounded acquisition-receipt slot. Other rewards could fill the receipt ledger after currency charge, leaving a charged hatch unable to grant its pet.
- [x] Reserve one acquisition-receipt slot together with each pending hatch reservation. Enforce `retained receipts + pending reservations <= MAX_ACQUISITION_RECEIPTS`.
- [x] Prune only acknowledged acquisition receipts during reservation, using seven days from durable completion; unresolved receipts never expire.
- [x] Consume the reserved receipt capacity atomically when the matching hatch grant completes; account for other pending reservations when processing a grant.
- [x] Apply completion-based receipt retention to the pet-ID reuse guard; unresolved acquisition IDs remain reserved indefinitely.
- [x] Add regression tests for final receipt-slot reservation, rejection of an additional pending hatch, successful receipt-slot consumption, expiry pruning, and pet-ID reuse after expiry.
- [x] Synchronize the newest validated DataStore snapshot into the in-memory cache when an idempotent XP retry returns `ALREADY_PROCESSED`.
- [ ] Run Studio pure-data tests and DataStore concurrency/fault-injection tests. Verify a reservation remains grantable when other reward sources execute concurrently.
- [x] Remove non-idempotent PetCollectionService XP write entry points before gameplay reward callers exist; all service-level XP writes now require a stable reward ID via `grantExperienceWithProgressOnce`.


### Acquisition receipt integrity

- [x] Reject acquisition ledgers where two retained receipts claim the same petId, even when acquisitionIds differ.
- [x] Cross-check an owned pet's speciesId and rarityTier against its retained acquisition receipt.
- [x] Add regression tests for duplicate receipt pet IDs and owned-record/receipt metadata mismatch.
- [ ] Execute collection tests in Roblox Studio and verify legacy production profiles against the stricter receipt invariants before rollout.


### Island shutdown persistence fencing

- [x] Release the island lease during BindToClose only after the final profile snapshot is confirmed persisted.
- [x] If the shutdown save fails, retain the lease until its normal expiry instead of allowing an immediate new session to load a known-stale snapshot.
- [ ] Exercise shutdown save failure, lease expiry, and immediate rejoin in a controlled Roblox Studio/DataStore test environment.


### Pet collection reconnect session isolation

- [x] Associate each loaded pet collection state with its exact Roblox `Player` instance, not only its numeric UserId.
- [x] Ignore a delayed load completion from an older Player instance, without clearing a newer in-flight or loaded state.
- [x] Ignore stale PlayerRemoving cleanup for a superseded Player instance, preserving the new player's profile, character connections and mutation state.
- [x] Reject stale Player-instance collection requests and mutations; require matching ownership for equipped-pet spawning and hatch recovery readiness.
- [ ] Test slow DataStore load + disconnect + immediate rejoin and overlapping server operations in Studio with mocked delays; current verification is static only.
- [ ] Add stronger cross-server pet collection session fencing if overlapping Player sessions prove possible; DataStore revision checks alone are not ownership leases.


### Pet collection cross-server writer fencing

- [x] Add `PetCollectionSessionData`: atomic claim uses an observed revision/generation/token tuple and returns a monotonically incremented generation plus server-generated session token. Claim retries with the same token are idempotent; stale observations fail closed.
- [x] On load, observe and validate the collection, then claim its next writer generation via the same collection DataStore key using `UpdateAsync` before enabling client/server collection requests.
- [x] Check generation and token inside every post-load collection `UpdateAsync` callback; stale instances cannot persist mutations after a newer session claims the key.
- [x] Preserve and validate optional fencing metadata through collection clones and pure data mutations; legacy profiles without these fields remain readable.
- [x] Abort in-flight claims when the Player instance disconnects or is superseded.
- [x] Add pure tests for claim retry, concurrent observation, stale writers, token validation, metadata preservation and partial metadata rejection.
- [ ] Run Roblox Studio unit and integration tests with two simulated servers, deliberately delayed `GetAsync` / `UpdateAsync`, and lost acknowledgements.
- [ ] Consider MemoryStore lease and session-heartbeat gating if user-presence exclusivity is required; persisted fencing only prevents stale writes, not new-session takeover while a prior session still exists.


### Shared island lease gating for pet collection

- [x] Use the existing island MemoryStore lease as the authority for collection loading and writes; avoid a second independent lease whose ownership could disagree with the island.
- [x] Expose `IslandSessionService.canWrite(userId, player)`, which checks exact Player identity, active island session, lease validity, and leave/close/shutdown state.
- [x] Wait for the writable island session before claiming the pet collection writer generation; fail closed and disconnect if the island session remains unavailable for 120 seconds.
- [x] Check island session write eligibility in every post-load pet collection DataStore UpdateAsync callback, plus client/server mutation entry points, companion spawn, and hatch recovery readiness.
- [x] Abort a pending pet collection claim when its island lease becomes non-writable.
- [x] Fix a Luau forward-reference bug: `IslandSessionService.applyHatchOperation` now captures the locally declared `saveSession` implementation instead of an unresolved global.
- [ ] Run Roblox Studio DataStore/MemoryStore integration tests for lease loss during a pending collection write, leave during claim, same-user rejoin, and hatch recovery after a CHARGED transaction.
- [ ] Ensure grant callbacks return deterministic conflict/lease-lost statuses and audit remaining time-of-check/time-of-use windows.


### Hatch recovery readiness and reconnect hardening

- [x] Align hatch recovery readiness timeout (150 seconds) with the pet collection's 120-second island lease readiness wait, instead of timing out after 45 seconds.
- [x] Track each in-progress hatch recovery by exact Player instance and run token; stale PlayerRemoving callbacks cannot cancel a newer player's run.
- [x] Keep the initial recovery readiness poll independent of lease readiness; once ready, require valid island lease and collection on every pending transaction iteration.
- [x] Cancel recovery cleanly when lease ownership is lost or the player disconnects; journal remains durable for later retry.
- [x] Add a Studio-only test asserting that recovery's readiness window exceeds the collection readiness window.
- [ ] Run controlled Studio tests for delayed collection loading, rapid disconnect/rejoin, lease loss during CHARGED recovery and DataStore write acknowledgement loss.
- [x] Resolve the seven-day dedupe gap for CHARGED transactions: unresolved receipts persist until the island journal is durably GRANTED and the collection receipt is acknowledged. Studio fault-injection is still required before live paid eggs.


### Hatch recovery retry during an active session

- [x] Re-read the authoritative island hatch journal on each recovery attempt rather than replaying the first login snapshot.
- [x] Retry unfinished PREPARED/CHARGED hatch transactions every 15 seconds while the same Player owns a writable island lease and the pet collection is ready.
- [x] Stop retrying when no pending transactions remain, the Player leaves, the lease becomes non-writable, or collection readiness is lost.
- [ ] Run Studio/MemoryStore/DataStore fault-injection covering transient save failures, disappearing lease, CHARGED journal recovery, and a blocked transaction that becomes resolvable without rejoining.
- [x] Reconcile acquisition receipt expiry with long-lived CHARGED hatch journals using transaction-bound completion acknowledgement; live paid hatching still awaits Studio fault-injection.


### Durable hatch acquisition deduplication

- [x] Store the source hatch transaction ID alongside each hatch acquisition receipt and pending reservation.
- [x] Keep unacknowledged acquisition receipts indefinitely; elapsed wall-clock time alone can never make a PREPARED/CHARGED hatch grantable twice.
- [x] After the island journal is durably GRANTED, acknowledge the matching collection receipt with its exact transaction ID and completion timestamp.
- [x] Compact only acknowledged receipts after the seven-day completion retention window; this window begins after durable completion, not initial acquisition.
- [x] Retry receipt acknowledgement for GRANTED journal entries on subsequent recovery passes and later joins; treat an already-compacted receipt as complete.
- [x] Prevent a repeated PREPARE from reporting a completed transaction as merely PREPARED; return ALREADY_GRANTED without regressing the journal.
- [x] Add tests for beyond-seven-day pending receipts, transaction-ID mismatch, acknowledgement idempotency, completed-receipt compaction, legacy reservation upgrade, and granted-journal idempotency.
- [ ] Run Roblox Studio/DataStore fault injection across the exact sequence: pet grant persisted -> server crash -> journal GRANTED -> receipt acknowledgement lost -> rejoin -> acknowledgement retry.
- [ ] Monitor the bounded 128-entry receipt ledger; capacity reservation fails closed before charging, but high-volume acquisition patterns may require a compacted external dedupe index.

- [x] Upgrade legacy acquisition receipts and pending reservations with the transaction ID from their matching durable hatch journal before completing recovery.

- [ ] Audit any pre-deployment CHARGED hatch journal whose old seven-day acquisition receipt may already have been pruned; such a legacy record can be ambiguous and must not be described as fully recoverable without a matching receipt/reservation or an explicit migration decision.


### Wallet API transaction exclusion (2026-11-22)

- [x] Require the exact live Player instance and a writable island lease before generic wallet grant/spend APIs mutate a profile.
- [x] Reject generic `grant`, `grantMany`, and `spend` calls while building, gathering, or hatch transactions hold the profile mutation guard.
- [x] Keep transaction-owned wallet changes inside their existing atomic profile operations; generic wallet helpers cannot interleave while those operations wait for DataStore durability.
- [ ] Add an executable Studio service-level regression harness for busy-session rejection and exact-Player identity, then run it in Roblox Studio.
- [ ] Run the complete Studio suite and multi-server DataStore/MemoryStore fault-injection scenarios before treating the persistence layer as accepted.


### Temporary Creator Store assets for prototype testing (2026-11-22)

- [x] Owner approved free Creator Store/Toolbox assets as temporary placeholders so the playable prototype can be tested before original art is complete.
- [x] Update PROJECT_SPEC.md, ART_BIBLE.md, README.md, and ASSET_TRACKER.md to distinguish temporary test assets from approved production assets.
- [x] Require exact source/creator/provenance records, license/attribution review, script audit, mobile/performance review, isolation from gameplay authority, and a documented replacement target.
- [ ] Select and review the first free environment kit in Roblox Studio; no third-party candidate is imported or approved yet.


### Companion environment awareness

- [x] Add lead-Bunny resource investigation: approach a nearby available/visible owner-island node, inspect it with Curious/Sniff, then resume the normal formation after a short visit. This is visual-only; gathering remains server-authoritative (Studio verification pending).
- [ ] Expand ambient reactions to approved points of interest after the first world biome exists.


## Economy audit

- [x] Audit current wallet defaults, resource-node rewards/respawn, and server building costs; document theoretical gathering ceilings and explicitly keep expansion prices unapproved until the full balance sheet is decided.

See `docs/game-systems/ECONOMY_BASELINE_AUDIT.md` for source-backed current values and open balancing decisions.


## Quest reward outbox foundation (2026-11-22)

- [x] Add pure QuestRewardOutboxData contracts for permanent quest-claim receipts and durable pet-XP outbox entries.
- [x] Validate quest IDs, stable reward IDs, pet IDs, positive bounded XP amounts, progression configuration version, timestamps, unique IDs, and contiguous bounded outbox storage.
- [x] Make duplicate claim and enqueue attempts idempotent; reject reuse of a reward ID with a different payload.
- [x] Record delivery only after a caller confirms the pet-side XP write; repeated delivery acknowledgement is idempotent.
- [x] Never expire or evict pending XP records; a full outbox fails closed.
- [x] Add the claim/outbox fields to newly created island profiles, preserve compatibility with legacy schema-v1 profiles, and deep-clone the ledgers before DataStore saves.
- [x] Add Studio-only contract tests for claim receipts, enqueue deduplication, payload conflicts, pending lookup, delivery acknowledgement, malformed records, and profile compatibility.
- [ ] Execute the new Studio tests in Roblox Studio.
- [x] Verify the full Rojo build and Studio artifact upload in GitHub Actions run 45039287808 (PASS); Studio script execution remains separate and pending.
- [ ] Integrate the durable quest claim transaction into IslandSessionService; no client claim endpoint is exposed.
- [ ] Add an outbox recovery worker that retries the same reward ID, durably marks delivery, then acknowledges the pet-side receipt.
- [ ] Decide approved reward amounts, XP progression configuration, and deterministic pet recipient policy before enabling claims. No economy values or recipient rule were invented.
- [ ] Add DataStore fault-injection coverage for island commit, pet XP commit, lost acknowledgement, player leave, server restart, and recovery after rejoin.


### Quest reward transaction integration (2026-11-22)

- [x] Add a server-only IslandSessionService claim primitive that commits the permanent claim receipt and XP outbox entry in one island revision.
- [x] Bind each claim receipt to its island revision and make retries wait for durable persistence before acknowledging the original receipt.
- [x] Add durable outbox delivery and second-phase pet receipt acknowledgement transitions.
- [x] Expose server-only pending-delivery and awaiting-acknowledgement snapshots for a future recovery worker.
- [x] Compact only fully acknowledged outbox entries; never evict pending or delivered-but-unacknowledged rewards.
- [x] Add the server-started recovery worker; it retries the same reward ID, persists island delivery, then acknowledges the pet receipt and source outbox. Studio/DataStore fault-injection remains pending.
- [ ] Approve reward values, progression thresholds/version, and deterministic pet recipient policy.
- [ ] Execute Roblox Studio DataStore failure/rejoin/server-restart tests before enabling any claim remote or UI.

- [x] Verify the latest Rojo build and Studio artifact upload in GitHub Actions run #115 (PASS); Studio script execution remains separate and pending.


### Quest XP recovery worker (2026-11-22)

- [x] Add a server-owned, versioned pet progression catalog contract. Unknown/unapproved versions fail closed; the registry is intentionally empty pending approved XP thresholds.
- [x] Add a recovery worker that waits for island + pet collection readiness and resumes pending or delivered-but-unacknowledged outbox entries.
- [x] Integrate the worker into server bootstrap; retry transient failures without dropping or regenerating reward IDs.
- [x] Add Studio-only progression catalog contract tests.
- [ ] Resolve the pet receipt/source acknowledgement retention edge case for prolonged outages.
- [ ] Add service-level fault-injection coverage for every cross-DataStore crash boundary and execute in Roblox Studio.
- [ ] Approve the progression curve, quest reward values, and deterministic pet recipient policy before enabling claims.


### Quest XP acknowledgement retention hardening (2026-11-22)

- [x] Persist the island source acknowledgement immediately after the pet XP delivery is confirmed and before acknowledging the pet receipt.
- [x] Add a separate durable `petAcknowledgedAt` outbox marker; compact only after both source and pet acknowledgement markers are persisted.
- [x] Recover source-acknowledged records whose pet receipt finalization was interrupted.
- [x] Treat a missing pet receipt as already finalized only after the source acknowledgement is durable; unacknowledged receipts remain permanent.
- [x] Add tests proving source-acknowledged records cannot be compacted before the final pet marker and that acknowledgement timestamps are ordered.
- [ ] Execute Studio tests and cross-DataStore crash/fault-injection scenarios.

- [x] Verify quest XP recovery worker and final acknowledgement handshake in GitHub Actions run #127 (Rojo build + Studio artifact upload PASS); Studio script execution remains pending.

- [x] Harden recovery worker startup against duplicate PlayerAdded/initial-player enumeration and keep waiting through slow profile loads instead of abandoning recovery after a fixed timeout.


### Quest reward recovery protocol fault injection (2026-11-22)

- [x] Extract cross-DataStore transaction ordering into a shared protocol used by the production recovery worker.
- [x] Add deterministic fault-injection tests for lost responses after each durable write boundary.
- [x] Assert stable reward ID retry and exactly-once XP application across all five interrupted boundaries.
- [x] Assert delivered-record resume never calls the XP grant again.
- [x] Assert missing pet receipt is accepted only after durable source acknowledgement.
- [ ] Run the Studio-only protocol suite and all existing data contract suites in Roblox Studio.
- [ ] Run live DataStore outage/rejoin/server-restart scenarios in a dedicated test environment.


### Quest journal legacy-profile compatibility (2026-11-22)

- [x] Fix quest snapshots for legacy island profiles created before `questProgress` existed: the server now presents the current introductory quests at 0 progress without mutating the stored profile.
- [x] Add Studio contract coverage for legacy nil progress and malformed progress snapshots.
- [ ] Execute the updated QuestProgressData tests in Roblox Studio.


- [x] Verify the legacy quest snapshot fix and expanded quest progress edge-case test packaging in GitHub Actions run #144 (Rojo build + Studio artifact upload PASS).


### Quest journal deterministic ordering (2026-11-22)

- [x] Replace hash-table iteration in quest progression/snapshot presentation with an explicit stable order: wood quest first, stone quest second.
- [x] Add a contract assertion that repeated snapshots preserve the same order.
- [ ] Execute the updated Luau test in Roblox Studio.


### Atomic gathering-to-quest integration (2026-11-22)

- [x] Extract a pure `IslandGatheringTransactionData` transform that composes wallet grant, resource-node cooldown, and quest progress before any live profile mutation.
- [x] Route `IslandSessionService.commitResourceGathering` through the shared transaction result and persist all three state changes under one island profile revision.
- [x] Add integration contract tests for wood/stone progression, independent node cooldowns, quest completion, immutable source state, cooldown rejection, wallet-cap rejection, malformed quest state, and unknown nodes.
- [ ] Execute the new Studio integration suite and existing gathering/quest contract suites in Roblox Studio.
- [ ] Validate actual DataStore persistence, leave/rejoin, and server restart behavior in a dedicated test place.


### Gathering persistence and reload contract (2026-11-22)

- [x] Add a Studio contract that JSON-serializes and restores a real island profile after a gathering transaction, then validates the restored profile against the canonical IslandData schema.
- [x] Assert resources, node cooldown, quest progress, and profile revision all survive the round trip.
- [x] Assert a reloaded node cannot be gathered twice during its persisted cooldown and that a distinct node advances quest progress once.
- [ ] Execute the serialization/reload contract in Roblox Studio.
- [ ] Run true DataStore leave/rejoin and server-restart scenarios in a dedicated test place; JSON round-trip is a schema contract, not a live DataStore test.


- [x] Verify gathering serialization/reload contract packaging in GitHub Actions run #157 (Rojo build + Studio artifact upload PASS); Studio execution and live DataStore testing remain pending.


### Quest completion vs reward claim visibility (2026-11-22)

- [x] Include durable claim receipt state in server quest snapshots without conflating it with completion.
- [x] Expose `rewardClaimed` only when the quest is complete and a structurally valid receipt exists.
- [x] Update Quest Journal cards to distinguish `ВЫПОЛНЕНО` from `НАГРАДА ПОЛУЧЕНА` and show the total claimed count.
- [x] Add contract coverage for claimed, unclaimed, malformed-receipt, and premature-receipt snapshots.
- [ ] Execute quest data and UI behavior tests in Roblox Studio.
- [ ] Approve reward economy and pet recipient policy before enabling a claim interaction.


- [x] Verify quest completion/claim-state visibility tests and UI packaging in GitHub Actions run #164 (Rojo build + Studio artifact upload PASS); Studio execution remains pending.


### Pet progression safety and collection visibility (2026-11-22)

- [x] Validate every server-owned progression curve before returning it to reward recovery; malformed configured data fails closed.
- [x] Reject NaN, infinity, fractional, and unsafe progression version identifiers.
- [x] Cover XP beyond the level-50 threshold: level remains capped while lifetime XP remains visible.
- [x] Display each pet's persisted level and lifetime XP in the collection details panel without inventing a next-level requirement.
- [ ] Execute progression/catalog/collection contract tests and inspect the collection panel at desktop and mobile sizes in Roblox Studio.
- [ ] Approve the production 50-level XP curve before enabling quest XP delivery.


- [x] Verify pet progression catalog hardening and contract-test packaging in GitHub Actions run #173; Rojo build and Studio artifact upload PASS. Studio test execution remains pending.


### Idempotent pet XP service boundary (2026-11-22)

- [x] Audit all server service/bootstrap modules: no gameplay callers use the non-idempotent XP service methods.
- [x] Remove `PetCollectionService.grantExperience` and `PetCollectionService.grantExperienceWithProgress`.
- [x] Keep only `grantExperienceWithProgressOnce` as the server service XP write entry point; every retryable gameplay reward must carry a stable server-generated reward ID.
- [x] Keep pure `PetCollectionData` mutation helpers for isolated deterministic data tests; they are not exposed as service-level DataStore write APIs.
- [ ] Add each approved combat/quest/interaction source through the durable reward protocol with an explicit amount, progression version, and pet-recipient policy.


### Pet activity reward contracts (2026-11-22)

- [x] Add a Studio-only API boundary test proving the legacy non-idempotent pet XP service methods are not exposed and the stable reward-ID method is the only XP write entry point.
- [x] Document server-authoritative reward invariants for the three specification sources: combat, quests, and interactions.
- [x] Explicitly separate pet progression XP from Kingdom Bond XP; existing Bond interaction XP must not be treated as progression XP.
- [x] Record open decisions without inventing values: XP curve/amounts, deterministic recipient policy, combat contribution/anti-farming rules, and interaction repeat/cooldown policy.
- [ ] Implement source-specific reward validation and durable event/outbox integration after each source's gameplay event model exists.
- [ ] Approve reward amounts, progression curve, and pet recipient policy before enabling live XP issuance.
- [ ] Execute the new API boundary test in Roblox Studio.


### Pet interaction hardening (2026-11-22)

- [x] Harden server interaction request validation: bounded safe pet IDs and finite non-negative safe-integer expected revisions.
- [x] Harden the pure interaction mutation with the same pet ID contract.
- [x] Test that interaction grants Bond XP but never pet progression XP.
- [x] Test exact cooldown boundary, rapid repeat rejection, and clock rollback rejection.
- [x] Test that an interaction mutates only the selected pet in a multi-pet collection.
- [x] Keep unsupported `feed` requests rejected until food inventory and cost rules are specified.
- [ ] Design species personality/preferences only after the approved pet roster and behavior matrix are finalized.
- [ ] Execute interaction tests and RemoteFunction/DataStore behavior in Roblox Studio.


### First player-facing UX correction pass (2026-11-22)

- [x] Construction catalogue selection and placement preview are now separate actions.
- [x] Add close control and shared modal ownership between construction and pet collection.
- [x] Apply viewport-aware construction panel sizing and compact action buttons.
- [ ] Verify construction workflow, collection/building handoff, and 375 px/touch layouts in Roblox Studio.
- [ ] Continue with gathering onboarding/interaction feedback, pet world presence, and per-action cooldown feedback.


### Pet interaction cooldown feedback (2026-11-22)

- [x] Show a lock and live MM:SS countdown on both interaction buttons while the server-owned per-pet cooldown is active.
- [x] Use the saved lastInteractionAt timestamp and synchronized server time for presentation; server remains authoritative for acceptance.
- [x] Restore normal button labels and enabled state automatically when cooldown reaches zero.
- [x] Keep the same cooldown rule for pet/play because the data contract currently defines one shared per-pet interaction cooldown.
- [ ] Verify timer synchronization and button behavior in Roblox Studio, including selection changes and rapid interaction attempts.


### Gathering onboarding feedback (2026-11-22)

- [x] Add floating labels to wood/stone resource nodes with explicit reward values.
- [x] Clarify the wood interaction as Срубить дерево and show the amount gained.
- [x] Show a first-wood hint while the wallet has zero wood.
- [x] Keep resource markers hidden during node cooldown.
- [ ] Verify first-time gathering on desktop and mobile in Studio.
- [ ] Replace placeholder tree/ore models with curated production assets.


### Pet companion grounding (2026-11-22)

- [x] Calculate the vertical ground lift from each companion's actual model pivot and bounding-box bottom.
- [x] Remove the hard-coded universal 0.28-stud offset so imported center-pivot meshes do not sink into or float above the island.
- [x] Add a Studio test using a 4-stud external mesh stand-in with a centered pivot.
- [ ] Verify actual imported pet assets, slopes, obstacles, streaming, and multiplayer presentation in Roblox Studio.


### Pet companion obstacle navigation (2026-11-22)

- [x] Detect obstacles in the companion's direct lane at two body heights.
- [x] Request asynchronous PathfindingService routes only when direct movement is blocked.
- [x] Follow computed waypoints and re-evaluate when the path is blocked or the goal moves.
- [x] Project path start/goal and waypoints to island ground; preserve each pet's measured ground lift.
- [x] Wait rather than clipping through obstacles while a route is pending or unavailable.
- [x] Release path connections and invalidate stale path computations when routes clear or controllers are destroyed.
- [x] Add smoke coverage for the clear-route fast path and path connection cleanup.
- [ ] Verify obstacle detours, stairs, slopes, cliffs, narrow passages, streaming, multiplayer, and mobile in Roblox Studio.

### Companion navigation recovery safety (2026-11-22)

- [x] Fix Luau lexical declaration ordering for the horizontal direction helper used by obstacle raycasts.
- [x] Keep owner distance separate from navigation waypoint distance so a blocked or pending path cannot suppress teleport recovery.
- [x] Invalidate pending path computations and disconnect blocked-path listeners after owner teleport recovery.
- [x] Add a Studio client regression scenario for teleporting while path computation is pending.
- [ ] Run the updated companion tests and actual wall/stair/slope navigation scenarios in Roblox Studio.

### Companion formation responsiveness (2026-11-22)

- [x] Remove duplicate interpolation that applied smoothing alpha twice to pet translation and caused excessive lag during turns and formation rearrangement.
- [x] Calculate catch-up animation from owner formation distance rather than a nearby path waypoint; avoid walking animation when a blocked path holds the companion in place.
- [x] Add a Studio regression case checking a single exponential interpolation step using a safe, isolated stand-in mesh.
- [ ] Run the new Luau tests and inspect formation turns, obstacles, cliffs, and mobile framerate in Roblox Studio.

### Companion terrain-edge safety (2026-11-22)

- [x] Sample ground support along direct companion routes so clear horizontal raycasts cannot send a pet through a cliff edge or large height discontinuity.
- [x] Recheck navigation waypoints for streamed-out ground or steep steps before moving, and retry pathfinding after a blocked terrain segment.
- [x] Project emergency teleport recovery onto the local ground surface using the pet-specific pivot offset.
- [x] Add Studio-only cliff-gap regression test using isolated test geometry.
- [ ] Run the companion tests in Roblox Studio and verify real island edges, stairs, slopes, streaming, and mobile performance.

### Companion navigation frame-budget pass (2026-11-22)

- [x] Add a 0.12-second cache for direct obstacle+ground checks while companion and formation target move less than 0.5 studs.
- [x] Recompute direct route immediately on significant target or pet movement; expire cached results rapidly to detect streamed/dynamic obstacle changes.
- [x] Clear cached positions after emergency teleport recovery.
- [x] Add Studio regression tests for stationary cache reuse and owner-movement invalidation.
- [ ] Execute client tests and profile raycasts at 30/60 FPS with 1-3 equipped companions in Roblox Studio/mobile.

### Unified player-facing modal ownership (2026-11-22)

- [x] Connect quest journal and island expansion panels to the existing `PlayerGui.PetKingdomsActiveModal` ownership convention.
- [x] Connect kingdom overview to shared modal ownership, keeping it mutually exclusive with construction and pet collection.
- [x] Close quest/expansion/kingdom panels by Escape; add click/tap-outside dismissal to quest/expansion/pet collection panels.
- [x] When a second major panel opens, hide the previous one instead of layering several backdrops and close buttons.
- [ ] Verify keyboard, mouse and touch close controls and one-window-only behavior in Roblox Studio.
- [ ] Rework viewport constraints for narrow screens (especially 320-375 px) and conduct a real responsive UI pass.

### Small viewport dialog sizing (2026-11-22)

- [x] Make quest journal and island expansion panel widths follow the actual viewport with bounded minimum/maximum dimensions.
- [x] Apply a shared proportional UIScale to each fixed-height dialog on short viewports rather than allowing its bottom/close controls to overflow.
- [x] Keep modal panels centered when the screen dimensions change.
- [ ] Test portrait devices (320×568, 375×667, 390×844) and short landscape windows in Roblox Studio Device Emulator.
- [ ] Rework the pet collection two-column mobile layout and the building action area separately.

### Mobile pet collection and compact placement mode (2026-11-22)

- [x] Fix pet cooldown UI helper declaration so its local Pet/Play button references exist before the function is defined.
- [x] On viewports narrower than 650 px, show a full-width pet list and separate full-width pet detail tab rather than unusably narrow desktop columns.
- [x] Selecting a pet automatically opens its detail tab on mobile; provide explicit list/detail navigation buttons.
- [x] Reflow mobile search, filters, and scrolling list; compact detail text offsets on short screens and fit the deletion confirmation within the viewport width.
- [x] Collapse the building catalogue during preview placement, retaining only a compact rotate/confirm/cancel action bar and close button.
- [x] Restore the full catalogue when placement ends; support resize of both modes.
- [ ] Validate 320 px/375 px portrait, landscape, mobile touch and native Roblox insets in Studio Device Emulator.
- [ ] Verify placement controls do not cover terrain target and that cooldown controls work when choosing another pet.

### Replaceable gathering visual assets (2026-11-22)

- [x] Support optional approved wood/stone Model templates in `ServerStorage/ResourceNodeModels` without changing gathering economy or node persistence.
- [x] Preserve existing procedural fallback when approved templates are absent.
- [x] Remove executable/template prompt content from resource art, and create the gameplay prompt on a trusted invisible anchor.
- [x] Restore original mesh transparency after gathering cooldown rather than making all parts opaque.
- [x] Add Studio-only world contract checks for a temporary custom resource template and trusted prompt.
- [ ] Curate and approve actual tree/ore assets with source/license/review; no third-party model imported in this pass.
- [ ] Execute Roblox Studio resource respawn, gathering, art pivot and streaming tests.

### Construction confirmation position safety (2026-11-22)

- [x] Ignore preview pointer positions over the visible building action panel so pressing Confirm/Rotate/Cancel cannot move the selected world cell.
- [x] Freeze requested catalog ID, grid X/Z, rotation, and moving instance ID before the yielding server call.
- [x] Pause preview updates and reject duplicate confirmation or edit actions while the server submission is in progress.
- [ ] Verify the exact grid cell seen on preview matches the saved object after pressing Confirm on desktop and touch.
- [ ] Investigate GUI-inset and landscape touch coordinates in Roblox Studio Device Emulator.

### Gathering rejoin and modal-flight safety (2026-11-22)

- [x] Reject untrusted/incorrect resource prompts; the gathering handler now only accepts the server-owned `GatherPrompt` under the invisible `GatherAnchor` directly inside an authorized resource node.
- [x] Add Studio integration checks for persisted resource cooldown: a rejoined player's tree starts hidden, the gather prompt is disabled, the invisible anchor remains hidden, and custom mesh alpha is preserved for later respawn.
- [x] Preserve an in-flight construction request when another modal takes focus, then close construction cleanly when its server response returns.
- [ ] Execute these tests in Roblox Studio and verify cooldown expiry, resuming resource availability, and multiple clicks/touch switches while a build request is pending.

### Resource respawn regression and repeated build receipts (2026-11-22)

- [x] Clear completed building request IDs even when the user switches to another window during the server response; preserve IDs only for explicitly retriable response codes.
- [x] Use immutable submitted catalog/moving instance fields to render build confirmation feedback, avoiding mutable UI state after yielding.
- [x] Extract resource visibility transitions into `ResourceNodeVisibility` so hide/restore behavior can be tested independently of persistence and live player sessions.
- [x] Add Studio-only repeat-cycle test verifying original translucent resource alpha, permanently invisible `GatherAnchor`, noncolliding parts and enabled/disabled prompt and markers.
- [ ] Execute all Studio tests and verify live 60-second respawns, rejoin, multiplayer, and touch-based duplicate submissions.
