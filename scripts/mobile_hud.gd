extends CanvasLayer
class_name MobileHUD
## MobileHUD.gd
## Tactical Extraction HUD for PROTOCOL: CRIMSON.
## Fully responsive between Portrait (1080x1920) and Landscape (1920x1080).
## Features Auto-Fire toggle, Mission Tracker Pill, Twin-Stick Drag Aim,
## and dynamic ability placement (Vertical Stack vs. Radial Arc).

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

func _process(delta: float) -> void:
	# Continuous mouse raycast targeting while special aiming on PC
	if (key_molotov_aiming or key_blast_aiming or (is_molotov_aiming and not DisplayServer.is_touchscreen_available()) or (is_super_blast_aiming and not DisplayServer.is_touchscreen_available())) and player:
		_update_mouse_aim()
		
	_fps_timer += delta
	if _fps_timer >= 0.22 and is_instance_valid(fps_label):
		_fps_timer = 0.0
		var fps := Engine.get_frames_per_second()
		var ms := 1000.0 / maxf(1.0, float(fps))
		fps_label.text = "⚡ %d FPS  (%.1f ms)" % [fps, ms]
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
	
	# Listen to Orientation changes for responsive layout reflow
	var om = get_node_or_null("/root/OrientationManager")
	if om:
		om.orientation_changed.connect(_on_orientation_changed)
		_apply_responsive_layout(om.is_portrait)
	else:
		_apply_responsive_layout(true)

func _on_orientation_changed(is_portrait: bool) -> void:
	_apply_responsive_layout(is_portrait)

func _apply_responsive_layout(is_portrait: bool) -> void:
	if not is_inside_tree():
		return
		
	if is_portrait:
		# ─── PORTRAIT (1080 x 1920) ──────────────────────────────────────────
		# Joystick
		joystick.offset_left = 60.0
		joystick.offset_top = -420.0
		joystick.offset_right = 420.0
		joystick.offset_bottom = -60.0
		
		# Fire Button
		fire_button.offset_left = -310.0
		fire_button.offset_top = -340.0
		fire_button.offset_right = -70.0
		fire_button.offset_bottom = -100.0
		
		# Auto-Fire Toggle Button (above fire button)
		if auto_fire_btn:
			auto_fire_btn.offset_left = -310.0
			auto_fire_btn.offset_top = -415.0
			auto_fire_btn.offset_right = -70.0
			auto_fire_btn.offset_bottom = -355.0
		
		# Vertical Stack Ability Buttons
		super_blast_button.offset_left = -275.0
		super_blast_button.offset_top = -600.0
		super_blast_button.offset_right = -105.0
		super_blast_button.offset_bottom = -430.0
		
		molotov_button.offset_left = -475.0
		molotov_button.offset_top = -540.0
		molotov_button.offset_right = -315.0
		molotov_button.offset_bottom = -380.0
		
		climb_button.offset_left = -465.0
		climb_button.offset_top = -320.0
		climb_button.offset_right = -305.0
		climb_button.offset_bottom = -160.0
		
		if mission_pill:
			mission_pill.offset_left = -280.0
			mission_pill.offset_right = 280.0
			mission_pill.offset_top = 100.0
	else:
		# ─── LANDSCAPE (1920 x 1080) ─────────────────────────────────────────
		# Movement Joystick left-anchored
		joystick.offset_left = 80.0
		joystick.offset_top = -400.0
		joystick.offset_right = 400.0
		joystick.offset_bottom = -80.0
		
		# Dedicated Fire / Aim Button right-anchored
		fire_button.offset_left = -330.0
		fire_button.offset_top = -320.0
		fire_button.offset_right = -90.0
		fire_button.offset_bottom = -80.0
		
		# Radial / Arc ability buttons arrayed around Fire button (Design Doc 6.3)
		if auto_fire_btn:
			auto_fire_btn.offset_left = -570.0
			auto_fire_btn.offset_top = -140.0
			auto_fire_btn.offset_right = -370.0
			auto_fire_btn.offset_bottom = -80.0
			
		molotov_button.offset_left = -550.0
		molotov_button.offset_top = -320.0
		molotov_button.offset_right = -390.0
		molotov_button.offset_bottom = -160.0
		
		super_blast_button.offset_left = -390.0
		super_blast_button.offset_top = -490.0
		super_blast_button.offset_right = -220.0
		super_blast_button.offset_bottom = -320.0
		
		climb_button.offset_left = -200.0
		climb_button.offset_top = -490.0
		climb_button.offset_right = -40.0
		climb_button.offset_bottom = -330.0
		
		if mission_pill:
			mission_pill.offset_left = -360.0
			mission_pill.offset_right = 360.0
			mission_pill.offset_top = 80.0

