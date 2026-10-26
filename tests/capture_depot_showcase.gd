extends SceneTree

func _init() -> void:
	print("[Capture] Starting visual capture of upper industrial quarantine depot (Warehouse & Container yard)...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	
	for i in range(15):
		await process_frame
		
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	if player:
		# Position player in the upper depot between container stack and warehouse
		player.global_position = Vector3(0, 1.8, -18)
		player.rotation.y = deg_to_rad(180) # Facing north toward extraction warehouse
		
		var runner_scene := preload("res://scenes/zombie_runner.tscn")
		var tank_scene := preload("res://scenes/zombie_tank.tscn")
		var shambler_scene := preload("res://scenes/zombie_runner.tscn")
		
		# Tank guarding warehouse roll-up door
		var t1: Node3D = tank_scene.instantiate()
		root_node.add_child(t1)
		t1.global_position = Vector3(2.5, 1.8, -26)
		t1.rotation.y = 0
		
		# Runner sprinting around shipping container stack
		var r1: Node3D = runner_scene.instantiate()
		root_node.add_child(r1)
		r1.global_position = Vector3(-2.8, 1.8, -23)
		r1.rotation.y = deg_to_rad(30)
		
		# Blood splatters on the industrial asphalt
		if BloodManager.instance:
			BloodManager.instance.spawn_splatter(Vector3(-1.0, 1.8, -20.0), Vector3.UP, 2.2, true)
			BloodManager.instance.spawn_directional_blood(Vector3(-1.0, 1.8, -20.0), Vector3.BACK, 50.0, false)
			BloodManager.instance.spawn_splatter(Vector3(1.8, 1.8, -22.0), Vector3.UP, 1.8, false)
			
	for i in range(35):
		await process_frame
		
	var img: Image = root.get_texture().get_image()
	if img:
		img.save_png("res://capture_depot_showcase.png")
		print("Saved capture_depot_showcase.png Size: ", img.get_size())
		
	quit(0)
