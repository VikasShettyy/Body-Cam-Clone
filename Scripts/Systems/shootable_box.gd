extends RigidBody3D

@onready var damageable: Damageable = $Damageable
@onready var hit_sound: AudioStreamPlayer3D = $HitSound


func _ready() -> void:
	damageable.damaged.connect(
		_on_damageable_damaged
	)

	damageable.died.connect(
		_on_damageable_died
	)


func _on_damageable_damaged(
	damage: float,
	hit_position: Vector3,
	hit_normal: Vector3
) -> void:

	print("Box hit for: ", damage)

	if hit_sound != null:
		hit_sound.pitch_scale = randf_range(
			0.9,
			1.1
		)

		hit_sound.play()


func _on_damageable_died() -> void:
	print("Box destroyed!")

	apply_central_impulse(
		Vector3(
			randf_range(-1.0, 1.0),
			2.0,
			randf_range(-1.0, 1.0)
		)
	)

	apply_torque_impulse(
		Vector3(
			randf_range(-2.0, 2.0),
			randf_range(-2.0, 2.0),
			randf_range(-2.0, 2.0)
		)
	)

	await get_tree().create_timer(1.0).timeout

	queue_free()
