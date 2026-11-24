# Pet Kingdoms — Roadmap

> Rule: deliver the approved MVP in order. No scope expansion before 1.0. A task is DONE only when the implementation is in this repository and its relevant verification has passed.

> Verification boundary: the current GitHub Actions workflow only runs a Rojo place build and uploads the `.rbxlx` artifact. It does **not** execute any Roblox Studio test scripts. A green CI run is a build check only; every Studio-only contract/integration test and manual runtime journey remains NOT DONE until its Output/result is observed in Studio.

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
- [ ] Replace or explicitly deprecate non-idempotent XP reward entry points before gameplay reward callers are introduced; use stable reward IDs for retryable sources.


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


## Owner-requested improvements — Stage 1: Interface & usability

- [x] Harden shared modal coordinator: deterministic peer-window closure, protected close callbacks, explicit focused-window query, and true close-all recovery.
- [x] Route Escape only to the focused top-level window across Island Expansion, Quest Journal, Pet Collection, and Island Building; preserve nested pet-delete confirmation as the first Escape target.
- [x] Add a Studio-only ModalManager smoke suite for focus transfer, peer closure, CloseAll, focus query, and unregister behavior.
- [ ] Execute `ModalManagerTests.client.lua` in Roblox Studio with `RunPetKingdomsStudioTests = true`.
- [ ] Runtime-test every modal-to-modal transition, interrupted close/reopen tweens, Escape behavior, and close-all while requests are pending.
- [ ] Finish the remaining Stage 1 items (visual consistency, icon coverage, mobile layout audit, and full usability regression) before starting Stage 2.

Implementation status above is source/CI status only; no Roblox Studio runtime test is claimed as passed.


### Stage 1 — Responsive UI follow-up (2026-11-23)

- [x] Make Kingdom Overview fit narrow phone widths and short landscape viewports; remove the 300 px minimum-width overflow risk.
- [x] Move construction selection actions below the pending-operation recovery panel when both are visible on compact screens.
- [ ] Audit Pet Collection at 320–375 px and short landscape; verify no clipped controls or unusable two-column regions.
- [ ] Audit Quest Journal, Island Expansion, Resource HUD, and floating buttons for short screens and safe-area collisions.
- [ ] Run touch/device tests in Roblox Studio. Latest source CI: overview change passed (`45139077658`); overlap fix CI pending (`45139112446`).


### Stage 1 — Pet Collection mobile UX (2026-11-23)

- [x] Replace narrow two-column pet collection layout with full-width list and a separate pet-detail view on screens under 650 px.
- [x] Add a clear back-to-list action; preserve desktop/tablet two-column layout.
- [x] Bound delete-confirmation width to the viewport and enlarge compact touch actions.
- [ ] Test portrait widths 320/360/390 px, short landscape, scroll restoration, empty states, delete confirmation, and orientation changes in Roblox Studio.
- [ ] Continue responsive audit of Quest Journal, Island Expansion, Resource HUD, and floating controls.

Source implementation complete; Roblox Studio/device validation remains pending. CI: first mobile-flow build passed (`45139318637`); follow-up build for confirmation sizing `45139348449` was in progress when recorded.


### Stage 1 — Quest Journal mobile UX (2026-11-23)

- [x] Add a real refresh button to match the existing timeout/error recovery instructions.
- [x] Give compact quest cards a vertical layout with wrapped descriptions and separated progress/tracking controls.
- [x] Bound quest tracking requests with the shared 12-second RequestRunner.
- [x] Prevent tracked quest names from overflowing the HUD and rebind responsive sizing when CurrentCamera changes.
- [ ] Test portrait widths 320/360/390 px, short landscape, long text, tracking timeout/retry, refresh/loading states, HUD clipping, and orientation changes in Roblox Studio.
- [ ] Continue responsive audit of Island Expansion, Resource HUD, and floating controls.

Source implementation complete; Studio/device validation pending. CI `45139613564` passed; follow-up spacing CI `45139635202` was in progress at the time of this entry.


### Stage 1 — Island Expansion responsive preview UX (2026-11-23)

- [x] Adapt panel sizing/typography to narrow and short screens; avoid fixed 250 px minimum width on very narrow viewports.
- [x] Increase refresh touch target to 44 px and prevent long dimension values from overflowing.
- [x] Rebind viewport listener when CurrentCamera changes.
- [x] Clarify that this screen currently previews geometry only; purchase is not implemented by the existing read-only remote.
- [x] Validate preview dimensions and required fields before calculating/rendering the expanded area.
- [ ] Studio test 320/360/390 px portrait, short landscape, missing island, malformed payload, max level, and preview cleanup on close/modal switch.
- [ ] Continue Stage 1 audit with Resource HUD and remaining floating controls.

Source changes are in main; CI runs `45139857411` and `45139876120` were pending at the time of this entry. Roblox Studio/device validation remains outstanding.


### Stage 1 — Resource HUD responsive layout (2026-11-23)

- [x] Keep four resource counters in one row on desktop and use a 2×2 grid on compact screens.
- [x] Add a tighter layout for screens below 360 px and truncate long values/labels safely.
- [x] Move kingdom-bond status and gather toast below the taller mobile resource bar.
- [x] Rebind viewport updates safely when CurrentCamera changes.
- [x] Bound initial wallet snapshot request with RequestRunner (12-second timeout) and preserve retry/backoff.
- [ ] Studio test 320/360/390 px portrait, desktop, gather toast, long balances, bond status, respawn/camera replacement, and push update ordering.
- [ ] Continue Stage 1 audit of floating controls, safe-area collisions, and full visual consistency.

