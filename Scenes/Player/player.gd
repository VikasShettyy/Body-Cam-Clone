extends CharacterBody3D



#object sounds while hit
@onready var metal_impact_sound: AudioStreamPlayer3D = (
	$MetalImpactSound
)
#UI Ammo
@export var ammo_label: Label 

# ============================================================
# WEAPON
# ============================================================

@onready var weapon_ads: Node3D = (
	$CameraPivot/Camera3D/WeaponHolder/WeaponADS
)

@onready var weapon: Node3D = (
	$CameraPivot/Camera3D/WeaponHolder/WeaponADS/Weapon
)

@onready var weapon_animation: AnimationPlayer = (
	weapon.find_child("AnimationPlayer", true, false)
)


# ============================================================
# WEAPON SWAY
# ============================================================

@export_category("Weapon Sway")

@export var weapon_sway_amount := 0.035
@export var weapon_sway_speed := 8.0
@export var weapon_max_sway := 0.08

var weapon_base_rotation := Vector3.ZERO
var weapon_base_position := Vector3.ZERO

var weapon_sway_target := Vector3.ZERO
var weapon_sway_input := Vector2.ZERO

@export var weapon_rotation_lag := 0.08
@export var weapon_rotation_lag_speed := 6.0

var weapon_lag_rotation := Vector3.ZERO
# ============================================================
# WEAPON RECOIL
# ============================================================

@export_category("Weapon Recoil")

@export var recoil_amount := 0.08
@export var recoil_rotation := 0.06
@export var recoil_recovery_speed := 12.0
@export var recoil_kick_speed := 18.0

var weapon_recoil_position := Vector3.ZERO
var weapon_recoil_rotation := Vector3.ZERO


# ============================================================
# WEAPON FIRE
# ============================================================

@export_category("Weapon Fire")

@export var fire_rate := 10.0

var is_firing := false
var fire_timer := 0.0


# ============================================================
# WEAPON IDLE / BREATHING
# ============================================================

@export_category("Weapon Idle")

@export var weapon_idle_amount := 0.012
@export var weapon_idle_speed := 1.8
@export var weapon_idle_smoothness := 5.0

var weapon_idle_time := 0.0


# ============================================================
# WEAPON MOVEMENT BOB
# ============================================================

@export_category("Weapon Movement Bob")

@export var weapon_bob_amount := 0.025
@export var weapon_bob_speed := 8.0

@export var weapon_sprint_bob_amount := 0.045
@export var weapon_sprint_bob_speed := 11.0

var weapon_bob_time := 0.0

var current_weapon_bob_x := 0.0

@export_category("Weapon Lean")

@export var weapon_lean_amount := 0.035
@export var weapon_tactical_lean_amount := 0.06
@export var weapon_lean_smoothness := 8.0

var current_weapon_lean := 0.0

# ============================================================
# MOVEMENT
# ============================================================

@export_category("Movement")

@export var walk_speed := 3.5
@export var sprint_speed := 6.0

@export var acceleration := 14.0
@export var friction := 18.0

@export var gravity := 18.0
@export var jump_velocity := 5.0


# ============================================================
# LOOK
# ============================================================

@export_category("Look")

@export var mouse_sensitivity := 0.0025
@export var max_look_angle := 85.0


# ============================================================
# BODYCAM MOVEMENT
# ============================================================

@export_category("Bodycam Movement")

@export var walk_bob_amount := 0.060
@export var walk_sway_amount := 0.045
@export var walk_bob_frequency := 9.0
@export var sprint_bob_frequency := 13.0
@export var camera_motion_smoothness := 12.0
@export var camera_walk_tilt := 0.035
@export var camera_run_tilt := 0.065
@export var camera_tilt_smoothness := 10.0
@export var camera_forward_amount := 0.030

#LEAN MOVEMENT
@export_category("Lean Movement")
@export var camera_lean_amount := 0.05
@export var camera_sprint_lean_amount := 0.09
@export var camera_lean_smoothness := 7.0

@export var tactical_lean_amount := 0.16
@export var tactical_sprint_lean_amount := 0.12
# ============================================================
# CAMERA INERTIA
# ============================================================

@export_category("Camera Inertia")

@export var look_smoothness := 14.0
@export var max_camera_yaw_offset := 0.06
@export var camera_yaw_inertia := 0.003
@export var yaw_return_speed := 10.0

var camera_yaw_offset := 0.0


# ============================================================
# CAMERA SHAKE
# ============================================================

@export_category("Camera Shake")

@export var landing_shake_strength := 0.025
@export var landing_shake_rotation := 0.018

# Normal jump landing
@export var jump_landing_multiplier := 0.35

# Strength of falling impact
@export var fall_shake_multiplier := 1.0

# How quickly the shake recovers
@export var shake_recovery_speed := 10.0

# Minimum downward velocity considered a fall
@export var fall_velocity_threshold := 5.0

