# Pet Art Pipeline — Bunny Rig Prototype

> Status: first procedural Bunny rig factory and Studio smoke test are committed. This is a technical blockout rig, not production pet art. Studio execution and visual approval are pending.

## Scope

The MVP requires 20 collectible pets, up to 3 active companions, and a reusable asset pipeline. The approved art direction requires expressive silhouettes, readable faces, consistent scale, contact grounding, and rigging that supports the companion animation set.

The first implementation target is Bunny, one of the named initial pet examples in PROJECT_SPEC.md.

## Current implementation

Source:
- `src/ReplicatedStorage/Shared/Pets/PetModelFactory.lua`
- `src/ServerScriptService/Tests/PetModelFactoryTests.server.lua`

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

## Rig conventions

- Pet faces forward along local negative Z.
- Root is the model PrimaryPart.
- All visible parts are attached through Motor6D joints.
- Root attachments provide stable follow and ground reference points.
- The factory returns an unparented Model; the caller owns placement, lifecycle, and cleanup.
- Species ID and rig version are stable metadata; do not infer species from the model name.

## Verification

Run `PetModelFactoryTests.server.lua` in Roblox Studio. It checks:
- Factory success and invalid species/scale rejection
- Species and rig metadata
- PrimaryPart, AnimationController, Animator, and attachments
- Exactly 17 Motor6D joints
- Non-colliding, massless visual parts
- Scaled instance metadata

The test is committed but has not been executed. No Studio visual, animation, mobile-performance, or companion-follow test has passed yet.

## Not done

- Production mesh sculpt/model, texture work, and final silhouette approval
- Facial expression variants and blink
- Idle, walk/run, follow, happy, curious, alert, and combat animation clips
- Animation import IDs and playback validation
- Grounding/contact shadow treatment in the real game camera
- Mobile performance and multi-pet stress test
- Remaining 19 pet species and shared production template
- Pet inventory, equip/team, XP, stats, and persistence integration

## Acceptance gate

Do not mark Bunny production-ready until the source model and rig are committed, art direction is approved, animation clips are integrated, the pet is viewed in the Green Valley gameplay camera, mobile performance is checked, and Studio verification is recorded in ASSET_TRACKER.md.
