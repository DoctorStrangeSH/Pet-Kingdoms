# Island Session Lease

> Status: MemoryStore lease implementation is committed and wired into the server profile lifecycle. It has not been executed or load-tested in Roblox Studio.

## Contract

- Backing service: MemoryStoreService HashMap `PetKingdoms_IslandLeases_v1`.
- Key: `player_<UserId>`.
- Each server session creates an unpredictable GUID token.
- Lease TTL: 90 seconds.
- Renewal interval: 30 seconds.
- Acquire is atomic through HashMap UpdateAsync. A live lease with another token is not replaced.
- Renew succeeds only when the stored token matches and the lease has not expired.
- Release changes the matching token's record to a released marker with a one-second expiration. It never removes another server's lease.
- All MemoryStore errors fail closed. A player is not allowed to continue mutating an island when lease acquisition or renewal cannot be confirmed.

## Lifecycle integration

1. Acquire lease before loading or creating the profile.
2. If acquisition fails, reject the join; do not read or write the profile.
3. Keep the token in the in-memory session and renew every 30 seconds.
4. If renewal fails, mark the session invalid/closing and kick the player. Saves are refused once the lease is invalid.
5. Save dirty data before releasing the lease on PlayerRemoving.
6. On shutdown, attempt final save and release the matching lease; lease TTL remains the crash-recovery fallback.

## Safety notes and limitations

- A MemoryStore outage can cause a conservative disconnect; this is preferable to allowing two active writers.
- If a server crashes, the lease expires after its TTL. Reconnect may be blocked until expiry.
- The current implementation does not implement a separate DataStore fencing number. Revision checks remain a second line of defense, not a substitute for the lease.
- A network timeout during renewal is treated as lease loss even if the request may have reached MemoryStore. This avoids uncertain writes.
- Test with two Studio server instances or a dedicated test universe: simultaneous acquire, renewal, expiry takeover, release by stale token, MemoryStore throttling/outage, and server shutdown.
- `IslandLeaseServiceTests.server.lua` now covers invalid arguments, first acquire, rejection of a second token, owner-only renewal/release, stale-token protection, and reacquisition after release. It requires a dedicated Studio test universe with MemoryStore API access; it has not been executed here.
- Expiry takeover and forced MemoryStore outage/throttling still require separate multi-server/manual integration tests.
