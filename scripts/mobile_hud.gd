extends CanvasLayer
class_name MobileHUD
## MobileHUD.gd
## In-game HUD for PROTOCOL: CRIMSON (portrait-first, built on the UiTheme/UIKit
## design system). Top-left: health and run stats. Top-right: pause. Under them:
## the mission line and Overwatch radio. Bottom: joystick (left), fire button
## (right: tap toggles auto-fire, hold/drag aims) with molotov, blast and the
## context button (climb / shoulder charge / jump) around it. Debug readouts only
## appear in debug builds.

@onready var top_bar: Control = $TopBar
@onready var health_bar: ProgressBar = $TopBar/HealthBar
@onready var zombie_count_label: Label = $TopBar/ZombieCountLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var pause_button: TextureButton = $TopBar/PauseButton
@onready var mission_pill: PanelContainer = $TopBar/MissionPill
@onready var mission_label: Label = $TopBar/MissionPill/MissionLabel
@onready var fps_label: Label = $TopBar/FpsLabel

@onready var powerup_widget: Panel = $TopBar/PowerupWidget
@onready var powerup_title: Label = $TopBar/PowerupWidget/Title
@onready var powerup_bar: ProgressBar = $TopBar/PowerupWidget/CountdownBar

@onready var controls_root: Control = $Controls
@onready var joystick: VirtualJoystick = $Controls/VirtualJoystick
@onready var fire_button: TextureButton = $Controls/FireButton
@onready var auto_fire_btn: Button = $Controls/AutoFireButton
@onready var super_blast_button: TextureButton = $Controls/SuperBlastButton
@onready var super_blast_cooldown_overlay: ColorRect = $Controls/SuperBlastButton/CooldownOverlay
@onready var molotov_button: TextureButton = $Controls/MolotovButton
@onready var molotov_ammo_badge: Label = $Controls/MolotovButton/AmmoBadge
@onready var climb_button: TextureButton = $Controls/ClimbButton

@onready var street_cleared_banner: Panel = $StreetClearedBanner

# Pause and Settings Modals
@onready var pause_modal: Control = $PauseModal
@onready var resume_btn: Button = $PauseModal/Card/VBox/ResumeBtn
@onready var restart_btn: Button = $PauseModal/Card/VBox/RestartBtn
@onready var settings_btn: Button = $PauseModal/Card/VBox/SettingsBtn
@onready var main_menu_btn: Button = $PauseModal/Card/VBox/MainMenuBtn

@onready var settings_modal: Control = $SettingsModal
@onready var shake_toggle_btn: Button = $SettingsModal/Card/VBox/ShakeToggleBtn
@onready var blood_toggle_btn: Button = $SettingsModal/Card/VBox/BloodToggleBtn
@onready var close_settings_btn: Button = $SettingsModal/Card/VBox/CloseSettingsBtn

var player: Player = null
var spawner: ZombieSpawner = null
var screen_shake_enabled: bool = true
var blood_max_enabled: bool = true
var is_fire_dragging: bool = false
var is_molotov_aiming: bool = false
var is_super_blast_aiming: bool = false
var key_molotov_aiming: bool = false
var key_blast_aiming: bool = false
var _fps_timer: float = 0.0

# Release UI (built in _apply_release_ui)
const FIRE_TAP_MS := 220
var _stats_label: Label = null
var _pause_btn: Button = null
var _fire_skin: RoundButtonSkin = null
var _molotov_skin: RoundButtonSkin = null
var _blast_skin: RoundButtonSkin = null
var _climb_skin: RoundButtonSkin = null
var _fire_down_ms: int = 0
var _fire_dragged: bool = false
var _hp: float = 100.0
var _kills: int = 0
var _run_sc: int = 0
var _pause_layer: Control = null
var _abandon_armed: bool = false
var _abandon_btn: Button = null

func _process(delta: float) -> void:
	# Continuous mouse raycast targeting while special aiming on PC
	if (key_molotov_aiming or key_blast_aiming or (is_molotov_aiming and not DisplayServer.is_touchscreen_available()) or (is_super_blast_aiming and not DisplayServer.is_touchscreen_available())) and player:
		_update_mouse_aim()
		
	_fps_timer += delta
	if _fps_timer >= 0.22 and is_instance_valid(fps_label) and fps_label.visible:
		_fps_timer = 0.0
		var fps := Engine.get_frames_per_second()
		var ms := 1000.0 / maxf(1.0, float(fps))
		fps_label.text = "%d FPS  (%.1f ms)" % [fps, ms]
		if fps_label.label_settings:
			if fps >= 55:
				fps_label.label_settings.font_color = Color(0.35, 1.0, 0.65, 0.95)
			elif fps >= 30:
				fps_label.label_settings.font_color = Color(1.0, 0.82, 0.25, 0.95)
			else:
				fps_label.label_settings.font_color = Color(1.0, 0.28, 0.28, 0.95)

