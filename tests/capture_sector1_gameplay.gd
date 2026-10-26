extends SceneTree

func _init() -> void:
	print("[Sector1Test] Starting in-engine gameplay capture of Sector 01 Residential...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("Failed to load res://scenes/main.tscn")
		quit(1)
		return
		
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	# Wait for sector to load and initialize
	for i in range(15):
		await process_frame
		
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	if not player:
		printerr("Player node not found!")
		quit(1)
		return
		
	# 1. POSITION PLAYER IN MAIN AVENUE CHOKEPOINT
	player.global_position = Vector3(0.0, 0.3, 16.0)
	player.rotation.y = deg_to_rad(180) # Facing North toward oncoming horde and stairs
	
	# 2. SPAWN ZOMBIES IN THE STREET CHOKEPOINTS
	var runner_scene := preload("res://scenes/zombie_runner.tscn")
	var shambler_scene := preload("res://scenes/zombie.tscn")
	var tank_scene := preload("res://scenes/zombie_tank.tscn")
	
	# Lead Runner charging between the wrecked cars
	var r1: Node3D = runner_scene.instantiate()
	root_node.add_child(r1)
	r1.global_position = Vector3(0.2, 0.3, 10.0)
	r1.rotation.y = 0.0
	
	# Shamblers flanking the curbs
	var s1: Node3D = shambler_scene.instantiate()
	root_node.add_child(s1)
	s1.global_position = Vector3(-1.8, 0.3, 6.0)
	s1.rotation.y = deg_to_rad(-15)
	
	var s2: Node3D = shambler_scene.instantiate()
	root_node.add_child(s2)
	s2.global_position = Vector3(1.5, 0.3, 4.0)
	s2.rotation.y = deg_to_rad(15)
	
	var s3: Node3D = shambler_scene.instantiate()
	root_node.add_child(s3)
	s3.global_position = Vector3(-0.5, 0.3, 0.0)
	
	# Massive Tank descending the split-level stairs
	var t1: Node3D = tank_scene.instantiate()
	root_node.add_child(t1)
	t1.global_position = Vector3(0.0, 1.6, -7.0)
	t1.rotation.y = 0.0
	
	# Runner emerging from East Alley
	var r2: Node3D = runner_scene.instantiate()
	root_node.add_child(r2)
	r2.global_position = Vector3(5.5, 0.3, 4.8)
	r2.rotation.y = deg_to_rad(-90)
	
	# 3. COMBAT BLOOD SPLATTERS
	if BloodManager.instance:
		BloodManager.instance.spawn_splatter(Vector3(0.2, 0.3, 11.5), Vector3.UP, 2.2, true)
		BloodManager.instance.spawn_directional_blood(Vector3(0.2, 0.3, 11.5), Vector3.BACK, 55.0, false)
		BloodManager.instance.spawn_splatter(Vector3(-1.5, 0.3, 7.5), Vector3.UP, 1.6, false)
		BloodManager.instance.spawn_splatter(Vector3(1.2, 0.3, 5.5), Vector3.UP, 1.8, false)
	
	# ── CAPTURE 1: PORTRAIT ORIENTATION ──
	var om = root.get_node_or_null("/root/OrientationManager")
	if om:
		om.set_portrait()
	else:
		DisplayServer.window_set_size(Vector2i(540, 960))
		root.size = Vector2i(1080, 1920)
		
	for i in range(25):
		await process_frame
		
	var img_p: Image = root.get_viewport().get_texture().get_image()
	if img_p:
		img_p.save_png("res://capture_sector1_portrait.png")
		print("[Sector1Test] Saved capture_sector1_portrait.png (Size: ", img_p.get_size(), ")")
		
	# ── CAPTURE 2: LANDSCAPE ORIENTATION ──
	if om:
		om.set_landscape()
	else:
		DisplayServer.window_set_size(Vector2i(960, 540))
		root.size = Vector2i(1920, 1080)
		
	for i in range(25):
		await process_frame
		
	var img_l: Image = root.get_viewport().get_texture().get_image()
	if img_l:
		img_l.save_png("res://capture_sector1_landscape.png")
		print("[Sector1Test] Saved capture_sector1_landscape.png (Size: ", img_l.get_size(), ")")
		
	print("[Sector1Test] Visual gameplay captures complete!")
	quit(0)
