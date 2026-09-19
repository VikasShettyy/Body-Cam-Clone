extends CharacterBody3D


# ============================================================
# WEAPON
# ============================================================

@onready var weapon: Node3D = (
	$CameraPivot/Camera3D/WeaponHolder/Weapon
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

@export var walk_bob_amount := 0.035
@export var walk_sway_amount := 0.025
@export var walk_bob_frequency := 8.0
@export var sprint_bob_frequency := 10.0
@export var camera_motion_smoothness := 10.0
@export var camera_roll_amount := 0.025
@export var camera_forward_amount := 0.015


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

@export var landing_shake_strength := 0.035
@export var landing_shake_rotation := 0.025
@export var shake_recovery_speed := 12.0

var shake_position := Vector3.ZERO
var shake_rotation := Vector3.ZERO

var previous_vertical_velocity := 0.0
var was_on_floor := false


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

	# Remember original camera position.
	camera_base_position = camera_pivot.position

	# Remember original weapon position and rotation.
	weapon_base_position = weapon.position
	weapon_base_rotation = weapon.rotation

	# Print available weapon animations.
	print("Weapon animations:")
	print(weapon_animation.get_animation_list())


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(event: InputEvent) -> void:

	# --------------------------------------------------------
	# Weapon animation testing
	# --------------------------------------------------------

	if event is InputEventKey and event.pressed:

		if event.keycode == KEY_1:
			weapon_animation.play("DRAW")

		elif event.keycode == KEY_2:
			weapon_animation.play("IDLE")

		elif event.keycode == KEY_3:
			weapon_animation.play("INSPEC")

		elif event.keycode == KEY_4:
			weapon_animation.play("OLSER")

		elif event.keycode == KEY_5:
			weapon_animation.play("RELOAD1")

		elif event.keycode == KEY_6:
			weapon_animation.play("RELOAD2")

		elif event.keycode == KEY_7:
			weapon_animation.play("SHOOT")


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


	# --------------------------------------------------------
	# Capture mouse again
	# --------------------------------------------------------

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			Input.mouse_mode = (
				Input.MOUSE_MODE_CAPTURED
			)


# ============================================================
# PHYSICS
# ============================================================

func _physics_process(delta: float) -> void:

	handle_movement(delta)

	handle_gravity(delta)

	move_and_slide()

	handle_bodycam_motion(delta)

	handle_camera_inertia(delta)

	handle_camera_shake(delta)

	handle_weapon_sway(delta)


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

	# --------------------------------------------------------
	# Horizontal movement speed
	# --------------------------------------------------------

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var movement_speed: float = horizontal_velocity.length()


	# --------------------------------------------------------
	# Movement state
	# --------------------------------------------------------

	var is_moving: bool = (
		movement_speed > 0.15
	)


	# --------------------------------------------------------
	# Sprint state
	# --------------------------------------------------------

	var is_sprinting: bool = (
		Input.is_action_pressed("sprint")
		and is_moving
	)


	# --------------------------------------------------------
	# Walking / sprinting bob
	# --------------------------------------------------------

	if is_moving and is_on_floor():

		var bob_frequency: float = (
			walk_bob_frequency
		)

		if is_sprinting:

			bob_frequency = (
				sprint_bob_frequency
			)

		camera_bob_time += (
			delta *
			bob_frequency
		)

	else:

		# Smoothly stop the bob.
		camera_bob_time = move_toward(
			camera_bob_time,
			0.0,
			delta * 5.0
		)


	# --------------------------------------------------------
	# Movement intensity
	# --------------------------------------------------------

	var speed_factor: float = clamp(
		movement_speed / sprint_speed,
		0.0,
		1.0
	)


	# --------------------------------------------------------
	# Vertical bob
	# --------------------------------------------------------

	var bob_y: float = (
		sin(camera_bob_time)
		* walk_bob_amount
		* speed_factor
	)


	# --------------------------------------------------------
	# Side-to-side sway
	# --------------------------------------------------------

	var bob_x: float = (
		cos(camera_bob_time * 0.5)
		* walk_sway_amount
		* speed_factor
	)


	# --------------------------------------------------------
	# Forward / backward movement
	# --------------------------------------------------------

	var bob_z: float = (
		sin(camera_bob_time * 0.5)
		* camera_forward_amount
		* speed_factor
	)


	# --------------------------------------------------------
	# Target camera position
	# --------------------------------------------------------

	var target_position: Vector3 = (
		camera_base_position
		+ Vector3(
			bob_x,
			bob_y,
			bob_z
		)
	)


	# --------------------------------------------------------
	# Smooth camera position
	# --------------------------------------------------------

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


	# --------------------------------------------------------
	# Bodycam roll
	# --------------------------------------------------------

	var target_roll: float = (
		-bob_x
		* camera_roll_amount
		* 10.0
	)


	camera_pivot.rotation.z = lerp(
		camera_pivot.rotation.z,
		target_roll,
		position_smoothing
	)


# ============================================================
# CAMERA INERTIA
# ============================================================

func handle_camera_inertia(delta: float) -> void:

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
		look_x,
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
		camera_yaw_offset,
		pitch_smoothing
	)


