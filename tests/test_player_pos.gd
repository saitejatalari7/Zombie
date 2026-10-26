extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node: Node = main_scene.instantiate()
	root.add_child(root_node)
	
	var player: Player = root_node.get_node("Player") as Player
	var spawner: ZombieSpawner = root_node.get_node("ZombieSpawner") as ZombieSpawner
	
	for i in range(120):
		player.mobile_move_input = Vector2(1, 0)
		player._physics_process(0.016)
		if i % 20 == 0:
			print("Frame ", i, " Player pos: ", player.global_position)
	
	quit()
