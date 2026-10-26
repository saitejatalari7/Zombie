extends SceneTree

func _initialize() -> void:
	# Wait for autoloads to be initialized and added to root
	await process_frame
	await process_frame
	
	print("\n=======================================================")
	print("--- AUDITING PHASE 1 BUILD (HARSH STRESS VALIDATION) ---")
	print("=======================================================\n")
	
	var pass_count := 0
	var fail_count := 0
	
	# Test 1: Autoload Presence
	print("[CHECK 1] Autoload Node Detection in Root...")
	var gm = root.get_node_or_null("GameManager")
	var om = root.get_node_or_null("OrientationManager")
	var am = root.get_node_or_null("AudioManager")
	
	if gm != null and om != null and am != null:
		print("  -> PASS: All 3 autoloads registered in root.")
		pass_count += 1
	else:
		print("  -> FAIL: Missing autoloads: GM=%s, OM=%s, AM=%s" % [gm != null, om != null, am != null])
		fail_count += 1
		quit(1)
		return
		
	# Test 2: OrientationManager Desktop Fallback Audit
	print("\n[CHECK 2] OrientationManager Desktop Initialization Audit...")
	print("  -> Current is_portrait state: %s" % om.is_portrait)
	if not om.is_portrait:
		print("  -> FLAW IDENTIFIED: OrientationManager forced Landscape on desktop despite project default portrait!")
		fail_count += 1
	else:
		print("  -> PASS: Initial orientation respected portrait.")
		pass_count += 1
		
	# Test 3: Viewport Stretch Sizing Audit
	print("\n[CHECK 3] Viewport Stretch Sizing Audit...")
	var prev_size = root.content_scale_size
	om.set_landscape()
	var land_scale = root.content_scale_size
	om.set_portrait()
	var port_scale = root.content_scale_size
	print("  -> Root content_scale_size in Landscape: %s, in Portrait: %s" % [land_scale, port_scale])
	if land_scale == port_scale:
		print("  -> FLAW IDENTIFIED: root.content_scale_size was NOT updated! Setting ProjectSettings in memory does not resize active viewports in Godot 4!")
		fail_count += 1
	else:
		print("  -> PASS: content_scale_size dynamically modified.")
		pass_count += 1

	# Test 4: GameManager Economy Double-Dip & Penalty Math
	print("\n[CHECK 4] GameManager Economy Logic Audit...")
	gm.reset_save()
	gm.survival_coins = 1000
	gm.record_kill("runner") # +5 SC
	var coins_after_kill = gm.survival_coins
	print("  -> Coins after runner kill: %d (expected 1005)" % coins_after_kill)
	
	gm.apply_mission_rewards(100, 10, 5, 50)
	print("  -> Coins after mission rewards (100 payout + 5 kill bonus): %d" % gm.survival_coins)
	if gm.survival_coins == 1110:
		print("  -> FLAW IDENTIFIED: Double-counting coins! Kill awarded in-run (+5) AND in reward tally (+5) = 1110 instead of 1105!")
		fail_count += 1
	else:
		pass_count += 1
		
	# Simulate Death Penalty Math
	gm.survival_coins = 1000
	var unbanked_in_run := 200
	gm.apply_mission_failure_penalty(unbanked_in_run)
	print("  -> Bank balance after death penalty with 200 unbanked: %d" % gm.survival_coins)
	if gm.survival_coins == 860:
		print("  -> FLAW IDENTIFIED: Deducted 140 from banked savings (1000 -> 860)! The player lost their savings, instead of forfeiting 70% of unbanked run loot!")
		fail_count += 1
	else:
		pass_count += 1

	# Test 5: GameManager Skill Persistence
	print("\n[CHECK 5] Skill Unlock & Equip Persistence Audit...")
	gm.unlock_skill("crimson_berserker")
	gm.equip_skill(0, "crimson_berserker")
	var cfg = ConfigFile.new()
	var err = cfg.load_encrypted_pass(gm.SAVE_PATH, gm.SAVE_KEY)
	var saved_skill_0 = ""
	if err == OK:
		saved_skill_0 = cfg.get_value("skills", "equipped_skills_0", "")
	print("  -> Saved equipped skill on disk without manual save: '%s'" % saved_skill_0)
	if saved_skill_0 != "crimson_berserker":
		print("  -> FLAW IDENTIFIED: unlock_skill() and equip_skill() do NOT auto-save! Progress is volatile until another action triggers save.")
		fail_count += 1
	else:
		pass_count += 1

	# Test 6: Settings Persistence (Audio, Haptics, Orientation)
	print("\n[CHECK 6] Settings Persistence in GameManager Audit...")
	am.master_volume = 0.42
	am.haptics_enabled = false
	gm.save_game()
	var cfg2 = ConfigFile.new()
	cfg2.load_encrypted_pass(gm.SAVE_PATH, gm.SAVE_KEY)
	var has_audio_sec = cfg2.has_section("audio") or cfg2.has_section("settings")
	print("  -> Has audio/settings section in save: %s" % has_audio_sec)
	if not has_audio_sec:
		print("  -> FLAW IDENTIFIED: Volume, haptics, and orientation settings are not saved in save file! They will reset every launch.")
		fail_count += 1
	else:
		pass_count += 1

	# Test 7: LoadingScreen Accessibility & Contract
	print("\n[CHECK 7] LoadingScreen Global Accessibility...")
	var ls_node = root.get_node_or_null("LoadingScreen")
	var has_class = ClassDB.class_exists("LoadingScreen")
	print("  -> Is LoadingScreen an autoload: %s, Is Class registered: %s" % [ls_node != null, has_class])
	if ls_node == null and not has_class:
		print("  -> FLAW IDENTIFIED: LoadingScreen is orphaned! Calling LoadingScreen.transition_to_scene() crashes with undeclared identifier.")
		fail_count += 1
	else:
		pass_count += 1

	print("\n=======================================================")
	print("--- AUDIT SUMMARY: %d PASSED, %d FLAWS DETECTED ---" % [pass_count, fail_count])
	print("=======================================================\n")
	
	quit()
