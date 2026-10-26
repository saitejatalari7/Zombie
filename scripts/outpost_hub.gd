extends Control
class_name OutpostHub
## OutpostHub.gd
## Central Operations Hub UI for PROTOCOL: CRIMSON.
## Manages Command Board (Missions), Armory (Weapons & 3D Preview),
## Operative Skills (Paired Matrix), and Base Upgrades.
## Fully responsive between Portrait (1080x1920) and Landscape (1920x1080).

# ─── Tab Enumeration ───────────────────────────────────────────────────────────
enum Tab { COMMAND_BOARD, ARMORY, SKILLS, BASE_UPGRADES }
var current_tab: Tab = Tab.COMMAND_BOARD

# ─── Node References: Top Bar ──────────────────────────────────────────────────
@onready var clearance_badge: Label = %ClearanceBadge
@onready var clearance_progress: ProgressBar = %ClearanceProgress
@onready var clearance_xp_label: Label = %ClearanceXPLabel
@onready var coins_label: Label = %CoinsLabel
@onready var cores_label: Label = %CoresLabel
@onready var settings_btn: Button = %SettingsButton
@onready var settings_modal: Control = %SettingsModal

# ─── Node References: Navigation Dock ──────────────────────────────────────────
@onready var btn_tab_command: Button = %BtnTabCommand
@onready var btn_tab_armory: Button = %BtnTabArmory
@onready var btn_tab_skills: Button = %BtnTabSkills
@onready var btn_tab_upgrades: Button = %BtnTabUpgrades

# ─── Node References: Tab Views ────────────────────────────────────────────────
@onready var view_command: Control = %ViewCommand
@onready var view_armory: Control = %ViewArmory
@onready var view_skills: Control = %ViewSkills
@onready var view_upgrades: Control = %ViewUpgrades

# ─── Command Board Elements ───────────────────────────────────────────────────
@onready var sector_1_btn: Button = %Sector1Btn
@onready var sector_2_btn: Button = %Sector2Btn
@onready var sector_3_btn: Button = %Sector3Btn
@onready var sector_4_btn: Button = %Sector4Btn
@onready var contract_title: Label = %ContractTitle
@onready var contract_desc: Label = %ContractDesc
@onready var contract_type_badge: Label = %ContractTypeBadge
@onready var contract_threat_label: Label = %ContractThreatLabel
@onready var contract_reward_sc: Label = %ContractRewardSC
@onready var contract_reward_rc: Label = %ContractRewardRC
@onready var deploy_btn: Button = %DeployButton

# ─── Armory Elements ──────────────────────────────────────────────────────────
@onready var weapon_carbine_btn: Button = %WeaponCarbineBtn
@onready var weapon_shotgun_btn: Button = %WeaponShotgunBtn
@onready var weapon_smg_btn: Button = %WeaponSMGBtn
@onready var weapon_pivot: Node3D = %WeaponPivot
@onready var weapon_model_holder: Node3D = %WeaponModelHolder
@onready var weapon_title: Label = %WeaponTitle

# Stat Tracks (Damage, Fire Rate, Penetration, Crit)
@onready var stat_damage_bar: ProgressBar = %StatDamageBar
@onready var stat_rate_bar: ProgressBar = %StatRateBar
@onready var stat_pen_bar: ProgressBar = %StatPenBar
@onready var stat_crit_bar: ProgressBar = %StatCritBar

@onready var upgrade_damage_btn: Button = %UpgradeDamageBtn
@onready var upgrade_rate_btn: Button = %UpgradeRateBtn
@onready var upgrade_pen_btn: Button = %UpgradePenBtn
@onready var upgrade_crit_btn: Button = %UpgradeCritBtn

@onready var inspect_viewport_container: SubViewportContainer = %InspectViewportContainer
@onready var content_area: Control = $ContentArea
@onready var nav_box: BoxContainer = %NavBox

