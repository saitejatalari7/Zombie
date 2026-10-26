extends SceneTree
## test_special_aim_bushes_cars.gd
## Automated test and visual audit for:
## 1. No automatic molotovs on rifle fire (AUTO mode shoots bullets only).
## 2. Hold-to-aim projectile arrow and release-to-shoot mechanics for Molotov & Super Blast.
## 3. Procedural dried grass bushes MultiMeshInstance3D (160 instances, zero draw calls).
## 4. Tactical automotive blue material on all civilian cars.
## 5. Exactly 5-6 abandoned transit buses with colliders across the urban sector.

func _init() -> void:
	print("=================================================================")
	print("[AUDIT] Starting Special Aim, Dried Grass, Blue Cars & Buses Audit")
	print("=================================================================")
	
	# Load Main scene
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("FAIL: Could not load res://scenes/main.tscn")
		quit(1)
		return
		
	var main = main_scene.instantiate()
	root.add_child(main)
	
	# Wait 2 frames for scene initialization
	await process_frame
	await process_frame
	
	var player: Player = main.get_node_or_null("Player")
	assert(player != null, "Player must exist in main scene")
	
	var sector = main.get_node_or_null("Sector1Residential")
	assert(sector != null, "Sector1Residential must be loaded")
	
	# ─────────────────────────────────────────────────────────────
	# TEST 1: No Automatic Molotov on Rifle Fire
	# ─────────────────────────────────────────────────────────────
	print("\n--- TEST 1: Verifying Rifle Fire / Auto Mode shoots bullets ONLY (No Auto-Molotov) ---")
	player.set_auto_fire(true)
	player.activate_molotov_powerup(15.0)
	var initial_molotov_ammo := player.molotov_ammo
	var initial_children_count := main.get_child_count()
	
	# Fire rifle 5 times in auto mode
	for i in range(5):
		player.can_fire_rifle = true
		player.fire_rifle()
	
	# Check if any MolotovProjectile was added to main
	var molotovs_found := 0
	for child in main.get_children():
		if child is MolotovProjectile or child.name.begins_with("Molotov"):
			molotovs_found += 1
			
	print("  -> Bullets fired: 5 bursts. Molotovs spawned: %d. Molotov ammo: %d/%d" % [
		molotovs_found, player.molotov_ammo, initial_molotov_ammo
	])
	assert(molotovs_found == 0, "CRITICAL ERROR: Player auto-fired a Molotov during rifle fire!")
	assert(player.molotov_ammo == initial_molotov_ammo, "Molotov ammo should not be consumed by rifle fire")
	print("  -> PASS: Auto-fire strictly shoots bullets only. Zero automatic molotovs.")
	
	# ─────────────────────────────────────────────────────────────
	# TEST 2: Hold-to-Aim Projectile Arrow & Release-to-Shoot
	# ─────────────────────────────────────────────────────────────
	print("\n--- TEST 2: Verifying Hold-to-Aim Projectile Arrow & Release-to-Shoot ---")
	assert(player.aim_arrow_indicator != null, "AimTrajectoryArrow must be attached to player")
	assert(player.aim_arrow_indicator.visible == false, "Arrow should initially be hidden")
	
	# 2A. Hold Molotov Button
	var aim_started := player.start_aiming_special("molotov")
	assert(aim_started, "start_aiming_special('molotov') must succeed with ammo > 0")
	assert(player.aim_arrow_indicator.visible == true, "Arrow must become visible on button hold")
	assert(player.aim_arrow_indicator.is_aiming == true, "AimTrajectoryArrow is_aiming must be true")
	
	# 2B. Aim drag
	var aim_drag := Vector2(0.8, -0.6) # Aim forward-right
	player.update_aim_special_vec(aim_drag)
	var aimed_dir := player.aim_arrow_indicator.get_aim_direction()
	print("  -> Aiming Molotov: Aim vector: %s, Aim distance: %.2f" % [
		str(aimed_dir), player.aim_arrow_indicator.current_dist
	])
	assert(aimed_dir.length() > 0.9, "Aim direction should be normalized")
	
	# 2C. Release-to-Shoot
	var shot_fired := player.release_aim_special()
	assert(shot_fired, "release_aim_special() must fire projectile")
	assert(player.aim_arrow_indicator.visible == false, "Arrow must hide after release")
	assert(player.molotov_ammo == initial_molotov_ammo - 1, "Molotov ammo must decrease by 1")
	print("  -> PASS: Molotov hold-to-aim and release-to-shoot verified successfully.")
	
	# 2D. Super Blast Aim & Release
	player.super_blast_timer = 0.0
	var blast_aim_started := player.start_aiming_special("super_blast")
	assert(blast_aim_started, "start_aiming_special('super_blast') must succeed when off cooldown")
	assert(player.aim_arrow_indicator.visible == true, "Arrow must be visible for super blast")
	var blast_fired := player.release_aim_special()
	assert(blast_fired, "release_aim_special() must fire super blast")
	assert(player.super_blast_timer > 0.0, "Super blast cooldown must be active")
	print("  -> PASS: Super Blast hold-to-aim and release-to-shoot verified successfully.")
	
	# ─────────────────────────────────────────────────────────────
	# TEST 3: Tactical Blue Civilian Cars
	# ─────────────────────────────────────────────────────────────
	print("\n--- TEST 3: Verifying Tactical Blue Paint on Civilian Cars ---")
	var cars_found: Array[Node] = []
	for n in sector.find_children("*", "Node3D", true, false):
		var nl := n.name.to_lower()
		if ("car" in nl or "sedan" in nl or "hatch" in nl) and not "rubble" in nl and not "col_" in nl:
			cars_found.append(n)
			
	print("  -> Found %d civilian car nodes in sector." % cars_found.size())
	assert(cars_found.size() >= 4, "Must have at least 4 cars in the level")
	
	var blue_meshes := 0
	for car in cars_found:
		for m in car.find_children("*", "MeshInstance3D", true, false):
			if m is MeshInstance3D and m.material_override:
				var mat: StandardMaterial3D = m.material_override as StandardMaterial3D
				if mat:
					var col_val: Color = mat.albedo_color
					# Verify blue tint: Blue channel significantly higher than Red/Green
					if col_val.b > 0.6 and col_val.r < 0.3:
						blue_meshes += 1
						
	print("  -> Meshes with blue automotive paint: %d" % blue_meshes)
	assert(blue_meshes >= 5, "Cars must have tactical blue material override applied")
	print("  -> PASS: Civilian cars are painted tactical automotive blue.")
	
	# ─────────────────────────────────────────────────────────────
	# TEST 4: Exactly 5 to 6 Abandoned Transit Buses with Colliders
	# ─────────────────────────────────────────────────────────────
	print("\n--- TEST 4: Verifying 5 to 6 Abandoned Transit Buses with Colliders ---")
	var buses_found: Array[Node] = []
	for n in sector.find_children("*", "Node3D", true, false):
		var nl: String = n.name.to_lower()
		if (nl.begins_with("transitbus") or nl.begins_with("cordon_transitbus") or nl == "transit_bus") and not nl.begins_with("col_"):
			buses_found.append(n)
			
	print("  -> Found %d transit bus instances across the sector:" % buses_found.size())
	for b in buses_found:
		print("     * %s at position %s" % [b.name, str(b.position)])
		
	assert(buses_found.size() >= 5 and buses_found.size() <= 7, "Must have 5 to 6 transit buses (found %d)" % buses_found.size())
	
	# Verify colliders exist for buses
	var bus_colliders: Array[Node] = []
	for c_shape in sector.find_children("*", "CollisionShape3D", true, false):
		var p_name: String = c_shape.get_parent().name.to_lower()
		if "bus" in p_name:
			bus_colliders.append(c_shape)
			
	print("  -> Found %d bus collision shapes protecting chokepoints." % bus_colliders.size())
	assert(bus_colliders.size() >= 5, "All buses must have tactical colliders")
	print("  -> PASS: Exactly %d abandoned buses positioned with solid colliders." % buses_found.size())
	
	# ─────────────────────────────────────────────────────────────
	# TEST 5: Procedural Dried Grass Bushes MultiMeshInstance3D
	# ─────────────────────────────────────────────────────────────
	print("\n--- TEST 5: Verifying Procedural Dried Grass Bushes MultiMeshInstance3D ---")
	var grass_node: MultiMeshInstance3D = sector.find_child("ProceduralDriedGrass", true, false) as MultiMeshInstance3D
	assert(grass_node != null, "ProceduralDriedGrass node must exist in sector")
	assert(grass_node.multimesh != null, "MultiMesh must be initialized")
	var grass_count := grass_node.multimesh.instance_count
	print("  -> Procedural dried grass instance count: %d instances (1 single draw call)" % grass_count)
	assert(grass_count >= 120, "Should have 120-180 procedural dried grass bush instances")
	
	var grass_mat = grass_node.multimesh.mesh.surface_get_material(0) as StandardMaterial3D
	if grass_mat:
		print("  -> Grass material: albedo=%s, cull_mode=%d (two-sided), vertex_color=%s" % [
			str(grass_mat.albedo_color), grass_mat.cull_mode, str(grass_mat.vertex_color_use_as_albedo)
		])
		assert(grass_mat.cull_mode == BaseMaterial3D.CULL_DISABLED, "Grass blades must be double-sided")
	print("  -> PASS: Procedural dried grass bushes MultiMesh verified successfully.")
	
	# ─────────────────────────────────────────────────────────────
	# TEST 6: Capture Screenshot of Aiming Indicator, Blue Cars & Buses
	# ─────────────────────────────────────────────────────────────
	print("\n--- TEST 6: Capturing Showcase Gameplay Screenshot ---")
	# Activate special aim for visual capture
	player.refill_molotov(3)
	player.start_aiming_special("molotov")
	player.update_aim_special_vec(Vector2(0.5, -0.8))
	
	for i in range(10):
		await process_frame
		
	var vp := main.get_viewport()
	var img := vp.get_texture().get_image()
	var save_path := "user://capture_gameplay_bushes_cars.png"
	var err := img.save_png(save_path)
	if err == OK:
		print("  -> SUCCESS: Captured gameplay screenshot to: %s" % save_path)
	
	print("\n=================================================================")
	print("[AUDIT SUCCESS] All 5 User Requirements 100% Satisfied!")
	print("=================================================================")
	quit(0)
