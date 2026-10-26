extends SceneTree

func _init() -> void:
	print("[Capture] Starting visual capture of tight urban layout and elevated camera perspective...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	
	for i in range(15):
		await process_frame
		
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	if player:
		# Position player in the narrow urban street corridor
		player.global_position = Vector3(0, 0.2, 8)
		player.rotation.y = deg_to_rad(180) # Facing north toward oncoming horde
		
		# Spawn Shamblers, Runners, and Tank funneling down the tight street
		var shambler_scene := preload("res://scenes/zombie.tscn")
		var runner_scene := preload("res://scenes/zombie_runner.tscn")
		var tank_scene := preload("res://scenes/zombie_tank.tscn")
		
		# Lead runner sprinting through the car chokepoint
		var r1: Node3D = runner_scene.instantiate()
		root_node.add_child(r1)
		r1.global_position = Vector3(0.0, 0.2, 1.5)
		r1.rotation.y = 0
		
		# Shamblers flanking the narrow sidewalk
		var s1: Node3D = shambler_scene.instantiate()
		root_node.add_child(s1)
		s1.global_position = Vector3(-1.6, 0.35, -2.5)
		s1.rotation.y = deg_to_rad(-10)
		
		var s2: Node3D = shambler_scene.instantiate()
		root_node.add_child(s2)
		s2.global_position = Vector3(1.5, 0.35, -3.5)
		s2.rotation.y = deg_to_rad(15)
		
		var s3: Node3D = shambler_scene.instantiate()
		root_node.add_child(s3)
		s3.global_position = Vector3(-0.5, 0.2, -6.5)
		s3.rotation.y = 0
		
		# Massive Tank advancing down the street past the split-level stairs
		var t1: Node3D = tank_scene.instantiate()
		root_node.add_child(t1)
		t1.global_position = Vector3(0.0, 0.2, -10.5)
		t1.rotation.y = 0
		
		# Visceral, solid crimson arterial blood splatters (zero transparent halo, zero double-layer overlap)
		if BloodManager.instance:
			# High-impact combat splatter
			BloodManager.instance.spawn_splatter(Vector3(0.2, 0.2, 2.5), Vector3.UP, 2.0, true)
			BloodManager.instance.spawn_directional_blood(Vector3(0.2, 0.2, 2.5), Vector3.BACK, 50.0, false)
			# Discrete satellite splatter marks
			BloodManager.instance.spawn_splatter(Vector3(-1.5, 0.35, -1.0), Vector3.UP, 1.4, false)
			BloodManager.instance.spawn_splatter(Vector3(1.4, 0.35, -4.0), Vector3.UP, 1.6, false)
			
	for i in range(35):
		await process_frame
		
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://capture_characters_showcase.png")
		print("Saved capture_characters_showcase.png Size: ", img.get_size())
		
	quit(0)
