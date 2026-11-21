# Bunny — first real mesh candidate

Status: **INTEGRATED AS A CREATOR STORE RUNTIME DEPENDENCY; STUDIO VISUAL REVIEW PENDING**

## Source

- Creator Store asset: [Bunny](https://create.roblox.com/store/asset/92070521355583/Bunny)
- Asset ID: `92070521355583`
- Creator shown on listing: `@letscreate19`
- Listing technical metadata: 3,050 triangles, 4,713 vertices, 5 MeshParts, 1 Decal.
- Listing description says the model was made with Blender and Clip Studio Paint.
- Store listing offers the model for free.

## Runtime integration

`PetAssetCatalog.lua` records the source and technical metadata. `PetAssetLoader.lua` loads the public free model through Roblox `AssetService:LoadAssetAsync`, removes all executable descendants, sets safe non-colliding mesh parts, and returns a model for the existing companion-follow system.

This is an imported mesh dependency, not a procedural Part-based replacement. The current source listing does not establish that the model is rigged, so the first integration treats it as a static mesh companion that follows the player. Custom rigging and pet-specific animation are separate follow-up work.

## Required Studio setting

Enable **Game Settings / Experience Settings → Security → Allow Loading Third Party Assets**. Roblox documents that `AssetService:LoadAssetAsync` can load public free Creator Store assets only when this setting is enabled. The setting is disabled by default.

## Acceptance gates

- [ ] Enable third-party asset loading in the test experience.
- [ ] Run `PetAssetLoaderTests.server.lua` in Roblox Studio.
- [ ] Inspect the model from front, side, and back in Studio.
- [ ] Check scale, forward direction, pivot, materials, textures, and visual quality in the actual game camera.
- [ ] Verify the model appears beside the player and follows correctly.
- [ ] Confirm no scripts/modules from the third-party asset remain.
- [ ] Decide whether to keep, customize, or replace this candidate before marking the Bunny production art DONE.

## Provenance policy

Do not redistribute the source model file outside the Roblox Creator Store. Keep the asset ID, creator, source URL, and license/access notes in this file. If the asset owner changes permissions or removes the asset, replace it with a project-owned model.
