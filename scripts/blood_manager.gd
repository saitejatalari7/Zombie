extends Node
class_name BloodManager
## BloodManager.gd
## High-performance persistent blood splatter, wall projection, 6m blast craters,
## pre-allocated particle pooling, and scent footprint tracking system for PROTOCOL: CRIMSON.

static var instance: BloodManager

var blood_decal_scene := preload("res://scenes/blood_decal.tscn")
var footprint_decal_scene := preload("res://scenes/footprint_decal.tscn")
var blood_burst_scene := preload("res://scenes/blood_burst.tscn")
var impact_scene := preload("res://scenes/bullet_impact.tscn")

var max_decals: int = 50
var active_decals: Array[Node] = []
var blood_puddles: Array[Vector3] = []
var blood_puddle_radii: Array[float] = []  # parallel to blood_puddles: how far each pool reaches
var active_footprints: Array[Dictionary] = [] # [{ "pos": Vector3, "strength": float, "time": float }]

# Particle Pools (Zero runtime instantiation hitch)
const POOL_SIZE: int = 12
var blood_burst_pool: Array[Node3D] = []
var impact_pool: Array[Node3D] = []
var next_burst_idx: int = 0
var next_impact_idx: int = 0

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		max_decals = gm.get_blood_decal_limit()  # Settings: blood amount FULL / LOW
	_init_pools()

func _init_pools() -> void:
	if not blood_burst_pool.is_empty():
		return
	for i in range(POOL_SIZE):
		var b: Node3D = blood_burst_scene.instantiate()
		add_child(b)
		var bp: GPUParticles3D = b.get_node_or_null("GPUParticles3D")
		if bp: bp.emitting = false
		blood_burst_pool.append(b)
		
		var imp: Node3D = impact_scene.instantiate()
		add_child(imp)
		var ip: GPUParticles3D = imp.get_node_or_null("GPUParticles3D")
		if ip: ip.emitting = false
		impact_pool.append(imp)

func spawn_burst(pos: Vector3) -> void:
	if blood_burst_pool.is_empty():
		_init_pools()
	if blood_burst_pool.is_empty():
		return
	var b := blood_burst_pool[next_burst_idx]
	next_burst_idx = (next_burst_idx + 1) % POOL_SIZE
	if b.has_method("emit_burst"):
		b.emit_burst(pos)
	else:
		b.global_position = pos
		var bp: GPUParticles3D = b.get_node_or_null("GPUParticles3D")
		if bp: bp.restart()

func spawn_impact(pos: Vector3, normal: Vector3) -> void:
	if impact_pool.is_empty():
		_init_pools()
	if impact_pool.is_empty():
		return
	var imp := impact_pool[next_impact_idx]
	next_impact_idx = (next_impact_idx + 1) % POOL_SIZE
	if imp.has_method("emit_impact"):
		imp.emit_impact(pos, normal)
	else:
		imp.global_position = pos
		var ip: GPUParticles3D = imp.get_node_or_null("GPUParticles3D")
		if ip: ip.restart()

func _process(delta: float) -> void:
	# Decay footprint scent records
	for i in range(active_footprints.size() - 1, -1, -1):
		active_footprints[i]["time"] -= delta
		active_footprints[i]["strength"] = maxf(0.0, active_footprints[i]["strength"] - delta * 0.25)
		if active_footprints[i]["time"] <= 0.0:
			active_footprints.remove_at(i)

func spawn_splatter(pos: Vector3, normal: Vector3 = Vector3.UP, scale_mult: float = 1.0, is_puddle: bool = false, is_wall: bool = false) -> Decal:
	if active_decals.size() >= max_decals:
		var oldest = active_decals.pop_front()  # untyped: may already be freed (faded out)
		if is_instance_valid(oldest):
			oldest.queue_free()
	
	var decal: Decal = blood_decal_scene.instantiate()
	get_parent().add_child(decal)
	decal.global_position = pos
	
	# Align decal projection to surface normal
	if normal.abs().dot(Vector3.UP) < 0.95:
		# Wall projection: align decal along normal
		var forward := normal.normalized()
		var up := Vector3.UP
		if absf(forward.dot(up)) > 0.9:
			up = Vector3.RIGHT
		decal.look_at(pos + forward, up)
		if decal.has_method("setup_wall"):
			decal.setup_wall(scale_mult)
		else:
			decal.size = Vector3(scale_mult * 1.1, scale_mult * 1.8, 1.0)
	else:
		if decal.has_method("setup"):
			decal.setup(randf_range(1.0, 1.8) * scale_mult, is_puddle)
		else:
			decal.size = Vector3(scale_mult * 1.4, 1.2, scale_mult * 1.4)
			decal.rotate_y(randf_range(0, TAU))
	
	active_decals.append(decal)
	
	decal.upper_fade = 0.001
	decal.lower_fade = 0.001
	decal.normal_fade = 0.0
	decal.distance_fade_enabled = false
	
	if is_puddle:
		_add_puddle(pos, 1.35 * maxf(1.0, scale_mult / 1.6))
			
	return decal

