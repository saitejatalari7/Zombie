extends SceneTree

func _init() -> void:
	# Add a timer to wait 1 physics frame for all ready signals to fire
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node: Node = main_scene.instantiate()
	root.add_child(root_node)
	
	process_frame.connect(_on_first_frame.bind(root_node), CONNECT_ONE_SHOT)

func _on_first_frame(root_node: Node) -> void:
	print("Game initialized successfully in SceneTree!")
	var player: Player = root_node.get_node("Player") as Player
	var spawner: ZombieSpawner = root_node.get_node("ZombieSpawner") as ZombieSpawner
	
	print("Player health: ", player.current_health)
	
	# Test firing rifle
	player.fire_rifle()
	print("Rifle fired successfully!")
	
	# Test super blast (fires 3 mini rockets)
	var blast_fired: bool = player.trigger_super_blast()
	print("Super blast fired: ", blast_fired)
	
	# Test zombie spawn
	spawner.spawn_single_zombie()
	print("Zombies alive: ", spawner.alive_zombies)
	
	if BloodManager.instance:
		BloodManager.instance.spawn_splatter(Vector3.ZERO, Vector3.UP, 1.5, true)
		print("Blood splatter spawned successfully! Decal count: ", BloodManager.instance.active_decals.size())
	
	print("ALL SYSTEMS TEST PASSED!")
	quit()
