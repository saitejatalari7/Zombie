extends CanvasLayer
class_name SunlightControlPanel
## SunlightControlPanel.gd
## Interactive In-Game Sunlight & Shadow Lab for PROTOCOL: CRIMSON.
## Allows real-time tweaking of Sun angles, direct energy, ambient shadow fill,
## and shadow distance directly during gameplay with presets and 1-tap clipboard copying.

@export var sun_path: NodePath
@export var world_env_path: NodePath

var sun: DirectionalLight3D = null
var world_env: WorldEnvironment = null

# UI Nodes
@onready var toggle_btn: Button = $ToggleBtn
@onready var panel_container: PanelContainer = $PanelContainer
@onready var close_btn: Button = $PanelContainer/Margin/VBox/HeaderHBox/CloseBtn

# Sliders
@onready var slider_pitch: HSlider = $PanelContainer/Margin/VBox/PitchBox/HSlider
@onready var lbl_pitch: Label = $PanelContainer/Margin/VBox/PitchBox/ValLabel

@onready var slider_yaw: HSlider = $PanelContainer/Margin/VBox/YawBox/HSlider
@onready var lbl_yaw: Label = $PanelContainer/Margin/VBox/YawBox/ValLabel

@onready var slider_energy: HSlider = $PanelContainer/Margin/VBox/EnergyBox/HSlider
@onready var lbl_energy: Label = $PanelContainer/Margin/VBox/EnergyBox/ValLabel

@onready var slider_ambient: HSlider = $PanelContainer/Margin/VBox/AmbientBox/HSlider
@onready var lbl_ambient: Label = $PanelContainer/Margin/VBox/AmbientBox/ValLabel

@onready var slider_shadow_dist: HSlider = $PanelContainer/Margin/VBox/ShadowDistBox/HSlider
@onready var lbl_shadow_dist: Label = $PanelContainer/Margin/VBox/ShadowDistBox/ValLabel

# Presets
@onready var btn_preset_default: Button = $PanelContainer/Margin/VBox/PresetGrid/BtnDefault
@onready var btn_preset_noon: Button = $PanelContainer/Margin/VBox/PresetGrid/BtnNoon
@onready var btn_preset_golden: Button = $PanelContainer/Margin/VBox/PresetGrid/BtnGolden
@onready var btn_preset_noir: Button = $PanelContainer/Margin/VBox/PresetGrid/BtnNoir
@onready var btn_preset_long: Button = $PanelContainer/Margin/VBox/PresetGrid/BtnLong

# Output
@onready var code_preview: LineEdit = $PanelContainer/Margin/VBox/CodePreview
@onready var copy_btn: Button = $PanelContainer/Margin/VBox/CopyBtn
@onready var copy_feedback: Label = $PanelContainer/Margin/VBox/CopyFeedback

var _updating_ui := false

