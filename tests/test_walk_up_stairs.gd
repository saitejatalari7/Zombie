extends SceneTree

func _init() -> void:
	print("[WalkTest] Testing player walking directly in -Z (straight towards stairs)...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("Failed to load res://scenes/main.tscn")
		quit(1)
		return
		
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	for i in range(10):
		await process_frame
		
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	if not player:
		printerr("Player node not found!")
		quit(1)
		return
		
	# Put player at Z = -2.0, facing North (-Z)
	player.global_position = Vector3(0.0, 0.2, -2.0)
	player.velocity = Vector3.ZERO
	
	print("[WalkTest] Starting walk at pos: ", player.global_position)
	
	var dt: float = 1.0 / 60.0
	var walked_successfully := false
	for frame in range(450):
		# Directly set velocity in -Z (move_speed is 6.2)
		player.velocity.x = 0.0
		player.velocity.z = -player.move_speed
		
		# Apply gravity
		if not player.is_on_floor():
			player.velocity.y -= 25.0 * dt
		elif player.velocity.y < 0.0:
			player.velocity.y = 0.0
			
		player.move_and_slide()
		
		if frame % 20 == 0:
			print("  Frame %3d: Player pos = (%.2f, %.2f, %.2f) | on_floor = %s | vel.y = %.2f" % [
				frame, player.global_position.x, player.global_position.y, player.global_position.z,
				player.is_on_floor(), player.velocity.y
			])
			
		if player.global_position.z <= -16.0 and player.global_position.y >= 3.0:
			walked_successfully = true
			
	print("[WalkTest] Final player pos: ", player.global_position)
	if walked_successfully or (player.global_position.z <= -16.0 and player.global_position.y >= 3.0):
		print("[WalkTest] SUCCESS: Player smoothly climbed from Y=0.2 to Y=%.2f at Z=%.2f!" % [
			player.global_position.y, player.global_position.z
		])
	else:
		printerr("[WalkTest] FAILURE: Player got blocked! Pos: ", player.global_position)
		
	quit(0 if walked_successfully else 1)
