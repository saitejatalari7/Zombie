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
			var area: Area3D = active_sector_node.extraction_zone
			area.body_entered.connect(_on_extraction_zone_entered)
			
		print("[Main] Sector %d loaded successfully: %s" % [sector_id, active_sector_node.sector_name])

func _on_extraction_zone_entered(body: Node3D) -> void:
	if body == player:
		print("[Main] Player reached extraction zone!")
		if hud:
			hud.show_street_cleared_banner()

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
