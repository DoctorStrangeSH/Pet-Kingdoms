# Bunny model import notes

- Units: Roblox studs.
- Up axis: +Y; forward: -Z.
- Ground plane: Y=0.
- Main body is one smooth triangulated implicit surface; facial and woodland accent meshes are separate named OBJ objects.
- Import through Studio 3D Importer with `bunny.mtl` adjacent to `bunny.obj`.
- `bunny.obj` is geometry only; it does not embed the rig or animations.
- The separate `build_bunny_rig.py` pipeline generates a first-pass 10-bone Blender rig and Idle/Walk/Hop/Happy clips in `.blend`/`.fbx` outputs. These outputs are structurally CI-validated but have not passed visual or Roblox Studio acceptance.
