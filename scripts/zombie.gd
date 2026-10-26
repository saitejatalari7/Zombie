extends CharacterBody3D
class_name Zombie

signal died(zombie: Zombie)

enum State {
	IDLE,
	CHASE,
	ATTACK_WINDUP,
	ATTACK_RECOVERY,
	STAGGER,
	DEAD
}

@export var max_health: float = 65.0
@export var base_speed: float = 1.4
@export var damage_per_second: float = 0.0
@export var attack_damage: float = 12.0
@export var attack_range: float = 1.25
@export var attack_cooldown: float = 1.2
@export var attack_windup_time: float = 0.35
@export var stagger_duration: float = 0.18
@export var aggro_distance: float = 22.0

var state: State = State.CHASE
var current_health: float = 65.0
var speed: float = 1.4
var is_dead: bool = false
var target_player: Player = null

# Timers
var attack_timer: float = 0.0
var stagger_timer: float = 0.0
var separation_timer: float = 0.0
var lunge_cooldown: float = 0.0

# Flocking / Avoidance
var separation_distance: float = 0.95
var cached_separation: Vector3 = Vector3.ZERO
var cached_obstacle_steer: Vector3 = Vector3.ZERO

# Knockback
var knockback_velocity: Vector3 = Vector3.ZERO
var last_hit_impulse: Vector3 = Vector3.ZERO

# Visuals & Procedural Walk Cycle
@onready var visual_root: Node3D = $Visuals
@onready var head_mesh: Node3D = $Visuals.find_child("Head", true, false) if has_node("Visuals") else null
@onready var torso_mesh: Node3D = $Visuals.find_child("Torso", true, false) if has_node("Visuals") else null
@onready var arm_left: Node3D = $Visuals.find_child("ArmLeft", true, false) if has_node("Visuals") else null
@onready var arm_right: Node3D = $Visuals.find_child("ArmRight", true, false) if has_node("Visuals") else null
@onready var leg_left: Node3D = $Visuals.find_child("LegLeft", true, false) if has_node("Visuals") else null
@onready var leg_right: Node3D = $Visuals.find_child("LegRight", true, false) if has_node("Visuals") else null

var walk_cycle: float = 0.0
var walk_speed_factor: float = 3.5
var hit_flash_timer: float = 0.0

# Burning state
var is_burning: bool = false
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0

func _ready() -> void:
	add_to_group("zombies")
	current_health = max_health
	
	# Paced zombie speed with small individual variance (+/- 12%)
	speed = base_speed * randf_range(0.88, 1.15)
	walk_speed_factor = randf_range(2.8, 4.0)
	walk_cycle = randf_range(0.0, TAU)
	separation_timer = randf_range(0.0, 0.25)
	
	_find_player()

## Reward category used by GameManager.record_kill().
func get_enemy_type() -> String:
	if is_in_group("bosses"):
		return "tank"
	if is_in_group("runners"):
		return "runner"
	return "shambler"

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0] as Player

func _physics_process(delta: float) -> void:
	if is_dead or state == State.DEAD:
		return
	
	# Hit flash recovery
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0:
			_reset_materials()
	
	# Burning state & chain ignition
	if is_burning:
		_process_burning(delta)
	
	# Target validation
	if not is_instance_valid(target_player):
		_find_player()
		if not is_instance_valid(target_player):
			_apply_gravity(delta)
			move_and_slide()
			return
	
	var dist_to_player := global_position.distance_to(target_player.global_position)
	
	# ─── STATE MACHINE ───
	match state:
		State.STAGGER:
			_process_stagger(delta)
		State.ATTACK_WINDUP:
			_process_attack_windup(delta, dist_to_player)
		State.ATTACK_RECOVERY:
			_process_attack_recovery(delta)
		State.CHASE, State.IDLE:
			_process_chase(delta, dist_to_player)
	
	# Apply gravity & damp knockback
	_apply_gravity(delta)
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, delta * 20.0)
	
	move_and_slide()
	
	if global_position.y < -1.0:
		global_position.y = 0.0
	
	# Procedural walk / attack animation with distance LOD
	_update_animation(delta, dist_to_player)

