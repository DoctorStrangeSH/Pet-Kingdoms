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


## Single-active-panel client UX (2026-11-23)

- Added a shared local `PetKingdomsPanelSignal` BindableEvent through PlayerGui to the building, pet collection, quest journal, and island expansion client scripts.
- Opening one of these full-screen panels notifies peers; the others close via their existing close functions instead of leaving overlapping modal stacks. Building cancels active placement and clears its local preview when another panel opens.
- No server authority, economy, building transactions, or profile schema changed.
- Verification pending: open the four panels in different sequences on PC and mobile, ensure only one modal stays active, building's hologram is removed on menu switch, and returning to building starts a fresh placement without losing any saved layout. Check that collection's delete-confirmation overlay does not persist after reopening.


## Construction placement confirmation lock (2026-11-23)

- Updated `IslandBuildingController.client.lua` so a world tap/click validates and locks the currently selected grid cell. Moving the pointer to the confirm button or touching another UI control no longer drags the placement preview away from its intended target.
- A second unprocessed world tap/click selects a different cell. Rotation revalidates the locked location; changing the catalog selection revalidates its new footprint. Confirm requires both a locked cell and current valid collision/bounds results.
- On touch devices the preview no longer raycasts every rendered frame based on stale/recycled touch movement; taps are the explicit position selector. Existing server-authoritative placement requests and idempotency logic are preserved.
- This code is committed but Roblox Studio runtime/mobile verification is pending. Test: touch a valid patch, tap Confirm, select a new cell, rotate a 3x3 item, switch catalog footprint, click UI outside world, and check overlap/out-of-bounds rejection. Also check PC mouse placement and moving an existing building.


## Compact construction tray (2026-11-23)

- Reworked the existing in-game IslandBuildingController panel into a 228px-tall bottom tray (previously 340px). The six catalog items are presented in a horizontally scrolling row rather than a 2-column/3-row grid, leaving more visible island space for placement.
- Adjusted action-row positioning and responsive button sizes for narrow screens; panel width follows the active camera viewport, and move/demolish controls shift lower on compact screens.
- No catalog costs, building authority, or persistence rules changed. This is integrated into the live controller rather than a mockup.
- Studio device emulator testing remains pending: verify horizontal swipe scrolling, confirm/cancel/rotate hit targets, status visibility, safe-area overlap, and move/demolish access at 320px, 375px, tablet, and desktop resolutions. Also verify catalog switching while a grid cell is locked.


## Construction catalog selection clarity (2026-11-23)

- Strengthened selected-building feedback in the in-game horizontal construction catalog: the active card gets a thicker fully visible gold outline, contrasted background, and a `Selected` UI attribute. Other cards retain the muted outline.
- Wrapped the compact building status label for longer Russian hints.
- On a catalog switch with a locked cell, the controller now projects that saved cell back into screen space before revalidating the new footprint, instead of accidentally using the pointer's current location over a catalog button.
- Roblox Studio and mobile device emulator checks remain pending, including selected-card outline legibility, raycast revalidation, rotate and confirmation, and switching to larger footprints near boundaries.


## Locked construction cell rotation correction (2026-11-23)

- Split placement preview into `updatePreviewAtCell(x, z)` (authoritative local grid-cell presentation and overlap/bounds feedback) and `updatePreview(screenPosition)` (raycast from a deliberate world pointer).
- Rotation with the on-screen button or R key and switching catalog cards now re-evaluate the exact locked grid coordinates directly. They no longer raycast through the current pointer position over UI, preventing the selected destination from drifting or being cleared by a UI interaction.
- Kept server-authoritative placement and idempotent request IDs unchanged. A locked footprint that becomes invalid displays red and cannot be confirmed; the player can select a new world cell.
- Roblox Studio runtime test still needed: lock a cell, move cursor over panel, rotate via button and R, swap 1x1/3x3 catalog entries, confirm valid and invalid placements, and check touch input and camera changes in mobile emulator.


## Client 3D construction silhouettes (2026-11-23)

- Added per-catalog local 3D preview silhouettes in `IslandBuildingController.client.lua`: house, pet house, stone path, garden lantern, flower bed and wooden fence. The simple transparent silhouettes are based on the existing server fallback blockouts; they are **not** approved production art or imported third-party asset models.
- The preview remains client-only; pieces are anchored, noncolliding, non-queryable and shadow-free. Both footprint indicator and silhouette follow the same selected grid cell and rotation; invalid positions retain the red footprint and fade the silhouette.
- Switching catalog items rebuilds the silhouette, while cancelling/stopping placement destroys all local preview pieces. Server-side placement, charge and persistence remain unchanged.
- Pending Studio validation: check Model:PivotTo preview alignment for all six catalog entries, 0/90/180/270 rotation, occupied and out-of-bounds positions, cancel cleanup, and touch selection. Replace blockout meshes with vetted Creator Store or original assets when sourced and reviewed.

## Construction preview pivot alignment (2026-11-23)

- Corrected client-side 3D silhouette placement: `LocalBuildingSilhouette` now has an invisible noncolliding PrimaryPart named `Pivot` at ground level, matching the server's procedural fallback template pivot.
- `Model:PivotTo` now positions and rotates each silhouette around the footprint origin rather than its bounding-box center, avoiding a discrepancy between preview and final construction.
- New local preview parts start hidden until the first successful island-cell projection, avoiding a flash at the Workspace origin.
- Source was committed to `main`, but Roblox Studio validation is pending. Test house/path/fence positioning after confirmation, 0/90/180/270 rotation, cancel cleanup, and mobile viewport. No third-party models were imported.


## Scenery-proof construction pointer (2026-11-23)

- Updated `IslandBuildingController.client.lua` to raycast using an Include filter containing only the current owner island's `Island_GrassTop`, rather than raycasting the complete world and rejecting the first non-ground hit.
- A player can now target the island ground even when decorations, trees, previously built houses or fences visually overlap the screen-space pointer; existing grid footprint overlap/bounds checks remain responsible for invalidating occupied cells. No server-side construction authorization, payments or persistence changed.
- When the pointer ray misses the island, both the footprint indicator and 3D local silhouette are hidden, preventing a stale preview from remaining visibly green at its last position.
- Verify in Roblox Studio: target a free cell behind a tree; tap an occupied building (red overlap, not accepted); move the cursor/tap outside island (preview disappears); return to grass (preview restores); test mobile camera, moving existing buildings, and island-edge restrictions. The code change is committed, but Studio verification is pending.


## Decorated prototype paths and fences (2026-11-23)

- Replaced the single oversized stone-path slab in `IslandWorldService.createFallbackBuilding` with four deterministically arranged slate stepping stones of varied size and tone. No randomness and no additional save fields: each path segment can still be rotated as before.
- Upgraded the procedural wooden fence with taller posts, lighter post caps, slimmer rails, and a small central wooden ornament.
- Mirrored both shapes in `IslandBuildingController.makePreviewVisual` so the local construction silhouette and fallback server-generated result use matching footprints and major geometry.
- These are still project-owned procedural placeholder models, not reviewed third-party Creator Store assets or finished production art. `ServerStorage/BuildingModels/<catalogId>` custom models take precedence when supplied in Studio.
- Studio runtime visual testing remains pending: create several adjacent path/fence segments, rotate all four directions, verify accurate previews, inspect mobile rendering, saved rejoin, interaction raycast and physics behavior. No construction cost, persistence schema, or server placement validation changed.


## Detailed procedural cottage and pet house (2026-11-23)

- Enhanced existing fallback main house with a roof ridge, window sills, front timber trim and a door knob. Enhanced pet house with a ridge, front corner beams, small windows and a decorative paw-colored badge; models remain fallback prototype art, not approved final assets.
- Updated the in-game construction preview to use corresponding geometry and proportions for both house types; placement costs and saved footprint dimensions remain unchanged. Custom ServerStorage/BuildingModels templates still take precedence.
- Fixed a preview-only defect: the invisible PrimaryPart pivot is excluded from transparency reveal so it stays hidden.
- Studio tests still pending: inspect homes from all angles, confirm front-facing details and preview/final alignment at 0/90/180/270 rotations, verify MainHousePrompt/PetHousePrompt remain usable, and test mobile framerate. Rojo CI build success does not establish runtime correctness.


## Island foliage and resource-node detail pass (2026-11-23)

- Updated procedural perimeter trees with four small leafy canopy clusters in alternating green shades; additional clusters are noncolliding and nonqueryable to avoid blocking movement or build raycasts.
- Added three differently tinted foliage lobes to gatherable wood nodes. Added two slate fragments and two restrained glass highlights to stone nodes. All new details belong to the existing node Model, so its current depleted-node visibility handling can hide them together with the node.
- Resource node IDs, interaction prompt selection, respawn timings, server rewards, DataStore schema, and building placement dimensions are unchanged. This is lightweight prototype geometry, not final vetted Creator Store assets.
- Roblox Studio validation pending: inspect details at mobile resolution, collect a wood node and a stone node, confirm all parts hide while depleted and return appropriately on respawn, verify prompts still work and no duplicate rewards. Check frame-time and part counts on eight concurrent islands before broader environment dressing.


## Perimeter meadow dressing (2026-11-23)

- Added `createEdgeMeadow` to `IslandWorldService.createTerrain`. Eight deterministic edge patches each contain two small green bushes and two pastel blossoms (32 new visual parts per home island), grouped under `IslandEdgeMeadow`.
- The decorations are anchored and deliberately non-colliding, non-touching, non-queryable and shadow-free. They do not occupy building grid cells, change the economy, or require new saved profile fields. The same arrangement is rebuilt when island geometry refreshes.
- These are lightweight procedural prototype decorations rather than approved production art or audited Creator Store assets. The existing arrival pad and central build area remain unchanged.
- Studio verification is pending: inspect plot edges at 24x24, 32x32, and 40x40, check building on/near patch locations, camera view, mobile frame time and eight concurrent islands. At eight islands this addition has up to 256 decorative BaseParts; optimize or replace with vetted mesh clusters if profiling shows a problem.


## Floating island cliff strata (2026-11-23)