# Maximum impact strength
@export var max_landing_impact := 2.5

var shake_position := Vector3.ZERO
var shake_rotation := Vector3.ZERO

var previous_vertical_velocity := 0.0
var was_on_floor := false


# ============================================================
# CAMERA RECOIL
# ============================================================

@export_category("Camera Recoil")

@export var camera_recoil_amount := 0.018
@export var camera_recoil_side_amount := 0.006
@export var camera_recoil_recovery := 14.0

var camera_recoil := Vector2.ZERO


# ============================================================
# WEAPON EFFECTS
# ============================================================

@onready var muzzle_flash: MeshInstance3D = (
	weapon.find_child("MuzzleFlash", true, false)
)

@onready var gunshot_sound: AudioStreamPlayer3D = (
	weapon.find_child("GunshotSound", true, false)
)

@onready var ejection_point: Marker3D = (
	weapon.find_child("EjectionPoint", true, false)
)

@onready var muzzle_light: OmniLight3D = (
	weapon.find_child("MuzzleLight", true, false)
)

@export_category("Shell Ejection")
@export var shell_scene: PackedScene
@export var shell_impulse := 1.8
@export var shell_upward_force := 0.6
@export var shell_lifetime := 4.0

# ============================================================
# MUZZLE FLASH
# ============================================================

@export_category("Muzzle Flash")

@export var muzzle_flash_duration := 0.04

var muzzle_flash_timer := 0.0

#Show Bullets

@export_category("Weapon Hit Detection")
@export var bullet_damage := 25.0
@export var bullet_range := 100.0
@export_category("Bullet Impact")
@export var bullet_impact_scene: PackedScene

#ammo section
@export_category("Weapon Ammo")
@onready var empty_click_sound: AudioStreamPlayer3D = (
	weapon.find_child("EmptyClickSound", true, false)
)
@export var magazine_size := 30
@export var reserve_ammo := 90

var current_ammo := 30
var is_reloading := false
var empty_click_played := false


#gun audio references
@onready var reload_sound: AudioStreamPlayer3D = (
	weapon.find_child("ReloadSound", true, false)
)
@export_category("Reload")
@export var reload_sound_delay := 0.55


#WEAPON ADS

@export_category("Weapon ADS")
@export var ads_speed := 10.0
@export var ads_fov := 55.0
@export var ads_distance := 0.30

var is_aiming := false
var default_camera_fov := 75.0

var weapon_ads_base_transform := Transform3D.IDENTITY
var ads_point_local_transform := Transform3D.IDENTITY

@onready var ads_point: Marker3D = (
	$CameraPivot/Camera3D/WeaponHolder/WeaponADS/Weapon/ADSPoint
)

# ============================================================
# ADS WEAPON STABILITY
# ============================================================

@export_category("ADS Weapon Stability")

@export_range(0.0, 1.0)
var ads_bob_multiplier := 0.25

@export_range(0.0, 1.0)
var ads_idle_multiplier := 0.15

@export var ads_running_forward_offset := 0.08

@export var ads_stability_smoothness := 10.0

var current_ads_forward_offset := 0.0

#PLAYER AUDIO
@export_category("Footsteps")
@onready var footstep_sound: AudioStreamPlayer3D = $FootstepSound
@export var footstep_min_speed := 0.8
@export var footstep_pitch_variation := 0.06

var last_footstep_phase := 0.0
var footstep_timer := 0.0


@export_category("Bullet Impact")
@export var bullet_force := 4.0
# ============================================================
# NODES
# ============================================================

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D


# ============================================================
# LOOK VARIABLES
# ============================================================

var look_x := 0.0
var look_y := 0.0


# ============================================================
# CAMERA BASE TRANSFORM
# ============================================================

var camera_base_position := Vector3.ZERO
var camera_bob_time := 0.0


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	default_camera_fov = camera.fov
	weapon_ads_base_transform = weapon_ads.transform

	ads_point_local_transform = (
		weapon.transform *
		ads_point.transform
	)
	# Remember original camera position.
	camera_base_position = camera_pivot.position

	# Remember original weapon position and rotation.
	weapon_base_position = weapon.position
	weapon_base_rotation = weapon.rotation

	current_ammo = magazine_size
	update_ammo_ui()
	
	
	
