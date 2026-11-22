# Pet Kingdoms — AI Handoff

 > Last updated: 2026-11-22  
> Purpose: resume work in a fresh chat without relying on conversation memory.

## Repository

- GitHub: https://github.com/DoctorStrangeSH/Pet-Kingdoms
- Default branch: main
- Repository was initially empty when first inspected on 2026-11-21.
- The first documentation baseline has been committed directly to main.

## Source of truth

Read these files first:
1. `README.md`
2. `docs/PROJECT_SPEC.md`
3. `docs/ROADMAP.md`
4. `docs/ART_BIBLE.md`
5. `docs/BUILD_AND_TEST.md`
6. `docs/ASSET_TRACKER.md`
7. `docs/game-systems/BUILDING_SYSTEM.md`
8. `docs/game-systems/BUILDING_VALIDATION_TESTS.md`
9. `docs/game-systems/ISLAND_PERSISTENCE.md`
10. `docs/game-systems/ISLAND_RESOURCE_WALLET.md`
11. `docs/game-systems/ISLAND_GATHERING.md`
12. `docs/game-systems/ISLAND_SESSION_LIFECYCLE.md`
13. `docs/game-systems/ISLAND_SESSION_LEASE.md`
14. `docs/game-systems/PET_ART_PIPELINE.md`
15. `docs/game-systems/PET_COMPANIONSHIP.md`

The repository is authoritative. If a chat message conflicts with these files, stop and reconcile the decision instead of silently changing scope.

DataStore fencing contract: after MemoryStore lease acquisition, call `IslandStore.claimSession(profile)` and use only the returned profile. It increments `sessionGeneration` atomically in the same player key only when the stored generation still matches the generation observed during load (compare-and-swap); stale loaders must be rejected. A stale nonzero-generation loader must never recreate a missing profile. Every save must preserve the claimed generation; `IslandStore.save` checks it inside the same UpdateAsync transform as the write. Never bypass `claimSession` for a live session.

## Current verified state

- [x] README and project overview committed.
- [x] Added read-only Roblox Studio Bunny import inspector: tools/roblox/InspectImportedBunny.lua.
- [x] Added manual Studio import/acceptance checklist: assets/pets/bunny/ROBLOX_STUDIO_IMPORT_CHECKLIST.md.
- [x] Received actual Studio report for `Workspace.bunny_rigged`: 108 descendants, 13 MeshParts, 7 Bones (pipeline expected 10), 13 Motor6D, 1 AnimationController, 0 Animator, 0 Humanoid, 0 scripts, 0 anchored BaseParts, 14 unanchored BaseParts, bounds 2 x 3.12 x 1.16 studs, all 13 MeshParts report `Enum.Material.Plastic`.
- [ ] Investigate why two ear bones are absent in Roblox import and why 13 Motor6D joints were generated; Blender FBX round-trip PASS does not prove Roblox rig parity.
- [ ] Owner explicitly rejected current Bunny appearance and deferred visual polish; do not present this model as production-ready or spend next milestone on more concept images. Focus on game systems while visual art is deferred.
- [x] MVP specification committed.
- [x] Scoped roadmap committed.
- [x] Art direction baseline documented.
- [x] Building system design baseline documented.
- [x] Rojo project mapping and initial Luau source module committed.
- [x] Server and client bootstrap entrypoints committed.
- [x] Server-owned starter building catalog committed.
- [x] Pure server-side placement validator committed.
- [x] Studio-only placement validator smoke-test script committed.
- [x] Studio-only GridMath smoke-test script committed.
- [x] Versioned island profile schema/validation module committed.
- [x] Persistent island resource wallet added (Wood/Stone/Gold/Gems); existing schema-v1 profiles migrate during claim.
- [x] Server-only IslandResourceService supports validated grant/spend with atomic balance checks and rollback on non-writable sessions.
- [x] IslandWorldService spawns two Wood (3 each) and two Stone (2 each) nodes per personal island; IslandGatheringService validates owner, ancestry, range and rewards, then disables nodes for 60 seconds before respawn. Bootstrap starts the gathering service. Studio multiplayer verification pending.
- [x] Added `IslandResourceHUD.client.lua`: four-resource HUD, initial server snapshot request, authoritative wallet update RemoteEvent, and localized gathering reward toast. Responsive width handling is implemented; phone/tablet safe-area and Studio playtest pending.
- [x] Added provisional server-owned construction costs for Pet House, Stone Path, Garden Lantern, Flower Bed, and Wooden Fence; Main House remains free. New placements charge through `IslandResourceService.spend`; moves are free. Placement rollback uses atomic `grantMany`; catalog costs are shown in the client and insufficient resources are localized. Values are provisional, no final balance approval; Studio transaction/failure testing pending.
- [x] Added `BuildingCatalogEconomyTests.server.lua` for catalog price/resource contracts (Studio execution pending).
- [ ] Durable transaction journal and demolition refund policy remain open.
- [x] Added first layout-derived Kingdom Bond progression: 10 provisional points per distinct non-Main-House building type, with four stages (Quiet/Cozy/Blooming/Thriving); duplicate types do not grant extra points. Score is derived from saved buildings, not client input or a farmable separate currency.
- [x] IslandWorldService replicates Bond attributes, tints the grass, and creates stage decorations on spawn and after building sync/demolition; stage decor is rebuilt idempotently and keyed to the derived stage, not raw building count.
- [x] Resource HUD displays Bond stage, points, and next threshold.
- [x] Added KingdomBondTests.server.lua and docs/game-systems/KINGDOM_BOND.md (Studio execution and visual verification pending).
- [ ] Pet/quest/farming contributions, final thresholds, rewards, and production stage art are not implemented.
- [x] Added IslandResources and IslandData wallet contract tests; Studio execution pending.
- [x] Studio-only IslandData smoke-test script committed.
- [x] Revision-aware IslandStore DataStore adapter committed.
- [x] IslandStore input-contract smoke test committed.
- [x] DataStore session-generation fencing implemented; Studio integration scenario committed (execution pending).
- [x] Fixed PlayerRemoving failure recovery: final save failures remain in a leaving-session retry path; after autosave succeeds, the service releases the MemoryStore lease and cleans up the island world/spawn slot. Forced-failure Studio integration verification remains pending.
- [x] Procedural island blockout renderer committed and integrated into player session lifecycle; Studio verification pending.
- [x] Character routing to the personal island arrival pad implemented for initial spawn and respawn; Studio verification pending.
- [x] Server-authoritative building place/move/demolish RemoteFunction implemented with idempotency, profile/world rollback, server-generated IDs, and per-player token-bucket rate limiting; Studio verification pending.
- [x] First client `main_house` construction controller implemented with local grid preview, rotate, confirm/cancel, and server-authoritative commit; Studio/device verification pending.
- [x] Runtime fallback blockout Models added for `main_house` and `pet_house`; production art remains NOT STARTED.
- [x] Minimal client catalogue added for `main_house` and `pet_house`; selected ID is sent to server-authoritative placement. Studio/device verification pending.
- [x] Server-authoritative demolition added for non-main-house buildings with client selection, explicit second-press confirmation, and rollback on non-writable session; Studio verification pending.
- [x] Client move mode added with server-authored building metadata, selected instance ID, preview, rotate, confirm/cancel, and authoritative profile/world transaction; Studio/device verification pending.
- [x] Client placement/move preview now checks island bounds and replicated building footprints for immediate overlap feedback; server remains authoritative; Studio verification pending.
- [x] Starter decor catalogue adds `stone_path`, `garden_lantern`, `flower_bed`, and `wooden_fence` with 1×1 footprints, fallback blockout models, responsive catalogue cards, and existing server-authoritative placement/move/demolition/persistence path; Studio verification pending.
- [x] First procedural Bunny rig factory committed with 17 Motor6D joints, AnimationController/Animator, follow/ground attachments, and scale validation; added eye highlights, split mouth, forehead tuft, and six whiskers using WeldConstraints without changing the 17-joint rig. Factory tests cover the new details; Studio smoke test not yet executed. This remains a primitive-geometry blockout, not production mesh art.
- [x] Procedural Bunny animation controller committed with idle, walk, run, happy, curious, sniff, alert, and combat states; Studio smoke test covers sniff pose but is not yet executed.
- [x] `CompanionFollowController` now triggers randomized idle personality moments (sniff, curious look, happy hop) while stationary; walking/running cancels the action. Client smoke test checks that an idle companion eventually performs an action; Studio execution pending.
- [x] Client `CompanionFollowController.lua` committed with three formation slots, ground raycast, smooth follow/orientation, and idle/walk/run state mapping; client Studio smoke test committed but not yet executed.
- [x] First responsive Russian `PetCollectionUI.client.lua` committed with owned-pet list, search, Bunny viewport preview, equipped count, and server-backed equip/unequip; Studio/device verification pending.
- [x] Server pet collection backend committed: separate DataStore, default starter Bunny, owned/equipped validation, max three equipped, `Get`/`Equip` RemoteFunction, and expected-revision conflict rejection. Pure data tests committed; Studio DataStore execution pending.
- [x] Server collection service attempts to load equipped models through `PetAssetLoader` and maintains the per-player folder lifecycle. Current Bunny catalog `assetId` is nil, so it returns `ASSET_NOT_CONFIGURED` and no model spawns. Verify actual spawn/respawn/equip after a production asset is approved and configured.
- [x] Client `PetCompanionRuntime.client.lua` binds replicated local-owner models to `CompanionFollowController` and destroys controllers on pet removal/character lifecycle. Studio runtime verification is pending.
- [x] Island persistence contract documented.
- [x] Player island profile lifecycle service committed and started from server bootstrap.
- [x] Per-player save serialization and deep snapshot cloning committed.
- [x] IslandStore detects rejected UpdateAsync writes without relying on a nil outer result.
- [x] Final-save failure retains the in-memory session for shutdown retry.
- [x] Island session lifecycle limitations and configuration documented.
- [x] IslandSessionService contract smoke test committed.
- [x] Placement validation test plan documented.
- [x] Build/live-sync instructions documented.
- [ ] Rojo build executed and verified.
- [ ] Roblox source project initialized beyond the initial scaffold.
- [ ] Roblox Studio place file created and verified.
- [ ] Owner reviewed the selected hybrid Rojo + Studio workflow.
- [ ] Placement validator and GridMath smoke tests executed in Roblox Studio.
- [ ] IslandStore tested against a live Roblox DataStore in Studio.
- [ ] Player lifecycle executed and verified in Roblox Studio with live DataStore access.
- [x] MemoryStore cross-server coordination lease implementation committed and integrated (Studio/multi-server verification pending; not a DataStore fencing guarantee).
- [x] IslandLeaseService integration smoke test committed (exclusive acquire, owner renew/release, stale token rejection, release/reacquire, invalid type rejection).
- [x] IslandData rejects unknown building IDs in unlock records.
- [x] IslandData rejects sparse/dictionary building lists and profiles exceeding the 256-record defensive ceiling; Studio tests committed.
- [ ] Save concurrency, UpdateAsync rejection, MemoryStore lease, and DataStore fencing verified in Roblox Studio.
- [x] Add DataStore-side fencing/session generation checked atomically in every profile write (Studio integration test committed; execution pending).
- [ ] End-to-end building placement, charging, and persistence implemented.
- [x] Original Bunny OBJ/MTL source committed: 15,332 vertices, 30,194 triangles, 13 named objects, 9 material groups. Rejected Creator Store candidate 92070521355583 is removed from runtime catalog.
- [x] Blender 4.2+ rig/export script `assets/pets/bunny/build_bunny_rig.py` and `RIG_PIPELINE.md` committed and executed in Blender 4.2.0 CI. Generated `.blend`/`.fbx` pass structural round-trip validation with 10 bones and four keyed actions. Roblox Studio import reported only 7 Bones and Plastic-only material enum; owner rejected the visual result. Do not treat this Bunny as production art or enable it in the runtime catalog.
- [ ] Import and review the original OBJ/MTL in Roblox Studio, publish to the experience, set the project-owned asset ID, and verify mesh appearance/follow/animations.
- [ ] Production 3D assets, final pet rigs, animation clips, and gameplay systems implemented. Current Bunny source/FBX is a rejected visual draft; procedural Part-based Bunny is a test blockout only. Neither is approved production art.

Important: concept art generated in chat is visual reference only. It is not a production model or integrated game asset.

## Product decisions to preserve

- MVP target: 20 pets.
- Up to 3 active companions.
- Pet max level: 50.
- Five core pet stats: Health, Attack, Defense, Speed, Critical Chance.
- All six rarity tiers can reach level 50.
- Evolution is post-MVP.
- First biome: Green Valley with Meadow, Deep Forest, Crystal Creek, Ancient Grove, Wildflower Hills.
- Kingdom Bond changes the island's appearance.
- Monetization must not create pay-to-win advantages.
- Build in the approved MVP order; do not add unrelated systems before 1.0.

## Next action

