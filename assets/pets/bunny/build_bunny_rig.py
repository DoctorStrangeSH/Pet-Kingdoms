# Pet Kingdoms — Bunny Blender rig/export pipeline
# Run in Blender 4.2+:
# blender --background --python assets/pets/bunny/build_bunny_rig.py
#
# Input: bunny.obj + bunny.mtl beside this script.
# Output: bunny_rigged.blend + bunny_rigged.fbx
#
# This script creates a first-pass deformation rig and four baked-ready actions.
# It is a technical rig draft; inspect weights and motion in Blender before Roblox import.

from pathlib import Path
import bpy
import math
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
OBJ_PATH = ROOT / "bunny.obj"
BLEND_PATH = ROOT / "bunny_rigged.blend"
FBX_PATH = ROOT / "bunny_rigged.fbx"

if not OBJ_PATH.exists():
    raise FileNotFoundError(f"Missing source mesh: {OBJ_PATH}")

# Reset scene.
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.actions):
    for block in list(datablocks):
        if block.users == 0:
            datablocks.remove(block)

# Import project-owned OBJ and its adjacent MTL.
bpy.ops.wm.obj_import(
    filepath=str(OBJ_PATH),
    forward_axis="NEGATIVE_Z",
    up_axis="Y",
    use_split_objects=True,
    use_split_groups=True,
    validate_meshes=True,
)
mesh_objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
if not mesh_objects:
    raise RuntimeError("OBJ importer produced no mesh objects.")

# Smooth shading and normalize transforms without changing world-space shape.
for obj in mesh_objects:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.select_set(False)

# Main fused body mesh receives skin weights. Small accessory meshes are attached
# rigidly to their nearest semantic bone to keep eyes/leaf/charm from stretching.
body = next((o for o in mesh_objects if "SculptedBody" in o.name), mesh_objects[0])

arm_data = bpy.data.armatures.new("Bunny_Armature")
arm = bpy.data.objects.new("Bunny_Rig", arm_data)
bpy.context.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
arm.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")

bone_defs = {
    "Root": ((0, 0.0, 0.0), (0, 0.35, 0.0), None),
    "Body": ((0, 0.35, 0.0), (0, 0.88, 0.0), "Root"),
    "Head": ((0, 0.88, -0.08), (0, 1.28, -0.12), "Body"),
    "Ear.L": ((-0.22, 1.28, 0.0), (-0.22, 2.08, 0.0), "Head"),
    "Ear.R": ((0.22, 1.28, 0.0), (0.22, 2.08, 0.0), "Head"),
    "FrontLeg.L": ((-0.25, 0.38, -0.18), (-0.25, 0.12, -0.18), "Body"),
    "FrontLeg.R": ((0.25, 0.38, -0.18), (0.25, 0.12, -0.18), "Body"),
    "BackLeg.L": ((-0.27, 0.38, 0.18), (-0.27, 0.10, 0.18), "Body"),
    "BackLeg.R": ((0.27, 0.38, 0.18), (0.27, 0.10, 0.18), "Body"),
    "Tail": ((0, 0.48, 0.36), (0, 0.62, 0.50), "Body"),
}
for name, (head, tail, parent_name) in bone_defs.items():
    bone = arm_data.edit_bones.new(name)
    bone.head = Vector(head)
    bone.tail = Vector(tail)
    if parent_name:
        bone.parent = arm_data.edit_bones[parent_name]
        bone.use_connect = False

bpy.ops.object.mode_set(mode="OBJECT")
arm.show_in_front = True
arm.data.display_type = "OCTAHEDRAL"

# Smooth spatial weights for the main body. Each vertex gets a small set of
# normalized influences; the head and limbs blend into the torso.
groups = {name: body.vertex_groups.new(name=name) for name in bone_defs}
def gaussian(point, center, spread):
    d = (point - Vector(center)).length
    return math.exp(-(d * d) / (2.0 * spread * spread))

for vertex in body.data.vertices:
    p = vertex.co
    influences = {
        "Body": gaussian(p, (0, 0.52, 0.02), 0.48),
        "Head": gaussian(p, (0, 1.12, -0.12), 0.34),
        "FrontLeg.L": gaussian(p, (-0.25, 0.20, -0.17), 0.23),
        "FrontLeg.R": gaussian(p, (0.25, 0.20, -0.17), 0.23),
        "BackLeg.L": gaussian(p, (-0.27, 0.18, 0.18), 0.23),
        "BackLeg.R": gaussian(p, (0.27, 0.18, 0.18), 0.23),
        "Tail": gaussian(p, (0, 0.42, 0.39), 0.19),
    }
    total = sum(influences.values()) or 1.0
    for name, weight in influences.items():
        normalized = weight / total
        if normalized > 0.025:
            groups[name].add([vertex.index], normalized, "REPLACE")

modifier = body.modifiers.new("Bunny_Skin", "ARMATURE")
modifier.object = arm
modifier.use_vertex_groups = True
body.parent = arm

# Attach each accessory mesh to its semantic bone. Rigid parenting is intentional
# for tiny face details and the leaf mantle/acorn; no accidental body deformation.
def accessory_bone(obj):
    name = obj.name.lower()
    if "earinner_l" in name:
        return "Ear.L"
    if "earinner_r" in name:
        return "Ear.R"
    if "eye" in name or "nose" in name:
        return "Head"
    if "leaf" in name or "belly" in name or "acorn" in name:
        return "Body"
    return "Head"

for obj in mesh_objects:
    if obj == body:
        continue
    bone_name = accessory_bone(obj)
    obj.parent = arm
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name