Source implementation committed as `da22105`; CI `45140354173` was in progress at the time of this entry. Roblox Studio/device validation remains outstanding.


### Stage 1 — Floating controls and safe zones (2026-11-23)

- [x] Audit persistent launcher placement across Pet Collection, Island Expansion, Quest Journal, and Build.
- [x] Fix the compact/touch collision between Pet Collection and Island Expansion launchers by assigning separate vertical slots.
- [x] Normalize compact launcher touch sizes: Pet Collection 52×52, Island Expansion 52×52, Quest Journal 50×50; keep Build launcher 154×48.
- [x] Keep quest launcher on the opposite edge and preserve Roblox safe GUI inset for top controls.
- [ ] Test simultaneous launcher visibility and touch hitboxes at 320/360/390 px portrait and short landscape, including safe-area/notch and construction/tracked-quest collisions.
- [ ] Complete full Stage 1 visual consistency, icon coverage, and in-Studio mobile regression before moving to Stage 2.

Source commits: `5fbb21e`, `8061fb1`. CI: `45142089887` and `45142096293` passed. Studio/device validation remains pending.


### Stage 1 — Shared visual language, buttons and cards (2026-11-23)

- [x] Add reusable circular launcher style with semantic gold/mint/rose accents.
- [x] Apply shared launcher style to Pet Collection, Island Expansion, and Quest Journal.
- [x] Replace bespoke Build launcher styling with shared gold action-button style.
- [x] Apply shared action-button styling to Quest Journal tracking control; shorten active label to `СЛЕЖУ` for compact readability.
- [x] Keep existing shared close-button, modal-card, pet-action, expansion-refresh, and building-action styling intact.
- [ ] Standardize status badges, empty/error/loading states, and typography/spacing in remaining screens.
- [ ] Complete in-Studio visual regression at desktop and 320/360/390 px mobile sizes before Stage 1 sign-off.

Source commits: `7d55e84`, `fd8ea0b`, `15ffb44`, `6227204`, `5927d19`, `87bab50`, `7f35991`. CI passed through quest tracking style commit (`45142944796`); latest label shortening CI pending. Studio/device validation remains outstanding.


### Stage 1 — Global status notifications (2026-11-23)

- [x] Make global toast notifications fit narrow screens without a 220 px forced minimum width.
- [x] Adapt toast text/icon sizing and constrain width to the active viewport.
- [x] Rebind resize updates safely when CurrentCamera changes; update existing visible toasts.
- [ ] Studio test long Russian messages, 320/360 px portrait, toast stack overflow, modal overlap, and camera replacement.
- [ ] Standardize per-panel status/empty/loading states and complete icon/typography audit.

Source commit `ba8b302`; CI `45147513350` was running at documentation time. Studio/device validation remains outstanding.


### Stage 1 — Empty, loading and error states (2026-11-23)

- [x] Add reusable shared styling for empty-state labels/cards.
- [x] Distinguish empty pet collection, empty favorites/team filters, and no search matches with contextual Russian guidance.
- [x] Add a dedicated empty Quest Journal state and handle payloads whose rows all fail validation.
- [x] Remove duplicate global error toasts when the same recoverable error is already shown inside Island Expansion or Quest Journal.
- [ ] Complete visual consistency for loading/success/error states in remaining panels and iconography.
- [ ] Run Studio/device regression at desktop and 320/360/390 px mobile before Stage 1 sign-off.

Source commits: `8d5a194`, `11c51cb`, `019647a`, `f7cf87a`, `122e4d1`, `5bd1493`, `040f1eb`, `fe0d5b2`, `1ab6c6c`, `99a40be`, `29b1ac2`. CI passed for all empty-state changes and Island Expansion notification cleanup; Quest Journal notification cleanup `45149320803` was pending. Studio/device validation remains outstanding.


### Stage 1 — Loading and action result feedback (2026-11-23)

- [x] Add a shared, race-safe transient button feedback helper for success/error/warning states.
- [x] Show inline success/retry feedback on Quest Journal tracking.
- [x] Show success/error/informational feedback on Island Expansion refresh without misleading retry copy.
- [x] Preserve original button state after feedback and protect against stale delayed resets.
- [x] Keep building confirm/demolish on existing loading + idempotent recovery flow rather than flashing feedback on controls that are torn down after completion.
- [ ] Audit remaining actions for meaningful inline result feedback, then complete iconography/typography and desktop/mobile Studio regression.

Source commits: `3f7b6a7`, `84450d3`, `9856117`, `e70029a`. CI passed for helper, Quest Journal, and initial Expansion integration; latest label adjustment run `45150128088` was pending. Studio/device validation remains outstanding.


### Stage 1 — Icon tokens and compact typography (2026-11-23)

- [x] Centralize common interface symbols in frozen `InterfaceTheme.Icons` tokens.
- [x] Apply shared icon tokens to pet collection, quest journal, island expansion, building controls, and shared close buttons.
- [x] Improve readability of resource labels on regular/tiny screens (9/8 px), quest tracking actions (12 px minimum), quest metadata (10 px), and pet metadata (10 px).
- [x] Use shared confirmation icon for completed quest rows.
- [ ] Audit remaining ad-hoc symbols and state/loading icon consistency.
- [ ] Complete desktop and 320/360/390 px mobile visual regression in Roblox Studio before Stage 1 sign-off.

