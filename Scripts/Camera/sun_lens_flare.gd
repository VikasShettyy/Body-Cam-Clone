extends TextureRect


@export_category("Sun")
@export var sun_marker: Marker3D


@export_category("Flare")
@export var max_alpha := 0.6
@export var flare_size := 500.0
@export var fade_speed := 4.0


@onready var player_camera: Camera3D = (
	get_node(
		"../../CharacterBody3D/CameraPivot/Camera3D"
	)
)


var current_alpha := 0.0


func _ready() -> void:

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_anchors_preset(
		Control.PRESET_CENTER
	)

	size = Vector2(
		flare_size,
		flare_size
	)

	pivot_offset = size * 0.5

	modulate.a = 0.0


func _process(delta: float) -> void:

	if player_camera == null:
		return

	if sun_marker == null:
		return

	var target_alpha := get_sun_strength()

	current_alpha = lerp(
		current_alpha,
		target_alpha,
		1.0 - exp(-fade_speed * delta)
	)

	modulate.a = current_alpha


func get_sun_strength() -> float:

	var camera_position: Vector3 = (
		player_camera.global_position
	)

	var direction_to_sun: Vector3 = (
		sun_marker.global_position
		- camera_position
	).normalized()


	var camera_forward: Vector3 = (
		-player_camera.global_transform.basis.z
	).normalized()


	var alignment: float = (
		camera_forward.dot(
			direction_to_sun
		)
	)


	if alignment <= 0.0:
		return 0.0


	var strength: float = pow(
		alignment,
		4.0
	)


	return strength * max_alpha
	