# Build a compact first animation set. All actions use a 24 fps timeline.
bpy.context.scene.render.fps = 24
pose_bones = arm.pose.bones
for pose_bone in pose_bones:
    pose_bone.rotation_mode = "XYZ"

def set_pose(frame, rotations, location=None):
    bpy.context.scene.frame_set(frame)
    for name, values in rotations.items():
        pb = pose_bones[name]
        pb.rotation_euler = values
        pb.keyframe_insert(data_path="rotation_euler", frame=frame, group=name)
    if location is not None:
        root = pose_bones["Root"]
        root.location = location
        root.keyframe_insert(data_path="location", frame=frame, group="Root")

def make_action(name, frames, loop=True):
    action = bpy.data.actions.new(name)
    arm.animation_data_create()
    arm.animation_data.action = action
    for frame, rotations, location in frames:
        set_pose(frame, rotations, location)
    action["pet_kingdoms_loop"] = loop
    action["pet_kingdoms_fps"] = 24
    return action

zero = (0.0, 0.0, 0.0)
idle_frames = [
    (1, {"Body": zero, "Head": zero, "Ear.L": zero, "Ear.R": zero}, (0, 0, 0)),
    (12, {"Body": (0.025, 0, 0), "Head": (0, 0.035, 0), "Ear.L": (0.04, 0, 0), "Ear.R": (-0.04, 0, 0)}, (0, 0.025, 0)),
    (24, {"Body": zero, "Head": zero, "Ear.L": zero, "Ear.R": zero}, (0, 0, 0)),
]
walk_frames = [
    (1, {"Body": (0.03, 0, 0), "FrontLeg.L": (0.42, 0, 0), "FrontLeg.R": (-0.42, 0, 0), "BackLeg.L": (-0.48, 0, 0), "BackLeg.R": (0.48, 0, 0), "Ear.L": (0.10, 0, 0), "Ear.R": (-0.10, 0, 0)}, (0, 0, 0)),
    (7, {"Body": (-0.03, 0, 0), "FrontLeg.L": (-0.42, 0, 0), "FrontLeg.R": (0.42, 0, 0), "BackLeg.L": (0.48, 0, 0), "BackLeg.R": (-0.48, 0, 0), "Ear.L": (-0.10, 0, 0), "Ear.R": (0.10, 0, 0)}, (0, 0, 0.015)),
    (13, {"Body": (0.03, 0, 0), "FrontLeg.L": (0.42, 0, 0), "FrontLeg.R": (-0.42, 0, 0), "BackLeg.L": (-0.48, 0, 0), "BackLeg.R": (0.48, 0, 0), "Ear.L": (0.10, 0, 0), "Ear.R": (-0.10, 0, 0)}, (0, 0, 0)),
]
hop_frames = [
    (1, {"Body": (0.12, 0, 0), "FrontLeg.L": (-0.35, 0, 0), "FrontLeg.R": (-0.35, 0, 0), "BackLeg.L": (0.35, 0, 0), "BackLeg.R": (0.35, 0, 0), "Ear.L": (-0.18, 0, 0), "Ear.R": (-0.18, 0, 0)}, (0, 0, 0)),
    (6, {"Body": (-0.10, 0, 0), "FrontLeg.L": (0.30, 0, 0), "FrontLeg.R": (0.30, 0, 0), "BackLeg.L": (-0.25, 0, 0), "BackLeg.R": (-0.25, 0, 0), "Ear.L": (0.24, 0, 0), "Ear.R": (0.24, 0, 0)}, (0, 0.22, 0)),
    (12, {"Body": zero, "FrontLeg.L": zero, "FrontLeg.R": zero, "BackLeg.L": zero, "BackLeg.R": zero, "Ear.L": zero, "Ear.R": zero}, (0, 0, 0)),
]
happy_frames = [
    (1, {"Head": (0, -0.10, 0), "Ear.L": (0.18, 0, 0), "Ear.R": (-0.18, 0, 0), "Body": zero}, (0, 0, 0)),
    (8, {"Head": (0, 0.10, 0), "Ear.L": (-0.18, 0, 0), "Ear.R": (0.18, 0, 0), "Body": (0.05, 0, 0)}, (0, 0.12, 0)),
    (16, {"Head": (0, -0.10, 0), "Ear.L": (0.18, 0, 0), "Ear.R": (-0.18, 0, 0), "Body": zero}, (0, 0, 0)),
]

actions = [
    make_action("Bunny_Idle", idle_frames, True),
    make_action("Bunny_Walk", walk_frames, True),
    make_action("Bunny_Hop", hop_frames, False),
    make_action("Bunny_Happy", happy_frames, False),
]

# Make the first action active for preview; save editable Blender source.
arm.animation_data.action = actions[0]
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = 24
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
for obj in mesh_objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = arm

bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))

# Export armature and all meshes; export all actions for Roblox animation processing.
bpy.ops.export_scene.fbx(
    filepath=str(FBX_PATH),
    use_selection=True,
    object_types={"ARMATURE", "MESH"},
    add_leaf_bones=False,
    apply_scale_options="FBX_SCALE_ALL",
    bake_anim=True,
    bake_anim_use_all_actions=True,
    bake_anim_simplify_factor=0.0,
    axis_forward="-Z",
    axis_up="Y",
    path_mode="COPY",
    embed_textures=True,
)
print(f"[PetKingdoms] Saved Blender source: {BLEND_PATH}")
print(f"[PetKingdoms] Exported rigged FBX: {FBX_PATH}")
print(f"[PetKingdoms] Mesh objects: {len(mesh_objects)}; actions: {[a.name for a in actions]}")
