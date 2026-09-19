extends ColorRect


@export_category("Exposure")
@export var min_exposure: float = 0.70
@export var max_exposure: float = 1.30
@export var target_brightness: float = 0.45


@export_category("Adaptation")
@export var brighten_speed: float = 1.5
@export var darken_speed: float = 0.7


@export_category("Measurement")
@export var measurement_interval: float = 0.10


@onready var player_camera: Camera3D = (
	get_node("../../CharacterBody3D/CameraPivot/Camera3D")
)

@export var exposure_camera : Camera3D
@export var exposure_viewport : SubViewport

var current_exposure: float = 1.0
var target_exposure: float = 1.0
var measurement_timer: float = 0.0


func _ready() -> void:
	# Make the small exposure viewport use
	# the same 3D world as the main viewport.
	exposure_viewport.world_3d = (
		get_viewport().world_3d
	)

	current_exposure = 1.0

	material.set_shader_parameter(
		"exposure",
		current_exposure
	)


func _process(delta: float) -> void:
	# Keep the exposure camera synchronized
	# with the real player camera.
	sync_exposure_camera()


	# Measure brightness periodically.
	measurement_timer += delta

	if measurement_timer >= measurement_interval:
		measurement_timer = 0.0
		measure_scene_brightness()


	# Smooth exposure adaptation.
	var adaptation_speed: float = darken_speed

	if target_exposure > current_exposure:
		adaptation_speed = brighten_speed


	current_exposure = move_toward(
		current_exposure,
		target_exposure,
		adaptation_speed * delta
	)


	# Send exposure to the bodycam shader.
	material.set_shader_parameter(
		"exposure",
		current_exposure
	)


func sync_exposure_camera() -> void:
	exposure_camera.global_transform = (
		player_camera.global_transform
	)

	exposure_camera.fov = player_camera.fov
	exposure_camera.near = player_camera.near
	exposure_camera.far = player_camera.far
	exposure_camera.cull_mask = player_camera.cull_mask


func measure_scene_brightness() -> void:
	var viewport_texture: ViewportTexture = (
		exposure_viewport.get_texture()
	)

	var image: Image = (
		viewport_texture.get_image()
	)

	if image == null:
		return

	var total_brightness: float = 0.0
	var total_weight: float = 0.0

	var width: int = image.get_width()
	var height: int = image.get_height()

	if width <= 1 or height <= 1:
		return

	for y in range(height):
		for x in range(width):

			var pixel: Color = image.get_pixel(
				x,
				y
			)

			# Calculate luminance.
			var luminance: float = (
				pixel.r * 0.299
				+ pixel.g * 0.587
				+ pixel.b * 0.114
			)

			# Convert pixel position to 0-1 coordinates.
			var uv_x: float = (
				float(x) / float(width - 1)
			)

			var uv_y: float = (
				float(y) / float(height - 1)
			)

			# Distance from the center.
			var distance_x: float = uv_x - 0.5
			var distance_y: float = uv_y - 0.5

			var distance_from_center: float = sqrt(
				distance_x * distance_x
				+ distance_y * distance_y
			)

			# Center-weighted exposure.
			var weight: float = 1.0 - clamp(
				distance_from_center * 1.5,
				0.0,
				0.75
			)

			total_brightness += (
				luminance * weight
			)

			total_weight += weight

	# Safety check.
	if total_weight <= 0.0:
		return

	# Calculate weighted average brightness.
	var average_brightness: float = (
		total_brightness / total_weight
	)

	# Prevent division by zero.
	average_brightness = max(
		average_brightness,
		0.01
	)

	# Calculate required exposure.
	target_exposure = clamp(
		target_brightness / average_brightness,
		min_exposure,
		max_exposure
	)
