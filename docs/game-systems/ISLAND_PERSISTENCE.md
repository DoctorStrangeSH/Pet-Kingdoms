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
- Retries transient failures up to four attempts.
- Returns an explicit result code; callers must not report save success unless the result is successful.

## Important integration boundary

This adapter is not yet connected to PlayerAdded/PlayerRemoving, BindToClose, island spawning, or a building transaction service. Do not call it as if a full save lifecycle exists.

Before integration:
1. Define the authoritative island bounds and initial profile defaults from the approved world layout.
2. Add a per-player in-memory session owner/lock so two server sessions cannot mutate one profile concurrently.
3. Increment revision on every successful state mutation.
4. Save on controlled checkpoints and PlayerRemoving; use BindToClose as a best-effort final flush.
5. Keep the player in a safe loading state if load fails; never create a blank profile over an unavailable/invalid save.
6. Test Studio API access, throttling, disconnects, shutdown, stale writes, and recovery using a dedicated test universe.

## Studio contract smoke test

`src/ServerScriptService/Tests/IslandStoreTests.server.lua` checks only that invalid inputs are rejected before any DataStore access. It does not validate live DataStore availability or persistence.