The technical lead selected hybrid Rojo + VS Code + Roblox Studio as the recommended project workflow. The building preview now gives immediate client-side overlap feedback; server validation remains authoritative. Owner review is still pending. Next:
1. Run a Rojo build from the repository root and fix any mapping errors.
2. Run `IslandDataTests.server.lua` and `IslandLeaseServiceTests.server.lua` in a dedicated Studio test universe with MemoryStore API access.
3. Open the generated place in Roblox Studio and verify the project tree.
4. Review the `UpdateAsync` transform behavior and run the stale/equal-revision integration test in a dedicated Studio test universe.
5. Run `PlacementValidatorTests.server.lua`, `GridMathTests.server.lua`, and `IslandDataTests.server.lua` in Studio; record the actual Output results.
6. Set Workspace attributes `IslandGridWidth` and `IslandGridDepth` from the approved island plot layout; do not guess dimensions.
6a. Run `KingdomBondTests.server.lua`; in Studio place one, three, and six non-Main-House objects, then move and demolish them. Verify stage, grass tint, stage decoration count, HUD threshold, rejoin restoration, and per-player ownership. Confirm no duplicate `KingdomBondDecor` folders appear.
7. Review `docs/game-systems/ISLAND_PERSISTENCE.md` and `docs/game-systems/ISLAND_SESSION_LIFECYCLE.md`; test the lifecycle in a dedicated Studio test universe with API access enabled.
8. Review `docs/game-systems/ISLAND_SESSION_LEASE.md`; run `IslandLeaseServiceTests.server.lua` and `IslandStoreTests.server.lua` in a dedicated test universe with MemoryStore and DataStore API access; verify stale-generation rejection, expiry takeover, throttling/outage, and shutdown across two Studio servers.
9. Configure `IslandGridWidth`, `IslandGridDepth`, `IslandGridCellSize`, and `Workspace/IslandSpawnPoints` per `docs/game-systems/ISLAND_WORLD_RENDERING.md`; run `IslandWorldServiceTests.server.lua` and visually verify two player islands, initial/respawn character arrival, saved building pivots, missing templates, and spawn-slot release.
10. Follow `docs/game-systems/BUILDING_TRANSACTIONS.md`; create a test `main_house` Model, invoke `ReplicatedStorage/Remotes/PlaceBuilding` as a real Studio player, and verify place/move, idempotency, rejection, rollback, and rejoin persistence.
11. Follow `docs/game-systems/BUILDING_CLIENT_CONTROLLER.md`; run the LocalScript in Studio, verify preview/raycast/rotation/confirm/cancel, and test at 375 px plus a real touch device.
9. Add a server transaction layer for resource charging and placement mutation only after economy prices are approved.
10. Add remotes with server-side rate limiting and idempotency; never expose client-trusted prices or footprints.
11. Add save/load recovery tests after persistence behavior is implemented.
12. Force a DataStore final-save failure during PlayerRemoving, then restore DataStore access and verify autosave retry succeeds, the MemoryStore lease releases, the world is destroyed, and the spawn slot is reusable; also force lease-release failure and verify cleanup retries safely.
13. Run `PetModelFactoryTests.server.lua`, `PetAnimationControllerTests.server.lua`, `PetCollectionDataTests.server.lua`, and client `CompanionFollowControllerTests.client.lua` in Roblox Studio; inspect Bunny motion, affection/play reactions, and formation from the Green Valley gameplay camera.
13. Verify PetCollectionUI Get/Equip in a published Studio test universe with DataStore access; test PC, tablet, and touch layouts.
14. Run Studio integration verification for server spawn replication, client follow, equip/unequip, character death/respawn, and three-pet formation. Fix any visual/physics lifecycle issues before marking the companion runtime complete.
15. Update ROADMAP and this handoff after each verified milestone.

## Working rules

- Make real repository changes; never present design concepts as implemented features.
- Update ROADMAP with DONE / NOT DONE and verification notes.
- Prefer small, testable, modular changes.
- Do not store live Roblox Instances in DataStores; persist validated compact data.
- Server validates economy, ownership, placement, rewards, and progression.
- Keep PC and mobile in scope from the start.


## Pet collection responsive layout (2026-11-22)

- Pet collection UI now subscribes to the active camera ViewportSize and re-applies responsive panel sizing when the viewport changes.
- The UI rebinds this listener when Workspace.CurrentCamera is replaced and disconnects the previous camera listener to avoid stale subscriptions.
- Studio verification remains pending: resize desktop window, rotate a touch device, and replace CurrentCamera while the panel is open.

## Pet collection request hardening (2026-11-22)

- Equip and Interact now share a server-side one-second per-player mutation rate limit to prevent repeated DataStore writes; read-only Get remains unrestricted by this mutation limiter.
- Mutation limiter state is cleared on PlayerRemoving.
- Studio multiplayer spam testing and verification that normal UI interactions remain responsive are pending.

## Latest pet companionship hardening (2026-11-22)

- Per-pet Bond progression is bounded: level 1–10, 50 XP per level, maximum stored XP 450. Interactions at max level remain allowed but cannot increase XP beyond the cap.
- `PetCollectionData.validate` rejects fractional/negative/over-cap XP, fractional interaction timestamps, and stored Bond levels that do not match the XP-derived level (`BOND_LEVEL_XP_MISMATCH`).
- Legacy pet records with all Bond fields absent remain valid and normalize to XP 0 / level 1 / timestamp 0 when cloned.
- Added pure tests for XP/level mismatch, fractional XP/timestamps, over-cap XP, max-level interaction cap, and invalid fractional action timestamps.
- Pet collection UI now has localized messages for cooldown, request throttling, stale revision, unavailable DataStore, and collection loading errors.
- Roblox Studio execution, live DataStore behavior, multiplayer, and PC/touch visual verification are still NOT DONE. Run `PetCollectionDataTests.server.lua` in Studio before marking the companionship loop complete.


## Pet collection data validation hardening (2026-11-22)

- `PetCollectionData` now uses one finite, non-negative integer validator for profile revision, pet acquisition timestamps, and last interaction timestamps. NaN, positive/negative infinity, and fractional timestamps/revisions are rejected.
- `PetCollectionDataTests.server.lua` now covers infinite/NaN revisions, infinite/fractional acquisition timestamps, and infinite/NaN interaction timestamps.
- These are committed Studio tests; they have not been executed in Roblox Studio in this session.
- The existing per-pet Bond interaction loop is distinct from the approved pet Level progression. Actual pet Level (maximum 50), gameplay XP, core stats, skills, equipment, and ability progression remain unimplemented. Do not invent the XP curve or rarity balance while those rules remain unspecified.
- Visual/model work is deferred to the owner. Keep code and systems work within the approved MVP; do not generate or replace pet art.


## Companion follow performance pass (2026-11-22)

- `CompanionFollowController` now creates one `RaycastParams` per controller and reuses it for ground projection instead of allocating a new filter object on every RenderStepped update.
- The cached exclusion filter contains the pet model and the target character, so the ground ray continues to ignore both.
- This is a small allocation reduction for each active companion (up to three); it does not change follow distances, formation, movement smoothing, or ground offset.
- Roblox Studio verification is still required for terrain, slopes, water, respawn, and mobile performance.


## Companion spawn race protection (2026-11-22)

- `PetCollectionService.spawnEquippedPets` now assigns a unique per-player token for every spawn request.
- After waiting for `HumanoidRootPart` and after each potentially yielding `PetAssetLoader.create`, the task verifies that its token is still current and the same character is active.
- A stale task destroys any model it just loaded and exits instead of parenting it into the player's folder. This prevents delayed CharacterAdded/equip tasks from reintroducing obsolete or duplicate companion models.
- PlayerRemoving clears the current token, invalidating in-flight tasks; a reconnect receives a new token that cannot collide with an older task.
- Verify rapid respawn + equip changes, slow asset loading, and PlayerRemoving during asset loading in Roblox Studio. No Studio execution was performed in this code pass.


## Pet Bond numeric validation hardening (2026-11-22)

- `PetCollectionData.interact` now uses the shared finite non-negative integer validator for its server-supplied timestamp. Negative, fractional, NaN, and infinite values are rejected before any profile clone or mutation.
- Persisted Bond XP and Bond level now use the same strict integer validators, rejecting NaN/Infinity as well as out-of-range/fractional values.
- Added Studio tests for negative/fractional/NaN/infinite interaction timestamps and non-finite Bond XP/level values.
- This closes a gap where positive infinity could pass the pure interaction timestamp check and only be rejected later by full profile validation.
- Roblox Studio execution remains pending.


## Pet progression data foundation (2026-11-22)

- Per-pet records now support optional `level` and `xp` fields. New starter records default to level 1 and 0 XP.
- Validation accepts levels 1–50 only and requires XP to be a finite non-negative integer. There is intentionally no XP cap because the approved XP curve/threshold table is not yet defined.
- `PetCollectionData.clone` normalizes legacy records that lack both fields to level 1 / 0 XP. The fields are optional in validation to keep existing DataStore records loadable without a schema-version bump.
- Added Studio tests for level 50, zero/over-cap/fractional levels, negative/fractional/NaN/Infinity XP, and legacy normalization.
- This is a storage/validation foundation, not a playable progression system: no XP awarding, level-up calculation, stat values, rarity multipliers, skills, or equipment behavior has been added.
- Do not implement XP thresholds or base stat values until they are approved in the project spec.


## Trusted pet XP reward API (2026-11-22)

- Added `PetCollectionData.grantExperience(profile, petId, amount)`: validates the existing profile, requires an owned pet and a positive finite integer amount, increments only the pet's ordinary `xp`, and increments collection revision. Bond XP/level are untouched.
- Added `PetCollectionService.grantExperience(player, petId, amount)`: server-module API that persists the reward through the pet collection DataStore `UpdateAsync`, validates the saved result, and refreshes the in-memory profile.
- This API is deliberately not wired to any RemoteEvent/RemoteFunction. Client payloads cannot choose reward amounts through this method. Future combat/quest/interaction server systems must derive the amount from trusted server state and call this API directly.
- XP thresholds, level-up calculation, source-specific amounts, reward idempotency policy, and actual gameplay callers remain open/not implemented. Do not award XP from the existing client-triggered collection interaction until an approved reward value and anti-replay policy are defined.
- Added Studio pure-data tests for valid reward, revision increment, level/Bond isolation, invalid amount (zero/fractional/NaN/Infinity), and unowned pet rejection. Tests are committed, not executed in Studio.


## Pet collection snapshot ordering (2026-11-22)

- Added `syncProfileIfNewer` in `PetCollectionService`. Mutation responses from Interact, Equip, and trusted XP rewards update the in-memory collection only when their persisted revision is at least as new as the current snapshot.
- This handles the case where DataStore `UpdateAsync` commits writes in order but yielding server callbacks resume in a different order; a late older response can no longer roll the in-memory cache back.
- Initial profile loading still assigns the loaded profile directly before mutation requests are available.
- Verify overlapping Equip/Interact/XP reward calls in Roblox Studio and confirm the in-memory revision never decreases. Studio verification remains pending.


## Latest pet collection response snapshots (2026-11-22)

- Equip and Interact now return `cloneForClient(state.profile)` after revision-aware synchronization, rather than blindly returning the individual DataStore response.
- A request that completes late can therefore no longer send a stale profile revision back to the UI after a newer concurrent mutation has already updated the in-memory snapshot.
- Equip still respawns from the current in-memory profile after synchronization.
- Verify overlapping Equip/Interact/XP calls from multiple client requests in Studio; UI should converge to the greatest revision and not display rolled-back equipped IDs or Bond values.


## Companion interaction animation priority (2026-11-22)

- Fixed a state-priority bug in `CompanionFollowController.update`: player-triggered `happy`/`curious` reactions now override autonomous `sniff`/`curious`/`happy` idle personality moments while the companion is stationary.
- Walk/run states remain higher priority, so an affection/play reaction does not freeze or replace movement animation.
- Added client Studio smoke assertions for interaction-over-idle priority and movement-over-interaction priority.
- Studio execution remains pending.


## Pet progression integer precision guard (2026-11-22)

- Added `PetCollectionData.MAX_SAFE_INTEGER = 9007199254740991` (2^53 - 1), the largest integer exactly representable by Luau's number type.
- The shared non-negative integer validator now rejects counters/timestamps above this bound, including ordinary pet XP and collection revision.
- `interact`, `setEquipped`, and trusted `grantExperience` reject a mutation when the collection revision cannot be incremented safely (`REVISION_OVERFLOW`).
- `grantExperience` returns `XP_OVERFLOW` if the resulting XP would exceed safe integer precision; rewards above the bound are rejected as invalid amounts.
- Added pure Studio test cases for the boundary, unsafe values, XP overflow, and revision overflow in all three mutation paths. Studio execution remains pending.


## Pet mutation input validation (2026-11-22)

- Added a shared `validateMutationProfile` guard and call it before any profile field access in `interact`, `setEquipped`, and `grantExperience`.
- Nil, non-table, malformed, wrong-owner, and otherwise invalid collection profiles now return a structured `INVALID_PROFILE:<reason>` result instead of risking an indexing/runtime error or partially evaluating a mutation.
- Revision overflow checks still run after profile validation, preserving the distinct `REVISION_OVERFLOW` result for valid profiles at the safe-integer boundary.
- Added pure Studio test cases for nil and malformed profiles across all mutation paths. Tests are committed but not executed in Roblox Studio.


## Pet stat schema foundation (2026-11-22)

- Added `ReplicatedStorage/Shared/Pets/PetStatsData.lua`, a pure module defining the approved stat keys: `health`, `attack`, `defense`, `speed`, and `criticalChance`.
- The module validates a resolved snapshot shape containing `level` (1–50), `rarityTier` (neutral numeric tier identifier 1–6), and all five finite non-negative stat values. It also provides a defensive clone and a copied stat-key list.
- No stat values, rarity names, growth curve, stat scaling, additive/multiplicative modifier order, equipment bonuses, or combat interpretation are invented. The module is a data-contract foundation only and is not wired into collection persistence or runtime yet.
- Added Studio-only pure tests for all six tier identifiers, level boundaries, missing/negative/NaN/Infinity stats, invalid snapshots, and clone isolation. Tests are committed but not executed in Studio.


