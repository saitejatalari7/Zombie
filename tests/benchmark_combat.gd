extends SceneTree

func _init() -> void:
	print("[CombatBenchmark] Starting intense combat simulation benchmark...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	# Wait for load and warm up
	for i in range(60):
		await process_frame
		
	var player = root_node.get_node_or_null("Player")
	var spawner = root_node.get_node_or_null("ZombieSpawner")
	
	# Rapid spawn 50 zombies
	if spawner:
		print("[CombatBenchmark] Force spawning 50 zombies...")
		for i in range(50):
			spawner.spawn_single_zombie()
			
	for i in range(30):
		await process_frame
		
	if player:
		player.auto_fire_enabled = true
		player.mobile_fire_pressed = true
	
	print("[CombatBenchmark] Starting combat loop (firing weapon + zombies moving)...")
	var times: Array[float] = []
	for frame in range(180):
			
		var t_start := Time.get_ticks_usec()
		await process_frame
		var dt := (Time.get_ticks_usec() - t_start) / 1000.0
		times.append(dt)
		
	var avg_time := 0.0
	var max_time := 0.0
	var min_time := 99999.0
	for t in times:
		avg_time += t
		if t > max_time: max_time = t
		if t < min_time: min_time = t
	avg_time /= times.size()
	
	var r := RenderingServer
	var report := "[CombatBenchmark] Results over 180 combat frames:\n"
	report += "  Avg Frame Time: %.2f ms (%.1f FPS)\n" % [avg_time, 1000.0 / avg_time]
	report += "  Min Frame Time: %.2f ms (%.1f FPS)\n" % [min_time, 1000.0 / min_time]
	report += "  Worst Spike:    %.2f ms (%.1f FPS)\n" % [max_time, 1000.0 / max_time]
	report += "  Draw Calls:     %d\n" % r.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	report += "  Objects:        %d\n" % r.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	report += "  Primitives:     %d\n" % r.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print(report)
	var f := FileAccess.open("res://benchmark_results.txt", FileAccess.WRITE)
	if f:
		f.store_string(report)
		f.close()
	
	quit(0)