func _ready() -> void:
	fire_button.button_down.connect(_on_fire_down)
	fire_button.button_up.connect(_on_fire_up)
	fire_button.gui_input.connect(_on_fire_gui_input)
	
	if auto_fire_btn:
		auto_fire_btn.pressed.connect(_on_auto_fire_pressed)
	
	super_blast_button.button_down.connect(_on_super_blast_down)
	super_blast_button.button_up.connect(_on_super_blast_up)
	super_blast_button.gui_input.connect(_on_super_blast_gui_input)
	
	molotov_button.button_down.connect(_on_molotov_down)
	molotov_button.button_up.connect(_on_molotov_up)
	molotov_button.gui_input.connect(_on_molotov_gui_input)
	
	climb_button.pressed.connect(_on_climb_pressed)
	joystick.joystick_vector.connect(_on_joystick_vector)
	
	# Pause & Modals
	pause_button.pressed.connect(toggle_pause)
	resume_btn.pressed.connect(resume_game)
	restart_btn.pressed.connect(restart_game)
	settings_btn.pressed.connect(open_settings)
	main_menu_btn.pressed.connect(goto_main_menu)
	
	# Settings
	shake_toggle_btn.pressed.connect(_on_shake_toggled)
	blood_toggle_btn.pressed.connect(_on_blood_toggled)
	close_settings_btn.pressed.connect(close_settings)
	
	_apply_portrait_layout()
	_apply_release_ui()

## The game is portrait only (1080 x 1920 canvas).
func _apply_portrait_layout() -> void:
	# Joystick: 330 px, bottom-left
	joystick.offset_left = 70.0
	joystick.offset_top = -470.0
	joystick.offset_right = 400.0
	joystick.offset_bottom = -140.0
	
	# Fire: 280 px round, bottom-right (tap = auto-fire on/off, hold/drag = aim)
	fire_button.offset_left = -350.0
	fire_button.offset_top = -420.0
	fire_button.offset_right = -70.0
	fire_button.offset_bottom = -140.0
	
	# Abilities in an arc around the fire button
	molotov_button.offset_left = -560.0
	molotov_button.offset_top = -330.0
	molotov_button.offset_right = -380.0
	molotov_button.offset_bottom = -150.0
	
	super_blast_button.offset_left = -270.0
	super_blast_button.offset_top = -630.0
	super_blast_button.offset_right = -90.0
	super_blast_button.offset_bottom = -450.0
	
	climb_button.offset_left = -480.0
	climb_button.offset_top = -540.0
	climb_button.offset_right = -330.0
	climb_button.offset_bottom = -390.0
	
	if mission_pill:
		mission_pill.set_anchors_preset(Control.PRESET_TOP_WIDE)
		mission_pill.offset_left = UIKit.MARGIN
		mission_pill.offset_right = -UIKit.MARGIN
		mission_pill.offset_top = 260.0
		mission_pill.offset_bottom = 340.0

func _on_auto_fire_pressed() -> void:
	if player:
		var state := player.toggle_auto_fire()
		_update_auto_fire_ui(state)

func _update_auto_fire_ui(enabled: bool) -> void:
	if _fire_skin:
		_fire_skin.text = "AUTO" if enabled else "FIRE"
		_fire_skin.fill = UIKit.CRIMSON if enabled else Color(UIKit.CRIMSON_DARK, 0.92)
	if auto_fire_btn:
		if enabled:
			auto_fire_btn.text = "AUTO: ON"
			auto_fire_btn.modulate = Color(1.0, 0.15, 0.25, 1.0)
		else:
			auto_fire_btn.text = "AUTO: OFF"
			auto_fire_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_fire_gui_input(event: InputEvent) -> void:
	# Twin-Stick Manual Drag-Aim sweep on Fire Button (Design Doc 6.3)
	if event is InputEventScreenDrag:
		_fire_dragged = true
		var center: Vector2 = fire_button.size * 0.5
		var drag_offset: Vector2 = (event.position - center) / (fire_button.size.x * 0.5)
		if player:
			player.mobile_aim_input = drag_offset.limit_length(1.0)
	elif event is InputEventMouseMotion and is_fire_dragging:
		if (event as InputEventMouseMotion).relative.length() > 4.0:
			_fire_dragged = true
		var center: Vector2 = fire_button.size * 0.5
		var drag_offset: Vector2 = (event.position - center) / (fire_button.size.x * 0.5)
		if player:
			player.mobile_aim_input = drag_offset.limit_length(1.0)

func _on_climb_pressed() -> void:
	if player:
		# Contextual: vault a ledge > shoulder-charge a nearby horde > jump
		if player.can_vault:
			player.trigger_vault()
		elif player.has_zombie_within(Player.SHOULDER_CHARGE_RADIUS):
			if not player.trigger_shoulder_charge():
				player.jump()
		else:
			player.jump()
		var tween := create_tween()
		tween.tween_property(climb_button, "scale", Vector2(0.88, 0.88), 0.06)
		tween.tween_property(climb_button, "scale", Vector2(1.0, 1.0), 0.1)