## Pet stat schema key hardening (2026-11-22)

- `PetStatsData.validate` now requires exactly the five approved stat keys. Unknown keys (including misspelled or future unapproved stats), non-string keys, and incomplete maps are rejected with explicit statuses.
- Added regression tests for extra `mana`, numeric keys, and missing stat count. This prevents silent acceptance of typoed or client-injected stat fields while the contract is still being established.
- No balance values or runtime integration were added. Studio test execution remains pending.


## Pet stat clone safety (2026-11-22)

- `PetStatsData.clone(snapshot)` now runs the full schema validator before reading nested fields.
- Invalid input returns `nil, reason` for nil, malformed level/rarity/stat maps, or invalid stat values; valid input still returns an independent copy containing only the approved schema.
- Added tests for nil and malformed clone input. Roblox Studio execution remains pending.


## Species base-stat definition contract (2026-11-22)

- Exposed `PetStatsData.validateStats(stats)` and `cloneStats(stats)` so species definitions can reuse the exact five-stat contract without fabricating level or rarity fields.
- Added `ReplicatedStorage/Shared/Pets/PetSpeciesStatsData.lua`. It validates stable lowercase species IDs, exact definition shape (`baseStats` only), all five finite non-negative base stats, and complete catalogs. It also returns defensive copies of individual definitions and catalogs.
- No species entries, names, base values, rarity assignments, or balance formulas were added. The PROJECT_SPEC explicitly leaves the remaining species and final rarity distribution open; this is a reusable contract only.
- Added Studio-only pure tests for valid/invalid IDs, malformed definitions, extra fields, invalid base stats, empty/invalid catalogs, and clone isolation. Tests are committed but not executed in Roblox Studio.


## Data-driven PetStatsCalculator foundation (2026-11-22)

- Added `ReplicatedStorage/Shared/Pets/PetStatsCalculator.lua`. It validates a species definition, pet level (1–50), rarity tier (1–6), and a required balance resolver supplied by the caller.
- The calculator gives the resolver a defensive copy of base stats plus level and rarity, catches resolver errors, validates the returned exact five-stat map, and returns an isolated validated snapshot.
- This deliberately does not define or assume a growth curve, rarity multiplier, modifier ordering, or stat balance. Until those decisions are approved, the resolver is an explicit dependency and there is no default formula.
- Added Studio-only tests for valid identity resolution, level/rarity boundaries, missing resolver, resolver exceptions, invalid output, unknown stats, and input/result isolation. Tests are committed but not executed in Studio.
- The calculator is not yet wired to collection persistence, combat, or a concrete species catalog.


## Exact resolved pet stat snapshot contract (2026-11-22)

- Hardened `PetStatsData.validate` to reject every top-level field except `level`, `rarityTier`, and `stats`.
- This keeps identity, ownership, runtime metadata, or unapproved progression fields out of the resolved stat value object; those belong in their own domain records, not inside the stat snapshot.
- Added regression coverage for injected `ownerUserId` and missing stats. The existing five-stat exact-key validation remains unchanged.
- No balance rules or modifier semantics were introduced. Roblox Studio test execution remains pending.


## Declarative pet stat modifier contract (2026-11-22)

- Added `ReplicatedStorage/Shared/Pets/PetStatModifiersData.lua` with strict modifier records: `id`, `sourceType`, `sourceId`, `stat`, `operation`, and `value`.
- Accepted source categories are equipment, skill, and ability. Supported data operation labels are `flat` and `percent`; values must be finite and within the safe numeric range. Negative values are allowed in the data contract so future design can represent penalties.
- Modifier lists are capped at 128, must be dense arrays, reject duplicate modifier IDs, invalid array keys, malformed entries, and unknown fields. Defensive clone helpers are included.
- This is a data contract only. It does not define percentage units, operation order, stacking/refresh rules, source ownership checks, duration semantics, or how modifiers affect combat. No modifiers are applied by `PetStatsCalculator` yet.
- Added Studio-only tests for valid equipment/skill/ability records, invalid source/stat/operation/value, extra fields, duplicate IDs, sparse/invalid lists, and clone isolation. Tests are committed but not executed in Roblox Studio.


## Ordered pet stat modifier pipeline (2026-11-22)

- Added `ReplicatedStorage/Shared/Pets/PetStatModifierPipeline.lua`. It validates the base stat map and modifier list, clones inputs, and processes modifiers in their supplied list order through a required `applyModifier(currentStats, modifier, index)` callback.
- The callback is responsible for all arithmetic semantics. The pipeline does not define percent units, flat/percent ordering, stacking, caps, refresh behavior, or source ownership.
- Each callback invocation is protected with `pcall`; its complete five-stat result is validated and copied before the next modifier. Errors or invalid outputs stop the pipeline with an indexed reason. Empty modifier lists return a defensive copy without requiring a policy.
- Added Studio-only tests for empty lists, order preservation, policy output, missing policy, duplicate IDs, invalid base/result values, callback errors, unknown output stats, and reference isolation. Corrected one test assertion after reviewing its expected error prefix. Tests are committed but not executed in Roblox Studio.
- This pipeline is not yet connected to `PetStatsCalculator`, inventory/equipment, skills, abilities, or combat.


## Pet stat calculator + modifier pipeline integration (2026-11-22)

- Added `PetStatsCalculator.calculateWithModifiers(..., resolveStats, modifiers, applyModifier)`.
- The integrated entry point validates the modifier list before running any resolver, rejects a missing modifier policy when the list is non-empty, and composes the existing species/level/rarity validation with the ordered modifier pipeline.
- The base stat resolver and modifier arithmetic remain caller-supplied. No percentage interpretation, stacking rule, progression curve, or balance value is defined here.
- Added calculator tests for a successful integrated result, retained level/rarity, modified output, source immutability, missing policy, and empty-list behavior. Tests are committed but not executed in Roblox Studio.
- The calculator currently returns the existing generic resolver failure reason if an injected resolver or modifier policy throws. More granular structured errors can be added when the public error contract is finalized.


## Pet progression threshold resolver foundation (2026-11-22)

- Added `ReplicatedStorage/Shared/Pets/PetProgressionData.lua`.
- The module validates an exact 50-entry cumulative-XP threshold array: level 1 must start at 0; thresholds must be safe non-negative integers and strictly increasing; sparse, extra-key, incomplete, fractional, NaN, and infinite entries are rejected.
- `getProgress(totalXp, thresholds)` validates total XP and resolves the current level with binary search, plus XP within the level, next cumulative threshold, amount required for the next level, normalized progress, and max-level state.
- The threshold table is injected. The tests use a clearly synthetic 100-XP-per-level table solely to verify boundary behavior; this is not approved game balance and must not be reused as production configuration.
- Added Studio-only tests for level 1, below/exact/midway thresholds, level 50, malformed threshold tables, and invalid XP. Tests are committed but not executed in Roblox Studio.
- This module does not mutate collection records, award XP, save data, or emit level-up events. Existing trusted `PetCollectionService.grantExperience` continues to store XP without changing pet level until the real XP curve is approved.


## Atomic pet XP + level progression (2026-11-22)

- Added `PetCollectionData.grantExperienceWithProgress(profile, petId, amount, thresholds)`. It validates the full collection and threshold table, validates reward amount and ownership, computes new cumulative XP, resolves the level using `PetProgressionData`, and writes XP + level + one collection revision increment in the same pure mutation.
- Returns a progression summary with previous/new level, levels gained (including multiple levels from one reward), current XP within level, next threshold, normalized progress, and max-level state.
- Added trusted server-only `PetCollectionService.grantExperienceWithProgress(player, petId, amount, thresholds)`, persisted through one DataStore UpdateAsync mutation and synchronized into the in-memory collection. It is not exposed to clients.
- Thresholds remain injected from trusted server configuration. Studio tests use synthetic 100-XP steps solely to verify behavior; no production curve is approved or configured.
- Added pure collection tests for XP+level atomic mutation, multi-level gain, level 50, invalid thresholds, unowned pet, overflow, one revision increment, and Bond isolation. Tests are committed but not executed in Studio.
- Important remaining risk: the existing bounded outer DataStore retry helper can retry a call after an ambiguous network failure. Reward idempotency keys/ledger are not implemented; callers must not blindly replay the same reward after an uncertain result. Define a bounded persisted reward-idempotency policy before wiring this API to combat, quest, or interaction reward sources.
- No gameplay reward callers or client remotes were added. The legacy `grantExperience` API remains unchanged for XP-only storage when no approved threshold configuration is available.


## Pet reward idempotency receipts (2026-11-22)

- Added optional `rewardReceipts` to the pet collection profile. Legacy records without the field remain valid; clone normalizes them to an empty list. Client snapshots do not expose the ledger.
- Each receipt stores `rewardId`, `petId`, `amount`, and `processedAt`. IDs are restricted to 1–128 ASCII word/colon/underscore/hyphen characters beginning with an alphanumeric character. Receipt lists must be dense, unique by reward ID, valid, and no larger than 128.
- Added `PetCollectionData.grantExperienceWithProgressOnce(..., rewardId, now)`. It checks/prunes expired receipts and applies XP + level + receipt together in one pure mutation. A repeated ID with the same pet/amount returns `ALREADY_PROCESSED` without changing XP or revision; reusing the ID with a different pet or amount returns `REWARD_ID_CONFLICT`.
- Added trusted server-only `PetCollectionService.grantExperienceWithProgressOnce(player, petId, amount, thresholds, rewardId)`, using the same DataStore UpdateAsync retry path. A stable reward ID must be generated by the trusted server gameplay source; it must never come from a client.
- Retention is explicitly seven days, capped at 128 receipts. Expired receipts are pruned during a new reward mutation. If 128 unexpired receipts remain, new unique rewards fail closed with `REWARD_LEDGER_FULL`; no unexpired receipt is silently evicted. Therefore deduplication is guaranteed only within the seven-day retention window, and authoritative reward IDs must be stable across retries/reconnects within that window.
- Added tests for first grant, duplicate grant, receipt persistence, payload conflict, invalid ID, expiry, ledger-full behavior, duplicate stored IDs, and invalid timestamps. Tests are committed but not executed in Roblox Studio.
- No client remote, combat/quest/interaction reward caller, or production XP curve was added.


## Pet collection acquisition foundation (2026-11-22)

- Added optional `rarityTier` to owned pet records, constrained to neutral numeric tiers 1–6. Existing starter/legacy Bunny records may omit it; no rarity names, weights, or distribution were assigned.
- Added `PetCollectionData.addPet(profile, petId, speciesId, rarityTier, now)`. It validates ownership profile, current species allowlist, ID, rarity tier, timestamp, capacity (100), and duplicate pet IDs; new records start at level 1, XP 0, Bond level 1 / XP 0 and are not auto-equipped.
- Added `PetCollectionService.grantPet(player, speciesId, rarityTier, acquisitionId)` as a trusted server-module API. Pet GUID is generated server-side before the DataStore UpdateAsync callback and is never accepted from a client.
- Added a separate optional `acquisitionReceipts` ledger. Legacy profiles remain valid. Receipt IDs are stable server-generated acquisition IDs; records store the generated pet ID, species, rarity tier, and timestamp. The ledger is bounded to 128 entries and seven-day retention, pruning expired entries during a new acquisition and failing closed if all entries remain unexpired.
- Added `PetCollectionData.addPetOnce`: duplicate acquisition IDs with the same species/rarity return `ALREADY_ACQUIRED` and the unchanged collection; mismatched species/rarity returns `ACQUISITION_ID_CONFLICT`. The service caller must reuse the same acquisition ID when retrying the same egg/shop/quest grant.
- Added tests for valid acquisition, defaults, rarity, revision, duplicate pet IDs, invalid species/tier/time, capacity, duplicate acquisition, acquisition conflicts, ledger full, and receipt expiry. Tests are committed but not executed in Roblox Studio.
- Important scope boundary: the project spec defines a 20-pet MVP target but explicitly leaves the remaining species and final rarity distribution open. Current allowlist contains only Bunny. This acquisition API is infrastructure only; it does not implement eggs, roll odds, currency costs, species catalog, or a client-facing hatch endpoint. Do not invent those rules.


## Pet egg data contract (2026-11-22)

- Added `ReplicatedStorage/Shared/Pets/PetEggData.lua` as a pure reusable contract for future egg definitions. A definition contains only an ordered `entries` array of unique `speciesId` + positive integer `weight` pairs; unknown fields, unknown catalog species, duplicate species, sparse arrays, empty lists, invalid weights, and total weight above 1,000,000,000 are rejected.
- The caller supplies the current approved species catalog to validation and cloning. No species are silently added by the egg system.
- `PetEggData.roll(eggId, definition, speciesCatalog, randomValue)` performs deterministic weighted selection from a caller-supplied value in [0, 1). The production caller must obtain that value from a server-owned `Random` instance; do not accept client-provided random values.
- Added Studio-only `PetEggDataTests.server.lua` covering valid definitions, clone isolation, weighted boundaries, unknown/duplicate species, invalid weights, sparse arrays, unknown fields, invalid random values, total-weight overflow, and empty definitions. Tests are committed but not executed in Roblox Studio.
- This is deliberately not a playable hatch system: no egg definitions, drop rates, rarity weights, currency costs, economy mutations, client remotes, or hatch UI exist. The project spec leaves exact economy rates and the final 20-species/rarity distribution open. Resolve those decisions before authoring production egg tables.


