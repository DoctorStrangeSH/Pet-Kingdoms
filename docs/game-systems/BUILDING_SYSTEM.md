# Island Building System — MVP Design

 > Status: server-authoritative placement/move/demolition code exists. New placement charging is implemented with provisional prices; Studio integration and persistence tests remain pending.

## 1. Player experience

Players personalize a persistent home island by placing, moving, rotating, upgrading, and removing approved buildings and decorations. The system must be understandable on PC and mobile.

## 2. Placement model

- Use a logical grid for building footprints.
- Every catalog item defines a stable item ID, footprint width/depth, rotation steps, unlock state, and optional server-owned resource cost.
- Current provisional prices (not final economy approval): Main House free; Pet House 5 Wood + 2 Stone; Stone Path 1 Wood + 1 Stone; Garden Lantern 2 Wood + 1 Stone; Flower Bed 1 Wood; Wooden Fence 1 Wood.
- The visual preview follows the pointer/touch ray and snaps to the logical grid.
- Preview states: valid, invalid, blocked, and unavailable.
- Rotation is in 90-degree increments unless an asset explicitly requires a different rule.
- Placement must reject overlap, out-of-bounds positions, blocked terrain, invalid height/slope, and unauthorized plot locations.
- Decorative objects may use a separate smaller placement grid if needed, but do not introduce this until core building placement is stable.

## 3. Controls

### Desktop
- Select item: click catalog item.
- Move preview: mouse/touch ray.
- Rotate: R or rotate button.
- Confirm: click/Enter.
- Cancel: Esc or cancel button.
- Move existing building: select it, then reposition preview.
- Remove: explicit action with confirmation where resources are refunded.

### Mobile
- Large touch-friendly catalog and action buttons.
- Drag to position.
- Dedicated rotate, confirm, and cancel controls.
- Never rely on keyboard shortcuts.

## 4. Server authority

The client may render a preview, but the server owns the decision.

For every place/move/remove/upgrade request, the server must:
1. Validate player identity and island ownership.
2. Resolve item ID and price from server-side catalog data.
3. Validate unlocks and available plot bounds.
4. Validate footprint, collision/overlap, and allowed surface.
5. Resolve the cost from `BuildingCatalog`; never accept client-supplied prices.
6. For new placements, validate and charge the resource wallet before creating the building record. Moves do not charge again.
7. If world sync or the profile write gate fails, restore the building/world state and atomically refund the charged resource bundle.
8. Persist the new island layout through the existing profile save lifecycle.
9. Return a result; the client must not claim success before confirmation.

Never trust client-supplied costs, dimensions, ownership, refund values, or final placement validity.

## 5. Data model

Persist compact data, not live Instances:
- schemaVersion
- islandLevel
- unlockedPlots
- buildings[]: instanceId, catalogId, integer grid coordinates, rotation, upgrade level
- decorations[]: same shape with decoration catalog IDs
- updatedAt or revision metadata as appropriate

Do not persist arbitrary client-provided CFrames or model contents. Derive world transforms from validated grid coordinates and catalog metadata.

## 6. Persistence and recovery

- Version the saved schema.
- Validate loaded records before spawning Instances.
- Ignore or quarantine malformed records rather than crashing the entire island load.
- Prevent duplicate charges and duplicate building creation on retries; use request IDs or idempotent operation handling.
- Current limitation: a process crash between charging and placement rollback is not yet protected by a durable transaction journal. Demolition refunds are intentionally not enabled.
- Handle DataStore failures without falsely acknowledging a save.
- Consider a bounded operation journal or revision number for recovery.
- Test rejoin, server shutdown, throttling, and partial failure in Roblox Studio.

## 7. MVP boundaries

In scope:
- A small curated building catalog.
- Grid snapping.
- Rotation.
- Move and remove.
- Server-side placement validation and resource charging.
- Island layout save/load.
- PC and mobile controls.

Not in scope before MVP unless the original source specification requires them:
- Freeform terrain sculpting.
- Complex multi-floor construction.
- Shared collaborative building.
- Player-to-player trading of buildings.
- User-generated building templates.

## 8. Current construction costs (provisional)

| Building | Cost |
|---|---|
| Main House | Free |
| Pet House | 5 Wood + 2 Stone |
| Stone Path | 1 Wood + 1 Stone |
| Garden Lantern | 2 Wood + 1 Stone |
| Flower Bed | 1 Wood |
| Wooden Fence | 1 Wood |

The client shows these as hints only. `IslandBuildingService` charges the server catalog values. The values need playtesting and a full economy balance pass. Failed placement sync/write-gate attempts use an atomic multi-resource refund. Demolition currently gives no refund.

## 9. Implementation sequence

1. Confirm toolchain and island coordinate model.
2. Define catalog schema and a small test catalog.
3. Implement pure grid/footprint validation functions.
4. Add server-authoritative placement requests.
5. Add client preview and PC controls.
6. Add mobile controls.
7. Add save/load with schema versioning and idempotency.
8. Verify in Studio with overlap, boundary, exploit, and persistence tests.
