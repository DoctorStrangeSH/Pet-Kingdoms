# Pet Kingdoms — Project Specification

> Status: baseline reconstructed from the approved project direction and decisions available on 2026-11-21. Items not yet confirmed are explicitly marked as open; do not silently invent requirements.

## 1. Vision

Create a colorful, child-friendly Roblox adventure where players collect and bond with expressive pets, explore a fantasy world, and build a personal kingdom on a persistent, expandable island.

The experience must be easy to understand, visually distinctive, satisfying over long play sessions, and designed for PC and mobile from the beginning.

## 2. Non-negotiable product principles

- Prefer original, carefully art-directed visuals and custom-created production assets. For playable prototypes and Studio testing, vetted free Creator Store/Toolbox assets are explicitly allowed as temporary placeholders. They must be reviewed, provenance-tracked, isolated from production asset catalogs, and replaceable without changing gameplay logic.
- Use a consistent colorful stylized-fantasy art direction, expressive cute 3D pets, warm fairytale lighting, and a polished fantasy UI using gold, purple, and turquoise accents.
- Keep the interface clear enough for children to understand without adult explanation.
- The player's home island is persistent and expandable; islands do not float away or move around.
- Bridges connect the home island to shared exploration areas.
- Farming and building must have meaningful gameplay purpose, not be decorative chores.
- Support mobile performance and touch controls.
- Important gameplay and economy actions must be validated by the server.
- Monetization must be optional and ethical; avoid pay-to-win advantages.

## 3. MVP delivery order

Work in this order. Do not expand scope or add unrelated mechanics before the MVP is complete.

1. Pet Art Pipeline.
2. Green Valley biome.
3. Starter Island, building, and Kingdom Bond.
4. Pet Collection.
5. Core Gameplay.

## 4. World and first biome

### Green Valley

The first biome is Green Valley. Its planned zones are:

- Meadow
- Deep Forest
- Crystal Creek
- Ancient Grove
- Wildflower Hills

The biome should be compact but visually dense, with discoverable resources, wild-pet encounters, and taming opportunities.

### Home islands and shared spaces

The previously approved world direction includes persistent personal home turtle-islands (up to eight player islands in a server) and shared Sun Grove and Moon Grove spaces connected by bridges.

A prior prototype milestone described:
- Starter inventory: 2 Wood and 1 Stone.
- Resource nodes: +3 Wood or +2 Stone per gather, with a 60-second respawn.
- Bridge repair: 5 Wood and 3 Stone.
- Guest protections and saved progress.

These values are provisional until verified against the actual game implementation and final balancing pass.

## 5. Pets and companionship

### Collection target

MVP collection target: 20 pets.

Named initial examples:
- Bunny
- Green Slime
- Forest Cat
- Leaf Fox
- Ice Bunny
- Snow Wolf
- Frost Owl
- Crystal Bear

The remaining twelve species and final rarity distribution are open decisions.

### Companion behavior

- Up to 3 active pets.
- One main companion.
- Team management menu.
- Companion states: Follow, Idle, Curious, Alert, Combat, Happy.
- Smooth, collision-safe movement, optimized for mobile.
- Server-authoritative handling for important gameplay actions.

Proposed exploration roles:
- Leaf Fox: resource finding.
- Bunny: secrets.
- Frost Owl: hidden objects.
- Forest Cat: hard-to-reach areas.

### Progression

- Maximum pet level: 50.
- XP sources: combat, quests, and interactions.
- Core stats: Health, Attack, Defense, Speed, Critical Chance.
- Skill tree, equipment, individual abilities, and Bond progression.
- Three active skills plus one additional progression slot.
- All six rarity tiers can reach level 50.
- Evolution is post-MVP and must not block 1.0.

## 6. Economy

The approved economy direction includes:

- Gold.
- Gems.
- Biome-specific resources.
- Quest rewards.
- Upgrade costs.
- Shops and purchasable items.
- A complete free progression path.
- Optional purchases that do not create pay-to-win advantages.

Exact earning rates, prices, inventory limits, shop catalogue, island expansion costs/unlock conditions, and monetization products remain open until an economy balance sheet is approved. Pet egg prices, hatch costs, and drop-rate tables are also unapproved; the codebase currently provides only a reusable weighted-selection data contract. Paid hatching must use a recoverable idempotent transaction across the island wallet and pet collection DataStores; a simple sequential spend-then-grant is not acceptable.

## 7. Building and kingdom

The player chooses what to build and how to arrange the home island. The building system should eventually support placement, moving, rotation, removal, footprint validation, and saving the island layout.

The previously discussed building-mode concept is a design proposal, not an implemented feature. Exact MVP building catalogue, plot rules, upgrade tree, construction costs, and placement constraints remain open until confirmed in the implementation plan.

Kingdom Bond is an approved system that changes the island's visual appearance as the player's relationship/progression with the kingdom grows. Exact thresholds and visual stages remain open.

## 8. UI and accessibility

- Child-friendly, understandable navigation and feedback.
- Large, readable controls and clear icons.
- Consistent visual hierarchy and polished fantasy styling.
- Responsive layouts and touch-friendly interaction for mobile.
- Clear feedback for gathering, building, pet interactions, rewards, and progression.

## 9. Technical and quality requirements

- Server validates currency, resource costs, ownership, placement, rewards, and other consequential actions.
- Persist player progression and island layout safely.
- Handle save failures and avoid duplicate reward issuance.
- Avoid trusting client-submitted prices, amounts, ownership, or placement validity.
- Keep systems modular so post-MVP content can be added without rewriting the MVP.
- Verify behavior in Roblox Studio; automated tests alone do not establish visual, physics, DataStore, or mobile correctness.

## 10. Out of scope before MVP

- Pet evolution.
- New biomes beyond the first Green Valley release.
- Unapproved systems or content expansions.
- Monetization that sells competitive power or bypasses core progression.

## 11. Open decisions

These must be resolved from the original full specification or by an explicit product decision before implementation:
- Exact Roblox project workflow (Rojo, Studio-only, or hybrid).
- Final list and rarity distribution of all 20 MVP pets.
- Complete MVP building catalogue and construction economy.
- Exact Gold/Gems/resource rates and shop inventory.
- Kingdom Bond thresholds and island visual stages.
- Combat/quest/taming details and MVP completion criteria.
- DataStore schema, save versioning, and recovery policy.
- Release acceptance criteria and performance budgets.