- Updated `IslandWorldService.createTerrain` to vary the existing eight perimeter cliff boulders by deterministic size and a controlled four-color stone palette, instead of repeating a single tinted shape.
- Added eight non-interactive, shadow-free slate strata below the walkable grass surface. They provide layering on the island sides without taking building cells, modifying `Island_GrassTop`, adding save fields, or affecting build costs.
- The existing major cliff rocks retain their collision settings; the new strata have `CanCollide`, `CanTouch`, `CanQuery` disabled. This is still procedural prototype art, not final asset production.
- Roblox Studio verification is pending: inspect cliffs from multiple camera angles, confirm strata remain below the top and do not obstruct characters or building placement, test differing island sizes/expansions and mobile part-count/performance. Eight extra decorative parts are created per island.


## Optional island meadow density (2026-11-23)

- `IslandWorldService.createEdgeMeadow` now reads the optional numeric `Workspace.IslandDecorationLevel` attribute when islands are generated. Default / 1 builds one bush plus one blossom per each of eight edge patches (16 cosmetic parts instead of 32). Level 0 disables the optional meadow; level 2 restores all 32 parts. Values are clamped to 0..2.
- This is server-wide level configuration read when generating an island, **not** an automatic per-device graphics quality setting. Existing world structures, resource nodes, rewards, building cells and persistence are unchanged. Level 0 has no meadow parts; a folder still exists. Changing the attribute does not retroactively modify spawned islands.
- Eight simultaneous islands use 128 meadow parts in default mode instead of 256; this is a geometric part-count reduction, not a measured FPS gain. Studio/mobile profiling and visual checks at each level are pending. Avoid claiming performance gains without tests.


## Construction transaction UI race fix and CI visibility (2026-11-23)

- Audited `IslandBuildingController.client.lua` remote request flow. The previous `PlaceBuilding:InvokeServer()` call yielded while `selectedCatalogId`, grid X/Z, rotation and movement ID were still mutable; response status could therefore describe another selected item. Repeated confirmations and mode edits were possible while pending.
- The controller now snapshots the full request payload before invoking the server, tracks `buildRequestInFlight`, blocks placement edits, rotation, cancel, new placement and repeat confirms while pending, and resolves messages using the snapshot. The existing request-ID retry mechanism is retained.
- An attempt to read combined GitHub commit statuses for the previous main commit yielded no status entries; the connector's commit-workflow-runs endpoint also yielded no runs because it filters to pull-request-triggered runs. **This does not establish a successful or failed push-triggered Actions run.** Check GitHub Actions directly.
- Still unverified in Roblox Studio: rapid double-tap Confirm, rotate/catalog switch while a slow server reply is pending, switching UI panels, server rejection, timeout/retry, move vs new build, and mobile touch inputs. These cases must pass before marking the building transaction UX DONE.


## Construction request and exclusive-panel interaction (2026-11-23)

- Fixed a UI overlap scenario in `IslandBuildingController.client.lua`: if another Pet Kingdoms panel opens while `PlaceBuilding:InvokeServer` is outstanding, the construction panel now hides immediately and its cleanup is deferred until the reply resolves. Server transaction and idempotency remain intact.
- `openKingdomOverview()` now closes construction before announcing its own overview, while a pending request is deferred; handling other panels through `PetKingdomsPanelSignal` uses the same pending-safe path. After success, the normal construction stop logic runs. After failed or thrown remote response, a deferred stop runs so a hidden build operation cannot continue owning input.
- The request snapshots catalog ID, cell coordinates, rotation and moving instance ID and blocks other edits and repeat confirms while waiting (prior commit).
- Studio tests pending: slow build + open journal/collection, slow build + open overview, server rejection while another panel is open, repeated rapid confirm, slow move, and close/reopen after a response. No GitHub Actions or Roblox runtime success is claimed.


## Demolition request serialization (2026-11-23)

- `IslandBuildingController.client.lua` now tracks a separate `demolitionRequestInFlight` state. A second confirmation or an island click cannot select a different building while the delete RemoteFunction is awaiting a response. Start-build and move-building buttons are also guarded during demolition.
- Before yielding, the controller captures the target `BuildingInstanceId` and marks Delete and Move inactive. On return (success, server error, or transport failure) it releases the guard, restores buttons, and clears the confirmation arm. Success deselects the removed building. The existing idempotency request ID is retained for transport failures and retryable server replies so retries will use the same transaction key for that target.
- Added localized explanations for missing/protected buildings, busy/in-progress server operations, save timeouts and rate limits. The server-owned deletion authorization, protected main house, resource rewards and persistence format were not changed.
- Roblox Studio test gate remains open: double-tap Delete, tap another object while Delete is pending, tap Move/Build while pending, retry a transient server fault, remove an already-removed object, switch to another panel mid-delete, and verify that another user cannot delete a building on someone else's island. No runtime test has been claimed.


## Mobile construction width fitting (2026-11-23)

- Updated `IslandBuildingController.client.lua` so the three construction action buttons size against the panel's actual padded content width (`panelWidth - 28`) and include their two 8px layout gaps. On narrow screens Rotate and Cancel become icon-only, with Confirm taking all remaining width.
- Lowered the panel minimum width from 260 to 220 px and use viewport-based panel width, avoiding the prior fixed 260px minimum on very narrow phones. The selection Move and Demolish actions now size and position as a pair against viewport width instead of fixed X offsets that could clip the latter button.
- This is responsive source code, not an emulator or Roblox Studio test. Verify at 320x568, 360x640, 375x667, 390x844 and landscape viewports; check safe areas, click hitboxes, text fit, player controls, move/demolish confirm, and panel changes while a server request is pending. Very small viewports below 236 px still need separate design review.


## Mobile building tap-versus-swipe guard (2026-11-23)

- `IslandBuildingController.client.lua` now handles single-finger world selection on `UserInputService.InputEnded`, not `InputBegan`. The touch must begin unprocessed and outside interactive GUI, must remain within an 18px movement threshold, and must end outside interactive GUI. Additional simultaneous touches invalidate the pending tap so camera pinch/rotate does not accidentally lock a building footprint.
- The shared `chooseWorldPoint` action is used for mouse clicks and touch taps; `PlayerGui:GetGuiObjectsAtPosition` checks for visible `GuiButton`, `ScrollingFrame` or `TextBox` under the pointer, avoiding fallthrough through controls. A fresh CurrentCamera is used to raycast building selection.
- This is a code-level safety guard; Roblox Studio/device simulator tests are outstanding. Check touch rotate-camera, joystick use, two-finger pinch, tap next to on-screen controls, open build panel, tap grassy cell, tap action buttons, close overlapping windows, and mouse selection. On some platforms mouse emulation may follow touch: validate that only one world selection is triggered.


## Touch world-selection hardening (2026-11-23)

- The construction controller now tracks all active Touch `InputObject`s, rather than tracking only a single candidate. Any multi-finger gesture invalidates world selection until every participating finger has lifted; the remaining finger cannot become a late building tap.
- Single-finger world selection is accepted only on release, with movement <=18 screen pixels and duration <=0.55 seconds, beginning outside interactive GUI and retaining the same building/selection mode until release. These limits prevent held touches, camera gestures, and panel transitions from changing a construction cell unintentionally.
- A short 0.35s window after touch begin/end ignores synthetic `MouseButton1` events on touch-enabled clients, reducing duplicate selection from touch emulation; physical mouse still works normally outside that window.
- Source change is pushed to main, but Roblox Studio and physical mobile runtime verification remains pending. Test tap vs long press, two-finger pinch/camera rotation, mobile joystick, touches on catalog/actions, touching while switching panels, touch followed by mouse, touch event ordering, and both mouse-only and hybrid laptops.


## Construction full-flow audit: move mode and panel focus (2026-11-23)

- Audited the live client code path for catalog selection, placement, move, demolition and exclusive panels.
- Move now announces its own panel opening through the shared `PetKingdomsPanelSignal`, preventing open journal/collection screens from overlapping the construction canvas. The moved item's original catalog type is selected before its `movingInstanceId` lock is applied; subsequent attempts to switch to a different catalog ID are rejected until the move exits. The guard also ignores catalog changes during demolition requests.
- Repaired the failed-`createPreview` move rollback to re-enable `flowerBedButton` and `woodenFenceButton` alongside the other catalog buttons; previously those two remained disabled.
- On panel switches originating from other controllers, the selected-building action buttons are dismissed by clearing selection except while a demolition transaction is in flight. No server-side record schema, costs, idempotency or island geometry changed.
- Studio validation remains outstanding: move each of six catalog objects, cancel and resume, rotate while moving, force a preview creation failure, try tapping another catalog button mid-move, open quest/collection while selection actions are visible, and verify the original model remains until server confirms movement. CI build is not a Roblox gameplay test.


## Construction / kingdom overview exclusive navigation (2026-11-23)

- Fixed a panel-transition bug in `IslandBuildingController.client.lua`: entering normal construction or Move now explicitly dismisses the kingdom overview before showing the construction panel; the shared panel signal alone did not close panels owned by the same controller.
- Opening kingdom overview now clears any selected-building Move/Demolish action buttons (except during an outstanding demolition request). This prevents selection actions from floating over overview UI.
- Added a dedicated 40x40 `CloseConstruction` button at the upper-right of the build panel, wired to the existing safe `stopPlacing` cancellation path. The title reserves width for this button; in-flight build requests still cannot be cancelled mid-transaction.
- Code changes are in main, but **Roblox Studio/gameplay verification is pending**. Verify Overview -> Build, Build -> Overview, Move -> Overview, close button on 320/360/390px screens, selection action overlap, slow server request while opening Overview, and keyboard/mobile interaction. Do not mark the UI release-ready before device testing.


## Stale building selection cleanup (2026-11-23)

- `IslandBuildingController.client.lua` now observes `Destroying` on the selected building Model. If a server refresh, external removal, or another authoritative world sync destroys that model, the controller disconnects the old observer, clears the selection and hides/disables Move/Demolish rather than retaining a stale reference.
- Selecting another model or clearing selection disconnects the previous observer first. The handler checks object identity and does not interfere with an active demolition transaction.
- This guards stale UI state; it does not alter server authorization or removal persistence. Roblox Studio test pending: select a building, remove it through server/world refresh, verify action buttons disappear; rapidly select A then B and destroy A; demolish B and ensure no stale observer clears the new selection; respawn/rebuild and select again.


