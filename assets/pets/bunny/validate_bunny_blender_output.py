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

print("[PetKingdoms] PASS: Blender output validation")
print(f"  armature_bones={len(actual_bones)} mesh_objects={len(meshes)} actions={sorted(expected_actions)}")
print(f"  blend_bytes={BLEND_PATH.stat().st_size} fbx_bytes={FBX_PATH.stat().st_size}")