## Wall & Floor directional projection with raycast detection
func spawn_directional_blood(hit_pos: Vector3, shot_dir: Vector3, damage: float = 34.0, spawn_floor_puddle: bool = true) -> void:
	var scale_factor: float = clampf(damage / 34.0, 0.8, 2.2)
	
	# 1. 3D physical burst particles from pool
	spawn_burst(hit_pos + Vector3(0, 0.8, 0))
	
	# 2. Floor puddle at impact
	if spawn_floor_puddle:
		spawn_splatter(hit_pos, Vector3.UP, scale_factor * 1.2, true)
	
	# 3. Raycast to detect walls behind the target along shot vector (only for heavier hits to prevent raycast spam)
	if damage >= 28.0:
		var space_state: PhysicsDirectSpaceState3D = null
		var parent := get_parent()
		if parent is Node3D and (parent as Node3D).get_world_3d():
			space_state = (parent as Node3D).get_world_3d().direct_space_state
		elif is_inside_tree():
			var vp := get_viewport()
			if vp and vp.find_world_3d():
				space_state = vp.find_world_3d().direct_space_state
				
		var wall_hit: bool = false
		if space_state != null:
			var ray_start := hit_pos + Vector3(0, 0.8, 0)
			var ray_dir := (shot_dir.normalized() + Vector3(0, -0.15, 0)).normalized()
			var ray_end := ray_start + (ray_dir * 4.5)
			
			var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, 1) # Environment mask 1
			var hit := space_state.intersect_ray(query)
			
			if not hit.is_empty():
				wall_hit = true
				var wall_pos: Vector3 = hit["position"]
				var wall_norm: Vector3 = hit["normal"]
				if wall_norm.dot(Vector3.UP) < 0.6:
					spawn_splatter(wall_pos, wall_norm, scale_factor * 1.3, false, true)
				else:
					spawn_splatter(wall_pos, wall_norm, scale_factor, false, false)
					
		if not wall_hit:
			var ground_spray := hit_pos + (shot_dir.normalized() * randf_range(1.0, 1.8))
			spawn_splatter(ground_spray, Vector3.UP, scale_factor * 0.8, false)

## 6-Meter Massive Blood Crater stamped by Heavy Rocket Launcher / Super Blast
func spawn_massive_blood_crater(center_pos: Vector3, diameter: float = 6.0) -> void:
	if active_decals.size() >= max_decals:
		var oldest = active_decals.pop_front()  # untyped: may already be freed (faded out)
		if is_instance_valid(oldest):
			oldest.queue_free()
			
	var decal: Decal = blood_decal_scene.instantiate()
	get_parent().add_child(decal)
	decal.global_position = center_pos + Vector3(0, 0.05, 0)
	decal.size = Vector3(diameter, 1.5, diameter)
	decal.modulate = Color(0.95, 0.02, 0.06, 0.98) # Ultra glossy crimson
	if decal.has_method("setup"):
		decal.setup(diameter, true)
	active_decals.append(decal)
	
	_add_puddle(center_pos, diameter * 0.5)
	
	# Radial satellite spatters in a 360 degree ring (limited to 8 for max FPS)
	var count := 8
	for i in range(count):
		var ang := (float(i) / float(count)) * TAU + randf_range(-0.15, 0.15)
		var dist := randf_range(diameter * 0.45, diameter * 0.9)
		var splat_pos := center_pos + Vector3(cos(ang) * dist, 0.05, sin(ang) * dist)
		spawn_splatter(splat_pos, Vector3.UP, randf_range(1.2, 1.8), false)

func spawn_footprint(pos: Vector3, heading_yaw: float, strength: float) -> void:
	if active_decals.size() >= max_decals:
		var oldest = active_decals.pop_front()  # untyped: may already be freed (faded out)
		if is_instance_valid(oldest):
			oldest.queue_free()
	
	var foot: Decal = footprint_decal_scene.instantiate()
	get_parent().add_child(foot)
	foot.global_position = pos + Vector3(0, 0.05, 0)
	if foot.has_method("setup"):
		foot.setup(heading_yaw, strength)
	
	active_decals.append(foot)
	
	# Register in scent memory for Runner zombies (4s lifetime)
	active_footprints.append({
		"pos": pos,
		"strength": strength,
		"time": 4.0
	})
	if active_footprints.size() > 30:
		active_footprints.pop_front()

## Query nearest blood footprint scent for Runner zombies
func get_nearest_footprint(pos: Vector3, max_dist: float = 14.0) -> Dictionary:
	var best_dist := max_dist
	var best_data: Dictionary = {}
	for fp in active_footprints:
		var d := pos.distance_to(fp["pos"])
		if d < best_dist and fp["strength"] > 0.15:
			best_dist = d
			best_data = fp
	return best_data

func _add_puddle(pos: Vector3, radius: float) -> void:
	blood_puddles.append(pos)
	blood_puddle_radii.append(radius)
	if blood_puddles.size() > 25:
		blood_puddles.pop_front()
		blood_puddle_radii.pop_front()

func is_stepping_in_blood(pos: Vector3, radius_check: float = 1.35) -> bool:
	for i in range(blood_puddles.size()):
		var reach := maxf(radius_check, blood_puddle_radii[i]) if i < blood_puddle_radii.size() else radius_check
		if pos.distance_to(blood_puddles[i]) <= reach:
			return true
	return false

## pool_scale > 1 makes a wider death pool (Hemorrhage Rounds).
func spawn_thick_viscous_blood(pos: Vector3, impulse: Vector3 = Vector3.ZERO, pool_scale: float = 1.0) -> void:
	spawn_splatter(pos, Vector3.UP, 1.6 * pool_scale, true)
	spawn_burst(pos + Vector3(0, 0.4, 0))
	if impulse.length() > 0.5:
		spawn_directional_blood(pos, impulse.normalized(), 40.0, false)

func spawn_blast_splatter(center_pos: Vector3, radius: float = 3.5, count: int = 6) -> void:
	spawn_splatter(center_pos, Vector3.UP, 1.8, true)
	for i in range(count):
		var ang := randf_range(0.0, TAU)
		var dist := randf_range(radius * 0.3, radius * 0.9)
		var splat_pos := center_pos + Vector3(cos(ang) * dist, 0.05, sin(ang) * dist)
		spawn_splatter(splat_pos, Vector3.UP, randf_range(0.8, 1.4), false)