# ============================================================
# CAMERA SHAKE
# ============================================================

func handle_camera_shake(delta: float) -> void:

	# --------------------------------------------------------
	# Detect landing
	# --------------------------------------------------------

	var just_landed: bool = (
		is_on_floor()
		and not was_on_floor
		and previous_vertical_velocity < -1.0
	)


	# --------------------------------------------------------
	# Landing impact
	# --------------------------------------------------------

	if just_landed:

		var impact_strength: float = clamp(
			abs(previous_vertical_velocity) / 10.0,
			0.0,
			1.0
		)


		shake_position.y -= (
			landing_shake_strength *
			impact_strength
		)


		shake_position.z += (
			landing_shake_strength *
			0.5 *
			impact_strength
		)


		shake_rotation.x += (
			landing_shake_rotation *
			impact_strength
		)


	# --------------------------------------------------------
	# Recovery
	# --------------------------------------------------------

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


	# --------------------------------------------------------
	# Apply position shake
	# --------------------------------------------------------

	camera.position = shake_position


	# --------------------------------------------------------
	# Apply rotation shake
	# --------------------------------------------------------

	camera.rotation.x = shake_rotation.x
	camera.rotation.y = shake_rotation.y
	camera.rotation.z = shake_rotation.z


	# --------------------------------------------------------
	# Store state
	# --------------------------------------------------------

	previous_vertical_velocity = velocity.y

	was_on_floor = is_on_floor()


# ============================================================
# WEAPON SWAY + IDLE
# ============================================================

func handle_weapon_sway(delta: float) -> void:

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var movement_speed: float = horizontal_velocity.length()

	var is_moving: bool = movement_speed > 0.15

	var is_sprinting: bool = (
		Input.is_action_pressed("sprint")
		and is_moving
	)


	# ========================================================
	# MOUSE SWAY
	# ========================================================

	var sway_rotation: Vector3 = Vector3(
		weapon_sway_input.y * weapon_sway_amount,
		weapon_sway_input.x * weapon_sway_amount,
		-weapon_sway_input.x * weapon_sway_amount * 0.5
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

		weapon_bob_time += delta * bob_speed

		movement_bob.x = (
			cos(weapon_bob_time)
			* bob_amount
		)

		movement_bob.y = (
			abs(sin(weapon_bob_time))
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


	var idle_position := Vector3(
		sin(weapon_idle_time)
		* weapon_idle_amount,

		cos(weapon_idle_time * 0.5)
		* weapon_idle_amount
		* 0.6,

		sin(weapon_idle_time * 0.5)
		* weapon_idle_amount
		* 0.4
	)


	# ========================================================
	# FINAL POSITION
	# ========================================================

	var target_position: Vector3 = (
		weapon_base_position
		+ idle_position
		+ movement_bob
	)


	# ========================================================
	# FINAL ROTATION
	# ========================================================

	var target_rotation: Vector3 = (
		weapon_base_rotation
		+ sway_rotation
	)


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