func _process_burning(delta: float) -> void:
	burn_timer -= delta
	burn_tick_timer += delta
	if burn_tick_timer >= 0.38:
		burn_tick_timer = 0.0
		take_damage(28.0, Vector3.ZERO)
		
		# Chain ignition to adjacent zombies within 1.5m (sample max 6)
		var zombies := get_tree().get_nodes_in_group("zombies")
		var count := mini(zombies.size(), 8)
		for i in range(count):
			var other = zombies[i]
			if other != self and is_instance_valid(other) and not other.is_dead and ("is_burning" in other and not other.is_burning):
				if global_position.distance_to(other.global_position) <= 1.5:
					other.ignite(burn_timer)
					
	if burn_timer <= 0.0:
		is_burning = false
		_reset_materials()

func _process_stagger(delta: float) -> void:
	stagger_timer -= delta
	velocity.x = knockback_velocity.x
	velocity.z = knockback_velocity.z
	if stagger_timer <= 0.0:
		state = State.CHASE

func _process_attack_windup(delta: float, dist_to_player: float) -> void:
	attack_timer -= delta
	# Stop in place while winding up swipe
	velocity.x = knockback_velocity.x * 0.5
	velocity.z = knockback_velocity.z * 0.5
	
	# Face player directly
	var to_player := (target_player.global_position - global_position)
	to_player.y = 0.0
	if to_player.length() > 0.01:
		var target_yaw := atan2(-to_player.x, -to_player.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 12.0)
	
	# Windup pose: arms reach up and forward
	if is_instance_valid(arm_left):
		arm_left.rotation.x = lerp_angle(arm_left.rotation.x, -1.6, delta * 10.0)
	if is_instance_valid(arm_right):
		arm_right.rotation.x = lerp_angle(arm_right.rotation.x, -1.6, delta * 10.0)
	
	if attack_timer <= 0.0:
		# Deliver strike!
		if dist_to_player <= attack_range + 0.45:
			var strike_impulse := to_player.normalized() * 3.5
			target_player.take_damage(attack_damage, strike_impulse)
			
		state = State.ATTACK_RECOVERY
		attack_timer = attack_cooldown

func _process_attack_recovery(delta: float) -> void:
	attack_timer -= delta
	# Slow recovery shuffle
	velocity.x = move_toward(velocity.x, 0.0, delta * 4.0) + knockback_velocity.x
	velocity.z = move_toward(velocity.z, 0.0, delta * 4.0) + knockback_velocity.z
	
	# Recover arm positions
	if is_instance_valid(arm_left):
		arm_left.rotation.x = lerp_angle(arm_left.rotation.x, -0.6, delta * 6.0)
	if is_instance_valid(arm_right):
		arm_right.rotation.x = lerp_angle(arm_right.rotation.x, -0.6, delta * 6.0)
		
	if attack_timer <= 0.0:
		state = State.CHASE

func _process_chase(delta: float, dist_to_player: float) -> void:
	# Check if within attack range
	if dist_to_player <= attack_range:
		state = State.ATTACK_WINDUP
		attack_timer = attack_windup_time
		velocity.x = 0.0
		velocity.z = 0.0
		return
	
	# Runners close the last few metres with a sudden lunge
	lunge_cooldown = maxf(0.0, lunge_cooldown - delta)
	if is_in_group("runners") and lunge_cooldown <= 0.0 and dist_to_player < 3.0:
		var lunge_dir := target_player.global_position - global_position
		lunge_dir.y = 0.0
		knockback_velocity += lunge_dir.normalized() * 6.0
		lunge_cooldown = 2.5
	
	# Direction towards player or blood scent
	var target_pos := target_player.global_position
	# Runners track blood scent, except when the player carries the objective: then they hunt the carrier
	if is_in_group("runners") and BloodManager.instance and not target_player.carrying_objective:
		var scent := BloodManager.instance.get_nearest_footprint(global_position, 12.0)
		if not scent.is_empty():
			target_pos = scent["pos"]
			
	var to_target := (target_pos - global_position)
	to_target.y = 0.0
	var move_dir := to_target.normalized()
	
	# Wall & Obstacle sliding (no building scaling!)
	if is_on_wall():
		var wall_norm := get_wall_normal()
		# Slide along wall normal instead of crashing or climbing
		move_dir = move_dir.slide(wall_norm).normalized()
		
		# Low step/stair check: if obstacle is low (<= 0.35m), give small step assist
		if is_on_floor() and move_dir.dot(to_target.normalized()) > 0.2:
			velocity.y = 2.0
	
	# Throttled soft flocking separation (every ~0.2s, samples up to 6 neighbors)
	separation_timer -= delta
	if separation_timer <= 0.0:
		separation_timer = 0.18 + randf_range(0.0, 0.06)
		_update_cached_separation()
		
	var desired_dir := (move_dir + cached_separation * 0.45).normalized()
	var current_move_speed := speed
	
	velocity.x = desired_dir.x * current_move_speed + knockback_velocity.x
	velocity.z = desired_dir.z * current_move_speed + knockback_velocity.z
	
	# Rotate towards travel heading
	if desired_dir.length() > 0.01:
		var target_yaw := atan2(-desired_dir.x, -desired_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 8.0)