func _on_auto_fire_pressed() -> void:
	if player:
		var state := player.toggle_auto_fire()
		_update_auto_fire_ui(state)

func _update_auto_fire_ui(enabled: bool) -> void:
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
		var center: Vector2 = fire_button.size * 0.5
		var drag_offset: Vector2 = (event.position - center) / (fire_button.size.x * 0.5)
		if player:
			player.mobile_aim_input = drag_offset.limit_length(1.0)
	elif event is InputEventMouseMotion and is_fire_dragging:
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
		molotov_button.modulate.a = 0.45 if (current <= 0) else 1.0

func _on_vault_state_changed(can_vault: bool) -> void:
	if climb_button:
		if can_vault:
			climb_button.modulate = Color(0.2, 1.0, 0.9, 1.0)
			var tween := create_tween()
			tween.tween_property(climb_button, "scale", Vector2(1.1, 1.1), 0.12)
			tween.tween_property(climb_button, "scale", Vector2(1.0, 1.0), 0.12)
		else:
			climb_button.modulate = Color(1, 1, 1, 0.45)

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
	_radio_speaker.text = "📻 " + String(line[0])
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
	_radio_panel = PanelContainer.new()
	_radio_panel.name = "RadioPanel"
	_radio_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radio_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_radio_panel.offset_left = -400.0
	_radio_panel.offset_right = 400.0
	_radio_panel.offset_top = 228.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.067, 0.067, 0.075, 0.88)
	bg.border_color = Color(1.0, 0.72, 0.0, 0.9)
	bg.border_width_left = 6
	bg.set_content_margin_all(16)
	_radio_panel.add_theme_stylebox_override("panel", bg)
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radio_panel.add_child(vbox)
	_radio_speaker = Label.new()
	_radio_speaker.add_theme_font_size_override("font_size", 24)
	_radio_speaker.add_theme_color_override("font_color", Color(1.0, 0.72, 0.0))
	vbox.add_child(_radio_speaker)
	_radio_text = Label.new()
	_radio_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio_text.custom_minimum_size = Vector2(740.0, 0.0)
	_radio_text.add_theme_font_size_override("font_size", 28)
	_radio_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.97))
	vbox.add_child(_radio_text)
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
func show_mission_result(summary: Dictionary) -> void:
	get_tree().paused = true
	controls_root.visible = false
	pause_button.visible = false
	pause_modal.visible = false
	
	var success: bool = summary.get("success", false)
	var accent := Color(0.35, 1.0, 0.55) if success else Color(1.0, 0.2, 0.25)
	
	var overlay := ColorRect.new()
	overlay.name = "MissionResult"
	overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(820, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.067, 0.067, 0.075, 0.97)
	style.border_color = accent
	style.set_border_width_all(4)
	style.set_content_margin_all(48)
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	card.add_child(vbox)
	
	_add_result_label(vbox, "EXTRACTION SUCCESSFUL" if success else "OPERATIVE KIA", 60, accent)
	_add_result_label(vbox, summary.get("title", ""), 26, Color(0.65, 0.65, 0.68))
	
	if summary.is_empty():
		_add_result_label(vbox, "No contract data.", 30, Color.WHITE)
	else:
		var kills: Dictionary = summary.get("kills", {})
		_add_result_label(vbox, "KILLS: %d   (SHAMBLER %d · RUNNER %d · TANK %d)" % [
			summary.get("kill_count", 0), kills.get("shambler", 0), kills.get("runner", 0), kills.get("tank", 0)
		], 30, Color.WHITE)
		if success:
			var contract_line := "CONTRACT PAYOUT: +%d SC" % summary.get("contract_sc", 0)
			if summary.get("first_clear", false):
				contract_line += "   [FIRST CLEAR x2]"
			_add_result_label(vbox, contract_line, 30, Color.WHITE)
			_add_result_label(vbox, "KILL BOUNTY: +%d SC" % summary.get("kill_sc", 0), 30, Color.WHITE)
			_add_result_label(vbox, "BANKED: +%d SC   +%d RC" % [summary.get("total_sc", 0), summary.get("total_rc", 0)], 38, Color(1.0, 0.72, 0.0))
		else:
			_add_result_label(vbox, "UNBANKED LOOT LOST: %d SC" % summary.get("lost_sc", 0), 30, Color(1.0, 0.45, 0.45))
			_add_result_label(vbox, "SALVAGED (30%%): +%d SC" % summary.get("total_sc", 0), 38, Color(1.0, 0.72, 0.0))
		
		var intel: Vector2i = summary.get("intel", Vector2i.ZERO)
		if intel.y > 0:
			_add_result_label(vbox, "INTEL FOUND IN THIS SECTOR: %d / %d" % [intel.x, intel.y], 26, Color(0.75, 0.75, 0.8))
		_add_result_label(vbox, "+%d XP   ·   CLR-LV.%02d  (%d / %d XP)" % [
			summary.get("total_xp", 0), summary.get("level_after", 1), summary.get("xp_now", 0), summary.get("xp_needed", 0)
		], 30, Color.WHITE)
		if summary.get("level_after", 1) > summary.get("level_before", 1):
			_add_result_label(vbox, "▲ CLEARANCE LEVEL UP!", 40, Color(1.0, 0.72, 0.0))
		if summary.get("sector_unlocked", 0) > 0:
			_add_result_label(vbox, "★ SECTOR %02d UNLOCKED" % summary["sector_unlocked"], 40, Color(1.0, 0.15, 0.2))
	
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)
	
	var redeploy_btn := Button.new()
	redeploy_btn.text = "REDEPLOY" if success else "RETRY CONTRACT"
	redeploy_btn.custom_minimum_size = Vector2(0, 110)
	redeploy_btn.add_theme_font_size_override("font_size", 34)
	redeploy_btn.pressed.connect(restart_game)
	vbox.add_child(redeploy_btn)
	
	var hub_btn := Button.new()
	hub_btn.text = "RETURN TO OUTPOST"
	hub_btn.custom_minimum_size = Vector2(0, 110)
	hub_btn.add_theme_font_size_override("font_size", 34)
	hub_btn.pressed.connect(goto_main_menu)
	vbox.add_child(hub_btn)

