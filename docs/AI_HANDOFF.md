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
- Reservation prunes expired acquisition receipts using the existing seven-day `REWARD_RECEIPT_RETENTION_SECONDS` window and persists the pruned ledger together with the reservation.
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
- Important unresolved issue: acquisition receipts are retained for seven days, whereas unfinished CHARGED hatch journals can persist longer. A grant succeeded just before an acknowledgement failure can become indistinguishable from a never-granted transaction once its acquisition receipt expires. Live paid hatching remains blocked until an unambiguous long-lived completion/deduplication strategy is implemented.


## Active-session hatch recovery retries (2026-11-22)

- Recovery already waits 150 seconds for readiness (collection may need 120 seconds for the island lease); current recovery source was found updated independently before this change.
- Updated `PetHatchingRecoveryService.recoverPlayer`: it now repeatedly reads the current island journal and attempts outstanding PREPARED/CHARGED transactions while `isCurrentRun`, `IslandSessionService.canWrite`, and `PetCollectionService.isReady` hold. A failed transaction no longer has to wait until the next login for another attempt.
- The retry delay is 15 seconds; the worker stops on an empty pending journal, disconnect, lease loss, or collection unavailability. It does not spin while a transaction cannot yet complete.
- Roblox Studio fault injection remains NOT DONE. A separate unresolved reliability issue is the seven-day expiry of acquisition receipts while CHARGED hatch transactions can persist longer. Until addressed, do not claim unlimited-duration duplicate prevention for a grant whose journal completion never persisted.
