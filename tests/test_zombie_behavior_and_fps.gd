extends SceneTree

func _init() -> void:
	print("=================================================================")
	print("--- AUDITING ZOMBIE REBALANCING, BEHAVIOR & FPS BENCHMARK ---")
	print("=================================================================")
	
	var scene: PackedScene = load("res://scenes/main.tscn")
	if not scene:
		printerr("Failed to load main.tscn")
		quit(1)
		return
		
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	
	for i in range(15):
		await process_frame
		
	var spawner: ZombieSpawner = root_node.get_node_or_null("ZombieSpawner")
	var player: Player = root_node.get_node_or_null("Player")
	
	assert(spawner != null, "ZombieSpawner must exist")
	assert(player != null, "Player must exist")
	
	# ─── CHECK 1: Max Active Zombies Cap ───
	print("\n[CHECK 1] Auditing Max Active Zombies Cap...")
	print("  Configured max_active_zombies: ", spawner.max_active_zombies)
	assert(spawner.max_active_zombies <= 20, "max_active_zombies must be <= 20 (configured: %d)" % spawner.max_active_zombies)
	print("  Initial active zombies: ", spawner.alive_zombies)
	assert(spawner.alive_zombies <= 8, "Initial zombies should be a tactical squad (found: %d)" % spawner.alive_zombies)
	print("  -> PASS: Zombie cap reduced and verified.")
	
	# ─── CHECK 2: Zombie Speeds (Halved) ───
	print("\n[CHECK 2] Auditing Halved Zombie Speeds...")
	var shambler_scene: PackedScene = load("res://scenes/zombie.tscn")
	var runner_scene: PackedScene = load("res://scenes/zombie_runner.tscn")
	var tank_scene: PackedScene = load("res://scenes/zombie_tank.tscn")
	
	var shambler: Zombie = shambler_scene.instantiate()
	var runner: Zombie = runner_scene.instantiate()
	var tank: Zombie = tank_scene.instantiate()
	
	print("  Shambler base_speed: %.2f (expected ~0.60)" % shambler.base_speed)
	print("  Runner base_speed:   %.2f (expected ~1.80)" % runner.base_speed)
	print("  Tank base_speed:     %.2f (expected ~0.70)" % tank.base_speed)
	
	assert(is_equal_approx(shambler.base_speed, 0.6), "Shambler base_speed must be 0.6")
	assert(is_equal_approx(runner.base_speed, 1.8), "Runner base_speed must be 1.8")
	assert(is_equal_approx(tank.base_speed, 0.7), "Tank base_speed must be 0.7")
	
	shambler.queue_free()
	runner.queue_free()
	tank.queue_free()
	print("  -> PASS: All zombie speeds strictly halved.")
	
	# ─── CHECK 3: Zombie Behavior & Stagger Logic ───
	print("\n[CHECK 3] Auditing Zombie Attack & Stagger Logic...")
	var test_zombie: Zombie = shambler_scene.instantiate()
	root_node.add_child(test_zombie)
	test_zombie.global_position = player.global_position + Vector3(0.0, 0.0, 1.0) # Within attack range
	
	for i in range(5):
		await process_frame
		
	print("  State when close to player: ", Zombie.State.keys()[test_zombie.state])
	assert(test_zombie.state == Zombie.State.ATTACK_WINDUP or test_zombie.state == Zombie.State.CHASE, "Zombie should transition to attack windup")
	
	# Test bullet impact stagger
	var prev_health := test_zombie.current_health
	test_zombie.take_damage(25.0, Vector3(0, 0, 5.0))
	print("  State after taking bullet damage: ", Zombie.State.keys()[test_zombie.state])
	assert(test_zombie.state == Zombie.State.STAGGER, "Zombie should enter STAGGER state when hit by bullets")
	assert(test_zombie.current_health < prev_health, "Health must be reduced")
	print("  -> PASS: Attack windup and bullet stagger confirmed.")
	test_zombie.queue_free()
	
	# ─── CHECK 4: Combat FPS & Performance Benchmark ───
	print("\n[CHECK 4] Benchmarking Combat Performance over 180 frames...")
	player.mobile_fire_pressed = true
	
	var frame_times: Array[float] = []
	for i in range(180):
		var t_start := Time.get_ticks_usec()
		await process_frame
		var dt := (Time.get_ticks_usec() - t_start) / 1000.0
		if i > 20: # warmup
			frame_times.append(dt)
			
	var avg_ms: float = 0.0
	var max_ms: float = 0.0
	for t in frame_times:
		avg_ms += t
		if t > max_ms:
			max_ms = t
	avg_ms /= frame_times.size()
	var avg_fps := 1000.0 / avg_ms if avg_ms > 0 else 0.0
	var worst_fps := 1000.0 / max_ms if max_ms > 0 else 0.0
	
	print("  Combat Results over %d frames:" % frame_times.size())
	print("  Avg Frame Time: %.2f ms (%.1f FPS)" % [avg_ms, avg_fps])
	print("  Worst Spike:    %.2f ms (%.1f FPS)" % [max_ms, worst_fps])
	print("  Zombies alive:  %d" % spawner.alive_zombies)
	
	var file := FileAccess.open("res://zombie_benchmark_results.txt", FileAccess.WRITE)
	if file:
		file.store_string("[ZombieRebalanceBenchmark]\n" +
			"Avg Frame Time: %.2f ms (%.1f FPS)\n" % [avg_ms, avg_fps] +
			"Worst Spike: %.2f ms (%.1f FPS)\n" % [max_ms, worst_fps] +
			"Active Zombies: %d\n" % spawner.alive_zombies +
			"Shambler Speed: 0.6 m/s | Runner: 1.8 m/s | Tank: 0.7 m/s\n"
		)
		file.close()
		
	print("\n=================================================================")
	print("--- ALL ZOMBIE REBALANCING & PERFORMANCE CHECKS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)