# Make sure muzzle flash and muzzle light start hidden.
	if muzzle_flash != null:
		muzzle_flash.visible = false

	if muzzle_light != null:
		muzzle_light.visible = false
	# Print available weapon animations.
	print("Weapon animations:")
	print(weapon_animation.get_animation_list())


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(event: InputEvent) -> void:

	# --------------------------------------------------------
	# Mouse button / automatic fire
	# --------------------------------------------------------
	
	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

			is_firing = event.pressed

		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_aiming = event.pressed	
	
	# --------------------------------------------------------
	# Mouse look
	# --------------------------------------------------------

	if event is InputEventMouseMotion:

		# Store mouse movement for weapon sway.
		weapon_sway_input = event.relative


		# ----------------------------------------------------
		# Player rotation
		# ----------------------------------------------------

		look_y -= (
			event.relative.x *
			mouse_sensitivity
		)


		# ----------------------------------------------------
		# Camera pitch target
		# ----------------------------------------------------

		look_x -= (
			event.relative.y *
			mouse_sensitivity
		)


		look_x = clamp(
			look_x,
			deg_to_rad(-max_look_angle),
			deg_to_rad(max_look_angle)
		)


		# ----------------------------------------------------
		# Player turns immediately
		# ----------------------------------------------------

		rotation.y = look_y


		# ----------------------------------------------------
		# Camera sideways inertia
		# ----------------------------------------------------

		camera_yaw_offset = clamp(
			camera_yaw_offset
			- event.relative.x * camera_yaw_inertia,
			-max_camera_yaw_offset,
			max_camera_yaw_offset
		)


	# --------------------------------------------------------
	# Escape
	# --------------------------------------------------------

	if event.is_action_pressed("ui_cancel"):

		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
		)

	#RELOAD ANIMATIon
	#=====================
	if event.is_action_pressed("reload"):
		reload_weapon()
	
	if event.is_action_pressed("inspect"):
		weapon_animation.play("INSPEC")
		await weapon_animation.animation_finished
	
	
# ============================================================
# PHYSICS
# ============================================================

func _physics_process(delta: float) -> void:

	handle_movement(delta)

	handle_gravity(delta)

	move_and_slide()


	# Weapon bob is the master movement cycle.
	handle_weapon_sway(delta)


	# Camera reads the weapon bob.
	handle_bodycam_motion(delta)


	# Footsteps read the same weapon bob.
	handle_footsteps()


	handle_camera_inertia(delta)

	handle_camera_shake(delta)

	handle_weapon_fire(delta)

	handle_muzzle_flash(delta)

	handle_weapon_ads(delta)
	
	
# ============================================================
# MOVEMENT
# ============================================================

func handle_movement(delta: float) -> void:

	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)


	var direction := Vector3(
		input_vector.x,
		0.0,
		input_vector.y
	)


	direction = (
		transform.basis *
		direction
	)

	direction.y = 0.0

	direction = direction.normalized()


	var target_speed := walk_speed
	
	#ammo section
	

	if Input.is_action_pressed("sprint"):

		target_speed = sprint_speed


	var target_velocity := direction * target_speed


	# --------------------------------------------------------
	# Accelerate
	# --------------------------------------------------------

	if direction.length() > 0.0:

		velocity.x = move_toward(
			velocity.x,
			target_velocity.x,
			acceleration * delta
		)

		velocity.z = move_toward(
			velocity.z,
			target_velocity.z,
			acceleration * delta
		)


	# --------------------------------------------------------
	# Stop smoothly
	# --------------------------------------------------------

	else:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			friction * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			friction * delta
		)


# ============================================================
# GRAVITY
# ============================================================

func handle_gravity(delta: float) -> void:

	if not is_on_floor():

		velocity.y -= gravity * delta

	else:

		if Input.is_action_just_pressed("jump"):

			velocity.y = jump_velocity

		else:

			velocity.y = 0.0


# ============================================================
# BODYCAM MOTION
# ============================================================

func handle_bodycam_motion(delta: float) -> void:

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var movement_speed: float = horizontal_velocity.length()

	var is_moving: bool = (
		movement_speed > 0.15
	)

	var is_sprinting: bool = (
		Input.is_action_pressed("sprint")
		and is_moving
	)