## Building upgrade system — server foundation (2026-11-23)

- Added server-owned upgrade definitions to `BuildingCatalog`: main house and pet house support levels 1–3; path, lantern, flower bed and fence support levels 1–2. Resource costs are defined per target level in the catalog, never accepted from the client.
- Added `action = "upgrade"` to `IslandBuildingService`. Server validates the owned instance ID, catalog eligibility, current level, max level and resource balances; charges resources, increments `upgradeLevel`, synchronizes the world model, and records a durable idempotent operation using `IslandSessionService.commitBuildingOperation`. On sync/commit failure, record and resources are restored and world sync is attempted.
- Upgrade requests now fingerprint as their own journal action (not `place`), preventing idempotency collisions with other operation types.
- `IslandWorldService` stamps `UpgradeLevel` on models both during initial island spawn and later sync. Legacy records without a level display as level 1 without requiring destructive migration.
- IMPORTANT: this is only the server/data foundation. No upgrade button, cost preview, confirmation UI, upgrade effects or final art changes have been added yet. The configured costs are initial balancing placeholders and must be playtested. No Roblox Studio test or CI success is claimed. Next step: client selection panel with level, server-sourced available action and resource cost; then verify success, insufficient resources, max level, repeated requests, save/rejoin, rollback and other-player isolation.


## Stage 1 — Interface & usability: pet collection modal lifecycle fix (2026-11-23)

- Fixed a nested-modal lifecycle bug in `PetCollectionUI.client.lua`: closing the collection now also hides its destructive delete-confirmation panel. Reopening the collection never resurrects a stale confirmation dialog from the previous visit.
- If no remote operation is active, the pending delete target is cleared on close/open. If a delete request is already in flight (`busy`), the target is retained until the transaction returns so the in-flight operation is not mutated/cancelled by a UI close.
- This is one focused Stage 1 fix, not completion of the interface section. Remaining audit: consistent close/backdrop behavior across Collection, Journal, Expansion and Building; safe-area and viewport checks; modal focus/z-index; close controls; loading/error/empty states; touch targets; verify all transitions in Studio. No runtime verification claimed.


## Stage 1 — Interface & usability: Escape closes topmost modal layer (2026-11-23)

- Added Escape-key dismissal for Pet Collection, Quest Journal and Island Expansion. Handled input is ignored so focused text boxes/gameplay input are not stolen.
- Pet Collection follows modal stacking: if the destructive delete confirmation is visible, Escape dismisses only that confirmation and clears its pending target; a second Escape closes the collection. It does not cancel an already-running server transaction.
- Quest Journal and Island Expansion close through their existing `setOpen(false)` paths, preserving their normal cleanup (including clearing island world preview).
- This improves desktop keyboard usability only. Roblox Studio verification remains required; mobile users still need visible close/back controls. Building placement already maps Escape to cancel; kingdom overview Escape behavior remains to audit. Stage 1 is not complete.


## Stage 1 — Interface & usability: short-viewport modal fit (2026-11-23)

- Quest Journal and Island Expansion now use a child `UIScale` to fit their fixed-height layouts into short/landscape viewports, rather than clipping the top close button or bottom actions. Scale is derived from current viewport height and clamped to 0.72–1.0; viewport-change listeners already call `resize()` and now update the scale too.
- Reduced minimum size constraints to 250x300 (Quest Journal) and 250x320 (Island Expansion), allowing narrow phone widths while keeping a sensible minimum. The quest list remains scrollable; expansion information cards scale as one composition.
- This is a targeted responsive correction, not a full mobile sign-off. Verify 320x568, 390x844, 568x320 and tablet/desktop sizes in Studio; inspect text legibility at minimum scale, button hitboxes, safe-area inset, and expansion preview cleanup. Pet Collection and Building have separate responsive logic and still need the same viewport audit. No runtime verification claimed.


## Stage 1 — Interface & usability: dismiss modal by backdrop click (2026-11-23)

- Converted the full-screen dimming layers for Pet Collection, Quest Journal and Island Expansion from passive `Frame`s to transparent-text `TextButton`s (`AutoButtonColor=false`). Their existing visual dimming is preserved, while tapping outside the child panel now dismisses the active modal through its normal close path.
- Pet Collection handles nested state safely: tapping the backdrop while delete confirmation is visible dismisses only that confirmation and clears its pending target; a second backdrop tap closes the collection. An in-flight server deletion remains untouched.
- Quest Journal and Island Expansion backdrop taps call their existing `setOpen(false)` path, preserving quest and world-preview cleanup.
- The Building kingdom overview already uses an activated full-screen backdrop button; construction's main panel uses its own close/cancel button and is intentionally not backdrop-dismissed during an active placement transaction.
- Studio verification pending: tap panel content and confirm no accidental close; tap backdrop; test delete confirmation backdrop twice; tap close buttons; open another modal during close animation; verify no stuck dim layer or input capture. No runtime verification claimed.


## Stage 1 — Interface & usability: collection modal transition consistency (2026-11-23)

- Pet Collection now fades its backdrop in/out consistently with Quest Journal and Island Expansion. The panel still animates into place; closing hides the child panel immediately and fades the backdrop before releasing it.
- Added a modal revision token so a delayed close callback cannot hide the backdrop after a fast reopen. Repeated close calls are idempotent, and reopening invalidates an earlier pending hide.
- Delete-confirmation cleanup and in-flight deletion safety are preserved. This is a focused modal-lifecycle polish, not a unified modal manager; the four scripts still use the shared BindableEvent convention and need full Studio transition/overlap verification.
- Test pending: spam open/close/backdrop/Escape, switch to Journal/Expansion during both open and close animation, start a delete request then close, reopen before fade completes, and confirm no stale dim layer or input capture. No Studio verification claimed.


## Stage 1 — Interface & usability: shared modal coordinator (2026-11-23)

- Added `ReplicatedStorage/Shared/ModalManager.lua` as the single client-side coordinator for top-level windows. It registers close handlers, opens one named modal at a time, closes every other registered window before assigning focus, exposes the active modal, and supports explicit close/unregister/close-all operations. Nested dialogs remain owned by their parent modal.
- Migrated Pet Collection, Quest Journal, Island Expansion and Island Building/Kingdom Overview from the ad-hoc `PetKingdomsPanelSignal` BindableEvent to the shared manager. Switching windows now invokes the previous window's normal close path, preserving each feature's cleanup.
- Construction keeps an in-flight server transaction intact when another modal opens; it hides the construction UI and closes after the response as before. Normal placement cancellation and kingdom overview dismissal now release modal focus so stale active-window state does not persist.
- The manager closes all other registered handlers, not only the remembered active one, so it can recover if a UI's visible state drifts from manager state. Handler errors are isolated with `pcall` and warnings.
- This is a code integration, not a completed UI sign-off. Studio checks pending: all 12 ordered transitions among four windows, repeated open/close, close via backdrop/Escape/X, opening while a placement request is pending, overview-to-build transition, and verifying no stale shade or input lock. Also verify no script still depends on `PetKingdomsPanelSignal` and inspect startup ordering. No runtime test claimed.


## Stage 1 — Interface & usability: shared visual theme foundation (2026-11-23)

- Added `ReplicatedStorage/Shared/InterfaceTheme.lua` with frozen semantic color tokens, typography roles, motion durations and corner-radius tokens.
- Migrated Pet Collection, Quest Journal, Island Expansion and Island Building/Kingdom Overview to the same shared color palette. Existing intent-based names (`text`, `valid`, `invalid`, `panelLight`, `track`, etc.) are retained as semantic aliases, reducing per-screen color drift.
- The building UI's formerly separate purple panel palette now uses the same dark slate/cream/gold/mint family as the other main windows. This is a foundational consistency pass, not a final visual redesign: typography and motion tokens are defined but not yet consumed consistently, and layouts/icons/buttons still need review.
- Static source audit confirms all four scripts' referenced `COLORS.*` keys exist in the shared palette. No Roblox Studio runtime test, visual approval or mobile sign-off is claimed.
- Next Stage 1 task: migrate common typography/motion/radius usage and review shared button/close-button patterns, then inspect screenshots at desktop and mobile sizes before declaring the design system complete.


## Stage 1 — Interface & usability: shared close button component (2026-11-23)

- Added `ReplicatedStorage/Shared/InterfaceComponents.lua` with `StyleCloseButton(TextButton)`. It applies the shared 40x40 hit target, semantic panel background, standard × glyph, shared display font, cream text, medium corner radius and subtle gold outline. Existing buttons retain their screen-specific close callbacks and ZIndex.
- Migrated the close buttons in Pet Collection, Quest Journal, Island Expansion and Island Building to the shared style helper. Aligned the first three to the same top-right header inset; construction keeps its panel-edge placement while sharing the same visual component.
- The shared component obtains its colors/typography/radii from `InterfaceTheme`, so visual adjustments now have one source of truth. Static source inspection confirms all four scripts call the helper after creating their button. Visual hit-target and overlap verification in Roblox Studio remains pending, especially on 320px-wide screens. No visual approval or mobile sign-off claimed.


## Stage 1 — Interface & usability: semantic action button styles (2026-11-23)

- Extended `ReplicatedStorage/Shared/InterfaceComponents.lua` with `StyleActionButton(button, variant)`. Supported semantic variants: `primary` (mint), `secondary` (slate), `danger` (rose/red), and `gold` (reward/highlight). The helper standardizes text contrast, font, 12–16px text size, rounded corners, subtle outline and interaction color behavior.
- Migrated key actions: construction rotate/confirm/cancel; pet interaction/play/equip/favorite/delete and delete confirmation/cancel; island expansion refresh. Existing button event handlers, enabled state logic and request flows remain unchanged.
- Dynamic quest tracking buttons and per-pet list selection buttons were intentionally left alone in this pass because their colors encode live selection/progress state; they need state-aware styling rather than a static variant.
- Static audit confirms all helper imports and calls are present in the migrated scripts. Roblox Studio visual verification is still pending: confirm text legibility, touch targets, contrast, disabled/loading state appearance, and that runtime state updates are not visually overridden. This is a shared component foundation, not a full UI polish sign-off.


