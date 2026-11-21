# Building Demolition

> Status: server-authoritative demolition and a first client click-to-select flow are committed. Studio verification is pending.

## Player flow

1. While not in placement mode, click/tap a building on the local player's island.
2. The client resolves the model's `BuildingInstanceId` and displays the demolition control.
3. First press arms a confirmation state; the button changes to `ТОЧНО УДАЛИТЬ?`.
4. Second press invokes `PlaceBuilding` with `action = "demolish"`, a fresh request ID, and the selected instance ID.
5. The server resolves the instance only in the invoking player's active profile.
6. The server refuses to demolish `main_house`.
7. For other buildings, the server removes the profile record and world model, then marks the profile dirty.
8. If the session cannot be marked writable, the record and model are restored.

## Security and persistence

- User identity comes from the RemoteFunction's Player argument.
- Client-supplied catalog ID, owner ID, coordinates, and price are ignored for demolition.
- A building ID not present in the caller's profile returns `BUILDING_NOT_FOUND`.
- The main house is protected server-side even if a client bypasses the UI.
- Recent request IDs are deduplicated through the existing per-player bounded result cache.
- Demolition does not refund resources because no building costs have been approved or charged yet.

## Current limitations

- Mouse and touch selection events are wired; real-device touch behavior still needs a device pass.
- There is no selection outline or confirmation modal yet; confirmation is a deliberate second button press.
- Demolition returns no materials or currency.
- There is no client move mode yet; the server place/move transaction remains available.
- Studio persistence and failure rollback tests are pending.

## Acceptance

- Selecting a building on the local island reveals the demolition control.
- Clicking another player's island never selects their buildings.
- First demolition press arms confirmation without changing the world.
- Second press removes the selected non-main-house model and saved record.
- Main house demolition is rejected by the server.
- Unknown/foreign IDs are rejected.
- Failed dirty marking restores both the saved record and visible model.
- Repeated request IDs do not remove additional records.
- Rejoin confirms demolished buildings do not respawn.
