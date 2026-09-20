extends CharacterBody3D


@export_category("Animation")
@export var run_animation_base_speed := 1.0

enum State {
	IDLE,
	CHASING,
	ATTACKING,
	DEAD
}


@export_category("Movement")
@export var move_speed := 2.5
@export var acceleration := 10.0
@export var gravity := 18.0


@export_category("Detection")
@export var detection_distance := 20.0


@export_category("Navigation")
@export var repath_interval := 0.15
@export var waypoint_reach_distance := 0.9

@export_category("Combat")
@export var attack_range := 1.5
@export var attack_damage := 20.0
@export var attack_cooldown := 1.2


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var damageable: Damageable = $Damageable

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state: AnimationNodeStateMachinePlayback = (
	animation_tree.get("parameters/playback")
)

var player: CharacterBody3D = null
var state: State = State.IDLE

var attack_timer := 0.0
var repath_timer := 0.0

var navigation_path: PackedVector3Array = PackedVector3Array()
var path_index := 0

var navigation_ready := false

var current_animation := ""
#Avoidence

@export_category("Navigation Recovery")
@export var stuck_check_time := 0.7
@export var stuck_distance_threshold := 0.08
@export var recovery_repath_delay := 0.15
var stuck_timer := 0.0
var recovery_timer := 0.0
var last_position := Vector3.ZERO


func _ready() -> void:
	
	damageable.died.connect(_on_died)

	animation_tree.active = true
	animation_state.start("Idle")

	navigation_agent.avoidance_enabled = false

	last_position = global_position
	print("AnimationTree active: ", animation_tree.active)
	print("Animation state: ", animation_state.get_current_node())
	call_deferred("initialize_navigation")

func initialize_navigation() -> void:

	await get_tree().physics_frame
	await get_tree().physics_frame

	navigation_ready = true

	print("Enemy navigation initialized.")


func _physics_process(delta: float) -> void:

	if state == State.DEAD:
		return

	handle_gravity(delta)

	attack_timer = max(
		attack_timer - delta,
		0.0
	)

	find_player()

	match state:

		State.IDLE:
			handle_idle(delta)

		State.CHASING:
			handle_chasing(delta)

		State.ATTACKING:
			handle_attack(delta)

	update_animation()

	move_and_slide()


# ============================================================
# GRAVITY
# ============================================================

func handle_gravity(delta: float) -> void:

	if not is_on_floor():

		velocity.y -= gravity * delta

	else:

		velocity.y = 0.0


# ============================================================
# FIND PLAYER
# ============================================================

func find_player() -> void:

	if player == null:

		var players := (
			get_tree().get_nodes_in_group("player")
		)

		if players.is_empty():
			return

		player = players[0] as CharacterBody3D

		print(
			"Enemy found player: ",
			player.name
		)

	if player == null:
		return


	var distance := (
		global_position.distance_to(
			player.global_position
		)
	)


	if distance <= attack_range:

		state = State.ATTACKING

	elif distance <= detection_distance:

		if state != State.CHASING:

			state = State.CHASING

			repath_timer = repath_interval

			stuck_timer = 0.0
			recovery_timer = 0.0
			last_position = global_position

	else:

		state = State.IDLE

func update_animation() -> void:

	var target_animation := ""

	match state:

		State.IDLE:
			target_animation = "Idle"

		State.CHASING:
			target_animation = "Run"

		State.ATTACKING:
			target_animation = "Attack"

		State.DEAD:
			return

	if target_animation != current_animation:
		current_animation = target_animation
		animation_state.travel(target_animation)

	# Match running animation speed to actual movement speed.
	if state == State.CHASING:

		var current_speed := Vector2(
			velocity.x,
			velocity.z
		).length()

		var speed_ratio := current_speed / move_speed

		speed_ratio = clamp(
			speed_ratio,
			0.5,
			1.5
		)

		animation_tree.set(
			"parameters/Run/TimeScale/scale",
			run_animation_base_speed * speed_ratio
		)
# ============================================================
# IDLE
# ============================================================

func handle_idle(delta: float) -> void:

	stop_horizontal(delta)

	navigation_path.clear()

	path_index = 0


