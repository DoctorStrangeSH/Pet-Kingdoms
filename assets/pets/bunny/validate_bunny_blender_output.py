#!/usr/bin/env python3
"""Run inside Blender after build_bunny_rig.py to verify generated outputs."""
from pathlib import Path
import bpy
import sys

ROOT = Path(__file__).resolve().parent
BLEND_PATH = ROOT / "bunny_rigged.blend"
FBX_PATH = ROOT / "bunny_rigged.fbx"

if not BLEND_PATH.is_file() or BLEND_PATH.stat().st_size < 10_000:
    raise RuntimeError("Missing or unexpectedly small bunny_rigged.blend")
if not FBX_PATH.is_file() or FBX_PATH.stat().st_size < 10_000:
    raise RuntimeError("Missing or unexpectedly small bunny_rigged.fbx")

bpy.ops.wm.open_mainfile(filepath=str(BLEND_PATH))

armatures = [obj for obj in bpy.data.objects if obj.type == "ARMATURE" and obj.name == "Bunny_Rig"]
if len(armatures) != 1:
    raise RuntimeError(f"Expected exactly one Bunny_Rig armature, found {len(armatures)}")
armature = armatures[0]
expected_bones = {
    "Root", "Body", "Head", "Ear.L", "Ear.R",
    "FrontLeg.L", "FrontLeg.R", "BackLeg.L", "BackLeg.R", "Tail",
}
actual_bones = {bone.name for bone in armature.data.bones}
if actual_bones != expected_bones:
    raise RuntimeError(f"Rig bone mismatch. Missing={sorted(expected_bones-actual_bones)} extra={sorted(actual_bones-expected_bones)}")

expected_actions = {"Bunny_Idle", "Bunny_Walk", "Bunny_Hop", "Bunny_Happy"}
actual_actions = {action.name for action in bpy.data.actions}
if not expected_actions.issubset(actual_actions):
    raise RuntimeError(f"Missing animation actions: {sorted(expected_actions-actual_actions)}")

meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
if len(meshes) < 10:
    raise RuntimeError(f"Expected imported body and accessory meshes, found {len(meshes)}")

body = next((obj for obj in meshes if "SculptedBody" in obj.name), None)
if body is None:
    raise RuntimeError("Could not locate fused Bunny_SculptedBody mesh")
if not any(mod.type == "ARMATURE" and mod.object == armature for mod in body.modifiers):
    raise RuntimeError("Main body is missing its Bunny_Skin armature modifier")
if not body.vertex_groups:
    raise RuntimeError("Main body has no skin vertex groups")

for action_name in expected_actions:
    action = bpy.data.actions[action_name]
    if not action.fcurves:
        raise RuntimeError(f"Animation action has no curves: {action_name}")

blend_action_count = len(expected_actions)

# Validate the actual interchange file, not just its byte size. Import the FBX
# into a clean scene and check that the armature, mesh geometry, and animation
# take survive the export/import round trip.
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.actions, bpy.data.meshes, bpy.data.armatures):
    for block in list(datablocks):
        if block.users == 0:
            datablocks.remove(block)

try:
    bpy.ops.import_scene.fbx(filepath=str(FBX_PATH), use_anim=True)
except Exception as exc:
    raise RuntimeError(f"Could not re-import generated Bunny FBX: {exc}") from exc

fbx_armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
if len(fbx_armatures) != 1:
    raise RuntimeError(f"FBX round-trip expected one armature, found {len(fbx_armatures)}")
fbx_armature = fbx_armatures[0]
fbx_bones = {bone.name for bone in fbx_armature.data.bones}
if fbx_bones != expected_bones:
    raise RuntimeError(
        f"FBX bone mismatch. Missing={sorted(expected_bones-fbx_bones)} "
        f"extra={sorted(fbx_bones-expected_bones)}"
    )

fbx_meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
if len(fbx_meshes) < 10:
    raise RuntimeError(f"FBX round-trip expected at least 10 mesh objects, found {len(fbx_meshes)}")

fbx_actions = [
    action for action in bpy.data.actions
    if action.fcurves and any(curve.keyframe_points for curve in action.fcurves)
]

# FBX can create both plain action names and armature-prefixed take names.
# Resolve exactly the four intended clips; do not count importer duplicates.
resolved_actions = {}
for expected_name in expected_actions:
    candidates = [
        action for action in fbx_actions
        if action.name == expected_name or action.name.endswith("|" + expected_name)
    ]
    if not candidates:
        raise RuntimeError(f"FBX round-trip is missing required clip: {expected_name}")
    resolved_actions[expected_name] = candidates[0]

# Require actual keyed motion rather than empty action datablocks.
for expected_name, action in resolved_actions.items():
    keyed_points = [
        point
        for curve in action.fcurves
        for point in curve.keyframe_points
    ]
    if len(keyed_points) < 2:
        raise RuntimeError(f"FBX action has fewer than two keyframes: {expected_name}")
    values = [point.co.y for point in keyed_points]
    if max(values) - min(values) < 1e-5:
        raise RuntimeError(f"FBX action has no measurable animated value change: {expected_name}")

print("[PetKingdoms] PASS: Blender source and FBX round-trip validation")
print(f"  fbx_required_clips={sorted(resolved_actions)}")
print(f"  fbx_imported_action_datablocks={len(fbx_actions)}")
print(f"  blend_armature_bones={len(actual_bones)} blend_mesh_objects={len(meshes)} blend_actions={blend_action_count}")
print(f"  fbx_armature_bones={len(fbx_bones)} fbx_mesh_objects={len(fbx_meshes)} fbx_animated_actions={len(fbx_actions)}")
print(f"  blend_bytes={BLEND_PATH.stat().st_size} fbx_bytes={FBX_PATH.stat().st_size}")
