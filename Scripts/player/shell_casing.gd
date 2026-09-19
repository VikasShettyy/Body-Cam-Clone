extends RigidBody3D

@export_category("Lifetime")
@export var lifetime := 4.0

@export_category("Spin")
@export var spin_strength := 25.0

@export_category("Impact Sound")
@export var impact_velocity_threshold := 1.2
@export var impact_cooldown := 0.08

@onready var clink_sound: AudioStreamPlayer3D = $ClinkSound

var life_timer := 0.0
var impact_timer := 0.0
var has_played_impact := false


func _ready() -> void:
	apply_torque_impulse(Vector3(
		randf_range(-spin_strength, spin_strength),
		randf_range(-spin_strength, spin_strength),
		randf_range(-spin_strength, spin_strength)
	))


func _physics_process(delta: float) -> void:
	life_timer += delta
	impact_timer -= delta

	if life_timer >= lifetime:
		queue_free()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if has_played_impact:
		return

	if impact_timer > 0.0:
		return

	if state.get_contact_count() <= 0:
		return

	var impact_speed := state.linear_velocity.length()

	if impact_speed < impact_velocity_threshold:
		return

	has_played_impact = true
	impact_timer = impact_cooldown

	if clink_sound != null:
		clink_sound.pitch_scale = randf_range(0.9, 1.1)
		clink_sound.volume_db = randf_range(-14.0, -9.0)
		clink_sound.play()