# ========================================================
# MOVEMENT LEAN
# ========================================================

	var horizontal_input := Input.get_axis(
		"move_left",
		"move_right"
	)

	var movement_lean_amount: float = camera_lean_amount

	if is_sprinting:
		movement_lean_amount = camera_sprint_lean_amount


	var movement_lean: float = (
		-horizontal_input * movement_lean_amount
	)


	# ========================================================
	# TACTICAL Q / E LEAN
	# ========================================================

	var tactical_lean: float = 0.0


	if Input.is_action_pressed("lean_left"):

		tactical_lean = tactical_lean_amount


	elif Input.is_action_pressed("lean_right"):

		tactical_lean = -tactical_lean_amount


	# ========================================================
	# COMBINE LEANS
	# ========================================================

	var target_lean: float = (
		movement_lean +
		tactical_lean
	)
	# ========================================================
	# BOB FREQUENCY
	# ========================================================

	if is_moving and is_on_floor():

		var bob_frequency: float = walk_bob_frequency

		if is_sprinting:
			bob_frequency = sprint_bob_frequency

		camera_bob_time += delta * bob_frequency

	else:

		camera_bob_time = move_toward(
			camera_bob_time,
			0.0,
			delta * 6.0
		)


	# ========================================================
	# MOVEMENT INTENSITY
	# ========================================================

	var speed_factor: float = clamp(
		movement_speed / sprint_speed,
		0.0,
		1.0
	)

	# Make sprinting noticeably stronger.
	if is_sprinting:
		speed_factor = min(
			speed_factor * 1.25,
			1.35
		)


	# ========================================================
	# VERTICAL BOB
	# ========================================================

	var bob_y: float = (
		abs(sin(camera_bob_time))
		* walk_bob_amount
		* speed_factor
	)
	# ========================================================
	# SIDE-TO-SIDE BODY SWAY
	# ========================================================
	var bob_x: float = 0.0


	# ========================================================
	# FORWARD / BACKWARD BODY MOVEMENT
	# ========================================================

	var bob_z: float = (
		sin(camera_bob_time)
		* camera_forward_amount
		* speed_factor
	)


	# ========================================================
	# SMALL SECONDARY MOVEMENT
	# ========================================================

	var secondary_y: float = (
		cos(camera_bob_time * 2.0)
		* walk_bob_amount
		* 0.20
		* speed_factor
	)


	bob_y += secondary_y


	# ========================================================
	# TARGET CAMERA POSITION
	# ========================================================

	var target_position: Vector3 = (
		camera_base_position
		+ Vector3(
			bob_x,
			bob_y,
			bob_z
		)
	)


	# ========================================================
	# SMOOTH CAMERA POSITION
	# ========================================================

	var position_smoothing: float = (
		1.0
		- exp(
			-camera_motion_smoothness *
			delta
		)
	)


	camera_pivot.position = (
		camera_pivot.position.lerp(
			target_position,
			position_smoothing
		)
	)


	# ========================================================
	# CAMERA TILT - EXACTLY SYNCED WITH WEAPON BOB
	# ========================================================

	var tilt_amount: float = camera_walk_tilt

	if is_sprinting:
		tilt_amount = camera_run_tilt


	var target_tilt: float = 0.0


	if is_moving and is_on_floor():

		# Weapon movement uses:
		# movement_bob.x = cos(weapon_bob_time) * bob_amount
		#
		# Therefore the camera uses the exact same phase.

		if is_sprinting:
			target_tilt = (
				-current_weapon_bob_x
				/ weapon_sprint_bob_amount
				* camera_run_tilt
			)
		else:
			target_tilt = (
				-current_weapon_bob_x
				/ weapon_bob_amount
				* camera_walk_tilt
			)


	# Smooth the tilt without changing its timing.
	var tilt_smoothing: float = (
		1.0
		- exp(
			-camera_tilt_smoothness * delta
		)
	)


# ========================================================
# COMBINE BOB TILT + MOVEMENT LEAN
# ========================================================

	var final_roll: float = (
		target_tilt +
		target_lean
	)


	camera_pivot.rotation.z = lerp(
		camera_pivot.rotation.z,
		final_roll,
		tilt_smoothing
	)
# ============================================================
# CAMERA INERTIA
# ============================================================

func handle_camera_inertia(delta: float) -> void:

	# ========================================================
	# CAMERA RECOIL RECOVERY
	# ========================================================

	var recoil_recovery: float = (
		1.0
		- exp(
			-camera_recoil_recovery *
			delta
		)
	)

	camera_recoil = camera_recoil.lerp(
		Vector2.ZERO,
		recoil_recovery
	)


	# --------------------------------------------------------
	# Smooth vertical look
	# --------------------------------------------------------

	var pitch_smoothing: float = (
		1.0
		- exp(
			-look_smoothness *
			delta
		)
	)


	camera_pivot.rotation.x = lerp(
		camera_pivot.rotation.x,
		look_x - camera_recoil.x,
		pitch_smoothing
	)


	# --------------------------------------------------------
	# Smooth horizontal camera lag
	# --------------------------------------------------------

	camera_yaw_offset = move_toward(
		camera_yaw_offset,
		0.0,
		yaw_return_speed * delta
	)


	camera_pivot.rotation.y = lerp(
		camera_pivot.rotation.y,
		camera_yaw_offset + camera_recoil.y,
		pitch_smoothing
	)


# ============================================================
# CAMERA SHAKE
# ============================================================

