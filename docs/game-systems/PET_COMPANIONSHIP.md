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
