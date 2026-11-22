# Island Resource Wallet — MVP Foundation

> Status: persistent wallet schema, backward-compatible profile migration, server-only grant/spend facade, and pure contract tests are committed. Gathering nodes, reward tables, building prices, and client UI are not implemented.

## Resource IDs

The wallet currently recognizes:
- `wood`
- `stone`
- `gold`
- `gems`

Biome-specific resources remain a later extension; do not accept arbitrary resource IDs from clients.

## Starter balances

The current profile initializer uses the previously documented provisional baseline:
- 2 Wood
- 1 Stone
- 0 Gold
- 0 Gems

These are provisional implementation defaults, not final balance approval. Keep values centralized in `IslandResources.STARTER_BALANCES`.

## Persistence and migration

- Wallet balances are stored inside the versioned island profile at `resources`.
- Existing schema-v1 profiles without `resources` are migrated in memory on load and receive the wallet during `claimSession`'s atomic UpdateAsync write.
- Save snapshots deep-copy the wallet table so mutations during a yielding DataStore call cannot alter the submitted snapshot.
- Wallet validation rejects unknown IDs, negative/fractional balances, NaN/infinite values, and values above the defensive integer ceiling.
- The schema version remains 1 because the new field is backward-compatible and optional during validation for legacy records.

## Server API

`IslandResourceService.getBalance(userId, resourceId)`
- Reads the current server-owned session balance.

`IslandResourceService.grant(userId, resourceId, amount)`
- Grants a validated positive integer amount.
- Marks the profile dirty.
- Rolls back the wallet if the session is not writable.

`IslandResourceService.spend(userId, costs)`
- Validates all resource IDs and amounts before changing any balance.
- Checks all balances before mutating any balance (all-or-nothing).
- Marks the profile dirty.
- Rolls back the wallet if the session is not writable.

These functions are server-only module APIs. Do not expose a RemoteFunction that accepts arbitrary grant amounts or client-provided costs. Gathering and building services must derive rewards/prices from server-owned definitions.

## Client display

- `IslandResourceHUD.client.lua` renders a compact four-resource HUD for Wood, Stone, Gold, and Gems.
- The client requests the initial wallet snapshot through `IslandResourceRequest` (`Get`). This endpoint returns data only; it cannot grant or spend resources.
- Successful server wallet mutations publish a complete authoritative snapshot through `IslandResourceUpdate`.
- Gathering grants additionally show a short localized reward toast. The HUD resizes for narrow viewports and uses the Roblox ProximityPrompt touch affordance for mobile gathering.
- The HUD is a first functional interface pass; visual/device acceptance still requires Roblox Studio review.

## Explicitly not implemented yet

- Resource node visuals and respawn timers are implemented; see `ISLAND_GATHERING.md`.
- Inventory HUD/toast and gathering animation are not implemented.
- Building costs/refunds; catalog prices remain intentionally unset until approved.
- Gold/gem earning and shops.
- Resource inventory UI.
- Economy balance sheet and final tuning.
- Studio/DataStore integration verification.

## Tests

- `IslandResourcesTests.server.lua`: starter balances, grant, atomic multi-resource spend, insufficient balance rollback, unknown IDs, fractional values, negative balances, and overflow.
- `IslandDataTests.server.lua`: wallet defaults and invalid resource balance rejection.

These Studio tests are committed; execution in Roblox Studio is still pending.


## Pet hatching integration constraint

The island wallet and pet collection currently live in separate DataStores. The current `spend` API mutates the loaded island session and marks it dirty for autosave; it is not a durable transaction acknowledgement. Do not implement paid egg hatching as a simple `spend` followed by `grantPet`. A server crash between operations can leave the player charged without a pet.

Before paid hatching ships, add a persisted transaction journal/debit receipt in the island profile, a durable save/commit acknowledgement, and retry/reconciliation using the same hatch transaction ID and pet acquisition ID. The selected species and rarity must be fixed in the durable prepared record before charging, so a retry cannot reroll. The pet collection acquisition receipt remains the idempotent grant boundary.


## Persisted hatch journal data contract

Island profiles now support an optional `hatchTransactions` array (new profiles initialize it empty). Each record fixes the egg ID, selected species, rarity tier, costs, acquisition ID, timestamp, and transaction state. `IslandHatchLedgerData` provides pure prepare/debit/complete transformations. The debit and CHARGED state are changed together in one profile snapshot, and repeated debit attempts are idempotent.

This module does not itself write DataStore. Until a serialized session API durably saves each transition and recovery handles PREPARED/CHARGED records across server restarts, it is not safe to acknowledge paid hatching to players or expose a hatch endpoint.


## Durable session mutation acknowledgement

`IslandSessionService.applyHatchOperation` now applies a single journal transition under a per-session hatch guard and waits for the exact profile revision to be confirmed by `IslandStore.save`. A timeout leaves the in-memory profile dirty so the existing autosave loop can retry; a later retry must reuse the same transaction ID. This provides a durable island-side acknowledgement, but does not yet orchestrate recovery or reconcile the separate pet collection DataStore.


## Recovery after player rejoin

`PetHatchingRecoveryService` waits until both the island session and pet collection are loaded. It resumes PREPARED transactions by charging the persisted cost snapshot, resumes CHARGED transactions by calling the idempotent pet grant with the stored acquisition ID, and only then marks the island journal GRANTED. A retry after a successful pet DataStore write but a lost response returns the existing acquisition receipt rather than creating another pet.

If the pet collection is full or either datastore is unavailable, the transaction remains pending; it is not silently discarded. The recovery worker retries on a later join. A capacity reservation or overflow/inbox policy is still required before paid hatching is enabled.


## Pet collection capacity reservation contract

Before a hatch is charged, `PetCollectionService.reservePetSlot` persists one slot in the pet collection profile under the transaction's acquisition ID. The invariant is `owned + reserved <= MAX_OWNED_PETS`. Ordinary pet rewards cannot consume reserved capacity. The matching idempotent grant atomically consumes the reservation and adds the owned pet.

Recovery reserves capacity before resuming a PREPARED or CHARGED transaction. If no slot is available, it defers without charging a PREPARED transaction. Reservations are not auto-expired because the island journal may still contain a payable or already charged transaction. Cancellation/release requires a future coordinated protocol.


## Pet inventory protection and removal

Pet records now carry `isLocked` and `isFavorite` flags. The server exposes revision-checked `Protect` and `Delete` collection actions. Permanent removal is denied for the starter Bunny, locked pets, equipped pets, and the last remaining pet. A successful deletion frees capacity. Future UI confirmation and sorting/filtering are not part of this technical foundation.
