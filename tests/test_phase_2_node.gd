extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("--- AUDITING PHASE 2 BUILD (OUTPOST HUB & 3D ASSETS) ---")
	print("=======================================================\n")
	
	var pass_count: int = 0
	var fail_count: int = 0
	
	# Instantiate OutpostHub
	var hub_scene: PackedScene = load("res://scenes/ui/outpost_hub.tscn")
	if hub_scene == null:
		print("  -> CRITICAL FAIL: Could not load outpost_hub.tscn!")
		get_tree().quit(1)
		return
		
	var hub = hub_scene.instantiate()
	add_child(hub)
	await get_tree().process_frame
	
	# Test 1: Outpost Hub Instantiation & Top Bar
	print("[CHECK 1] Outpost Hub Initialization & Top Bar...")
	var badge: Label = hub.get_node_or_null("%ClearanceBadge")
	var coins: Label = hub.get_node_or_null("%CoinsLabel")
	var cores: Label = hub.get_node_or_null("%CoresLabel")
	if badge != null and coins != null and cores != null:
		print("  -> PASS: Outpost Hub instantiated with live economy/clearance counters.")
		pass_count += 1
	else:
		print("  -> FAIL: Missing top bar nodes!")
		fail_count += 1
		
	# Test 2: 3D Diorama & Imported GLB
	print("\n[CHECK 2] Live 3D Outpost Diorama Background...")
	var diorama: Node = hub.find_child("OutpostDiorama", true, false)
	var diorama_mesh: Node = diorama.find_child("OutpostMesh", true, false) if diorama else null
	if diorama != null and diorama_mesh != null:
		print("  -> PASS: Outpost Diorama GLB loaded and rendered in live 3D background.")
		pass_count += 1
	else:
		print("  -> FAIL: Diorama background or OutpostMesh missing! Diorama=%s, Mesh=%s" % [diorama != null, diorama_mesh != null])
		fail_count += 1

	# Test 3: Tab Switching Logic
	print("\n[CHECK 3] Navigation Dock Tab Switching...")
	hub.switch_tab(hub.Tab.ARMORY)
	var armory_vis: bool = hub.view_armory.visible and not hub.view_command.visible
	hub.switch_tab(hub.Tab.SKILLS)
	var skills_vis: bool = hub.view_skills.visible and not hub.view_armory.visible
	hub.switch_tab(hub.Tab.BASE_UPGRADES)
	var upgrades_vis: bool = hub.view_upgrades.visible and not hub.view_skills.visible
	hub.switch_tab(hub.Tab.COMMAND_BOARD)
	var command_vis: bool = hub.view_command.visible and not hub.view_upgrades.visible
	
	if armory_vis and skills_vis and upgrades_vis and command_vis:
		print("  -> PASS: All 4 navigation tabs switch and isolate view states cleanly.")
		pass_count += 1
	else:
		print("  -> FAIL: Tab switching view state failure!")
		fail_count += 1

	# Test 4: Armory 3D Weapon Models & Inspection
	print("\n[CHECK 4] Armory 3D Weapon Inspection & GLB Swapping...")
	hub.switch_tab(hub.Tab.ARMORY)
	hub.select_weapon("assault_carbine")
	var c_mesh: Node3D = hub._active_weapon_mesh
	hub.select_weapon("tactical_shotgun")
	var s_mesh: Node3D = hub._active_weapon_mesh
	hub.select_weapon("high_caliber_smg")
	var smg_mesh: Node3D = hub._active_weapon_mesh
	
	if c_mesh != null and s_mesh != null and smg_mesh != null and c_mesh != s_mesh and s_mesh != smg_mesh:
		print("  -> PASS: All 3 weapons (Carbine, Shotgun, SMG) loaded and swappable in 3D viewport.")
		pass_count += 1
	else:
		print("  -> FAIL: Weapon models failed inspection check!")
		fail_count += 1

	# Test 5: Armory Stat Upgrade Execution
	print("\n[CHECK 5] Armory 4-Track Stat Upgrades...")
	var gm: Node = get_node_or_null("/root/GameManager")
	gm.survival_coins = 5000
	hub.select_weapon("assault_carbine")
	var prev_dmg_lv: int = gm.get_weapon_upgrade_level("assault_carbine", "damage_knockback")
	hub._on_upgrade_stat("damage_knockback")
	var new_dmg_lv: int = gm.get_weapon_upgrade_level("assault_carbine", "damage_knockback")
	print("  -> Carbine Overpressure Rounds Tier: %d -> %d" % [prev_dmg_lv, new_dmg_lv])
	if new_dmg_lv == prev_dmg_lv + 1:
		print("  -> PASS: Weapon upgrade transaction executed and updated in GameManager.")
		pass_count += 1
	else:
		print("  -> FAIL: Weapon upgrade failed to increment!")
		fail_count += 1

	# Test 6: Operative Skills Matrix Unlocking & Equipping
	print("\n[CHECK 6] Operative Skills Matrix & Pairing...")
	hub.switch_tab(hub.Tab.SKILLS)
	gm.research_cores = 50
	gm.clearance_level = 10
	gm.unequip_skill(0)
	gm.unequip_skill(1)
	
	# Unlock and equip blood_siphon
	hub._on_skill_action_pressed("blood_siphon")
	var eq1: Array[String] = gm.get_equipped_skills()
	print("  -> Equipped after 1st action: %s" % str(eq1))
	
	# Unlock and equip hemorrhage_rounds (Crimson Berserker Pair)
	hub._on_skill_action_pressed("hemorrhage_rounds")
	var eq2: Array[String] = gm.get_equipped_skills()
	print("  -> Equipped after 2nd action (Synergy Pair): %s" % str(eq2))
	
	if eq2[0] == "blood_siphon" and eq2[1] == "hemorrhage_rounds":
		print("  -> PASS: Paired skill synergy unlocked and equipped into dual slots.")
		pass_count += 1
	else:
		print("  -> FAIL: Skill pair equipping failed!")
		fail_count += 1

	# Test 7: Outpost Facility Upgrades
	print("\n[CHECK 7] Outpost Facility Upgrades (Comms, Medbay, Helipad)...")
	hub.switch_tab(hub.Tab.BASE_UPGRADES)
	var prev_comms: int = gm.get_outpost_level("comms_array")
	hub._on_upgrade_outpost_facility("comms_array")
	var new_comms: int = gm.get_outpost_level("comms_array")
	print("  -> Comms Array Level: %d -> %d" % [prev_comms, new_comms])
	if new_comms == prev_comms + 1:
		print("  -> PASS: Outpost facility upgraded successfully.")
		pass_count += 1
	else:
		print("  -> FAIL: Facility upgrade failed!")
		fail_count += 1

	# Test 8: Settings Modal Dialog
	print("\n[CHECK 8] Settings Modal Dialog Operations...")
	var modal: Control = hub.settings_modal
	modal.open()
	var is_open: bool = modal.visible
	modal._on_master_changed(65.0)
	var am: Node = get_node_or_null("/root/AudioManager")
	var vol_updated: bool = is_equal_approx(am.master_volume, 0.65)
	modal.close()
	await get_tree().create_timer(0.2).timeout
	var is_closed: bool = not modal.visible
	
	if is_open and vol_updated and is_closed:
		print("  -> PASS: Settings modal opened, modified audio volume, and closed cleanly.")
		pass_count += 1
	else:
		print("  -> FAIL: Settings modal operations failed! Open=%s, Vol=%s, Closed=%s" % [is_open, vol_updated, is_closed])
		fail_count += 1

	print("\n=======================================================")
	print("--- AUDIT RESULT: %d PASSED, %d FAILED ---" % [pass_count, fail_count])
	print("=======================================================\n")
	
	if fail_count > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