func _add_result_label(parent: Control, text: String, font_size: int, col: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", col)
	parent.add_child(label)

func show_street_cleared_banner() -> void:
	if not street_cleared_banner:
		return
	street_cleared_banner.visible = true
	street_cleared_banner.position.y = -100.0
	street_cleared_banner.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(street_cleared_banner, "position:y", 105.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(street_cleared_banner, "modulate:a", 1.0, 0.3)
	
	# Stay for 4.5s then smoothly dismiss
	tween.tween_interval(4.5)
	tween.tween_property(street_cleared_banner, "position:y", -100.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(street_cleared_banner, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): street_cleared_banner.visible = false)

func toggle_pause() -> void:
	var is_paused := get_tree().paused
	if is_paused:
		resume_game()
	else:
		get_tree().paused = true
		pause_modal.visible = true

func resume_game() -> void:
	get_tree().paused = false
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
	settings_modal.visible = true

func close_settings() -> void:
	settings_modal.visible = false

func goto_main_menu() -> void:
	_abandon_active_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/outpost_hub.tscn")

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
	if player:
		player.mobile_fire_pressed = true

func _on_fire_up() -> void:
	is_fire_dragging = false
	if player:
		player.mobile_fire_pressed = false
		player.mobile_aim_input = Vector2.ZERO

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

func _on_super_blast_cooldown(ratio: float) -> void:
	if super_blast_cooldown_overlay:
		super_blast_cooldown_overlay.anchor_top = 1.0 - ratio
		super_blast_button.disabled = (ratio > 0.01)
		super_blast_button.modulate.a = 0.55 if (ratio > 0.01) else 1.0

func _on_zombie_count_changed(alive_count: int, total_kills: int) -> void:
	zombie_count_label.text = "💀 %02d  |  KILLS: %d" % [alive_count, total_kills]

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "WAVE %02d" % wave_number
