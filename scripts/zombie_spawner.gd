extends Node3D
class_name ZombieSpawner

signal zombie_count_changed(alive_count: int, total_kills: int)
signal wave_started(wave_number: int)

@export var max_active_zombies: int = 18 # Balanced horde cap for rock-solid 60 FPS
@export var spawn_interval: float = 1.4 # Tactical spawn pacing
@export var spawn_points: Array[Node3D] = []

var zombie_scene := preload("res://scenes/zombie.tscn")
var runner_scene := preload("res://scenes/zombie_runner.tscn")
var tank_scene := preload("res://scenes/zombie_tank.tscn")
var powerup_scene := preload("res://scenes/powerup_pickup.tscn")

var street_spawn_points: Array[Node3D] = []
var building_spawn_points: Array[Node3D] = []

var timer: float = 0.0
var alive_zombies: int = 0
var total_kills: int = 0
var current_wave: int = 1
var kills_in_current_wave: int = 0
var wave_target_kills: int = 12 # Wave 1: 12 kills, Wave 2: 18, Wave 3: 25
var wave_cooldown_timer: float = 0.0

var player: Player = null
var is_frenzy: bool = false

func _ready() -> void:
	refresh_spawn_points()
	emit_signal("wave_started", current_wave)
	emit_signal("zombie_count_changed", alive_zombies, total_kills)
	
	# Spawn initial pickup in courtyard
	call_deferred("_spawn_initial_powerup")
	
	# Spawn initial mob down the alleyway (4 shamblers, 1 runner)
	# Positioned down the street (z: -12 to -18) to allow player tactical breathing room
	for i in range(5):
		var scene_to_spawn := (runner_scene if i == 4 else zombie_scene)
		var z: Zombie = scene_to_spawn.instantiate()
		get_parent().call_deferred("add_child", z)
		var spawn_z := randf_range(-12.0, -18.0)
		var spawn_x := randf_range(-2.2, 2.2)
		z.position = Vector3(spawn_x, 0, spawn_z)
		z.died.connect(_on_zombie_died)
		alive_zombies += 1
	
	emit_signal("zombie_count_changed", alive_zombies, total_kills)

func refresh_spawn_points() -> void:
	street_spawn_points.clear()
	building_spawn_points.clear()
	
	for pt in spawn_points:
		if not is_instance_valid(pt):
			continue
		var n := pt.name.to_lower()
		# Markers identifying building doorways, elevated terraces, or alley nooks
		if "door" in n or "terrace" in n or "nook" in n or "building" in n or "bay" in n or "airlock" in n or pt.global_position.y > 1.2:
			building_spawn_points.append(pt)
		else:
			street_spawn_points.append(pt)
			
	if street_spawn_points.is_empty():
		street_spawn_points = spawn_points.duplicate()
	if building_spawn_points.is_empty() and not spawn_points.is_empty():
		building_spawn_points = [spawn_points[0]]

func _spawn_initial_powerup() -> void:
	var p1: Node3D = powerup_scene.instantiate()
	get_parent().add_child(p1)
	p1.global_position = Vector3(-6.0, 0.0, 1.5)
	
	var p2: Node3D = powerup_scene.instantiate()
	get_parent().add_child(p2)
	p2.global_position = Vector3(0.0, 2.9, -28.0)

func setup_player(p_player: Player) -> void:
	player = p_player
	if player:
		player.powerup_timer_changed.connect(_on_powerup_timer_changed)

func _on_powerup_timer_changed(time_left: float, _max_time: float) -> void:
	is_frenzy = (time_left > 0.05)

func _process(delta: float) -> void:
	# Wave intermission pause
	if wave_cooldown_timer > 0.0:
		wave_cooldown_timer -= delta
		return
		
	timer += delta
	var active_interval := (0.7 if is_frenzy else spawn_interval)
	if timer >= active_interval:
		timer = 0.0
		var limit := (26 if is_frenzy else max_active_zombies)
		if alive_zombies < limit:
			var batch := (2 if is_frenzy else 1)
			for i in range(batch):
				if alive_zombies < limit:
					spawn_single_zombie()

func spawn_single_zombie() -> void:
	if spawn_points.is_empty():
		return
		
	# Decide if spawning from building doorway vs street chokepoint
	# 30-45% chance to emerge from buildings, higher in later waves
	var building_chance := clampf(0.28 + float(current_wave) * 0.06, 0.28, 0.50)
	var from_building := (randf() < building_chance and not building_spawn_points.is_empty())
	
	var target_list := (building_spawn_points if from_building else street_spawn_points)
	if target_list.is_empty():
		target_list = spawn_points
		
	var pt: Node3D = target_list[randi() % target_list.size()]
	
	# Determine zombie type based on wave & building context
	var roll := randf()
	var scene_to_spawn: PackedScene
	
	if current_wave >= 3 and roll < 0.20 and from_building:
		# Tanks break out from building doorways/bays in Wave 3+
		scene_to_spawn = tank_scene
	elif roll < (0.24 + float(current_wave) * 0.04):
		scene_to_spawn = runner_scene
	elif roll < 0.32 and current_wave >= 2:
		scene_to_spawn = tank_scene
	else:
		scene_to_spawn = zombie_scene
		
	var z: Zombie = scene_to_spawn.instantiate()
	get_parent().add_child(z)
	
	# Jitter position slightly
	var offset := Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8))
	z.global_position = pt.global_position + offset
	z.died.connect(_on_zombie_died)
	
	alive_zombies += 1
	emit_signal("zombie_count_changed", alive_zombies, total_kills)

func _on_zombie_died(_zombie: Zombie) -> void:
	alive_zombies = max(0, alive_zombies - 1)
	total_kills += 1
	kills_in_current_wave += 1
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and is_instance_valid(_zombie):
		gm.record_kill(_zombie.get_enemy_type())
	
	# 10% chance to drop Molotov Power-Up on zombie death
	if randf() < 0.10 and is_instance_valid(_zombie):
		var p: Node3D = powerup_scene.instantiate()
		get_parent().call_deferred("add_child", p)
		p.position = _zombie.global_position + Vector3(0, 0.1, 0)
	
	if kills_in_current_wave >= wave_target_kills:
		current_wave += 1
		kills_in_current_wave = 0
		wave_target_kills = int(wave_target_kills * 1.4)
		spawn_interval = maxf(0.85, spawn_interval * 0.94)
		wave_cooldown_timer = 2.5 # 2.5-second breathing room between waves
		emit_signal("wave_started", current_wave)
	
	emit_signal("zombie_count_changed", alive_zombies, total_kills)
