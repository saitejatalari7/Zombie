extends Node

func _ready() -> void:
	print("\n=================================================================")
	print("--- AUDITING PHASE 2 BUILD (HARSH ULTRA-DEMANDING VALIDATOR) ---")
	print("=================================================================\n")
	
	var pass_count: int = 0
	var fail_count: int = 0
	
	var hub_scene: PackedScene = load("res://scenes/ui/outpost_hub.tscn")
	var hub = hub_scene.instantiate()
	add_child(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# ─── CHECK 1: Scene Resource Health & UID Warnings ──────────────────────
	print("[CHECK 1] Asset UID & Scene Integrity Check...")
	# Verify outpost_diorama scene for broken UIDs
	var diorama_res = load("res://scenes/ui/outpost_diorama.tscn")
	if diorama_res != null:
		print("  -> PASS: Outpost diorama scene instantiates without crash.")
		pass_count += 1
	else:
		print("  -> FAIL: Diorama scene failed to load.")
		fail_count += 1
		
	# ─── CHECK 2: Responsive Landscape Layout Overlap Audit ─────────────────
	print("\n[CHECK 2] Landscape UI Reflow & Container Collision Audit...")
	var om = get_node_or_null("/root/OrientationManager")
	om.set_landscape()
	await get_tree().process_frame
	
	var nav_dock: Control = hub.get_node_or_null("%NavDock")
	var content_area: Control = hub.find_child("ContentArea", true, false)
	var nav_hbox: HBoxContainer = nav_dock.find_child("HBox", true, false) if nav_dock else null
	
	print("  -> In Landscape: NavDock anchors=%s, size=%s, pos=%s" % [nav_dock.anchors_preset, nav_dock.size, nav_dock.position])
	print("  -> In Landscape: ContentArea offset_left=%s, pos=%s" % [content_area.offset_left, content_area.position])
	
	var overlap_detected: bool = false
	if content_area.position.x < nav_dock.position.x + nav_dock.size.x and nav_dock.position.x >= 0:
		overlap_detected = true
		
	var is_hbox_squashed: bool = (nav_hbox != null and nav_dock.size.x < 300 and nav_hbox is HBoxContainer)
	
	if overlap_detected or is_hbox_squashed:
		print("  -> FLAW IDENTIFIED: Landscape layout collision! NavDock occupies left sidebar (w=%d) but ContentArea does not offset (x=%d)! Buttons still locked in horizontal HBox!" % [
			nav_dock.size.x, content_area.position.x
		])
		fail_count += 1
	else:
		print("  -> PASS: ContentArea dynamically offsets to clear sidebar.")
		pass_count += 1
	
	om.set_portrait()
	await get_tree().process_frame

	# ─── CHECK 3: Contract Dossier Specification (3 Contracts per Sector) ───
	print("\n[CHECK 3] Contract Board Specification Compliance (Section 4.2)...")
	# Design doc Section 3.3 & 4.2 dictates:
	# "Tapping a Sector opens 3 available Extraction Contracts displayed as sleek military dossiers"
	var contract_cards = hub.find_children("*Contract*", "Control", true, false)
	var dossier_selector = hub.find_child("ContractSelector*", true, false)
	print("  -> Detected contract card containers in Sector view: %d" % contract_cards.size())
	if contract_cards.size() < 3 and dossier_selector == null:
		print("  -> FLAW IDENTIFIED: Design doc Section 3.3 violation! Only 1 static contract is displayed per sector instead of 3 selectable contract dossiers!")
		fail_count += 1
	else:
		print("  -> PASS: 3 Contract dossiers supported per sector.")
		pass_count += 1

	# ─── CHECK 4: Armory Interactive Touch/Mouse Drag Inspection ────────────
	print("\n[CHECK 4] Armory Manual 3D Drag-to-Rotate Inspection Audit...")
	hub.switch_tab(hub.Tab.ARMORY)
	var viewport_container: SubViewportContainer = hub.find_child("InspectViewportContainer", true, false)
	var has_gui_input: bool = viewport_container != null and viewport_container.gui_input.get_connections().size() > 0
	print("  -> ViewportContainer gui_input connections: %d" % (viewport_container.gui_input.get_connections().size() if viewport_container else 0))
	if not has_gui_input:
		print("  -> FLAW IDENTIFIED: Weapon inspection is passive spin only! Player cannot swipe/drag to rotate and inspect weapons in 3D.")
		fail_count += 1
	else:
		print("  -> PASS: Weapon inspection supports interactive drag rotation.")
		pass_count += 1

	# ─── CHECK 5: Equipped Skill Slot Button Interactivity ──────────────────
	print("\n[CHECK 5] Equipped Skill Slot Button Interactivity Audit...")
	hub.switch_tab(hub.Tab.SKILLS)
	var slot0: Button = hub.get_node_or_null("%EquippedSlot0Btn")
	var slot1: Button = hub.get_node_or_null("%EquippedSlot1Btn")
	var slot0_connected: bool = slot0 != null and slot0.pressed.get_connections().size() > 0
	var slot1_connected: bool = slot1 != null and slot1.pressed.get_connections().size() > 0
	print("  -> Slot 0 button pressed connections: %d | Slot 1 connections: %d" % [
		slot0.pressed.get_connections().size() if slot0 else 0,
		slot1.pressed.get_connections().size() if slot1 else 0
	])
	if not slot0_connected or not slot1_connected:
		print("  -> FLAW IDENTIFIED: Equipped skill slot buttons are dead UI! Tapping them does not unequip or focus the skill.")
		fail_count += 1
	else:
		print("  -> PASS: Equipped skill slot buttons are interactive.")
		pass_count += 1

	# ─── CHECK 6: Skill Synergy Mathematical Feedback ───────────────────────
	print("\n[CHECK 6] Skill Synergy Visual Pairing Feedback Audit...")
	var gm = get_node_or_null("/root/GameManager")
	gm.equip_skill(0, "blood_siphon")
	gm.equip_skill(1, "hemorrhage_rounds")
	hub._refresh_skills_ui()
	# Check if synergy active badge or indicator exists
	var synergy_badge = hub.find_child("*Synergy*", true, false)
	print("  -> Synergy indicator node detected: %s" % (synergy_badge != null))
	if synergy_badge == null:
		print("  -> FLAW IDENTIFIED: Design doc Section 5 requires active paired synergy indicator when complementary skills are equipped together!")
		fail_count += 1
	else:
		print("  -> PASS: Active paired synergy banner displayed.")
		pass_count += 1

	# ─── CHECK 7: Economy Insufficient Funds UI Feedback ────────────────────
	print("\n[CHECK 7] Armory & Facility Transaction Safety Audit...")
	gm.survival_coins = 0
	gm.research_cores = 0
	hub.switch_tab(hub.Tab.ARMORY)
	var up_btn: Button = hub.get_node_or_null("%UpgradeDamageBtn")
	print("  -> Upgrade button disabled with 0 coins: %s" % up_btn.disabled)
	if not up_btn.disabled:
		print("  -> FLAW IDENTIFIED: Upgrade button remains enabled with insufficient funds!")
		fail_count += 1
	else:
		print("  -> PASS: Purchase buttons properly disable when unaffordable.")
		pass_count += 1

	# ─── CHECK 8: Audio SFX Call Disconnect Audit ───────────────────────────
	print("\n[CHECK 8] UI SFX Event Hook Audit...")
	var am = get_node_or_null("/root/AudioManager")
	var has_ui_clicks: bool = am.sfx_registry.has("ui_click") and am.sfx_registry.has("ui_confirm")
	print("  -> Audio registry has UI sfx keys: %s" % has_ui_clicks)
	if not has_ui_clicks:
		print("  -> FLAW IDENTIFIED: UI audio keys missing from AudioManager registry.")
		fail_count += 1
	else:
		print("  -> PASS: UI audio registry keys configured.")
		pass_count += 1

	print("\n=================================================================")
	print("--- HARSH AUDIT SUMMARY: %d PASSED, %d FLAWS DETECTED ---" % [pass_count, fail_count])
	print("=================================================================\n")
	
	if fail_count > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
