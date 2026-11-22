# Island Expansion — Geometry Contract

> Status: geometry foundation implemented. Player-facing purchases, unlock conditions, persistence mutations, UI, and Studio gameplay verification are NOT implemented yet.

## Goal

The home island must grow without moving the island, relocating existing buildings, or invalidating saved grid coordinates. Expansion extends the buildable grid symmetrically around its existing center.

## Geometry contract

- Current starter plot remains 24×24 cells at the current default world configuration.
- Expansion level 0 preserves the current dimensions.
- Each expansion level adds 8 cells to width and depth.
- The first two levels therefore resolve to 32×32 and 40×40 cells when the base plot is 24×24.
- Maximum prototype expansion level: 2.
- Existing grid coordinates are not translated by this geometry helper; world rendering must continue to center the grid using the profile's effective bounds.
- The helper is pure Luau and has no DataStore, Instance, RemoteEvent, wallet, or client dependencies.

## Economy and progression deliberately deferred

The project specification leaves exact earning rates, prices, upgrade costs, and progression requirements open pending an approved balance sheet. This contract therefore does not invent expansion prices, charge resources, or grant unlocks. A later server-authoritative transaction must define and validate those rules before expansion becomes purchasable.

## Implementation

- Services/IslandExpansion.lua: validates levels and calculates effective grid dimensions.
- Tests/IslandExpansionTests.server.lua: Studio-only contract coverage for current dimensions, each level, max level, invalid levels, and invalid base dimensions.

## Not implemented

- Persisting expansion level in the island profile and migrating legacy profiles.
- Server-authoritative purchase/unlock transaction and idempotency receipt.
- Terrain/world regeneration and safe handling of occupied edge cells.
- Expansion preview, confirmation UI, costs, and progression requirements.
- Save/rejoin, multiplayer, and mobile Studio playtests.
