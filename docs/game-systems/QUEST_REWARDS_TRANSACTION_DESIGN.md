# Quest Rewards — Transaction and Recovery Design

Status: server-side persistence and recovery-worker scaffolding implemented. Reward amounts, progression thresholds, reward catalog entries, and live claim endpoint are still not approved by this document.

## Existing storage boundaries

- Quest progress, island resources, tracked quest selection, and island profile revisions are persisted by the island profile DataStore.
- Pet ownership and pet XP are persisted by the separate pet collection DataStore.
- The pet collection already exposes the trusted server-only `grantExperienceWithProgressOnce` operation, keyed by a stable reward ID.
- These two DataStores cannot participate in one atomic transaction.

## Required claim protocol

1. The server verifies that the quest exists and is complete in the active island profile.
2. The server resolves the reward from a server-owned catalog. The client never supplies amounts, resource IDs, XP, pet IDs, or reward IDs.
3. The island profile transaction writes, in one revision:
   - the currency/resource grant;
   - a permanent quest-claim receipt keyed by quest ID;
   - if pet XP is part of the reward, an outbox record with a stable reward ID, the exact pet ID, amount, and progression configuration version.
4. The island revision must become durable before the server acknowledges the claim.
5. An outbox worker delivers pet XP through `grantExperienceWithProgressOnce` using the exact persisted reward ID.
6. The worker marks the outbox record delivered in a later durable island revision.
7. The worker persists a source acknowledgement in another durable island revision. This proves the pet XP write was confirmed before the pet receipt retention clock starts.
8. The worker acknowledges the pet-side receipt. If the receipt is already absent after the source acknowledgement is durable, it is safe to finalize: the source marker proves the XP write had already succeeded, and unacknowledged pet receipts never expire.
9. The worker persists a final pet-receipt acknowledgement marker in the island outbox. Only records with this final marker may be compacted on a later enqueue.
10. If the worker crashes at any boundary, it resumes from the corresponding outbox phase. XP delivery retries always reuse the same reward ID.

## Retention and recovery invariant

The pet-side idempotency receipt must remain available until the island source acknowledgement is durable. Implemented ordering: the island first persists `deliveredAt`, then persists `acknowledgedAt`; only then does the worker call the pet receipt acknowledgement that starts the seven-day retention window. Finally, the island persists `petAcknowledgedAt`. The outbox record is compactable only after this final marker. If the worker resumes after the pet receipt has already expired, a missing receipt is accepted only when the source acknowledgement is already durable. Unacknowledged receipts remain retained indefinitely.

Quest claim receipts in the island profile must be retained for the lifetime of the quest claim (or represented by a permanent claimed flag). They must not be evicted by a rolling short-term ledger.

## Required failure tests before release

- Duplicate claim request returns the original result and grants nothing twice.
- DataStore timeout before island commit grants nothing and leaves the quest claimable.
- Island commit succeeds but response is lost; retry returns already claimed.
- Pet XP commit succeeds but outbox acknowledgement fails; retry uses the same reward ID and grants no duplicate XP.
- Pet DataStore unavailable; outbox remains pending and retries safely.
- Player leaves or server shuts down during delivery; a later server resumes the outbox.
- Pet is no longer owned / invalid target; delivery fails closed and creates an actionable recovery state.
- Currency cap reached; the entire claim is rejected without partial resource grants or a claim receipt.

## Not approved yet

- Gold/Gems/resource reward amounts.
- Pet XP amounts and level thresholds.
- Which pet receives XP (claim-time selection vs. deterministic active pet).
- Any claim UI or reward animation.

Do not enable a live claim button until the economy values and pet recipient rule are approved and the cross-DataStore recovery tests pass.


## Implemented server-side transaction primitives (2026-11-22)

