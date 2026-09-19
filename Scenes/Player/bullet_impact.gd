extends Node3D

@export var lifetime := 3.0
@export var random_pitch := true

@onready var impact_sound: AudioStreamPlayer3D = $ImpactSound


func _ready() -> void:
	if impact_sound != null:
		if random_pitch:
			impact_sound.pitch_scale = randf_range(0.9, 1.1)

		impact_sound.play()

	await get_tree().create_timer(lifetime).timeout
	queue_free()