func _ready() -> void:
	layer = 25 # Ensure it renders above game HUD and modals
	
	if not sun and has_node(sun_path):
		sun = get_node(sun_path) as DirectionalLight3D
	if not world_env and has_node(world_env_path):
		world_env = get_node(world_env_path) as WorldEnvironment
		
	# Fallback auto-discovery
	if not sun:
		var root_tree := get_tree().current_scene
		if root_tree:
			sun = root_tree.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
			world_env = root_tree.find_child("WorldEnvironment", true, false) as WorldEnvironment
			
	# Connect UI Signals
	toggle_btn.pressed.connect(_on_toggle_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	
	slider_pitch.value_changed.connect(_on_slider_changed)
	slider_yaw.value_changed.connect(_on_slider_changed)
	slider_energy.value_changed.connect(_on_slider_changed)
	slider_ambient.value_changed.connect(_on_slider_changed)
	slider_shadow_dist.value_changed.connect(_on_slider_changed)
	
	btn_preset_default.pressed.connect(func(): _apply_values(-45.0, 106.0, 1.95, 0.18, 100.0))
	btn_preset_noon.pressed.connect(func(): _apply_values(-78.0, 25.0, 1.45, 0.65, 55.0))
	btn_preset_golden.pressed.connect(func(): _apply_values(-28.0, 115.0, 1.35, 0.40, 80.0))
	btn_preset_noir.pressed.connect(func(): _apply_values(-45.0, 220.0, 1.15, 0.20, 65.0))
	btn_preset_long.pressed.connect(func(): _apply_values(-22.0, 42.0, 1.30, 0.35, 85.0))
	
	copy_btn.pressed.connect(_on_copy_pressed)
	
	# Listen to orientation changes
	var om = get_node_or_null("/root/OrientationManager")
	if om:
		om.orientation_changed.connect(_on_orientation_changed)
		_apply_orientation(om.is_portrait)
	else:
		_apply_orientation(false)
		
	# Load initial values
	sync_from_lights()
	panel_container.visible = false

func setup(p_sun: DirectionalLight3D, p_env: WorldEnvironment) -> void:
	sun = p_sun
	world_env = p_env
	sync_from_lights()

func sync_from_lights() -> void:
	if not is_inside_tree() or not slider_pitch:
		return
	_updating_ui = true
	
	if sun:
		slider_pitch.value = sun.rotation_degrees.x
		slider_yaw.value = fposmod(sun.rotation_degrees.y, 360.0)
		slider_energy.value = sun.light_energy
		slider_shadow_dist.value = sun.directional_shadow_max_distance
	else:
		slider_pitch.value = -45.0
		slider_yaw.value = 106.0
		slider_energy.value = 1.95
		slider_shadow_dist.value = 100.0
		
	if world_env and world_env.environment:
		slider_ambient.value = world_env.environment.ambient_light_energy
	else:
		slider_ambient.value = 0.18
		
	_updating_ui = false
	_refresh_labels()

func _on_slider_changed(_val: float) -> void:
	if _updating_ui:
		return
		
	var pitch := slider_pitch.value
	var yaw := slider_yaw.value
	var energy := slider_energy.value
	var ambient := slider_ambient.value
	var shadow_dist := slider_shadow_dist.value
	
	if sun:
		sun.rotation_degrees = Vector3(pitch, yaw, 0.0)
		sun.light_energy = energy
		sun.directional_shadow_max_distance = shadow_dist
		
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = ambient
		
	_refresh_labels()

func _apply_values(pitch: float, yaw: float, energy: float, ambient: float, shadow_dist: float) -> void:
	_updating_ui = true
	slider_pitch.value = pitch
	slider_yaw.value = yaw
	slider_energy.value = energy
	slider_ambient.value = ambient
	slider_shadow_dist.value = shadow_dist
	_updating_ui = false
	
	_on_slider_changed(0.0)

func _refresh_labels() -> void:
	lbl_pitch.text = "%.1f°" % slider_pitch.value
	lbl_yaw.text = "%.1f°" % slider_yaw.value
	lbl_energy.text = "%.2f" % slider_energy.value
	lbl_ambient.text = "%.2f" % slider_ambient.value
	lbl_shadow_dist.text = "%.0f m" % slider_shadow_dist.value
	
	# Update code preview
	var code_snippet := "sun.rotation_degrees = Vector3(%.1f, %.1f, 0.0) | energy: %.2f | amb: %.2f" % [
		slider_pitch.value, slider_yaw.value, slider_energy.value, slider_ambient.value
	]
	code_preview.text = code_snippet

func _on_copy_pressed() -> void:
	var full_code := (
		"# ── Selected Sunlight & Environment Configuration ──\n" +
		"sun.rotation_degrees = Vector3(%.1f, %.1f, 0.0)\n" % [slider_pitch.value, slider_yaw.value] +
		"sun.light_energy = %.2f\n" % slider_energy.value +
		"sun.directional_shadow_max_distance = %.1f\n" % slider_shadow_dist.value +
		"world_env.environment.ambient_light_energy = %.2f\n" % slider_ambient.value
	)
	
	DisplayServer.clipboard_set(full_code)
	print("[SunlightControl] COPIED CONFIG TO CLIPBOARD:\n", full_code)
	
	copy_feedback.text = "✓ COPIED TO CLIPBOARD & CONSOLE!"
	copy_feedback.modulate = Color(0.2, 1.0, 0.4, 1.0)
	var t := create_tween()
	t.tween_property(copy_feedback, "modulate:a", 0.0, 2.0).set_delay(1.0)

func _on_toggle_pressed() -> void:
	panel_container.visible = not panel_container.visible
	if panel_container.visible:
		sync_from_lights()

func _on_close_pressed() -> void:
	panel_container.visible = false

func _on_orientation_changed(is_portrait: bool) -> void:
	_apply_orientation(is_portrait)

func _apply_orientation(is_portrait: bool) -> void:
	if not is_inside_tree() or not panel_container:
		return
		
	if is_portrait:
		# Portrait (1080x1920)
		toggle_btn.position = Vector2(1080 - 190, 42)
		toggle_btn.size = Vector2(140, 56)
		
		panel_container.position = Vector2(60, 110)
		panel_container.size = Vector2(960, 680)
	else:
		# Landscape (1920x1080)
		toggle_btn.position = Vector2(1920 - 240, 36)
		toggle_btn.size = Vector2(150, 52)
		
		panel_container.position = Vector2(1920 - 540, 96)
		panel_container.size = Vector2(500, 720)
