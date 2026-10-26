extends Node3D
## Main.gd
## Tactical Sector Runtime Coordinator for PROTOCOL: CRIMSON.
## Spawns the active Sector selected from the Command Board,
## positions the player, sets boundaries, configures DayNightManager,
## and connects Spawners and Extraction alerts.

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var player: Player = $Player
@onready var spawner: ZombieSpawner = $ZombieSpawner
@onready var hud: MobileHUD = $MobileHUD
@onready var sun: DirectionalLight3D = $DirectionalLight3D

var waypoint_arrow_scene := preload("res://scenes/waypoint_arrow.tscn")

const SECTOR_SCENES: Dictionary = {
	1: preload("res://scenes/sectors/sector_1_residential.tscn"),
	2: preload("res://scenes/sectors/sector_2_transit.tscn"),
	3: preload("res://scenes/sectors/sector_3_industrial.tscn"),
	4: preload("res://scenes/sectors/sector_4_research.tscn")
}

var active_sector_node: SectorBase = null

# ─── Mission State ───
var kills_required: int = 25
var objective_complete: bool = false
var mission_over: bool = false
var extraction_area: Area3D = null
var extraction_marker: Node3D = null

func _ready() -> void:
	# Selected golden/dramatic raking sunlight configuration (User Pick)
	sun.rotation_degrees = Vector3(-45.0, 106.0, 0.0)
	sun.light_energy = 1.95
	sun.directional_shadow_max_distance = 100.0
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = 0.18
	
	# Determine sector to load
	var gm = get_node_or_null("/root/GameManager")
	var sec_id: int = gm.current_sector if gm else 1
	_load_tactical_sector(sec_id)
	
	hud.setup(player, spawner)
	spawner.setup_player(player)
	_start_mission(sec_id)
	
	var sun_panel = get_node_or_null("SunlightControlPanel")
	if sun_panel and sun_panel.has_method("setup"):
		sun_panel.setup(sun, world_env)
	
	# Connect legacy WoodenBarricade if present in legacy whitebox map
	var barricade := get_node_or_null("EnvironmentMap/WoodenBarricade") as WoodenBarricade
	if barricade:
		barricade.barricade_broken.connect(_on_barricade_broken)
	
	call_deferred("_setup_reference_blood_splatters")

func _load_tactical_sector(sector_id: int) -> void:
	if not SECTOR_SCENES.has(sector_id):
		sector_id = 1
	
	# Hide or remove prototype EnvironmentMap if present
	var legacy_env := get_node_or_null("EnvironmentMap")
	if legacy_env:
		legacy_env.visible = false
		legacy_env.queue_free()
	
	var scene: PackedScene = SECTOR_SCENES[sector_id]
	active_sector_node = scene.instantiate() as SectorBase
	add_child(active_sector_node)
	
	# Position Player at sector spawn point and set bounds
	if active_sector_node:
		var spawn_pos := active_sector_node.get_player_spawn_pos()
		player.global_position = spawn_pos
		player.sector_bounds = active_sector_node.sector_bounds
		
		# Point zombie spawner to sector spawn markers
		var spawn_nodes := active_sector_node.get_spawn_point_nodes()
		if not spawn_nodes.is_empty():
			for c in spawner.get_children():
				c.queue_free()
			spawner.spawn_points.clear()
			for child in spawn_nodes:
				var m := Marker3D.new()
				m.name = child.name
				spawner.add_child(m)
				m.global_transform = child.global_transform
				spawner.spawn_points.append(m)
			if spawner.has_method("refresh_spawn_points"):
				spawner.refresh_spawn_points()
		
		# Configure lighting via DayNightManager
		var dnm = get_node_or_null("/root/DayNightManager")
		if dnm:
			dnm.set_sector_mode(sector_id, active_sector_node.is_night_sector)
			if world_env and sun:
				dnm.apply_to_environment(world_env.environment, sun)
		
		# Connect extraction zone
		if active_sector_node.extraction_zone and active_sector_node.extraction_zone is Area3D:
			extraction_area = active_sector_node.extraction_zone
			_configure_extraction_zone(extraction_area)
			extraction_area.body_entered.connect(_on_extraction_zone_entered)
			
		print("[Main] Sector %d loaded successfully: %s" % [sector_id, active_sector_node.sector_name])

