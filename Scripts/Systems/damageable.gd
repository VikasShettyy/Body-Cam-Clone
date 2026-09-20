class_name Damageable
extends Node

signal damaged(
	damage: float,
	hit_position: Vector3,
	hit_normal: Vector3
)

signal died

@export_category("Health")
@export var max_health := 100.0

var health: float
var is_dead := false


func _ready() -> void:
	health = max_health


func take_damage(
	damage: float,
	hit_position: Vector3,
	hit_normal: Vector3
) -> void:
	if is_dead:
		return

	health = max(health - damage, 0.0)

	print(
		"Damage: ",
		damage,
		" | Health: ",
		health,
		"/",
		max_health
	)

	damaged.emit(
		damage,
		hit_position,
		hit_normal
	)

	if health <= 0.0:
		is_dead = true
		died.emit()