## Stage 1 — Interface & usability: shared card styling (2026-11-23)

- Added `StyleCard(GuiObject, variant)` to `ReplicatedStorage/Shared/InterfaceComponents.lua`. It applies shared corner radii and subtle semantic outlines; `surface`, `highlight` and `compact` variants support standard content, important next-step cards and dense cards.
- Migrated Quest Journal quest cards, Island Expansion current/next level cards, and Pet Collection detail surface to the shared helper. The next island level card uses the highlight treatment; the current level and other content use the neutral surface treatment.
- Dynamic pet-list selection/equipped outlines and construction catalog selection strokes remain state-driven and were not overwritten by the static helper. This preserves selection semantics.
- Static source audit only. Roblox Studio visual testing remains pending for clipping, nested stroke ordering, text contrast, narrow screens, and runtime state transitions. Building catalog and kingdom overview card surfaces still need a deliberate state-aware migration.


## Stage 1 — Interface & usability: shared typography scale (2026-11-23)

- Added semantic text sizes to `InterfaceTheme.Typography.Sizes`: Display 22, Heading 18, Body 14, Caption 12, Micro 10, Numeric 20. Existing Gotham font roles remain centralized.
- Added `InterfaceComponents.StyleText(TextLabel, role)` to apply role-based font, size and non-scaled text consistently.
- Migrated Pet Collection and Quest Journal main titles/subtitles, and Island Expansion title/subtitle/current-level/next-level labels. This is a targeted header hierarchy pass; dynamic content, body copy and small status labels retain their existing sizes until individually reviewed for fit.
- Static source audit confirms helper and role definitions exist in the shared modules and the three migrated screens call them. Roblox Studio visual checks remain pending: title clipping at 320px width, long localized strings, font legibility at minimum scale, and construction/kingdom overview typography consistency. No runtime or visual sign-off claimed.


## Stage 1 — Interface & usability: shared notification system (2026-11-23)

- Added `ReplicatedStorage/Shared/NotificationManager.lua`, a client-side toast stack using the shared theme. It supports success, info, warning, error and reward variants; semantic accent/icon treatment; short entrance/exit tweens; configurable duration clamped to 1.5–8 seconds; and a four-toast visible cap.
- Replaced the Quest Journal's private completion-toast implementation with the shared manager. Quest completion now uses the common success style.
- Integrated global feedback for Island Expansion preview failures and construction outcomes (successful place/move/demolish and server/network rejections). Existing contextual status text remains in each panel, so detailed guidance is still available.
- Static source checks confirm the manager and integrations exist. Studio verification pending: multiple simultaneous notifications, mobile width/text wrapping, safe-area positioning, toast overlap with other HUD elements, success/error contrast, and rapid expiry/removal. No runtime or visual sign-off claimed.


## Stage 1 — Interface & usability: reusable loading button state (2026-11-23)

- Added `InterfaceComponents.SetButtonLoading(TextButton, isLoading, loadingText?)`. It stores the button's original text, Active and AutoButtonColor values, disables interaction during the request, displays a localized progress label, and restores the exact prior values afterward. Repeated enter/exit calls are idempotent.
- Integrated the helper into Island Expansion refresh, Quest Journal track/untrack action, Building placement confirmation, and demolition. Existing request guards (`loading`, `busy`, `buildRequestInFlight`, `demolitionRequestInFlight`) and server validation remain in place; this is presentation-state reuse, not a replacement for transaction guards.
- Static source checks confirm helper and integrations. Roblox Studio verification pending: slow response, server rejection, thrown InvokeServer, rapid double taps, switching windows mid-request, and correct restoration of original labels/disabled states. Important limitation: this change does not impose a network timeout on RemoteFunction calls; if the server never returns, the current request coroutine can still remain pending. A bounded request timeout/recovery pass remains separate work before claiming the no-stuck guarantee.


## Stage 1 — Interface & usability: bounded waits for read-only requests (2026-11-23)

- Added `ReplicatedStorage/Shared/RequestRunner.lua`. It executes a supplied RemoteFunction callback in a separate task, waits up to a bounded 2–30 seconds (default 12), and returns a structured `{ ok, value, errorCode }` result. A timeout stops waiting in the UI coroutine and discards a late client result.
- Integrated the bounded wait into read-only requests: Island Expansion preview refresh, Quest Journal data refresh, and Pet Collection `Get`. On timeout, each screen exits its loading state and shows retry guidance; Quest Journal and Island Expansion also use the shared notification manager.
- Pet Collection's `Get` returns multiple values, so its callback explicitly wraps them with `table.pack` before passing through the single-value runner. This preserves the success flag and collection payload.
- Important semantic limitation: Roblox RemoteFunction calls cannot be cancelled by this client timeout. The server may still finish the original request later; the late result is ignored. Therefore this helper is currently used only for read-only refreshes. Mutating operations (place/move/demolish, pet equip/delete/interact, quest tracking) are deliberately not wrapped until each path has safe server-side idempotency/reconciliation, so a timeout cannot invite duplicate or ambiguous actions.
- Static source checks confirm the three integrations, timeout branches, and loading cleanup. Roblox Studio tests pending: simulate delayed responses above/below 12s, thrown RemoteFunction errors, repeated refresh after timeout, closing/reopening panels during wait, and confirm no stale loading state. No runtime verification claimed.


## Stage 1 — Interface & usability: bounded building mutations with idempotent retry protection (2026-11-23)

- Audited the existing server transaction path before changing the client. `IslandBuildingService` already validates request IDs, fingerprints payloads, returns cached results for exact retries, rejects request-ID/payload conflicts, and checks the persisted `IslandBuildingJournalData` ledger. The durable journal retains successful receipts for seven days and distinguishes in-progress/unpersisted revisions. This pre-existing server protection is the basis for safely retrying the exact same place/move/demolish request.
- Integrated `RequestRunner.Invoke(..., 12)` into building placement/move and demolition. The UI now exits loading after the bounded wait. A timeout is described as an unknown result, not as a failed operation; the original request ID remains associated with the exact operation key so retrying the same payload returns the prior result or an in-progress status instead of charging/creating a second building.
- Added a client-side unresolved-operation guard. While a building result is unknown or the server reports an in-progress/busy/persistence state, a different building mutation is blocked until the same operation is retried and resolved. The operation key includes action and immutable payload fields; demolition keys include the target instance ID.
- Important UX limitation still open: the player must preserve the same placement/move target and coordinates to retry the exact request. Closing/cancelling the placement UI after a timeout can make a move retry harder because its original selection state may be cleared. A dedicated “check/retry pending operation” recovery control should be added before this flow is considered complete. Do not clear unresolved request IDs on timeout/network errors.
- Static audit confirms the client runner integration, operation-key guard, server request fingerprint/cache and durable journal. No Studio runtime test or simulated packet-loss test has been run. Next verification: force a delay past 12 seconds, retry the exact operation, confirm one charge/one building; retry with changed coordinates and confirm the client blocks it; test demolition; test panel close during a pending move; test server busy/persist timeout recovery.


## Stage 1 — Interface & usability: pending-operation recovery UI (2026-11-23)

- Added a compact, persistent top-of-screen recovery panel to the island construction GUI. It appears only while a building operation has an unknown or server-reported in-progress/busy/persistence result. It identifies the operation and offers a single “ПРОВЕРИТЬ РЕЗУЛЬТАТ” action.
- The client now retains the exact request payload and request ID for timed-out/uncertain placement, move, and demolition operations. The recovery action resends that exact payload through the bounded 12-second RequestRunner; it does not reconstruct coordinates or create a new request ID. Successful duplicate receipts resolve the panel; server in-progress/busy/persistence states and timeouts keep it available for another check. Definitive non-pending responses clear the pending state.
- Fixed a pre-existing UI guard ordering issue in demolition: a conflicting pending operation is now checked before loading/disabled state is entered, so the early return cannot leave the demolition button stuck.
- Static source checks confirm the recovery panel, retained payload, forward-declared callbacks (Luau lexical scope), exact-payload retry, and integration for build/move/demolish. Roblox Studio/device verification has not been run. Required tests: timeout followed by successful exact retry; operation still in progress; panel close during move then recovery; demolition after timeout when selected model disappears; different operation blocked while pending; narrow mobile viewport; reconnect/rejoin behavior (pending recovery is currently client-session scoped, not persisted across reconnect).
- Remaining limitation: the recovery panel is session-local. If the player disconnects or the client resets before resolving the operation, this panel state is lost. The server journal still prevents duplicate successful operations for the same ID, but the client does not yet persist pending intent across reconnect. Do not mark the recovery UX complete until Studio/device tests pass.

- Follow-up verification: GitHub Actions Roblox project build succeeded on source commit `edfd36d` (run `45138284051`). This verifies the Rojo project build pipeline only; it is not a substitute for Roblox Studio runtime/device testing.


## Stage 1 — Interface & usability: modal focus coordination (2026-11-23)

- Hardened `ReplicatedStorage/Shared/ModalManager.lua`: registered modal names are closed in deterministic sorted order on focus changes; close handlers are isolated with `pcall`; focus is cleared before peer windows close; added `IsActive(name)`; `CloseAll()` now invokes every registered close handler to repair stale visibility instead of closing only the remembered active window.
- Updated Island Expansion, Quest Journal, Pet Collection, and Island Building Escape handling to act only when their top-level window owns modal focus. The construction overview is now dismissed by Escape before exiting placement, and nested pet deletion confirmation still closes before its parent collection.
- Added `Tests/ModalManagerTests.client.lua`, a Studio-only smoke suite gated by `RunPetKingdomsStudioTests`, covering focus transfer, peer closure, CloseAll cleanup, active-window checks, and unregister behavior. The suite is committed but not yet executed in Roblox Studio.
- Static source checks passed for the new APIs and all four client integrations. Roblox project build CI was triggered by test commit `a47e990`; check run `45138727077` before claiming CI success. Remaining runtime checks: open each modal from every other modal, rapid switch/reopen during close tweens, Escape with nested dialogs, CloseAll during a pending request, and phone/tablet input.


## Stage 1 — Interface & usability: narrow/short viewport fixes (2026-11-23)

