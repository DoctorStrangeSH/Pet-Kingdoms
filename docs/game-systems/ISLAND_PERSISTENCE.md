# Island Persistence — DataStore Adapter

> Status: server-side adapter implemented; live DataStore behavior has not been verified in Roblox Studio.

## Storage contract

- Store: `PetKingdoms_Islands_v1`
- Key: `player_<UserId>`
- Payload: compact versioned island profile from `IslandData.lua`
- No Roblox Instances, CFrames, client-supplied prices, or model contents are persisted.

## API

`IslandStore.load(userId)`
- Rejects invalid user IDs before touching DataStore.
- Retries transient GetAsync failures up to four attempts with bounded exponential backoff.
- Returns `true, nil, "NOT_FOUND"` for a new player.
- Validates loaded records against the current schema and server building catalog.
- Returns an explicit failure for malformed/unsupported saved profiles; it does not silently replace them with a blank island.

`IslandStore.save(profile)`
- Validates the complete profile before DataStore access.
- Uses UpdateAsync.
- Refuses to overwrite a stored profile whose revision is equal to or newer than the submitted snapshot.
- Important: the UpdateAsync transform returns the existing value when rejecting a write. Returning `nil` from an UpdateAsync transform cancels the write but the API still returns the current stored value; callers must not use a nil result as the rejection signal.
- Tracks whether the transform accepted the submitted snapshot and reports `SAVED` only when that write was accepted.
- Retries transient failures up to four attempts.
- Returns an explicit result code; callers must not report save success unless the result is successful.

## Important integration boundary

The adapter is connected to the server PlayerAdded/PlayerRemoving/autosave/BindToClose profile lifecycle through `IslandSessionService`, but the complete lifecycle has not been verified in Roblox Studio. Island spawning and a building transaction service are not implemented.

Before integration:
1. Define the authoritative island bounds and initial profile defaults from the approved world layout.
2. Add a cross-server session lease/single-writer lock so two server sessions cannot mutate one profile concurrently.
3. Increment revision on every successful state mutation.
4. Save on controlled checkpoints and PlayerRemoving; use BindToClose as a best-effort final flush.
5. Keep the player in a safe loading state if load fails; never create a blank profile over an unavailable/invalid save.
6. Test Studio API access, throttling, disconnects, shutdown, stale writes, and recovery using a dedicated test universe.

## Studio contract smoke test

`src/ServerScriptService/Tests/IslandStoreTests.server.lua` checks only that invalid inputs are rejected before any DataStore access. It does not validate live DataStore availability or persistence.


## Profile collection integrity

- The persisted `buildings` collection must be a contiguous 1-based array; sparse indexes and dictionary keys are rejected.
- A profile may contain at most 256 building records. This is a defensive validation ceiling for the MVP data contract, not a player-facing progression limit; revisit it only with an explicit performance and product decision.
- Unknown IDs in `unlockedBuildingIds` are rejected instead of silently accepted.
- Studio tests cover sparse/dictionary building collections and over-limit profiles. These tests are committed but not yet executed in Studio.