func handle_camera_shake(delta: float) -> void:

	# ========================================================
	# DETECT LANDING
	# ========================================================

	var just_landed: bool = (
		is_on_floor()
		and not was_on_floor
		and previous_vertical_velocity < -1.0
	)


	# ========================================================
	# LANDING IMPACT
	# ========================================================

	if just_landed:

		var fall_velocity: float = abs(
			previous_vertical_velocity
		)


		# ----------------------------------------------------
		# Determine whether this was a jump or a real fall
		# ----------------------------------------------------

		var impact_strength: float


		if fall_velocity < fall_velocity_threshold:

			# Normal jump.
			# Keep the camera shake small.

			impact_strength = (
				jump_landing_multiplier
			)

		else:

			# Falling from a height.
			# Increase shake based on falling velocity.

			impact_strength = (
				fall_velocity /
				10.0
			)

			impact_strength *= (
				fall_shake_multiplier
			)


		# ----------------------------------------------------
		# Clamp maximum shake
		# ----------------------------------------------------

		impact_strength = clamp(
			impact_strength,
			0.0,
			max_landing_impact
		)


		# ----------------------------------------------------
		# Vertical camera impact
		# ----------------------------------------------------

		shake_position.y -= (
			landing_shake_strength *
			impact_strength
		)


		# ----------------------------------------------------
		# Forward camera kick
		# ----------------------------------------------------

		shake_position.z += (
			landing_shake_strength *
			0.5 *
			impact_strength
		)


		# ----------------------------------------------------
		# Camera rotation impact
		# ----------------------------------------------------

		shake_rotation.x += (
			landing_shake_rotation *
			impact_strength
		)


		# Slight random roll for heavier impacts
		shake_rotation.z += (
			randf_range(
				-landing_shake_rotation,
				landing_shake_rotation
			)
			* 0.35
			* impact_strength
		)


	# ========================================================
	# SHAKE RECOVERY
	# ========================================================

	var recovery_amount: float = (
		1.0
		- exp(
			-shake_recovery_speed *
			delta
		)
	)


	shake_position = (
		shake_position.lerp(
			Vector3.ZERO,
			recovery_amount
		)
	)


	shake_rotation = (
		shake_rotation.lerp(
			Vector3.ZERO,
			recovery_amount
		)
	)


	# ========================================================
	# APPLY POSITION SHAKE
	# ========================================================

	camera.position = shake_position


	# ========================================================
	# APPLY ROTATION SHAKE
	# ========================================================

	camera.rotation.x = shake_rotation.x
	camera.rotation.y = shake_rotation.y
	camera.rotation.z = shake_rotation.z


	# ========================================================
	# STORE PREVIOUS STATE
	# ========================================================

	previous_vertical_velocity = velocity.y
	was_on_floor = is_on_floor()
# ============================================================
# WEAPON SWAY + RECOIL + BOB
# ============================================================

func handle_weapon_sway(delta: float) -> void:

	# ========================================================
	# RECOIL RECOVERY
	# ========================================================

	var recoil_recovery: float = (
		1.0
		- exp(
			-recoil_recovery_speed *
			delta
		)
	)

	weapon_recoil_position = weapon_recoil_position.lerp(
		Vector3.ZERO,
		recoil_recovery
	)

	weapon_recoil_rotation = weapon_recoil_rotation.lerp(
		Vector3.ZERO,
		recoil_recovery
	)


	# ========================================================
	# MOVEMENT STATE
	# ========================================================

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var movement_speed: float = horizontal_velocity.length()

	var is_moving: bool = (
		movement_speed > 0.15
	)

	var is_sprinting: bool = (
		Input.is_action_pressed("sprint")
		and is_moving
	)


	# ========================================================
	# MOUSE SWAY
	# ========================================================

	var sway_rotation: Vector3 = Vector3(
		weapon_sway_input.y
		* weapon_sway_amount,

		weapon_sway_input.x
		* weapon_sway_amount,

		-weapon_sway_input.x
		* weapon_sway_amount
		* 0.5
	)
# ========================================================
# WEAPON ROTATION LAG
# ========================================================

	var target_lag_rotation := Vector3(
		-weapon_sway_input.y * weapon_rotation_lag,
		-weapon_sway_input.x * weapon_rotation_lag,
		weapon_sway_input.x * weapon_rotation_lag * 0.5
	)

	var lag_smoothing := (
		1.0
		- exp(
			-weapon_rotation_lag_speed * delta
		)
	)

	weapon_lag_rotation = weapon_lag_rotation.lerp(
		target_lag_rotation,
		lag_smoothing
	)

	sway_rotation.x = clamp(
		sway_rotation.x,
		-weapon_max_sway,
		weapon_max_sway
	)

	sway_rotation.y = clamp(
		sway_rotation.y,
		-weapon_max_sway,
		weapon_max_sway
	)

	sway_rotation.z = clamp(
		sway_rotation.z,
		-weapon_max_sway,
		weapon_max_sway
	)