- Updated the Kingdom Overview in `IslandBuildingController.client.lua`: its width now follows the active viewport, the minimum width no longer forces a 300 px panel on narrow phones, and a dedicated UIScale keeps the full 286 px card within short landscape viewports. Typography is reduced on compact screens. The overview rebinds to CurrentCamera and recomputes on viewport changes and every open.
- Fixed a mobile overlap between the pending-operation recovery panel and the Move/Demolish action row. On compact viewports the action row moves down while recovery is visible and returns to its normal position after the pending operation resolves.
- Static source checks passed for both responsive paths. Rojo CI for the overview change passed (`45139077658`). CI for the latest overlap fix is queued (`45139112446`) at time of this note. No Roblox Studio/device runtime testing has been performed.
- Next mobile audit targets: inspect Pet Collection's two-column layout at 320–375 px, test Quest Journal/Island Expansion in short landscape, and review Resource HUD plus all floating action buttons for safe-area/notch collisions. Then run Studio touch tests and update the Stage 1 checklist.


## Stage 1 — Interface & usability: Pet Collection single-column mobile flow (2026-11-23)

- Reworked the Pet Collection layout for viewports narrower than 650 px. Search, filters, and pet list now occupy the full panel width; selecting a pet switches to a dedicated detail screen instead of squeezing the list and details into two narrow columns. Added an explicit “К СПИСКУ ПИТОМЦЕВ” back action. Desktop/tablet wide layout remains two-column.
- Mobile detail uses the existing full-height detail card and its responsive viewport preview; the delete-confirmation dialog now scales to the available screen width and its two action buttons receive a larger 40 px height on compact layouts.
- `resize` is forward-declared so pet-card callbacks can safely call it in Luau lexical scope. The viewport handler continues to rebind when CurrentCamera changes.
- Static source checks passed for compact list/detail visibility, back navigation, resize forward declaration, and bounded confirmation width. CI run `45139318637` for the first mobile-flow commit passed; follow-up build for confirmation scaling (`45139348449`) was still running at documentation time. No Roblox Studio/device runtime testing has been performed.
- Next: test 320/360/390 px portrait and short landscape, selection/back while list is scrolled, opening delete confirmation on a phone, no-pets/empty-filter states, and orientation changes while the collection is open. Continue the mobile audit with Quest Journal, Island Expansion, and Resource HUD.


## Stage 1 — Interface & usability: Quest Journal mobile readability and recovery (2026-11-23)

- Added an explicit refresh button to the Quest Journal header. Previously the timeout/error status instructed the player to press refresh even though no refresh control existed.
- On viewports narrower than 520 px, quest cards now use a taller vertical layout: full-width title, wrapped two-line description, separated progress row, and a dedicated tracking action lower in the card. Desktop card layout is unchanged. Follow-up adjustment separates the mobile tracking button from the progress row to avoid overlap.
- Quest tracking now uses the bounded 12-second `RequestRunner` rather than an unbounded direct `InvokeServer` wrapped in `pcall`; the UI can recover from a stalled response instead of waiting indefinitely.
- The tracked-quest HUD truncates long names rather than overflowing. Responsive sizing now rebinds to the active CurrentCamera's ViewportSize signal and updates the panel constraints for narrow screens and short landscape. Tracker width is bounded by viewport width.
- Static source checks passed for refresh control, mobile wrapped descriptions, tracking timeout, camera rebind, and separated card actions. CI run `45139613564` passed for the main changes; follow-up CI for the final spacing adjustment (`45139635202`) was in progress when recorded. No Roblox Studio/device runtime tests have been run.
- Next verification: 320/360/390 px portrait, short landscape, long localized quest titles/descriptions, tracking timeout/retry, refresh while loading, tracked HUD clipping, and open modal during orientation change. Then continue Stage 1 audit with Island Expansion and Resource HUD.


## Stage 1 — Interface & usability: Island Expansion preview UX (2026-11-23)

- Improved narrow/short viewport behavior in `IslandExpansionUI.client.lua`: viewport-aware panel constraints now avoid forcing the former 250 px minimum onto very narrow screens; title/value/status/button typography scales for compact layouts; the refresh action has a 44 px touch target; long level/dimension values truncate instead of spilling outside cards.
- Responsive handling now disconnects the old camera's ViewportSize listener and binds to the current camera, so orientation/viewport updates remain observed after CurrentCamera replacement.
- Corrected misleading copy: the panel is a geometry preview only and explicitly says expansion purchase is not implemented. It does not imply the player can currently buy/unlock expansion.
- Hardened preview rendering against malformed/inconsistent server dimensions: current dimensions must be positive, next dimensions must exceed current dimensions, and required level/size/max-level fields must be numeric before formatting. This avoids division-by-zero and malformed UI output.
- Source commits: `810e420` (responsive preview UX), `357cfd8` (dimension validation). CI runs `45139857411` and `45139876120` were still running/queued at documentation time. No Roblox Studio/device runtime tests have been performed. Purchase affordability/confirmation is intentionally not implemented because the existing remote is read-only (`GetIslandExpansionPreview`); do not add a client-only fake purchase flow. Next tests: 320/360/390 px portrait, short landscape, missing island model, malformed preview payload, maximum level, and world preview cleanup when switching modals/closing.


## Stage 1 — Interface & usability: Resource HUD compact layout (2026-11-23)

- Replaced the four-across resource strip with a responsive `UIGridLayout`: desktop retains four resource chips in one row; compact screens below 560 px use a two-by-two layout with a 92 px bar. On very narrow screens (<360 px), icons and values shrink further and long balances/resource labels truncate rather than overlap.
- Adjusted the kingdom-bond label and gather toast positions/sizes for the taller mobile HUD so they no longer occupy the same vertical band as the resource bar. The bond label is narrower and uses smaller text on tiny screens.
- Rebound the ViewportSize listener safely when `Workspace.CurrentCamera` changes, disconnecting the previous camera connection instead of accumulating listeners.
- Replaced the initial wallet snapshot's unbounded direct InvokeServer/pcall with the shared 12-second RequestRunner, retaining bounded retry/backoff behavior. Live server push updates remain authoritative.
- Static checks passed for grid layout, compact/tiny sizing, truncation, viewport rebinding, and bounded initial fetch. CI run `45140354173` was running when this note was added. No Roblox Studio/device tests have been performed. Next verify 320/360/390 px portrait, desktop 1280+, toast while collecting, long balances, bond label, respawn/camera replacement, and server push ordering.


## Stage 1 — Interface & usability: floating launcher collision audit (2026-11-23)

- Audited the persistent launchers across Pet Collection, Island Expansion, Quest Journal, and Building. Found a real compact/touch collision: Pet Collection had a legacy touch-only override placing its launcher at Y=0.72, directly on top of Island Expansion's Y=0.70 launcher.
- Removed the one-off touch override and moved launcher placement into Pet Collection's shared responsive `resize()` path. On compact screens the pet launcher is now 52×52 at the right edge, Y=0.46; on wider screens it remains 62×62 at Y=0.55. Island Expansion is 52×52 at Y=0.72 on compact screens (62×62 at Y=0.70 otherwise). This creates a deliberate vertical gap on phones while retaining desktop positions.
- Quest Journal remains on the opposite (left) edge with a 50 px compact target; Build remains top-right with a 154×48 target. All these ScreenGuis retain the default safe inset behavior (`IgnoreGuiInset=false` or default false), so top controls respect Roblox's GUI inset.
- Static checks passed for responsive launcher positions/sizes and existing camera viewport rebinding. Pet launcher CI `45142089887` passed; expansion launcher CI `45142096293` passed. No Studio/device touch test has been performed. Remaining: test simultaneous visibility, 320/360/390 px portrait, short landscape, top safe inset/notches, and interaction with build selection/recovery controls and tracked quest HUD.


## Stage 1 — Interface & usability: shared visual styles (2026-11-23)

- Added `InterfaceComponents.StyleFloatingButton(button, variant)` as the single shared visual treatment for circular world launchers. It applies the shared theme's panel/cream colors, circular radius, accent outline (gold/mint/rose), consistent typography, and interaction settings without overriding responsive size or position.
- Applied the shared launcher style to Pet Collection (mint accent), Island Expansion (gold), Quest Journal (gold); Build entry uses the existing shared `StyleActionButton(..., "gold")` instead of its bespoke visual treatment.
- Standardized Quest Journal's Track action with `StyleActionButton` and compact text truncation. The active state label is now the short Russian `СЛЕЖУ`, so it remains legible at the shared minimum action-button font size instead of clipping a long word.
- Existing close buttons, modal cards, pet actions, expansion refresh, and building actions already used shared component helpers; this pass extends coverage to the floating launchers and quest tracking. Static checks confirm all four launchers call the shared helper and quest tracking no longer has a duplicate one-off corner style.
- CI passed for shared component addition and each launcher application (`45142855564`, `45142875810`, `45142881523`, `45142889014`, `45142895588`); quest tracking style CI `45142944796` passed. Latest label-shortening change is commit `7f35991`; its CI should be checked before treating the final pass as green. No Roblox Studio/device visual regression has been run.
- Next: unify status badges/empty/error states and audit typography/spacing in the remaining building and resource interfaces. Do not begin Stage 2 until Stage 1's visual audit and Studio/device regression are complete.


## Stage 1 — Interface & usability: responsive global notifications (2026-11-23)

- Updated `NotificationManager` toast sizing for narrow screens: minimum width reduced from 220 to 180 px, max width bounded by viewport, compact message/icon typography, and a 58 px toast height for wrapped messages. This prevents global notifications from being forced wider than small phone screens.
- Added viewport resize handling that disconnects and rebinds when `Workspace.CurrentCamera` changes, and reapplies constraints to already-visible notifications. Existing semantic variants (success/info/warning/error/reward), stacking, animation, and safe GUI inset are preserved.
- CI run `45147513350` was in progress when this note was written. No Studio/device visual test has been performed. Next verify long Russian messages, 320/360 px portrait, 4-toast overflow replacement, notifications during modal open, and camera replacement.
- Stage 1 remains open: standardize per-panel status/empty/loading presentation, finish icon coverage, and perform desktop/mobile Studio regression before moving to Stage 2.


## Stage 1 — Interface & usability: reusable empty states and non-duplicated errors (2026-11-23)

