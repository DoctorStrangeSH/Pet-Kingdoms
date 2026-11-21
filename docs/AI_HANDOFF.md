# Pet Kingdoms — AI Handoff

> Last updated: 2026-11-21  
> Purpose: resume work in a fresh chat without relying on conversation memory.

## Repository

- GitHub: https://github.com/DoctorStrangeSH/Pet-Kingdoms
- Default branch: main
- Repository was initially empty when first inspected on 2026-11-21.
- The first documentation baseline has been committed directly to main.

## Source of truth

Read these files first:
1. README.md
2. docs/PROJECT_SPEC.md
3. docs/ROADMAP.md
4. docs/ART_BIBLE.md
5. docs/game-systems/BUILDING_SYSTEM.md
6. docs/game-systems/BUILDING_VALIDATION_TESTS.md
7. docs/game-systems/ISLAND_PERSISTENCE.md
8. docs/game-systems/ISLAND_SESSION_LIFECYCLE.md
9. docs/game-systems/ISLAND_SESSION_LEASE.md
9. docs/BUILD_AND_TEST.md
10. docs/ASSET_TRACKER.md

The repository is authoritative. If a chat message conflicts with these files, stop and reconcile the decision instead of silently changing scope.

## Current verified state

- [x] README and project overview committed.
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
- [x] Studio-only IslandData smoke-test script committed.
- [x] Revision-aware IslandStore DataStore adapter committed.
- [x] IslandStore input-contract smoke test committed.
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
- [x] MemoryStore cross-server island lease implementation committed and integrated (Studio/multi-server verification pending).
- [x] IslandLeaseService integration smoke test committed (exclusive acquire, owner renew/release, stale token rejection, release/reacquire).
- [ ] Save concurrency, UpdateAsync rejection, and MemoryStore lease behavior verified in Roblox Studio.
- [ ] End-to-end building placement, charging, and persistence implemented.
- [ ] Any production 3D assets, rigs, animations, or gameplay systems implemented.

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

The technical lead selected hybrid Rojo + VS Code + Roblox Studio as the recommended project workflow. Owner review is still pending. Next:
1. Run a Rojo build from the repository root and fix any mapping errors.
2. Open the generated place in Roblox Studio and verify the project tree.
3. Review the `UpdateAsync` transform behavior and run the stale/equal-revision integration test in a dedicated Studio test universe.
4. Run `PlacementValidatorTests.server.lua`, `GridMathTests.server.lua`, and `IslandDataTests.server.lua` in Studio; record the actual Output results.
5. Set Workspace attributes `IslandGridWidth` and `IslandGridDepth` from the approved island plot layout; do not guess dimensions.
6. Review `docs/game-systems/ISLAND_PERSISTENCE.md` and `docs/game-systems/ISLAND_SESSION_LIFECYCLE.md`; test the lifecycle in a dedicated Studio test universe with API access enabled.
7. Review `docs/game-systems/ISLAND_SESSION_LEASE.md`; run `IslandLeaseServiceTests.server.lua` in a dedicated test universe with MemoryStore API access; then test expiry takeover, throttling/outage, and shutdown across two Studio servers.
8. Add a server transaction layer for resource charging and placement mutation only after economy prices are approved.
9. Add remotes with server-side rate limiting and idempotency; never expose client-trusted prices or footprints.
10. Add save/load recovery tests after persistence behavior is implemented.
11. Update ROADMAP and this handoff after each verified milestone.

## Working rules

- Make real repository changes; never present design concepts as implemented features.
- Update ROADMAP with DONE / NOT DONE and verification notes.
- Prefer small, testable, modular changes.
- Do not store live Roblox Instances in DataStores; persist validated compact data.
- Server validates economy, ownership, placement, rewards, and progression.
- Keep PC and mobile in scope from the start.