# ─── Operative Skills Elements ────────────────────────────────────────────────
@onready var equipped_slot_0_btn: Button = %EquippedSlot0Btn
@onready var equipped_slot_1_btn: Button = %EquippedSlot1Btn
@onready var active_synergy_banner: PanelContainer = %ActiveSynergyBanner
@onready var synergy_bonus_label: Label = %SynergyBonusLabel
@onready var skill_matrix_container: Container = %SkillMatrixContainer

# ─── Base Upgrades Elements ───────────────────────────────────────────────────
@onready var comms_level_label: Label = %CommsLevelLabel
@onready var comms_upgrade_btn: Button = %CommsUpgradeBtn
@onready var medbay_level_label: Label = %MedbayLevelLabel
@onready var medbay_upgrade_btn: Button = %MedbayUpgradeBtn
@onready var helipad_level_label: Label = %HelipadLevelLabel
@onready var helipad_upgrade_btn: Button = %HelipadUpgradeBtn

# ─── State ─────────────────────────────────────────────────────────────────────
var selected_sector: int = 1
var selected_contract_index: int = 0
var next_contract_btn: Button = null
var selected_weapon: String = "assault_carbine"
var _weapon_models: Dictionary = {}
var _active_weapon_mesh: Node3D = null

# Preloaded GLB Weapon Scenes
const SCENE_CARBINE = preload("res://assets/models/weapons/assault_carbine.glb")
const SCENE_SHOTGUN = preload("res://assets/models/weapons/tactical_shotgun.glb")
const SCENE_SMG = preload("res://assets/models/weapons/high_caliber_smg.glb")

# Skill definitions live in GameManager (shared with save refunds)
@onready var skills_data: Dictionary = GameManager.SKILLS_DATA

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_init_weapon_models()
	_connect_top_bar_and_dock()
	_connect_command_board()
	_connect_armory()
	_connect_base_upgrades()
	_build_skill_matrix_ui()
	
	# Connect to GameManager signals
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.coins_changed.connect(_on_coins_changed)
		gm.research_cores_changed.connect(_on_cores_changed)
		gm.clearance_level_changed.connect(_on_clearance_changed)
		gm.clearance_xp_changed.connect(_on_xp_changed)
		gm.skill_equipped.connect(_on_skill_equipped)
		gm.weapon_upgraded.connect(_on_weapon_upgraded)
		gm.outpost_upgraded.connect(_on_outpost_upgraded)
	
	# Connect to OrientationManager
	var om = get_node_or_null("/root/OrientationManager")
	if om:
		om.orientation_changed.connect(_on_orientation_changed)
		_apply_responsive_layout(om.is_portrait)
	
	_lock_unreleased_content()
	
	# Initial UI refresh
	switch_tab(Tab.COMMAND_BOARD)
	select_sector(1)
	select_weapon("assault_carbine")
	_refresh_top_bar()
	_refresh_base_upgrades()


## Weapons and skills that don't work in a run yet can't be selected or bought.
func _lock_unreleased_content() -> void:
	var weapon_buttons := {
		"tactical_shotgun": weapon_shotgun_btn,
		"high_caliber_smg": weapon_smg_btn,
	}
	for weapon_id in weapon_buttons:
		var btn: Button = weapon_buttons[weapon_id]
		if btn and not (weapon_id in GameManager.IMPLEMENTED_WEAPONS):
			btn.disabled = true
			btn.text += "\nIN DEVELOPMENT"
	if btn_tab_skills:
		btn_tab_skills.visible = not GameManager.IMPLEMENTED_SKILLS.is_empty()
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and (gm.pending_refund_sc > 0 or gm.pending_refund_rc > 0):
		_show_toast("REFUNDED %d SC + %d RC for gear still in development" % [gm.pending_refund_sc, gm.pending_refund_rc])
		gm.pending_refund_sc = 0
		gm.pending_refund_rc = 0


func _show_toast(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.0))
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.067, 0.067, 0.075, 0.95)
	bg.set_content_margin_all(14)
	label.add_theme_stylebox_override("normal", bg)
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.offset_left = -300.0
	label.offset_right = 300.0
	label.offset_top = 140.0
	add_child(label)
	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)


