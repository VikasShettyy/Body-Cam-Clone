@tool
extends EditorScript


# ============================================================
# SETTINGS
# ============================================================

const SCALE_FACTOR := 0.1


# Ragdoll uses collision layer 4.
# It does NOT collide with itself.
const RAGDOLL_LAYER := 4


# ============================================================
# MAIN BONES
# ============================================================

const MAIN_BONE_KEYWORDS := [
	"rootJoint",

	"Pelvis",

	"Spine",
	"Spine1",
	"Spine2",
	"Spine3",
	"Chest",

	"Neck",
	"Head",

	"L_UpperArm",
	"L_Forearm",
	"L_ForeArm",
	"L_Hand",

	"R_UpperArm",
	"R_Forearm",
	"R_ForeArm",
	"R_Hand",

	"L_Thigh",
	"L_Calf",
	"L_Foot",

	"R_Thigh",
	"R_Calf",
	"R_Foot"
]


# ============================================================
# RUN
# ============================================================

func _run() -> void:

	var selection := get_editor_interface().get_selection()
	var selected_nodes := selection.get_selected_nodes()

	if selected_nodes.is_empty():
		print("ERROR: Select PhysicalBoneSimulator3D first.")
		return

	var root: Node = selected_nodes[0]

	if not root is PhysicalBoneSimulator3D:
		print("ERROR: Selected node is not PhysicalBoneSimulator3D.")
		return

	var simulator := root as PhysicalBoneSimulator3D


	print("")
	print("================================")
	print("RAGDOLL CLEANUP")
	print("================================")


	var kept := 0
	var removed := 0
	var scaled := 0


	var physical_bones := simulator.find_children(
		"*",
		"PhysicalBone3D",
		true,
		false
	)


	print(
		"Generated bones: ",
		physical_bones.size()
	)


	# ========================================================
	# REMOVE UNWANTED BONES
	# ========================================================

	for node in physical_bones:

		var bone := node as PhysicalBone3D

		if bone == null:
			continue

		var bone_name := str(bone.bone_name)


		if not is_main_bone(bone_name):

			print("Removing: ", bone_name)

			bone.queue_free()

			removed += 1

			continue


		print("Keeping: ", bone_name)

		kept += 1


		# ====================================================
		# PHYSICAL SETTINGS
		# ====================================================

		bone.can_sleep = true

		bone.linear_damp = 2.0
		bone.angular_damp = 5.0

		bone.gravity_scale = 1.0

		bone.bounce = 0.0
		bone.friction = 1.0

		# ====================================================
		# COLLISION SHAPES
		# ====================================================

		var collision_nodes := bone.find_children(
			"*",
			"CollisionShape3D",
			true,
			false
		)


		for collision_node in collision_nodes:

			var collision := collision_node as CollisionShape3D

			if collision == null:
				continue

			if collision.shape == null:
				continue


			var shape: Shape3D = collision.shape


			if shape is CapsuleShape3D:

				var capsule := shape as CapsuleShape3D

				capsule.radius *= SCALE_FACTOR
				capsule.height *= SCALE_FACTOR

				scaled += 1


			elif shape is SphereShape3D:

				var sphere := shape as SphereShape3D

				sphere.radius *= SCALE_FACTOR

				scaled += 1


			elif shape is BoxShape3D:

				var box := shape as BoxShape3D

				box.size *= SCALE_FACTOR

				scaled += 1


	print("")
	print("================================")
	print("RAGDOLL CLEANUP COMPLETE")
	print("================================")

	print("Kept: ", kept)
	print("Removed: ", removed)
	print("Scaled shapes: ", scaled)

	print("================================")


# ============================================================
# MAIN BONE CHECK
# ============================================================

func is_main_bone(bone_name: String) -> bool:

	var lower_name := bone_name.to_lower()


	# --------------------------------------------------------
	# Remove unwanted categories
	# --------------------------------------------------------

	if "weapon" in lower_name:
		return false

	if "finger" in lower_name:
		return false

	if "thumb" in lower_name:
		return false

	if "toe" in lower_name:
		return false

	if "eye" in lower_name:
		return false

	if "face" in lower_name:
		return false

	if "facial" in lower_name:
		return false

	if "ik" in lower_name:
		return false

	if "helper" in lower_name:
		return false

	if "twist" in lower_name:
		return false

	if "roll" in lower_name:
		return false


	# --------------------------------------------------------
	# Keep main bones
	# --------------------------------------------------------

	for keyword in MAIN_BONE_KEYWORDS:

		if keyword.to_lower() in lower_name:
			return true


	return false