- Added `InterfaceComponents.StyleEmptyState(TextLabel, icon?)` to provide shared panel-soft background, rounded corners, subtle outline, centered wrapped text, and optional icon on its own line.
- Pet Collection now distinguishes a genuinely empty owned collection from empty favorites/team filters and an unmatched search. Each state has actionable Russian copy rather than the old generic `Ничего не найдено` message. Empty state uses the shared style.
- Quest Journal now shows a dedicated styled empty state when the server returns zero quests. It also detects a non-empty payload where every row fails validation and reports a recoverable data error instead of presenting a misleading blank list.
- Removed duplicate global toasts for Island Expansion request errors and Quest Journal timeout: the owning panel already displays the same failure and its recovery instruction. Global notifications remain for cross-screen events such as quest completion.
- CI: empty-state component and pet/quest empty states passed (`45149053072`, `45149098073`, `45149128790`, `45149161972`, `45149198176`, `45149213651`). Island Expansion duplicate-notification cleanup passed (`45149312696`). Quest Journal duplicate-timeout cleanup run `45149320803` was still running at the time of this entry. No Studio/device runtime verification has been performed.
- Next Stage 1 work: standardize loading/error/success state visuals in remaining panels, audit icon consistency and typography, then complete desktop and 320/360/390 px mobile regression in Roblox Studio. Stage 2 remains blocked until Stage 1 is signed off.


## Stage 1 — Interface & usability: action-button feedback (2026-11-23)

- Added reusable `InterfaceComponents.SetButtonFeedback(button, state, message?, duration?)` for short success/error/warning confirmation on the action that was just used. It captures/restores the original text, colors, Active/AutoButtonColor, and uses a generation token so an older delayed reset cannot overwrite a newer result. Supports success/error/warning theme colors and ignores destroyed buttons.
- Applied it to Quest Journal tracking: successful tracking briefly confirms `СЛЕЖУ`; failed tracking shows a clear `ПОВТОРИТЬ` state and then restores the normal label. Existing server state and sibling-button styling remain authoritative.
- Applied it to Island Expansion refresh: successful refresh confirms `ГОТОВО`, request/data errors show `ОШИБКА`, and the informational preview state uses neutral `ИНФО` rather than a misleading retry label. Loading still uses the shared `SetButtonLoading` helper and is always released after the request.
- CI passed for shared feedback helper (`45150058034`), Quest Journal integration (`45150090227`), and initial Island Expansion integration (`45150097015`). Latest informational-label adjustment `e70029a` CI `45150128088` was still running when this note was added. No Studio/device visual test has been performed.
- Building confirm/demolish already use loading locks, recovery flow, idempotent request IDs and global outcome notifications; those controls close/replace their panel after completion, so transient button feedback was not added where it would flash during teardown. Next: inspect other action surfaces for meaningful inline feedback, then finish icons/typography and Studio mobile regression. Stage 2 remains blocked.


## Stage 1 — Interface & usability: icon tokens and typography pass (2026-11-23)

- Added a frozen `InterfaceTheme.Icons` token map for common UI symbols (close/back/refresh, pet/quest/island/build, favorite, lock, move/rotate/demolish, confirm, search). Replaced repeated literals in Pet Collection, Quest Journal, Island Expansion, Building, and shared close-button styling so common actions are centrally defined.
- Improved compact readability: resource labels now use 9 px on regular screens and 8 px on very narrow screens (previously 7/6 px); quest tracking action is normalized to the shared action-button minimum 12 px; quest status captions are 10 px; pet list metadata is 10 px.
- Standardized the completed-quest checkmark through the shared icon token. Existing per-screen typography hierarchy and deliberate display sizes remain intact; no risky global font-size rewrite.
- CI passed for icon token definition and all five consumers (`45151844985`, `45151869370`, `45151877388`, `45151882211`, `45151891949`, `45151899598`). Typography checks `45151960757`, `45151969028`, and `45151976802` were running when recorded. No Roblox Studio/device visual verification has been done.
- Remaining Stage 1: audit residual ad-hoc symbols and screen-specific labels, finish shared status/loading icon coverage, final visual consistency, then desktop and 320/360/390 px mobile regression in Studio. Do not move to Stage 2 until the user tests the actual Roblox build and Stage 1 is signed off.


## Stage 1 — Interface & usability: final UI cleanup pass (2026-11-23)

- Removed redundant one-off `UICorner`/`UIStroke` creation immediately before `StyleFloatingButton` in Pet Collection, Quest Journal, and Island Expansion. Removed the same duplicate setup before the shared `StyleActionButton` on the Build launcher. The shared helpers already create/update those instances, so the duplicate setup had no visual effect and made styling harder to maintain.
- Finished migrating remaining repeated icon literals in Pet Collection (favorite filter/actions, lock state, bunny/pet list glyphs) and the Build rotate control to `InterfaceTheme.Icons`; added the missing `Bunny` token. Earlier cleanup CI passed for Pet Collection, Quest Journal, Expansion, and Build (`45152712568`, `45152719063`, `45152727753`, `45152749170`, `45152771679`). The latest icon migration is building in `45152892961` and has not yet completed at this note.
- Static audit of primary UI scripts found no `TextScaled=true`, no TODO/FIXME/HACK or old AI-attribution comments, and no remaining duplicate corner/stroke setup before floating-launcher style helpers. Remaining icon literals are deliberate domain-specific decoration (e.g. quest/star markers), not common action icons.
- Stage 1 is not signed off yet: resource HUD still has its own local color palette and should be aligned with the shared theme; full visual overflow/spacing audit and Roblox Studio desktop/mobile regression remain. Stage 2 remains blocked.


## Stage 1 — Interface & usability: Resource HUD theme alignment (2026-11-23)

- Migrated `IslandResourceHUD.client.lua` from a private panel/text/accent palette to `InterfaceTheme.Colors`; retained only resource-specific semantic tints for wood, stone, and crystals. The HUD now uses shared panel, soft-panel, cream, muted, gold, mint, and panel-light tokens.
- Replaced local font declarations and common text sizes with `InterfaceTheme.Typography` tokens for resource amounts, resource labels, gather toast, kingdom-bond status, and responsive resizing. Replaced local corner radii with `InterfaceTheme.Radii` and the kingdom-bond house glyph with `InterfaceTheme.Icons.Build`.
- Static audit confirms no remaining local duplicate base palette, no direct Gotham font declarations, and all color references resolve to defined shared theme tokens. Responsive 2×2 mobile / 4-column desktop layout and resource-specific accent colors remain unchanged.
- CI run `45153168859` for this HUD migration was in progress at documentation time. No Roblox Studio visual/device test has been performed. Next: run the final screen overflow/spacing audit and prepare a focused Studio checklist; Stage 1 remains open pending user-side runtime verification.

## Island persistence follow-up — 2026-11-24

- [x] Extended the gated DataStore round-trip fixture to cover all six current building catalogue entries, shifted grid coordinates after level-1 expansion, all four wallet balances, one resource cooldown, a durable building-operation receipt, and a level-2 Pet House upgrade.
- [x] Added validation for optional persisted building `upgradeLevel`: integer, at least 1, no higher than the catalogue maximum, and only allowed for upgradeable catalogue entries. Legacy records with no field remain valid and render as level 1.
- [x] Added data-contract tests for valid level 2, over-maximum level 4, and fractional level 1.5.
- [x] Fixed restored resource cooldown visuals so the gathering BillboardGui is disabled together with the model parts and ProximityPrompt.
- [x] Extended the island-world lifecycle test to assert cooldown marker visibility and to assert the level-2 Pet House upgrade attribute survives initial spawn and island refresh after expansion.
- [x] Added `docs/testing/ISLAND_PERSISTENCE_TESTING.md` and updated it with all six building types, upgrade persistence, cooldown marker visibility, and isolated DataStore test setup.
- [ ] Rojo build runs for commits `b314415`, `cb6a737`, `729e3ad`, `cff57f7`, `2e2ceb2`, `306227e`, `500565e`, `b0f2635`, `9a29c5f`, `2d772a5`, and `519a9be` are queued or in progress at the latest inspection. These runs only build the place file; they do not execute Studio tests. Do not mark any runtime test green from a successful build.
- [x] The earlier persistence contract commit `4f3cf84` has a successful Rojo build (run `45352472617`).
- [ ] Execute Studio-only `IslandDataTests.server.lua` and `IslandWorldServiceTests.server.lua`; a successful Rojo build does not execute these scripts.
- [ ] Run `IslandStoreTests.server.lua` only in a dedicated non-production test universe with `Workspace.RunIslandStoreIntegrationTests = true` and Studio API access enabled. Never point synthetic records at production DataStores.
- [ ] Perform the full player journey: gather, build all six types, upgrade Pet House, expand, leave/rejoin twice, and verify balances, positions, upgrade level, cooldown timestamps, and markers.
- [ ] Keep island persistence Stage 1 open until the Studio and manual checks above are recorded. No new expansion purchase economy should be invented before the economy balance sheet is approved.

## Quest persistence follow-up — 2026-11-24

- [x] Extended the isolated `IslandStoreTests.server.lua` fixture to model legacy schema-v1 profiles without `questProgress` or `trackedQuestId`; session claim must migrate both to safe defaults.
- [x] Added a non-default save/load case for both introductory quest counters (`gather_wood = 2`, `gather_stone = 1`) and selected tracked objective (`gather_stone`).
- [x] Assert the quest state survives DataStore reload and remains present in the next claimed session generation.
- [ ] CI validation for commit `2d772a5`; run remains pending until GitHub Actions reports a completed result.
- [ ] Execute the gated integration test only in a dedicated test universe, then verify the tracked quest and counters in a real leave/rejoin Studio journey.

## Persistence test hygiene — 2026-11-24

- [x] The gated `IslandStoreTests.server.lua` integration scenario now runs inside an `xpcall` and always attempts to remove its randomly generated synthetic `PetKingdoms_Islands_v1` profile after success or assertion failure.
- [x] The test fails explicitly if `RemoveAsync` cleanup cannot be confirmed, instead of silently accumulating synthetic records.
- [ ] CI validation for commit `519a9be`; Studio API execution remains pending in the dedicated test universe.

## Verification boundary reminder — 2026-11-24