## Pet hatching transaction safety (2026-11-22)

- Added `ReplicatedStorage/Shared/Pets/PetHatchingData.lua`, a pure validated transaction-record contract. Records snapshot the selected egg, species, rarity tier, currency costs, timestamp, stable transaction ID, and stable `hatch:<transactionId>` acquisition ID.
- The allowed state progression is strictly `PREPARED -> CHARGED -> GRANTED`; repeating the current state is idempotent, skipping or reversing a state is rejected. Cost snapshots are defensively cloned and restricted to known wallet currencies.
- Added Studio-only `PetHatchingDataTests.server.lua` for valid creation, stable acquisition ID, cost-copy isolation, transitions, idempotency, invalid transitions, unknown currencies, empty costs, invalid rarity, malformed IDs, overflow, and unsupported states. Tests are committed but not executed in Roblox Studio.
- Critical architecture finding: island currency is held in `PetKingdoms_Islands_v1` and mutated through the in-memory island session + autosave; pet ownership is held separately in `PetKingdoms_PetCollections_v1` and mutated through its own DataStore UpdateAsync. There is no atomic transaction spanning these stores. `IslandResourceService.spend` marks the in-memory island session dirty but does not synchronously persist the debit. Calling it followed by `PetCollectionService.grantPet` is not crash-safe.
- Therefore do NOT wire a live hatch service or client RemoteFunction yet. Before enabling paid hatching, persist the prepared hatch record and debit receipt alongside the wallet in the island profile, expose a verified durable flush/commit result, and implement recovery/reconciliation so retries with the same transaction ID complete the same species/rarity and acquisition ID without charging twice. Also define refund/terminal failure policy. The pet collection acquisition receipt is the second idempotency boundary.
- Exact egg prices, species pool, drop weights, and rarity mapping remain product decisions; no values are invented here.


## Island-profile hatch journal (2026-11-22)

- Added `IslandHatchLedgerData.lua` with pure profile-transform helpers: `prepare`, `charge`, and `markGranted`. Each returns a cloned profile; callers must persist the returned profile before acknowledging success.
- Journal records are stored in `IslandProfile.hatchTransactions`, include fixed egg/species/rarity/cost/acquisition ID and states PREPARED, CHARGED, GRANTED. New island profiles initialize an empty journal; legacy profiles may omit it.
- `charge` validates all required wallet balances before changing any, then debits all currencies and changes the journal record to CHARGED in the same returned profile snapshot. Repeated CHARGED/GRANTED requests do not debit again. Transaction ID reuse with different selected result or costs is rejected.
- Journal is validated by `IslandData.validate` and deep-cloned into island save snapshots. It is bounded to 64 records; expired GRANTED records may be pruned, but unresolved PREPARED/CHARGED records are retained and cause fail-closed behavior when capacity is exhausted.
- Timestamp validation uses the safe integer range rather than a currency cap.
- Studio-only `IslandHatchLedgerDataTests.server.lua` covers prepare idempotency, cost conflict, atomic debit, repeated debit, grant acknowledgement, insufficient funds, duplicate IDs, and invalid states. Tests are committed but not executed in Roblox Studio.
- Important limitation: these are pure profile transformations only. No service currently persists a PREPARED/CHARGED/GRANTED transition synchronously or returns a durable commit acknowledgement. Do not connect a paid hatch remote yet. Next step is a serialized IslandSessionService transaction API that durably saves each transition and recovers incomplete records before allowing new hatches.


## Durable island hatch mutation API (2026-11-22)

- Added `IslandSessionService.applyHatchOperation(userId, operation, transactionId, record?)`. Supported operations are PREPARE, CHARGE, GRANT; PREPARE requires the supplied record transactionId to match the explicit transactionId argument.
- Hatch transitions are serialized per island session with `hatchMutationBusy`. Each pure journal transform is applied without yielding, installed as the live profile, and assigned a new profile revision.
- Sessions track `persistedRevision`, initialized from the claimed profile revision and advanced only after `IslandStore.save(snapshot)` confirms the exact revision. The API loops through serialized saves until the target revision is persisted and the session is clean, with a 30-second deadline. A timeout does not roll back the in-memory journal; callers must retry using the same transaction ID, and autosave continues to retry dirty profiles.
- The save loop accounts for unrelated profile mutations that occur while a DataStore save yields: if the live revision advances beyond the saved snapshot, it stays dirty and another save is required before acknowledging the hatch operation.
- Added `PetCollectionService.isReady(player)` as a read-only readiness check for future recovery orchestration.
- No hatch remote or player-facing hatch endpoint is exposed. No production egg/cost/species definitions exist. This API is infrastructure only and still requires Studio/DataStore fault-injection verification before paid use.


## Player-join hatch recovery (2026-11-22)

- Added `PetHatchingRecoveryData.lua` as a pure decision table: PREPARED resumes at CHARGE, CHARGED resumes at GRANT, GRANTED is complete; unknown/missing states fail closed.
- Added `PetHatchingRecoveryService.lua`. Bootstrap starts it after IslandSessionService, PetCollectionService, and IslandGatheringService. It waits up to 45 seconds for both island session and pet collection readiness, then snapshots unresolved transactions from the island profile.
- PREPARED records are charged through the durable island session API. CHARGED records are granted through `PetCollectionService.grantPet` using the persisted species, rarity, and acquisitionId. Only after grant success (including ALREADY_ACQUIRED) is the island journal advanced to GRANTED.
- This safely handles a lost response after pet collection UpdateAsync: retrying the same acquisitionId returns the existing pet receipt rather than adding a duplicate.
- If collection is full or a datastore operation fails, the transaction stays PREPARED/CHARGED and is deferred; the next player join retries it. A future capacity reservation or overflow/inbox policy is required before paid hatching.
- Added Studio-only `PetHatchingRecoveryDataTests.server.lua` for all three states and invalid inputs. Tests are committed but not executed in Roblox Studio. End-to-end interruption/fault-injection tests remain NOT DONE.
- No hatch RemoteFunction, egg definitions, drop rates, prices, or player-facing hatch flow has been added.


## Pet collection capacity reservations (2026-11-22)

- Pet collection profiles now support optional `reservedAcquisitions`; legacy profiles remain valid and normalize through `PetCollectionData.clone`.
- Validation checks reservation structure, unique acquisition IDs, approved species, rarity 1–6, timestamps, dense arrays, receipt conflicts, and the hard invariant `owned + reserved <= MAX_OWNED_PETS`.
- `PetCollectionData.reservePetSlotOnce` reserves one slot idempotently. `PetCollectionService.reservePetSlot` persists the reservation through the same collection DataStore UpdateAsync path used by grants.
- Ordinary `addPet` respects reserved capacity. `addPetOnce` consumes a matching reservation before adding the pet, atomically replacing one reserved slot with one owned pet.
- `grantPet` creates and consumes a reservation in the same UpdateAsync mutation when called without a prior reservation; existing matching reservations are consumed. This protects legacy trusted grant callers from exceeding capacity.
- `PetHatchingRecoveryService` reserves capacity before CHARGE/GRANT. If the collection is full, it defers the transaction before any PREPARED transaction is charged. If already acquired, the idempotent receipt is accepted.
- Added reservation scenarios to `PetCollectionDataTests.server.lua`. Tests are committed but not executed in Roblox Studio. Multi-server concurrency and DataStore fault injection remain NOT DONE.
- Reservations are not automatically expired. A reservation must not be released while its corresponding island transaction can still be PREPARED or CHARGED. A future cancellation flow must coordinate both profiles and prove the transaction has not been charged before release.


## Pet inventory management foundation (2026-11-22)

- Pet records now persist optional `isLocked` and `isFavorite` booleans. Validation rejects non-boolean values; clone normalization defaults missing legacy values to false.
- Added pure `PetCollectionData.setPetFlags` and `PetCollectionData.removePet`.
- Deletion rejects the permanent starter pet (`starter-bunny`), any locked pet, any currently equipped pet, and the last remaining pet. A successful removal increments revision and validates the resulting profile; capacity is freed immediately.
- Added RemoteFunction actions `Protect` and `Delete`. Both require a current expectedRevision, pass through the per-player mutation rate limit, validate the persisted profile inside UpdateAsync, and return the latest safe client snapshot.
- The client snapshot uses the normalized collection clone, so lock/favorite flags are available to future UI without exposing server-only receipt/reservation ledgers.
- Added Studio-only pure data tests for protection flags, invalid flags, locked/equipped/starter/last-pet deletion rejection, successful deletion, and capacity release. Tests are committed but not executed in Roblox Studio.
- Audit fix: `grantPet` now accepts an existing matching reservation returned by `reservePetSlotOnce` and consumes it, rather than incorrectly treating ALREADY_RESERVED as a failed grant.


## Pet evolution architecture foundation (2026-11-22)

- Added `ReplicatedStorage/Shared/Pets/PetEvolutionData.lua`. It is deliberately balance-agnostic: it defines no species catalog, evolution outcomes, level gates, costs, currencies, items, or other game rules.
- Catalog entries have only three required stable identifiers: `evolutionId`, `sourceSpeciesId`, and `targetSpeciesId`.
- Validation rejects malformed identifiers, duplicate evolution IDs, self-evolution, sparse/oversized catalogs, and directed cycles. Branches and converging paths are supported.
- `getOptions(catalog, sourceSpeciesId)` returns cloned matching definitions and does not mutate the catalog.
- Added Studio-only `PetEvolutionDataTests.server.lua` for the catalog contract. Tests are committed but have not been run in Roblox Studio.
- No production evolution definitions are present; the current owned species registry still contains only `bunny`. Do not invent forms or progression requirements. Persistence, eligibility, and evolution transactions remain NOT DONE until design approves the species/form catalog and rules.


## Pet evolution transition preparation (2026-11-22)

- Extended `PetEvolutionData` with `getDefinition(catalog, evolutionId)`, which validates the catalog and returns a clone of the matching definition.
- Added `prepareTransition(definition, petRecord)`. It rejects malformed definitions/records and source-species mismatches, then returns a cloned pet record with only `speciesId` changed. The stable `petId`, rarity, level, XP, bond progress, equipped linkage, lock/favorite flags, and any future record metadata are retained.
- The function is intentionally pure and does not persist or mutate the supplied record. It is not a production evolution endpoint.
- Added Studio-only tests for stable ID, preservation of progression and protection metadata, no mutation of the source record, invalid source, malformed record, and unknown evolution ID. Tests are committed but have not been executed in Roblox Studio.
- Important blocker confirmed in `PetCollectionData.lua`: the authoritative `VALID_SPECIES` registry currently contains only `bunny`. No target form is approved or accepted by persisted collection validation. Do not create a production evolution transaction or invent a target species until game design approves the first form and updates the registry.


## Pet identity ledger hardening (2026-11-22)

- `PetCollectionData.addPet` now rejects a petId found in the retained `acquisitionReceipts` ledger with `PET_ID_ALREADY_USED`. This prevents a deleted pet's identity from being reused while its acquisition receipt remains retained.
- The ledger remains bounded and applies the existing receipt-retention policy; this is not a permanent lifetime tombstone guarantee. Do not claim permanent identity retirement until the retention/capacity policy is explicitly redesigned.
- Added a regression test that grants a pet through `addPetOnce`, removes it, and verifies that `addPet` cannot recreate the same petId.
- Test source is committed but not executed in Roblox Studio.


## Pet acquisition ledger capacity audit (2026-11-22)

- Critical issue found: `reservePetSlotOnce` previously reserved a collection slot but not an acquisition-receipt ledger slot. Since `addPetOnce` could later fail with `ACQUISITION_LEDGER_FULL`, a hatch could be charged while its pet grant became impossible if other acquisitions filled the bounded ledger in between.
- Fixed by counting retained acquisition receipts plus all pending reservations before accepting a new reservation. The invariant is `retained acquisition receipts + pending acquisition reservations <= MAX_ACQUISITION_RECEIPTS`.
- Current policy supersedes this historical note: reservation prunes only acknowledged acquisition receipts after seven days from `completedAt`; receipts without a durable completion acknowledgement never expire.
- `addPetOnce` accounts for all other pending reservations while consuming the matching reservation and receipt slot atomically.
- The direct `addPet` pet-ID reuse guard now respects the same retention window: an ID is blocked while its acquisition receipt is retained, but not forever after expiry.
- Added regression tests for reserving the final receipt slot, refusing another pending hatch, consuming the reserved receipt slot, pruning expired receipts, and allowing pet-ID reuse after expiry.
- Tests are committed but have not been run in Roblox Studio. Multi-server concurrency and DataStore failure injection remain NOT DONE.
- Additional cache consistency fix: when `grantExperienceWithProgressOnce` returns `ALREADY_PROCESSED`, it now validates and synchronizes the current DataStore snapshot into the in-memory cache if its revision is newer. A duplicate reward retry can therefore still refresh stale local state without applying XP twice.
- Audit note: `PetCollectionService.grantExperience` and `grantExperienceWithProgress` are non-idempotent trusted APIs. They have no confirmed gameplay callers in the current audit; retryable reward sources must use `grantExperienceWithProgressOnce` with a stable server-generated reward ID. Do not wire retryable gameplay rewards to the non-idempotent methods.


