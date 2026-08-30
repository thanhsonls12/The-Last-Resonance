"""Build a lightweight rigid-part armature for Kiro-K7 and export animations.

The source character is intentionally made from separate hard-surface meshes, so
rigid bone parenting is a better fit than forcing a skinned modifier onto every
part. The resulting armature is still a normal glTF armature and can be driven by
Godot's AnimationPlayer.

This is an optional standalone export pipeline; the current runtime loads the
animation-library GLB under ``assets/models/animations/Kiro_K7/``.

Run from the project root with Blender:

    blender --background source.blend --python tools/rig_kiro.py -- \
        assets/models/characters/Kiro_K7_rigged.blend \
        assets/models/characters/Kiro_K7.glb
"""

import math
import os
import sys

import bpy
from mathutils import Euler, Vector


def cli_paths():
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	project_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
	out_blend = args[0] if len(args) > 0 else os.path.join(project_dir, "assets", "models", "characters", "Kiro_K7_rigged.blend")
	out_glb = args[1] if len(args) > 1 else os.path.join(project_dir, "assets", "models", "characters", "Kiro_K7.glb")
	return os.path.abspath(out_blend), os.path.abspath(out_glb)


def make_bone(armature_data, bones, name, head, tail, parent=None, connected=False):
	bone = armature_data.edit_bones.new(name)
	bone.head = Vector(head)
	bone.tail = Vector(tail)
	if parent:
		bone.parent = bones[parent]
		bone.use_connect = connected
	bones[name] = bone
	return bone


def create_armature():
	for obj in list(bpy.data.objects):
		if obj.type == "ARMATURE" and obj.name.startswith("Kiro_"):
			bpy.data.objects.remove(obj, do_unlink=True)

	armature_data = bpy.data.armatures.new("Kiro_K7_Armature")
	armature = bpy.data.objects.new("Kiro_K7_Armature", armature_data)
	bpy.context.collection.objects.link(armature)
	armature.show_in_front = True
	armature_data.display_type = "BBONE"

	bpy.context.view_layer.objects.active = armature
	armature.select_set(True)
	bpy.ops.object.mode_set(mode="EDIT")
	bones = {}
	make_bone(armature_data, bones, "root", (0, 0, 0), (0, 0, 1.08))
	make_bone(armature_data, bones, "pelvis", (0, 0, 1.08), (0, 0, 1.35), "root")
	make_bone(armature_data, bones, "torso", (0, 0, 1.35), (0, 0, 2.5), "pelvis")
	make_bone(armature_data, bones, "head", (0, 0, 2.5), (0, 0, 3.6), "torso")

	for side, x in (("l", -1.0), ("r", 1.0)):
		make_bone(armature_data, bones, f"upper_arm_{side}", (x, 0, 2.08), (x, 0, 1.69), "torso")
		make_bone(armature_data, bones, f"forearm_{side}", (x, 0, 1.36), (x, 0, 1.07), f"upper_arm_{side}")
		make_bone(armature_data, bones, f"hand_{side}", (x, 0, 0.96), (x, -0.12, 0.70), f"forearm_{side}")
		make_bone(armature_data, bones, f"thigh_{side}", (x * 0.38, 0, 1.08), (x * 0.38, 0, 0.62), "pelvis")
		make_bone(armature_data, bones, f"shin_{side}", (x * 0.38, 0, 0.52), (x * 0.38, 0, 0.27), f"thigh_{side}")
		make_bone(armature_data, bones, f"foot_{side}", (x * 0.38, 0, 0.27), (x * 0.38, -0.28, 0.18), f"shin_{side}")
	bpy.ops.object.mode_set(mode="OBJECT")
	return armature, bones


def mesh_bone_name(object_name):
	name = object_name.lower()
	if "pelvis" in name:
		return "pelvis"
	if any(token in name for token in ("torso", "chest", "backpack", "backcore", "backvent")):
		return "torso"
	if any(token in name for token in ("head", "face", "eye", "cheek", "ear", "antenna", "neck")):
		return "head"
	for side in ("l", "r"):
		if name.endswith("_" + side):
			if "shoulder" in name or "upperarm" in name:
				return f"upper_arm_{side}"
			if "elbow" in name or "forearm" in name or "hand" in name:
				return f"forearm_{side}" if "hand" not in name else f"hand_{side}"
			if "thigh" in name:
				return f"thigh_{side}"
			if "knee" in name or "shin" in name:
				return f"shin_{side}"
			if "foot" in name or "toe" in name:
				return f"foot_{side}"
	return None


def parent_meshes(armature, meshes):
	for obj in meshes:
		bone_name = mesh_bone_name(obj.name)
		if bone_name is None:
			continue
		world_matrix = obj.matrix_world.copy()
		obj.parent = armature
		obj.parent_type = "BONE"
		obj.parent_bone = bone_name
		obj.matrix_world = world_matrix


def key_pose(armature, frame, rotations=None, root_z=0.0):
	rotations = rotations or {}
	for pose_bone in armature.pose.bones:
		pose_bone.rotation_mode = "XYZ"
	armature.pose.bones["root"].location = (0, 0, root_z)
	armature.pose.bones["root"].keyframe_insert(data_path="location", frame=frame, group="root")
	for name, rotation in rotations.items():
		pose_bone = armature.pose.bones[name]
		pose_bone.rotation_euler = Euler(rotation, "XYZ")
		pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame, group=name)


