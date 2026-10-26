extends Node
## test_phase_3_harsh_audit.gd
## Harsh, uncompromising validation audit for PROTOCOL: CRIMSON — Phase 3.
## Audits all 13 3D GLB assets, 4 Modular Sector scenes, Day/Night manager,
## Player controller flashlight & LOS priority targeting, and HUD responsive reflow.

const SectorBaseScript = preload("res://scripts/sector_base.gd")

func _ready() -> void:
	print("\n=================================================================")
	print("--- AUDITING PHASE 3 BUILD (HARSH ULTRA-DEMANDING VALIDATOR) ---")
	print("=================================================================\n")
	
	var pass_count: int = 0
	var fail_count: int = 0
	
	# ─── CHECK 1: 3D GLB Asset Integrity & Loading (13 Assets) ─────────────
	print("[CHECK 1] Auditing all 13 3D GLB Assets generated via Blender...")
	var required_glbs: Array[String] = [
		"res://assets/models/props/wrecked_car_a.glb",
		"res://assets/models/props/wrecked_car_b.glb",
		"res://assets/models/props/wrecked_car_c.glb",
		"res://assets/models/props/dead_tree_a.glb",
		"res://assets/models/props/dead_tree_b.glb",
		"res://assets/models/props/power_pole.glb",
		"res://assets/models/props/streetlamp.glb",
		"res://assets/models/props/transit_bus.glb",
		"res://assets/models/props/chemical_silo.glb",
		"res://assets/models/props/shipping_container.glb",
		"res://assets/models/sectors/modular_wall.glb",
		"res://assets/models/sectors/modular_floor.glb",
		"res://assets/models/sectors/modular_stairwell.glb"
	]
	
	var missing_glbs: Array[String] = []
	for glb_path in required_glbs:
		if not ResourceLoader.exists(glb_path):
			missing_glbs.append(glb_path)
		else:
			var res: Resource = load(glb_path)
			if res == null:
				missing_glbs.append(glb_path)
				
	if missing_glbs.is_empty():
		print("  -> PASS: All 13 Phase 3 GLB models verified, loaded, and valid.")
		pass_count += 1
	else:
		print("  -> FAIL: Missing or invalid GLB assets: %s" % str(missing_glbs))
		fail_count += 1
		
	# ─── CHECK 2: All 4 Modular City Sectors ────────────────────────────────
	print("\n[CHECK 2] Auditing the 4 Distinct Sector Scenes & Biomes...")
	var sector_paths: Array[String] = [
		"res://scenes/sectors/sector_1_residential.tscn",
		"res://scenes/sectors/sector_2_transit.tscn",
		"res://scenes/sectors/sector_3_industrial.tscn",
		"res://scenes/sectors/sector_4_research.tscn"
	]
	
	var all_sectors_valid: bool = true
	for i in range(sector_paths.size()):
		var p: String = sector_paths[i]
		if not ResourceLoader.exists(p):
			print("  -> FAIL: Sector scene does not exist: %s" % p)
			all_sectors_valid = false
			continue
			
		var sec_scene: PackedScene = load(p)
		var sec = sec_scene.instantiate()
		if sec == null:
			print("  -> FAIL: Sector %d failed to instantiate" % (i + 1))
			all_sectors_valid = false
			continue
			
		add_child(sec)
		await get_tree().process_frame
		
		# Validate SectorBase contracts
		var has_spawn: bool = ("player_spawn" in sec and sec.player_spawn != null)
		var has_extract: bool = ("extraction_zone" in sec and sec.extraction_zone != null)
		var spawn_count: int = sec.get_spawn_point_transforms().size() if sec.has_method("get_spawn_point_transforms") else 0
		var has_nav: bool = sec.find_child("NavigationRegion3D", true, false) != null
		var has_props: bool = sec.find_child("Props", true, false) != null
		
		var bounds_val = sec.get("sector_bounds")
		var is_night_val = sec.get("is_night_sector")
		
		sec.queue_free()
		await get_tree().process_frame
		
		if not (has_spawn and has_extract and spawn_count >= 4 and has_nav and has_props):
			print("  -> FLAW IDENTIFIED: Sector %d missing critical requirements! (Spawn: %s, Extract: %s, Spawners: %d, Nav: %s, Props: %s)" % [
				i + 1, str(has_spawn), str(has_extract), spawn_count, str(has_nav), str(has_props)
			])
			all_sectors_valid = false
		else:
			print("  -> PASS: Sector %d valid. (Spawners: %d, Bounds: %s, Night: %s)" % [
				i + 1, spawn_count, str(bounds_val), str(is_night_val)
			])
			
	if all_sectors_valid:
		print("  -> PASS: All 4 Sector biomes satisfy specification.")
		pass_count += 1
	else:
		fail_count += 1
		
	# ─── CHECK 3: DayNightManager Autoload & Lighting Control ───────────────
	print("\n[CHECK 3] Auditing DayNightManager & Day vs. Blackout Lighting...")
	var dnm = get_node_or_null("/root/DayNightManager")
	if dnm == null:
		print("  -> FAIL: DayNightManager is not registered as an Autoload!")
		fail_count += 1
	else:
		dnm.set_day_mode()
		var day_ok: bool = not dnm.is_night_mode()
		
		dnm.set_sector_mode(3) # Sector 3 must trigger mandatory night ops
		var night_sec3_ok: bool = dnm.is_night_mode()
		
		var test_env: Environment = Environment.new()
		var test_sun: DirectionalLight3D = DirectionalLight3D.new()
		dnm.apply_to_environment(test_env, test_sun)
		var night_ambient_dark: bool = test_env.ambient_light_energy <= 0.1
		var night_sun_dim: bool = test_sun.light_energy <= 0.1
		
		dnm.set_day_mode()
		dnm.apply_to_environment(test_env, test_sun)
		var day_ambient_bright: bool = test_env.ambient_light_energy >= 0.5
		var day_sun_bright: bool = test_sun.light_energy >= 1.0
		
		test_sun.free()
		
		if day_ok and night_sec3_ok and night_ambient_dark and night_sun_dim and day_ambient_bright and day_sun_bright:
			print("  -> PASS: DayNightManager properly enforces Day Ops and Night/Blackout Ops (#050507 near-zero ambient).")
			pass_count += 1
		else:
			print("  -> FLAW IDENTIFIED: DayNightManager lighting parameters do not meet strict specifications.")
			fail_count += 1
			
	# ─── CHECK 4: Player Controller Flashlight & Priority LOS Targeting ───
	print("\n[CHECK 4] Auditing Player Flashlight, Auto-Fire, and Priority LOS Targeting...")
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var test_player = player_scene.instantiate()
	add_child(test_player)
	await get_tree().process_frame
	
	# Verify TorchLight node exists
	var torch: SpotLight3D = test_player.get("torch_light")
	if torch == null:
		print("  -> FAIL: Player missing SpotLight3D TorchLight node!")
		fail_count += 1
	else:
		test_player._on_lighting_mode_changed(true)
		var torch_on: bool = torch.visible
		test_player._on_lighting_mode_changed(false)
		var torch_off: bool = not torch.visible
		
		if torch_on and torch_off:
			print("  -> PASS: Player Tactical Flashlight dynamically toggles on Day/Night modes.")
			pass_count += 1
		else:
			print("  -> FAIL: TorchLight does not respond to Day/Night mode changes.")
			fail_count += 1
			
	# Check Auto-Fire toggle
	test_player.set_auto_fire(true)
	var auto_on: bool = test_player.auto_fire_enabled
	test_player.set_auto_fire(false)
	var auto_off: bool = not test_player.auto_fire_enabled
	
	if auto_on and auto_off:
		print("  -> PASS: Auto-fire toggle API functional.")
		pass_count += 1
	else:
		print("  -> FAIL: Auto-fire toggle state failed.")
		fail_count += 1
		
	# Check Priority LOS Targeting: Runners > Bosses > Shamblers
	print("  -> Testing Target Priority: Runners > Bosses > Shamblers...")
	var shambler := Node3D.new()
	shambler.name = "TestShambler"
	shambler.add_to_group("zombies")
	add_child(shambler)
	shambler.global_position = test_player.global_position + Vector3(0, 0, -5) # 5m away
	
	var boss := Node3D.new()
	boss.name = "TestBoss"
	boss.add_to_group("bosses")
	add_child(boss)
	boss.global_position = test_player.global_position + Vector3(0, 0, -8) # 8m away
	
	var runner := Node3D.new()
	runner.name = "TestRunner"
	runner.add_to_group("runners")
	add_child(runner)
	runner.global_position = test_player.global_position + Vector3(0, 0, -10) # 10m away
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Even though Runner is furthest (10m vs 5m), Runner MUST be prioritized!
	var selected_target = test_player.get_best_target_with_los(20.0)
	print("  -> Acquired target with priority: %s (Expected: TestRunner)" % (selected_target.name if selected_target else "NULL"))
	
	if selected_target == runner:
		print("  -> PASS: Target selection correctly prioritizes Runners over Bosses and Shamblers!")
		pass_count += 1
	else:
		print("  -> FLAW IDENTIFIED: Target selection failed to prioritize Runner over closer Shambler!")
		fail_count += 1
		
	# Now remove runner and verify Boss is prioritized over closer Shambler
	runner.queue_free()
	await get_tree().process_frame
	var selected_target_2 = test_player.get_best_target_with_los(20.0)
	print("  -> Acquired target without runner: %s (Expected: TestBoss)" % (selected_target_2.name if selected_target_2 else "NULL"))
	if selected_target_2 == boss:
		print("  -> PASS: Target selection correctly prioritizes Boss over Shambler!")
		pass_count += 1
	else:
		print("  -> FLAW IDENTIFIED: Target selection failed to prioritize Boss over Shambler!")
		fail_count += 1
		
	boss.queue_free()
	shambler.queue_free()
	test_player.queue_free()
	await get_tree().process_frame
	
	# ─── CHECK 5: HUD Overhaul & Orientation Layout Reflow ─────────────────
	print("\n[CHECK 5] Auditing Mobile HUD Overhaul, Auto-Fire UI, & Orientation Reflow...")
	var hud_scene: PackedScene = load("res://scenes/ui/mobile_hud.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	await get_tree().process_frame
	
	var has_auto_btn: bool = hud.get("auto_fire_btn") != null
	var has_mission_pill: bool = hud.get("mission_pill") != null
	
	# Test Portrait Layout
	var om = get_node_or_null("/root/OrientationManager")
	om.set_portrait()
	await get_tree().process_frame
	var portrait_auto_y: float = hud.auto_fire_btn.offset_top if has_auto_btn else 0.0
	var portrait_fire_y: float = hud.fire_button.offset_top
	
	# Test Landscape Layout
	om.set_landscape()
	await get_tree().process_frame
	var landscape_auto_x: float = hud.auto_fire_btn.offset_left if has_auto_btn else 0.0
	var landscape_fire_x: float = hud.fire_button.offset_left
	
	print("  -> Portrait positions: AutoFire y=%f, FireButton y=%f" % [portrait_auto_y, portrait_fire_y])
	print("  -> Landscape positions: AutoFire x=%f, FireButton x=%f" % [landscape_auto_x, landscape_fire_x])
	
	var landscape_arc_valid: bool = landscape_auto_x < landscape_fire_x
	
	om.set_portrait()
	hud.queue_free()
	await get_tree().process_frame
	
	if has_auto_btn and has_mission_pill and landscape_arc_valid:
		print("  -> PASS: HUD overhaul successfully validates Auto-Fire button, Mission Tracker Pill, and responsive radial arc reflow.")
		pass_count += 1
	else:
		print("  -> FLAW IDENTIFIED: HUD overhaul failed component or responsive layout audit.")
		fail_count += 1
		
	# ─── FINAL VERDICT ─────────────────────────────────────────────────────
	print("\n=================================================================")
	print(">>> PHASE 3 AUDIT COMPLETE: %d PASSED, %d FAILED <<<" % [pass_count, fail_count])
	print("=================================================================\n")
	
	if fail_count == 0:
		print("ALL PHASE 3 REQUIREMENTS RIGOROUSLY MET! ZERO COMPROMISES.")
	else:
		print("PHASE 3 HAS UNRESOLVED FLAWS TO REMEDIATE.")
		
	get_tree().quit(0 if fail_count == 0 else 1)
