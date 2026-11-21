# Client Building Catalogue

> Status: first two starter entries are selectable in the client construction panel. This is a minimal functional catalogue, not the final card art or full building inventory. Studio/device verification is pending.

## Available entries

| Stable ID | Display name | Footprint | Unlock |
|---|---|---:|---|
| `main_house` | Главный дом | 3 × 3 | Default unlocked |
| `pet_house` | Домик питомцев | 3 × 3 | Default unlocked |
| `stone_path` | Каменная дорожка | 1 × 1 | Default unlocked |
| `garden_lantern` | Садовый фонарь | 1 × 1 | Default unlocked |

The server's `BuildingCatalog.lua` remains the authority for footprints, unlocks, and allowed rotations. The client currently mirrors the starter footprint dimensions solely to size its cosmetic preview; server validation is always authoritative.

## Player flow

1. Open `СТРОИТЬ`.
2. Select Главный дом or Домик питомцев.
3. The selected card receives a highlighted state.
4. The preview footprint follows the pointer/touch and rotates with the existing 90-degree control.
5. Confirm sends the selected stable catalog ID to `PlaceBuilding`.
6. The server creates the corresponding production template or temporary fallback blockout.

## Current limitations

- The four entries use text/emoji buttons; production illustrations, rarity/category filters, search, prices, and unlock messaging are not implemented.
- The two houses use 3 × 3 footprints; path and lantern use 1 × 1 footprints.
- Resource costs are intentionally absent until economy values are approved.
- Selection and placement have not yet been verified in Roblox Studio or on a touch device.
- Move and demolish UX are not part of this milestone.

## Acceptance

- Both cards can be selected and selection highlight updates.
- Selected ID is the one sent to the server.
- Preview size and rotation remain correct after switching entries.
- Server rejects unknown or locked IDs regardless of client UI.
- Both starter buildings create the correct model/blockout and persist after rejoin.
- Test at 375 px and on a touch device.
