extends SceneTree

func _init() -> void:
	print("[Check420] Checking colliders around (0, 0.5, -4.2)...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	for i in range(10):
		await process_frame
		
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	var dspace = player.get_world_3d().direct_space_state
	
	var space_param := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.0, 1.0)
	space_param.shape = box
	space_param.transform = Transform3D(Basis(), Vector3(0.0, 0.5, -4.2))
	var hits = dspace.intersect_shape(space_param, 10)
	print("Hits at (0, 0.5, -4.2): ", hits.size())
	for hit in hits:
		var c = hit.collider
		var p = c.get_parent()
		print("  Hit collider: '", c.name, "' | class: ", c.get_class(), " | parent: '", p.name if p else "none", "'")
		if c is Node3D:
			print("    collider pos: ", c.global_position)
			
	quit(0)
