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
