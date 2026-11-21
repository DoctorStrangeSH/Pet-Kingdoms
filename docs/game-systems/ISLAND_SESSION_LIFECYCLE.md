# Island Session Lifecycle

> Status: server profile lifecycle code is committed. It has not been run in Roblox Studio and is not a full island-world spawn system.

## Startup requirements

The server reads two Workspace attributes:
- `IslandGridWidth`
- `IslandGridDepth`

These values must be set by the approved world/plot layout before players join. They are intentionally not hard-coded in source. If either value is missing or invalid, a first-time player is not given a guessed-size island; the join is failed safely.

## Lifecycle behavior

- `PlayerAdded`: load and validate the player's profile.
- New profile: create from configured grid bounds and persist it before making the session available.
- Load error or invalid profile: fail closed; do not silently create a replacement profile.
- `PlayerRemoving`: stop further mutations, wait for any in-flight save, save a dirty profile, then release the in-memory session only after success.
- Save calls for the same player are serialized; autosave, leave, and shutdown cannot write concurrently.
- Save snapshots clone the buildings array, each building record, and unlock map before yielding to DataStore.
- If final save fails, retain the in-memory session for a best-effort shutdown retry rather than immediately discarding it.
- Autosave: every 60 seconds, save dirty sessions only.
- `BindToClose`: best-effort flush of dirty profiles, bounded to 25 seconds.
- `getProfile(userId)`: server-only access to the in-memory profile.
- `markDirty(userId)`: increments the profile revision and marks it for saving.

## Important limitations

- No island model is spawned into Workspace yet.
- No client remotes or building mutations call this service yet.
- No cross-server session lease is implemented. Revision checks prevent an older/equal revision from overwriting a newer stored snapshot, but simultaneous sessions can still race and one may receive a stale-save failure.
- PlayerRemoving and shutdown persistence are best-effort; live DataStore behavior must be tested in a dedicated test universe.
- A retained session after a failed PlayerRemoving save is only held in memory; it cannot guarantee recovery if the server crashes before another successful save.
- The Studio contract test checks unknown-session behavior only; it does not prove the DataStore or full lifecycle works.

Before public playtesting, implement a cross-server session lease or another explicit single-writer policy, then test reconnects, server shutdown, throttling, and concurrent sessions.
