extends SceneTree

func _init() -> void:
	print("[WedgeTest] Testing ConvexPolygonShape3D ramp climbing...")
	var root_node := Node3D.new()
	root.add_child(root_node)
	
	# Create ground
	var ground_sb := StaticBody3D.new()
	var ground_cs := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(20.0, 0.4, 40.0)
	ground_cs.shape = ground_shape
	ground_sb.position = Vector3(0.0, -0.2, 0.0)
	ground_sb.add_child(ground_cs)
	root_node.add_child(ground_sb)
	
	# Create upper floor at Y = 3.2, Z = -14.5 to -30.0
	var upper_sb := StaticBody3D.new()
	var upper_cs := CollisionShape3D.new()
	var upper_shape := BoxShape3D.new()
	upper_shape.size = Vector3(10.0, 3.4, 15.0)
	upper_cs.shape = upper_shape
	upper_sb.position = Vector3(0.0, 1.5, -22.0)
	upper_sb.add_child(upper_cs)
	root_node.add_child(upper_sb)
	
	# Create Solid Wedge Ramp from Z = -5.5 to Z = -14.5, Y = 0 to 3.2
	var stair_width := 4.4
	var hw := stair_width * 0.5
	var z_start := -5.5
	var z_end := -14.5
	var total_rise := 3.2
	
	var pts := PackedVector3Array([
		Vector3(-hw, -0.2, z_start),      # 0: bottom front left
		Vector3( hw, -0.2, z_start),      # 1: bottom front right
		Vector3(-hw,  0.0, z_start),      # 2: top front left (flush with ground!)
		Vector3( hw,  0.0, z_start),      # 3: top front right (flush with ground!)
		Vector3(-hw, -0.2, z_end),        # 4: bottom back left
		Vector3( hw, -0.2, z_end),        # 5: bottom back right
		Vector3(-hw, total_rise, z_end),  # 6: top back left
		Vector3( hw, total_rise, z_end),  # 7: top back right
	])
	
	var wedge_sb := StaticBody3D.new()
	var wedge_cs := CollisionShape3D.new()
	var wedge_shape := ConvexPolygonShape3D.new()
	wedge_shape.points = pts
	wedge_cs.shape = wedge_shape
	wedge_sb.add_child(wedge_cs)
	root_node.add_child(wedge_sb)
	
	# Instantiate player
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root_node.add_child(player)
	player.global_position = Vector3(0.0, 0.2, -2.0)
	
	for i in range(5):
		await process_frame
		
	print("[WedgeTest] Starting walk at: ", player.global_position)
	var dt: float = 1.0 / 60.0
	for frame in range(500):
		player.velocity.x = 0.0
		player.velocity.z = -player.move_speed
		if not player.is_on_floor():
			player.velocity.y -= 25.0 * dt
		elif player.velocity.y < 0.0:
			player.velocity.y = 0.0
		player.move_and_slide()
		
		if player.global_position.z <= -16.0 and player.global_position.y >= 3.1:
			print("  Reached terrace at frame %d! Pos: %s" % [frame, player.global_position])
			break
			
	print("[WedgeTest] Now testing walking back DOWN from Upper Terrace...")
	for frame in range(260):
		player.velocity.x = 0.0
		player.velocity.z = player.move_speed
		if not player.is_on_floor():
			player.velocity.y -= 25.0 * dt
		elif player.velocity.y < 0.0:
			player.velocity.y = 0.0
		player.move_and_slide()
		
		if frame % 15 == 0:
			print("  Descent Frame %3d: pos = (%.2f, %.2f, %.2f) | on_floor = %s | vel.y = %.2f" % [
				frame, player.global_position.x, player.global_position.y, player.global_position.z,
				player.is_on_floor(), player.velocity.y
			])
		
	print("[WedgeTest] Final pos after walking down: ", player.global_position)
	if player.global_position.z >= -3.0 and player.global_position.y <= 0.05:
		print("[WedgeTest] DOUBLE SUCCESS! Player smoothly walked back DOWN to ground level at Y = %.2f!" % player.global_position.y)
	else:
		printerr("[WedgeTest] FAILED to walk down! Pos: ", player.global_position)
		
	quit(0 if (player.global_position.z >= -3.0 and player.global_position.y <= 0.05) else 1)