Source commits: `0bbf4f0`, `1606f79`, `9d3a189`, `c553373`, `cc7dd65`, `c5fa285`, `b8fc05a`, `2392b1c`, `34920b9`. Icon-token CI passed; typography CI runs `45151960757`, `45151969028`, `45151976802` were pending at documentation time. Studio/device validation remains outstanding.


### Stage 1 — Final UI cleanup and icon migration (2026-11-23)

- [x] Remove redundant corner/stroke creation before shared launcher and action-button style helpers.
- [x] Move remaining Pet Collection favorite/lock/bunny glyphs and Build rotate glyph to `InterfaceTheme.Icons`; add shared Bunny token.
- [x] Static audit: no `TextScaled=true`, no TODO/FIXME/HACK or legacy AI attribution comments in the primary UI scripts.
- [ ] Align Resource HUD palette/typography with shared `InterfaceTheme`.
- [ ] Finish spacing/overflow audit and run desktop + 320/360/390 px mobile regression in Roblox Studio before Stage 1 sign-off.

Source commits: `639d343`, `a9fcfe5`, `3d6cd07`, `742be87`, `a32852e`, `035659b`, `a43e98f`, `996901c`. Cleanup CI passed through commit `a32852e`; latest build `45152892961` was pending. Studio/device validation remains outstanding.


### Stage 1 — Resource HUD shared theme migration (2026-11-23)

- [x] Replace Resource HUD's duplicate base palette with `InterfaceTheme.Colors`.
- [x] Use shared typography tokens for resource amounts, labels, gather feedback, kingdom-bond label, and responsive sizes.
- [x] Use shared radius tokens and shared Build icon token.
- [x] Preserve per-resource semantic accent tints and existing responsive grid layout.
- [ ] Finish cross-screen overflow/spacing audit and complete Roblox Studio desktop/mobile regression before Stage 1 sign-off.

Source commit: `bce0786`. CI `45153168859` was running at documentation time. Studio/device validation remains outstanding.

### Stage 1 — Building controls compact-screen and camera lifecycle pass (2026-11-23)

- [x] Rebind the construction panel's viewport listener when Workspace.CurrentCamera is replaced; disconnect the previous camera listener to avoid stale updates and accumulated connections.
- [x] Shorten the demolition action label to УДАЛИТЬ on compact screens while retaining ДЕМОНТИРОВАТЬ on wider layouts, preventing the action text from competing with the reduced touch-button width.
- [x] Keep the selection action labels synchronized when a building is selected after the initial viewport layout.
- [x] Run the Roblox place build and upload the Studio-ready artifact successfully (GitHub Actions run 45192511163).
- [ ] Verify at 320/360/390 px portrait, short landscape, and desktop in Roblox Studio; include camera replacement and selection/move/demolish actions.
- [ ] Continue the cross-screen overflow/spacing audit. Stage 1 remains open until Studio/device regression is completed.

Source commit: c332695. Roblox Studio/device verification has not been performed.

### Stage 1 — Pet Collection, Quest Journal and Expansion responsive audit (2026-11-23)

- [x] Reflow the Pet Collection detail pane into a vertical compact layout on phones; suppress secondary pet-interaction controls that previously collided with bond/equip controls.
- [x] Add a shorter-screen layout for compact/landscape viewports and reduce action labels to fit narrow touch buttons.
- [x] Keep pet detail selection synchronized with search and active filters; show a dedicated no-match state instead of stale details for a filtered-out pet.
- [x] Prevent Quest Journal title/subtitle from running underneath refresh/close controls; use compact labels on narrow screens.
- [x] Prevent Island Expansion title from colliding with its close control; use a compact title on narrow screens.
- [ ] Run CI/static validation for all latest UI commits.
- [ ] Verify Pet Collection search/filter/sort/equip/favorite/lock/delete and modal interactions at 320/360/390 px portrait and short landscape.
- [ ] Verify Quest Journal tracking, scrolling, tracker HUD and header controls at narrow widths.
- [ ] Verify Expansion preview, modal transitions, and floating launchers on phone/tablet/desktop.
- [ ] Complete Roblox Studio/device visual regression; Stage 1 remains open until runtime verification is done.

Source commits: e94ec80, bb89e36, e91d298, ddc4ab5, 94f5570. Studio/device verification remains outstanding.

### Stage 1 — Resource HUD overflow and final mobile panel pass (2026-11-23)

- [x] Ensure long Kingdom Bond stage/status text truncates within the responsive HUD pill instead of overflowing into adjacent UI.
- [x] Keep the resource HUD responsive two-row layout and separate toast/bond positions on compact screens.
- [x] CI passed for Pet Collection compact layout commits `348a47d`, `99410fd`, `e94ec80`, and `bb89e36`.
- [ ] Complete CI for subsequent Pet Collection filter synchronization, Quest Journal/Expansion header changes, and Resource HUD truncation (runs queued/in progress at documentation time).
- [ ] Complete Roblox Studio runtime verification at desktop, 320/360/390 px portrait, and short landscape; check modal stacking, safe areas, touch targets, scrolling, and camera replacement.
- [ ] Close Stage 1 only after Studio/device regression and visual review.

