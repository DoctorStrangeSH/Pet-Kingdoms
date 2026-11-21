# Bunny — original Pet Kingdoms mesh v1

**Status: original mesh source committed; Roblox Studio import, rigging, animation, and visual approval pending.**

The unsuitable Creator Store Bunny candidate (asset `92070521355583`) is rejected and must not be used in Pet Kingdoms.

## Project-owned source files
- `bunny.obj` — original triangulated 3D mesh.
- `bunny.mtl` — 9 material definitions.
- `model_notes.md` — coordinate and import notes.

## Mesh data
- 15,332 vertices.
- 30,194 triangles.
- 13 named mesh objects.
- 9 material groups.
- Units: studs; +Y up; forward -Z; ground plane Y=0.
- Main body/head/ears/cheeks/legs/tail are one smooth implicit-surface mesh; face and woodland accent meshes are separately named.
- Visual direction: Green Valley woodland explorer, warm ivory coat, large expressive dark eyes, rose inner ears, sage leaf mantle, acorn charm.

This is a first custom mesh draft, not yet accepted production art. The geometry has not yet been inspected in Roblox Studio and is currently static: no skeleton, skin weights, or animation clips.

## Rigging pipeline

A reproducible Blender script is available at `build_bunny_rig.py`; see `RIG_PIPELINE.md`. It defines a first-pass 10-bone rig and Idle/Walk/Hop/Happy actions. GitHub Actions now installs Blender, executes the build, validates the generated .blend/.fbx, and uploads both as a 30-day workflow artifact. The full Blender 4.2.0 build now passes in GitHub Actions. It generated both `bunny_rigged.blend` (3,416,204 bytes) and `bunny_rigged.fbx` (1,061,468 bytes). The validator reopened the .blend and confirmed the 10-bone armature, fused body skin modifier/vertex groups, and all four named actions with animation curves. Download the 30-day build artifact from [successful workflow run](https://github.com/DoctorStrangeSH/Pet-Kingdoms/actions/runs/44914831260). This is a technically validated build, not yet visual approval or Roblox Studio import approval.

## Automated source validation

GitHub Actions workflow `Pet asset source validation` now runs `validate_bunny_source.py` and Python syntax compilation for the Blender script on relevant changes. Latest run passed: [run #1](https://github.com/DoctorStrangeSH/Pet-Kingdoms/actions/runs/44912586099). This validates OBJ/MTL structure and Python syntax only; it does not execute Blender or approve the model visually.

## Required next steps
1. Import `bunny.obj` using Roblox Studio 3D Importer with `bunny.mtl` alongside it.
2. Check orientation, pivot, shading, material assignment, silhouette, and scale.
3. Publish the imported model to this experience and write its new asset ID into `PetAssetCatalog.lua`.
4. Add a proper rig and skin weights, then create the approved companion animation set.
5. Run the pet loader smoke test and inspect it in Green Valley under actual gameplay camera/lighting.
6. Only then consider production approval.

Do not restore the rejected Creator Store asset ID.
