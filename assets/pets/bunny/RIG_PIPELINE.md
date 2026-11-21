# Bunny rig build pipeline

Run the project-owned Blender pipeline from Blender 4.2+:

```bash
blender --background --python assets/pets/bunny/build_bunny_rig.py
```

The script imports `bunny.obj` + `bunny.mtl`, smooths shading, creates a first-pass 10-bone armature, assigns spatial skin weights to the main body, attaches tiny face/leaf/charm meshes to semantic bones, creates Idle/Walk/Hop/Happy actions, saves `bunny_rigged.blend`, and exports `bunny_rigged.fbx`.

## Important status
This is an automated technical rig draft, not a visually approved character. Review the weights around shoulders/hips/ears and scrub every action in Blender. The OBJ's main sculpted body is a single fused mesh; accessories are separate objects. Do not publish the FBX to Roblox until the deformation and animation review passes.

## Roblox import
1. Run the script in Blender 4.2+.
2. Open the resulting `.blend` and inspect the rig and all four actions.
3. Export/import the FBX using Roblox Studio's 3D Importer.
4. Publish the model and animations to the same experience; record their IDs and permissions.
5. Update the runtime catalog only after the imported rig is verified.
6. Run the pet loader and companion animation tests in Studio.

The source OBJ/MTL remain the editable geometry source. The Blender script is the reproducible rig/export source.
