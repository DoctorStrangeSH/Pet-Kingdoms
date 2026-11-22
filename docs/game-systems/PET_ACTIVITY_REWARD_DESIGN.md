# Pet Activity Rewards — Design Contract

Status: architecture contract only. No XP amounts, cooldowns, recipient policy, or balance values are approved by this document.

## Goal

Award pet progression XP for the three source categories named in the project specification:

1. Combat.
2. Quests.
3. Interactions.

Pet progression XP is distinct from Kingdom Bond XP. Bond XP represents relationship growth and keeps its own rules, cooldown, and persistence. A single interaction must not silently grant both currencies unless a later design explicitly approves that behavior.

## Non-negotiable invariants

- The server decides whether an activity actually happened and whether it qualifies.
- Clients never submit XP amounts, pet IDs, progression versions, or reward IDs.
- Every XP grant uses `PetCollectionService.grantExperienceWithProgressOnce` with a stable, server-generated reward ID.
- Retrying the same activity reward must not grant XP twice. Reusing an ID with a different payload must fail closed.
- The progression version and XP amount are selected by server-owned configuration, never by a client.
- The recipient pet is selected by a documented deterministic policy. Do not assume the currently equipped pet, all equipped pets, or the highest-level pet until this policy is approved.
- A source event must remain recoverable across player leave, server shutdown, and DataStore failures. Cross-DataStore delivery uses a durable source outbox and acknowledgement protocol; do not replace it with sequential best-effort writes.
- A missing progression configuration or invalid source event defers/rejects delivery without consuming the source event.
- Pet XP and level are committed together in the pet collection profile.
- Level is capped at 50; lifetime XP remains retained.

## Source-specific requirements

### Quest

- Quest completion and claim receipt are separate states.
- The existing island quest reward outbox is the durable source boundary.
- Claiming remains disabled until reward amounts, progression version, and deterministic recipient policy are approved.

### Combat

- The server must validate the encounter, target, contribution, and completion outcome.
- Reward identity must derive from a server-owned encounter/reward instance, not a client timestamp or client-provided string.
- Define anti-farming, repeated-target, party contribution, defeat, and disconnect behavior before enabling XP.
- Combat does not yet have an approved runtime implementation or balance.

### Interaction

- The server must validate interaction target, ownership/range, cooldown, and qualifying outcome.
- Existing Bond XP interaction handling is not a substitute for pet progression XP.
- Define whether interaction XP is one-time, daily, repeatable with cooldown, or activity-session based before enabling it.
- No interaction progression XP amount or cooldown is approved.

## Required implementation sequence

1. Keep the idempotent pet XP service boundary as the only XP DataStore write API.
2. Add source-specific server event validation and stable reward-ID creation.
3. Add durable source outbox/receipt handling for each cross-profile source.
4. Add an explicit, tested pet-recipient policy.
5. Add source-specific deterministic tests, including retries and interrupted delivery.
6. Approve the XP curve and source amounts in the economy balance sheet.
7. Only then enable live reward issuance and validate it in Roblox Studio with DataStore fault injection.

## Explicitly not part of this contract

- No XP rates or amounts.
- No level-up stat bonuses.
- No skill tree or skill unlock thresholds.
- No pet evolution.
- No recipient selection rule.
- No combat/interaction reward endpoint.
- No client-triggered reward request.


## Existing Bond interaction implementation audit (2026-11-22)

- The current collection supports only two interaction intents: `pet` and `play`. `feed` remains rejected until a food inventory/cost contract exists.
- These actions award Bond XP only, using the existing per-pet cooldown. They do not award pet progression XP.
- The server validates ownership through the persisted profile, checks the expected collection revision, rate-limits mutation requests, and writes through the collection DataStore session fence.
- Pet IDs are now constrained to the same bounded safe identifier alphabet used by server-generated collection IDs. Expected revisions must be finite, non-negative safe integers.
- Pure data tests now cover the exact cooldown boundary, rollback attempts, selected-pet isolation, progression XP/Bond separation, and malformed identifiers.
- Personality-specific preferences, feeding, consumable costs, and progression XP for interactions remain unimplemented/open; do not invent these behaviors.