# ============================================================
# CHASING
# ============================================================
func handle_chasing(delta: float) -> void:

	if player == null:

		state = State.IDLE

		return


	var distance := (
		global_position.distance_to(
			player.global_position
		)
	)


	if distance <= attack_range:

		state = State.ATTACKING

		stop_horizontal(delta)

		return


	if not navigation_ready:

		stop_horizontal(delta)

		return


	# --------------------------------------------------
	# PATH REBUILD
	# --------------------------------------------------

	repath_timer += delta

	if repath_timer >= repath_interval:

		repath_timer = 0.0

		build_navigation_path()


	# --------------------------------------------------
	# RECOVERY TIMER
	# --------------------------------------------------

	if recovery_timer > 0.0:

		recovery_timer -= delta

		return


	# --------------------------------------------------
	# CHECK IF ENEMY IS STUCK
	# --------------------------------------------------

	var moved_distance := (
		global_position.distance_to(
			last_position
		)
	)


	if moved_distance < stuck_distance_threshold:

		stuck_timer += delta

	else:

		stuck_timer = 0.0


	last_position = global_position


	# --------------------------------------------------
	# STUCK
	# --------------------------------------------------

	if stuck_timer >= stuck_check_time:

		stuck_timer = 0.0

		recovery_timer = recovery_repath_delay

		print(
			"Enemy appears stuck. Rebuilding path."
		)

		build_navigation_path()

		stop_horizontal(delta)

		return


	# --------------------------------------------------
	# NO PATH
	# --------------------------------------------------

	if navigation_path.is_empty():

		stop_horizontal(delta)

		return


	if path_index >= navigation_path.size():

		stop_horizontal(delta)

		return


	# --------------------------------------------------
	# CURRENT WAYPOINT
	# --------------------------------------------------

	var waypoint := navigation_path[path_index]


	var direction := (
		waypoint -
		global_position
	)


	direction.y = 0.0


	var distance_to_waypoint := (
		direction.length()
	)


	# --------------------------------------------------
	# WAYPOINT REACHED
	# --------------------------------------------------

	if distance_to_waypoint <= waypoint_reach_distance:

		path_index += 1

		if path_index >= navigation_path.size():

			stop_horizontal(delta)

		return


	direction = direction.normalized()


	# --------------------------------------------------
	# MOVEMENT
	# --------------------------------------------------

	velocity.x = move_toward(
		velocity.x,
		direction.x * move_speed,
		acceleration * delta
	)


	velocity.z = move_toward(
		velocity.z,
		direction.z * move_speed,
		acceleration * delta
	)


	# --------------------------------------------------
	# ROTATION
	# --------------------------------------------------

	var target_rotation := atan2(
		-direction.x,
		-direction.z
	)


	rotation.y = lerp_angle(
		rotation.y,
		target_rotation,
		8.0 * delta
	)

# ============================================================
# BUILD NAVIGATION PATH
# ============================================================

func build_navigation_path() -> void:

	if player == null:
		return


	var navigation_map := (
		navigation_agent.get_navigation_map()
	)


	if not navigation_map.is_valid():

		print(
			"ERROR: Navigation map is invalid."
		)

		return


	var start_position := (
		NavigationServer3D.map_get_closest_point(
			navigation_map,
			global_position
		)
	)


	var target_position := (
		NavigationServer3D.map_get_closest_point(
			navigation_map,
			player.global_position
		)
	)


	var new_path := (
		NavigationServer3D.map_get_path(
			navigation_map,
			start_position,
			target_position,
			true
		)
	)


	if new_path.is_empty():

		print(
			"Enemy could not find navigation path."
		)

		navigation_path.clear()

		path_index = 0

		return


	navigation_path = new_path

	# The first point is normally the enemy's
	# current navigation position, so skip it.

	if navigation_path.size() > 1:

		path_index = 1

	else:

		path_index = 0


# ============================================================
# ATTACK
# ============================================================

func handle_attack(delta: float) -> void:

	stop_horizontal(delta)


	if player == null:

		state = State.IDLE

		return


	var direction := (
		player.global_position -
		global_position
	)


	direction.y = 0.0


	if direction.length() > 0.01:

		direction = direction.normalized()


		var target_rotation := atan2(
			-direction.x,
			-direction.z
		)


		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			10.0 * delta
		)


	var distance := (
		global_position.distance_to(
			player.global_position
		)
	)


	if distance > attack_range:

		state = State.CHASING

		repath_timer = repath_interval

		return


	if attack_timer > 0.0:
		return


	attack_timer = attack_cooldown

	perform_attack()


# ============================================================
# PERFORM ATTACK
# ============================================================

func perform_attack() -> void:

	if player == null:
		return

	animation_state.travel("Attack")

	print("Enemy attacks player!")


	var player_damageable := (
		player.find_child(
			"Damageable",
			true,
			false
		) as Damageable
	)

	if player_damageable == null:

		print(
			"Player does not have a Damageable node!"
		)

		return


	var attack_direction := (
		player.global_position -
		global_position
	)


	if attack_direction.length() > 0.01:

		attack_direction = (
			attack_direction.normalized()
		)


	player_damageable.take_damage(
		attack_damage,
		player.global_position,
		attack_direction
	)

# ============================================================
# STOP
# ============================================================

func stop_horizontal(delta: float) -> void:

	velocity.x = move_toward(
		velocity.x,
		0.0,
		acceleration * delta
	)


	velocity.z = move_toward(
		velocity.z,
		0.0,
		acceleration * delta
	)


# ============================================================
# DEATH
# ============================================================

func _on_died() -> void:

	state = State.DEAD

	velocity = Vector3.ZERO

	navigation_path.clear()

	print("Enemy died")
	queue_free()
