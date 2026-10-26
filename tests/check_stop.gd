extends SceneTree

func _init() -> void:
	print("[CheckStop] Inspecting what stops the player...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	for i in range(10):
		await process_frame
		
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	player.global_position = Vector3(0.0, 0.2, -3.5)
	
	var dt: float = 1.0 / 60.0
	for frame in range(100):
		player.velocity.x = 0.0
		player.velocity.z = -player.move_speed
		if not player.is_on_floor():
			player.velocity.y -= 25.0 * dt
		elif player.velocity.y < 0.0:
			player.velocity.y = 0.0
		player.move_and_slide()
		
		var col_count := player.get_slide_collision_count()
		if col_count > 0:
			for c_idx in range(col_count):
				var col := player.get_slide_collision(c_idx)
				var c_obj = col.get_collider()
				print("  Frame %d: pos=(%.2f, %.2f, %.2f) | Hit collider: '%s' (parent: '%s') | normal: %s | travel: %s" % [
					frame, player.global_position.x, player.global_position.y, player.global_position.z,
					c_obj.name, c_obj.get_parent().name if c_obj.get_parent() else "none",
					col.get_normal(), col.get_travel()
				])
				
		if frame > 40 and player.velocity.length() < 0.1:
			break
			
	quit(0)