def new_action(armature, name, end_frame):
	action = bpy.data.actions.new(name)
	action.use_fake_user = True
	armature.animation_data_create()
	armature.animation_data.action = action
	for pose_bone in armature.pose.bones:
		pose_bone.rotation_mode = "XYZ"
		pose_bone.rotation_euler = Euler((0, 0, 0), "XYZ")
		pose_bone.location = Vector((0, 0, 0))
	key_pose(armature, 1, {})
	action.frame_start = 1
	action.frame_end = end_frame
	return action


def build_actions(armature):
	for action in list(bpy.data.actions):
		if action.name in {"Idle", "Walk", "Push", "Victory", "Interact"}:
			bpy.data.actions.remove(action)

	idle = new_action(armature, "Idle", 48)
	for frame, bob, tilt in ((1, 0.0, -0.015), (13, 0.025, 0.015), (25, 0.0, -0.015), (37, 0.025, 0.015), (48, 0.0, -0.015)):
		key_pose(armature, frame, {"head": (0, 0, tilt)}, bob)

	walk = new_action(armature, "Walk", 24)
	for frame, swing in ((1, 0.34), (7, 0.0), (13, -0.34), (19, 0.0), (24, 0.34)):
		key_pose(
			armature,
			frame,
			{
				"thigh_l": (swing, 0, 0),
				"thigh_r": (-swing, 0, 0),
				"shin_l": (-swing * 0.28, 0, 0),
				"shin_r": (swing * 0.28, 0, 0),
				"upper_arm_l": (-swing * 0.60, 0, 0),
				"upper_arm_r": (swing * 0.60, 0, 0),
				"forearm_l": (-swing * 0.38, 0, 0),
				"forearm_r": (swing * 0.38, 0, 0),
			},
			abs(swing) * 0.02,
		)

	push = new_action(armature, "Push", 18)
	lean = math.radians(10)
	arm_forward = math.radians(18)
	for frame, amount in ((1, 0.0), (5, 1.0), (10, 1.0), (18, 0.0)):
		key_pose(
			armature,
			frame,
			{
				"torso": (lean * amount, 0, 0),
				"head": (-lean * 0.35 * amount, 0, 0),
				"upper_arm_l": (arm_forward * amount, 0, 0),
				"upper_arm_r": (arm_forward * amount, 0, 0),
				"forearm_l": (arm_forward * 0.85 * amount, 0, 0),
				"forearm_r": (arm_forward * 0.85 * amount, 0, 0),
			},
		)

	victory = new_action(armature, "Victory", 40)
	cheer = math.radians(120)
	elbow = math.radians(42)
	for frame, amount, bob in ((1, 0.0, 0.0), (10, 1.0, 0.10), (22, 0.85, 0.02), (31, 1.0, 0.10), (40, 0.95, 0.05)):
		key_pose(
			armature,
			frame,
			{
				"upper_arm_l": (-cheer * amount, 0, 0),
				"upper_arm_r": (-cheer * amount, 0, 0),
				"forearm_l": (-elbow * amount, 0, 0),
				"forearm_r": (-elbow * amount, 0, 0),
				"torso": (math.radians(-6) * amount, 0, 0),
				"head": (math.radians(-12) * amount, 0, 0),
			},
			bob,
		)

	interact = new_action(armature, "Interact", 24)
	reach = math.radians(55)
	wrist = math.radians(30)
	for frame, amount in ((1, 0.0), (8, 1.0), (15, 1.0), (24, 0.0)):
		key_pose(
			armature,
			frame,
			{
				"upper_arm_r": (-reach * amount, 0, 0),
				"forearm_r": (-wrist * amount, 0, 0),
				"torso": (math.radians(8) * amount, 0, 0),
				"head": (math.radians(-5) * amount, 0, 0),
			},
		)

	# Let the glTF exporter emit each action as a named animation clip.
	armature.animation_data.action = None
	return [idle, walk, push, victory, interact]


def select_character(armature, meshes):
	bpy.ops.object.select_all(action="DESELECT")
	armature.select_set(True)
	for mesh in meshes:
		mesh.select_set(True)
	bpy.context.view_layer.objects.active = armature


def main():
	out_blend, out_glb = cli_paths()
	os.makedirs(os.path.dirname(out_blend), exist_ok=True)
	os.makedirs(os.path.dirname(out_glb), exist_ok=True)

	meshes = [
		obj for obj in bpy.context.scene.objects
		if obj.type == "MESH" and obj.name.startswith("Kiro_")
	]
	if not meshes:
		raise RuntimeError("No Kiro_ mesh objects found in the source blend")
	armature, _ = create_armature()
	parent_meshes(armature, meshes)
	actions = build_actions(armature)
	select_character(armature, meshes)

	bpy.ops.wm.save_as_mainfile(filepath=out_blend)
	bpy.ops.export_scene.gltf(
		filepath=out_glb,
		export_format="GLB",
		use_selection=True,
		export_apply=True,
		export_animations=True,
		export_animation_mode="ACTIONS",
		export_force_sampling=True,
		export_frame_step=1,
	)
	print("RIGGED_BLEND", out_blend)
	print("ANIMATIONS", ",".join(action.name for action in actions))
	print("RIGGED_GLB", out_glb)


if __name__ == "__main__":
	main()
