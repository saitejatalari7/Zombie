extends SceneTree

func _init() -> void:
	print("[DebugCollision] Finding what collides around Z = -7.14...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	for i in range(10):
		await process_frame
		
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	player.global_position = Vector3(0.0, 0.2, -6.5)
	
	# Raycast or direct space check
	var dspace = player.get_world_3d().direct_space_state
	
	# Cast rays forward at various heights
	for h in [0.1, 0.3, 0.5, 1.0, 1.5, 2.0]:
		var from_pos := Vector3(0.0, h, -6.0)
		var to_pos := Vector3(0.0, h, -8.0)
		var query := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
		var res := dspace.intersect_ray(query)
		if res.is_empty():
			print("Ray at Y=%.2f: NO HIT" % h)
		else:
			print("Ray at Y=%.2f: HIT at %s | collider = %s (parent: %s)" % [
				h, res.position, res.collider.name, res.collider.get_parent().name if res.collider.get_parent() else "null"
			])
			
	# Check Stair_Collision_Ramp transform and shape
	var ramp = root_node.find_child("Stair_Collision_Ramp", true, false)
	if ramp:
		print("Stair_Collision_Ramp found! pos: ", ramp.global_position, " rot_deg: ", ramp.rotation_degrees)
		for c in ramp.get_children():
			if c is CollisionShape3D:
				print("  CollisionShape3D shape size: ", c.shape.size if c.shape is BoxShape3D else c.shape)
	else:
		printerr("Stair_Collision_Ramp NOT FOUND!")
		
	# Check if VisualSteps have colliders or if something else is at Z = -7.14
	var space_param := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	space_param.shape = box
	space_param.transform = Transform3D(Basis(), Vector3(0.0, 1.0, -7.14))
	var hits = dspace.intersect_shape(space_param, 10)
	print("Hits in 2m box around (0, 1, -7.14): ", hits.size())
	for hit in hits:
		print("  Hit collider: ", hit.collider.name, " parent: ", hit.collider.get_parent().name if hit.collider.get_parent() else "none")

	quit(0)
