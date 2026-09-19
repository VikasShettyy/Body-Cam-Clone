class_name SurfaceInfo
extends Node

enum SurfaceKind {
	DEFAULT,
	METAL,
	GLASS
}

@export var surface_type: SurfaceKind = SurfaceKind.DEFAULT

@onready var impact_sound: AudioStreamPlayer3D = $MetalImpactSound


func play_impact() -> void:
	if impact_sound == null:
		return

	impact_sound.pitch_scale = randf_range(
		0.9,
		1.1
	)

	impact_sound.play()
