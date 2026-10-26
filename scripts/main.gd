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
	1: preload("res://scenes/sectors/sector_1_quarantine_block.tscn"),
	2: preload("res://scenes/sectors/sector_2_transit.tscn"),
	3: preload("res://scenes/sectors/sector_3_industrial.tscn"),
	4: preload("res://scenes/sectors/sector_4_research.tscn")
}

var active_sector_node: SectorBase = null

# ─── Mission State ───
var job: MissionJob = null
var objective_complete: bool = false
var mission_over: bool = false
var extraction_area: Area3D = null
var extraction_marker: Node3D = null

# ─── Evac Hold: once the LZ is open, stand in it until the countdown ends ───
var evac_active: bool = false
var evac_hold_time: float = 20.0
var evac_time_left: float = 0.0
var player_in_lz: bool = false

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
	spawner.configure_for_sector(sec_id)
	_start_mission(sec_id)
	
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
	# The contract chooses which layout of the sector to play
	var gm = get_node_or_null("/root/GameManager")
	if gm and active_sector_node is LayoutSector:
		active_sector_node.set("layout_id", String(gm.get_active_contract().get("layout", "")))
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
		
		spawner.spawn_opening(
			active_sector_node.get_marker_nodes("OpeningMob"),
			active_sector_node.get_marker_nodes("PickupSpawns")
		)
		
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
			extraction_area.body_exited.connect(_on_extraction_zone_exited)
			
		print("[Main] Sector %d loaded successfully: %s" % [sector_id, active_sector_node.sector_name])

