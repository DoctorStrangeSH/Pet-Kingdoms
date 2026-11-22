# Pet Companionship — First Playable Interaction Loop

> Status: code milestone committed. The interaction loop is provisional and still requires Roblox Studio, DataStore, PC, and touch-device verification. Values are initial tuning constants, not final economy balance.

## Product basis

The project specification explicitly calls for expressive collected pets, companionship, a team of up to three, pet Bond progression, and XP from interactions. The MVP does not yet define exact interaction actions, rewards, or cooldown values. This implementation adds the smallest testable loop without inventing consumable prices or currency costs.

## Player actions

- **Погладить** (pet): grants 10 provisional Bond XP to the selected owned pet.
- **Поиграть** (play): grants 10 provisional Bond XP to the selected owned pet.
- Both actions share a 30-second per-pet cooldown, so switching between the two actions does not bypass the cooldown.
- Interactions are available from the selected pet's collection detail panel.
- A successful action triggers a short server-replicated emotion cue: happy for affection, curious for play.

No food/inventory action is added because an approved food catalogue and resource cost are not defined yet.

## Bond progression

- Each pet stores bondXp, bondLevel, and lastInteractionAt.
- Bond starts at level 1.
- Every 50 accumulated Bond XP grants one level.
- Maximum Bond level is provisionally 10; maximum stored XP is capped at 450 (9 level-ups × 50 XP). XP does not continue accumulating after the cap.
- XP and cooldown timestamp are persisted in the existing pet collection DataStore record.
- Old collection records without these optional fields remain valid and normalize to 0 XP, level 1, and timestamp 0 when cloned.
- Bond level is per pet; it is not the same as the island-wide Kingdom Bond stage.
- Validation enforces integer XP/timestamps and requires the stored level to match the level derived from XP. Inconsistent or over-cap records are rejected rather than silently accepted.

## Security and persistence

- The server verifies the player collection is loaded, validates the requested pet is owned, checks the expected revision, and performs the mutation inside DataStore UpdateAsync.
- Client-supplied XP, level, timestamps, or cooldown values are never accepted.
- A one-second per-player request throttle protects the DataStore path; the per-pet cooldown is persisted and enforced inside the pure data mutation.
- The collection revision increments on successful interactions to prevent stale concurrent mutations.
- Max-level interactions remain available but do not exceed the XP cap.
- No currencies or consumables are charged.

## Implementation

- Pure rules and normalization: ReplicatedStorage/Shared/Pets/PetCollectionData.lua
- Server-authoritative persistence and emotion replication: ServerScriptService/Services/PetCollectionService.lua
- Collection controls and progress display: StarterPlayer/StarterPlayerScripts/PetCollectionUI.client.lua
- Visible emotion animation: StarterPlayer/StarterPlayerScripts/CompanionFollowController.lua
- Contract tests: ServerScriptService/Tests/PetCollectionDataTests.server.lua

## Not implemented

- Feeding with actual inventory items.
- Pet needs, hunger, stamina, or decay timers.
- Distinct personality traits and reactions.
- Pet levels/stats/skills/equipment from the broader progression spec.
- Interaction XP contribution to island-wide Kingdom Bond.
- Final XP curve and cooldown tuning.
- Studio DataStore integration, multiplayer, mobile, and visual animation verification.


## Ordinary Pet XP reward foundation

- `PetCollectionData.grantExperience(profile, petId, amount)` is a pure validated mutation for ordinary pet XP. It requires a positive finite integer reward and an owned pet, increments only `xp` and collection revision, and leaves Bond fields unchanged.
- `PetCollectionService.grantExperience(player, petId, amount)` is the trusted server-only persistence entry point. It writes through DataStore `UpdateAsync` and is not exposed through a client remote.
- Combat, quest, and interaction systems may call this API only after validating their gameplay event on the server. The current collection UI does not directly award ordinary Pet XP.
- Reward values, level thresholds, level-up math, source callers, and replay/idempotency policy remain undefined; no balance values are assumed here.


## Pet collection concurrency safeguard

