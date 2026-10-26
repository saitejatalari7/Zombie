extends Node
## OrientationManager.gd — Global Autoload
## Handles dynamic portrait ↔ landscape switching at runtime.
## Correctly updates Godot 4 viewport scale (content_scale_size) and window dimensions.
## Emits orientation_changed so all UI and camera systems can re-anchor responsively.

# ─── Signals ───────────────────────────────────────────────────────────────────
signal orientation_changed(is_portrait: bool)

# ─── State ─────────────────────────────────────────────────────────────────────
var is_portrait: bool = true:
	set(value):
		if is_portrait != value:
			is_portrait = value
			_apply_orientation()
			orientation_changed.emit(is_portrait)

# ─── Viewport Dimension Presets ───────────────────────────────────────────────
const PORTRAIT_SIZE := Vector2i(1080, 1920)
const LANDSCAPE_SIZE := Vector2i(1920, 1080)

# Window overrides for desktop simulation
const DESKTOP_PORTRAIT_WINDOW := Vector2i(540, 960)
const DESKTOP_LANDSCAPE_WINDOW := Vector2i(960, 540)

## Camera3D isometric presets matching tactical reference layouts
const PORTRAIT_CAMERA_SIZE := 46.0     # Orthographic size for portrait (wide tactical view)
const LANDSCAPE_CAMERA_SIZE := 40.0    # Orthographic size for landscape (wide tactical view)
const PORTRAIT_CAMERA_FOV := 58.0      # Perspective FOV for portrait (wide tactical view)
const LANDSCAPE_CAMERA_FOV := 60.0     # Perspective FOV for landscape (wide tactical view)

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# On mobile, query hardware screen orientation; on desktop, default to portrait
	# or restore saved preference from GameManager if available
	var preferred_portrait := true
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and "saved_is_portrait" in gm:
		preferred_portrait = gm.saved_is_portrait
	elif _is_mobile():
		var current_orientation := DisplayServer.screen_get_orientation()
		preferred_portrait = (current_orientation == DisplayServer.SCREEN_PORTRAIT \
			or current_orientation == DisplayServer.SCREEN_REVERSE_PORTRAIT)
	else:
		# On desktop testing, preserve portrait as default
		preferred_portrait = true

	# Force clean initialization
	is_portrait = preferred_portrait
	_apply_orientation()
	print("[OrientationManager] Ready — Initialized to %s (%dx%d)" % [
		"Portrait" if is_portrait else "Landscape",
		get_viewport_size().x,
		get_viewport_size().y
	])


# ─── Public API ────────────────────────────────────────────────────────────────
func set_portrait() -> void:
	self.is_portrait = true


func set_landscape() -> void:
	self.is_portrait = false


func toggle_orientation() -> void:
	self.is_portrait = !is_portrait


func get_viewport_size() -> Vector2i:
	return PORTRAIT_SIZE if is_portrait else LANDSCAPE_SIZE


func get_camera_orthographic_size() -> float:
	return PORTRAIT_CAMERA_SIZE if is_portrait else LANDSCAPE_CAMERA_SIZE


func get_camera_fov() -> float:
	return PORTRAIT_CAMERA_FOV if is_portrait else LANDSCAPE_CAMERA_FOV


# ─── Core Viewport & Window Scaling ───────────────────────────────────────────
func _apply_orientation() -> void:
	var target_size := get_viewport_size()
	
	# 1. Update OS-level screen orientation on Mobile devices
	if _is_mobile():
		if is_portrait:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		else:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	
	# 2. CRITICAL FIX FOR GODOT 4:
	# Setting ProjectSettings does NOT dynamically resize active runtime viewports.
	# We must explicitly update root.content_scale_size and window content scale.
	var root_viewport := get_tree().root
	if root_viewport:
		root_viewport.content_scale_size = target_size
	
	var window := get_window()
	if window:
		window.content_scale_size = target_size
		# On desktop (development / testing), resize the display window
		if not _is_mobile():
			window.size = DESKTOP_PORTRAIT_WINDOW if is_portrait else DESKTOP_LANDSCAPE_WINDOW
	
	# 3. Synchronize with GameManager save state if available
	var gm = get_node_or_null("/root/GameManager")
	if gm and "saved_is_portrait" in gm:
		if gm.saved_is_portrait != is_portrait:
			gm.saved_is_portrait = is_portrait
			gm.save_settings_only()
	
	print("[OrientationManager] Applied %s mode — content_scale_size: %dx%d" % [
		"Portrait" if is_portrait else "Landscape",
		target_size.x,
		target_size.y
	])


func _is_mobile() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"


# ─── Camera Helper ─────────────────────────────────────────────────────────────
func apply_to_camera(camera: Camera3D) -> void:
	if not camera:
		return
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		camera.size = get_camera_orthographic_size()
	else:
		camera.fov = get_camera_fov()


# ─── Safe Margin Helper ────────────────────────────────────────────────────────
func get_ui_safe_margins() -> Dictionary:
	if is_portrait:
		return {
			"top": 80,       # Status bar / notch clearance
			"bottom": 40,    # Navigation bar
			"left": 24,
			"right": 24,
		}
	else:
		return {
			"top": 24,
			"bottom": 24,
			"left": 80,      # Notch / punch-hole landscape clearance
			"right": 80,
		}