- `IslandSessionService.commitQuestRewardClaim` verifies server-side quest completion and commits the permanent claim receipt plus pet XP outbox record in one island profile revision. It accepts only an internal server-resolved reward plan; no RemoteFunction or client-supplied reward data is exposed.
- Claim receipts record the island revision that must be durable before the claim can be acknowledged. Retries wait for that revision and return the original receipt.
- `commitQuestRewardDelivery` records pet-side XP delivery in a later durable island revision. Duplicate delivery calls also verify persistence before returning success.
- `commitQuestRewardAcknowledgement` records the source-side acknowledgement after durable pet XP delivery and before pet receipt acknowledgement. `commitQuestRewardPetAcknowledgement` records the final pet receipt acknowledgement in another durable island revision.
- `getPendingQuestRewards`, `getQuestRewardsAwaitingAcknowledgement`, and `getQuestRewardsAwaitingPetAcknowledgement` expose the three recovery phases to trusted server code.
- Outbox records are compactable only after both source acknowledgement and final pet acknowledgement are durable. Pending, delivered-but-unacknowledged, and source-acknowledged-but-not-finalized records are never evicted; permanent quest claim receipts are retained separately.
- Still NOT DONE: reward catalog/balance approval, recipient selection, XP threshold configuration, live claim remote/UI, and execution of the Studio fault-injection suite against Roblox DataStores.


## Recovery worker implementation (2026-11-22)

- Added `QuestRewardRecoveryService`, started by the server bootstrap. It waits for the exact Player's writable island session and ready pet collection before processing.
- For pending records it resolves the exact stored progression version, calls `grantExperienceWithProgressOnce` with the stable reward ID and stored pet ID/amount, persists island delivery, persists source acknowledgement, acknowledges the pet receipt, and persists a final pet acknowledgement marker.
- For delivered-but-unacknowledged records it resumes at source acknowledgement. For source-acknowledged-but-not-finalized records it resumes at pet receipt acknowledgement. The source marker is persisted before the pet receipt retention clock starts, so prolonged source-store outages cannot expire the only deduplication receipt.
- DataStore failures, unavailable targets, and configuration gaps fail closed and retry without changing or dropping the outbox record.
- Added `PetProgressionCatalog` as a versioned server-owned registry. It is intentionally empty until XP thresholds are approved; unknown versions return `PROGRESSION_VERSION_NOT_CONFIGURED`. This prevents the worker from inventing a progression curve or delivering a reward with the wrong curve.
- Added Studio-only catalog contract tests and started the worker from `Bootstrap.server.lua`.
- The worker is infrastructure only while the catalog is empty: no quest reward can be delivered until a progression version is explicitly configured and a trusted claim catalog creates valid outbox records.
- Remaining: add service-level fault-injection tests for every transaction boundary, run Studio tests, and approve progression/reward/recipient policy.


## Recovery protocol fault-injection coverage (2026-11-22)

- Extracted the ordered cross-DataStore handshake into `QuestRewardRecoveryProtocol`; the production recovery worker now delegates both pending delivery and delivered-record finalization to this shared protocol.
- Added `QuestRewardRecoveryProtocolTests.server.lua`, a deterministic Studio-only fault-injection suite. It simulates a lost response immediately after each durable boundary: pet XP grant, island delivery marker, source acknowledgement, pet receipt acknowledgement, and final pet acknowledgement marker.
- Each scenario retries with the same stable reward ID and asserts XP is applied exactly once and all durable phases eventually complete.
- Additional cases verify that an already-delivered record resumes without invoking XP grant, and that `RECEIPT_NOT_FOUND` is accepted only after source acknowledgement is durable.
- These are deterministic adapter-level fault-injection tests, not live Roblox DataStore outage tests. The latter still require Studio execution with a dedicated test place/account and controlled DataStore access.


## Atomic gathering and quest progress integration (2026-11-22)

The production gathering commit now uses `IslandGatheringTransactionData.apply(profile, nodeId, now)` to compute the complete candidate state before mutating the live session. The pure transform validates the wallet and quest state, records the node cooldown, grants the canonical resource reward, and advances the matching quest. Only when all stages succeed does `IslandSessionService.commitResourceGathering` assign resources, resource-node cooldowns, and quest progress together and persist them under one profile revision.

A Studio-only integration contract suite covers successful wood/stone gathering, independent node cooldowns, wood quest completion, immutable source state, cooldown rejection, wallet-cap rejection, malformed quest state, and unknown nodes. These tests still require execution in Roblox Studio; Rojo CI only verifies project packaging.