func _process(delta: float) -> void:
	# Rotate inspected weapon smoothly
	if weapon_pivot and current_tab == Tab.ARMORY:
		weapon_pivot.rotate_y(delta * 0.9)


# ─── Navigation Dock & Tab Switching ──────────────────────────────────────────
func switch_tab(tab: Tab) -> void:
	current_tab = tab
	
	view_command.visible = (tab == Tab.COMMAND_BOARD)
	view_armory.visible = (tab == Tab.ARMORY)
	view_skills.visible = (tab == Tab.SKILLS)
	view_upgrades.visible = (tab == Tab.BASE_UPGRADES)
	
	# Tab button active visual states
	_update_tab_button_style(btn_tab_command, tab == Tab.COMMAND_BOARD)
	_update_tab_button_style(btn_tab_armory, tab == Tab.ARMORY)
	_update_tab_button_style(btn_tab_skills, tab == Tab.SKILLS)
	_update_tab_button_style(btn_tab_upgrades, tab == Tab.BASE_UPGRADES)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_click")
	
	if tab == Tab.ARMORY:
		select_weapon(selected_weapon)
	elif tab == Tab.SKILLS:
		_refresh_skills_ui()
	elif tab == Tab.BASE_UPGRADES:
		_refresh_base_upgrades()


func _update_tab_button_style(btn: Button, active: bool) -> void:
	if not btn: return
	if active:
		btn.modulate = Color(1.0, 0.15, 0.2, 1.0)
	else:
		btn.modulate = Color(0.75, 0.75, 0.78, 1.0)


# ─── Top Bar Refresh ───────────────────────────────────────────────────────────
func _refresh_top_bar() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm: return
	
	if clearance_badge:
		clearance_badge.text = "CLR-LV.%02d" % gm.clearance_level
	if clearance_progress:
		var req: int = gm.get_xp_for_next_level()
		clearance_progress.max_value = req if req > 0 else 100
		clearance_progress.value = gm.clearance_xp
	if clearance_xp_label:
		clearance_xp_label.text = "%d / %d XP" % [gm.clearance_xp, gm.get_xp_for_next_level()]
	if coins_label:
		coins_label.text = "%d SC" % gm.survival_coins
	if cores_label:
		cores_label.text = "%d RC" % gm.research_cores


func _on_coins_changed(amount: int) -> void:
	if coins_label: coins_label.text = "%d SC" % amount
	_refresh_armory_buttons()
	_refresh_base_upgrades()


func _on_cores_changed(amount: int) -> void:
	if cores_label: cores_label.text = "%d RC" % amount
	_refresh_skills_ui()


func _on_clearance_changed(level: int) -> void:
	_refresh_top_bar()
	_refresh_sector_locks()
	_refresh_skills_ui()


func _on_xp_changed(current: int, req: int) -> void:
	if clearance_progress:
		clearance_progress.max_value = req if req > 0 else 100
		clearance_progress.value = current
	if clearance_xp_label:
		clearance_xp_label.text = "%d / %d XP" % [current, req]