# ─── Mission Flow: clear quota → extraction unlocks → reach LZ → debrief ───
func _start_mission(sector_id: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	kills_required = gm.get_contract(sector_id)["kills_required"]
	gm.start_mission_run()
	gm.in_run_kills_changed.connect(_on_run_kills_changed)
	player.died.connect(_on_player_died)
	_on_run_kills_changed(0)

func _configure_extraction_zone(area: Area3D) -> void:
	# Player lives on physics layer 2; sector scenes only listened on layer 1.
	area.set_collision_mask_value(2, true)
	area.monitoring = true
	
	var has_shape := false
	for c in area.get_children():
		if c is CollisionShape3D:
			has_shape = true
	if not has_shape:
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(6.0, 4.0, 6.0)
		col.shape = box
		col.position = Vector3(0.0, 1.0, 0.0)
		area.add_child(col)
	
	# Evac beacon: hidden until the contract objective is met
	extraction_marker = Node3D.new()
	extraction_marker.name = "EvacBeacon"
	area.add_child(extraction_marker)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.05, 0.12, 0.28)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.6
	beam_mesh.bottom_radius = 0.6
	beam_mesh.height = 14.0
	beam_mesh.material = mat
	var beam := MeshInstance3D.new()
	beam.mesh = beam_mesh
	beam.position = Vector3(0.0, 7.0, 0.0)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extraction_marker.add_child(beam)
	var pad_mesh := CylinderMesh.new()
	pad_mesh.top_radius = 3.0
	pad_mesh.bottom_radius = 3.0
	pad_mesh.height = 0.04
	pad_mesh.material = mat
	var pad := MeshInstance3D.new()
	pad.mesh = pad_mesh
	pad.position = Vector3(0.0, 0.05, 0.0)
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extraction_marker.add_child(pad)
	extraction_marker.visible = false

func _on_run_kills_changed(run_kills: int) -> void:
	if objective_complete or mission_over:
		return
	if run_kills < kills_required:
		hud.set_mission_status("ELIMINATE HOSTILES  %d / %d" % [run_kills, kills_required])
		return
	
	objective_complete = true
	hud.set_mission_status("EVAC UNLOCKED — REACH THE LZ ▲", Color(1.0, 0.8, 0.1))
	hud.show_banner("⚡ ZONE CLEARED — EVAC UNLOCKED", "Follow the red beacon to the extraction LZ ➔")
	if is_instance_valid(extraction_marker):
		extraction_marker.visible = true
	# Already standing in the LZ when the quota completes
	if extraction_area and extraction_area.overlaps_body(player):
		_on_extraction_zone_entered(player)

func _on_extraction_zone_entered(body: Node3D) -> void:
	if body != player or mission_over or player.is_dead:
		return
	if not objective_complete:
		hud.show_banner("LZ LOCKED", "Eliminate %d hostiles before evac" % kills_required)
		return
	
	mission_over = true
	print("[Main] Player extracted!")
	var gm = get_node_or_null("/root/GameManager")
	var summary: Dictionary = gm.complete_mission() if gm else {}
	hud.show_mission_result(summary)

func _on_player_died() -> void:
	if mission_over:
		return
	mission_over = true
	hud.set_mission_status("OPERATIVE DOWN", Color(1.0, 0.2, 0.2))
	# Short beat so the death registers before the debrief.
	# (connect, not await: the connection drops cleanly if the scene is left first)
	get_tree().create_timer(1.6).timeout.connect(_resolve_death)

func _resolve_death() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var summary: Dictionary = gm.fail_mission() if gm else {}
	hud.show_mission_result(summary)

func _on_barricade_broken() -> void:
	if hud:
		hud.show_street_cleared_banner()
	var arrow: Node3D = waypoint_arrow_scene.instantiate()
	add_child(arrow)
	arrow.global_position = Vector3(0.0, 3.2, -14.0)

func _setup_reference_blood_splatters() -> void:
	if not BloodManager.instance:
		return
	
	# Atmospheric initial blood decals
	BloodManager.instance.spawn_splatter(Vector3(2.1, 0.05, 1.8), Vector3.UP, 3.2, true)
	BloodManager.instance.spawn_splatter(Vector3(1.3, 0.05, 2.2), Vector3.UP, 1.8, false)
	BloodManager.instance.spawn_splatter(Vector3(-0.8, 0.05, 6.5), Vector3.UP, 2.6, true)
