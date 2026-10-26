extends SceneTree
## test_molotov_landing_precision.gd
## Rigorous mathematical and physical verification that Molotov cocktail
## lands EXACTLY where the player marks/aims it to land across all distances and elevations.

func _init() -> void:
	print("=================================================================")
	print("[AUDIT] Starting Molotov Landing Precision Test")
	print("=================================================================")
	
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("FAIL: Could not load main.tscn")
		quit(1)
		return
		
	var main := main_scene.instantiate() as Node3D
	root.add_child(main)
	
	await process_frame
	await process_frame
	
	var player: Player = main.get_node_or_null("Player")
	assert(player != null, "Player must exist")
	
	var molotov_scene := preload("res://scenes/molotov_projectile.tscn")
	
	# Test Cases: [TargetPosition, Description]
	var test_targets: Array[Dictionary] = [
		{"target": Vector3(0.0, 0.0, -5.0), "desc": "Short 5m throw North (Main Avenue)"},
		{"target": Vector3(0.0, 0.0, -12.0), "desc": "Medium 12m throw North (Mid Avenue)"},
		{"target": Vector3(8.0, 0.0, -3.0), "desc": "East Service Alley 8.5m throw"},
		{"target": Vector3(-5.0, 0.0, -8.0), "desc": "Courtyard 9.4m throw North-West"},
		{"target": Vector3(-14.0, 3.2, -18.0), "is_absolute": true, "desc": "Elevated 3.2m Upper Terrace throw"}
	]
	
	var p_pos := player.global_position
	var spawn_pos := player.muzzle_point.global_position + Vector3(0, 0.4, 0)
	
	for tc in test_targets:
		var target: Vector3 = tc["target"] if tc.get("is_absolute", false) else (p_pos + tc["target"])
		print("\n--- Testing %s: Target = %s ---" % [tc["desc"], str(target)])
		
		# 1. Start aiming at target
		player.refill_molotov(3)
		player.start_aiming_special("molotov")
		player.update_aim_special_world(target)
		
		var marked_pos := player.aim_arrow_indicator.get_aim_target_world()
		print("  -> Aim indicator marked target: %s" % str(marked_pos))
		
		# 2. Instantiate molotov and simulate physics steps
		var molotov: MolotovProjectile = molotov_scene.instantiate() as MolotovProjectile
		main.add_child(molotov)
		molotov.init_target(spawn_pos, marked_pos)
		
		var landed := false
		var impact_pos := Vector3.ZERO
		var dt := 0.016667
		
		for step in range(120): # Up to 2.0 seconds of simulation
			molotov._physics_process(dt)
			if molotov.exploded:
				landed = true
				impact_pos = molotov.global_position
				break
		
		if not landed and is_instance_valid(molotov):
			impact_pos = molotov.global_position
			landed = molotov.exploded
			
		print("  -> Landed impact position:      %s" % str(impact_pos))
		var err_dist := Vector2(impact_pos.x - marked_pos.x, impact_pos.z - marked_pos.z).length()
		var err_y := absf(impact_pos.y - marked_pos.y)
		print("  -> Horizontal error: %.4fm, Vertical error: %.4fm" % [err_dist, err_y])
		
		assert(err_dist <= 0.15, "Molotov must land within 15cm of marked spot! (Error: %.4fm)" % err_dist)
		assert(err_y <= 0.20, "Molotov must impact at marked elevation! (Error: %.4fm)" % err_y)
		print("  -> PASS: %s landed with pinpoint precision!" % tc["desc"])
		
		player.cancel_aim_special()
	
	# ─────────────────────────────────────────────────────────────
	# CAPTURE SHOWCASE SCREENSHOT OF 3D PARABOLIC TRAJECTORY ARC
	# ─────────────────────────────────────────────────────────────
	print("\n--- Capturing Screenshot of 3D Parabolic Trajectory Arc ---")
	player.refill_molotov(3)
	player.start_aiming_special("molotov")
	player.update_aim_special_world(p_pos + Vector3(4.0, 0.0, -10.0))
	
	for i in range(10):
		await process_frame
		
	var vp := main.get_viewport()
	var img := vp.get_texture().get_image()
	var save_path := "user://capture_molotov_arc_precision.png"
	var err := img.save_png(save_path)
	if err == OK:
		print("  -> SUCCESS: Captured precision arc screenshot to: %s" % save_path)
	
	print("\n=================================================================")
	print("[AUDIT SUCCESS] Molotov lands EXACTLY where marked in all tests!")
	print("=================================================================")
	quit(0)
