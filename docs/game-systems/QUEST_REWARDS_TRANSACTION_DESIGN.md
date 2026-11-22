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
5. An outbox worker delivers pet XP through `grantExperienceWithProgressOnce`.
6. The worker marks the outbox record delivered in a later durable island revision.
7. If the worker crashes after pet XP commits but before the island acknowledgement, it retries the same reward ID. The pet collection must return an idempotent duplicate result without applying XP again.

## Retention and recovery invariant

The pet-side idempotency receipt must remain available for at least as long as its corresponding island outbox can be retried. Implemented: unacknowledged receipts are retained indefinitely; a trusted source acknowledgement records acknowledgedAt, after which the seven-day retention window applies. The island outbox must call this acknowledgement only after its own delivered state is durable. Until that caller integration exists, receipts remain unacknowledged and do not expire.

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
- `commitQuestRewardAcknowledgement` records the source-side acknowledgement only after the caller has durably acknowledged the pet-side XP receipt. `getPendingQuestRewards` and `getQuestRewardsAwaitingAcknowledgement` expose separate recovery phases to trusted server code.
- Fully acknowledged outbox records may be compacted on a later enqueue. Pending and delivered-but-unacknowledged records are never evicted; permanent quest claim receipts are retained separately.
- Still NOT DONE: reward catalog/balance approval, recipient selection, XP threshold configuration, worker integration, live claim remote/UI, and cross-DataStore fault-injection tests.


## Recovery worker implementation (2026-11-22)

- Added `QuestRewardRecoveryService`, started by the server bootstrap. It waits for the exact Player's writable island session and ready pet collection before processing.
- For pending records it resolves the exact stored progression version, calls `grantExperienceWithProgressOnce` with the stable reward ID and stored pet ID/amount, persists the island delivery transition, acknowledges the pet receipt, and finally persists the island source acknowledgement.
- For delivered-but-unacknowledged records it resumes at the receipt acknowledgement phase. DataStore failures, unavailable targets, and configuration gaps fail closed and retry without changing or dropping the outbox record.
- Added `PetProgressionCatalog` as a versioned server-owned registry. It is intentionally empty until XP thresholds are approved; unknown versions return `PROGRESSION_VERSION_NOT_CONFIGURED`. This prevents the worker from inventing a progression curve or delivering a reward with the wrong curve.
- Added Studio-only catalog contract tests and started the worker from `Bootstrap.server.lua`.
- The worker is infrastructure only while the catalog is empty: no quest reward can be delivered until a progression version is explicitly configured and a trusted claim catalog creates valid outbox records.
- Remaining: resolve the pet-receipt/source-ack retry retention edge case under prolonged DataStore outage, add service-level fault-injection tests, run Studio tests, and approve progression/reward/recipient policy.
