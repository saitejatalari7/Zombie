extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node: Node = main_scene.instantiate()
	root.add_child(root_node)
	
	# Activate molotov and trigger firing to see combat FPS
	var player = root.get_node("Main/Player")
	player.activate_molotov_powerup(15.0)
	player.mobile_fire_pressed = true
	
	# Let it run for 300 frames and sample FPS and frame times
	var fps_samples: Array[float] = []
	for i in range(300):
		await process_frame
		if i > 60: # After warmup
			fps_samples.append(Engine.get_frames_per_second())
	
	var avg_fps: float = 0.0
	var min_fps: float = 9999.0
	for f in fps_samples:
		avg_fps += f
		if f < min_fps:
			min_fps = f
	avg_fps /= fps_samples.size()
	
	print("--- PERFORMANCE BENCHMARK (Initial State) ---")
	print("Avg FPS: ", snappedf(avg_fps, 0.1), " | Min FPS: ", snappedf(min_fps, 0.1))
	print("Zombies alive: ", root.get_node("Main/ZombieSpawner").alive_zombies)
	print("Active Decals: ", BloodManager.instance.active_decals.size() if BloodManager.instance else 0)
	print("---------------------------------------------")
	
	quit()
