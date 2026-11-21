# Building Move Mode

> Status: client move mode is connected to the existing server-authoritative place/move transaction. Studio/device verification is pending.

## Model metadata

Every spawned or synchronized building Model exposes server-authored attributes:
- `BuildingInstanceId`
- `BuildingCatalogId`
- `GridX`
- `GridZ`
- `GridRotation`

These attributes are presentation metadata for selection and editing. The server still reads the actual profile record and validates the requested move; it does not trust client-provided previous coordinates.

## Player flow

1. Click/tap a building on the player's own island.
2. The client shows `ПЕРЕНЕСТИ`; non-main-house buildings also show `ДЕМОНТИРОВАТЬ`.
3. Press `ПЕРЕНЕСТИ`.
4. The client reads the stable building ID/catalog ID and saved rotation from replicated attributes.
5. A translucent footprint preview appears and follows the pointer/touch over the island grid.
6. Rotate with the existing rotate control or R key.
7. Confirm with `СОХРАНИТЬ`, or cancel to leave the original building untouched.
9. The client sends the existing `movingInstanceId` field to `PlaceBuilding`.
10. The server finds the existing profile record, validates bounds/overlap/unlock/rotation, synchronizes the replacement model, and marks the profile dirty.
11. The existing instance ID is preserved; a second building record is not created.

## Safety

- Selection is restricted to Models descended from the caller's own island.
- The server validates that the moving instance exists in the caller's profile and that its catalog ID matches the requested building.
- PlacementValidator excludes only the building being moved from overlap checks.
- Invalid target positions are rejected; the saved position remains unchanged.
- The main house can be moved but cannot be demolished.
- Cancel sends no request and changes no server state.

## Current limitations

- Preview is still a translucent footprint blockout, not a cloned production mesh.
- Client preview checks bounds and known building footprints for immediate feedback; server validation remains authoritative.
- There is no drag-to-move while in selection mode; the player enters an explicit move mode.
- Touch input and camera behavior need device testing.
- Studio transaction/persistence checks remain pending.

## Acceptance

- Selection reads correct server-authored building attributes.
- Overlapping a different building is shown as invalid in the client preview.
- Moving a building keeps the same instance ID and does not duplicate its profile record or world Model.
- Move to overlapping/out-of-bounds positions is rejected and old position remains.
- Cancel leaves original building and profile unchanged.
- Rejoin restores the building at its new accepted location.
- Main house can be moved but cannot be demolished.
- Touch and 375 px layout are usable.
