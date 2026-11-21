# Bunny — Roblox Studio import and acceptance checklist

> Manual Studio gate. GitHub CI cannot import assets into the user's Roblox experience or approve their appearance.

## Before importing
- [ ] Download the pet-kingdoms-bunny-rigged artifact from https://github.com/DoctorStrangeSH/Pet-Kingdoms/actions/runs/44915841762
- [ ] Extract bunny_rigged.fbx and keep bunny_rigged.blend as the editable source.
- [ ] Open the target Pet Kingdoms place in Roblox Studio and use the 3D Importer on the FBX.

## Structural inspection
1. Select the imported top-level Model in Explorer.
2. Open View → Command Bar.
3. Paste/run tools/roblox/InspectImportedBunny.lua from this repository.
4. Save the Output report and attach it to the next development discussion.

Expected structural signals:
- MeshParts are present.
- Bone instances are present (the FBX must remain a skinned mesh).
- No unexpected scripts/modules were imported.
- Record bounding box, pivot, mesh count, and bone hierarchy.
- AnimationController/Animator may not be created by FBX import; their absence is not a failed mesh import. Runtime setup must add them deliberately.

## Visual and animation acceptance
- [ ] Overall silhouette matches the Green Valley woodland explorer direction.
- [ ] Warm ivory coat, expressive dark eyes, rose inner ears, sage leaf mantle, and acorn charm are present and legible.
- [ ] Materials/textures survive import; no missing textures, flat grey surfaces, or unexpected material substitutions.
- [ ] Scale and pivot are appropriate beside the player avatar.
- [ ] Skin deformation is clean at head/neck, ears, torso, and all four legs.
- [ ] Idle, Walk, Hop, and Happy each play and loop/hold as intended.
- [ ] No mesh separation, clipping, severe twisting, or foot sliding.
- [ ] Inspect at actual Green Valley gameplay camera distance and lighting, including a mobile-sized viewport.

## Publish and runtime integration — only after approval
- [ ] Publish the model to the Pet Kingdoms experience and record the model asset ID.
- [ ] Publish each animation to the same experience and record animation IDs/permissions.
- [ ] Add a Roblox AnimationController + Animator to the loaded model in runtime code.
- [ ] Implement an external/skinned-pet animation controller that loads the four animation IDs; do not route a skinned mesh through the current Motor6D procedural controller.
- [ ] Revisit anchoring: the current generic loader anchors all BaseParts. Verify that this does not interfere with the chosen Bone/Animator animation setup before reuse.
- [ ] Add catalog IDs only after published assets and permissions are verified.
- [ ] Run loader, animation, follow, respawn, and cleanup tests in Studio.

## Current known runtime gap
PetAssetLoader.create("bunny") returns ASSET_NOT_CONFIGURED while PetAssetCatalog.bunny.assetId is nil. CompanionFollowController skips animation setup for IsExternalMeshPet == true; a dedicated AnimationController/Animator path is still required. The procedural Motor6D Bunny is a separate prototype and is not the Blender mesh.