Source commits: `348a47d`, `99410fd`, `e94ec80`, `bb89e36`, `e91d298`, `ddc4ab5`, `94f5570`, `b9626d6`. Studio/device verification remains outstanding.

### Stage 1 — Pet preview search performance (2026-11-23)

- [x] Avoid recreating the 3D pet preview model on every search keystroke; refresh the detail pane only when the selected pet actually changes. Server-driven collection mutations still refresh the detail explicitly.
- [x] CI passed for the combined UI changes through Expansion header commit `94f5570` (run `45195330456`, Studio-ready place artifact uploaded).
- [ ] Complete CI for Resource HUD truncation and preview-search optimization (runs queued at documentation time).
- [ ] Perform Studio/device runtime regression before Stage 1 sign-off.

Source commit: `0404d0d`; preceding successful build commit: `94f5570`.

### Stage 1 — Live-play feedback fixes: responsive UI, modal layering, icons and gathering (2026-11-23)

- [x] Lower the building ScreenGui display order below collection, expansion and quest modals so the persistent build launcher cannot cover open windows.
- [x] Hide the build launcher while construction/move mode is active; restore it when placement mode closes or cannot start.
- [x] Add viewport-based scaling and compact text sizing to construction controls; provide explicit touch placement instructions.
- [x] Replace emoji-only launcher/catalogue/resource symbols that rendered as missing-glyph squares with compact supported symbol tokens.
- [x] Keep the resource HUD retrying its initial server snapshot until the island profile is ready instead of stopping after six attempts.
- [x] Add visible “ДЕРЕВО +3” and “КАМЕНЬ +2” world markers to gathering nodes; hide markers during node cooldown and restore them on respawn.
- [x] Publish active-modal changes from ModalManager and hide the tracked-quest HUD whenever any modal window is open, preventing it from covering Quest Journal, Pet Collection or construction.
- [x] Scale compact launcher, header, filter, tracker and touch-control typography for Pet Collection, Quest Journal and Island Expansion.
- [x] Refresh building catalogue, controller and gathering documentation to match the code that is actually present, including six building entries, server-owned costs, move/demolish and gathering amounts.
- [x] CI passed for the main runtime fixes through Quest Journal overlay commit `f9f394e` (run `45198607456`).
- [ ] CI for the ModalManager event smoke-test update `6471a44` is queued.
- [ ] Verify that the new glyph set renders on Windows desktop, Roblox mobile and console; replace any remaining unsupported symbols with actual image assets if needed.
- [ ] In Roblox Studio, verify the build preview is visible and follows mouse/touch, tap-to-place works, confirmation charges the correct price, and all six entries create persisted structures.
- [ ] Verify 320/360/390 px portrait, short landscape, desktop, safe areas, modal close buttons, click-outside dismissal, Escape, and no floating HUD overlap.
- [ ] Verify initial resource values appear before gathering; test both Wood nodes (+3 each) and Stone nodes (+2 each), including 60-second respawn.
- [ ] Stage 1 remains open until the owner confirms the Studio/device checks; CI build success alone is not visual/runtime acceptance.

Source commits: `6dafbf3`, `5bfb83d`, `5af9026`, `3ac8ff6`, `ff679e8`, `8b12c58`, `7f09c81`, `42fae44`, `8193c20`, `acdaa62`, `86f1c15`, `e282612`, `f9f394e`, `7f09c81`, `6471a44`. Runtime verification in Roblox Studio remains outstanding.

### Stage 1 — Construction preview visibility (2026-11-23)

- [x] Add an always-on-top green/red Highlight outline to the client-only building silhouette so valid and invalid placement targets are readable against grass.
- [x] Keep the silhouette visible at stronger opacity when a cell is selected; hide the outline when the pointer is not over the player's island.
- [ ] CI for preview outline commit `a05df7a` is queued.
- [ ] Verify in Roblox Studio that the selected house/prop silhouette is visibly rendered and follows mouse/touch before pressing confirm.

### Stage 1 — Live-play follow-up: placement visibility and modal launchers (2026-11-23)

- [x] Show an initial visual-only building preview in the nearest unoccupied grid cell when placement/move begins; still require a deliberate world tap/click to lock the position before confirming.
- [x] Re-seed the preview when a catalogue selection changes and the position has not been locked.
- [x] Keep the last preview visible when hovering the construction controls instead of raycasting through the panel.
- [x] Reduce construction tray height from 228 to 198 UI pixels on narrow screens, including 54 px catalogue cards and responsive action placement.
- [x] Prevent a completed quest tracker from reappearing after any other modal closes.
- [x] Hide all four floating launch buttons (build, pets, quest journal, expansion) whenever the shared ModalManager reports an open window; restore them when all windows are closed.
- [x] Rojo CI build passed for the initial placement preview and compact construction tray commit `df5d5e5` (run `45240345153`).
- [ ] Complete Rojo CI on the later quest tracker and global-launcher visibility changes.
- [ ] Run owner-visible Roblox Studio tests of initial preview, taps and clicks, mobile tray, backdrop dismissal, Escape and modal transitions. **Code/build checks do not substitute for visual acceptance.**
- [ ] Replace temporary text glyphs with verified image-backed icons in the final asset pass.
- [ ] Keep Stage 1 open until all screenshots' regressions are verified on 320/360/390 px portrait, landscape and desktop.

