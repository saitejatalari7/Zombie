extends Node3D
class_name AimTrajectoryArrow
## AimTrajectoryArrow.gd
## 3D visual aiming indicator for special abilities (Molotov Cocktail, Super Blast).
## Displays an emissive directional arrow, a 3D parabolic trajectory arc with
## flight beads, and a ground area-of-effect blast reticle at the exact landing spot.

@export var default_distance: float = 10.5
@export var min_distance: float = 3.5
@export var max_distance: float = 16.0

var is_aiming: bool = false
var current_ability: String = ""
var current_dir: Vector3 = Vector3.FORWARD
var current_dist: float = 10.5
var target_world_pos: Vector3 = Vector3.ZERO
var player_ref: Node3D = null

var shaft_mesh_instance: MeshInstance3D
var head_mesh_instance: MeshInstance3D
var reticle_ring: MeshInstance3D
var reticle_cross_h: MeshInstance3D
var reticle_cross_v: MeshInstance3D
var arc_dots_root: Node3D
var arc_dots: Array[MeshInstance3D] = []

var mat_molotov: StandardMaterial3D
var mat_blast: StandardMaterial3D

func _ready() -> void:
	top_level = true # Global transform eliminates parent rotation interference!
	_setup_materials()
	_build_arrow_geometry()
	visible = false

func setup_player(p: Node3D) -> void:
	player_ref = p

func _setup_materials() -> void:
	# Fiery orange-red for Molotov Cocktail
	mat_molotov = StandardMaterial3D.new()
	mat_molotov.resource_name = "AimMolotovMat"
	mat_molotov.albedo_color = Color(1.0, 0.45, 0.1, 0.95)
	mat_molotov.emission_enabled = true
	mat_molotov.emission = Color(1.0, 0.42, 0.08)
	mat_molotov.emission_energy_multiplier = 2.4
	mat_molotov.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_molotov.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_molotov.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Electric cyan for Super Blast / Rockets
	mat_blast = StandardMaterial3D.new()
	mat_blast.resource_name = "AimBlastMat"
	mat_blast.albedo_color = Color(0.18, 0.85, 1.0, 0.95)
	mat_blast.emission_enabled = true
	mat_blast.emission = Color(0.15, 0.82, 1.0)
	mat_blast.emission_energy_multiplier = 2.4
	mat_blast.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_blast.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_blast.cull_mode = BaseMaterial3D.CULL_DISABLED

func _build_arrow_geometry() -> void:
	# 1. Shaft (directional ground indicator)
	shaft_mesh_instance = MeshInstance3D.new()
	shaft_mesh_instance.name = "Shaft"
	var box := BoxMesh.new()
	box.size = Vector3(0.24, 0.04, 1.0)
	shaft_mesh_instance.mesh = box
	shaft_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shaft_mesh_instance)
	
	# 2. Arrowhead (Chevron / Prism at tip)
	head_mesh_instance = MeshInstance3D.new()
	head_mesh_instance.name = "ArrowHead"
	var prism := PrismMesh.new()
	prism.size = Vector3(0.95, 1.15, 0.06)
	head_mesh_instance.mesh = prism
	head_mesh_instance.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	head_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(head_mesh_instance)
	
	# 3. Ground Impact Reticle Ring (AOE landing zone)
	reticle_ring = MeshInstance3D.new()
	reticle_ring.name = "BlastReticleRing"
	reticle_ring.top_level = true # Positioned directly at target_world_pos
	var torus := TorusMesh.new()
	torus.inner_radius = 1.65
	torus.outer_radius = 1.85
	torus.rings = 24
	torus.ring_segments = 16
	reticle_ring.mesh = torus
	reticle_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(reticle_ring)
	
	# Reticle crossbars (+)
	reticle_cross_h = MeshInstance3D.new()
	var cross_box := BoxMesh.new()
	cross_box.size = Vector3(0.9, 0.04, 0.12)
	reticle_cross_h.mesh = cross_box
	reticle_cross_h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reticle_ring.add_child(reticle_cross_h)
	
	reticle_cross_v = MeshInstance3D.new()
	var cross_box_v := BoxMesh.new()
	cross_box_v.size = Vector3(0.12, 0.04, 0.9)
	reticle_cross_v.mesh = cross_box_v
	reticle_cross_v.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reticle_ring.add_child(reticle_cross_v)
	
	# 4. Parabolic Trajectory Arc Dots (10 glowing beads through the air)
	arc_dots_root = Node3D.new()
	arc_dots_root.name = "ArcDots"
	arc_dots_root.top_level = true
	add_child(arc_dots_root)
	
	var dot_sphere := SphereMesh.new()
	dot_sphere.radius = 0.08
	dot_sphere.height = 0.16
	dot_sphere.radial_segments = 8
	dot_sphere.rings = 6
	
	for i in range(12):
		var dot := MeshInstance3D.new()
		dot.mesh = dot_sphere
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arc_dots_root.add_child(dot)
		arc_dots.append(dot)