# ─── Command Board (Sectors & Deploy) ─────────────────────────────────────────
func select_sector(sector_id: int, contract_index: int = 0) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var max_sec: int = gm.highest_sector_unlocked if gm else 1
	if sector_id > max_sec:
		return  # Locked
	if gm and not gm.is_sector_playable(sector_id):
		return  # Classified: map not built yet
	
	selected_sector = sector_id
	selected_contract_index = contract_index
	
	# Contract dossier comes from GameManager so advertised reward == actual payout
	if gm:
		var contracts: Array = gm.get_contracts(sector_id)
		selected_contract_index = clampi(contract_index, 0, contracts.size() - 1)
		var c: Dictionary = contracts[selected_contract_index]
		contract_title.text = c["title"]
		var objective: String
		match c.get("job", "kill_quota"):
			"steps":
				var lines := PackedStringArray()
				var n := 1
				for st in c.get("steps", []):
					lines.append("%d. %s" % [n, String(st.get("title", "")).capitalize()])
					n += 1
				lines.append("%d. Extract from the terrace LZ" % n)
				objective = "\n" + "\n".join(lines)
			"asset_recovery":
				objective = "Recover the flight recorder, then reach the extraction LZ."
			_:
				objective = "Eliminate %d hostiles, then reach the extraction LZ." % c["kills_required"]
		contract_desc.text = "%s\n\nOBJECTIVE: %s" % [c["desc"], objective]
		contract_type_badge.text = c["type"]
		contract_threat_label.text = c["threat"]
		var sc_text := "+%d SC" % gm.get_contract_payout_sc(c)
		if not gm.is_sector_cleared(sector_id):
			sc_text += " (FIRST CLEAR x2)"
		contract_reward_sc.text = sc_text
		contract_reward_rc.text = "+%d RC" % c["payout_rc"]
		
		if next_contract_btn:
			next_contract_btn.visible = contracts.size() > 1
			next_contract_btn.text = "CONTRACT %d / %d   ▸ NEXT" % [selected_contract_index + 1, contracts.size()]

	_refresh_sector_locks()


func _refresh_sector_locks() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var max_sec: int = gm.highest_sector_unlocked if gm else 1
	
	var buttons := [sector_1_btn, sector_2_btn, sector_3_btn, sector_4_btn]
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if not btn:
			continue
		var sector_id := i + 1
		var playable: bool = gm.is_sector_playable(sector_id) if gm else sector_id == 1
		btn.disabled = (sector_id > max_sec) or not playable
		btn.text = "SEC-%02d" % sector_id if playable else "SEC-%02d\nCLASSIFIED" % sector_id
	
	if sector_1_btn: sector_1_btn.modulate = Color(1, 0.2, 0.2) if selected_sector == 1 else Color(1, 1, 1)
	if sector_2_btn: sector_2_btn.modulate = Color(1, 0.2, 0.2) if selected_sector == 2 else Color(1, 1, 1)
	if sector_3_btn: sector_3_btn.modulate = Color(1, 0.2, 0.2) if selected_sector == 3 else Color(1, 1, 1)
	if sector_4_btn: sector_4_btn.modulate = Color(1, 0.2, 0.2) if selected_sector == 4 else Color(1, 1, 1)


