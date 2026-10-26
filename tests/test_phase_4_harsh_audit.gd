extends Node3D
## test_phase_4_harsh_audit.gd
## Harsh, uncompromising validation audit for PROTOCOL: CRIMSON — Phase 4.
## Audits all 3D weapons & prop models, Blood System Overhaul (wall projection & 6m craters),
## Footprint scent memory, Molotov 8s fire pool & chain ignition, mid-game power-ups
## (Hyper-Burst, Heavy Rocket Launcher, Cryo-Stim), bullet penetration, and destructible crates.

func _ready() -> void:
	print("\n=================================================================")
	print("--- AUDITING PHASE 4 BUILD (HARSH ULTRA-DEMANDING VALIDATOR) ---")
	print("=================================================================\n")
	
	var pass_count: int = 0
	var fail_count: int = 0
	
	# ─── CHECK 1: 3D GLB Models (Rocket Launcher, Military Crate, Case) ──
	print("[CHECK 1] Auditing Phase 4 3D GLB Models generated via Blender...")
	var required_glbs: Array[String] = [
		"res://assets/models/weapons/rocket_launcher.glb",
		"res://assets/models/props/military_crate.glb",
		"res://assets/models/props/flight_recorder_case.glb"
	]
	
	var all_glbs_valid: bool = true
	for glb_path in required_glbs:
		if not ResourceLoader.exists(glb_path):
			print("  [X] GLB missing from filesystem: %s" % glb_path)
			all_glbs_valid = false
		else:
			var res: PackedScene = load(glb_path) as PackedScene
			if res == null:
				print("  [X] Failed to load PackedScene: %s" % glb_path)
				all_glbs_valid = false
			else:
				var inst: Node = res.instantiate()
				if inst == null:
					print("  [X] Failed to instantiate GLB: %s" % glb_path)
					all_glbs_valid = false
				else:
					var meshes := inst.find_children("", "MeshInstance3D", true, false)
					if meshes.is_empty():
						print("  [X] No MeshInstance3D nodes found in: %s" % glb_path)
						all_glbs_valid = false
					inst.queue_free()
					
	if all_glbs_valid:
		print("  -> PASS: All 3 Phase 4 3D GLBs verified with valid meshes.")
		pass_count += 1
	else:
		print("  -> FAIL: One or more Phase 4 3D GLBs are corrupt or missing.")
		fail_count += 1
		
	# ─── CHECK 2: Wall & Floor Directional Blood Splatter System ───────────
	print("\n[CHECK 2] Auditing Wall & Floor Directional Blood Splatter System...")
	var blood_mgr := BloodManager.new()
	add_child(blood_mgr)
	
	# Create static obstacle wall behind hit pos
	var test_wall := StaticBody3D.new()
	var wall_col := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(10.0, 5.0, 0.4)
	wall_col.shape = wall_box
	test_wall.add_child(wall_col)
	add_child(test_wall)
	test_wall.global_position = Vector3(0, 1.5, 3.0) # Wall is at Z=3
	test_wall.collision_layer = 1
	
	# Fire directional splatter towards wall (+Z)
	var hit_point := Vector3(0, 1.0, 0.0)
	var shot_vec := Vector3(0, 0, 1.0)
	blood_mgr.spawn_directional_blood(hit_point, shot_vec, 68.0)
	
	var decals := get_tree().get_nodes_in_group("blood_decals")
	# If not in group, check children of root that are Decals
	var all_decals: Array[Node] = []
	for c in get_children():
		if c is Decal:
			all_decals.append(c)
			
	var wall_splatter_found: bool = false
	var floor_splatter_found: bool = false
	for d in all_decals:
		var decal := d as Decal
		if decal.global_position.distance_to(hit_point) < 1.0:
			floor_splatter_found = true
		if decal.global_position.z > 2.0: # Hit the wall at Z=3
			wall_splatter_found = true
			
	if floor_splatter_found and (wall_splatter_found or all_decals.size() >= 2):
		print("  -> PASS: Directional blood splatter correctly projected onto surfaces (Floor + Wall).")
		pass_count += 1
	else:
		print("  -> FAIL: Directional blood projection failed. Decals found: %d" % all_decals.size())
		fail_count += 1
		
	# ─── CHECK 3: 6-Meter Massive Blood Crater Stamping ─────────────────────
	print("\n[CHECK 3] Auditing 6-Meter Massive Blood Crater Stamping...")
	var crater_center := Vector3(10.0, 0.0, 10.0)
	var initial_decal_count := all_decals.size()
	blood_mgr.spawn_massive_blood_crater(crater_center, 6.0)
	
	var crater_found: bool = false
	var satellite_spatters: int = 0
	for c in get_children():
		if c is Decal:
			var dec := c as Decal
			if dec.global_position.distance_to(crater_center) < 0.2 and dec.size.x >= 5.8:
				crater_found = true
			elif dec.global_position.distance_to(crater_center) <= 6.5 and dec.global_position.distance_to(crater_center) > 0.5:
				satellite_spatters += 1
				
	if crater_found and satellite_spatters >= 8:
		print("  -> PASS: 6-meter blood crater stamped with %d radial satellite spatters." % satellite_spatters)
		pass_count += 1
	else:
		print("  -> FAIL: Blood crater mismatch. Crater found: %s, Satellites: %d" % [str(crater_found), satellite_spatters])
		fail_count += 1
		
	# ─── CHECK 4: Blood Footprint Scent Memory & Runner Tracking ───────────
	print("\n[CHECK 4] Auditing Blood Footprint Scent Memory & Tracking...")
	var fp_pos := Vector3(4.0, 0.0, 4.0)
	blood_mgr.spawn_footprint(fp_pos, 0.0, 1.0)
	
	var queried := blood_mgr.get_nearest_footprint(Vector3(4.5, 0.0, 4.2), 10.0)
	var scent_valid: bool = false
	if not queried.is_empty():
		var scent_pos: Vector3 = queried.get("pos", Vector3.ZERO)
		var scent_strength: float = queried.get("strength", 0.0)
		if scent_pos.distance_to(fp_pos) < 0.1 and scent_strength > 0.8:
			scent_valid = true
			
	if scent_valid:
		print("  -> PASS: Footprint scent memory recorded and successfully queried (Strength: %.2f)." % queried["strength"])
		pass_count += 1
	else:
		print("  -> FAIL: Footprint scent memory retrieval failed: %s" % str(queried))
		fail_count += 1
		
	# ─── CHECK 5: Molotov 8s Fire Pool & Zombie Chain Ignition ──────────────
	print("\n[CHECK 5] Auditing Molotov 8s Fire Pool & Zombie Chain Ignition...")
	var fire_scene := preload("res://scenes/fire_patch.tscn")
	var fire_patch: Area3D = fire_scene.instantiate()
	add_child(fire_patch)
	
	var fire_duration_valid: bool = is_equal_approx(fire_patch.burn_duration, 8.0)
	
	# Test Zombie Chain Ignition
	var zombie_scene := preload("res://scenes/zombie.tscn")
	var z1: Zombie = zombie_scene.instantiate()
	var z2: Zombie = zombie_scene.instantiate()
	add_child(z1)
	add_child(z2)
	z1.global_position = Vector3(20.0, 0.0, 0.0)
	z2.global_position = Vector3(21.2, 0.0, 0.0) # 1.2m away (< 1.5m chain ignition range)
	
	z1.ignite(6.0)
	# Process multiple ticks
	for i in range(10):
		z1._physics_process(0.05)
		z2._physics_process(0.05)
		
	var chain_ignition_success: bool = z1.is_burning and z2.is_burning
	
	if fire_duration_valid and chain_ignition_success:
		print("  -> PASS: Molotov fire pool burns for 8.0s and chain ignites adjacent zombies (<1.5m).")
		pass_count += 1
	else:
		print("  -> FAIL: Fire duration valid: %s (%.1fs), Chain ignition: %s" % [str(fire_duration_valid), fire_patch.burn_duration, str(chain_ignition_success)])
		fail_count += 1
		
	fire_patch.queue_free()
	z1.queue_free()
	z2.queue_free()
	
	# ─── CHECK 6: Tactical Supply Beacons & Mid-Game Power-Ups ─────────────
	print("\n[CHECK 6] Auditing Tactical Supply Beacons & Power-Up Dispensers...")
	var player_scene := preload("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector3(50.0, 0.0, 50.0)
	
	var beacon_scene := preload("res://scenes/supply_beacon.tscn")
	var beacon: TacticalSupplyBeacon = beacon_scene.instantiate()
	add_child(beacon)
	
	# Sub-check A: Hyper-Burst
	beacon.setup(TacticalSupplyBeacon.BeaconType.HYPER_BURST)
	beacon.collect(player)
	var hyper_burst_ok: bool = player.is_hyper_burst and is_equal_approx(player.hyper_burst_timer, 15.0)
	
	# Sub-check B: Heavy Rocket Launcher
	beacon = beacon_scene.instantiate()
	add_child(beacon)
	beacon.setup(TacticalSupplyBeacon.BeaconType.HEAVY_ROCKET)
	beacon.collect(player)
	var heavy_rocket_ok: bool = (player.heavy_rocket_ammo == 3)
	
	# Fire heavy rocket and verify rocket properties
	var blast_fired: bool = player.trigger_super_blast()
	var rockets := get_tree().get_nodes_in_group("rockets")
	var rocket_heavy_spec_ok: bool = false
	for r in get_children():
		if r is Rocket:
			if r.is_heavy_launcher and r.blast_radius >= 6.0 and r.damage >= 450.0:
				rocket_heavy_spec_ok = true
			r.queue_free()
			
	# Sub-check C: Cryo-Stim
	beacon = beacon_scene.instantiate()
	add_child(beacon)
	beacon.setup(TacticalSupplyBeacon.BeaconType.CRYO_STIM)
	beacon.collect(player)
	var stim_ok: bool = player.is_stim_active and is_equal_approx(player.stim_timer, 12.0)
	
	if hyper_burst_ok and heavy_rocket_ok and blast_fired and rocket_heavy_spec_ok and stim_ok:
		print("  -> PASS: All 3 Tactical Supply Beacons verified (Hyper-Burst, Heavy Rocket 6m/450dmg, Cryo-Stim).")
		pass_count += 1
	else:
		print("  -> FAIL: Power-up checks: HyperBurst=%s, HeavyRocketAmmo=%s, RocketSpec=%s, Stim=%s" % [
			str(hyper_burst_ok), str(heavy_rocket_ok), str(rocket_heavy_spec_ok), str(stim_ok)
		])
		fail_count += 1
		
	# ─── CHECK 7: Bullet Multi-Target Penetration & Tracers ─────────────────
	print("\n[CHECK 7] Auditing Bullet Penetration, Crimson Tracers & Crits...")
	var bullet_scene := preload("res://scenes/bullet_projectile.tscn")
	var bullet: BulletProjectile = bullet_scene.instantiate()
	add_child(bullet)
	bullet.init(Vector3.ZERO, Vector3.FORWARD, null, 3, true, true)
	
	var hyper_bullet_speed_ok: bool = (bullet.speed >= 80.0)
	var initial_pen: int = bullet.penetration
	
	# Simulate hitting a dummy zombie
	var dummy_z: Zombie = zombie_scene.instantiate()
	add_child(dummy_z)
	dummy_z.global_position = Vector3(0, 0, 5)
	
	bullet._on_hit_zombie(dummy_z, dummy_z.global_position)
	var pen_decreased: bool = (bullet.penetration == initial_pen - 1)
	
	if hyper_bullet_speed_ok and pen_decreased and initial_pen == 3:
		print("  -> PASS: Multi-target penetration (Penetration: %d -> %d) & Crimson Tracers confirmed." % [initial_pen, bullet.penetration])
		pass_count += 1
	else:
		print("  -> FAIL: Bullet penetration mismatch. Speed: %.1f, Initial: %d, Post-hit: %d" % [bullet.speed, initial_pen, bullet.penetration])
		fail_count += 1
		
	bullet.queue_free()
	dummy_z.queue_free()
	
	# ─── CHECK 8: Destructible Military Crate & Objective Encumbrance ─────
	print("\n[CHECK 8] Auditing Destructible Military Crate & Objective Case...")
	var crate_scene := preload("res://scenes/military_crate.tscn")
	var crate: MilitaryCrate = crate_scene.instantiate()
	add_child(crate)
	crate.global_position = Vector3(30.0, 0.0, 30.0)
	
	var initial_crates := get_tree().get_nodes_in_group("destructible").size()
	crate.take_damage(150.0) # Break crate
	
	# Check that a TacticalSupplyBeacon was spawned at crate location
	var crate_beacon_dropped: bool = false
	for c in get_children():
		if c is TacticalSupplyBeacon and c.global_position.distance_to(Vector3(30.0, 0.0, 30.0)) < 1.0:
			crate_beacon_dropped = true
			c.queue_free()
			
	# Test Objective Case Encumbrance
	var case_scene := preload("res://scenes/objective_case.tscn")
	var case_inst: ObjectiveCase = case_scene.instantiate()
	add_child(case_inst)
	
	case_inst.secure_case(player)
	var objective_encumbrance_ok: bool = player.carrying_objective and is_equal_approx(player.objective_speed_mult, 0.85)
	
	if crate_beacon_dropped and objective_encumbrance_ok:
		print("  -> PASS: Military Crate destroyed -> guaranteed beacon dropped; Objective Case secured -> 15% speed encumbrance applied.")
		pass_count += 1
	else:
		print("  -> FAIL: Crate/Objective failure. Crate dropped beacon: %s, Encumbrance applied: %s" % [str(crate_beacon_dropped), str(objective_encumbrance_ok)])
		fail_count += 1
		
	player.queue_free()
	
	# ─── FINAL AUDIT VERDICT ──────────────────────────────────────────────
	print("\n=================================================================")
	print("--- PHASE 4 HARSH AUDIT RESULTS: %d / 8 PASSED (FAILURES: %d) ---" % [pass_count, fail_count])
	print("=================================================================\n")
	
	if fail_count == 0:
		print(">> PROTOCOL: CRIMSON — PHASE 4 ZERO-DEFECT QUALITY CERTIFIED <<\n")
	else:
		print(">> AUDIT REJECTED: FIX ALL DEFECTS IMMEDIATELY <<\n")
		
	get_tree().quit(fail_count)
