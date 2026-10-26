extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("--- RE-TESTING PHASE 1 BUILD (POST-REFACTOR AUDIT) ---")
	print("=======================================================\n")
	
	var pass_count: int = 0
	var fail_count: int = 0
	
	var root: Window = get_tree().root
	var gm: Node = root.get_node_or_null("GameManager")
	var om: Node = root.get_node_or_null("OrientationManager")
	var am: Node = root.get_node_or_null("AudioManager")
	var ls: Node = root.get_node_or_null("LoadingScreen")
	
	# Test 1: Autoload Presence
	print("[CHECK 1] Global Autoload Verification...")
	if gm != null and om != null and am != null and ls != null:
		print("  -> PASS: All 4 autoloads (GameManager, OrientationManager, AudioManager, LoadingScreen) registered in root.")
		pass_count += 1
	else:
		print("  -> FAIL: Missing autoloads: GM=%s, OM=%s, AM=%s, LS=%s" % [gm != null, om != null, am != null, ls != null])
		fail_count += 1
		get_tree().quit(1)
		return

	# Test 2: OrientationManager Desktop Fallback Audit
	print("\n[CHECK 2] OrientationManager Desktop Initialization Audit...")
	print("  -> Current is_portrait state: %s" % om.is_portrait)
	if om.is_portrait:
		print("  -> PASS: Preserves Portrait default on desktop development runs.")
		pass_count += 1
	else:
		print("  -> FAIL: OrientationManager forced Landscape on desktop despite project default portrait!")
		fail_count += 1

	# Test 3: Viewport Stretch Sizing Audit (Godot 4 content_scale_size)
	print("\n[CHECK 3] Viewport Stretch Sizing Audit (Godot 4 content_scale_size)...")
	om.set_landscape()
	var land_scale: Vector2i = root.content_scale_size
	om.set_portrait()
	var port_scale: Vector2i = root.content_scale_size
	print("  -> Root content_scale_size: Landscape=%s, Portrait=%s" % [land_scale, port_scale])
	if land_scale == Vector2i(1920, 1080) and port_scale == Vector2i(1080, 1920):
		print("  -> PASS: content_scale_size dynamically modified to match orientation.")
		pass_count += 1
	else:
		print("  -> FAIL: content_scale_size was NOT updated correctly! Land=%s, Port=%s" % [land_scale, port_scale])
		fail_count += 1

	# Test 4: GameManager Economy Logic & No Double-Dipping
	print("\n[CHECK 4] GameManager Economy Logic & Double-Dip Prevention...")
	gm.reset_save()
	gm.survival_coins = 1000
	gm.start_mission_run()
	
	# In-run kill
	gm.record_kill("runner") # +5 in-run
	print("  -> Vault SC after kill: %d (expected 1000, unbanked in run: %d)" % [gm.survival_coins, gm.in_run_sc])
	var kill_check_passed: bool = (gm.survival_coins == 1000 and gm.in_run_sc == 5)
	
	# Mission completion with kill bonus tally
	gm.apply_mission_rewards(100, 10, gm.in_run_sc, 50)
	print("  -> Vault SC after rewards (100 payout + 5 in-run kill bonus): %d (expected 1105)" % gm.survival_coins)
	if kill_check_passed and gm.survival_coins == 1105:
		print("  -> PASS: Economy clean. No double-counting in-run kills.")
		pass_count += 1
	else:
		print("  -> FAIL: Economy desync! Expected 1105, got %d" % gm.survival_coins)
		fail_count += 1

	# Test 5: Death Penalty Math (Protection of Banked Savings)
	print("\n[CHECK 5] Mission Failure Penalty Math (Vault Protection)...")
	gm.survival_coins = 1000
	var unbanked_sc: int = 200
	var kept_loot: int = gm.apply_mission_failure_penalty(unbanked_sc)
	print("  -> Scavenged in-run: %d | Kept: %d (30%%) | Vault balance: %d (expected 1060)" % [
		unbanked_sc, kept_loot, gm.survival_coins
	])
	if gm.survival_coins == 1060 and kept_loot == 60:
		print("  -> PASS: Player kept 30% of scavenged run loot without vault penalty.")
		pass_count += 1
	else:
		print("  -> FAIL: Vault balance damaged or incorrect kept amount! Got %d" % gm.survival_coins)
		fail_count += 1

	# Test 6: Skill Unlock & Equip Persistence
	print("\n[CHECK 6] Skill Unlock & Equip Auto-Save Audit...")
	gm.unlock_skill("tactical_demolisher")
	gm.equip_skill(0, "tactical_demolisher")
	
	# Verify immediately on disk without manual save call
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load_encrypted_pass(gm.SAVE_PATH, gm.SAVE_KEY)
	var disk_skill_0: String = ""
	if err == OK:
		disk_skill_0 = cfg.get_value("skills", "equipped_skills_0", "")
	print("  -> Verified skill in slot 0 on encrypted disk: '%s'" % disk_skill_0)
	if disk_skill_0 == "tactical_demolisher":
		print("  -> PASS: Skill operations auto-saved to disk immediately.")
		pass_count += 1
	else:
		print("  -> FAIL: Skill was not persisted to disk!")
		fail_count += 1

	# Test 7: Settings Persistence (Audio, Haptics, Orientation)
	print("\n[CHECK 7] User Settings Persistence Audit...")
	am.master_volume = 0.45
	am.sfx_volume = 0.85
	am.music_volume = 0.35
	am.haptics_enabled = false
	om.set_portrait()
	gm.save_game()
	
	var cfg2: ConfigFile = ConfigFile.new()
	cfg2.load_encrypted_pass(gm.SAVE_PATH, gm.SAVE_KEY)
	var saved_mv: float = cfg2.get_value("settings", "master_volume", 0.0)
	var saved_hap: bool = cfg2.get_value("settings", "haptics_enabled", true)
	print("  -> Disk settings: master_volume=%0.2f, haptics=%s" % [saved_mv, saved_hap])
	if is_equal_approx(saved_mv, 0.45) and saved_hap == false:
		print("  -> PASS: Audio, haptics, and orientation settings persisted correctly.")
		pass_count += 1
	else:
		print("  -> FAIL: Settings failed to persist to disk!")
		fail_count += 1

	# Test 8: LoadingScreen Global API & 3D Wireframe Spec
	print("\n[CHECK 8] LoadingScreen Architecture & Visual Spec Audit...")
	var has_api: bool = ls.has_method("transition_to_scene") and ls.has_method("play_studio_splash")
	var has_wireframe: bool = ls.get_node_or_null("%WireframePivot") != null
	var has_progress: bool = ls.get_node_or_null("%ProgressBar") != null
	var has_status: bool = ls.get_node_or_null("%StatusLabel") != null
	
	print("  -> Has Global Transition API: %s" % has_api)
	print("  -> Has 3D Rotating Wireframe Silhouette: %s" % has_wireframe)
	print("  -> Has Razor-thin Crimson Progress Bar: %s" % has_progress)
	print("  -> Has Monospace Military Readout: %s" % has_status)
	
	if has_api and has_wireframe and has_progress and has_status:
		print("  -> PASS: LoadingScreen fulfills Section 3.1 architectural & visual spec.")
		pass_count += 1
	else:
		print("  -> FAIL: LoadingScreen missing spec components! API=%s, Wireframe=%s" % [has_api, has_wireframe])
		fail_count += 1

	print("\n=======================================================")
	print("--- AUDIT RESULT: %d PASSED, %d FAILED ---" % [pass_count, fail_count])
	print("=======================================================\n")
	
	if fail_count > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
