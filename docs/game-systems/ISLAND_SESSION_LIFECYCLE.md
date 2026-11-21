# Island Session Lifecycle

> Status: server profile lifecycle, island spawning, MemoryStore lease renewal, DataStore generation fencing, serialized autosaves, and retryable leave cleanup are implemented. Roblox Studio/live DataStore verification is still pending.

## Startup requirements

The server reads two Workspace attributes:
- `IslandGridWidth`
- `IslandGridDepth`

These values must be set by the approved world/plot layout before players join. They are intentionally not hard-coded in source. If either value is missing or invalid, a first-time player is not given a guessed-size island; the join is failed safely.

## Lifecycle behavior

- `PlayerAdded`: load and validate the player's profile.
- New profile: create from configured grid bounds and persist it before making the session available.
- Load error or invalid profile: fail closed; do not silently create a replacement profile.
- `PlayerRemoving`: stop further mutations, mark the session as leaving, wait for any in-flight save, save a dirty profile, then release the lease and world/session resources only after success.
- If the final save fails, retain the profile, world, and lease; the autosave loop retries the final save every 60 seconds. After a successful retry, it releases the lease and destroys the world/session resources.
- If lease release fails after a successful save, retain the leaving session and retry release on the next autosave cycle; do not destroy the world or forget the lease token before release succeeds.
- Save calls for the same player are serialized; autosave, leave, and shutdown cannot write concurrently.
- Save snapshots clone the buildings array, each building record, and unlock map before yielding to DataStore.
- If final save fails, retain the in-memory session for a best-effort shutdown retry rather than immediately discarding it.
- Autosave: every 60 seconds, save dirty sessions and retry sessions marked as leaving (including lease-release retries after a successful final save).
- `BindToClose`: best-effort flush of dirty profiles and release of session leases, bounded to 25 seconds.
- `getProfile(userId)`: server-only access to the in-memory profile.
- `markDirty(userId)`: increments the profile revision and marks it for saving.

## Important limitations

- Lifecycle, MemoryStore lease, DataStore generation fencing, and island-world rendering are implemented but have not been verified together in Roblox Studio with live API access.
- The final-save retry path is code-reviewed but still needs a forced-failure integration test: make the first PlayerRemoving save fail, allow the next autosave to succeed, and verify that the session, world model, spawn reservation, and MemoryStore lease are all released exactly once.
- If the server crashes before a retry succeeds, unsaved in-memory changes can still be lost. Autosave reduces this window but cannot guarantee persistence during a prolonged DataStore outage.
- The shutdown flush is best-effort and bounded; test throttling/outage and concurrent server shutdown in a dedicated test universe.

## Required Studio integration checks

- [ ] Normal leave: dirty profile saves, MemoryStore lease releases, island world is destroyed, and spawn slot becomes available.
- [ ] Failed final save: session/world/lease are retained; a later autosave retries.
- [ ] Successful retry after failed final save: profile is saved, lease is released, world and spawn reservation are removed, and no orphan session remains.
- [ ] Lease release failure after successful save: cleanup is retried without duplicating or destroying another player's world.
- [ ] Reconnect after successful leave: profile and all building records load at the same grid coordinates and rotations.
- [ ] Two players in one server receive distinct spawn points; one player leaving frees only their own slot.
- [ ] Two servers cannot both mutate the same profile; stale generation writes are rejected.
- [ ] Server shutdown flushes sessions within the configured deadline and logs any profiles that could not be saved.
