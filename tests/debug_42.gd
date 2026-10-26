extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	for i in range(10): await process_frame
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	player.global_position = Vector3(0.0, 0.2, -3.8)
	
	var dt: float = 1.0 / 60.0
	for frame in range(40):
		player.velocity.x = 0.0
		player.velocity.z = -player.move_speed
		if not player.is_on_floor():
			player.velocity.y -= 25.0 * dt
		elif player.velocity.y < 0.0:
			player.velocity.y = 0.0
		player.move_and_slide()
		
		var col_info := ""
		for ci in range(player.get_slide_collision_count()):
			var c = player.get_slide_collision(ci)
			col_info += " [hit %s, norm=%s]" % [c.get_collider().name, c.get_normal()]
		print("Frame %2d: pos=(%.3f, %.3f, %.3f) vel=(%.2f, %.2f) on_floor=%s%s" % [
			frame, player.global_position.x, player.global_position.y, player.global_position.z,
			player.velocity.x, player.velocity.z, player.is_on_floor(), col_info
		])
	quit(0)