func _update_mouse_aim() -> void:
	if not player:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var cam := get_viewport().get_camera_3d()
	if cam:
		var ray_origin := cam.project_ray_origin(mouse_pos)
		var ray_dir := cam.project_ray_normal(mouse_pos)
		var space_state := player.get_world_3d().direct_space_state
		var ray_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 150.0, 1)
		ray_query.exclude = [player.get_rid()]
		var hit := space_state.intersect_ray(ray_query)
		var target_world: Vector3
		if not hit.is_empty():
			target_world = hit["position"]
		else:
			var plane := Plane(Vector3.UP, player.global_position.y)
			var hit_plane = plane.intersects_ray(ray_origin, ray_dir)
			target_world = hit_plane if hit_plane else (player.global_position + (-player.transform.basis.z * 10.0))
		player.update_aim_special_world(target_world)

func _on_molotov_down() -> void:
	if player and player.molotov_ammo > 0:
		is_molotov_aiming = true
		player.start_aiming_special("molotov")
		if not DisplayServer.is_touchscreen_available():
			_update_mouse_aim()
		var tween := create_tween()
		tween.tween_property(molotov_button, "scale", Vector2(1.15, 1.15), 0.08)

func _on_molotov_gui_input(event: InputEvent) -> void:
	if not is_molotov_aiming or not player:
		return
	if event is InputEventScreenDrag:
		var center: Vector2 = molotov_button.size * 0.5
		var drag_offset: Vector2 = (event.position - center) / (molotov_button.size.x * 0.5)
		if drag_offset.length() > 0.15:
			player.update_aim_special_vec(drag_offset)
	elif event is InputEventMouseMotion:
		_update_mouse_aim()

func _on_molotov_up() -> void:
	var tween := create_tween()
	tween.tween_property(molotov_button, "scale", Vector2(1.0, 1.0), 0.1)
	if is_molotov_aiming:
		is_molotov_aiming = false
		if player:
			player.release_aim_special()

func _on_molotov_pressed() -> void:
	if player:
		var ok := player.throw_molotov()
		if ok:
			var tween := create_tween()
			tween.tween_property(molotov_button, "scale", Vector2(1.15, 1.15), 0.06)
			tween.tween_property(molotov_button, "scale", Vector2(1.0, 1.0), 0.12)

func setup(p_player: Player, p_spawner: ZombieSpawner) -> void:
	player = p_player
	spawner = p_spawner
	
	if player:
		player.health_changed.connect(_on_health_changed)
		player.super_blast_cooldown.connect(_on_super_blast_cooldown)
		player.powerup_timer_changed.connect(_on_powerup_timer_changed)
		if player.has_signal("powerup_activated"):
			player.powerup_activated.connect(_on_powerup_activated)
		if player.has_signal("rocket_ammo_changed"):
			player.rocket_ammo_changed.connect(_on_rocket_ammo_changed)
		player.molotov_ammo_changed.connect(_on_molotov_ammo_changed)
		player.vault_state_changed.connect(_on_vault_state_changed)
		player.auto_fire_toggled.connect(_update_auto_fire_ui)
		_on_health_changed(player.current_health, player.max_health)
		_on_molotov_ammo_changed(player.molotov_ammo, player.max_molotov_ammo)
		_on_vault_state_changed(player.can_vault)
		_update_auto_fire_ui(player.auto_fire_enabled)
	
	if spawner:
		spawner.zombie_count_changed.connect(_on_zombie_count_changed)
		spawner.wave_started.connect(_on_wave_started)
		_on_wave_started(spawner.current_wave)
		_on_zombie_count_changed(spawner.alive_zombies, spawner.total_kills)
	
	# Check GameManager for current contract info
	var gm = get_node_or_null("/root/GameManager")
	if gm and not gm.current_contract.is_empty():
		set_mission_info(gm.current_contract.get("title", "EXTRACTION CONTRACT"), gm.current_contract)

var current_powerup_title: String = "ACTIVE OVERDRIVE"

