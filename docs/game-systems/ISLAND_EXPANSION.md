# Island Expansion — Geometry Contract

> Status: geometry and backward-compatible profile persistence foundation implemented. Server-authoritative purchase, costs, UI, and Studio gameplay verification are NOT implemented yet.

## Goal

The home island must grow without moving the island, relocating existing buildings, or invalidating saved grid coordinates. Expansion extends the buildable grid symmetrically around its existing center.

## Geometry contract

- Current starter plot remains 24×24 cells at the current default world configuration.
- Expansion level 0 preserves the current dimensions.
- Each expansion level adds 8 cells to width and depth.
- The first two levels therefore resolve to 32×32 and 40×40 cells when the base plot is 24×24.
- Maximum prototype expansion level: 2.
- The profile stores `expansionLevel`; legacy schema-v1 records without it are normalized to level 0 during load/session claim.
- Each expansion adds 8 cells per axis and shifts saved grid coordinates by 4 cells per axis. Because world rendering centers the grid, existing buildings retain their exact world-space positions.
- Existing grid coordinates are not translated by this geometry helper; world rendering must continue to center the grid using the profile's effective bounds.
- The helper is pure Luau and has no DataStore, Instance, RemoteEvent, wallet, or client dependencies. Studio contract tests now also cover two sequential profile transformations, cumulative coordinate shifts, source immutability, and max-level rejection; execution remains pending. Additional cases reject fractional, negative, NaN, and infinite saved building coordinates.

## Economy and progression deliberately deferred

The project specification leaves exact earning rates, prices, upgrade costs, and progression requirements open pending an approved balance sheet. This contract therefore does not invent expansion prices, charge resources, or grant unlocks. A later server-authoritative transaction must define and validate those rules before expansion becomes purchasable.

## Implementation

- Services/IslandExpansion.lua: validates levels and non-negative integer building coordinates, calculates effective grid dimensions, and returns a cloned next-level profile while preserving existing building world positions.
- IslandData validates the optional expansion level; IslandStore migrates legacy profiles to level 0 during load and atomic session claim.
- IslandData Studio tests cover profile validation, two expansion steps, maximum level, source immutability, and unchanged building world positions.
- Tests/IslandExpansionTests.server.lua: Studio-only contract coverage for current dimensions, each level, max level, invalid levels, and invalid base dimensions.

## Not implemented

- Server-authoritative purchase/unlock transaction, resource debit, durable idempotency receipt, and session mutation lock.
- Terrain/world regeneration and safe handling of occupied edge cells.
- Expansion preview, confirmation UI, costs, and progression requirements.
- Save/rejoin, multiplayer, and mobile Studio playtests.


## Renderer integration test

The IslandWorldService integration test now includes a level-1 expanded profile (32x32 grid), verifies the rendered terrain dimensions and world attributes, and compares the main-house pivot before/after the +4-cell coordinate shift. This is a Studio test only; it does not mean purchase or live resize is implemented.


The renderer integration test now covers both expansion levels: 32x32 / 256x256 studs and 40x40 / 320x320 studs. At each level it asserts that the main-house world pivot remains unchanged after the corresponding saved-grid offset. Test execution is pending in Roblox Studio.


## Persisted bounds validation

Before rendering, IslandWorldService checks the profile's saved bounds against the configured starter dimensions and its persisted expansion level through IslandExpansion.matchesProfileBounds. A legacy profile without an expansionLevel is interpreted as level 0. Inconsistent dimensions are rejected before a spawn slot is allocated, preventing a corrupted or unsupported profile from creating oversized or mismatched terrain.


## Canonical transition preparation

`IslandExpansion.prepareNextProfile(profile, baseWidth, baseDepth)` is the pure preparation boundary for the future server transaction. It validates the current saved bounds against the configured base and level, derives exactly one next level using the existing immutable profile transformation, then validates the resulting bounds again. It returns `PREPARED` only for a canonical transition. It intentionally does not charge, persist, or mutate the active world.


Preparation contract tests additionally verify rejection at maximum level, invalid building records, and incorrect configured base dimensions.


## Server-session commit foundation

`IslandSessionService.commitIslandExpansion(userId, player, expectedLevel)` applies one canonical level transition under the existing shared profile mutation lock. It verifies the exact active Player and writable island lease, validates the expected level and configured base bounds, prepares a cloned next profile, advances its revision, and waits for that revision to persist. Repeating the same expected-level request after the transition returns `ALREADY_APPLIED` after confirming durability rather than applying a second level. This is not yet a purchase endpoint: there is no resource debit, request receipt ledger, client remote, or live world respawn.