# ========================================================
# MOVEMENT BOB
# ========================================================

	var movement_bob := Vector3.ZERO

	if is_moving and is_on_floor():

		var bob_speed: float = weapon_bob_speed
		var bob_amount: float = weapon_bob_amount

		if is_sprinting:
			bob_speed = weapon_sprint_bob_speed
			bob_amount = weapon_sprint_bob_amount

		# ----------------------------------------------------
		# ADS STABILITY
		# ----------------------------------------------------

		if is_aiming and not is_reloading:
			bob_amount *= ads_bob_multiplier

		weapon_bob_time += (
			delta *
			bob_speed
		)

		movement_bob.x = (
			cos(weapon_bob_time)
			* bob_amount
		)

		current_weapon_bob_x = movement_bob.x

		movement_bob.y = (
			abs(
				sin(weapon_bob_time)
			)
			* bob_amount
		)

		movement_bob.z = (
			sin(weapon_bob_time * 0.5)
			* bob_amount
			* 0.5
		)

	else:

		weapon_bob_time = move_toward(
			weapon_bob_time,
			0.0,
			delta * 5.0
		)

	# ========================================================
	# IDLE / BREATHING
	# ========================================================

	if not is_moving:

		weapon_idle_time += (
			delta *
			weapon_idle_speed
		)

	else:

		weapon_idle_time += (
			delta *
			weapon_idle_speed *
			0.5
		)


	var idle_amount := weapon_idle_amount

	if is_aiming and not is_reloading:
		idle_amount *= ads_idle_multiplier
	
	var idle_position := Vector3(
		sin(weapon_idle_time)
		* idle_amount,

		cos(weapon_idle_time * 0.5)
		* idle_amount
		* 0.6,

		sin(weapon_idle_time * 0.5)
		* idle_amount
		* 0.4
	)


	# ========================================================
	# FINAL POSITION
	# ========================================================

	var target_position: Vector3 = (
		weapon_base_position
		+ idle_position
		+ movement_bob
		+ weapon_recoil_position
	)


	# ========================================================
	# FINAL ROTATION
	# ========================================================

# ========================================================
# WEAPON LEAN
# ========================================================

	var horizontal_input := Input.get_axis(
		"move_left",
		"move_right"
	)

	var movement_lean := (
		-horizontal_input * weapon_lean_amount
	)


	var tactical_lean := 0.0


	if Input.is_action_pressed("lean_left"):

		# Camera leans left.
		# Weapon counter-leans right.
		tactical_lean = weapon_tactical_lean_amount

	elif Input.is_action_pressed("lean_right"):

		# Camera leans right.
		# Weapon counter-leans left.
		tactical_lean = -weapon_tactical_lean_amount


	var target_weapon_lean := (
		movement_lean +
		tactical_lean
	)


	var lean_smoothing := (
		1.0
		- exp(
			-weapon_lean_smoothness * delta
		)
	)


	current_weapon_lean = lerp(
		current_weapon_lean,
		target_weapon_lean,
		lean_smoothing
	)


	# ========================================================
	# FINAL ROTATION
	# ========================================================

	var target_rotation: Vector3 = (
		weapon_base_rotation
		+ sway_rotation
		+ weapon_lag_rotation
		+ weapon_recoil_rotation
	)

	target_rotation.z += current_weapon_lean
	# ========================================================
	# SMOOTH ROTATION
	# ========================================================

	var rotation_smoothing: float = (
		1.0
		- exp(
			-weapon_sway_speed *
			delta
		)
	)


	weapon.rotation = weapon.rotation.lerp(
		target_rotation,
		rotation_smoothing
	)


	# ========================================================
	# SMOOTH POSITION
	# ========================================================

	var position_smoothing: float = (
		1.0
		- exp(
			-weapon_idle_smoothness *
			delta
		)
	)


	weapon.position = weapon.position.lerp(
		target_position,
		position_smoothing
	)


	# ========================================================
	# RECOVER MOUSE SWAY
	# ========================================================

	var input_recovery: float = (
		1.0
		- exp(
			-12.0 *
			delta
		)
	)


	weapon_sway_input = weapon_sway_input.lerp(
		Vector2.ZERO,
		input_recovery
	)


# ============================================================
# WEAPON FIRE
# ============================================================

func handle_weapon_fire(delta: float) -> void:
	if is_reloading:
		fire_timer = 0.0
		return

	if not is_firing:
		fire_timer = 0.0
		empty_click_played = false
		return

	if current_ammo <= 0:
		fire_timer = 0.0

		if not empty_click_played:
			if empty_click_sound != null:
				empty_click_sound.play()
				
			empty_click_played = true

		return

	empty_click_played = false

	fire_timer -= delta

	if fire_timer <= 0.0:
		shoot()
		current_ammo -= 1
		update_ammo_ui()
		fire_timer = 1.0 / fire_rate
# ============================================================
# SHOOT
# ============================================================

