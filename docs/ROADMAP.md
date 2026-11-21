# Pet Kingdoms — Roadmap

> Rule: deliver the approved MVP in order. No scope expansion before 1.0. A task is DONE only when the implementation is in this repository and its relevant verification has passed.

## Stage 0 — Repository foundation

- [x] Create project README and central specification.
- [x] Create a single source-of-truth roadmap.
- [x] Confirm the intended Roblox development workflow: hybrid Rojo + VS Code + Roblox Studio.
- [x] Add the initial Rojo project mapping and source folder structure.
- [x] Add server and client bootstrap entrypoints.
- [x] Document the local build/live-sync workflow.
- [ ] Run a real Rojo build and record the result.
- [ ] Add CI checks appropriate to the chosen workflow.

## Stage 1 — Pet Art Pipeline

- [x] Document the visual style guide and technical asset standards in ART_BIBLE.md.
- [ ] Review and formally approve the art bible against the full original specification.
- [ ] Create the first original pet model and animation pipeline.
- [ ] Validate scale, silhouette, materials, rig, animation, and mobile performance.
- [ ] Produce a reusable template for all 20 MVP pets.

## Stage 2 — Green Valley

- [ ] Build the Meadow.
- [ ] Build Deep Forest.
- [ ] Build Crystal Creek.
- [ ] Build Ancient Grove.
- [ ] Build Wildflower Hills.
- [ ] Add gathering nodes, wild-pet encounters, and taming opportunities.
- [ ] Validate navigation, readability, performance, and exploration flow.

## Stage 3 — Starter Island, building, and Kingdom Bond

- [x] Document the MVP building-system design and server-authority requirements.

- [ ] Implement persistent personal home islands.
- [ ] Implement shared Sun Grove and Moon Grove connections.
- [ ] Implement bridge repair and guest permissions.
- [ ] Implement island expansion and validated building placement.
- [ ] Implement island layout persistence and recovery.
- [ ] Implement Kingdom Bond progression and visual island changes.
- [ ] Make farming and production meaningfully contribute to progression.

## Stage 4 — Pet Collection

- [ ] Deliver the 20-pet MVP collection.
- [ ] Implement pet inventory and collection UI.
- [ ] Implement up to 3 active companions and team management.
- [ ] Implement companion states and mobile-safe movement.
- [ ] Implement pet levels, XP, stats, skills, equipment, and Bond.
- [ ] Verify all six rarity tiers can reach level 50.

## Stage 5 — Core Gameplay

- [ ] Implement the approved combat loop.
- [ ] Implement quests and rewards.
- [ ] Implement exploration interactions and pet abilities.
- [ ] Implement Gold, Gems, biome resources, shops, and balanced upgrade costs.
- [ ] Verify free progression is complete and optional purchases are non-pay-to-win.

## Stage 6 — 1.0 Release Gate

- [ ] End-to-end playthrough from new player to MVP completion.
- [ ] Save/load, reconnect, duplicate reward, and failure-recovery tests.
- [ ] Server-authority and exploit-resistance review.
- [ ] Roblox Studio visual/physics checks.
- [ ] PC and mobile usability/performance checks.
- [ ] Fix all release-blocking bugs; freeze scope for 1.0.

## Current status

The repository now contains the documentation baseline, Rojo mapping, grid math, server/client bootstraps, a server-owned starter building catalog, a pure placement validator, and a Studio-only smoke-test script. The validator and tests are committed but have not been executed in Roblox Studio; no end-to-end building gameplay, resource charging, persistence, or production asset is claimed as complete.