Source commits: `df5d5e5`, `828abc4`, `0ddfbf8`, `12fb285`, `33b7522`, `7c9ce96`.

### Stage 1 — Reliable backdrop dismissal on mouse and touch (2026-11-23)

- [x] Add explicit pointer hit-testing to Quest Journal, Island Expansion and Pet Collection while each is the active modal. Mouse/touch outside the visible panel closes it, independently of the backdrop button's Activated event.
- [x] For Pet Collection, an outside tap dismisses its nested deletion confirmation first without issuing the destructive action. A later outside tap can close the collection itself.
- [x] Preserve existing close-button, Escape and modal-switch behavior. Building placement still uses world taps for selecting cells, rather than treating an outside tap as a dismissal.
- [x] CI passed for the previous floating-launcher visibility fixes through commit `7c9ce96` (run `45240532154`).
- [ ] Confirm CI for the new backdrop-detection changes (`5bb6df5`, `00be4a4`, `652290e`).
- [ ] Verify outside-tap, touch-confirmation, panel-interior interaction, and close control on 320/360/390 px and desktop in Roblox Studio.
- [ ] Do not mark Stage 1 done without in-game visual and input checks.

### Stage 1 — Backdrop input correction (2026-11-23)

- [x] Confirmed CI success for all three pointer-bound backdrop handlers (5bb6df5, 00be4a4, 652290e).
- [x] Removed competing shade.Activated close handlers from Quest Journal, Pet Collection and Island Expansion. Noninteractive labels, frames and cards nested inside the backdrop could otherwise trigger unintended closure via the ancestor TextButton.
- [x] Retained explicit mouse/touch panel-bound hit testing for dismissal outside the visible panel, close buttons and Escape handling.
- [x] Kept the nested Pet Collection deletion confirmation non-destructive when dismissing it with a background tap.
- [ ] CI validation for the handler-removal commits bb90b70, 5f56397, e4c15e8.
- [ ] Runtime acceptance in Roblox Studio: tapping empty space inside a modal must keep it open; tapping outside must close it. Verify close X, Escape, switching modals and touch/desktop at 320/360/390 px plus landscape.
- [ ] Stage 1 cannot be marked complete based solely on code/CI.

### Stage 1 — Mobile modal layout pass (2026-11-24)

- [x] Island Expansion: replace the scaled desktop layout on compact screens with a dedicated shorter layout; reposition title, subtitle, current/next cards, values, status and refresh button; preserve 36–40 px close/refresh targets.
- [x] Island Expansion: use 306 px panel on very short screens, 330 px on short screens and 390 px on regular screens; keep the compact composition at UIScale 1 instead of shrinking all controls.
- [x] Quest Journal: introduce compact 320/350/380 px panel heights for very short/short/regular mobile viewports; reflow title, subtitle, close/refresh buttons, scroll list and status area.
- [x] Quest Journal: retain a scrollable task list in the compact layout and keep the footer status outside its scroll region.
- [x] CI passed for Island Expansion mobile reflow commit a12deca (run 45349952553).
- [ ] CI validation for Quest Journal mobile reflow commit f047713 (run 45349998429).
- [ ] Verify both screens in Roblox Studio at 320×568, 360×640, 390×844, short landscape and desktop; check title/button collisions, scroll reachability, readable text and tap targets.
- [ ] Continue mobile layout pass for Pet Collection and construction tray after verifying these two modal layouts.
- [ ] Do not close Stage 1 until runtime/device acceptance is confirmed.

### Stage 1 — Pet Collection mobile safe-area layout (2026-11-24)

- [x] Bound the compact collection panel to the actual viewport height with a predictable 16 px top/bottom safe margin; cap tall-phone panel height at 620 px and avoid a percentage-height panel on short landscape screens.
- [x] Keep the panel centered and preserve the existing mobile list/detail navigation, search/filter row, and large action controls.
- [x] Adjust the mobile collection title size for very narrow screens.
- [x] CI passed for Quest Journal compact reflow (f047713, run 45349998429) and Island Expansion compact reflow (a12deca, run 45349952553).
- [ ] CI validation for Pet Collection safe-area commit ca8872b (run 45350278164).
- [ ] Verify list/detail navigation, preview visibility, favorite/lock/equip/delete actions and scroll behavior on 320×568, 360×640, 390×844 and short landscape.
- [ ] Continue with construction panel mobile reflow and final image-backed icon replacement; Stage 1 remains open pending Roblox Studio/device verification.

### Stage 1 — Construction tray mobile refinement (2026-11-24)

- [x] Reduce the compact construction tray height to 190 px and anchor it closer to the bottom safe area.
- [x] Preserve usable touch controls by limiting compact UIScale reduction to very short viewports; ordinary phone screens use full-size controls.
- [x] Reduce catalogue card width to 106/112 px on compact screens so more entries are visible while retaining horizontal scrolling to all six entries.
- [x] Reduce compact catalogue scrollbar thickness and adjust card typography for very narrow screens.
- [ ] CI validation for construction tray refinement commit 7b08295 (run 45350460447).
- [ ] Verify all six cards can be tapped and horizontally scrolled on 320/360/390 px screens; confirm rotate/place/cancel remain reachable and do not overlap.
- [ ] Verify building preview tracks touch and mouse, invalid cells are rejected, and successful placement persists in Studio.
- [ ] Stage 1 remains open pending device/runtime checks and final icon asset replacement.

