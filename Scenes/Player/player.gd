extends CharacterBody3D


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

# How much the camera moves vertically while walking.
@export var walk_bob_amount := 0.035

# How much the camera moves sideways.
@export var walk_sway_amount := 0.025

# Walking frequency.
@export var walk_bob_frequency := 8.0

# Sprinting is slightly faster.
@export var sprint_bob_frequency := 10.0

# Camera movement smoothing.
@export var camera_motion_smoothness := 10.0

# How much the camera tilts sideways.
@export var camera_roll_amount := 0.025

# Small forward/backward movement.
@export var camera_forward_amount := 0.015

# ============================================================
# CAMERA INERTIA
# ============================================================

@export_category("Camera Inertia")

# How quickly the camera catches up to vertical look.
@export var look_smoothness := 14.0

# Maximum sideways camera lag in radians.
@export var max_camera_yaw_offset := 0.06

# How strongly mouse movement affects camera lag.
@export var camera_yaw_inertia := 0.003

# How quickly sideways lag returns to center.
@export var yaw_return_speed := 10.0


var camera_yaw_offset := 0.0

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

	# Remember the original camera pivot position.
	camera_base_position = camera_pivot.position


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(event: InputEvent) -> void:

	# --------------------------------------------------------
	# Mouse look
	# --------------------------------------------------------

	if event is InputEventMouseMotion:

		# --------------------------------------------------------
		# Player rotation
		# --------------------------------------------------------
	
		look_y -= (
			event.relative.x *
			mouse_sensitivity
		)


		# --------------------------------------------------------
		# Camera pitch target
		# --------------------------------------------------------

		look_x -= (
			event.relative.y *
			mouse_sensitivity
		)


		look_x = clamp(
			look_x,
			deg_to_rad(-max_look_angle),
			deg_to_rad(max_look_angle)
		)


		# --------------------------------------------------------
		# Player turns immediately
		# --------------------------------------------------------

		rotation.y = look_y


		# --------------------------------------------------------
		# Camera gets a small sideways inertia offset
		# --------------------------------------------------------

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

	# ========================================================
	# HORIZONTAL MOVEMENT SPEED
	# ========================================================

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var movement_speed: float = horizontal_velocity.length()


	# ========================================================
	# MOVEMENT STATE
	# ========================================================

	var is_moving: bool = movement_speed > 0.15


	# ========================================================
	# SPRINT STATE
	# ========================================================

	var is_sprinting: bool = (
		Input.is_action_pressed("sprint")
		and is_moving
	)


	# ========================================================
	# WALKING / SPRINTING BOB
	# ========================================================

	if is_moving and is_on_floor():

		var bob_frequency: float = walk_bob_frequency

		if is_sprinting:
			bob_frequency = sprint_bob_frequency

		camera_bob_time += delta * bob_frequency

	else:

		# Smoothly stop the bob when the player stops.
		camera_bob_time = move_toward(
			camera_bob_time,
			0.0,
			delta * 5.0
		)


	# ========================================================
	# MOVEMENT INTENSITY
	# ========================================================

	var speed_factor: float = clamp(
		movement_speed / sprint_speed,
		0.0,
		1.0
	)


	# ========================================================
	# VERTICAL BOB
	# ========================================================

	var bob_y: float = (
		sin(camera_bob_time)
		* walk_bob_amount
		* speed_factor
	)


	# ========================================================
	# SIDE-TO-SIDE SWAY
	# ========================================================

	var bob_x: float = (
		cos(camera_bob_time * 0.5)
		* walk_sway_amount
		* speed_factor
	)


	# ========================================================
	# FORWARD / BACKWARD MOVEMENT
	# ========================================================

	var bob_z: float = (
		sin(camera_bob_time * 0.5)
		* camera_forward_amount
		* speed_factor
	)


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
			-camera_motion_smoothness * delta
		)
	)

	camera_pivot.position = camera_pivot.position.lerp(
		target_position,
		position_smoothing
	)


	# ========================================================
	# BODYCAM ROLL
	# ========================================================

	var target_roll: float = (
		-bob_x
		* camera_roll_amount
		* 10.0
	)


	# Smooth roll.
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

	var pitch_smoothing := (
		1.0 -
		exp(
			-look_smoothness * delta
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