## Acquisition receipt integrity (2026-11-22)

- `PetCollectionData.validate` now enforces one retained acquisition receipt per petId, in addition to unique acquisitionIds.
- When an owned record still has a retained acquisition receipt, validation checks that its speciesId and rarityTier match the original acquisition metadata. A mismatch returns `ACQUISITION_RECEIPT_PET_MISMATCH`.
- Added tests for duplicate receipt pet IDs under different acquisition IDs and for a live owned record whose rarity no longer matches its receipt.
- Compatibility caution: this tightens validation for persisted profiles. Before rollout, run the Studio suite against representative existing profiles and confirm no legitimate migration path changes species/rarity without updating the original acquisition receipt. Evolution should preserve species history rather than rewrite the acquisition receipt.
- Tests are committed but not executed in Roblox Studio.


## Island shutdown persistence fencing (2026-11-22)

- Fixed a shutdown ordering issue in `IslandSessionService`: `BindToClose` previously attempted to release the island lease even when the final `IslandStore.save` failed.
- The lease is now released only after `saveSession` confirms the final snapshot persisted. On failure, the server logs the condition and leaves the lease to expire naturally, preventing an immediate new server from loading the stale persisted snapshot while the previous server is shutting down.
- This trades a temporary rejoin delay (bounded by the lease TTL) for safer persistence ordering. Studio/DataStore fault-injection and immediate-rejoin behavior remain unverified.


## Pet collection reconnect isolation (2026-11-22)

- Fixed the async pet collection load path: `loadPlayer` holds a local `ownedState` with the exact `Player` instance. When its UpdateAsync completes, it checks that the currently registered state is still `ownedState` before mutating/clearing anything.
- `PlayerRemoving` now refuses to clean up a session registered under another `Player` instance with the same UserId; this prevents a delayed leave callback from disconnecting new character listeners or clearing a newer profile.
- All server entry points handling player-specific collection changes now verify `state.player == player`. The companion spawner and `PetCollectionService.isReady` use the same check, so recovery does not mistake an old session for the new join.
- This is same-server reconnect fencing only. A separate pet collection DataStore ownership lease/fencing scheme has not yet been implemented; concurrent writes from distinct servers still require integration testing and a stronger protocol if needed.
- Changes are committed and source-verified; Roblox Studio and controlled DataStore race tests have not been executed.


## Pet collection persisted writer fencing (2026-11-22)

- Added `ReplicatedStorage/Shared/Pets/PetCollectionSessionData.lua`, which implements pure `claim(current, observed, token, defaultFactory)` and `owns(current, generation, token)` checks.
- On load `PetCollectionService` now observes the DataStore profile, validates it, and atomically claims a new monotonically increasing `collectionSessionGeneration` with `collectionSessionToken` via `UpdateAsync`. Claim is conditional on the observed revision, generation and token; outdated snapshots are rejected rather than silently superseding a newer claim. Ambiguous claim retry with the same token is idempotent.
- All post-load mutations through the shared `updateWithRetry` adapter are guarded inside the actual UpdateAsync transform by the originating Player state and the currently persisted generation/token. If another server has claimed a newer generation, an old callback aborts without writing.
- The claim callback separately checks that the original Player instance still owns the in-memory load state and remains connected. This complements the earlier same-server reconnect fencing.
- `PetCollectionData.clone` now preserves both session fencing fields. Validation accepts legacy profiles with neither field but rejects incomplete or malformed pairs. Thus pure data mutations cannot drop fencing metadata.
- Added Studio-only test file `PetCollectionSessionDataTests.server.lua` and collection mutation/validation regression tests. Source reviewed; tests have NOT been executed in Roblox Studio.
- Remaining limitations: no cross-server MemoryStore lease/heartbeat for exclusive presence, no mocked DataStore concurrency test, and no end-to-end cross-store hatch fault-injection verification. Observational GetAsync caching can cause a safe but inconvenient stale-claim rejection; retry behavior/UI needs design.


## Shared island lease gates pet collection writes (2026-11-22)

- `IslandSessionService` now retains the exact owning Player instance and exposes `canWrite(userId, player)`, requiring a live session with matching Player, valid lease and no closing/leaving/shutdown.
- `PetCollectionService.loadPlayer` waits (up to 120 s) for that writable island session before observing or claiming the collection's DataStore writer generation. This prevents an otherwise-new collection generation from taking ownership while the same user's island lease belongs to another server.
- Both trusted server and client collection operations check `canWrite`, and the shared UpdateAsync wrapper checks it again inside the DataStore transform. Failure aborts the transform; no stale write is intentionally committed.
- Collection `isReady` and equipped pet spawning also require an active writable island session, so hatch recovery will not proceed on a stale island lease.
- Fixed a pre-existing Luau lexical forward-reference issue in `IslandSessionService.applyHatchOperation`: `saveSession` is now forward-declared as a local typed function and assigned later. Without this, the transaction persistence loop could attempt to call a missing global.
- Scope: this is code-level verification only; Roblox Studio/MemoryStore integration and failure injection remain NOT DONE. Neither two DataStores nor the lease can form one atomic cross-store transaction; journal-based recovery and idempotent acquisition receipts remain necessary.


## Hatch recovery readiness and reconnect hardening (2026-11-22)

- Previous mismatch: PetCollectionService can wait 120 seconds for the island lease, while hatch recovery gave up after 45 seconds. This could silently defer recovery until the next login even during an otherwise valid delayed load. Recovery now waits up to 150 seconds; shared constants and a Studio-only test enforce the ordering.
- Recovery runs are scoped to (Player instance, run token) instead of comparing only a UserId-keyed token. A late PlayerRemoving from a previous instance cannot clear a new recovery run.
- The readiness polling loop only checks run identity before testing live island lease and collection readiness, so it correctly waits for an island that does not yet exist. Each pending operation checks run identity, island write authority and collection readiness again.
- All changes are source-verified and committed to main. Roblox Studio tests and multi-server failure injection remain NOT DONE.
- Historical issue, resolved in the durable receipt update below: unresolved hatch receipts now have no age-based expiry and remain bound to their source transaction until the island journal is durably GRANTED and the collection receipt is acknowledged. Studio fault-injection is still required before live paid hatching.


## Active-session hatch recovery retries (2026-11-22)

- Recovery already waits 150 seconds for readiness (collection may need 120 seconds for the island lease); current recovery source was found updated independently before this change.
- Updated `PetHatchingRecoveryService.recoverPlayer`: it now repeatedly reads the current island journal and attempts outstanding PREPARED/CHARGED transactions while `isCurrentRun`, `IslandSessionService.canWrite`, and `PetCollectionService.isReady` hold. A failed transaction no longer has to wait until the next login for another attempt.
- The retry delay is 15 seconds; the worker stops on an empty pending journal, disconnect, lease loss, or collection unavailability. It does not spin while a transaction cannot yet complete.
- Roblox Studio fault injection remains NOT DONE. The seven-day receipt gap is resolved in code by transaction-bound completion acknowledgement; do not treat this as production-verified until the cross-store crash/rejoin tests pass.


## Durable hatch acquisition receipts (2026-11-22)

- Fixed the seven-day dedupe gap. Acquisition receipts now carry optional `transactionId` and `completedAt`. Hatch reservations and grants both persist the exact source transaction ID.
- An acquisition receipt without `completedAt` is unresolved and is never expired by age. This is the critical guarantee for PREPARED/CHARGED hatch transactions that can remain recoverable indefinitely.
- Once `IslandSessionService.applyHatchOperation(..., "GRANT", transactionId)` confirms the island journal is durably GRANTED, `PetCollectionService.acknowledgeAcquisition` records `completedAt` in the collection DataStore. Only acknowledged receipts may be compacted, after seven days from completion.
- Recovery retries acknowledgement for already-GRANTED journal entries. A missing receipt in this branch is treated as already compacted; the durable GRANTED journal is authoritative. The receipt acknowledgement is idempotent and transaction-bound.
- `IslandHatchLedgerData.prepare` now returns `ALREADY_GRANTED` for an existing completed transaction, preventing a retry from appearing to be a fresh PREPARED operation.
- Legacy pending reservations with no transaction ID can be upgraded to the transaction ID supplied by the current recovery record. Conflicting transaction IDs are rejected.
- The acquisition receipt ledger remains bounded at 128 entries. The code reserves capacity before charging; if full, it fails closed rather than charging a hatch that cannot be durably deduplicated. High-volume long-term operation may need a separate compacted dedupe index.
- Studio tests were added/updated but have NOT been executed in Roblox Studio. Cross-store fault injection remains NOT DONE.

- Legacy hatch recovery compatibility: when a matching acquisition receipt predates transaction binding, `reservePetSlotOnce` binds it to the exact transaction ID from the durable island journal and persists the upgrade before recovery continues. A conflicting pre-existing transaction ID is rejected. Legacy reservations are upgraded the same way.

- Legacy migration caveat: a CHARGED journal created under the previous seven-day receipt policy may already have lost its receipt before this code ships. If its collection receipt was pruned and no matching pending reservation remains, the old cross-store outcome is unknowable from the remaining data alone (the pet grant may or may not have persisted). The new code prevents this expiry gap for transactions processed under the new acknowledgement lifecycle, but it cannot reconstruct deleted historical evidence. Audit any existing live profiles before enabling paid hatching; resolve ambiguous old CHARGED records with an explicit migration/admin policy rather than silently claiming guaranteed recovery.


## Island economy transaction hardening (2026-11-22)

- Construction purchase previously called `IslandResourceService.spend` (which marked the profile dirty) before appending the building record and then called `markDirty` a second time. The two fields were therefore separate revisions. It now applies the server-catalog cost directly to the live wallet, appends the building record, synchronizes the world, and marks the profile dirty once. If world sync or the writable-session check fails, it restores both the building list/world and the exact pre-purchase wallet snapshot. A resource HUD snapshot is published only after the combined mutation commits.
- Building mutations, gathering prompts and client wallet snapshot requests now reject stale/non-owning Player instances through `IslandSessionService.canWrite` before using a UserId-keyed profile.
- Added pure `IslandResources.grantMany`: it rejects empty reward maps, unknown resources, invalid amounts and any cap overflow before mutating any wallet balance. `IslandResourceService.grantMany` delegates to this shared atomic operation and still rolls back if the island session cannot be marked dirty.
- `IslandResources.spend` now rejects empty cost maps instead of reporting a successful no-op.
- `IslandData.validate` now delegates wallet checks to `IslandResources.validate`, so persisted profiles cannot load balances above the live 2,000,000,000 cap and then become impossible to mutate. Added a regression test for an over-cap saved wallet.
- Construction catalog tests now assert every configured cost map is non-empty. Resource tests cover empty spends, multi-resource grant success, invalid-reward atomicity, empty reward rejection, and cap-failure atomicity.
- No demolition refund was added: the roadmap explicitly leaves that policy for economy balancing approval.
- Remaining: recent building request IDs are still cached only in memory (64 entries). A durable building-operation receipt/journal is required to cover server restart, cache eviction and cross-server retries. Roblox Studio execution and autosave/failure injection remain NOT DONE.


## Durable building-operation receipts (2026-11-22)

- Added pure `IslandBuildingJournalData` and persisted `buildingOperations` receipts inside the same island profile key as buildings and wallet balances. Each receipt stores request ID, length-prefixed payload fingerprint, operation type, creation time, the profile revision that commits it, and the exact success response.
- Placement, move, and demolition now append a receipt and increment the profile revision once, then wait for `IslandStore.save` to persist at least that revision before returning success. A server restart after the successful response reloads the building state and its receipt together; a retry with the same ID/payload replays the saved result without charging again. Reusing an ID with another payload is rejected.
- Duplicate requests arriving while the receipt revision is still being saved receive `BUILDING_OPERATION_IN_PROGRESS`; the client retains that exact request ID and can retry it. The client also reuses request IDs after transient RemoteFunction transport failures for the same placement/demolition payload.
- Receipt replay checks `persistedRevision`, not just the in-memory profile, so a second concurrent request cannot observe an uncommitted receipt and receive premature success.
- The journal retains up to 512 receipts for seven days. Expired receipts are pruned when a later operation is appended; a still-present expired ID is rejected rather than replayed. If all 512 slots are occupied by unexpired receipts, new building mutations fail closed with `LEDGER_FULL` rather than evicting retry evidence. This is an explicit bounded-ledger policy and should be monitored during live play.
- Legacy schema-v1 profiles migrate to an empty receipt ledger during load/claim; profile validation rejects malformed or duplicate receipts. Added pure Studio tests for append/replay, in-progress gating, payload conflicts, expiry, malformed entries, and full-ledger behavior, plus island profile migration/validation coverage.
- Roblox Studio tests, live DataStore restart tests, and injected save-failure/concurrency scenarios have NOT been executed. Do not treat the implementation as Studio-verified until those checks pass.

- IslandStore save retry hardening: if a retry observes the same session generation already at or beyond the requested snapshot revision, it now acknowledges the snapshot as durable instead of reporting a stale-revision failure. This handles an UpdateAsync write whose acknowledgement was lost, and prevents the building journal from reporting failure after the same receipt was already committed. The Store Studio integration test now checks this same-generation older-snapshot retry case.
- IslandData also rejects any receipt whose recorded commit revision is ahead of the profile's saved revision. The Studio profile test covers this corruption case.


## Persistent island resource nodes (2026-11-22)