### Stage 1 — Live placement rotation feedback (2026-11-24)

- [x] Route both the on-screen rotate button and PC R key through one placement-rotation handler.
- [x] Refresh the visible ghost immediately after rotation, even before a touch player has locked a target cell.
- [x] Preserve a locked placement cell when rotating and revalidate the rotated footprint; if no cell has been chosen yet, reseed the preview at the nearest free grid cell.
- [x] Confirm the compact construction tray CI passed (7b08295, run 45350460447).
- [ ] CI validation for immediate rotation feedback commit 07791bf.
- [ ] Verify touch rotate updates the silhouette before confirmation; verify invalid rotated footprints become red and cannot be submitted.
- [ ] Verify the full six-entry place/move/cancel/save flow in Roblox Studio; Stage 1 remains open.

### Stage 1 — Touch-drag building placement (2026-11-24)

- [x] Add a drag gesture for touch placement: after the finger moves beyond the tap threshold, the local building ghost follows the finger across the player's island.
- [x] On release, validate and lock the final cell only when the footprint is valid; invalid/out-of-island targets remain unconfirmable.
- [x] Preserve tap-to-place for short stationary touches and keep two-finger gestures blocked from selecting world cells.
- [x] Preserve the existing guard that ignores touches beginning on interactive UI controls.
- [x] Confirm CI passed for immediate placement-rotation feedback (07791bf, run 45350635172).
- [x] CI passed for touch-drag placement commit 4d3cd46 (run 45351087149).
- [ ] Verify on a real touch device: tap selection, drag preview, release-to-lock, rotate after drag, invalid footprint rejection, two-finger camera gestures and UI-originated gestures.
- [ ] Verify server confirmation, resource deduction and persistence after a successful drag placement; Stage 1 remains open.

### Stage 1 — Touch placement guidance (2026-11-24)

- [x] Update the mobile construction hint to explain the actual interaction: drag the ghost with one finger, or tap free grass; release over a valid cell to lock placement.
- [x] Update move-mode hint to explain that an existing building can be dragged to a new location or repositioned by tapping free grass.
- [x] Document the touch-drag control alongside tap-to-place in BUILDING_CLIENT_CONTROLLER.md.
- [ ] Verify the touch gesture on a physical device; CI confirms the project builds but cannot simulate Roblox touch input.
- [ ] Verify resource spending, server commit, world model sync and rejoin persistence for each of the six catalog entries.

### Stage 1 — Starter gathering/building economy contract (2026-11-24)

- [x] Add a Studio-only cross-system contract test for the starter wallet, canonical wood/stone node rewards and all six building catalog entries.
- [x] Verify the intended first-build path in the test: starter wallet (2 wood/1 stone) cannot afford the pet house; gathering one wood node (+3) and one stone node (+2) makes its 5 wood/2 stone cost affordable.
- [x] Verify every priced starter building can be afforded after the starter gathering loop and a failed pet-house spend does not partially deduct either resource.
- [x] Explain the actual gathering controls and rewards when construction is rejected for insufficient resources.
- [x] Document the two wood nodes, two stone nodes, independent 60-second cooldown and starter pet-house progression in BUILDING_CLIENT_CONTROLLER.md.
- [ ] CI validation for economy contract test commit f938f1e and missing-material guidance commit fd30e19.
- [ ] Studio runtime verification: trigger each of the four gathering prompts, confirm HUD balances/toasts, wait for respawn, rejoin during cooldown, and confirm the saved timer/reward.
- [ ] Studio runtime verification: place all six catalog entries, confirm exact costs are deducted once, and verify buildings plus balances persist after rejoin.

### Stage 1 — Full island persistence round-trip coverage (2026-11-24)

- [x] Extend the dedicated Studio/DataStore integration test to persist and reload a representative placed main house, exact rotated grid coordinates, all four resource balances, level-1 expansion bounds, resource-node cooldown, and the building idempotency receipt.
- [x] Assert the expanded building coordinates remain the shifted grid coordinates (x=5, z=5) and the expanded plot remains 18×18 after reload.
- [ ] CI validation for expanded persistence integration test commit 4f3cf84.
- [ ] Run IslandStoreTests in a dedicated Roblox test universe with Studio API access; the test writes a synthetic DataStore key and must not be treated as a live-user save test.
- [ ] Run IslandWorldServiceTests in Studio to confirm persisted building records are rendered into the regenerated island world.
- [ ] Manual end-to-end test: build, gather, expand, leave, rejoin, and compare structures/resources/positions/cooldowns.

### Stage 1 — Restored island cooldown world-state checks (2026-11-24)

- [x] Extend the Studio island-world lifecycle test with a persisted wood-node cooldown.
- [x] Assert island spawn restores the node's AvailableAt timestamp, hidden visual state and disabled ProximityPrompt.
- [x] Assert a world refresh after expansion does not accidentally respawn/re-enable a node whose saved cooldown is still active.
- [ ] CI validation for persistence round-trip commit 4f3cf84 and world cooldown restoration test commit b314415.
- [ ] Execute the DataStore round-trip test in a dedicated Roblox test universe and the world lifecycle test in Studio.
- [ ] Complete manual build/gather/expand/leave/rejoin verification before closing the persistence stage.

