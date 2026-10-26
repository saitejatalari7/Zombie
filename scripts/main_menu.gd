extends Control
class_name MainMenu

@onready var play_btn: Button = $MenuButtons/PlayButton
@onready var settings_btn: Button = $MenuButtons/SettingsButton
@onready var quit_btn: Button = $MenuButtons/QuitButton

@onready var settings_modal: Control = $SettingsModal
@onready var shake_btn: Button = $SettingsModal/Card/VBox/ShakeBtn
@onready var blood_btn: Button = $SettingsModal/Card/VBox/BloodBtn
@onready var close_settings_btn: Button = $SettingsModal/Card/VBox/CloseSettingsBtn

var screen_shake: bool = true
var blood_max: bool = true

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	shake_btn.pressed.connect(_on_shake_toggle)
	blood_btn.pressed.connect(_on_blood_toggle)
	close_settings_btn.pressed.connect(_on_close_settings)

func _on_play_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(play_btn, "scale", Vector2(0.92, 0.92), 0.08)
	tween.tween_property(play_btn, "scale", Vector2(1.0, 1.0), 0.1)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
	settings_modal.visible = true

func _on_close_settings() -> void:
	settings_modal.visible = false

func _on_shake_toggle() -> void:
	screen_shake = not screen_shake
	shake_btn.text = "SCREEN SHAKE: " + ("ON" if screen_shake else "OFF")

func _on_blood_toggle() -> void:
	blood_max = not blood_max
	blood_btn.text = "BLOOD PARTICLES: " + ("MAX" if blood_max else "LOW")

func _on_quit_pressed() -> void:
	get_tree().quit()
