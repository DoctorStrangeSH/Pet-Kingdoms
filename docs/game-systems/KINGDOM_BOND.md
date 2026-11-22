# Kingdom Bond — MVP Foundation

> Status: first code milestone committed. The rules below are a provisional implementation, not final progression balance. Roblox Studio visual and multiplayer verification is still required.

## Product intent

The approved project specification says Kingdom Bond changes the personal island's visual appearance as the player's relationship/progression with the kingdom grows. Exact thresholds and visual stages were left open. This first pass keeps the progression understandable and directly tied to the saved island layout.

## Current MVP rule

- The Main House is the starting landmark and does not grant Bond.
- Every distinct non-Main-House building/decor type contributes 10 provisional Bond points once. Repeating the same type does not farm additional Bond.
- Points are derived from profile.buildings; they are not a second persisted currency and cannot be farmed by repeatedly placing/removing the same object.
- Removing a building reduces the derived score and can lower the visible stage. No demolition refund is granted by this system.
- Moves do not change the score because the building count does not change.

## Provisional stages

| Current improvements | Points | Stage |
|---:|---:|---|
| 0 | 0 | Тихий остров |
| 1–2 | 10–20 | Уютное королевство |
| 3–5 | 30–50 | Цветущее королевство |
| 5+ distinct types | 50+ | Процветающее королевство |

These thresholds are deliberately simple for the first playable loop. They must be playtested and balanced; do not treat them as approved economy values.

## World presentation

IslandWorldService derives the stage when the island spawns and whenever a building is synchronized or demolished. It:

- replicates Bond points, stage ID/name, current improvement count, and next threshold as island attributes;
- gently changes the grass tint by stage;
- creates a small set of stage decorations (flowers, a crystal accent, then a banner);
- rebuilds only its own KingdomBondDecor folder so repeated refreshes do not duplicate decorations.

Visual milestones are keyed to the calculated Bond stage, not raw building count. The first decorations are blockout geometry, not final production art. They must later be replaced by original assets that match docs/ART_BIBLE.md.

## UI

IslandResourceHUD.client.lua displays the current stage, points, and next milestone under the resource bar. The server-owned island attributes are the source of truth.

## Architecture

- Pure progression calculation: Services/KingdomBond.lua
- Server world presentation: Services/IslandWorldService.lua
- Player display: IslandResourceHUD.client.lua
- Contract tests: Tests/KingdomBondTests.server.lua

No client can submit Bond points or select a stage.

## Not implemented yet

- Pet companionship and pet interactions contributing to Bond.
- Quest/story milestones.
- Farming/production progression.
- Permanent historical Bond XP or one-time achievement journal.
- Final stage thresholds, rewards, unlocks, and production art.
- Studio validation of stage refresh on place/move/demolish/rejoin and multiplayer ownership.
