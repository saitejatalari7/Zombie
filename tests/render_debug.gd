extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node: Node = main_scene.instantiate()
	root.add_child(root_node)
	
	process_frame.connect(_capture.bind(root_node), CONNECT_ONE_SHOT)

func _capture(root_node: Node) -> void:
	var vp := root.get_viewport()
	print("Viewport size: ", vp.size)
	
	# Check where zombies actually are
	var spawner := root_node.get_node("ZombieSpawner") as ZombieSpawner
	spawner.spawn_single_zombie()
	
	var zombies := get_nodes_in_group("zombies")
	for z in zombies:
		print("Spawned zombie pos: ", z.global_position)
		z._physics_process(0.1)
		print("Zombie pos after 0.1s: ", z.global_position)
	
	# Check Ground visibility and global transform
	var ground := root_node.get_node("EnvironmentMap/Ground") as StaticBody3D
	var mesh_inst := ground.get_node("MeshInstance3D") as MeshInstance3D
	print("Ground visible: ", ground.visible, " global_pos: ", ground.global_position)
	print("MeshInstance3D visible: ", mesh_inst.visible, " aabb: ", mesh_inst.get_aabb())
	print("MeshInstance3D material_override: ", mesh_inst.material_override)
	print("Mesh material: ", mesh_inst.mesh.material if mesh_inst.mesh else null)
	
	var cam := root_node.get_node("IsometricCamera") as Camera3D
	print("Camera far plane: ", cam.far, " near plane: ", cam.near, " fov: ", cam.fov)
	print("Camera pos: ", cam.global_position, " looking at: ", cam.global_transform.basis.z)
	
	# Check if Ground is inside camera frustum
	print("Is ground in camera frustum? ", cam.is_position_in_frustum(Vector3.ZERO))
	print("Is player in camera frustum? ", cam.is_position_in_frustum(root_node.get_node("Player").global_position))
	
	quit()