- Added canonical server-owned definitions for the four existing island gathering nodes (two Wood, two Stone), including fixed reward amounts and a 60-second respawn policy. World generation now uses these definitions and restores depleted node visuals/prompts from the profile's saved `availableAt` timestamp.
- Added serializable `resourceNodes` state to the island profile. Each depleted node stores `nodeId`, canonical `resourceId`, `lastGatheredAt`, and `availableAt`. Validation rejects unknown/duplicate nodes, mismatched resource types, invalid timestamps, and cooldown durations outside the server policy. Legacy schema-v1 profiles migrate to an empty state list (all four nodes initially available).
- Gathering now commits the wallet reward and node cooldown together in one profile revision. The server waits for that revision to become durable before acknowledging the gather and publishing the resource HUD update. Per-session gathering serialization plus the persisted cooldown prevents duplicate prompt triggers and re-gather after reconnect/server restart.
- A server reconciliation loop resumes node respawn timers after world creation. Remaining offline time counts down; already-expired nodes spawn available. The cooldown begins at successful server commit time.
- Added `IslandResourceNodeDataTests` for cooldown, expiry, independent nodes, unknown IDs, duplicate state, resource mismatch, and policy limits. Extended `IslandDataTests` and `IslandStoreTests` for profile validation, legacy migration, and DataStore round-trip. Tests are committed but have NOT been run in Roblox Studio; live DataStore, restart, and concurrent prompt fault-injection remain pending.

- Mutation concurrency audit: gathering, building, and hatch profile writes now share mutual exclusion checks. Building requests are rejected at handler entry while another profile mutation is persisting, before they can change wallet/building state; session commit methods retain their own defensive lock checks. This avoids a failed overlapping placement rollback restoring a stale wallet snapshot over a resource gather.


## Generic wallet API transaction exclusion (2026-11-22)

- Hardened `IslandResourceService.grant`, `grantMany`, and `spend` with a shared writable-profile resolver. It requires the exact currently connected Player instance and an active writable island lease before touching balances.
- The resolver rejects generic wallet mutations with `PROFILE_MUTATION_BUSY` while a building, gathering, or hatch transaction is in progress. This prevents the convenience wallet facade from bypassing the profile mutation guards while a larger transaction is waiting for DataStore durability.
- Wallet snapshots are sent only to the resolved live Player after a successful mutation. Existing rollback-on-`markDirty`-failure behavior is preserved.
- Updated `docs/game-systems/ISLAND_RESOURCE_WALLET.md` to document the guards.
- Static review only; Roblox Studio tests have NOT been run. A service-level regression harness for busy-session rejection and exact-Player identity remains NOT DONE.


## Reproducible Rojo build and Studio artifact (2026-11-22)

- Added `rokit.toml` pinning Rojo 7.7.1.
- Added `.github/workflows/roblox-project-build.yml`, triggered by changes to `src/**`, `default.project.json`, `rokit.toml`, or the workflow; it installs the pinned toolchain, builds `build/PetKingdoms.rbxlx`, and uploads `pet-kingdoms-studio-build` for 14 days.
- First workflow attempt exposed a duplicate Rokit install: `setup-rokit` already installs manifest tools, and a second plain `rokit install` failed on the trust prompt. Removed the redundant step.
- Verified successful run `45021287072` (commit `c6cdd0521fa53b6f92b421b09acde67ef13c8f40`). Rojo version check, full project build, and artifact upload all passed. Artifact ID: `14753892241`.
- This proves the repository can be serialized into a place file; it does NOT prove Roblox Studio runtime, DataStore/MemoryStore, physics, UI, or mobile correctness. Open the artifact in Studio and run the dedicated test checklist.
- Updated README and `docs/BUILD_AND_TEST.md` with local Rokit setup and artifact download instructions.

## Temporary Creator Store / Toolbox policy (2026-11-22)

- Owner explicitly permits free Roblox Creator Store/Toolbox assets as temporary prototype visuals so they can playtest sooner.
- Updated PROJECT_SPEC.md, ART_BIBLE.md, README.md, and ASSET_TRACKER.md. Temporary assets must be free, provenance-tracked, license-reviewed, script-audited, performance-checked, isolated from gameplay authority, and have an explicit replacement target.
- No new external model has been selected, imported, or approved yet. Do not claim that the place already contains Creator Store visuals. The first environment kit still requires candidate review and Studio import.


## Personal island Workspace bootstrap (2026-11-22)

- Found the concrete runtime blocker: IslandSessionService requires Workspace attributes `IslandGridWidth` and `IslandGridDepth`; IslandWorldService separately requires `IslandGridCellSize` and `Workspace/IslandSpawnPoints`. The repository had no source/configuration creating these, so a clean place would fail closed before a player's island could spawn.
- Added `IslandWorldConfig.lua` and invoked it before `IslandSessionService.start()` in `Bootstrap.server.lua`.
- Provisional defaults: 24×24 logical cells, 8 studs per cell, eight island slots in a 4×2 layout with 256-stud center spacing (192-stud island top and 64-stud gap).
- Generated spawn parts are invisible, anchored, non-colliding, non-touchable, and non-queryable. Initialization is idempotent. Valid pre-existing Workspace attributes and owner-authored spawn folders containing BaseParts are preserved; invalid configuration fails closed.
- Added `IslandWorldConfigTests.server.lua` to verify defaults, spawn point availability/count for generated layouts, and idempotency. Studio execution is still pending.
- IMPORTANT: dimensions and layout are provisional prototype defaults. They require Studio review, including two simultaneous players, respawn, island separation, and mobile/streaming behavior.


## Multiplayer island slot allocation hardening (2026-11-22)

- Hardened `IslandWorldService.spawn`: only anchored BaseParts can be selected as personal-island spawn points. This matches the documented owner-authored spawn point contract and avoids moving/unanchored parts being treated as stable slots.
- Expanded `IslandWorldServiceTests.server.lua` into a Studio integration smoke test: bootstrap configuration, reject invalid profile, spawn two distinct players, ensure distinct arrival positions, reject duplicate spawn for one owner, verify world models, remove an island, clear its arrival CFrame, and reuse the released slot.
- Test execution is pending in Roblox Studio; CI Rojo build only validates source-to-place serialization and does not execute Roblox services.


## Pet House collection interaction (2026-11-22)

- Added a server-created `PetHousePrompt` to rendered Pet House models. It attaches to the Door when present, otherwise PrimaryPart/first BasePart. The same helper is called by initial spawn and live building synchronization.
- Updated `PetCollectionUI.client.lua` to listen for `ProximityPromptService.PromptTriggered` and open the existing collection panel only when the prompt is inside a `pet_house` whose ancestor island model has `OwnerUserId == LocalPlayer.UserId`.
- Prompt text is Russian ("Открыть коллекцию", "Домик питомцев"), keyboard E, gamepad X, zero hold, 10-stud distance.
- No new remote or authority boundary was added. Equip, protect, delete, and pet interaction continue through the existing server-validated collection remote.
- Extended `IslandWorldServiceTests.server.lua` with a saved Pet House record and assertions that the model and localized prompt are rendered.
- CI Rojo build validates serialization only; execute the Studio test and check PC/gamepad/mobile prompt behavior, owner filtering, and custom-template fallback.


## Main House kingdom interaction (2026-11-22)

- Extended the shared server-side building interaction helper to add `MainHousePrompt` on rendered `main_house` models, alongside the existing Pet House prompt.
- Main House prompt text: "Управлять королевством" / "Главный дом"; keyboard E, gamepad X, no hold, 10-stud distance. It uses the Door or a safe BasePart fallback.
- `IslandBuildingController.client.lua` listens for the prompt and starts the existing `beginPlacing()` flow only when the prompt is inside a main_house model under the local player's island model.
- No new placement path or authority bypass: item selection, client preview, server catalog pricing, validation, persistence and rollback remain as before.
- Expanded `IslandWorldServiceTests.server.lua` to render both Main House and Pet House and assert each localized prompt exists.
- Studio execution and actual PC/gamepad/mobile interaction remain pending.


## Kingdom overview panel (2026-11-22)

- Changed the owned Main House prompt from immediately entering placement mode to opening a compact Kingdom Overview panel.
- Panel reads the island model's server-authored attributes: Kingdom Bond stage/name/points, next stage threshold, and placed building count. It refreshes while open when those attributes change.
- Displays stage progress, remaining points, building count, and a clear button into the existing construction flow.
- Closing the panel does not alter island state. The build button calls the same existing `beginPlacing()` client preview flow; all actual placement still goes through server validation, server-owned catalog costs, persistence and rollback.
- Added touch-friendly close/shade and a centered responsive panel; Studio visual/device verification is pending.


## Kingdom overview statistics correction (2026-11-22)

- `KingdomBond.calculate` now exposes both `buildingCount` (non-Main-House improvements used by the existing Bond rules) and `totalBuildingCount` (all placed buildings, including Main House).
- `IslandWorldService.refreshKingdomBondVisuals` replicates the total as `KingdomBondTotalBuildingCount`; the existing Bond scoring count and thresholds are unchanged.
- Main House overview now displays the actual total placed-building count with correct Russian singular/plural forms.
- Progress bar lower threshold is keyed by the stable `KingdomBondStage` ID rather than comparing localized stage names.
- Added pure contract assertions for empty, Main House + improvement, and duplicate-building layouts. Studio test execution remains pending.


## Island expansion geometry foundation (2026-11-22)

- Added Services/IslandExpansion.lua, a pure geometry contract. Level 0 preserves current base dimensions; each of two provisional levels adds 8 cells to both axes (24x24 -> 32x32 -> 40x40 at current defaults).
- Added Studio-only tests for dimensions, next-level calculation, maximum level, negative/fractional/over-limit levels, and invalid base dimensions.
- Added docs/game-systems/ISLAND_EXPANSION.md. The module intentionally does not set prices or unlock requirements because the economy balance sheet is not approved.
- No profile schema, live world bounds, building placement, or player-facing behavior has changed yet. The purchase/persistence/world-rendering slice remains NOT DONE.


## Island expansion profile persistence foundation (2026-11-22)

- Island profiles now carry optional schema-v1 expansionLevel; newly created profiles start at 0, legacy records are accepted and normalized to 0 in IslandStore.load and the atomic claimSession transform.
- IslandExpansion.expandProfile returns a cloned profile for the next level, increases dimensions by 8 cells per axis, and shifts every saved building coordinate by 4 cells per axis. This compensates for the renderer's centered-grid coordinate mapping and keeps existing buildings at the same world-space position.
- IslandData validates the expansion level. Studio tests cover legacy compatibility, invalid levels, two expansions, max-level rejection, source immutability, and world-position invariance.
- Still NOT DONE: applying the transform through a server-authoritative session transaction, approved resource costs/unlocks, durable receipt/idempotency, world regeneration, client UI, and Studio playtests.


## Playable join-flow integration (2026-11-22)

- Server bootstrap now sets `Players.CharacterAutoLoads = false` before starting IslandSessionService.
- IslandSessionService publishes `PetKingdomsLoadStatus`/`PetKingdomsLoadMessage` through lease acquisition, profile load/claim, world generation and character creation.
- After the island is spawned and the live session is installed, server calls `Player:LoadCharacterAsync()`; CharacterAdded routes the character to the island. The player is marked Ready only after the character is pivoted to the current island arrival CFrame.
- Added `StarterPlayerScripts/IslandLoading.client.lua`: localized full-screen loading panel, animated progress indicator, server-authored phase text, failure state, and fade-out only on Ready.
- This fixes the confusing default spawn in an empty Workspace during DataStore loading. It does not by itself complete the art/world MVP; the current island renderer remains a procedural blockout.
- The loading client also clamps the default third-person camera to 8–28 studs and rebinds CameraSubject to the new Humanoid after character spawn.
- Verify in Studio: publish a private test place, enable Game Settings → Security → Enable Studio Access to API Services, then test new player, saved returning player, delayed DataStore, failed lease/load, respawn, and two-player join.


## Character death and respawn lifecycle (2026-11-22)

- Since `Players.CharacterAutoLoads = false`, Roblox no longer automatically respawns a dead character. IslandSessionService now binds the active character's Humanoid.Died event after every CharacterAdded.
- A death schedules a five-second respawn, guarded by the exact active session, writable lease, player presence, and the still-current dead character. Respawn uses LoadCharacterAsync with up to three bounded attempts.
- New character arrival continues through the island's current arrival CFrame; the loading overlay remains until the character is moved and marked Ready.
- CharacterAdded and Humanoid.Died connections are disconnected on lease loss and session finalization.
- Studio verification still required: kill the character, confirm one respawn after the delay, verify no duplicate characters/respawn tasks, then leave/rejoin during the delay and confirm no stale respawn occurs.


## Pet collection management UI (2026-11-22)

- Expanded the existing responsive collection panel with filters for all owned pets, equipped team, and favorites; added sorting by newest acquisition, species name, or companionship Bond, with favorites prioritized.
- Added favorite and lock toggles using the existing server-authoritative `Protect` action and expected collection revision.
- Added a two-step permanent deletion confirmation using the existing server-authoritative `Delete` action. Locked pets cannot be deleted from the UI; server rules still protect the starter pet, last pet, and equipped pets.
- Added localized empty states for filters/search with no matches.
- No new remote actions or client-authoritative collection mutations were introduced.
- Still requires Roblox Studio desktop/touch checks, small-screen layout review, and DataStore integration tests.