func start_aiming(ability: String, initial_dir: Vector3, initial_dist: float = 10.5) -> void:
	current_ability = ability
	is_aiming = true
	visible = true
	reticle_ring.visible = true
	arc_dots_root.visible = (ability == "molotov")
	
	var mat := mat_molotov if ability == "molotov" else mat_blast
	shaft_mesh_instance.material_override = mat
	head_mesh_instance.material_override = mat
	reticle_ring.material_override = mat
	reticle_cross_h.material_override = mat
	reticle_cross_v.material_override = mat
	for dot in arc_dots:
		dot.material_override = mat
	
	if is_instance_valid(player_ref):
		global_position = Vector3(player_ref.global_position.x, player_ref.global_position.y + 0.06, player_ref.global_position.z)
		
	update_aim(initial_dir, initial_dist)

func update_aim(dir: Vector3, dist: float = 10.5) -> void:
	if is_instance_valid(player_ref):
		global_position = Vector3(player_ref.global_position.x, player_ref.global_position.y + 0.06, player_ref.global_position.z)
		
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD
	
	current_dir = Vector3(dir.x, 0.0, dir.z).normalized()
	current_dist = clampf(dist, min_distance, max_distance)
	
	# Arrow orientation angle in world coordinates
	var angle := atan2(-current_dir.x, -current_dir.z)
	rotation.y = angle
	
	# Ground elevation detection at target point
	var raw_target := global_position + (current_dir * current_dist)
	var floor_y := _detect_ground_y(raw_target)
	target_world_pos = Vector3(raw_target.x, floor_y, raw_target.z)
	
	# Shaft stretches along local -Z axis
	var shaft_len := current_dist - 1.2
	shaft_mesh_instance.scale.z = shaft_len
	shaft_mesh_instance.position = Vector3(0.0, 0.0, -shaft_len * 0.5 - 0.4)
	
	# Arrowhead at the tip
	head_mesh_instance.position = Vector3(0.0, 0.0, -current_dist + 0.5)
	
	# Place reticle ring at exact target world position
	reticle_ring.global_position = target_world_pos + Vector3(0.0, 0.05, 0.0)
	
	# Position parabolic trajectory beads in 3D air
	_update_trajectory_arc()

func update_aim_world_target(world_target: Vector3) -> void:
	if is_instance_valid(player_ref):
		global_position = Vector3(player_ref.global_position.x, player_ref.global_position.y + 0.06, player_ref.global_position.z)
		
	var diff := world_target - global_position
	diff.y = 0.0
	var dist := clampf(diff.length(), min_distance, max_distance)
	var dir := diff.normalized() if diff.length_squared() > 0.01 else -global_transform.basis.z
	update_aim(dir, dist)

func _detect_ground_y(test_pos: Vector3) -> float:
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return global_position.y
	var query := PhysicsRayQueryParameters3D.create(test_pos + Vector3(0, 5.0, 0), test_pos + Vector3(0, -5.0, 0), 1)
	if is_instance_valid(player_ref):
		query.exclude = [player_ref.get_rid()]
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		return hit["position"].y
	return global_position.y

func _update_trajectory_arc() -> void:
	if not arc_dots_root.visible:
		return
	var p_start := global_position + Vector3(0.0, 1.2, 0.0)
	var p_end := target_world_pos + Vector3(0.0, 0.05, 0.0)
	var delta_y := p_end.y - p_start.y
	var arc_h := maxf(1.6, delta_y + 1.2)
	
	var count := arc_dots.size()
	for i in range(count):
		var t := float(i + 1) / float(count + 1)
		var horiz_pos := p_start.lerp(p_end, t)
		var vert_offset := 4.0 * arc_h * t * (1.0 - t)
		arc_dots[i].global_position = Vector3(horiz_pos.x, horiz_pos.y + vert_offset, horiz_pos.z)

func get_aim_direction() -> Vector3:
	return current_dir

func get_aim_target_world() -> Vector3:
	return target_world_pos

func stop_aiming() -> void:
	is_aiming = false
	visible = false
	reticle_ring.visible = false
	arc_dots_root.visible = false