- Mutation results are synchronized into the in-memory profile only when their revision is not older than the current snapshot. This prevents delayed DataStore responses from regressing the live profile after a newer concurrent mutation has already completed.
- Verify concurrent Equip, Interact, and server XP reward calls in Studio; persisted DataStore ordering and live in-memory ordering both need integration coverage.


- Equip/Interact RemoteFunction responses return the newest in-memory collection snapshot after revision-aware synchronization, not a potentially stale individual DataStore response. This keeps the client view aligned with concurrent server mutations.


## Companion reaction state priority

- Player-triggered Pet/Play emotion cues override autonomous idle personality animations while the pet is stationary, so a user interaction is visible immediately instead of waiting for a random idle action to finish.
- Walk/run states remain dominant during movement. Client Studio tests cover both priority rules; execution is pending.


## Integer precision and overflow protection

- Collection integer fields use the exact-integer ceiling of Luau numbers: `2^53 - 1`. Values beyond this boundary are rejected rather than silently losing precision.
- Pet XP rewards that would exceed the safe integer ceiling return `XP_OVERFLOW`; rewards outside the accepted positive integer range return `INVALID_XP_AMOUNT`.
- Equip, Pet/Play, and XP reward mutations reject a collection revision that cannot be incremented safely (`REVISION_OVERFLOW`).
- Boundary and overflow test cases are committed; Roblox Studio execution remains pending.


## Pet House as a physical collection entrance

- Every rendered `pet_house` building receives a server-created `PetHousePrompt` ProximityPrompt on its door (or a safe model BasePart fallback).
- The localized action is `Открыть коллекцию`; keyboard E, gamepad X, zero hold duration, and 10-stud activation distance.
- The collection UI listens to the local ProximityPromptService event and opens the existing collection panel only when the prompt belongs to a `pet_house` under the local player's own island model.
- The existing collection RemoteFunction remains the only path for equip/protect/delete/interact operations; those mutations remain server-authoritative and revision-checked. The prompt itself grants no ownership or gameplay reward.
- Prompt creation is shared by initial island rendering and live building synchronization, so a newly placed or moved Pet House has the same interaction.
- Studio verification is pending: test keyboard, gamepad, touch prompt presentation, another player's Pet House, and a missing Door part on a custom template.


## Companion grounding correction (2026-11-22)

- Follow controllers now calculate each pet model's actual pivot-to-bounding-box-bottom offset when binding.
- Ground placement no longer assumes a universal 0.28-stud root offset. This supports the procedural Bunny rig and imported mesh pets with center-based pivots and different heights.
- Added a Studio client test with a 4-stud imported-mesh stand-in whose pivot is centered; the expected ground lift is 2 studs.
- This corrects vertical placement only. Obstacle navigation, slope limits, multiplayer replication behavior, and mobile performance still require Studio verification.


## Companion obstacle navigation foundation (2026-11-22)

- CompanionFollowController performs two horizontal obstacle raycasts (low and upper body) before moving directly toward its formation target.
- If the direct lane is blocked, it requests a Roblox PathfindingService route using a 1.25-stud agent radius, 3.2-stud agent height, and jump/climb support.
- Path computation runs asynchronously and is reused while the target remains nearby; blocked waypoints invalidate the route and trigger a retry.
- Waypoint positions are projected onto the island surface and lifted by the companion's measured pivot-to-bounds-bottom offset.
- If navigation is pending or fails, the companion waits instead of walking through an obstacle. When the direct lane clears, path resources are released.
- This is a client-side cosmetic movement system. It does not grant the pet gameplay authority or change server-owned island interactions.
- Studio verification is still required for generated navmesh coverage, narrow paths, stairs, cliffs, streaming, multiplayer presentation, and mobile performance.

## Companion navigation safety follow-up (2026-11-22)

The obstruction raycast helper now has its horizontal-vector dependency declared in lexical scope before use. Recovery from a distant owner is calculated against the actual formation target, not the current path waypoint; teleporting clears pending routes and increments their generation to discard stale asynchronous results. Studio tests cover this interrupted-navigation case, but real obstacle, stairs and mobile traversal remain unverified.
