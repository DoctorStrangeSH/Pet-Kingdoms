# Pet Art Pipeline — Bunny Rig Prototype

> Status: first procedural Bunny rig factory and Studio smoke test are committed. This is a technical blockout rig, not production pet art. Studio execution and visual approval are pending.

## Scope

The MVP requires 20 collectible pets, up to 3 active companions, and a reusable asset pipeline. The approved art direction requires expressive silhouettes, readable faces, consistent scale, contact grounding, and rigging that supports the companion animation set.

The first implementation target is Bunny, one of the named initial pet examples in PROJECT_SPEC.md.

## Current implementation

Source:
- `src/ReplicatedStorage/Shared/Pets/PetModelFactory.lua`
- `src/ReplicatedStorage/Shared/Pets/PetAnimationController.lua`
- `src/ReplicatedStorage/Shared/Pets/PetCollectionData.lua`
- `src/ServerScriptService/Services/PetCollectionService.lua`
- `src/ServerScriptService/Tests/PetCollectionDataTests.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/CompanionFollowController.lua`
- `src/StarterPlayer/StarterPlayerScripts/PetCollectionUI.client.lua`
- `src/ServerScriptService/Tests/PetModelFactoryTests.server.lua`
- `src/ServerScriptService/Tests/PetAnimationControllerTests.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/Tests/CompanionFollowControllerTests.client.lua`

## Pet collection backend prototype

`PetCollectionData.lua` defines a compact versioned collection profile with a starter Bunny, up to 100 owned pets, and up to three equipped pet IDs. It validates owner identity, species IDs, contiguous lists, unique pet IDs, and equipped ownership. The pure `setEquipped` operation rejects unowned IDs, duplicates, sparse arrays, and more than three equipped pets.

`PetCollectionService.lua` loads and initializes collections in a separate DataStore (`PetKingdoms_PetCollections_v1`). The server exposes `ReplicatedStorage/Remotes/PetCollectionRequest` with `Get` and `Equip` actions. Equip requests are validated against server-loaded ownership and use an expected revision check inside `UpdateAsync` to reject stale concurrent writes. The client can submit only pet IDs and the revision it observed; it cannot submit ownership records or species unlocks.

`PetCollectionUI.client.lua` adds a responsive Russian-language collection panel with owned-pet cards, search, a Bunny ViewportFrame preview, current team count, and equip/unequip actions. It calls the server RemoteFunction and sends the observed profile revision; server validation remains authoritative. The UI is a code-built first pass, not final art/UI polish.

This is still a collection/equip UI and persistence prototype. It does not yet spawn world models or connect equipped IDs to the follow controller. The starter Bunny is granted to every new collection by default. DataStore API access must be enabled in a published test universe for runtime verification.

The factory currently supports:
- Stable species ID: `bunny`
- Versioned rig metadata: `RigVersion = 1`
- Explicit prototype marker: `IsPetRigPrototype = true`
- Validated scale input from greater than zero through 3
- A primary `HumanoidRootPart`
- Separate body, belly, head, ears, inner ears, eyes, nose, cheeks, four legs, and tail
- 17 Motor6D joints
- `AnimationController` and `Animator`
- `FollowAttachment` and `GroundContact`
- Non-colliding, massless visual parts

## Procedural animation prototype

`PetAnimationController.lua` provides lightweight procedural poses for the current Bunny rig. It does not require uploaded animation assets. A client-side caller creates a controller for a parented Bunny model, calls `setState(state)`, and invokes `update(dt)` from its RenderStepped loop. Call `destroy()` when the pet is removed.

Supported states: `idle`, `walk`, `run`, `happy`, `curious`, `alert`, and `combat`. The controller validates the Bunny rig version and required Motor6D joints, resets its managed transforms each update, rejects unknown states, and restores identity transforms on destroy.

This is a procedural prototype, not a final animation set. The client-side `CompanionFollowController.lua` now drives a pet model toward a three-slot formation behind the local character, uses a downward raycast to find ground height, smoothly turns toward movement, and selects idle/walk/run from horizontal target speed. Create one controller per equipped pet and call `destroy()` when unequipped or the character changes. The module deliberately does not spawn pets or grant ownership; inventory/equip replication remains a separate server-authoritative feature.

The default sprint threshold is set above typical default Roblox walking speed; callers can override it in options. The client smoke test covers three formation slots and rejects slot 4. Studio execution and visual tuning remain pending.

## Rig conventions

- Pet faces forward along local negative Z.
- Root is the model PrimaryPart and is anchored so a future companion controller can move the complete rig with PivotTo without physics-driven falling.
- All visible parts are attached through Motor6D joints.
- Root attachments provide stable follow and ground reference points.
- Visual parts remain unanchored, massless, and non-colliding; Motor6D joints keep the assembly together.
- The factory returns an unparented Model; the caller owns placement, lifecycle, and cleanup.
- Species ID and rig version are stable metadata; do not infer species from the model name.

## Verification

Run `PetModelFactoryTests.server.lua`, `PetAnimationControllerTests.server.lua`, and the client `CompanionFollowControllerTests.client.lua` in Roblox Studio. They check:
- Factory success and invalid species/scale rejection
- Species and rig metadata
- PrimaryPart, AnimationController, Animator, and attachments
- Exactly 17 Motor6D joints
- Non-colliding, massless visual parts
- Scaled instance metadata
- Animation state acceptance and unknown-state rejection
- Procedural idle and walk joint motion
- Safe transform reset and idempotent controller cleanup
- Three distinct follow formation slots, controller construction, and rejection of slot 4

The three rig/follow test scripts and the pet collection data test are committed but have not been executed. No Studio visual, animation, mobile-performance, or companion-follow test has passed yet.

## Not done

- Production mesh sculpt/model, texture work, and final silhouette approval
- Facial expression variants and blink
- Uploaded/artist-authored animation clips and polished animation timing
- Server-authoritative pet ownership, inventory UI, and equipped-pet world spawn replication
- Connect equipped IDs to replicated pet world spawns and the follow controller
- Runtime lifecycle wiring for respawn, unequip, and character replacement
- Animation import IDs and playback validation
- Grounding/contact shadow treatment in the real game camera
- Mobile performance and multi-pet stress test
- Remaining 19 pet species and shared production template
- XP, stats, world spawn integration, and progression persistence

## Acceptance gate

Do not mark Bunny production-ready until the source model and rig are committed, art direction is approved, animation clips are integrated, the pet is viewed in the Green Valley gameplay camera, mobile performance is checked, and Studio verification is recorded in ASSET_TRACKER.md.