- GitHub Actions workflow `.github/workflows/roblox-project-build.yml` runs only `rojo build` and uploads the Studio-ready place file.
- It does not launch Roblox Studio or execute `src/ServerScriptService/Tests` scripts.
- Therefore all queued/completed Actions runs are build checks only. Do not describe them as passing persistence, data, world, or gameplay tests.
- Studio-only tests and the manual leave/rejoin journey remain NOT DONE until their actual Studio Output and observed behavior are recorded.

## Pet collection persistence follow-up — 2026-11-24

- [x] Added `PetCollectionStoreTests.server.lua`, gated by Workspace attribute `RunPetCollectionStoreIntegrationTests`.
- [x] The integration fixture uses the production collection store name with a randomly generated synthetic key, verifies the key is empty before use, and removes the synthetic record after success or assertion failure.
- [x] Covered first session claim, reservation/grant, pet bond interaction, XP, favorite/lock flags, equipped order, durable acquisition receipt, DataStore reload, and stale-writer rejection after a newer generation claims the profile.
- [x] Added `docs/testing/PET_COLLECTION_TESTING.md` with safe Studio instructions and a manual leave/rejoin journey.
- [ ] CI/Rojo build validation for `fea5228` and follow-up assertion commit `a6f4651`; this workflow does not execute Studio tests.
- [ ] Run pure collection tests and the gated integration test in Roblox Studio; use a dedicated non-production test universe only.
- [ ] Verify real pet spawn and UI restoration after leave/rejoin.

## Companion spawn and character lifecycle — 2026-11-24

- [x] Added `PetCompanionSpawnService.lua` to isolate server-side formation creation and cleanup. It validates the collection, preserves equipped order, assigns PetId/OwnerUserId/FormationSlot, positions models relative to HumanoidRootPart, and clears previous models before rebuilding.
- [x] `PetCollectionService` now delegates formation creation to the spawn service while retaining `PetAssetLoader` as the only production asset factory.
- [x] Added `CharacterRemoving` cleanup and spawn-token invalidation. The handler checks the exact character instance so a delayed removal from an old character cannot clear a newer formation.
- [x] A cancelled model-factory attempt removes only models created by that attempt; it cannot wipe a newer spawn's folder after a yield.
- [x] Added `PetCompanionSpawnServiceTests.server.lua` for ordered two-pet spawn, position/attributes, duplicate prevention, invalid profile, cancellation, overlapping attempts, gated asset behavior, and cleanup of its temporary Workspace folder.
- [ ] Rojo build validation for commits `62a013e`, `f42d9a7`, `d9ff948`, `c7017a6`, `3388827`, `934ddca`, `fddd5d0`, and `2e00a15`.
- [ ] Run the new spawn-service test in Roblox Studio.
- [ ] Real model spawning/follow/respawn/rejoin remains blocked until the original project-owned Bunny mesh is imported and published from Studio. Do not restore the rejected third-party asset ID or silently use the procedural test prototype in production.

## Companion follow navigation — 2026-11-24

- [x] The existing client follow controller now uses a per-model `GroundOffset` attribute. The procedural Bunny sets a scale-aware value; published mesh assets derive a conservative offset from their bounding-box height.
- [x] Added short-lived, client-only obstacle detours. A raycast checks the direct segment from the companion to its formation/investigation target; when blocked, the controller tests lateral waypoints on both sides and selects the shortest route with both segments clear and a grounded waypoint; the lateral offset accounts for how the waypoint-to-target segment converges back toward the formation slot.
- [x] Detour width accounts for the obstacle's oriented BasePart bounds and the pet footprint, with a 14-stud maximum lateral offset to avoid sending companions excessively far from the owner. If both sides remain blocked, the controller does not keep steering into a corner; it retries on the next scan interval.
- [x] Added client Studio regression assertions for obstacle detection, lateral clearance, grounded waypoint height, and companion ground metadata at normal and scaled rig sizes.
- [ ] Rojo build validation for commits `cfc95c6`, `5cf865d`, `8d26140`, `5cd34b4`, `01768ec`, `a0ddbd2`, `a815332`, `801a993`, `f21a69e`, `b2a3d0e`, `5e341c8`, and `eaaf464`.
- [ ] Run `CompanionFollowControllerTests.client.lua` in Studio with Workspace attribute `RunPetKingdomsStudioTests = true`. This test is client-side and its PASS lines must be read from the client Output.
- [ ] Verify real island obstacles and mobile frame pacing with the published project Bunny mesh. Raycast detours are local steering, not full PathfindingService navigation; narrow mazes or fully enclosed obstacles still require real-world testing and may need a pathfinding stage.
- [ ] Keep the companion follow stage open until Studio and device checks are recorded.

## Companion jump response — 2026-11-24

- [x] `CompanionFollowController` observes the target character's Humanoid state. A Jumping transition starts one short hop if the companion is within 18 studs of its formation target; a descending Freefall does not start another hop; the client regression also covers a falling-only state after landing.
- [x] The hop uses a 0.68-second sine arc with 2.2-stud peak height, layered onto the existing ground-snapped follow target. The controller keeps normal horizontal steering and returns to the grounded slot after the arc.
- [x] Added `jump` to the procedural animation state machine. The airborne pose tucks the front paws, folds the hind legs, and adjusts the head/ears/tail.
- [x] Extended client follow tests for take-off, vertical lift, no retrigger during the same airborne interval, and hop completion; extended animation tests for jump state and limb transforms.
- [ ] Rojo build validation for commits `c5d9e0b`, `c819094`, `8220ab4`, `8ed3cb1`, `b7fa15b`, `f55a906`, and `860e3fa`.
- [ ] Run the server animation smoke test and client follow test in Studio. The client test requires Workspace attribute `RunPetKingdomsStudioTests = true`; inspect client Output for its PASS lines.
- [ ] Verify the actual published Bunny mesh, jump/landing alignment, and mobile frame pacing. Runtime acceptance is not complete from source changes or a Rojo build alone.

## Companion slope and ramp alignment — 2026-11-24

- [x] Added a separate ground-normal raycast helper. Each follow controller refreshes its surface normal every 0.15 seconds rather than adding a raycast to every RenderStepped update.
- [x] The companion target CFrame now uses the sampled surface normal as its up vector, while preserving the smoothed horizontal facing direction. This lets the model lean with bridges and ramps.
- [x] Surface normals steeper than 50 degrees fall back to world-up to avoid rotating the pet onto near-vertical walls.
- [x] Added a client Studio fixture with an 18-degree rotated ramp and checks for body alignment on an 18-degree ramp and upright fallback on a 65-degree surface.
- [ ] Rojo build validation for commits `eff6503`, `8b2c295`, and `5a98d33`.
- [ ] Run `CompanionFollowControllerTests.client.lua` in Studio with Workspace attribute `RunPetKingdomsStudioTests = true`; inspect client Output.
- [ ] Test real bridge/ramp transitions, ground contact and mobile frame pacing using the published Bunny mesh. The ramp fixture is not a substitute for an island playtest.

## Companion locomotion polish — 2026-11-24

- [x] Added `turnSmoothing` (default 9, bounded 4–18) and blend the desired horizontal facing direction before building the slope-aware target CFrame.
- [x] Fixed a double-interpolation issue in the follow tail: the controller now creates the target CFrame at the desired position and applies one positional/rotational interpolation. `movementSpeed` is measured from the resulting next CFrame's actual displacement divided by dt.
- [x] The final locomotion state is chosen from measured pet movement: idle below 0.35 studs/s, walk above that threshold, and run at 7.5 studs/s or during a sufficiently fast catch-up. Jump remains the highest-priority locomotion state.
- [x] Added `PetAnimationController:setMovementSpeed`; procedural walk/run leg cadence scales with actual speed and clamps input to 0–24 studs/s.
- [x] Client follow tests now cover smooth direction change, a pet walking toward formation while its owner is stationary, settling to idle, and remaining in place after stopping.
- [x] Server animation tests compare slow/fast gait poses and verify speed clamping.
- [ ] Rojo build validation for commits `f96b077`, `6064618`, `eddd03b`, `47e9d9f`, and `7e81a36`, plus turn-fixture correction `41bc463`.
- [ ] Run both companion Studio smoke tests and inspect the correct Server/client Output windows.
- [ ] Verify the same behavior with the published Bunny mesh and on mobile. Do not mark runtime acceptance from a green Rojo build alone.


## Latest UI lifecycle hardening — 2026-11-24

- [x] Updated `ModalManager.Register` to close and detach an existing controller before replacing its close callback; this prevents stale visible panels/input shades after LocalScript rebinding.
- [x] Updated `ModalManager.Unregister` to invoke cleanup even when focus bookkeeping is stale. The old callback is detached before invocation to avoid recursive unregister loops.
- [x] Preserved `ModalManager.ActiveChanged`; active focus loss is published when the focused controller is replaced or unregistered.
- [x] Expanded `src/StarterPlayer/StarterPlayerScripts/Tests/ModalManagerTests.client.lua` for visible and inactive unregister, re-registration, self-unregistering cleanup, focus state and event notifications.
- [ ] Validate implementation commit `3a284fd` and test commit `1048ec1` with the pinned Rojo GitHub Actions workflow.
- [ ] Run the ModalManager client smoke test in Roblox Studio with `Workspace.RunPetKingdomsStudioTests = true`; inspect client Output for PASS lines.
- [ ] Manually exercise rapid modal handoffs among Pet Collection, Quest Journal, Island Expansion and Build. Build success does not prove modal runtime behavior.
- Stage 1 remains open. Continue UI/responsive/construction acceptance only; do not advance to Stage 2 before Studio/device checks are recorded.


## Resource HUD icon token completion — 2026-11-24

- [x] Replaced the four duplicated resource glyph literals in `IslandResourceHUD.client.lua` with `InterfaceTheme.Icons.Wood`, `Stone`, `Gold`, and `Gems`.
- [x] Preserved each resource's semantic accent color and the existing responsive 2×2 compact / 1×4 wide layout.
- [x] Updated the Resource HUD shared-theme section in `docs/ROADMAP.md`.
- [ ] Run pinned Rojo build validation for commit `0647cc2`; no workflow run/status is currently associated with this commit.
- [ ] Verify all four symbols render on desktop, 320/360/390 px portrait and short landscape in Roblox Studio; check toast and HUD do not overlap the safe-area controls.
- Stage 1 remains open; do not sign off iconography until visual Studio/device verification is complete.