func _update_cached_separation() -> void:
	cached_separation = Vector3.ZERO
	var zombies := get_tree().get_nodes_in_group("zombies")
	var total := zombies.size()
	if total <= 1:
		return
		
	var sample_count := mini(6, total)
	var start_idx := randi() % total
	for i in range(sample_count):
		var z = zombies[(start_idx + i) % total]
		if z != self and is_instance_valid(z) and not z.is_dead:
			var diff: Vector3 = global_position - z.global_position
			diff.y = 0.0
			var d := diff.length()
			if d < separation_distance and d > 0.01:
				cached_separation += (diff / (d * d)) * 0.35

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5

func _update_animation(delta: float, dist_to_player: float) -> void:
	# Distance LOD: Beyond 24m, skip fine limb bone updates to protect CPU
	if dist_to_player > 24.0:
		return
		
	var horiz_vel := Vector2(velocity.x, velocity.z).length()
	if horiz_vel > 0.05:
		# Stride cadence follows actual speed so fast runners don't moonwalk
		walk_cycle += delta * walk_speed_factor * clampf(speed / 1.2, 0.8, 2.5)
		var bob := absf(sin(walk_cycle)) * 0.06
		visual_root.position.y = bob
		visual_root.rotation.z = sin(walk_cycle) * 0.04
		
		if state == State.CHASE or state == State.IDLE:
			if is_instance_valid(arm_left):
				arm_left.rotation.x = sin(walk_cycle) * 0.25 - 0.5
			if is_instance_valid(arm_right):
				arm_right.rotation.x = -sin(walk_cycle) * 0.25 - 0.5
		if is_instance_valid(leg_left):
			leg_left.rotation.x = -sin(walk_cycle) * 0.4
		if is_instance_valid(leg_right):
			leg_right.rotation.x = sin(walk_cycle) * 0.4
	else:
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 2.0)
		visual_root.rotation.z = move_toward(visual_root.rotation.z, 0.0, delta * 2.0)

func _set_head_color(col: Color) -> void:
	if not is_instance_valid(head_mesh):
		return
	if head_mesh is GeometryInstance3D:
		head_mesh.set_instance_shader_parameter("albedo_override", col)
	for child in head_mesh.find_children("", "MeshInstance3D", true, false):
		child.set_instance_shader_parameter("albedo_override", col)

func ignite(duration: float = 6.0) -> void:
	if is_dead:
		return
	is_burning = true
	burn_timer = maxf(burn_timer, duration)
	_set_head_color(Color(1.0, 0.35, 0.05))

func take_damage(amount: float, impulse: Vector3 = Vector3.ZERO) -> void:
	if is_dead or state == State.DEAD:
		return
	
	current_health -= amount
	knockback_velocity += impulse
	last_hit_impulse = impulse
	
	# Stagger on hit (bullets deliver stopping power)
	if stagger_duration > 0.0:
		state = State.STAGGER
		stagger_timer = stagger_duration
	
	# Flash red
	hit_flash_timer = 0.08
	_set_head_color(Color(1.0, 0.2, 0.2))
	
	# Directional blood splatter onto walls and floor
	if BloodManager.instance:
		BloodManager.instance.spawn_directional_blood(
			global_position,
			impulse if impulse.length() > 0.1 else Vector3.FORWARD,
			amount
		)
	
	if current_health <= 0.0:
		die()

func die() -> void:
	is_dead = true
	state = State.DEAD
	emit_signal("died", self)
	
	# Disable collisions immediately so player and swarms pass freely
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape:
		col_shape.set_deferred("disabled", true)
	
	# Splatter thick viscous blood (puddle + spray + 3D droplets)
	if BloodManager.instance:
		BloodManager.instance.spawn_thick_viscous_blood(global_position, last_hit_impulse)
	
	# Collapse & sink into the ground
	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual_root, "position:y", -0.7, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(visual_root, "rotation:x", deg_to_rad(-80.0), 0.4)
	tween.tween_property(visual_root, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	
	tween.chain().tween_callback(queue_free)

func _reset_materials() -> void:
	_set_head_color(Color.WHITE)
