# Pet Kingdoms — Economy Baseline Audit

> Status: implementation facts and provisional earning-rate calculations only. This document does NOT approve final prices, progression pacing, or expansion costs.

## Scope

This audit records the current server-owned resource wallet, gathering-node definitions, and building catalog. Exact earning rates, shop prices, expansion costs/unlock conditions, and the final economy balance sheet remain open in `docs/PROJECT_SPEC.md`.

## Current wallet

Source: `IslandResources.lua`

| Resource | Starter balance |
|---|---:|
| Wood | 2 |
| Stone | 1 |
| Gold | 0 |
| Gems | 0 |

Allowed resource IDs are `wood`, `stone`, `gold`, and `gems`. Balances are non-negative integers capped at 2,000,000,000. The wallet is stored in the persistent island profile.

## Current gathering definitions

Source: `IslandResourceNodeCatalog.lua`

| Node | Resource | Reward | Respawn |
|---|---|---:|---:|
| WoodNode_A | Wood | 3 | 60 seconds |
| WoodNode_B | Wood | 3 | 60 seconds |
| StoneNode_A | Stone | 2 | 60 seconds |
| StoneNode_B | Stone | 2 | 60 seconds |

Assuming every node is available and gathered immediately when it respawns, the theoretical gross ceiling is:

- Wood: 2 nodes × 3 per 60 seconds = 6 per minute.
- Stone: 2 nodes × 2 per 60 seconds = 4 per minute.

These are mathematical upper bounds, not expected player income. They exclude travel time, interaction time, player inactivity, contention, and any future changes to node availability.

## Current construction catalog

Source: `BuildingCatalog.lua`

| Building | Wood | Stone | Notes |
|---|---:|---:|---|
| Main house | Free | Free | Default unlocked |
| Pet house | 5 | 2 | Default unlocked |
| Stone path | 1 | 1 | Default unlocked |
| Garden lantern | 2 | 1 | Default unlocked |
| Flower bed | 1 | — | Default unlocked |
| Wooden fence segment | 1 | — | Default unlocked |

The server catalog is authoritative. Prices are present in code but the project specification still describes the construction economy as provisional/open pending a complete balance sheet.

## Immediate starter observations

- Starter wallet is 2 Wood and 1 Stone.
- One successful wood-node gather raises Wood to 5.
- One successful stone-node gather raises Stone to 3.
- Therefore, after one gather of each resource, the current wallet can cover the coded Pet House cost of 5 Wood and 2 Stone, leaving 0 Wood and 1 Stone.
- A single gather is not necessarily instantaneous; the two resource node interactions and their availability are governed by the server's 60-second node cooldown.
- No gold or gem earning source is established by the current gathering catalog. The inspected server Services directory contains no quest, reward, or shop service; these are still roadmap items, not implemented earning sources.

## Expansion economy status

No expansion cost, unlock requirement, or time-to-unlock target is approved in the project specification. Do not add a guessed price or enable purchases until a complete economy decision is recorded.

The current expansion geometry is a two-step prototype: 24×24 → 32×32 → 40×40 cells. These dimensions do not imply prices.

## Decisions still required before enabling purchases

1. Intended active-play time to reach expansion level 1.
2. Intended active-play time to reach expansion level 2.
3. Whether expansion consumes only gathered materials or also Gold.
4. Whether quests and exploration contribute meaningful resource income.
5. Whether the resource-node count/reward/cooldown should remain as currently implemented.
6. How the economy should pace building purchases alongside expansion.
7. How the free progression path remains viable without monetization.

## Safety and implementation constraints

- Never accept a price or resource amount supplied by the client.
- Keep prices in server-owned definitions.
- Perform all resource checks and debits atomically under the profile mutation lock.
- Persist the debit and expansion level in the same durable profile revision.
- Use an idempotency receipt so retries cannot double-charge or double-expand.
- Do not acknowledge success until the relevant profile revision is durable.
- Roblox Studio/DataStore and real player pacing tests are required; code-level calculations do not establish the final balance.

## Sources inspected

- `docs/PROJECT_SPEC.md`
- `src/ServerScriptService/Services/IslandResources.lua`
- `src/ServerScriptService/Services/IslandResourceNodeCatalog.lua`
- `src/ServerScriptService/Services/IslandResourceNodeData.lua`
- `src/ServerScriptService/Services/BuildingCatalog.lua`
- `src/ServerScriptService/Services/IslandSessionService.lua`
- `src/ServerScriptService/Services/KingdomBond.lua`