func shoot() -> void:

	# --------------------------------------------------------
	# Weapon animation
	# --------------------------------------------------------

	weapon_animation.play("SHOOT")


	# --------------------------------------------------------
	# Weapon recoil
	# --------------------------------------------------------

	weapon_recoil_position.z += recoil_amount

	weapon_recoil_rotation.x -= recoil_rotation


	# --------------------------------------------------------
	# Camera recoil
	# --------------------------------------------------------

	camera_recoil.x += camera_recoil_amount

	camera_recoil.y += randf_range(
		-camera_recoil_side_amount,
		camera_recoil_side_amount
	)


	# --------------------------------------------------------
	# MUZZLE FLASH + LIGHT
	# --------------------------------------------------------

	if muzzle_flash != null:
		muzzle_flash.visible = true

	if muzzle_light != null:
		muzzle_light.visible = true

	muzzle_flash_timer = muzzle_flash_duration


	# --------------------------------------------------------
	# Gunshot
	# --------------------------------------------------------

	if gunshot_sound != null:
		gunshot_sound.play()


	# --------------------------------------------------------
	# Shell + bullet
	# --------------------------------------------------------

	eject_shell()
	fire_bullet()
	
	
func eject_shell() -> void:
	if shell_scene == null:
		return

	if ejection_point == null:
		return

	var shell := shell_scene.instantiate() as RigidBody3D

	if shell == null:
		return

	get_tree().current_scene.add_child(shell)

	shell.global_position = ejection_point.global_position
	shell.global_basis = ejection_point.global_basis

	var right_direction: Vector3 = ejection_point.global_transform.basis.x
	var up_direction: Vector3 = ejection_point.global_transform.basis.y

	var random_direction: Vector3 = (
		right_direction * randf_range(0.8, 1.2)
		+ up_direction * randf_range(0.2, 0.5)
	)

	random_direction += Vector3(
		randf_range(-0.2, 0.2),
		randf_range(-0.1, 0.2),
		randf_range(-0.2, 0.2)
	)

	random_direction = random_direction.normalized()

	shell.apply_central_impulse(
		random_direction * shell_impulse
		+ Vector3.UP * shell_upward_force
	)


	# --------------------------------------------------------
	# Gunshot sound
	# --------------------------------------------------------

	if gunshot_sound != null:

		gunshot_sound.play()


# ============================================================
# MUZZLE FLASH and Light
# ============================================================

func handle_muzzle_flash(delta: float) -> void:

	if muzzle_flash_timer <= 0.0:
		return


	muzzle_flash_timer -= delta


	if muzzle_flash_timer <= 0.0:

		if muzzle_flash != null:
			muzzle_flash.visible = false

		if muzzle_light != null:
			muzzle_light.visible = false

func fire_bullet() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var screen_center := viewport_size * 0.5

	var ray_origin := camera.project_ray_origin(screen_center)
	var ray_direction := camera.project_ray_normal(screen_center)

	var ray_end := (
		ray_origin
		+ ray_direction * bullet_range
	)

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end
	)

	query.exclude = [self]

	var result := get_world_3d().direct_space_state.intersect_ray(
		query
	)

	if result.is_empty():
		return

	var hit_position: Vector3 = result["position"]
	var hit_normal: Vector3 = result["normal"]
	var hit_object: Object = result["collider"]

	handle_bullet_hit(
		hit_position,
		hit_normal,
		hit_object
	)
	
func handle_bullet_hit(
	hit_position: Vector3,
	hit_normal: Vector3,
	hit_object: Object
) -> void:

	print("Hit: ", hit_object)

	spawn_bullet_impact(
		hit_position,
		hit_normal,
		hit_object
	)

	var damageable: Damageable = (
		hit_object.find_child(
			"Damageable",
			true,
			false
		) as Damageable
	)

	if damageable != null:
		damageable.take_damage(
			bullet_damage,
			hit_position,
			hit_normal
		)

	var surface: SurfaceInfo = (
		hit_object.find_child(
			"SurfaceType",
			true,
			false
		) as SurfaceInfo
	)

	if surface != null:
		surface.play_impact()

	if hit_object is RigidBody3D:
		var body: RigidBody3D = hit_object

		body.apply_impulse(
			-hit_normal * bullet_force,
			hit_position - body.global_position
		)
		

func spawn_bullet_impact(
	hit_position: Vector3,
	hit_normal: Vector3,
	hit_object: Object
) -> void:

	if bullet_impact_scene == null:
		return

	var impact := bullet_impact_scene.instantiate() as Node3D

	if impact == null:
		return

	get_tree().current_scene.add_child(impact)

	# Position and orient the impact first.
	impact.global_position = (
		hit_position + hit_normal * 0.005
	)

	var look_direction: Vector3 = -hit_normal
	var up_direction: Vector3 = Vector3.UP

	# Prevent looking_at() from receiving parallel vectors.
	if abs(look_direction.dot(up_direction)) > 0.98:
		up_direction = Vector3.FORWARD

	impact.global_basis = Basis.looking_at(
		look_direction,
		up_direction
	)

	# Attach the bullet hole to the object that was hit.
	if hit_object is Node3D:
		var hit_node: Node3D = hit_object

		impact.reparent(
			hit_node,
			true
		)	