func show_powerup_banner(title: String) -> void:
	current_powerup_title = title
	if powerup_widget:
		powerup_widget.visible = true
		powerup_title.text = title
		var tween := create_tween()
		tween.tween_property(powerup_widget, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(powerup_widget, "scale", Vector2(1.0, 1.0), 0.1)

func _on_powerup_activated(p_name: String, _duration_or_ammo: float) -> void:
	show_powerup_banner(p_name)

func _on_rocket_ammo_changed(current: int, _max_val: int) -> void:
	if current > 0:
		show_powerup_banner("HEAVY ROCKETS: %d RDS" % current)
	else:
		if powerup_title and powerup_title.text.begins_with("HEAVY ROCKETS"):
			powerup_widget.visible = false

func set_mission_status(status_text: String, col: Color = Color.WHITE) -> void:
	if mission_label:
		mission_label.text = status_text
		mission_label.modulate = col

func set_mission_info(title: String, _contract_data: Dictionary = {}) -> void:
	if mission_label:
		mission_label.text = "[ 1/3 ] %s — 120m" % title

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
				toggle_pause()
			elif event.keycode == KEY_E or event.keycode == KEY_Q or event.keycode == KEY_B:
				key_blast_aiming = true
				if player:
					player.start_aiming_special("super_blast")
			elif event.keycode == KEY_G or event.keycode == KEY_F:
				key_molotov_aiming = true
				if player:
					player.start_aiming_special("molotov")
			elif event.keycode == KEY_SPACE:
				_on_climb_pressed()
			elif event.keycode == KEY_T:
				_on_auto_fire_pressed()
		elif not event.pressed:
			if event.keycode == KEY_E or event.keycode == KEY_Q or event.keycode == KEY_B:
				if key_blast_aiming:
					key_blast_aiming = false
					if player:
						player.release_aim_special()
			elif event.keycode == KEY_G or event.keycode == KEY_F:
				if key_molotov_aiming:
					key_molotov_aiming = false
					if player:
						player.release_aim_special()
	elif event is InputEventMouseMotion:
		if (key_molotov_aiming or key_blast_aiming) and player:
			var cam := get_viewport().get_camera_3d()
			if cam:
				var ray_origin := cam.project_ray_origin(event.position)
				var ray_dir := cam.project_ray_normal(event.position)
				var plane := Plane(Vector3.UP, player.global_position.y)
				var hit = plane.intersects_ray(ray_origin, ray_dir)
				if hit:
					player.update_aim_special_world(hit)

func _on_molotov_ammo_changed(current: int, max_val: int) -> void:
	if molotov_ammo_badge:
		molotov_ammo_badge.text = "%d/%d" % [current, max_val]
	if molotov_button:
		molotov_button.disabled = (current <= 0)
	if _molotov_skin:
		_molotov_skin.text = "%d/%d" % [current, max_val]
		_molotov_skin.icon_color = UIKit.AMBER if current > 0 else UIKit.MUTED
		_molotov_skin.text_color = UIKit.AMBER if current > 0 else UIKit.MUTED

func _on_vault_state_changed(can_vault: bool) -> void:
	if _climb_skin:
		_climb_skin.text = "CLIMB" if can_vault else "CHARGE"
		_climb_skin.ring = UIKit.CYAN if can_vault else Color(0, 0, 0, 0)
		_climb_skin.ring_width = 6.0 if can_vault else 0.0
	if climb_button and can_vault:
		var tween := create_tween()
		tween.tween_property(climb_button, "scale", Vector2(1.1, 1.1), 0.12)
		tween.tween_property(climb_button, "scale", Vector2(1.0, 1.0), 0.12)

var evac_bar: ProgressBar = null

# ─── Radio panel: queued lines from Overwatch (and intel reads) ───
const RADIO_LINE_TIME := 4.5
var _radio_panel: PanelContainer = null
var _radio_speaker: Label = null
var _radio_text: Label = null
var _radio_queue: Array = []
var _radio_busy: bool = false

func show_radio(speaker: String, text: String) -> void:
	if text.strip_edges() == "":
		return
	_radio_queue.append([speaker, text])
	if not _radio_busy:
		_next_radio_line()

func _next_radio_line() -> void:
	if _radio_queue.is_empty():
		_radio_busy = false
		if _radio_panel:
			var t := create_tween()
			t.tween_property(_radio_panel, "modulate:a", 0.0, 0.3)
			t.tween_callback(_hide_radio_if_idle)
		return
	_radio_busy = true
	_ensure_radio_panel()
	var line: Array = _radio_queue.pop_front()
	_radio_speaker.text = String(line[0])
	_radio_text.text = String(line[1])
	_radio_panel.visible = true
	_radio_panel.modulate.a = 1.0
	get_tree().create_timer(RADIO_LINE_TIME, true).timeout.connect(_next_radio_line)

func _hide_radio_if_idle() -> void:
	if _radio_queue.is_empty() and _radio_panel:
		_radio_panel.visible = false

func _ensure_radio_panel() -> void:
	if _radio_panel:
		return
	_radio_panel = UIKit.card("AccentCard")
	_radio_panel.name = "RadioPanel"
	_radio_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radio_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_radio_panel.offset_left = UIKit.MARGIN
	_radio_panel.offset_right = -UIKit.MARGIN
	_radio_panel.offset_top = 360.0
	var row := UIKit.hbox(18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UIKit.icon("radio", 52, UIKit.AMBER))
	var col := UIKit.vbox(4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_radio_speaker = UIKit.label("", "CaptionLabel", UIKit.AMBER)
	col.add_child(_radio_speaker)
	_radio_text = UIKit.paragraph("", UIKit.TEXT, 34)
	col.add_child(_radio_text)
	row.add_child(col)
	_radio_panel.add_child(row)
	add_child(_radio_panel)
	move_child(_radio_panel, 0)

var objective_pointer: ObjectivePointer = null

## Points at the current goal (objective, then LZ). Pass null to hide.
func update_objective_pointer(target: Variant, from: Vector3, color: Color) -> void:
	if not objective_pointer:
		objective_pointer = ObjectivePointer.new()
		objective_pointer.name = "ObjectivePointer"
		add_child(objective_pointer)
		move_child(objective_pointer, 0)  # under modals and the debrief
	if target == null:
		objective_pointer.clear()
	else:
		objective_pointer.point_at(target, from, color)
var _evac_fill_holding: StyleBoxFlat = null
var _evac_fill_paused: StyleBoxFlat = null

## Evac countdown bar under the mission pill. Red while paused (player outside the LZ).
func show_evac_progress(fraction: float, holding: bool) -> void:
	if not evac_bar:
		evac_bar = ProgressBar.new()
		evac_bar.name = "EvacBar"
		evac_bar.show_percentage = false
		evac_bar.max_value = 1.0
		evac_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		evac_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
		evac_bar.offset_left = -260.0
		evac_bar.offset_right = 260.0
		evac_bar.offset_top = 190.0
		evac_bar.offset_bottom = 214.0
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.07, 0.07, 0.08, 0.85)
		evac_bar.add_theme_stylebox_override("background", bg)
		add_child(evac_bar)
		_evac_fill_holding = StyleBoxFlat.new()
		_evac_fill_holding.bg_color = Color(1.0, 0.72, 0.0)
		_evac_fill_paused = StyleBoxFlat.new()
		_evac_fill_paused.bg_color = Color(1.0, 0.2, 0.25)
	evac_bar.add_theme_stylebox_override("fill", _evac_fill_holding if holding else _evac_fill_paused)
	evac_bar.value = clampf(fraction, 0.0, 1.0)
	evac_bar.visible = true

func hide_evac_progress() -> void:
	if evac_bar:
		evac_bar.visible = false

func show_banner(title: String, sub: String = "") -> void:
	if not street_cleared_banner:
		return
	var title_label := street_cleared_banner.get_node_or_null("Title") as Label
	var sub_label := street_cleared_banner.get_node_or_null("Sub") as Label
	if title_label:
		title_label.text = title
	if sub_label:
		sub_label.text = sub
	show_street_cleared_banner()

## End-of-run debrief (extraction or KIA). Pauses the game; HUD runs with process_mode ALWAYS.
## Rewards first, then XP and level-up, then the next goal, then the actions.
func show_mission_result(summary: Dictionary) -> void:
	get_tree().paused = true
	controls_root.visible = false
	if _pause_btn:
		_pause_btn.visible = false
	if objective_pointer:
		objective_pointer.clear()
	if _radio_panel:
		_radio_panel.visible = false
	hide_evac_progress()
	var gm = get_node_or_null("/root/GameManager")
	var success: bool = summary.get("success", false)
	
	var layer := Control.new()
	layer.name = "MissionResult"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_theme(layer)
	add_child(layer)
	layer.add_child(UIKit.overlay(0.97))
	var col := UIKit.vbox(26)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = UIKit.MARGIN
	col.offset_right = -UIKit.MARGIN
	col.offset_top = UIKit.TOP_SAFE + 70
	col.offset_bottom = -130
	layer.add_child(col)
	
	var status := UIKit.hbox(12)
	status.add_child(UIKit.icon("check" if success else "skull", 44, UIKit.GREEN if success else UIKit.CRIMSON))
	status.add_child(UIKit.label("EXTRACTED" if success else "OPERATIVE DOWN", "CaptionLabel", UIKit.GREEN if success else UIKit.CRIMSON, 36))
	col.add_child(status)
	var title_text := String(summary.get("title", "MISSION"))
	var parts := title_text.split(": ", false, 1)
	var title := UIKit.label(parts[parts.size() - 1], "DisplayLabel")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	
	if summary.is_empty():
		col.add_child(UIKit.paragraph("No contract data."))
	else:
		var rewards := UIKit.card()
		var rv := UIKit.vbox(18)
		var kills: Dictionary = summary.get("kills", {})
		if success:
			var contract_text := "+%s" % UIKit.fmt_int(int(summary.get("contract_sc", 0)))
			if summary.get("first_clear", false):
				contract_text += "  (FIRST CLEAR ×2)"
			rv.add_child(_result_row("Contract", contract_text, UIKit.TEXT))
			rv.add_child(_result_row("Kills (%d)" % int(summary.get("kill_count", 0)), "+%s" % UIKit.fmt_int(int(summary.get("kill_sc", 0))), UIKit.TEXT))
		else:
			rv.add_child(_result_row("Kills", str(int(summary.get("kill_count", 0))), UIKit.TEXT))
			if int(summary.get("lost_sc", 0)) > 0:
				rv.add_child(_result_row("Coins lost", "-%s" % UIKit.fmt_int(int(summary.get("lost_sc", 0))), UIKit.CRIMSON))
		var intel: Vector2i = summary.get("intel", Vector2i.ZERO)
		if intel.y > 0:
			rv.add_child(_result_row("Intel found", "%d / %d" % [intel.x, intel.y], UIKit.TEXT))
		var line := ColorRect.new()
		line.color = UIKit.LINE
		line.custom_minimum_size = Vector2(0, 2)
		rv.add_child(line)
		var totals := UIKit.hbox(16)
		totals.add_child(UIKit.currency("coin", int(summary.get("total_sc", 0)), UIKit.AMBER, 56, "+"))
		totals.add_child(UIKit.expander())
		totals.add_child(UIKit.currency("core", int(summary.get("total_rc", 0)), UIKit.CRIMSON, 56, "+"))
		rv.add_child(totals)
		if not success:
			rv.add_child(UIKit.label("You keep 30% of the coins you picked up and half your XP.", "CaptionLabel"))
		rewards.add_child(rv)
		col.add_child(rewards)
		
		var xp_card := UIKit.card()
		var xv := UIKit.vbox(14)
		var xr := UIKit.hbox(12)
		xr.add_child(UIKit.label("LEVEL %d" % int(summary.get("level_after", 1)), "SubheadLabel"))
		if int(summary.get("level_after", 1)) > int(summary.get("level_before", 1)):
			xr.add_child(UIKit.label("LEVEL UP", "SubheadLabel", UIKit.AMBER))
		xr.add_child(UIKit.expander())
		xr.add_child(UIKit.label("+%d XP" % int(summary.get("total_xp", 0)), "SubheadLabel", UIKit.DIM, 40))
		xv.add_child(xr)
		var need := int(summary.get("xp_needed", 0))
		xv.add_child(UIKit.bar(float(summary.get("xp_now", 0)) / float(maxi(need, 1)) if need > 0 else 1.0))
		xp_card.add_child(xv)
		col.add_child(xp_card)
		
		if int(summary.get("sector_unlocked", 0)) > 0:
			var unlock := UIKit.card("SuccessCard")
			unlock.add_child(UIKit.label("SECTOR %d UNLOCKED" % int(summary["sector_unlocked"]), "SubheadLabel", UIKit.GREEN))
			col.add_child(unlock)
	
	var goal: Dictionary = gm.get_next_armory_goal() if gm else {}
	var upgrade_ready := false
	if not goal.is_empty():
		var cost := int(goal["cost"])
		upgrade_ready = gm.survival_coins >= cost
		var goal_card := UIKit.card("SuccessCard" if upgrade_ready else "")
		var text: String
		if upgrade_ready:
			text = "Upgrade ready: %s level %d for %s coins" % [goal["name"], int(goal["level"]), UIKit.fmt_int(cost)]
		else:
			text = "Next upgrade: %s level %d, %s more coins" % [goal["name"], int(goal["level"]), UIKit.fmt_int(cost - int(gm.survival_coins))]
		goal_card.add_child(UIKit.paragraph(text, UIKit.GREEN if upgrade_ready else UIKit.TEXT_SOFT, 34))
		col.add_child(goal_card)
	
	col.add_child(UIKit.expander())
	if upgrade_ready:
		var up := UIKit.button("Upgrade now", "AmberButton")
		up.pressed.connect(_goto_hub_tab.bind("armory"))
		col.add_child(up)
	var row := UIKit.hbox(20)
	var hub_btn := UIKit.button("Outpost", "GhostButton")
	hub_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub_btn.pressed.connect(goto_main_menu)
	row.add_child(hub_btn)
	var again := UIKit.button("Redeploy" if success else "Retry")
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(restart_game)
	row.add_child(again)
	col.add_child(row)


func _result_row(left: String, right: String, right_color: Color) -> HBoxContainer:
	var r := UIKit.hbox(16)
	r.add_child(UIKit.label(left, "", UIKit.DIM))
	r.add_child(UIKit.expander())
	if right != "":
		r.add_child(UIKit.label(right, "", right_color))
	return r


func _goto_hub_tab(tab: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.pending_hub_tab = tab
	goto_main_menu()


func show_street_cleared_banner() -> void:
	if not street_cleared_banner:
		return
	street_cleared_banner.visible = true
	street_cleared_banner.position.y = 500.0
	street_cleared_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(street_cleared_banner, "position:y", 520.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(street_cleared_banner, "modulate:a", 1.0, 0.25)
	tween.tween_interval(3.5)
	tween.tween_property(street_cleared_banner, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_hide_street_banner)

func _hide_street_banner() -> void:
	street_cleared_banner.visible = false

func toggle_pause() -> void:
	if _pause_layer:
		resume_game()
	elif not get_tree().paused:
		get_tree().paused = true
		_show_pause_menu()

func _show_pause_menu() -> void:
	_abandon_armed = false
	_pause_layer = Control.new()
	_pause_layer.name = "PauseMenu"
	_pause_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_theme(_pause_layer)
	add_child(_pause_layer)
	_pause_layer.add_child(UIKit.overlay(0.86))
	var col := UIKit.vbox(24)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = UIKit.MARGIN * 2
	col.offset_right = -UIKit.MARGIN * 2
	col.offset_top = 640
	col.offset_bottom = -400
	_pause_layer.add_child(col)
	var title := UIKit.label("PAUSED", "DisplayLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	col.add_child(UIKit.spacer(20))
	var resume := UIKit.button("Resume")
	resume.pressed.connect(resume_game)
	col.add_child(resume)
	var settings := UIKit.button("Settings", "GhostButton")
	settings.pressed.connect(open_settings)
	col.add_child(settings)
	_abandon_btn = UIKit.button("Abandon mission", "GhostButton")
	_abandon_btn.add_theme_color_override("font_color", Color(1.0, 0.42, 0.45))
	_abandon_btn.pressed.connect(_on_abandon_pressed)
	col.add_child(_abandon_btn)

func _on_abandon_pressed() -> void:
	if not _abandon_armed:
		_abandon_armed = true
		_abandon_btn.text = "TAP AGAIN: RUN LOOT IS LOST"
		return
	goto_main_menu()

func resume_game() -> void:
	get_tree().paused = false
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
	pause_modal.visible = false
	settings_modal.visible = false

func restart_game() -> void:
	_abandon_active_run()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _abandon_active_run() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.run_active:
		gm.abandon_mission()

func open_settings() -> void:
	SettingsScreen.open(self)

func close_settings() -> void:
	settings_modal.visible = false

func goto_main_menu() -> void:
	_abandon_active_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/hub_screen.tscn")

func _on_shake_toggled() -> void:
	screen_shake_enabled = not screen_shake_enabled
	shake_toggle_btn.text = "SCREEN SHAKE: " + ("ON" if screen_shake_enabled else "OFF")

func _on_blood_toggled() -> void:
	blood_max_enabled = not blood_max_enabled
	blood_toggle_btn.text = "BLOOD PARTICLES: " + ("MAX" if blood_max_enabled else "LOW")
	if BloodManager.instance:
		BloodManager.instance.max_decals = (300 if blood_max_enabled else 80)

func _on_powerup_timer_changed(time_left: float, max_time: float) -> void:
	if time_left > 0.05:
		powerup_widget.visible = true
		powerup_bar.value = (time_left / max_time) * 100.0
		powerup_title.text = "%s - %.1fs" % [current_powerup_title, time_left]
	else:
		powerup_widget.visible = false

func _on_joystick_vector(vec: Vector2) -> void:
	if player:
		player.mobile_move_input = vec

func _on_fire_down() -> void:
	is_fire_dragging = true
	_fire_down_ms = Time.get_ticks_msec()
	_fire_dragged = false
	if player:
		player.mobile_fire_pressed = true

func _on_fire_up() -> void:
	is_fire_dragging = false
	if player:
		player.mobile_fire_pressed = false
		player.mobile_aim_input = Vector2.ZERO
	# A quick tap (no drag) toggles auto-fire; holding or dragging is manual aim
	if not _fire_dragged and Time.get_ticks_msec() - _fire_down_ms < FIRE_TAP_MS:
		_on_auto_fire_pressed()

func _on_super_blast_down() -> void:
	if player and player.super_blast_timer <= 0.0:
		is_super_blast_aiming = true
		player.start_aiming_special("super_blast")
		if not DisplayServer.is_touchscreen_available():
			_update_mouse_aim()
		var tween := create_tween()
		tween.tween_property(super_blast_button, "scale", Vector2(1.2, 1.2), 0.08)

func _on_super_blast_gui_input(event: InputEvent) -> void:
	if not is_super_blast_aiming or not player:
		return
	if event is InputEventScreenDrag:
		var center: Vector2 = super_blast_button.size * 0.5
		var drag_offset: Vector2 = (event.position - center) / (super_blast_button.size.x * 0.5)
		if drag_offset.length() > 0.15:
			player.update_aim_special_vec(drag_offset)
	elif event is InputEventMouseMotion:
		_update_mouse_aim()

func _on_super_blast_up() -> void:
	var tween := create_tween()
	tween.tween_property(super_blast_button, "scale", Vector2(1.0, 1.0), 0.1)
	if is_super_blast_aiming:
		is_super_blast_aiming = false
		if player:
			player.release_aim_special()

func _on_super_blast_pressed() -> void:
	if player:
		var success := player.trigger_super_blast()
		if success:
			var tween := create_tween()
			tween.tween_property(super_blast_button, "scale", Vector2(1.2, 1.2), 0.08)
			tween.tween_property(super_blast_button, "scale", Vector2(1.0, 1.0), 0.12)

func _on_health_changed(current: float, max_val: float) -> void:
	health_bar.max_value = max_val
	health_bar.value = current
	_hp = current
	_update_stats()

func _on_super_blast_cooldown(ratio: float) -> void:
	super_blast_button.disabled = (ratio > 0.01)
	if _blast_skin:
		_blast_skin.cooldown = ratio

func _on_zombie_count_changed(alive_count: int, total_kills: int) -> void:
	zombie_count_label.text = "%02d  |  KILLS: %d" % [alive_count, total_kills]
	_kills = total_kills
	_update_stats()

func _on_run_loot_changed(current_sc: int, _current_rc: int) -> void:
	_run_sc = current_sc
	_update_stats()

func _update_stats() -> void:
	if _stats_label:
		_stats_label.text = "%d HP   ·   %d KILLS   ·   +%s COINS" % [int(ceil(_hp)), _kills, UIKit.fmt_int(_run_sc)]


## Builds the release HUD on top of the existing nodes (their signals and gameplay
## wiring are untouched): re-skins the round buttons, adds the stats card and the
## pause button, restyles the mission line and banner, hides debug readouts.
func _apply_release_ui() -> void:
	# The HUD is a CanvasLayer, which blocks theme inheritance: theme its roots.
	for child in get_children():
		if child is Control:
			_theme(child)
	fps_label.visible = OS.is_debug_build()
	if fps_label.visible:
		fps_label.label_settings = null
		fps_label.add_theme_font_size_override("font_size", UIKit.SIZE_CAPTION)
		fps_label.add_theme_color_override("font_color", UIKit.GREEN)
	zombie_count_label.visible = false
	wave_label.visible = false
	pause_button.visible = false
	if auto_fire_btn:
		auto_fire_btn.visible = false
	
	# Health + run stats card, top-left
	var stats_card := UIKit.card()
	stats_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stats_card.offset_left = UIKit.MARGIN
	stats_card.offset_top = UIKit.TOP_SAFE
	stats_card.offset_right = UIKit.MARGIN + 560
	var stats_col := UIKit.vbox(10)
	stats_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_card.add_child(stats_col)
	health_bar.reparent(stats_col, false)
	health_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	health_bar.custom_minimum_size = Vector2(480, 28)
	health_bar.show_percentage = false
	var hb_bg := StyleBoxFlat.new()
	hb_bg.bg_color = UIKit.BAR_BG
	var hb_fill := StyleBoxFlat.new()
	hb_fill.bg_color = UIKit.CRIMSON
	health_bar.add_theme_stylebox_override("background", hb_bg)
	health_bar.add_theme_stylebox_override("fill", hb_fill)
	_stats_label = UIKit.label("", "SubheadLabel", UIKit.TEXT, 34)
	stats_col.add_child(_stats_label)
	top_bar.add_child(stats_card)
	
	# Pause, top-right
	_pause_btn = Button.new()
	_pause_btn.theme_type_variation = "GhostButton"
	_pause_btn.icon = UIKit.icon_texture("pause")
	_pause_btn.expand_icon = true
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_btn.offset_left = -UIKit.MARGIN - UIKit.MIN_TOUCH
	_pause_btn.offset_right = -UIKit.MARGIN
	_pause_btn.offset_top = UIKit.TOP_SAFE
	_pause_btn.offset_bottom = UIKit.TOP_SAFE + UIKit.MIN_TOUCH
	_pause_btn.pressed.connect(toggle_pause)
	top_bar.add_child(_pause_btn)
	
	# Mission line
	mission_pill.theme_type_variation = ""
	mission_pill.remove_theme_stylebox_override("panel")
	mission_label.label_settings = null
	mission_label.theme_type_variation = "SubheadLabel"
	mission_label.add_theme_font_size_override("font_size", 40)
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Banner (objective complete, evac inbound, ...)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(UIKit.PANEL, 0.94)
	banner_style.border_color = UIKit.AMBER
	banner_style.border_width_left = 10
	street_cleared_banner.add_theme_stylebox_override("panel", banner_style)
	street_cleared_banner.offset_left = -440.0
	street_cleared_banner.offset_right = 440.0
	for child_name in ["Title", "Sub"]:
		var bl := street_cleared_banner.get_node_or_null(child_name) as Label
		if bl:
			bl.label_settings = null
			bl.offset_left = -420.0
			bl.offset_right = 420.0
			bl.theme_type_variation = "SubheadLabel" if child_name == "Title" else "CaptionLabel"
			bl.add_theme_color_override("font_color", UIKit.AMBER if child_name == "Title" else UIKit.TEXT_SOFT)
	
	# Power-up widget text
	if powerup_title:
		powerup_title.label_settings = null
		powerup_title.theme_type_variation = "CaptionLabel"
		powerup_title.add_theme_color_override("font_color", UIKit.AMBER)
	
	# Round buttons
	_fire_skin = _skin(fire_button, "fire", UIKit.CRIMSON, UIKit.TEXT)
	_fire_skin.ring = UIKit.CRIMSON_DARK
	_fire_skin.ring_width = 8.0
	_molotov_skin = _skin(molotov_button, "molotov", Color(UIKit.PANEL, 0.88), UIKit.AMBER)
	_blast_skin = _skin(super_blast_button, "rocket", Color(UIKit.PANEL, 0.88), UIKit.TEXT)
	_blast_skin.text = "BLAST"
	_climb_skin = _skin(climb_button, "charge", Color(UIKit.PANEL, 0.75), UIKit.CYAN)
	if player:
		_update_auto_fire_ui(player.auto_fire_enabled)
		_on_molotov_ammo_changed(player.molotov_ammo, player.max_molotov_ammo)
		_on_vault_state_changed(player.can_vault)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.in_run_loot_changed.connect(_on_run_loot_changed)
		_run_sc = gm.in_run_sc
	_update_stats()


func _theme(c: Control) -> void:
	if c.theme == null:
		c.theme = get_tree().root.theme


## Replaces a TextureButton's art with a drawn round skin (input wiring unchanged).
func _skin(btn: TextureButton, icon_name: String, fill: Color, icon_color: Color) -> RoundButtonSkin:
	btn.texture_normal = null
	btn.texture_pressed = null
	btn.texture_hover = null
	btn.texture_disabled = null
	btn.modulate = Color.WHITE
	for child in btn.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false
	var skin := RoundButtonSkin.new()
	skin.fill = fill
	skin.icon = UIKit.icon_texture(icon_name)
	skin.icon_color = icon_color
	skin.text_color = icon_color
	btn.add_child(skin)
	return skin

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "WAVE %02d" % wave_number