func _on_deploy_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_confirm")
		if am.has_method("haptic_medium"):
			am.haptic_medium()
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_sector = selected_sector
		gm.current_contract = gm.get_contract(selected_sector, selected_contract_index).duplicate()
		gm.current_contract["sector"] = selected_sector
	
	var dnm = get_node_or_null("/root/DayNightManager")
	if dnm:
		dnm.set_sector_mode(selected_sector)
	
	var ls = get_node_or_null("/root/LoadingScreen")
	if ls and ls.has_method("transition_to_scene"):
		ls.transition_to_scene("res://scenes/main.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


# ─── Armory (3D Weapon Inspection & Upgrades) ─────────────────────────────────
func _init_weapon_models() -> void:
	_weapon_models["assault_carbine"] = SCENE_CARBINE.instantiate()
	_weapon_models["tactical_shotgun"] = SCENE_SHOTGUN.instantiate()
	_weapon_models["high_caliber_smg"] = SCENE_SMG.instantiate()
	
	for key in _weapon_models:
		var node: Node3D = _weapon_models[key]
		node.visible = false
		weapon_model_holder.add_child(node)


func select_weapon(weapon_id: String) -> void:
	selected_weapon = weapon_id
	
	# Swap 3D model
	for key in _weapon_models:
		var node: Node3D = _weapon_models[key]
		node.visible = (key == weapon_id)
		if key == weapon_id:
			_active_weapon_mesh = node
	
	if weapon_title:
		match weapon_id:
			"assault_carbine": weapon_title.text = "ARC-15 ASSAULT CARBINE"
			"tactical_shotgun": weapon_title.text = "TS-12 BREACHING SHOTGUN"
			"high_caliber_smg": weapon_title.text = "VECTOR-50 HEAVY SMG"
	
	# Update selector button highlights
	weapon_carbine_btn.modulate = Color(1, 0.1, 0.2) if weapon_id == "assault_carbine" else Color(1, 1, 1)
	weapon_shotgun_btn.modulate = Color(1, 0.1, 0.2) if weapon_id == "tactical_shotgun" else Color(1, 1, 1)
	weapon_smg_btn.modulate = Color(1, 0.1, 0.2) if weapon_id == "high_caliber_smg" else Color(1, 1, 1)
	
	_refresh_armory_buttons()


func _refresh_armory_buttons() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm: return
	
	var dmg_lv: int = gm.get_weapon_upgrade_level(selected_weapon, "damage_knockback")
	var rate_lv: int = gm.get_weapon_upgrade_level(selected_weapon, "fire_rate_mag")
	var pen_lv: int = gm.get_weapon_upgrade_level(selected_weapon, "penetration")
	var crit_lv: int = gm.get_weapon_upgrade_level(selected_weapon, "crit_autoaim")
	
	stat_damage_bar.value = dmg_lv * 10
	stat_rate_bar.value = rate_lv * 10
	stat_pen_bar.value = pen_lv * 10
	stat_crit_bar.value = crit_lv * 10
	
	_setup_upgrade_button(upgrade_damage_btn, dmg_lv, "OVERPRESSURE ROUNDS", gm.survival_coins)
	_setup_upgrade_button(upgrade_rate_btn, rate_lv, "EXTENDED DRUM", gm.survival_coins)
	_setup_upgrade_button(upgrade_pen_btn, pen_lv, "PIERCING CORE", gm.survival_coins)
	_setup_upgrade_button(upgrade_crit_btn, crit_lv, "LASER TARGETER", gm.survival_coins)


func _setup_upgrade_button(btn: Button, level: int, title: String, user_sc: int) -> void:
	if not btn: return
	if level >= 10:
		btn.text = "%s [MAX TIER]" % title
		btn.disabled = true
	else:
		var cost: int = (level + 1) * 150
		btn.text = "%s [LV.%d] — %d SC" % [title, level + 1, cost]
		btn.disabled = (user_sc < cost)


func _on_upgrade_stat(track: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm: return
	var current_lv: int = gm.get_weapon_upgrade_level(selected_weapon, track)
	var cost: int = (current_lv + 1) * 150
	if gm.upgrade_weapon(selected_weapon, track, cost):
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("ui_confirm")
		_refresh_armory_buttons()


func _on_weapon_upgraded(_w: String, _t: String, _l: int) -> void:
	_refresh_armory_buttons()


# ─── Operative Skills Matrix ──────────────────────────────────────────────────
func _build_skill_matrix_ui() -> void:
	# Clear placeholder children
	for child in skill_matrix_container.get_children():
		child.queue_free()
	
	for skill_id in skills_data:
		if not (skill_id in GameManager.IMPLEMENTED_SKILLS):
			continue
		var data: Dictionary = skills_data[skill_id]
		
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(280, 110)
		
		var vbox := VBoxContainer.new()
		vbox.set("theme_override_constants/separation", 6)
		
		var header := Label.new()
		header.text = data["name"]
		header.set("theme_override_colors/font_color", Color(0.95, 0.95, 0.97))
		header.set("theme_override_font_sizes/font_size", 14)
		vbox.add_child(header)
		
		var desc := Label.new()
		desc.text = data["desc"]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.set("theme_override_colors/font_color", Color(0.65, 0.65, 0.68))
		desc.set("theme_override_font_sizes/font_size", 11)
		vbox.add_child(desc)
		
		var action_btn := Button.new()
		action_btn.name = "ActionBtn"
		action_btn.custom_minimum_size = Vector2(0, 32)
		action_btn.pressed.connect(_on_skill_action_pressed.bind(skill_id))
		vbox.add_child(action_btn)
		
		card.add_child(vbox)
		card.set_meta("skill_id", skill_id)
		skill_matrix_container.add_child(card)
	
	_refresh_skills_ui()


func _refresh_skills_ui() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm: return
	
	# Update top 2 equipped slots
	var eq: Array[String] = gm.get_equipped_skills()
	var s0_name: String = skills_data[eq[0]]["name"] if skills_data.has(eq[0]) else (eq[0].to_upper() if eq[0] != "" else "[ EMPTY ]")
	var s1_name: String = skills_data[eq[1]]["name"] if skills_data.has(eq[1]) else (eq[1].to_upper() if eq[1] != "" else "[ EMPTY ]")
	equipped_slot_0_btn.text = "SLOT 1: %s" % s0_name
	equipped_slot_1_btn.text = "SLOT 2: %s" % s1_name
	
	# Detect canonical pair synergies
	var pair_set := {}
	if eq[0] != "": pair_set[eq[0]] = true
	if eq[1] != "": pair_set[eq[1]] = true
	
	if active_synergy_banner:
		if pair_set.has("blood_siphon") and pair_set.has("hemorrhage_rounds"):
			active_synergy_banner.visible = true
			synergy_bonus_label.text = "⚡ CRIMSON BERSERKER ACTIVE: +25% Fire Rate & 2x Blood Pool Radius"
		elif pair_set.has("napalm_gel") and pair_set.has("thermobaric_ignition"):
			active_synergy_banner.visible = true
			synergy_bonus_label.text = "⚡ TACTICAL DEMOLISHER ACTIVE: +50% Burn Time & Concussive Chain Blasts"
		elif pair_set.has("silent_treads") and pair_set.has("strobe_torch"):
			active_synergy_banner.visible = true
			synergy_bonus_label.text = "⚡ GHOST OPERATIVE ACTIVE: Runner Scent Camouflage & Strobe Cone Stun"
		else:
			active_synergy_banner.visible = false
	
	# Update all skill cards
	for card in skill_matrix_container.get_children():
		var skill_id: String = card.get_meta("skill_id")
		var data: Dictionary = skills_data[skill_id]
		var btn: Button = card.find_child("ActionBtn")
		if not btn: continue
		
		var is_unlocked: bool = gm.is_skill_unlocked(skill_id)
		var is_equipped: bool = (eq[0] == skill_id or eq[1] == skill_id)
		
		if is_equipped:
			btn.text = "EQUIPPED [TAP TO UNEQUIP]"
			btn.modulate = Color(1, 0.1, 0.2)
			btn.disabled = false
		elif is_unlocked:
			btn.text = "EQUIP SKILL"
			btn.modulate = Color(0.2, 0.9, 0.3)
			btn.disabled = false
		else:
			# Locked
			if gm.clearance_level < data["level_req"]:
				btn.text = "REQ: CLR-LV.%d" % data["level_req"]
				btn.modulate = Color(0.5, 0.5, 0.5)
				btn.disabled = true
			else:
				btn.text = "UNLOCK [%d RC]" % data["cost_rc"]
				btn.modulate = Color(1, 0.7, 0.1)
				btn.disabled = (gm.research_cores < data["cost_rc"])


func _on_skill_action_pressed(skill_id: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm: return
	
	var eq: Array[String] = gm.get_equipped_skills()
	if eq[0] == skill_id:
		gm.unequip_skill(0)
		_refresh_skills_ui()
		return
	if eq[1] == skill_id:
		gm.unequip_skill(1)
		_refresh_skills_ui()
		return
	
	if gm.is_skill_unlocked(skill_id):
		# Equip in slot 0 or slot 1
		if eq[0] == "":
			gm.equip_skill(0, skill_id)
		else:
			gm.equip_skill(1, skill_id)
	else:
		# Unlock with RC
		var cost: int = skills_data[skill_id]["cost_rc"]
		if gm.spend_research_cores(cost):
			gm.unlock_skill(skill_id)
			if eq[0] == "":
				gm.equip_skill(0, skill_id)
			elif eq[1] == "":
				gm.equip_skill(1, skill_id)
	
	_refresh_skills_ui()


func _on_skill_equipped(_slot: int, _id: String) -> void:
	_refresh_skills_ui()


# ─── Outpost Upgrades ─────────────────────────────────────────────────────────
func _refresh_base_upgrades() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm: return
	
	var comms_lv: int = gm.get_outpost_level("comms_array")
	var medbay_lv: int = gm.get_outpost_level("medbay")
	var helipad_lv: int = gm.get_outpost_level("helipad")
	
	comms_level_label.text = "COMMS ARRAY // TIER %d/5\n+15%% Contract Payouts per tier" % comms_lv
	medbay_level_label.text = "FIELD MEDBAY // TIER %d/5\n+20 Starting Health per tier" % medbay_lv
	helipad_level_label.text = "TACTICAL HELIPAD // TIER %d/5\n-3s Evac Hold per tier (now %ds)" % [helipad_lv, int(gm.get_evac_hold_time())]
	
	_setup_base_upgrade_btn(comms_upgrade_btn, comms_lv, gm.survival_coins, gm.research_cores)
	_setup_base_upgrade_btn(medbay_upgrade_btn, medbay_lv, gm.survival_coins, gm.research_cores)
	_setup_base_upgrade_btn(helipad_upgrade_btn, helipad_lv, gm.survival_coins, gm.research_cores)


func _setup_base_upgrade_btn(btn: Button, level: int, user_sc: int, user_rc: int) -> void:
	if not btn: return
	if level >= 5:
		btn.text = "MAX TIER REACHED"
		btn.disabled = true
	else:
		var cost_sc: int = (level + 1) * 400
		var cost_rc: int = (level + 1) * 2
		btn.text = "UPGRADE [%d SC + %d RC]" % [cost_sc, cost_rc]
		btn.disabled = (user_sc < cost_sc or user_rc < cost_rc)


func _on_upgrade_outpost_facility(facility: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm: return
	var cur_lv: int = gm.get_outpost_level(facility)
	var cost_sc: int = (cur_lv + 1) * 400
	var cost_rc: int = (cur_lv + 1) * 2
	if gm.upgrade_outpost(facility, cost_sc, cost_rc):
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("ui_confirm")
		_refresh_base_upgrades()


func _on_outpost_upgraded(_fac: String, _lv: int) -> void:
	_refresh_base_upgrades()
	select_sector(selected_sector, selected_contract_index)


# ─── Responsive Layout (Portrait vs Landscape) ────────────────────────────────
func _on_orientation_changed(is_portrait: bool) -> void:
	_apply_responsive_layout(is_portrait)


func _apply_responsive_layout(is_portrait: bool) -> void:
	var om = get_node_or_null("/root/OrientationManager")
	var margins: Dictionary = om.get_ui_safe_margins() if om else {"top": 80, "bottom": 40, "left": 24, "right": 24}
	
	# Adjust dock position & orientation: Bottom (horizontal) in Portrait, Left Dock (vertical) in Landscape
	var nav_dock: Control = %NavDock
	if nav_dock:
		if is_portrait:
			nav_dock.anchors_preset = Control.PRESET_BOTTOM_WIDE
			nav_dock.offset_top = -100
			nav_dock.offset_bottom = -margins["bottom"]
			nav_dock.offset_left = margins["left"]
			nav_dock.offset_right = -margins["right"]
			if nav_box:
				nav_box.vertical = false
			if content_area:
				content_area.offset_left = 0
				content_area.offset_bottom = -110
		else:
			nav_dock.anchors_preset = Control.PRESET_LEFT_WIDE
			nav_dock.offset_left = margins["left"]
			nav_dock.offset_right = 260
			nav_dock.offset_top = 100
			nav_dock.offset_bottom = -margins["bottom"]
			if nav_box:
				nav_box.vertical = true
			if content_area:
				content_area.offset_left = 280
				content_area.offset_bottom = -margins["bottom"]


# ─── Signal Connections ────────────────────────────────────────────────────────
func _connect_top_bar_and_dock() -> void:
	if settings_btn:
		settings_btn.pressed.connect(func(): if settings_modal: settings_modal.open())
	
	btn_tab_command.pressed.connect(func(): switch_tab(Tab.COMMAND_BOARD))
	btn_tab_armory.pressed.connect(func(): switch_tab(Tab.ARMORY))
	btn_tab_skills.pressed.connect(func(): switch_tab(Tab.SKILLS))
	btn_tab_upgrades.pressed.connect(func(): switch_tab(Tab.BASE_UPGRADES))
	
	if equipped_slot_0_btn:
		equipped_slot_0_btn.pressed.connect(func(): _on_slot_unequip_pressed(0))
	if equipped_slot_1_btn:
		equipped_slot_1_btn.pressed.connect(func(): _on_slot_unequip_pressed(1))


func _on_slot_unequip_pressed(slot: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.unequip_skill(slot)
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("ui_click")
		_refresh_skills_ui()


func _connect_command_board() -> void:
	sector_1_btn.pressed.connect(func(): select_sector(1))
	sector_2_btn.pressed.connect(func(): select_sector(2))
	sector_3_btn.pressed.connect(func(): select_sector(3))
	sector_4_btn.pressed.connect(func(): select_sector(4))
	deploy_btn.pressed.connect(_on_deploy_pressed)
	
	# Cycle between the sector's contracts (inserted above the Deploy button)
	next_contract_btn = Button.new()
	next_contract_btn.name = "NextContractBtn"
	next_contract_btn.custom_minimum_size = Vector2(0, 40)
	next_contract_btn.add_theme_font_size_override("font_size", 14)
	next_contract_btn.pressed.connect(func(): select_sector(selected_sector, selected_contract_index + 1 if selected_contract_index + 1 < _contract_count() else 0))
	deploy_btn.get_parent().add_child(next_contract_btn)
	deploy_btn.get_parent().move_child(next_contract_btn, deploy_btn.get_index())


func _contract_count() -> int:
	var gm = get_node_or_null("/root/GameManager")
	return gm.get_contracts(selected_sector).size() if gm else 1


func _connect_armory() -> void:
	weapon_carbine_btn.pressed.connect(func(): select_weapon("assault_carbine"))
	weapon_shotgun_btn.pressed.connect(func(): select_weapon("tactical_shotgun"))
	weapon_smg_btn.pressed.connect(func(): select_weapon("high_caliber_smg"))
	
	upgrade_damage_btn.pressed.connect(func(): _on_upgrade_stat("damage_knockback"))
	upgrade_rate_btn.pressed.connect(func(): _on_upgrade_stat("fire_rate_mag"))
	upgrade_pen_btn.pressed.connect(func(): _on_upgrade_stat("penetration"))
	upgrade_crit_btn.pressed.connect(func(): _on_upgrade_stat("crit_autoaim"))
	
	if inspect_viewport_container:
		inspect_viewport_container.gui_input.connect(_on_viewport_gui_input)


func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if weapon_pivot:
			weapon_pivot.rotate_y(event.relative.x * 0.01)
			weapon_pivot.rotate_x(event.relative.y * 0.005)
	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if weapon_pivot:
				weapon_pivot.rotate_y(event.relative.x * 0.01)
				weapon_pivot.rotate_x(event.relative.y * 0.005)


func _connect_base_upgrades() -> void:
	comms_upgrade_btn.pressed.connect(func(): _on_upgrade_outpost_facility("comms_array"))
	medbay_upgrade_btn.pressed.connect(func(): _on_upgrade_outpost_facility("medbay"))
	helipad_upgrade_btn.pressed.connect(func(): _on_upgrade_outpost_facility("helipad"))