## Companion follow catch-up (2026-11-22)

- CompanionFollowController now derives movement animation from both owner velocity and horizontal distance to the desired formation slot. Pets visibly run when lag exceeds 8 studs and walk when slot error exceeds 1.1 studs.
- When the horizontal gap reaches 55 studs (e.g. streaming or character reset), the client controller recovers the pet near its owner's formation rather than slowly sliding from far away.
- Added Studio client smoke assertions for catch-up run state and extreme-gap recovery.
- This remains client-side visual positioning for server-owned replicated pet models; ownership/equip and collection mutations remain server-authoritative.
- Still pending: execute the smoke test in Roblox Studio, validate on uneven terrain/mobile, and review multi-pet formation around obstacles.


## Main companion selection (2026-11-22)

- Collection detail now exposes a star control for equipped pets. The first equipped pet is the main companion (FormationSlot 1); choosing another equipped pet moves it to the front while preserving the relative order of the remaining team.
- Uses the existing server-authoritative Equip remote with expectedRevision; no new mutation endpoint or client-side ownership rule.
- Main companion selection remains unavailable for pets not currently in the active team.
- Verify in Studio: switch lead among 1–3 equipped pets, rejoin and confirm order persists, confirm spawned FormationSlot 1 matches the selected lead, and review narrow/mobile layout.


## Ambient resource awareness (2026-11-22)

- CompanionFollowController scans the owner's own PlayerIslands/<island>/ResourceNodes folder once per second, looking only for nearby visible nodes whose AvailableAt timestamp has elapsed.
- A nearby wood node triggers a short curious reaction; a stone node triggers a short sniff reaction. Reactions are cosmetic and never grant resources, trigger prompts, or bypass IslandGatheringService server validation.
- Movement remains higher priority; direct player interaction remains higher priority than ambient curiosity.
- Added a Studio client smoke assertion for a nearby available wood node. Execute it in Roblox Studio; also verify hidden/depleted nodes are ignored and check mobile frame cost with three active pets.


## Lead Bunny resource investigation (2026-11-22)

- The lead companion (slot 1) can now briefly leave formation to approach the nearest available, visible resource node within its scan radius.
- It chooses a ground-resolved approach point roughly 2.8 studs from the node, walks toward it, performs Curious for wood or Sniff for stone when close, then resumes its regular follow slot after up to four seconds.
- A per-node 12-second re-investigation cooldown avoids repeatedly selecting the same node. Secondary companions remain in formation.
- Investigation is cosmetic only. It does not activate ProximityPrompts, mutate profiles, or grant resources; IslandGatheringService remains the sole gathering authority.
- Studio smoke coverage now checks approach, inspection reaction, and return to formation. Studio runtime, uneven terrain, StreamingEnabled and mobile behavior remain unverified.


## First successful Roblox Studio launch (2026-11-22)

- Owner confirmed the project now gets past the localized loading screen and enters a Play session in the dedicated private test Experience after enabling Studio API access.
- Treat this as a successful first-join smoke check only. The personal island's visual quality, resource gathering, construction, collection UI, pet companion behavior, save/rejoin, respawn, multi-server leases, and mobile controls still need individual verification.
- Next development priority: turn the currently separate gathering/building/companion systems into a repeatable first-session gameplay loop, while testing each system in Studio before expanding scope.


## Gathering reward toast event alignment (2026-11-22)

- Fixed a client/server event contract mismatch in IslandResourceHUD: IslandGatheringService publishes the success code `GATHERED`, while the HUD previously accepted only `GRANTED`. The wallet snapshot was updated, but the successful gather toast was silently discarded.
- HUD now displays the existing localized reward toast for the authoritative `GATHERED` event. No reward authority or economy logic changed.
- Verify in the dedicated Roblox Studio test Experience: gather one Wood node and one Stone node; confirm the wallet count and matching +3/+2 toast; gather a depleted node and confirm no success toast or duplicate reward.


## Building retry idempotency fix (2026-11-22)

- Placement/move UI previously cleared its pending request ID for every successful RemoteFunction transport response, including server-level transient results such as PERSIST_TIMEOUT or BUILDING_OPERATION_IN_PROGRESS.
- It now uses the same shouldKeepPendingRequest predicate as demolition and retains the request ID for transient/in-progress outcomes. This allows the server's idempotency cache and durable building journal to recognize a retry as the same logical operation instead of creating a new charge/place request.
- Transport failures already retained the request ID and remain unchanged.
- Verify with Studio fault injection: force a transient persistence result, retry the same placement, and assert exactly one building record and one resource charge. Also verify definitive errors clear the pending request key.


## Construction catalog cleanup (2026-11-22)

- Removed the unused BUILDING_COSTS table from IslandBuildingController. It duplicated provisional prices already owned by the server's BuildingCatalog and was not read by the client.
- Server remains authoritative for all construction costs and affordability decisions. This is dead-code removal only; no price, placement, or economy behavior changed.


## Island expansion geometry regression coverage (2026-11-22)

- Extended IslandExpansionTests.server.lua beyond dimension-only checks.
- The test now expands a representative profile from 24x24 to 32x32 to 40x40, checks the +4-cell coordinate shift on each expansion, verifies cumulative offsets for two saved buildings, confirms the original source profile is unchanged, and rejects a third expansion at the configured maximum.
- These are Studio-only pure contract tests. They have been committed but not executed in the owner's Roblox Studio session.
- Expansion pricing, purchase/unlock, durable transaction receipt, world resize/update, occupied-edge handling, and client preview remain unimplemented because the economy and unlock requirements are not approved yet.


## Island expansion input hardening (2026-11-22)

- IslandExpansion.expandProfile now rejects negative and fractional saved building grid coordinates instead of accepting any numeric x/z values.
- Added Studio contract cases for both malformed coordinate classes.
- This is validation hardening only. It does not add purchase pricing, a purchase remote, wallet debit, or world resizing. Expansion remains geometry/persistence foundation only.


## Island expansion non-finite coordinate regression cases (2026-11-22)

- Added Studio contract cases for NaN and positive-infinity saved building coordinates.
- The expansion transformer rejects both through the non-negative integer coordinate guard.
- No runtime gameplay or economy behavior changed. Studio execution remains pending.


## Expanded island renderer integration coverage (2026-11-22)

- Extended IslandWorldService Studio integration test to respawn a profile at expansion level 1 with 32x32 bounds and +4-cell shifted building coordinates.
- The test asserts world GridWidth/GridDepth attributes, 256x256-stud grass terrain at the configured 8-stud cell size, and unchanged main-house world pivot compared with the starter plot.
- This validates the existing profile-driven renderer on a rejoin-style respawn path; it does not implement live in-session expansion, purchase, resource debit, or a durable expansion receipt.
- Studio execution is still pending.


## Maximum expanded island renderer regression (2026-11-22)

- Extended IslandWorldService Studio integration coverage to render the maximum prototype expansion level (40x40 grid, 320x320 studs at 8-stud cells).
- The test checks persisted world bounds, rendered grass dimensions, main-house existence, and exact preservation of its original world-space pivot after the cumulative +8-cell coordinate offset.
- This remains a Studio integration test and has not been executed in the owner's Studio session. No purchase, live resize, or resource transaction was added.


## Expansion profile bounds consistency guard (2026-11-22)

- Added IslandExpansion.matchesProfileBounds(profile, baseWidth, baseDepth), which validates the stored width/depth against the configured base dimensions and persisted expansionLevel. Legacy profiles without expansionLevel remain level 0.
- IslandWorldService.spawn now fails closed with INVALID_EXPANSION_BOUNDS before allocating a spawn slot or creating world instances when persisted geometry does not match its expansion level; missing base Workspace bounds return MISSING_ISLAND_GRID_BOUNDS.
- Added pure contract cases for legacy, level 1, max level, mismatched bounds, and out-of-range levels, plus a world-renderer rejection integration case.
- No expansion purchase or wallet mutation has been introduced. Studio tests remain pending execution by the owner.


## Canonical next-expansion preparation (2026-11-22)

- Added pure IslandExpansion.prepareNextProfile(profile, baseWidth, baseDepth).
- It first validates the current profile against configured starter dimensions and persisted expansion level, then derives the next profile and validates the resulting bounds again.
- It returns PREPARED only for a canonical one-level transition. Invalid current geometry, max-level, and malformed building records retain explicit failure codes.
- The helper does not mutate the source profile, debit resources, write DataStore, or change the live world. It is a safe preparation primitive for the future server-authoritative transaction after economy rules are approved.
- Added Studio contract cases for valid starter preparation, source immutability, and rejection of a non-canonical current profile.


## Expansion preparation failure-path coverage (2026-11-22)

- Added contract tests for prepareNextProfile rejection at maximum level, invalid saved building coordinates, and mismatched configured base dimensions.
- These tests complement the success and source-immutability cases and ensure invalid requests fail before any future transaction can mutate or persist a profile.
- No purchase, resource debit, durable receipt, or live world resize was introduced. Studio execution remains pending.


## Expansion test execution-order fix (2026-11-22)

- Corrected IslandExpansionTests.server.lua so the representative source profile and its derived second-level profile are declared before the preparation assertions that consume them.
- This fixes a Studio runtime test-script ordering defect; no production gameplay code or save data changed.
- GitHub Actions Rojo build passed for commit bd463c062ba24a8099d271a47d0704f99e9cd175. This validates project packaging, not execution of Studio-only tests.


## Expansion contract test deduplication (2026-11-22)

- Removed a second duplicated copy of the IslandExpansion geometry contract test block.
- Confirmed the Studio test file now has exactly one declaration each for the representative source profile, first-level profile, and second-level profile. Preparation assertions run after those values are constructed.
- No production service or profile data changed. GitHub Actions packaging check is pending for the cleanup commit.


## Server-session expansion commit foundation (2026-11-22)

- Added IslandSessionService.commitIslandExpansion(userId, player, expectedLevel).
- Requires the exact active Player instance and writable island lease; shares the existing building mutation lock so it cannot overlap building, gathering, or hatch profile mutations.
- Validates expectedLevel and configured base bounds, prepares one canonical next profile, increments the profile revision, and waits for DataStore persistence before returning EXPANDED.
- A retry using the same expectedLevel after the in-memory transition returns ALREADY_APPLIED only after the resulting revision is durable; a stale or skipped expected level returns EXPANSION_LEVEL_CONFLICT.
- This is a server service primitive only: no RemoteEvent/client endpoint, resource cost, wallet debit, durable request receipt, or live IslandWorldService respawn has been wired. Studio and DataStore fault-injection tests remain pending.


## Live island refresh after expansion (2026-11-22)

- Added IslandWorldService.refresh(userId, player, profile). It validates the canonical profile and existing world/spawn ownership, builds a complete replacement world at the same assigned spawn point, and only swaps/destroys the old world after successful generation.
- IslandSessionService.commitIslandExpansion now calls refresh only after the target profile revision is confirmed durable. If rendering fails after persistence, the operation reports durable success with PERSISTED_WORLD_REFRESH_PENDING and leaves the saved profile authoritative for next load.
- Updated IslandWorldService Studio integration tests to refresh the active world from 24x24 to 32x32 and then 40x40 without removing/reallocating the island. Tests assert the old model is replaced and existing building world positions remain stable.
- No client RemoteFunction or purchase endpoint is exposed yet; the economy is not approved, so no free expansion can be triggered by clients. Studio runtime tests remain pending.


## Read-only island expansion preview endpoint (2026-11-22)

- Added IslandExpansionService and started it from Bootstrap.server.lua.
- Exposes ReplicatedStorage/Remotes/GetIslandExpansionPreview as a RemoteFunction. It requires the exact current writable Player session, validates the profile against configured base bounds, and returns current/next level and dimensions, max level, canExpand, purchaseAvailable=false, and ECONOMY_NOT_APPROVED.
- Preview calls are rate-limited per user; first request is allowed immediately and per-user limiter state is cleaned on PlayerRemoving.
- This endpoint is read-only. It does not mutate profile data, charge resources, or invoke commitIslandExpansion. No client UI is wired yet.


## Client expansion preview panel (2026-11-22)

- Added StarterPlayerScripts/IslandExpansionUI.client.lua. It creates a responsive island button and a themed panel consistent with the existing resource HUD/pet collection UI.
- Panel invokes GetIslandExpansionPreview and displays current level/dimensions, next level/dimensions, max-level state, request errors, and an explicit note that purchase is disabled until economy approval.
- Added manual refresh, open/close animation, mobile width adjustment, and no client-side profile mutation.
- Purchase button and boundary hologram are intentionally not included: economy rules and a trustworthy world-space preview locator are not yet defined.


## Local holographic expansion preview (2026-11-22)

- Extended IslandExpansionUI.client.lua to create four client-local neon preview strips around the current island's grass surface, sized from server-provided next dimensions and aligned to the existing island CFrame.
- Preview is only shown while the expansion panel is open and the server reports another level is geometrically available. It uses anchored, non-colliding, non-touching, non-queryable parts and SelectionBox outlines.
- Preview folder is destroyed when the panel closes or before a new preview is drawn. It does not alter the server world, profile, saved coordinates, or economy.
- Roblox Studio visual alignment and runtime behavior still require manual verification.


## Stable island identity after repeated expansion refresh (2026-11-22)

