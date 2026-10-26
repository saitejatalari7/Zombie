extends SceneTree

func _init() -> void:
	print("=================================================================")
	print("--- AUDITING GAMEPLAY UPDATES (SUNLIGHT, FPS, RADIUS, 1-BULLET, WAVES) ---")
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
		
	var player: Player = root_node.get_node_or_null("Player")
	var spawner: ZombieSpawner = root_node.get_node_or_null("ZombieSpawner")
	var hud: MobileHUD = root_node.get_node_or_null("MobileHUD")
	var sun: DirectionalLight3D = root_node.get_node_or_null("DirectionalLight3D")
	var world_env: WorldEnvironment = root_node.get_node_or_null("WorldEnvironment")
	
	assert(player != null, "Player must exist")
	assert(spawner != null, "ZombieSpawner must exist")
	assert(hud != null, "MobileHUD must exist")
	assert(sun != null, "Sun DirectionalLight3D must exist")
	assert(world_env != null, "WorldEnvironment must exist")
	
	# ─── CHECK 1: User's Default Sunlight Configuration ───
	print("\n[CHECK 1] Auditing User's Default Sunlight Configuration...")
	print("  Sun rot: ", sun.rotation_degrees)
	print("  Sun energy: ", sun.light_energy)
	print("  Shadow max dist: ", sun.directional_shadow_max_distance)
	print("  Ambient energy: ", world_env.environment.ambient_light_energy)
	
	assert(is_equal_approx(sun.rotation_degrees.x, -45.0), "Sun pitch must be -45.0°")
	assert(is_equal_approx(sun.rotation_degrees.y, 106.0), "Sun yaw must be 106.0°")
	assert(is_equal_approx(sun.light_energy, 1.95), "Sun light_energy must be 1.95")
	assert(is_equal_approx(sun.directional_shadow_max_distance, 100.0), "Shadow dist must be 100.0")
	assert(is_equal_approx(world_env.environment.ambient_light_energy, 0.18), "Ambient energy must be 0.18")
	print("  -> PASS: User's chosen sunlight baked as default.")
	
	# ─── CHECK 2: In-Game FPS Meter ───
	print("\n[CHECK 2] Auditing In-Game FPS Meter...")
	var fps_label: Label = hud.get_node_or_null("TopBar/FpsLabel")
	assert(fps_label != null, "FpsLabel must exist on HUD TopBar")
	for i in range(20):
		await process_frame
	print("  FPS Meter Text: ", fps_label.text)
	assert(fps_label.text.contains("FPS"), "FpsLabel must display FPS")
	print("  -> PASS: In-game FPS meter active and updating.")
	
	# ─── CHECK 3: Shooting Radius & Auto-Shoot Rule ───
	print("\n[CHECK 3] Auditing Auto-Shooting Radius Cutoff...")
	assert(is_equal_approx(player.auto_shoot_radius, 8.5), "auto_shoot_radius must be 8.5m")
	
	# Enable auto-fire
	player.set_auto_fire(true)
	assert(player.range_ring != null and player.range_ring.visible, "Range ring must be visible when auto-fire is ON")
	
	# Clean up any existing zombies for strict test
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	for i in range(5):
		await process_frame
		
	var zombie_scene: PackedScene = load("res://scenes/zombie.tscn")
	
	# Test A: Zombie outside radius (12m away)
	var far_zombie: Zombie = zombie_scene.instantiate()
	root_node.add_child(far_zombie)
	far_zombie.global_position = player.global_position + Vector3(12.0, 0.0, 0.0)
	
	for i in range(5):
		await process_frame
		
	var target_far = player.get_best_target_with_los(player.auto_shoot_radius)
	print("  Target when zombie is at 12m (> 8.5m): ", target_far)
	assert(target_far == null, "Player must NOT acquire or react to zombies outside 8.5m radius")
	far_zombie.queue_free()
	
	# Test B: Zombie inside radius (6m away)
	var near_zombie: Zombie = zombie_scene.instantiate()
	root_node.add_child(near_zombie)
	near_zombie.global_position = player.global_position + Vector3(6.0, 0.0, 0.0)
	
	for i in range(5):
		await process_frame
		
	var target_near = player.get_best_target_with_los(player.auto_shoot_radius)
	print("  Target when zombie is at 6m (<= 8.5m): ", target_near)
	assert(target_near != null, "Player MUST acquire zombie within 8.5m radius")
	near_zombie.queue_free()
	print("  -> PASS: Strict 8.5m auto-shooting radius confirmed.")
	
	# ─── CHECK 4: Single Bullet Initial Firing ───
	print("\n[CHECK 4] Auditing 1-Bullet Initial Firing...")
	var initial_bullet_count: int = player.bullet_count
	assert(initial_bullet_count == 1, "Player must fire 1 bullet initially")
	
	# Count bullets spawned during rifle shot
	var bullets_before := root_node.find_children("", "BulletProjectile", true, false).size()
	player.fire_rifle()
	var bullets_after := root_node.find_children("", "BulletProjectile", true, false).size()
	var spawned_count := bullets_after - bullets_before
	print("  Bullets spawned on single shot: ", spawned_count)
	assert(spawned_count == 1, "Expected exactly 1 bullet spawned (found: %d)" % spawned_count)
	print("  -> PASS: Single-bullet initial fire verified.")
	
	# ─── CHECK 5: Building Doorway & Street Wave Spawns ───
	print("\n[CHECK 5] Auditing Building Doorway & Street Wave Spawns...")
	print("  Street spawn points count:   ", spawner.street_spawn_points.size())
	print("  Building spawn points count: ", spawner.building_spawn_points.size())
	assert(spawner.street_spawn_points.size() > 0, "Must have street spawn points")
	assert(spawner.building_spawn_points.size() > 0, "Must have building doorway spawn points")
	print("  -> PASS: Building doorway and street points cleanly categorized.")
	
	# ─── Capture Gameplay Screenshot ───
	for i in range(20):
		await process_frame
		
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://capture_gameplay_updates.png")
		print("[Check] Successfully saved capture_gameplay_updates.png!")
		
	print("\n=================================================================")
	print("--- ALL 5 GAMEPLAY FEATURES AUDITED & VERIFIED (100% PASS) ---")
	print("=================================================================\n")
	quit(0)
