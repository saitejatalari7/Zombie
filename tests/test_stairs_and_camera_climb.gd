extends SceneTree

func _init() -> void:
	print("[StairsTest] Verifying zoomed-out camera and climbing to Upper Terrace (Y = 3.2m)...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("Failed to load res://scenes/main.tscn")
		quit(1)
		return
		
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	for i in range(15):
		await process_frame
		
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	if not player:
		printerr("Player node not found!")
		quit(1)
		return
		
	# Spawn zombies across both Lower Street and Upper Terrace
	var runner_scene := preload("res://scenes/zombie_runner.tscn")
	var shambler_scene := preload("res://scenes/zombie.tscn")
	var tank_scene := preload("res://scenes/zombie_tank.tscn")
	
	# Shamblers on lower street
	var s1: Node3D = shambler_scene.instantiate()
	root_node.add_child(s1)
	s1.global_position = Vector3(-1.8, 0.3, 12.0)
	
	# Runner sprinting up the split-level stairs
	var r1: Node3D = runner_scene.instantiate()
	root_node.add_child(r1)
	r1.global_position = Vector3(0.0, 1.6, -10.0)
	
	# Massive Tank guarding the Upper Terrace at Y = 3.2m!
	var t1: Node3D = tank_scene.instantiate()
	root_node.add_child(t1)
	t1.global_position = Vector3(0.0, 3.2, -22.0)
	
	# Blood splatters on the upper terrace
	if BloodManager.instance:
		BloodManager.instance.spawn_splatter(Vector3(0.0, 3.2, -20.0), Vector3.UP, 2.4, true)
		BloodManager.instance.spawn_directional_blood(Vector3(0.0, 3.2, -20.0), Vector3.BACK, 60.0, false)
		BloodManager.instance.spawn_splatter(Vector3(0.0, 0.3, 16.0), Vector3.UP, 2.0, true)
		BloodManager.instance.spawn_splatter(Vector3(2.0, 0.3, 8.0), Vector3.UP, 1.5, false)
		
	# ── TEST 1: PLAYER ON LOWER MAIN STREET (ZOOMED OUT VIEW) ──
	player.global_position = Vector3(0.0, 0.3, 22.0)
	player.rotation.y = deg_to_rad(180) # Facing North toward stairs
	
	var om = root.get_node_or_null("/root/OrientationManager")
	if om:
		om.set_portrait()
	else:
		DisplayServer.window_set_size(Vector2i(540, 960))
		root.size = Vector2i(1080, 1920)
		
	for i in range(25):
		await process_frame
		
	var img_p1: Image = root.get_viewport().get_texture().get_image()
	if img_p1:
		img_p1.save_png("res://capture_zoomed_portrait_lower.png")
		print("[StairsTest] Saved capture_zoomed_portrait_lower.png! Size: ", img_p1.get_size())
		
	# ── TEST 2: PLAYER ON TOP OF UPPER TERRACE AT Y = 3.2m (SOLID FLOOR VERIFICATION) ──
	player.global_position = Vector3(0.0, 3.5, -18.0)
	player.rotation.y = deg_to_rad(180) # Facing North toward Extraction Zone
	
	for i in range(25):
		await process_frame
		
	print("[StairsTest] Player position on terrace: ", player.global_position, " on floor: ", player.is_on_floor())
	
	var img_p2: Image = root.get_viewport().get_texture().get_image()
	if img_p2:
		img_p2.save_png("res://capture_zoomed_portrait_upper.png")
		print("[StairsTest] Saved capture_zoomed_portrait_upper.png! Size: ", img_p2.get_size())
		
	# ── TEST 3: LANDSCAPE VIEW OF UPPER TERRACE ──
	if om:
		om.set_landscape()
	else:
		DisplayServer.window_set_size(Vector2i(960, 540))
		root.size = Vector2i(1920, 1080)
		
	for i in range(25):
		await process_frame
		
	var img_l: Image = root.get_viewport().get_texture().get_image()
	if img_l:
		img_l.save_png("res://capture_zoomed_landscape_upper.png")
		print("[StairsTest] Saved capture_zoomed_landscape_upper.png! Size: ", img_l.get_size())
		
	quit(0)