# ─── Mission Flow: job objective → extraction unlocks → reach LZ → debrief ───
func _start_mission(_sector_id: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var contract: Dictionary = gm.get_active_contract()
	gm.start_mission_run()
	
	job = MissionJob.create(contract.get("job", "kill_quota"))
	job.name = "MissionJob"
	job.setup(contract, active_sector_node, player)
	job.spawner = spawner
	add_child(job)
	job.status_changed.connect(_on_job_status_changed)
	job.objective_met.connect(_on_objective_met)
	job.radio_message.connect(func(text: String): hud.show_radio("OVERWATCH", text))
	job.progress_changed.connect(_on_job_progress)
	if job.has_signal("hive_destroyed"):
		job.connect("hive_destroyed", _on_hive_destroyed)
	gm.in_run_kills_changed.connect(job.on_run_kills_changed)
	player.died.connect(_on_player_died)
	job.start()
	_spawn_intel(gm)

func _on_hive_destroyed(size_class: String, reward: Dictionary) -> void:
	var names := {"S": "HIVE POD", "M": "HIVE", "L": "HIVE MOUND"}
	var sub := "+%d coins" % int(reward.get("sc", 0))
	if int(reward.get("rc", 0)) > 0:
		sub += "  +%d core" % int(reward["rc"])
	hud.show_banner("%s DESTROYED" % names.get(size_class, "HIVE"), sub)

func _on_job_progress(fraction: float, active: bool) -> void:
	if fraction <= 0.0 and not active:
		hud.hide_evac_progress()
	else:
		hud.show_evac_progress(fraction, active)

## Optional intel documents: only the ones this save hasn't found yet.
func _spawn_intel(gm) -> void:
	for m in active_sector_node.get_marker_nodes("IntelSpots"):
		if gm.is_intel_found(String(m.name)):
			continue
		var pickup := IntelPickup.new()
		pickup.intel_id = String(m.name)
		active_sector_node.add_child(pickup)
		pickup.global_position = m.global_position
		pickup.collected.connect(_on_intel_collected)

func _on_intel_collected(intel_id: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var entry: Dictionary = gm.collect_intel(intel_id)
	if entry.is_empty():
		return
	var progress: Vector2i = gm.get_intel_progress(gm.current_sector)
	hud.show_radio("INTEL %d/%d · %s" % [progress.x, progress.y, entry["title"]], String(entry["text"]))
	hud.show_powerup_banner("INTEL FOUND  +%d CORES" % GameManager.INTEL_RC_REWARD)

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
	extraction_marker = MissionJob.make_beacon(Color(1.0, 0.05, 0.12, 0.28))
	extraction_marker.name = "EvacBeacon"
	area.add_child(extraction_marker)
	extraction_marker.visible = false

func _on_job_status_changed(text: String, color: Color) -> void:
	if not objective_complete and not mission_over:
		hud.set_mission_status(text, color)

func _on_objective_met() -> void:
	if objective_complete or mission_over:
		return
	objective_complete = true
	if job:
		hud.show_radio("OVERWATCH", String(job.contract.get("extract_radio", "")))
	hud.set_mission_status("EVAC UNLOCKED — REACH THE LZ", Color(1.0, 0.8, 0.1))
	hud.show_banner("OBJECTIVE COMPLETE — EVAC UNLOCKED", "Follow the red beacon to the extraction LZ")
	if is_instance_valid(extraction_marker):
		extraction_marker.visible = true
	# Already standing in the LZ when the objective completes
	if extraction_area and extraction_area.overlaps_body(player):
		player_in_lz = true
		_start_evac()

func _on_extraction_zone_entered(body: Node3D) -> void:
	if body != player or mission_over or player.is_dead:
		return
	player_in_lz = true
	if not objective_complete:
		hud.show_banner("LZ LOCKED", job.get_locked_hint() if job else "")
		return
	if not evac_active:
		_start_evac()

func _on_extraction_zone_exited(body: Node3D) -> void:
	if body == player:
		player_in_lz = false

func _start_evac() -> void:
	evac_active = true
	var gm = get_node_or_null("/root/GameManager")
	evac_hold_time = gm.get_evac_hold_time() if gm else 20.0
	evac_time_left = evac_hold_time
	spawner.evac_frenzy = true
	hud.show_banner("EVAC INBOUND — HOLD THE LZ", "Stay inside the beacon until the chopper lands")

func _process(delta: float) -> void:
	_update_objective_pointer()
	if not evac_active or mission_over or player.is_dead:
		return
	if player_in_lz:
		evac_time_left = maxf(0.0, evac_time_left - delta)
		hud.set_mission_status("HOLD THE LZ — EVAC IN %.1fs" % evac_time_left, Color(1.0, 0.8, 0.1))
	else:
		hud.set_mission_status("RETURN TO THE LZ — EVAC PAUSED", Color(1.0, 0.3, 0.3))
	hud.show_evac_progress(1.0 - evac_time_left / evac_hold_time, player_in_lz)
	if evac_time_left <= 0.0:
		_extract()

## Arrow to the current goal: the job's objective first, then the LZ (hidden once you're in it).
func _update_objective_pointer() -> void:
	if mission_over or player.is_dead:
		hud.update_objective_pointer(null, Vector3.ZERO, Color.WHITE)
		return
	var target: Variant = null
	var color := Color(1.0, 0.72, 0.0)
	if objective_complete:
		if extraction_area and not player_in_lz:
			target = extraction_area.global_position
			color = Color(1.0, 0.15, 0.2)
	elif job:
		target = job.get_target_position()
	hud.update_objective_pointer(target, player.global_position, color)

func _extract() -> void:
	mission_over = true
	evac_active = false
	spawner.evac_frenzy = false
	hud.hide_evac_progress()
	print("[Main] Player extracted!")
	var gm = get_node_or_null("/root/GameManager")
	var summary: Dictionary = gm.complete_mission() if gm else {}
	hud.show_mission_result(summary)

func _on_player_died() -> void:
	if mission_over:
		return
	mission_over = true
	evac_active = false
	spawner.evac_frenzy = false
	hud.hide_evac_progress()
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
	if not BloodManager.instance or not active_sector_node:
		return
	
	# Atmospheric starting blood pools, placed per sector via "BloodDecor" markers
	for m in active_sector_node.get_marker_nodes("BloodDecor"):
		BloodManager.instance.spawn_splatter(m.global_position, Vector3.UP, m.get_meta("size", 2.0), m.get_meta("heavy", false))
