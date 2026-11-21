# Pet Kingdoms — AI Handoff

> Last updated: 2026-11-21  
> Purpose: resume work in a fresh chat without relying on conversation memory.

## Repository

- GitHub: https://github.com/DoctorStrangeSH/Pet-Kingdoms
- Default branch: main
- Repository was initially empty when first inspected on 2026-11-21.
- The first documentation baseline has been committed directly to main.

## Source of truth

Read these files first:
1. README.md
2. docs/PROJECT_SPEC.md
3. docs/ROADMAP.md
4. docs/ART_BIBLE.md
5. docs/game-systems/BUILDING_SYSTEM.md

The repository is authoritative. If a chat message conflicts with these files, stop and reconcile the decision instead of silently changing scope.

## Current verified state

- [x] README and project overview committed.
- [x] MVP specification committed.
- [x] Scoped roadmap committed.
- [x] Art direction baseline documented.
- [x] Building system design baseline documented.
- [ ] Roblox source project initialized.
- [ ] Roblox Studio place file created and verified.
- [ ] Rojo/Studio workflow explicitly confirmed by owner.
- [ ] Any production 3D assets, rigs, animations, or gameplay systems implemented.

Important: concept art generated in chat is visual reference only. It is not a production model or integrated game asset.

## Product decisions to preserve

- MVP target: 20 pets.
- Up to 3 active companions.
- Pet max level: 50.
- Five core pet stats: Health, Attack, Defense, Speed, Critical Chance.
- All six rarity tiers can reach level 50.
- Evolution is post-MVP.
- First biome: Green Valley with Meadow, Deep Forest, Crystal Creek, Ancient Grove, Wildflower Hills.
- Kingdom Bond changes the island's appearance.
- Monetization must not create pay-to-win advantages.
- Build in the approved MVP order; do not add unrelated systems before 1.0.

## Next action

Confirm the preferred authoring workflow with the owner. Recommended default: hybrid Rojo + VS Code for source-controlled Luau, Roblox Studio for world assembly, visual iteration, and playtesting. After confirmation:
1. Add default.project.json and a minimal src/ structure.
2. Add a tiny vertical slice: server-owned player profile/bootstrap plus one testable resource node interaction.
3. Add automated checks that can run in CI.
4. Validate the place in Roblox Studio; do not claim Studio verification until it has actually happened.
5. Update ROADMAP and this handoff after each verified milestone.

## Working rules

- Make real repository changes; never present design concepts as implemented features.
- Update ROADMAP with DONE / NOT DONE and verification notes.
- Prefer small, testable, modular changes.
- Do not store live Roblox Instances in DataStores; persist validated compact data.
- Server validates economy, ownership, placement, rewards, and progression.
- Keep PC and mobile in scope from the start.