### Stage 1 — Safe persistence test opt-in and manual checklist (2026-11-24)

- [x] Gate synthetic DataStore writes behind Workspace attribute `RunIslandStoreIntegrationTests`; ordinary Studio play runs input-contract checks only and skips synthetic profile writes.
- [x] Add `docs/testing/ISLAND_PERSISTENCE_TESTING.md` with dedicated-test-universe setup, safe Studio test steps, and a manual leave/rejoin acceptance journey.
- [ ] CI validation for test gating commit cb6a737 and persistence test guide commit f4485c7.
- [ ] Run the gated integration scenario only in an isolated test universe; never point synthetic tests at production player data.
- [ ] Execute the full manual journey and record the observed result before marking island persistence DONE.

### Stage 1 — Restored gathering marker visibility (2026-11-24)

- [x] Fix island generation so a resource node restored during cooldown also disables its BillboardGui gathering marker; previously the model and prompt were hidden but the floating marker could remain visible.
- [x] Extend the island-world lifecycle test to assert the restored cooldown hides the gathering marker as well as the resource model and prompt.
- [ ] CI validation for runtime fix commit 729e3ad and regression test commit cff57f7.
- [ ] Verify visually in Studio: rejoin while a node is cooling down; no floating gathering label should remain until the node respawns.

### Stage 1 — Full building catalogue persistence coverage (2026-11-24)

- [x] Expand the DataStore round-trip fixture from one house to all six current catalogue types: main house, pet house, stone path, garden lantern, flower bed and wooden fence.
- [x] Assert every saved catalogue ID survives reload and the expected grid positions are shifted correctly by island expansion.
- [ ] CI validation for all-six-building persistence test commit 2e2ceb2.
- [ ] Run the isolated DataStore integration test and verify all six records survive a load/save/load cycle.

### Stage 1 — Building upgrade persistence integrity (2026-11-24)

- [x] Validate optional saved `upgradeLevel` against the server-owned building catalogue; legacy records without the field remain valid and use level 1 at render time.
- [x] Reject fractional levels, values below 1, levels above the building's maximum and upgrade levels on catalog entries that do not support upgrades.
- [x] Add data-contract coverage for valid and invalid saved upgrade levels.
- [x] Extend the DataStore round-trip fixture so the pet house's level-2 upgrade survives profile reload.
- [ ] CI validation for data validation commit 306227e, data tests commit 500565e and persistence test commit b0f2635.
- [ ] Run Studio data tests and the isolated DataStore integration scenario.
- [x] Update `docs/testing/ISLAND_PERSISTENCE_TESTING.md` to include all six building types, the pet-house level-2 upgrade, and the hidden gathering marker during cooldown.
- [ ] CI validation for the latest persistence/data-validation changes; current GitHub Actions runs are queued and have not started.

### Stage 1 — Restored building upgrade runtime state (2026-11-24)

- [x] Extend the island-world lifecycle fixture with a level-2 pet house.
- [x] Assert initial island spawn exposes the persisted `UpgradeLevel = 2` attribute on the rendered pet-house model.
- [x] Assert island refresh after expansion preserves that same upgrade level.
- [ ] Run the Studio world lifecycle test to verify restored building upgrade state in the actual Roblox runtime.
- [ ] CI validation for world regression test commit 9a29c5f.
 
### Stage 1 — Quest state persistence round-trip (2026-11-24)

- [x] Extend the legacy-profile fixture to omit introductory quest progress and tracked-quest selection; assert session claim migrates safe defaults.
- [x] Persist non-default progress for both introductory quests and a non-default tracked objective in the DataStore round-trip fixture.
- [x] Assert quest counters and tracked objective survive save/load and are present in the next claimed session.
- [ ] CI validation for quest persistence test commit 2d772a5.
- [ ] Execute the gated DataStore integration test in a dedicated Roblox test universe; Studio runtime verification remains required.
 
### Stage 1 — Isolated persistence test cleanup (2026-11-24)

- [x] Wrap the gated DataStore integration scenario so the synthetic island profile is removed after both success and assertion failure.
- [x] Fail the test explicitly if synthetic-record cleanup cannot be confirmed; never silently accumulate test profiles.
- [ ] CI validation for cleanup commit 519a9be.
- [ ] Verify the cleanup path in the dedicated test universe with Studio API access enabled.
 
### Stage 1 — Pet collection DataStore round-trip (2026-11-24)

- [x] Add an opt-in Studio integration test against the dedicated `PetKingdoms_PetCollections_v1` store.
- [x] Verify owned pet identity/species/rarity, XP, bond state, favorite/lock flags, equipped order and acquisition receipt survive reload.
- [x] Verify a newer collection writer generation fences out the previous writer.
- [x] Check the synthetic key is empty before use and remove it after success or assertion failure.
- [x] Document safe contract tests, isolated DataStore setup and the manual player journey in `docs/testing/PET_COLLECTION_TESTING.md`.
- [ ] Rojo build validation for test commits `fea5228` and `a6f4651`; build success does not execute the Studio integration test.
- [ ] Run the pure collection contract tests in Studio.
- [ ] Run the gated DataStore integration test in a dedicated non-production test universe.
- [ ] Verify real pet spawn, collection UI, equip order and state after leaving/rejoining with a dedicated test account.
 
