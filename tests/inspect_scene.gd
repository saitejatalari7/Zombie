extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node: Node = main_scene.instantiate()
	root.add_child(root_node)
	
	process_frame.connect(_inspect.bind(root_node), CONNECT_ONE_SHOT)

func _inspect(root_node: Node) -> void:
	print("--- INSPECTING SCENE ---")
	var env_map: Node = root_node.get_node_or_null("EnvironmentMap")
	print("EnvironmentMap node: ", env_map)
	if env_map:
		for child in env_map.get_children():
			print("  Child: ", child.name, " pos: ", child.position)
			for sub in child.get_children():
				if sub is MeshInstance3D:
					print("    MeshInstance3D: ", sub.name, " mesh: ", sub.mesh, " mat: ", (sub.mesh.material if sub.mesh else null))
	
	var player: Node = root_node.get_node_or_null("Player")
	print("Player pos: ", player.global_position if player else null)
	
	var cam: Camera3D = root_node.get_node_or_null("IsometricCamera") as Camera3D
	print("Camera pos: ", cam.global_position, " rot: ", cam.global_rotation_degrees)
	
	var zombies := get_nodes_in_group("zombies")
	print("Total zombies spawned: ", zombies.size())
	for z in zombies:
		print("  Zombie: ", z.name, " pos: ", z.global_position)
	
	quit()
