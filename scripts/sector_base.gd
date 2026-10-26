extends Node3D
class_name SectorBase
## SectorBase.gd
## Base controller for the 4 Tactical City Sectors in PROTOCOL: CRIMSON.
## Manages sector boundaries, player spawn point, zombie spawn markers,
## extraction extraction zone, NavMesh, and Day/Night lighting setup.

@export var sector_id: int = 1
@export var sector_name: String = "SECTOR 01: RESIDENTIAL QUARANTINE"
@export var is_night_sector: bool = false
@export var sector_bounds: Rect2 = Rect2(Vector2(-35, -55), Vector2(70, 110))

@onready var world_env: WorldEnvironment = get_node_or_null("WorldEnvironment")
@onready var sun: DirectionalLight3D = get_node_or_null("DirectionalLight3D")
@onready var player_spawn: Marker3D = get_node_or_null("PlayerSpawn")
@onready var extraction_zone: Node3D = get_node_or_null("ExtractionZone")
@onready var spawn_points_root: Node3D = get_node_or_null("ZombieSpawners")
@onready var streetlamps_root: Node3D = get_node_or_null("Props/Streetlamps")

var streetlamp_lights: Array[OmniLight3D] = []

const ProceduralVegetation = preload("res://scripts/procedural_vegetation.gd")

func _ready() -> void:
	# Configure DayNightManager for this sector
	var dnm = get_node_or_null("/root/DayNightManager")
	if dnm:
		dnm.set_sector_mode(sector_id, is_night_sector)
		if world_env and sun:
			dnm.apply_to_environment(world_env.environment, sun)
		dnm.streetlamp_flicker_tick.connect(_on_streetlamp_flicker)
	
	# Cache all streetlamp OmniLight3D nodes
	_cache_streetlamp_lights()
	
	# Automatically generate collision for low-poly prop meshes if needed
	_ensure_prop_collisions()
	
	# Apply tactical blue material to all civilian cars
	_apply_vehicle_materials()
	
	# Ensure 5-6 abandoned transit buses exist as tactical chokepoints
	_ensure_transit_buses()
	
	# Ensure procedural dried grass bushes are scattered across curbs and walls
	_ensure_procedural_vegetation()
	
	print("[Sector %d: %s] Initialized. Night Mode: %s. Bounds: %s" % [
		sector_id, sector_name, str(is_night_sector), str(sector_bounds)
	])

func _apply_vehicle_materials() -> void:
	var mat_car_blue := load("res://assets/materials/mat_car_blue.tres") as StandardMaterial3D
	if not mat_car_blue:
		return
	for n in find_children("*", "Node3D", true, false):
		var n_name := n.name.to_lower()
		if "car" in n_name or "sedan" in n_name or "hatch" in n_name:
			for mesh_inst in n.find_children("*", "MeshInstance3D", true, false):
				if mesh_inst is MeshInstance3D:
					var m_name := mesh_inst.name.to_lower()
					if not ("whl" in m_name or "wheel" in m_name or "windshield" in m_name or "glass" in m_name or "rearwin" in m_name or "sidewin" in m_name):
						mesh_inst.material_override = mat_car_blue

func _ensure_transit_buses() -> void:
	var bus_configs = [
		{"name": "TransitBus_North_2", "pos": Vector3(1.8, 0.0, -31.5), "rot": 15.0},
		{"name": "TransitBus_East_3", "pos": Vector3(20.5, 0.0, 4.0), "rot": 82.0},
		{"name": "TransitBus_Mid_4", "pos": Vector3(-2.2, 0.0, -11.0), "rot": -8.0},
		{"name": "TransitBus_Terrace_5", "pos": Vector3(-14.5, 3.2, -18.0), "rot": 34.0},
		{"name": "TransitBus_Terminal_6", "pos": Vector3(12.5, 0.0, 29.0), "rot": -55.0}
	]
	var props = get_node_or_null("NavigationRegion3D/Props")
	if not props:
		props = get_node_or_null("Props")
	if not props:
		props = self
	
	var bus_scene = load("res://assets/models/props/transit_bus.glb") as PackedScene
	if not bus_scene:
		return
		
	for cfg in bus_configs:
		if not find_child(cfg["name"], true, false):
			var b = bus_scene.instantiate() as Node3D
			b.name = cfg["name"]
			b.position = cfg["pos"]
			b.rotation_degrees.y = cfg["rot"]
			props.add_child(b)
			# Box collider
			var body = StaticBody3D.new()
			body.name = "Col_" + cfg["name"]
			body.position = cfg["pos"] + Vector3(0, 1.6, 0)
			body.rotation_degrees.y = cfg["rot"]
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(3.0, 3.2, 10.5)
			col.shape = box
			body.add_child(col)
			props.add_child(body)

func _ensure_procedural_vegetation() -> void:
	if not find_child("ProceduralDriedGrass", true, false):
		var grass_mmi = ProceduralVegetation.build_dried_grass_multimesh(160)
		var props = get_node_or_null("NavigationRegion3D/Props")
		if not props:
			props = get_node_or_null("Props")
		if props:
			props.add_child(grass_mmi)
		else:
			add_child(grass_mmi)

func _cache_streetlamp_lights() -> void:
	streetlamp_lights.clear()
	var lights := find_children("*", "OmniLight3D", true, false)
	for l in lights:
		if l is OmniLight3D:
			streetlamp_lights.append(l)

func _on_streetlamp_flicker(energy_mult: float) -> void:
	if is_night_sector:
		for lamp in streetlamp_lights:
			if is_instance_valid(lamp):
				lamp.light_energy = 2.4 * energy_mult

func get_spawn_point_transforms() -> Array[Transform3D]:
	var points: Array[Transform3D] = []
	if spawn_points_root:
		for child in spawn_points_root.get_children():
			if child is Marker3D or child is Node3D:
				points.append(child.global_transform)
	return points

func get_spawn_point_nodes() -> Array[Node3D]:
	var nodes: Array[Node3D] = []
	if spawn_points_root:
		for child in spawn_points_root.get_children():
			if child is Node3D:
				nodes.append(child)
	return nodes

func get_player_spawn_pos() -> Vector3:
	if player_spawn:
		return player_spawn.global_position
	return Vector3.ZERO

func _ensure_prop_collisions() -> void:
	# Recursively ensure that MeshInstance3D nodes in Props have StaticBody3D collision
	var props_root := get_node_or_null("Props")
	if not props_root:
		return
	
	_create_collisions_recursive(props_root)

func _create_collisions_recursive(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		if node.get_parent() is StaticBody3D:
			return # Already has body
		var has_body_child := false
		for c in node.get_children():
			if c is StaticBody3D:
				has_body_child = true
				break
		if not has_body_child and not node.name.begins_with("NoCol"):
			var body := StaticBody3D.new()
			body.name = node.name + "_Collision"
			var shape := CollisionShape3D.new()
			shape.shape = node.mesh.create_convex_shape(true, false)
			body.add_child(shape)
			node.add_child(body)
			
	for child in node.get_children():
		_create_collisions_recursive(child)
