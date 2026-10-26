extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	for i in range(10): await process_frame
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	player.global_position = Vector3(0.0, 0.15, -5.858)
	
	var dspace = player.get_world_3d().direct_space_state
	var p := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	p.shape = cap
	p.transform = Transform3D(Basis(), Vector3(0.0, 0.15 + 0.85, -5.858))
	var res = dspace.intersect_shape(p, 10)
	print("Hits overlapping player capsule at (0.0, 0.15, -5.858): ", res.size())
	for r in res:
		var c = r.collider
		print("  Overlap: '", c.name, "' parent: '", c.get_parent().name if c.get_parent() else "none", "'")
		if c is StaticBody3D:
			for cs in c.get_children():
				if cs is CollisionShape3D:
					print("    shape: ", cs.shape, " size: ", cs.shape.size if "size" in cs.shape else "pts")
	quit(0)