func reload_weapon() -> void:
	if is_reloading:
		return

	if current_ammo >= magazine_size:
		return

	if reserve_ammo <= 0:
		return

	is_reloading = true
	is_firing = false
	fire_timer = 0.0

	weapon_animation.play("RELOAD2")

	await get_tree().create_timer(
		reload_sound_delay
	).timeout

	if reload_sound != null and is_reloading:
		reload_sound.play()

	await weapon_animation.animation_finished

	var ammo_needed: int = magazine_size - current_ammo
	var ammo_to_load: int = min(ammo_needed, reserve_ammo)

	current_ammo += ammo_to_load
	reserve_ammo -= ammo_to_load
	
	update_ammo_ui()
	
	is_reloading = false

func update_ammo_ui() -> void:
	if ammo_label == null:
		return

	ammo_label.text = "%d / %d" % [
		current_ammo,
		reserve_ammo
	]

func handle_weapon_ads(delta: float) -> void:

	var target_transform: Transform3D = (
		weapon_ads_base_transform
	)

	var target_fov: float = default_camera_fov


	# ========================================================
	# ADS
	# ========================================================

	if is_aiming and not is_reloading:

		var desired_ads_transform := Transform3D(
			Basis.IDENTITY,
			Vector3(
				0.0,
				0.0,
				-ads_distance
			)
		)

		target_transform = (
			desired_ads_transform
			* ads_point_local_transform.affine_inverse()
		)

		target_fov = ads_fov


	# ========================================================
	# ADS RUNNING CLIP PROTECTION
	# ========================================================

	var horizontal_velocity := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var movement_speed := horizontal_velocity.length()

	var is_sprinting := (
		Input.is_action_pressed("sprint")
		and movement_speed > 0.15
	)

	var target_forward_offset := 0.0

	if is_aiming and is_sprinting and not is_reloading:
		target_forward_offset = ads_running_forward_offset


	var offset_smoothing := (
		1.0
		- exp(
			-ads_stability_smoothness * delta
		)
	)

	current_ads_forward_offset = lerp(
		current_ads_forward_offset,
		target_forward_offset,
		offset_smoothing
	)


	# Move WeaponADS slightly forward during ADS sprint.
	target_transform.origin.z -= (
		current_ads_forward_offset
	)


	# ========================================================
	# SMOOTH ADS
	# ========================================================

	var smoothing: float = (
		1.0 -
		exp(
			-ads_speed * delta
		)
	)

	weapon_ads.transform = (
		weapon_ads.transform.interpolate_with(
			target_transform,
			smoothing
		)
	)


	# ========================================================
	# CAMERA FOV
	# ========================================================

	camera.fov = lerp(
		camera.fov,
		target_fov,
		smoothing
	)
func handle_footsteps() -> void:

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var movement_speed: float = horizontal_velocity.length()


	# ========================================================
	# NOT WALKING / NOT RUNNING
	# ========================================================

	if not is_on_floor() or movement_speed < footstep_min_speed:

		last_footstep_phase = 0.0

		return


	# ========================================================
	# USE THE EXACT SAME PHASE AS THE WEAPON BOB
	# ========================================================

	var current_phase: float = sin(
		weapon_bob_time
	)


	# ========================================================
	# DETECT WHEN WEAPON BOB REACHES THE BOTTOM
	# ========================================================
	#
	# Weapon Y movement:
	#
	# abs(sin(weapon_bob_time))
	#
	# The bottom occurs every time the sine crosses zero.
	#
	#       /\        /\
	#      /  \      /  \
	# ----/----\----/----\----
	#       ↑        ↑
	#    FOOTSTEP  FOOTSTEP
	#
	# ========================================================

	var crossed_zero: bool = (
		(
			last_footstep_phase < 0.0
			and current_phase >= 0.0
		)
		or
		(
			last_footstep_phase > 0.0
			and current_phase <= 0.0
		)
	)


	if crossed_zero:

		play_footstep()


	# ========================================================
	# STORE CURRENT PHASE
	# ========================================================

	last_footstep_phase = current_phase		
func play_footstep() -> void:

	if footstep_sound == null:
		return

	footstep_sound.pitch_scale = randf_range(
		1.0 - footstep_pitch_variation,
		1.0 + footstep_pitch_variation
	)

	footstep_sound.play()
	
func handle_surface_impact(
	hit_object: Object,
	hit_position: Vector3,
	hit_normal: Vector3
) -> void:

	var surface: SurfaceInfo = (
		hit_object.find_child(
			"SurfaceType",
			true,
			false
		) as SurfaceInfo
	)

	if surface == null:
		return

	match surface.surface_type:

		SurfaceInfo.SurfaceKind.DEFAULT:
			play_metal_impact()

		SurfaceInfo.SurfaceKind.METAL:
			play_metal_impact()

		SurfaceInfo.SurfaceKind.GLASS:
			pass
			
func play_metal_impact() -> void:
	if metal_impact_sound == null:
		return

	metal_impact_sound.pitch_scale = randf_range(
		0.9,
		1.1
	)

	metal_impact_sound.play()
