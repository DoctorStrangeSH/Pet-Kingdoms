# Island Persistence — DataStore Adapter

> Status: server-side adapter implemented; live DataStore behavior has not been verified in Roblox Studio.

## Storage contract

- Store: `PetKingdoms_Islands_v1`
- Key: `player_<UserId>`
- Payload: compact versioned island profile from `IslandData.lua`, including the persistent `resources` wallet (Wood/Stone/Gold/Gems)
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
- `claimSession(profile)` uses UpdateAsync to increment a monotonic `sessionGeneration` in the same player profile key. It returns the authoritative profile with the claimed generation.
- `save(profile)` uses UpdateAsync and checks that the stored `sessionGeneration` exactly matches the submitted generation inside the same atomic transform that writes the profile.
- A stale server generation is rejected even if its revision number is larger than the current stored revision.
- Within the same generation, refuses to overwrite a stored profile whose revision is equal to or newer than the submitted snapshot.
- Important: the UpdateAsync transform returns the existing value when rejecting a write. Returning `nil` from an UpdateAsync transform cancels the write but the API still returns the current stored value; callers must not use a nil result as the rejection signal.
- Tracks whether the transform accepted the submitted snapshot and reports `SAVED` only when that write was accepted.
- Retries transient failures up to four attempts.
- Returns an explicit result code; callers must not report save success unless the result is successful.

## Important integration boundary

The adapter is connected to the server PlayerAdded/PlayerRemoving/autosave/BindToClose profile lifecycle through `IslandSessionService`, but the complete lifecycle has not been verified in Roblox Studio. Island spawning and a building transaction service are not implemented.

Before integration:
1. Define the authoritative island bounds and initial profile defaults from the approved world layout.
2. Acquire the MemoryStore coordination lease, then claim the next DataStore `sessionGeneration` before opening the player session.
3. Increment revision on every successful state mutation; preserve the claimed generation in all snapshots.
4. Save on controlled checkpoints and PlayerRemoving; use BindToClose as a best-effort final flush.
5. Keep the player in a safe loading state if load/claim fails; never create a blank profile over an unavailable/invalid save.
6. Test Studio API access, throttling, disconnects, shutdown, stale generations, stale writes, and recovery using a dedicated test universe.

## Studio contract smoke test

`src/ServerScriptService/Tests/IslandStoreTests.server.lua` checks only that invalid inputs are rejected before any DataStore access. It does not validate live DataStore availability or persistence.


## Profile collection integrity

- The persisted `buildings` collection must be a contiguous 1-based array; sparse indexes and dictionary keys are rejected.
- A profile may contain at most 256 building records. This is a defensive validation ceiling for the MVP data contract, not a player-facing progression limit; revisit it only with an explicit performance and product decision.
- Unknown IDs in `unlockedBuildingIds` are rejected instead of silently accepted.
- Studio tests cover sparse/dictionary building collections and over-limit profiles. These tests are committed but not yet executed in Studio.


## Resource wallet migration

Existing schema-v1 records without a `resources` field remain valid. `IslandStore.load` supplies the provisional starter wallet in memory; `claimSession` writes it into the profile as part of the atomic session-generation claim. Save snapshots clone the wallet table. See `ISLAND_RESOURCE_WALLET.md` for the server-only grant/spend API and outstanding gathering/economy work.

## DataStore-side session fencing

The profile stores an optional `sessionGeneration` field for backward compatibility with existing schema-v1 records. A successful `claimSession` increments it atomically in the profile's DataStore key only if the currently stored generation still equals the generation observed by that loader (`compare-and-swap`). A delayed loader holding an older profile snapshot cannot supersede a newer claim. Every save must include that generation, and the UpdateAsync transform compares it to the current stored generation before accepting the snapshot. This makes the generation check atomic with the profile write; the MemoryStore lease remains a coordination/fast-rejection layer, not the fencing authority.

`IslandStoreTests.server.lua` now includes an integration scenario: claim generation A, assert a stale loader using the original generation-zero snapshot cannot claim, claim generation B from A's current profile, assert that A cannot save, then assert B can save. It uses a synthetic user key and requires a dedicated test universe with DataStore API access. The test has been committed but not executed here.