## Compact floating launcher collision fix — 2026-11-24

- [x] Moved the compact Pet Collection launcher from vertical center 0.46 to 0.34 while preserving its right-edge inset and 48×48 touch size. This separates it from Island Expansion at 0.72 on 180 px-high landscape viewports (68.4 px center spacing).
- [ ] Pinned Rojo build validation for `c9cabdd`.
- [ ] Studio visual/touch verification at 320×180, 360×180, 320×240, portrait phones, tablet and desktop; verify the topbar inset and no collision with other controls.
- Do not close Stage 1 until runtime/device checks are recorded.


## Ultra-short landscape modal reflow — 2026-11-24

- [x] Quest Journal now detects `ViewportSize.Y < 220`, sizes its panel to viewport height minus 20 px, compresses title/subtitle and controls, retains a scrollable quest list, and places status within the visible panel.
- [x] Island Expansion now detects the same ultra-short landscape threshold, fits its panel within viewport height minus 20 px, uses compact 34 px information cards, preserves a close control and refresh action, and hides nonessential subtitle/status copy in this mode.
- [ ] Validate Quest Journal commit `ffea06e` and Island Expansion commit `80fc57e` with pinned Rojo build.
- [ ] Roblox Studio runtime test at 320×180 and 360×180, then rotate back to portrait; verify no clipping, button overlap, or stale visibility state.
- Stage 1 remains open. Continue the safe-area audit with Pet Collection, building controls, Resource HUD, and notifications.

- [x] Follow-up fix `52dd49e`: explicitly restore Island Expansion's status label when resizing back from ultra-short landscape to portrait/desktop, avoiding stale hidden UI state.


## Pet Collection ultra-short landscape reflow — 2026-11-24

- [x] Added a dedicated `ViewportSize.Y < 220` layout; panel height is viewport height minus 20 px, removing the previous 280 px minimum that clipped 320×180 / 360×180 screens.
- [x] List view retains title/close, search, filters and a scrollable pet list.
- [x] Selected-pet view retains Back, favorite, lock, equip, set-main and delete controls; hides the 3D preview, description, bond and nonessential team/interaction rows at this extreme height.
- [x] Explicitly restores subtitle, status label, preview and standard controls when returning to taller/portrait viewports.
- [x] Commits: `ed55732` (initial reflow), `5bbf9fb` (viewport rotation restoration), `f517f67` (cleanup).
- [ ] Run pinned Rojo build validation for the three commits.
- [ ] Run Studio/device acceptance at 320×180 and 360×180, including list/search/filter, selection/back, favorite/lock/equip/main/delete, close/shade and orientation changes.
- Stage 1 remains open; source-level layout changes are not a substitute for Studio runtime/device verification.


## Construction panel short-screen reflow — 2026-11-24

- [x] Added `ViewportSize.Y < 220` layout to `resizeBuildingPanel`: panel is 160 px tall and UIScale remains 1, so action touch targets are not reduced below 44 px.
- [x] Reflowed status, catalog and action rows into the compact panel; catalog cards are 44 px tall, action row retains 44 px rotate/build/cancel controls.
- [x] Hide the Build launcher while placement is active or the full-width pending-operation recovery notice is visible, preventing overlap in the top safe area.
- [ ] Run pinned Rojo build validation for commit `5e524b7`.
- [ ] Studio/device acceptance at 320×180 and 360×180: panel clipping, catalog scroll, rotate/confirm/cancel/close, world touch placement, pending operation recovery and launcher restoration.
- [ ] Verify Move/Demolish controls, overview modal handoff, and return to portrait/desktop layout. Stage 1 remains open; no runtime acceptance implied.

- [x] Follow-up commit `4513354`: apply recovery-aware launcher visibility in placement failure/stop paths and ModalManager focus callbacks, preventing those callbacks from accidentally showing the launcher over an unresolved recovery notice.


## Construction preview safety — 2026-11-24

- [x] Commit `f9b38b4`: added `hideUnavailablePreview()` to clear stale footprint coordinates, validity and lock state, hide the footprint/ghost parts, and disable its Highlight when no valid free cell can be seeded or the island grid is unavailable.
- [ ] Studio QA: fill the island until each catalog item's footprint has no free cell; verify the ghost disappears and Confirm stays disabled.
- [ ] Switch from a valid catalog item to an item with no free cell, then back; verify no stale preview/coordinates and explicit tap/drag is still required.
- Source-level change only; no Roblox Studio runtime verification has been performed.


## Placement geometry regression coverage — 2026-11-24

- [x] Commit `6addbbf`: extend `PlacementValidatorTests.server.lua` with 270-degree rectangular footprint dimensions, exact-boundary fit, out-of-bounds rejection, overlap rejection against an already-rotated rectangle, and edge-adjacent acceptance.
- [ ] Run `PlacementValidatorTests.server.lua` in Roblox Studio and inspect client/server Output for every PASS.
- [ ] Rojo CI build validation for test commit `6addbbf`.
- These are committed test cases, not evidence that the validator has run in Studio.


## Shared placement geometry contract — 2026-11-24

- [x] Commits `e8a46d8` and `674e707`: client construction preview now imports the shared `ReplicatedStorage/Shared/Building/GridMath` module for rotated footprint dimensions, bounds checks, and overlap intersection; invalid rotation routes through preview invalidation.
- [x] Commit `1a69faf`: `IslandWorldService` publishes base `FootprintWidth` and `FootprintDepth` from the server-owned `BuildingCatalog` on both initial-spawned and transaction-synced building Models. The client uses those attributes for existing-building overlap checks rather than duplicating their catalog sizes.
- [x] Commit `61e009c`: when the island grid/surface becomes unavailable, preview coordinates, validity, lock state and ghost visuals are invalidated rather than leaving a stale cell.
- [ ] Studio: inspect footprint attributes for every catalog entry after initial spawn, move, upgrade, and island refresh; compare client preview with actual server Model pivot on rotated spawn points and after expansion.
- [ ] Rojo CI/build and Roblox Studio runtime/device verification remain pending; source-level checks are not runtime acceptance.

- [x] Commit `c898465`: extended `GridMathTests.server.lua` with 270-degree footprint dimension checks and rotated-rectangle overlap/edge-adjacency assertions. Studio execution remains pending.


## Canonical shared building footprints — 2026-11-24

- [x] Commit `423723d`: created `ReplicatedStorage/Shared/Building/BuildingFootprints.lua` with base dimensions for all six current buildable catalog IDs.
- [x] Commit `04cab44`: client preview imports this shared table instead of maintaining a duplicate `BUILDING_SIZES` table.
- [x] Commit `f52bead`: server-owned `BuildingCatalog` now derives `footprintWidth`/`footprintDepth` from the same shared table; server remains authoritative for IDs, unlocks, rotations, costs and transactions.
- [x] Commit `1fbfbb2`: GridMath Studio smoke test validates every shared footprint has positive integer dimensions.
- [ ] Studio run: confirm client preview and server validation agree for all six items at 0/90/180/270 degrees, including move and expanded island boundaries. CI/Studio runtime validation pending.


## Shared grid-to-world pivot conversion — 2026-11-24

- [x] Commit `bdcbe3d` / `81ee83a`: added `GridMath.getFootprintCenterOffset`, validating bounds and cell size before converting the occupied footprint rectangle into island-local center coordinates.
- [x] Commit `454e703`: server `IslandWorldService.gridToWorld` now uses the shared center conversion before applying the spawn CFrame and catalog rotation.
- [x] Commit `e53ad91`: client placement preview uses the same helper for both footprint and visual pivot, eliminating the duplicate center formula.
- [x] Commit `393ba60`: added Studio smoke tests for asymmetric 3×1 and even-sized footprints, out-of-bounds footprints, and invalid cell sizes.
- [x] Commit `5bcf9fb`: pointer-off-island and missing-surface branches now use the same preview invalidation helper, clearing stale cell/lock/ghost state.
- [ ] Studio: compare preview and spawned Model pivot positions/orientations on rotated spawn points, at all supported rotations, and after island expansion. Runtime acceptance pending.


## Imported building model pivot normalization — 2026-11-24

- [x] Commit `0864641`: added `BuildingModelPivot.normalizeToGroundCenter` to calculate visual bounds and normalize the model pivot to the ground-level center of the bounding box.
- [x] Commit `b07891b`: `IslandWorldService.getBuildingTemplate` now normalizes cloned ServerStorage templates before spawn/move placement, records `VisualBoundsWidth/Height/Depth`, and falls back to procedural geometry if bounds are invalid.
- [x] Commit `8eafa01`: removed the parent requirement so freshly cloned, unparented templates can be normalized before they enter Workspace.
- [x] Commits `203f5ba`, `d5fcfd6`, `fe9ec1a`: added Studio smoke tests for unparented and rotated fixtures, ground-center alignment, orientation preservation, bounds reporting, and idempotence.
- [ ] Run `BuildingModelPivotTests.server.lua` in Roblox Studio and inspect production templates against their grid footprints. No Studio runtime execution has been claimed.


## Visual model footprint diagnostics — 2026-11-24

- [x] Commit `b9046ba`: added `BuildingModelPivot.checkFootprintFit`, comparing measured visual bounds to catalog footprint dimensions in studs with a default 5% cell-size tolerance. Diagnostic only; no automatic asset scaling.
- [x] Commit `d18db3b`: template clones now expose `VisualFootprintFits`, `VisualOverhangX`, `VisualOverhangZ`, and measured visual bounds; oversized models produce a server warning.
- [x] Commit `d97e095`: added synthetic tests for in-footprint dimensions, tolerated small overhang, excess overhang reporting, and invalid cell size.
- [x] Commit `56dc287`: Studio test now audits actual `ServerStorage/BuildingModels` entries on clones, reporting measured bounds, footprint, overhang, and missing-template fallback status without mutating source assets.
- [ ] Run `BuildingModelPivotTests.server.lua` in Roblox Studio and review `[PetKingdoms Audit]` output; no actual Studio measurements are available yet.