- Fixed IslandWorldService.refresh to keep the canonical model name `Island_<userId>` instead of appending `_Refresh` to the previous model name on every expansion.
- This matters because the client hologram locates the active island through `PlayerIslands/Island_<userId>`; the old naming behavior made the world preview disappear after the first refresh.
- Added Studio integration assertions for the canonical name after both level-1 and level-2 refreshes.
- Visual effect/animation remains a separate follow-up; Studio execution is pending.


## Post-persistence expansion completion effect (2026-11-22)

- Added a short server-replicated completion effect inside IslandWorldService.refresh, invoked only after the replacement world is fully generated, parented, and made active.
- Four neon edge ribbons pulse/fade over the newly added perimeter; a particle burst uses a transient attachment contained in the effect folder. Debris removes the entire effect folder after 3.5 seconds.
- The effect is visual only: no terrain/profile mutation, collision, touch, query, or saved state. If refresh generation fails, no effect is emitted.
- Added a Studio integration assertion that a successful size increase creates the transient effect and particle emitter. Roblox Studio visual verification remains pending.


## Expansion retry side-effect fix (2026-11-22)

- Fixed commitIslandExpansion so an `ALREADY_APPLIED` retry returns after confirming the durable revision and releases the mutation lock without calling IslandWorldService.refresh again.
- A lost acknowledgement retry therefore cannot regenerate the active world or replay the expansion completion effect. Only the first successful transition performs the world refresh.
- Expansion pricing remains deliberately undefined because the project economy specification does not approve costs/rates yet. No prices were invented and purchase remains disabled.


## Economy baseline audit (2026-11-22)

- Added `docs/game-systems/ECONOMY_BASELINE_AUDIT.md` with source-backed starter wallet, all four current gathering nodes, rewards, respawn, coded construction costs, and theoretical gross gathering ceilings.
- Confirmed theoretical ceilings under continuous immediate gathering: 6 Wood/minute and 4 Stone/minute. These are not realistic expected rates.
- Confirmed current starter wallet (2 Wood, 1 Stone) plus one Wood gather and one Stone gather covers the currently coded Pet House cost (5 Wood, 2 Stone).
- No expansion prices or unlock requirements were invented. Project spec keeps the complete economy and expansion balance open pending explicit approval.
- No gameplay code or economy values were changed in this audit.


## Economy source coverage checks (2026-11-22)

- Extended `IslandResourceNodeDataTests.server.lua` with contract assertions for exactly four canonical starter gathering nodes, the 60-second cooldown, and each node's resource/reward mapping.
- Reconfirmed there is no quest, reward, or shop service in the current server Services directory. Gold and Gems exist in the wallet schema but no earning source is implemented in the inspected gathering catalog.
- Updated the economy audit and roadmap to distinguish implemented wallet support from missing income sources. No new currency rates or prices were invented.
- Studio execution of these tests is still pending.


## Introductory quest progress foundation (2026-11-22)

- Added pure `QuestProgressData.lua` with two provisional starter objectives: gather 3 Wood and gather 2 Stone. Targets are prototype values for Studio playtesting, not approved economy/balance values.
- Added `questProgress` to newly created island profiles and validation; legacy schema-v1 profiles without this field remain valid and are migrated to empty quest progress by IslandStore load/claim paths.
- Integrated gathering progress into the same durable island profile revision as the resource reward and node cooldown. A gather cannot award resources without also applying the corresponding quest progress transaction.
- Added `QuestService` and `ReplicatedStorage/Remotes/GetQuestProgress` as a rate-limited, read-only snapshot endpoint. Clients cannot submit progress or rewards.
- Added Studio tests for quest progress targets, completion caps, invalid IDs/missing entries, and profile validation/migration compatibility.
- Quest rewards, claim endpoint, player-facing journal UI, additional quest types, and actual Studio/DataStore execution remain NOT DONE. No Gold/Gem rewards or economy values were invented.


## Quest Journal UI (2026-11-22)

- Added `src/StarterPlayer/StarterPlayerScripts/QuestJournalUI.client.lua`, a responsive journal matching existing dark fantasy UI styling.
- Added a parchment launcher button, modal panel, quest cards, progress bars, completed states, and remaining-quest badge.
- UI reads only from `GetQuestProgress`; it never sends progress or reward claims to the server.
- Journal refreshes when opened and after the server's confirmed `IslandResourceUpdate` gathering event (debounced to respect the server read rate limit).
- Rewards remain explicitly unavailable; no economy amounts were invented. Tracked HUD and completion toast are still pending.
- Studio visual and mobile interaction verification is pending.


## Quest tracking and completion feedback (2026-11-22)

- Extended `QuestJournalUI.client.lua` with a compact tracked-objective HUD anchored bottom-left and responsive sizing.
- Added per-card Track button; selection is client-local for now and is not persisted across sessions.
- Automatically selects the first incomplete quest on initial snapshot and advances to the next incomplete objective after completion.
- Added completion toast driven only by a server-read quest snapshot after the confirmed gather event. Toast is transition-based and does not replay for already-completed quests on initial load.
- Client remains read-only: it cannot submit progress or claim rewards.
- Reward claim flow and persistent tracked-quest preference remain NOT DONE. Studio visual/device verification remains pending.


## Persistent tracked quest preference (2026-11-22)

- Added `trackedQuestId` to newly created island profiles, defaulting to `gather_wood`; legacy schema-v1 profiles are migrated to the same default during load/claim.
- Island profile validation accepts nil for unmigrated legacy records but rejects unknown quest IDs.
- Added `IslandSessionService.commitTrackedQuest`: validates the selected quest exists and is incomplete, serializes against other profile mutations, increments profile revision, and waits for DataStore durability before success.
- Added server RemoteFunction `SetTrackedQuest`; request input is type-checked and server-side rate-limited. Snapshot now returns the persisted tracked quest ID.
- Updated the journal so Track buttons wait for server confirmation and selection survives rejoin. When the selected objective is completed, the UI picks the next incomplete objective and attempts to persist it.
- Added profile validation tests for default, unknown, and legacy tracked quest IDs.
- Reward claiming and its idempotent receipt ledger remain NOT DONE. Studio/DataStore runtime verification remains pending.


## Quest reward transaction design (2026-11-22)

- Added `docs/game-systems/QUEST_REWARDS_TRANSACTION_DESIGN.md`.
- Confirmed quest progress/resources live in the island profile DataStore while pet XP lives in the separate pet collection DataStore; there is no cross-DataStore atomic transaction.
- Specified a durable island claim receipt + XP outbox + stable pet reward ID protocol. Retries must be idempotent if pet XP commits but island acknowledgement fails.
- Identified a retention mismatch to resolve before enabling cross-store rewards: pet reward receipts currently have bounded seven-day retention, while an outbox could remain pending longer. The receipt must outlive all retries or be reconciled safely.
- No reward values, XP amounts, pet recipient rule, or live claim endpoint were invented. Reward implementation and UI remain NOT DONE.


## Pet XP receipt acknowledgement hardening (2026-11-22)

- Changed `PetCollectionData.grantExperienceWithProgressOnce`: unacknowledged reward receipts are retained indefinitely and continue to deduplicate retries regardless of age.
- Added `acknowledgedAt` validation and `PetCollectionData.acknowledgeExperienceReward`; only a trusted source acknowledgement starts the seven-day retention window.
- Added `PetCollectionService.acknowledgeExperienceReward`, a server-only DataStore-backed operation. It validates the current collection snapshot, updates through UpdateAsync retry, syncs the resulting revision, and is idempotent.
- Added Studio data tests for unacknowledged receipts surviving beyond seven days, acknowledgement persistence, duplicate acknowledgement, expiry only after acknowledgement, and invalid acknowledgement timestamps.
- Important: this is the pet-side safety primitive only. The island XP outbox and caller integration are NOT DONE, so no live quest reward claims are enabled.


## Quest reward outbox foundation (2026-11-22)

- Branch: feature/quest-reward-outbox-foundation.
- Added QuestRewardOutboxData.lua, a pure data contract for permanent quest claim receipts and durable XP outbox records.
- Claim receipts are keyed by quest ID and have no expiry/pruning path. Repeating the same claim is ALREADY_CLAIMED; attempting to replace its reward identity is rejected.
- Outbox records carry stable rewardId, quest ID, exact pet ID, XP amount, progression configuration version, enqueue timestamp, and optional delivery timestamp.
- Duplicate enqueue with the same payload is idempotent; a reused reward ID with different content fails closed. Pending entries are never evicted; the bounded ledger rejects new entries when full.
- Island profiles now initialize questRewardClaims and questRewardOutbox. Validation accepts older schema-v1 profiles without these fields. IslandSessionService.cloneProfile deep-clones both ledgers before save.
- Added QuestRewardOutboxDataTests.server.lua and extended IslandDataTests.server.lua.
- These are data/persistence primitives only. There is still no quest claim transaction, client claim remote, XP delivery worker, or live reward configuration.
- Do not invent reward amounts, XP progression version, or which pet receives quest XP. These decisions remain open in docs/PROJECT_SPEC.md and QUEST_REWARDS_TRANSACTION_DESIGN.md.
- Next: inspect/implement the server-side durable claim transaction using an approved server-owned reward catalog; then add a recovery worker that delivers the exact stable reward ID, persists island delivery acknowledgement, and only then calls PetCollectionService.acknowledgeExperienceReward. Execute Studio/DataStore fault-injection tests before enabling claims.


## Quest outbox CI verification (2026-11-22)

- GitHub Actions run 45039287808 (PR #1, commit 9d287477722727f8c9bb33bbcd50d204b7f1de70) completed successfully: pinned Rojo setup, project build, and Studio-ready artifact upload all PASS.
- Artifact: pet-kingdoms-studio-build (artifact ID 14760529099), available until 2026-12-06 15:37 UTC.
- CI validates Rojo packaging only. The new Studio-only Lua tests and live DataStore recovery scenarios have not been executed.


## Quest claim transaction primitives (2026-11-22)

- Added server-only `IslandSessionService.commitQuestRewardClaim(userId, player, questId, rewardPlan)`. It verifies the quest is complete, then writes the permanent claim receipt and pet XP outbox record in one profile revision. `rewardPlan` must be resolved by trusted server code; no client remote was added.
- Claim receipts now optionally carry the exact island revision. The transaction writes this revision and retries wait until it is persisted before acknowledging the receipt.
- Added `commitQuestRewardDelivery` and `commitQuestRewardAcknowledgement`, each persisting its state transition and checking durability even on duplicate retries.
- Added server-side read helpers `getPendingQuestRewards` and `getQuestRewardsAwaitingAcknowledgement` so a future worker can recover both sides of the two-phase protocol.
- Outbox records in `acknowledgedAt` state are compacted only when appending a later record. Pending and delivered-but-unacknowledged records are retained. Permanent claim receipts remain in the separate claims map.
- Extended pure Studio tests for claim revision binding, acknowledgement ordering/idempotency, and safe outbox compaction.
- Still no recovery worker, reward catalog, XP threshold table, recipient-selection rule, claim RemoteFunction, or claim UI. Do not activate claims or invent economy values until those are approved.


## Quest claim transaction CI verification (2026-11-22)

- GitHub Actions run #115 / run ID 45039658996 completed successfully on commit c804f6d511f6b2b05945d9e62aa4163dab1e1b40. Pinned Rokit setup, Rojo version check, full project build, and artifact upload all PASS.
- Artifact `pet-kingdoms-studio-build` ID 14760569677 is available until 2026-12-06 15:41 UTC.
- CI confirms project serialization only. It does not execute Luau tests or live DataStore workflows; Roblox Studio verification remains pending.


## Quest XP recovery worker (2026-11-22)

- Added `PetProgressionCatalog.lua`, a versioned server-owned progression registry. It intentionally contains no thresholds until XP balance is approved; unknown versions fail closed.
- Added `QuestRewardRecoveryService.lua` and started it from Bootstrap. It waits for the exact player's writable island session and ready collection, processes pending records using their stored stable reward ID/pet ID/amount/version, persists delivery before receipt acknowledgement, and resumes delivered-but-unacknowledged records.
- DataStore/configuration/target failures leave the durable outbox untouched and are retried with a delay. The worker never accepts reward details from clients.
- Added `PetProgressionCatalogTests.server.lua`.
- CI build does not execute Studio-only scripts. Studio execution and DataStore fault injection remain pending.
- No live claim endpoint or reward values are enabled. Do not populate progression thresholds or recipient/reward policy without approval.
- Known remaining design hardening: the current pet receipt retention clock starts when the pet receipt is acknowledged, before the island source acknowledgement is persisted. If the latter remains unavailable beyond the seven-day receipt window, recovery needs a stronger finalization handshake; resolve before production claims.


## Quest XP acknowledgement retention hardening (2026-11-22)

- Reordered the worker handshake: pet XP write -> durable island delivered marker -> durable island source acknowledgement -> pet receipt acknowledgement -> durable island pet-acknowledged marker.
- Added `petAcknowledgedAt` to outbox validation and compaction rules. An outbox record cannot be compacted after only the source acknowledgement; both markers must be durable.
- Added `commitQuestRewardPetAcknowledgement` and `getQuestRewardsAwaitingPetAcknowledgement` to IslandSessionService.
- Recovery now resumes the source-ack and pet-ack phases separately. A missing pet receipt is accepted only after source acknowledgement is already durable, proving the XP write was confirmed before the receipt retention window began.
- Added contract tests for phase ordering, safe retention, and finalization.
- This closes the previously documented seven-day source-ack outage window in the intended transaction protocol. Studio execution/fault injection remains pending.
