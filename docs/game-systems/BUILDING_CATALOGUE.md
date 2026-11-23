# Client Building Catalogue

> Status: six starter entries are present in the construction panel. The server owns prices, footprints, unlock validation and placement. Procedural blockout previews are functional in source; Studio/device input and visual verification remain pending.

## Available entries

| Entry | Display name | Footprint | Current placement cost |
|---|---|---:|---:|
| `main_house` | Главный дом | 3 × 3 | Free |
| `pet_house` | Домик питомцев | 3 × 3 | 5 Wood, 2 Stone |
| `stone_path` | Каменная дорожка | 1 × 1 | 1 Wood, 1 Stone |
| `garden_lantern` | Садовый фонарь | 1 × 1 | 2 Wood, 1 Stone |
| `flower_bed` | Цветочная клумба | 1 × 1 | 1 Wood |
| `wooden_fence` | Забор (секция) | 1 × 1 | 1 Wood |

All six entries are currently marked unlocked in the server catalog. The client mirrors footprint dimensions only for its local preview; server validation and charging remain authoritative.

## Player flow

1. Open `СТРОИТЬ` from the top-right launcher.
2. Select one of the six catalogue entries. The selected card is highlighted.
3. PC: move the pointer over free island grass. Touch: tap the desired free grass cell.
4. A green preview indicates a valid location; red indicates an invalid/out-of-bounds/occupied location.
5. Rotate with the rotate button (or `R` on PC).
6. Press `ПОСТРОИТЬ` to submit the placement. The server validates and charges the catalog cost atomically.
7. Use `ОТМЕНА`, the panel close control, or `Escape` to leave placement mode.

## Other construction actions

- Select an existing building on the island to reveal Move and Demolish actions.
- Move uses the same grid preview and does not charge a second placement cost.
- Demolish requires a second confirmation and protects the main house.
- Server operations use request IDs and a recovery panel to avoid duplicate transactions after timeouts.

## Current limitations

- The client catalogue uses text and compact symbols, not approved illustrated building cards.
- The visible building preview and fallback buildings are procedural blockouts, not final production art.
- Catalogue search, categories, rarity, unlock progression and upgrade controls are not yet exposed in the client UI.
- Move/demolish, touch targeting, safe areas and all six placements still require Studio/device regression.

## Acceptance

- All six entries select and show the matching preview.
- Preview tracks mouse/touch, rotates correctly, and indicates invalid bounds/overlap.
- Costs match the server catalog and are charged only after successful server validation.
- Move, demolish, cancellation, recovery and rejoin persistence work without duplicate operations.
- Test desktop and 320/360/390 px portrait plus short landscape in Roblox Studio.
