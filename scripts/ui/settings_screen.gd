extends Control
class_name SettingsScreen
## SettingsScreen.gd
## The one settings screen, opened from the title, the hub and the pause menu.
## Audio sliders, gameplay toggles and a two-step "reset progress". Works while paused.

signal closed()

var _reset_armed: bool = false
var _reset_button: Button = null


static func open(parent: Node) -> SettingsScreen:
	var s := SettingsScreen.new()
	s.name = "SettingsScreen"
	parent.add_child(s)
	return s


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if theme == null:
		theme = get_tree().root.theme  # may be opened under a CanvasLayer (pause menu)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UIKit.overlay(0.96))

	var root := UIKit.vbox(26)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = UIKit.MARGIN
	root.offset_right = -UIKit.MARGIN
	root.offset_top = UIKit.TOP_SAFE + 40
	root.offset_bottom = -120
	add_child(root)

	root.add_child(UIKit.label("SETTINGS", "DisplayLabel"))

	var am = get_node_or_null("/root/AudioManager")
	var gm = get_node_or_null("/root/GameManager")

	root.add_child(UIKit.label("AUDIO", "CaptionLabel"))
	root.add_child(_slider_row("Music", am.music_volume if am else 0.7, _set_music))
	root.add_child(_slider_row("Effects", am.sfx_volume if am else 1.0, _set_effects))
	
	root.add_child(UIKit.label("GAMEPLAY", "CaptionLabel"))
	root.add_child(_toggle_row("Vibration", am.haptics_enabled if am else true, "ON", "OFF", _set_vibration))
	root.add_child(_toggle_row("Screen shake", gm.saved_screen_shake if gm else true, "ON", "OFF", _set_shake))
	root.add_child(_toggle_row("Blood amount", gm.saved_blood_full if gm else true, "FULL", "LOW", _set_blood))
	
	root.add_child(UIKit.label("DATA", "CaptionLabel"))
	_reset_button = UIKit.button("Reset progress", "GhostButton", UIKit.MIN_TOUCH)
	_reset_button.add_theme_color_override("font_color", Color(1.0, 0.42, 0.45))
	_reset_button.pressed.connect(_on_reset_pressed)
	root.add_child(_reset_button)

	root.add_child(UIKit.expander())
	var done := UIKit.button("Done", "GhostButton")
	done.pressed.connect(_close)
	root.add_child(done)


func _slider_row(title: String, value: float, on_change: Callable) -> Control:
	var row := UIKit.hbox(24)
	row.custom_minimum_size = Vector2(0, UIKit.MIN_TOUCH)
	var l := UIKit.label(title)
	l.custom_minimum_size = Vector2(260, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(0, 80)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row


## A full-width tappable row that flips between two values.
func _toggle_row(title: String, on: bool, word_on: String, word_off: String, on_change: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = "GhostButton"
	b.custom_minimum_size = Vector2(0, UIKit.MIN_TOUCH)
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta("on", on)
	b.set_meta("title", title.to_upper())
	b.set_meta("word_on", word_on)
	b.set_meta("word_off", word_off)
	b.set_meta("on_change", on_change)
	_refresh_toggle(b)
	b.pressed.connect(_on_toggle_pressed.bind(b))
	return b


func _on_toggle_pressed(b: Button) -> void:
	var state: bool = not bool(b.get_meta("on"))
	b.set_meta("on", state)
	var cb: Callable = b.get_meta("on_change")
	cb.call(state)
	_refresh_toggle(b)


func _refresh_toggle(b: Button) -> void:
	var state: bool = b.get_meta("on")
	var word: String = b.get_meta("word_on") if state else b.get_meta("word_off")
	b.text = "%s   ·   %s" % [String(b.get_meta("title")), word]
	b.add_theme_color_override("font_color", UIKit.GREEN if state else UIKit.AMBER)


# ─── Setting handlers ─────────────────────────────────────────────────────────
func _set_music(v: float) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.music_volume = v


func _set_effects(v: float) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.sfx_volume = v


func _set_vibration(on: bool) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.haptics_enabled = on


func _set_shake(on: bool) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.saved_screen_shake = on


func _set_blood(on: bool) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.saved_blood_full = on
		if BloodManager.instance:
			BloodManager.instance.max_decals = gm.get_blood_decal_limit()


func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "TAP AGAIN TO ERASE ALL PROGRESS"
		get_tree().create_timer(4.0, true).timeout.connect(_disarm_reset)
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.reset_save()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")


func _disarm_reset() -> void:
	if is_instance_valid(_reset_button) and _reset_armed:
		_reset_armed = false
		_reset_button.text = "RESET PROGRESS"


func _close() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.save_settings_only()
	closed.emit()
	queue_free()
