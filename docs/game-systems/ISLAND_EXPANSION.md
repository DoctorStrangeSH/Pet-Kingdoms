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
- The helper is pure Luau and has no DataStore, Instance, RemoteEvent, wallet, or client dependencies. Studio contract tests now also cover two sequential profile transformations, cumulative coordinate shifts, source immutability, and max-level rejection; execution remains pending.

## Economy and progression deliberately deferred

The project specification leaves exact earning rates, prices, upgrade costs, and progression requirements open pending an approved balance sheet. This contract therefore does not invent expansion prices, charge resources, or grant unlocks. A later server-authoritative transaction must define and validate those rules before expansion becomes purchasable.

## Implementation

- Services/IslandExpansion.lua: validates levels, calculates effective grid dimensions, and returns a cloned next-level profile while preserving existing building world positions.
- IslandData validates the optional expansion level; IslandStore migrates legacy profiles to level 0 during load and atomic session claim.
- IslandData Studio tests cover profile validation, two expansion steps, maximum level, source immutability, and unchanged building world positions.
- Tests/IslandExpansionTests.server.lua: Studio-only contract coverage for current dimensions, each level, max level, invalid levels, and invalid base dimensions.

## Not implemented

- Server-authoritative purchase/unlock transaction, resource debit, durable idempotency receipt, and session mutation lock.
- Server-authoritative purchase/unlock transaction and idempotency receipt.
- Terrain/world regeneration and safe handling of occupied edge cells.
- Expansion preview, confirmation UI, costs, and progression requirements.
- Save/rejoin, multiplayer, and mobile Studio playtests.
