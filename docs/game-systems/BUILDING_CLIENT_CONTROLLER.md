# Client Island Building Controller

> Status: first client construction controller is committed. It provides a local grid preview and server-confirmed placement for `main_house` and `pet_house`. Studio input, camera, and visual verification remain pending.

## Player flow

1. The player opens the `СТРОИТЬ` button.
2. The construction panel opens in catalogue mode. The player chooses an item first; no preview or world placement begins yet.
3. Pressing ВЫБРАТЬ МЕСТО enters placement mode and creates a translucent local preview on the player's own grass surface.
4. The preview follows pointer/touch position. The final ПОДТВЕРДИТЬ action sends the currently displayed grid cell to the server.
5. The preview is green while its rotated footprint remains inside the configured island bounds and does not overlap another building; otherwise it is red.
6. Confirm invokes `ReplicatedStorage/Remotes/PlaceBuilding` with a fresh request ID and the integer grid cell.
7. The UI closes only after the server returns success. Server rejection is shown as a status message.

## Controls

- PC: mouse to aim, R to rotate, Escape to cancel, panel buttons to confirm/cancel.
- Touch: choose a catalogue card, tap ВЫБРАТЬ МЕСТО, drag/tap to aim, then use rotate/confirm/cancel controls. The panel is constrained to the viewport; real device testing remains required.
- The construction panel has a persistent close button and Escape cancellation.
- Construction and pet collection coordinate through the shared PlayerGui.PetKingdomsActiveModal attribute; opening one hides the other instead of stacking them.

## World contract

The server island Model exposes:
- `OwnerUserId`
- `GridWidth`
- `GridDepth`
- `GridCellSize`

The client raycasts only against `Island_GrassTop` belonging to the local player's island. The preview uses a client-only translucent blockout Part; it is never parented into the authoritative island model and is not saved. The server independently validates overlap, unlocks, bounds, rotation, and ownership.

## Current limitations

- `main_house` and `pet_house` are selectable; this is a minimal two-entry catalogue, not the final catalogue UI.
- Preview is a simple translucent footprint blockout, not the final original house mesh.
- The client shows bounds validity only; overlap feedback is supplied by the server response.
- Moving an existing building is supported by the server API but not exposed in this UI.
- Resource charging is not included because economy values are still open.
- Camera occlusion, mobile safe areas, gamepad, and actual device performance need Studio/device verification.

## Studio acceptance

- Confirm the LocalScript runs under StarterPlayerScripts.
- Configure a valid island with the grid attributes and spawn points.
- Confirm the build button appears after joining and the preview follows mouse/touch.
- Confirm 90-degree rotation updates the footprint and preview.
- Confirm cancel creates no server model and no profile record.
- Confirm valid placement creates exactly one server model and survives rejoin.
- Confirm out-of-bounds and overlapping requests are rejected by the server.
- Test at 375 px width and on a touch device.


## UX correction pass (2026-11-22)

- [x] Split catalogue selection and world placement into separate steps. Selecting a building no longer immediately starts or changes the preview position.
- [x] Label the two actions explicitly: ВЫБРАТЬ МЕСТО then ПОДТВЕРДИТЬ.
- [x] Add a visible close button to the construction panel and preserve Escape/cancel behavior.
- [x] Add responsive panel bounds and compact button sizing for narrow viewports.
- [x] Coordinate construction and pet collection modal ownership to prevent those two major windows from stacking.
- [ ] Verify exact placement, focus/input, overlap preview, and mobile safe-area behavior in Roblox Studio on desktop and touch devices.

## Shared modal ownership extension (2026-11-22)

The global `PlayerGui.PetKingdomsActiveModal` convention now includes `building`, `pets`, `quests`, `expansion`, and `kingdom`. Opening a major panel hides the previous one without stacking close-button hit targets. Quest, expansion, and kingdom overview respond to Escape; quest, expansion, and pet collection accept a backdrop click/tap outside their panel. Roblox Studio/mobile validation remains pending.

## Compact placement UI (2026-11-22)

The building catalogue is visible while choosing a building. Once the player enters placement preview, its large catalogue grid hides, and the bottom panel becomes a compact action bar (rotate, confirm, cancel, close), leaving more screen area available for positioning the preview. Ending the mode restores catalogue layout. Responsive sizing is retained on viewport changes; Studio mobile usability testing is pending.

## Placement confirmation fidelity (2026-11-22)

The client no longer repositions its preview when the pointer crosses its visible action bar, and an in-flight placement request freezes catalog ID, grid coordinates, rotation, and moving-instance ID. The idempotent request ID and server payload use the same snapshot. This protects the currently selected world cell from being shifted by mouse movement/touch over Confirm or by RenderStepped updates during the server call. Roblox Studio desktop/touch gameplay verification remains pending.

## In-flight modal switching (2026-11-22)

When a request is pending, switching to another major window defers construction cleanup until the remote returns. The response handler then closes the now-inactive build panel without clearing the new window's modal ownership. Tests and touch interaction verification in Roblox Studio remain pending.
