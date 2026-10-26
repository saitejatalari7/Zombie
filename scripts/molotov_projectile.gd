extends Node3D
class_name MolotovProjectile
## MolotovProjectile.gd
## High-precision ballistic Molotov cocktail that flies along an authentic
## parabolic arc and lands EXACTLY at the player's aimed target reticle position.

var velocity: Vector3 = Vector3.ZERO
var target_pos: Vector3 = Vector3.ZERO
var start_pos: Vector3 = Vector3.ZERO
var flight_time: float = 0.8
var elapsed_time: float = 0.0
var gravity: float = 22.0
var spin_axis: Vector3 = Vector3.RIGHT
var spin_speed: float = 16.0
var fire_patch_scene := preload("res://scenes/fire_patch.tscn")
var impact_scene := preload("res://scenes/bullet_impact.tscn")
var exploded: bool = false

## Precision target initialization: calculates exact velocities to land at p_target_pos
func init_target(p_spawn_pos: Vector3, p_target_pos: Vector3) -> void:
	global_position = p_spawn_pos
	start_pos = p_spawn_pos
	target_pos = p_target_pos
	exploded = false
	elapsed_time = 0.0
	
	var diff_xz := Vector3(target_pos.x - start_pos.x, 0.0, target_pos.z - start_pos.z)
	var dist_xz := diff_xz.length()
	var dir_xz := diff_xz.normalized() if dist_xz > 0.01 else Vector3.FORWARD
	var delta_y := target_pos.y - start_pos.y
	
	# Determine peak arc height above the higher point
	var arc_height := maxf(1.6, delta_y + 1.2)
	var vy_initial := sqrt(2.0 * gravity * arc_height)
	var t_apex := vy_initial / gravity
	var fall_h := arc_height - delta_y
	var t_fall := sqrt(maxf(0.01, 2.0 * fall_h / gravity))
	flight_time = maxf(0.35, t_apex + t_fall)
	
	# Exact horizontal velocity required to reach target in flight_time
	var v_horizontal := dist_xz / flight_time
	velocity = (dir_xz * v_horizontal) + (Vector3.UP * vy_initial)
	spin_axis = Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), randf_range(-1, 1)).normalized()

## Fallback / direction-based initialization
func init(p_spawn_pos: Vector3, throw_dir: Vector3) -> void:
	var flat_dir := Vector3(throw_dir.x, 0, throw_dir.z).normalized()
	init_target(p_spawn_pos, p_spawn_pos + flat_dir * 10.5)

func _physics_process(delta: float) -> void:
	if exploded:
		return
	
	elapsed_time += delta
	var prev_pos := global_position
	velocity.y -= gravity * delta
	global_position += velocity * delta
	rotate(spin_axis, spin_speed * delta)
	
	# Obstacle raycast collision along the step
	var space_state := get_world_3d().direct_space_state
	if space_state:
		var step_query := PhysicsRayQueryParameters3D.create(prev_pos, global_position, 1)
		var hit := space_state.intersect_ray(step_query)
		if not hit.is_empty():
			var hit_norm: Vector3 = hit["normal"]
			if hit_norm.dot(Vector3.UP) > 0.5:
				# Hitting floor/ground near target: land right at targeted spot
				global_position = target_pos
			else:
				# Hitting a vertical barrier or wall: shatter and drop fire pool to floor below
				global_position = hit["position"]
				target_pos = hit["position"]
				var down_query := PhysicsRayQueryParameters3D.create(hit["position"], hit["position"] + Vector3.DOWN * 6.0, 1)
				var down_hit := space_state.intersect_ray(down_query)
				if not down_hit.is_empty():
					target_pos.y = down_hit["position"].y
				else:
					target_pos.y = 0.05
			explode()
			return
	
	# Reached target flight time or descended past target ground elevation
	if elapsed_time >= flight_time or (velocity.y < 0.0 and global_position.y <= target_pos.y + 0.12):
		global_position = target_pos
		explode()
		return
	
	# Direct zombie hit check
	var zombies := get_tree().get_nodes_in_group("zombies")
	for z in zombies:
		if is_instance_valid(z) and z is Node3D and not z.get("is_dead"):
			var d: float = (z.global_position + Vector3(0, 0.8, 0)).distance_to(global_position)
			if d < 1.0:
				explode()
				return

func explode() -> void:
	if exploded:
		return
	exploded = true
	AudioManager.play_sfx_near("molotov_shatter", global_position, 0.0)
	
	# Spawn ground fire patch at exact impact elevation
	var patch: Node3D = fire_patch_scene.instantiate()
	get_parent().add_child(patch)
	patch.global_position = Vector3(global_position.x, target_pos.y + 0.05, global_position.z)
	
	# Spawn glass shatter / spark effect
	var impact: Node3D = impact_scene.instantiate()
	get_parent().add_child(impact)
	impact.setup(global_position, Vector3.UP)
	
	queue_free()
