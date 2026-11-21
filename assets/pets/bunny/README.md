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

A reproducible Blender script is available at `build_bunny_rig.py`; see `RIG_PIPELINE.md`. It defines a first-pass 10-bone rig and Idle/Walk/Hop/Happy actions and will generate `bunny_rigged.blend` and `bunny_rigged.fbx` when run in Blender 4.2+. The script has not yet been executed, so these output files are not present yet and no rig/animation quality is claimed.

## Required next steps
1. Import `bunny.obj` using Roblox Studio 3D Importer with `bunny.mtl` alongside it.
2. Check orientation, pivot, shading, material assignment, silhouette, and scale.
3. Publish the imported model to this experience and write its new asset ID into `PetAssetCatalog.lua`.
4. Add a proper rig and skin weights, then create the approved companion animation set.
5. Run the pet loader smoke test and inspect it in Green Valley under actual gameplay camera/lighting.
6. Only then consider production approval.

Do not restore the rejected Creator Store asset ID.
