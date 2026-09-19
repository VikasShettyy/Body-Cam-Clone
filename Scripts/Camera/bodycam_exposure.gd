extends ColorRect


@export_category("Exposure")

@export var min_exposure: float = 0.55
@export var max_exposure: float = 1.35

# Brightness range used to determine how much light is visible.
@export var dark_threshold: float = 0.05
@export var bright_threshold: float = 0.65


@export_category("Sun / Directional Light")

# Drag your DirectionalLight3D here.
@export var directional_light: DirectionalLight3D

# How strongly looking toward the sun affects exposure.
@export_range(0.0, 1.0)
var sun_influence: float = 0.35

# Only start getting a strong sun effect when looking fairly
# directly toward the light.
@export var sun_angle_start: float = 0.35


@export_category("Adaptation")

@export var brighten_speed: float = 2.5
@export var darken_speed: float = 1.0


@export_category("Measurement")

@export var measurement_interval: float = 0.15


@onready var player_camera: Camera3D = (
	get_node(
		"../../CharacterBody3D/CameraPivot/Camera3D"
	)
)


@export var exposure_camera: Camera3D
@export var exposure_viewport: SubViewport


var current_exposure: float = 1.0
var target_exposure: float = 1.0

var measurement_timer: float = 0.0
var last_shader_exposure: float = -1.0


func _ready() -> void:

	exposure_viewport.world_3d = (
		get_viewport().world_3d
	)

	current_exposure = 1.0
	target_exposure = 1.0

	material.set_shader_parameter(
		"exposure",
		current_exposure
	)

	last_shader_exposure = current_exposure


func _process(delta: float) -> void:

	sync_exposure_camera()

	measurement_timer += delta

	if measurement_timer >= measurement_interval:

		measurement_timer -= measurement_interval

		measure_scene_brightness()


	# Smooth exposure change.

	var adaptation_speed: float = darken_speed

	if target_exposure > current_exposure:
		adaptation_speed = brighten_speed


	current_exposure = move_toward(
		current_exposure,
		target_exposure,
		adaptation_speed * delta
	)


	# Don't update the shader every tiny change.

	if abs(
		current_exposure -
		last_shader_exposure
	) > 0.001:

		material.set_shader_parameter(
			"exposure",
			current_exposure
		)

		last_shader_exposure = current_exposure


func sync_exposure_camera() -> void:

	if player_camera == null:
		return

	if exposure_camera == null:
		return


	exposure_camera.global_transform = (
		player_camera.global_transform
	)

	exposure_camera.fov = (
		player_camera.fov
	)

	exposure_camera.near = (
		player_camera.near
	)

	exposure_camera.far = (
		player_camera.far
	)

	exposure_camera.cull_mask = (
		player_camera.cull_mask
	)


func measure_scene_brightness() -> void:

	if exposure_viewport == null:
		return


	var viewport_texture: ViewportTexture = (
		exposure_viewport.get_texture()
	)

	if viewport_texture == null:
		return


	var image: Image = (
		viewport_texture.get_image()
	)

	if image == null:
		return


	var width: int = image.get_width()
	var height: int = image.get_height()


	if width <= 1 or height <= 1:
		return


	var total_brightness: float = 0.0
	var total_weight: float = 0.0


	# --------------------------------------------------
	# Measure center-weighted scene brightness
	# --------------------------------------------------

	for y in range(height):

		for x in range(width):

			var pixel: Color = (
				image.get_pixel(x, y)
			)


			var luminance: float = (
				pixel.r * 0.299
				+
				pixel.g * 0.587
				+
				pixel.b * 0.114
			)


			var uv_x: float = (
				float(x) /
				float(width - 1)
			)

			var uv_y: float = (
				float(y) /
				float(height - 1)
			)


			var distance_x: float = (
				uv_x - 0.5
			)

			var distance_y: float = (
				uv_y - 0.5
			)


			var distance_from_center: float = sqrt(
				distance_x * distance_x
				+
				distance_y * distance_y
			)


			# Center gets more importance.

			var weight: float = (
				1.0 -
				clamp(
					distance_from_center * 1.5,
					0.0,
					0.75
				)
			)


			total_brightness += (
				luminance *
				weight
			)

			total_weight += weight


	if total_weight <= 0.0:
		return


	var average_brightness: float = (
		total_brightness /
		total_weight
	)


	# --------------------------------------------------
	# Convert scene brightness into a 0-1 light factor
	# --------------------------------------------------

	var brightness_factor: float = inverse_lerp(
		dark_threshold,
		bright_threshold,
		average_brightness
	)

	brightness_factor = clamp(
		brightness_factor,
		0.0,
		1.0
	)


	# --------------------------------------------------
	# Detect whether camera is facing the sun
	# --------------------------------------------------

	var sun_factor: float = get_sun_facing_factor()


	# --------------------------------------------------
	# Combine scene brightness + sun direction
	# --------------------------------------------------

	var light_factor: float = max(
		brightness_factor,
		sun_factor * sun_influence
	)

	light_factor = clamp(
		light_factor,
		0.0,
		1.0
	)


	# --------------------------------------------------
	# Convert light amount into exposure
	# --------------------------------------------------

	target_exposure = lerp(
		min_exposure,
		max_exposure,
		light_factor
	)


func get_sun_facing_factor() -> float:

	if directional_light == null:
		return 0.0


	if player_camera == null:
		return 0.0


	# Camera forward direction.

	var camera_forward: Vector3 = (
		-player_camera.global_transform.basis.z
	)


	# Direction from the camera toward the directional light.

	var light_direction: Vector3 = (
		directional_light.global_transform.basis.z
	)


	camera_forward = camera_forward.normalized()
	light_direction = light_direction.normalized()


	var facing: float = (
		camera_forward.dot(light_direction)
	)


	# Looking away from the sun = 0.
	# Looking toward the sun = 1.

	var sun_factor: float = inverse_lerp(
		sun_angle_start,
		1.0,
		facing
	)


	return clamp(
		sun_factor,
		0.0,
		1.0
	)
