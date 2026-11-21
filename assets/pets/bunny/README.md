# Bunny — original Pet Kingdoms mesh v1

**Status: original mesh and Blender rig/animation outputs built and CI-validated; Roblox Studio import, visual review, and runtime integration pending.**

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

This is a first custom mesh draft, not yet accepted production art. The source OBJ is static; the separate generated Blender/FBX outputs contain a first-pass 10-bone rig, skin weights, and four clips. None have yet been visually approved or imported into Roblox Studio.

## Rigging pipeline

A reproducible Blender script is available at `build_bunny_rig.py`; see `RIG_PIPELINE.md`. It defines a first-pass 10-bone rig and Idle/Walk/Hop/Happy actions. GitHub Actions now installs Blender, executes the build, validates the generated .blend/.fbx, and uploads both as a 30-day workflow artifact. The full Blender 4.2.0 build passes in GitHub Actions. The validator reopens the .blend, imports the .fbx into a clean scene, and verifies the 10-bone armature, 13 mesh objects, and real keyed motion for each of the four required clips (Idle/Walk/Hop/Happy). Latest successful round-trip run: https://github.com/DoctorStrangeSH/Pet-Kingdoms/actions/runs/44915841762. This is structural validation only, not visual approval or Roblox Studio import approval.

## Automated source validation

GitHub Actions workflow `Pet asset source validation` now runs `validate_bunny_source.py` and Python syntax compilation for the Blender script on relevant changes. Latest run passed: [run #1](https://github.com/DoctorStrangeSH/Pet-Kingdoms/actions/runs/44912586099). This validates OBJ/MTL structure and Python syntax only; it does not execute Blender or approve the model visually.

## Required next steps
1. Import bunny_rigged.fbx using Roblox Studio 3D Importer; keep the .blend as editable source and OBJ/MTL as geometry/material source.
2. Run tools/roblox/InspectImportedBunny.lua from Studio Command Bar with the imported Model selected; save the full Output report.
3. Check orientation, pivot, scale, texture/material fidelity, silhouette, and bone hierarchy.
4. Scrub all four imported animations and inspect skin deformation around ears, head, torso, and legs.
5. Fix import/deformation issues before publishing anything.
6. Publish the approved model and each animation to this experience; record IDs and permissions.
7. Implement and test the runtime animation loader before setting catalog IDs or replacing the procedural prototype.
8. Inspect it in Green Valley under actual gameplay camera/lighting. Only then consider production approval.

Do not restore the rejected Creator Store asset ID.