### Stage 1 — Companion spawn and character lifecycle (2026-11-24)

- [x] Extract server-owned equipped companion creation/cleanup into `PetCompanionSpawnService`; production still uses the approved `PetAssetLoader` only.
- [x] Rebuild the owner's formation from the saved equipped order and assign stable pet/owner/slot attributes.
- [x] Make formation rebuild idempotent: old models are removed before replacements are published.
- [x] Fence model-factory yields with a current-character/session callback; cancelled attempts destroy only models created by that attempt.
- [x] Clear the matching character's companions immediately on `CharacterRemoving`; ignore delayed removal events for an older character.
- [x] Add Studio tests for two-pet spawn order, placement, duplicate prevention, invalid-profile rejection, stale-spawn cancellation, overlapping spawn attempts, asset gate behavior and idempotent cleanup.
- [ ] Rojo build validation for commits `62a013e`, `f42d9a7`, `d9ff948`, `c7017a6`, `3388827`, `934ddca`, `fddd5d0`, and `2e00a15`.
- [ ] Run `PetCompanionSpawnServiceTests.server.lua` in Roblox Studio.
- [ ] Import and publish the original Bunny mesh in the dedicated test universe, then verify actual model spawn/follow after join, death/respawn and rejoin. Do not enable an unapproved Creator Store replacement.
 
### Stage 1 — Companion ground alignment and obstacle avoidance (2026-11-24)

- [x] Add a model-specific `GroundOffset` contract: procedural Bunny rigs expose their scaled ground clearance; imported mesh pets derive a conservative offset from their published bounding-box height.
- [x] Ground-snap the follow target using the pet's own offset rather than a hard-coded value shared by every asset.
- [x] Detect a blocked direct follow segment with a client raycast and select a short-lived lateral waypoint around the obstacle; re-check the direct route after reaching the waypoint.
- [x] Size the lateral clearance from the obstacle's oriented bounds and the pet's footprint; if both sides are blocked, do not repeatedly steer into the obstruction.
- [x] Add Studio regression coverage for wall detection, lateral clearance, ground alignment, and scale-aware ground metadata.
- [ ] Rojo build validation for commits `cfc95c6`, `5cf865d`, `8d26140`, `5cd34b4`, `01768ec`, `a0ddbd2`, `a815332`, `801a993`, `f21a69e`, `b2a3d0e`, `5e341c8`, and `eaaf464`.
- [ ] Run `CompanionFollowControllerTests.client.lua` with `Workspace.RunPetKingdomsStudioTests = true` in Roblox Studio; inspect the client Output for every PASS.
- [ ] Verify following around actual island buildings, fences, paths, ramps, and bridges with the published Bunny mesh. A single wall fixture does not prove full navigation around complex geometry.
- [ ] Verify walk/run/idle transitions, slopes, jumps, streaming gaps, death/respawn and mobile frame pacing in Studio on desktop and a physical mobile device.
- [ ] Keep the companion follow stage open until actual Studio and device acceptance is recorded.
 
### Stage 1 — Companion jump response (2026-11-24)

- [x] Detect the owner's Jumping state and trigger one short cosmetic companion hop when the pet is within follow range.
- [x] Do not retrigger during the same airborne interval; descending Freefall does not count as a new take-off.
- [x] Blend a bounded vertical arc into the normal follow target so the pet returns to its ground-snapped formation position.
- [x] Add a dedicated procedural jump pose with tucked front paws, folded hind legs, and responsive ears.
- [x] Add client follow regression coverage for take-off detection, vertical lift, no repeated hop during one airborne interval, descending-fall rejection, and landing completion.
- [x] Extend the animation smoke test to verify the jump state and limb pose.
- [ ] Rojo build validation for commits `c5d9e0b`, `c819094`, `8220ab4`, `8ed3cb1`, `b7fa15b`, `f55a906`, and `860e3fa`.
- [ ] Run `PetAnimationControllerTests.server.lua` and `CompanionFollowControllerTests.client.lua` in Roblox Studio; inspect Server and client Output respectively.
- [ ] Verify jump timing, landing height, and repeated jump behavior with the published project Bunny mesh on desktop and mobile.
- [ ] Keep companion movement Stage 1 open until Studio runtime and device checks are recorded.
 
### Stage 1 — Companion slope and ramp alignment (2026-11-24)

- [x] Sample the ground surface normal at a bounded 6–7 Hz rate instead of raycasting every rendered frame.
- [x] Smoothly orient the companion body to traversable ramp/bridge surfaces while preserving its movement-facing direction.
- [x] Keep surfaces steeper than 50 degrees on a safe upright fallback to avoid unstable wall-like rotations.
- [x] Add a Studio client regression fixture using an 18-degree ramp and assert the companion's up vector aligns with the ramp normal and remains upright on a 65-degree surface.
- [ ] Rojo build validation for commits `eff6503`, `8b2c295`, and `5a98d33`.
- [ ] Run `CompanionFollowControllerTests.client.lua` in Roblox Studio and inspect the client Output.
- [ ] Verify actual island bridges, ramps, slopes, and flat-to-slope transitions with the published Bunny mesh on desktop and mobile.
- [ ] Keep movement Stage 1 open until runtime slope, jump, obstacle, and device checks are recorded.
