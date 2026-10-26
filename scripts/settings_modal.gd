extends Control
## SettingsModal.gd
## In-game and Outpost Hub settings dialog.
## Controls Master/SFX/Music volumes, haptic toggles, orientation mode, and save wipes.

signal closed()

@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var haptics_check: CheckBox = %HapticsCheck
@onready var orientation_btn: Button = %OrientationButton
@onready var close_btn: Button = %CloseButton
@onready var reset_save_btn: Button = %ResetSaveButton
@onready var confirm_dialog: ConfirmationDialog = %ConfirmDialog

func _ready() -> void:
	visible = false
	_connect_signals()
	_sync_ui_from_state()

func open() -> void:
	_sync_ui_from_state()
	visible = true
	var tween := create_tween()
	modulate.a = 0.0
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_click")

func close() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_back")
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func():
		visible = false
		closed.emit()
	)

func _connect_signals() -> void:
	if master_slider:
		master_slider.value_changed.connect(_on_master_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if haptics_check:
		haptics_check.toggled.connect(_on_haptics_toggled)
	if orientation_btn:
		orientation_btn.pressed.connect(_on_orientation_pressed)
	if close_btn:
		close_btn.pressed.connect(close)
	if reset_save_btn:
		reset_save_btn.pressed.connect(_on_reset_save_pressed)
	if confirm_dialog:
		confirm_dialog.confirmed.connect(_on_reset_confirmed)

func _sync_ui_from_state() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		if master_slider: master_slider.value = am.master_volume * 100.0
		if sfx_slider: sfx_slider.value = am.sfx_volume * 100.0
		if music_slider: music_slider.value = am.music_volume * 100.0
		if haptics_check: haptics_check.button_pressed = am.haptics_enabled
	
	var om = get_node_or_null("/root/OrientationManager")
	if om and orientation_btn:
		orientation_btn.text = "MODE: PORTRAIT" if om.is_portrait else "MODE: LANDSCAPE"

func _on_master_changed(value: float) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.master_volume = value / 100.0

func _on_sfx_changed(value: float) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.sfx_volume = value / 100.0

func _on_music_changed(value: float) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.music_volume = value / 100.0

func _on_haptics_toggled(toggled_on: bool) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.haptics_enabled = toggled_on
		if toggled_on and am.has_method("haptic_light"):
			am.haptic_light()

func _on_orientation_pressed() -> void:
	var om = get_node_or_null("/root/OrientationManager")
	if om:
		om.toggle_orientation()
		if orientation_btn:
			orientation_btn.text = "MODE: PORTRAIT" if om.is_portrait else "MODE: LANDSCAPE"

func _on_reset_save_pressed() -> void:
	if confirm_dialog:
		confirm_dialog.popup_centered()

func _on_reset_confirmed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("reset_save"):
		gm.reset_save()
	_sync_ui_from_state()
	close()
